#!/usr/bin/env python3
"""NeNe Delve の規約検査。依存は Python 標準ライブラリだけ。"""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
from dataclasses import dataclass
from datetime import date
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import commit_message  # noqa: E402

RULE_ID = r"(?:ARC|SWF|QLT|GIT|CNF)-\d{3}"
HEADING = re.compile(rf"^(#{{2,4}}) ({RULE_ID}) — ")
STATUS = re.compile(r"機械強制:\s+\*\*(active|planned|不能|不採用)\*\*")
MATRIX_ROW = re.compile(rf"^\| ({RULE_ID}) \| (active|planned|不能|不採用) \|")
PROOF_ROW = re.compile(rf"^\| ({RULE_ID}) \|")
ID_REF = re.compile(rf"\b({RULE_ID})\b")
IMPORT_LINE = re.compile(r"^(?:@testable[ \t]+)?import[ \t]+([A-Za-z_][A-Za-z0-9_]*)\s*$")
DECL = re.compile(
    r"^(?:@\w+(?:\([^)]*\))?[ \t]+)*"
    r"(?:(?:public|internal|open|fileprivate|private|package|final|nonisolated)[ \t]+)*"
    r"(struct|class|enum|protocol|actor)[ \t]+([A-Za-z_][A-Za-z0-9_]*)"
)
FORBIDDEN_SUFFIXES = ("Manager", "Helper", "Utils", "Util", "Common")
FORBIDDEN_DIRS = {"utils", "helpers", "managers", "misc", "common"}
PACKAGE_URL = re.compile(r'\.package\(\s*url:\s*"([^"]+)"')
TARGET_DECL = re.compile(
    r"\.(?:executableTarget|target)\(\s*name:\s*\"([^\"]+)\"\s*,\s*dependencies:\s*\[([^\]]*)\]",
    re.S,
)
WAIVER_REF = re.compile(r"^// Waiver: (WVR-\d{4})\s*$")
SWIFTLINT_RULE = {
    "force_unwrapping": "SWF-004",
    "force_cast": "SWF-004",
    "force_try": "SWF-004",
    "implicitly_unwrapped_optional": "SWF-004",
    "cyclomatic_complexity": "SWF-012",
    "function_body_length": "SWF-012",
    "function_parameter_count": "SWF-012",
    "nesting": "SWF-012",
}
SKIP_PARTS = {".git", ".build", ".tools", ".handoff", ".swiftpm"}
IMPORTS = {
    "Sources/NeNeDelveCore/": frozenset(),
    "Sources/NeNeDelveRender/": frozenset({"NeNeDelveCore"}),
    "Sources/NeNeDelveTerminal/": frozenset({"NeNeDelveRender", "Glibc"}),
    "Sources/nene-delve/": frozenset(
        {"NeNeDelveCore", "NeNeDelveRender", "NeNeDelveTerminal", "Glibc"}
    ),
    "Tests/": frozenset(
        {"Testing", "NeNeDelveCore", "NeNeDelveRender", "NeNeDelveTerminal"}
    ),
}
TIME_PATTERNS = (
    r"\bContinuousClock\b",
    r"\bSuspendingClock\b",
    r"\bSystemRandomNumberGenerator\b",
    r"\.random\s*\(",
    r"\bDate\b",
    r"\bProcessInfo\b",
    r"\bgetenv\b",
    r"\bclock_gettime\b",
    r"\bgettimeofday\b",
    r"\barc4random\b",
    r"\bLocale\b",
    r"\bTimeZone\b",
    r"\bCalendar\b",
    r"\bFileManager\b",
    r"\bCommandLine\b",
    r"\btime\s*\(",
    r"\bfopen\b",
    r"\bURLSession\b",
)
UNSAFE_POINTERS = (
    r"\bUnsafe(?:Mutable)?(?:Raw)?(?:Buffer)?Pointer\b",
    r"\bwithUnsafe(?:Mutable)?(?:Bytes|Pointer)\b",
    r"\bOpaquePointer\b",
)
TASK_WORD = "TO" + "DO"
FIXME_WORD = "FIX" + "ME"


@dataclass(frozen=True)
class Violation:
    rule_id: str
    path: str
    line: int
    message: str

    def render(self) -> str:
        return f"{self.rule_id}: {self.path}:{self.line}: {self.message}"


def rel(root: Path, path: Path) -> str:
    return path.relative_to(root).as_posix()


def skipped(path: Path) -> bool:
    return any(part in SKIP_PARTS for part in path.parts)


def strip_comments(text: str) -> str:
    out: list[str] = []
    index = 0
    length = len(text)
    while index < length:
        if text.startswith("/*", index):
            end = text.find("*/", index + 2)
            chunk = text[index:] if end < 0 else text[index : end + 2]
            out.append("\n" * chunk.count("\n"))
            if end < 0:
                break
            index = end + 2
            continue
        if text.startswith("//", index):
            end = text.find("\n", index)
            if end < 0:
                break
            index = end
            continue
        out.append(text[index])
        index += 1
    return "".join(out)


def swift_files(root: Path) -> list[Path]:
    found: list[Path] = []
    for folder in ("Sources", "Tests"):
        base = root / folder
        if base.exists():
            found.extend(sorted(base.rglob("*.swift")))
    return found


def markdown_files(root: Path) -> list[Path]:
    found: list[Path] = []
    for path in sorted(root.rglob("*.md")):
        if skipped(path.relative_to(root)):
            continue
        found.append(path)
    return found


def line_number(text: str, index: int) -> int:
    return text.count("\n", 0, index) + 1


def check_names(root: Path) -> list[Violation]:
    violations: list[Violation] = []
    for path in swift_files(root):
        relative = rel(root, path)
        for part in Path(relative).parts:
            if part.lower() in FORBIDDEN_DIRS:
                violations.append(
                    Violation("CNF-001", relative, 1, f"directory name '{part}' is forbidden by SWF-010")
                )
        text = path.read_text(encoding="utf-8")
        for number, line in enumerate(text.splitlines(), 1):
            match = DECL.match(line)
            if match is None:
                continue
            name = match.group(2)
            for suffix in FORBIDDEN_SUFFIXES:
                if name.endswith(suffix):
                    violations.append(
                        Violation(
                            "CNF-001",
                            relative,
                            number,
                            f"type '{name}' ends with forbidden suffix {suffix} (SWF-010)",
                        )
                    )
                    break
    return violations


def check_one_declaration(root: Path) -> list[Violation]:
    violations: list[Violation] = []
    for path in swift_files(root):
        relative = rel(root, path)
        names: list[tuple[int, str]] = []
        for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            match = DECL.match(line)
            if match is not None:
                names.append((number, match.group(2)))
        if len(names) != 1:
            violations.append(
                Violation(
                    "CNF-002",
                    relative,
                    names[0][0] if names else 1,
                    f"expected one top-level type, found {len(names)} (SWF-011)",
                )
            )
            continue
        if path.stem != names[0][1]:
            violations.append(
                Violation(
                    "CNF-002",
                    relative,
                    names[0][0],
                    f"file name '{path.stem}' does not match type '{names[0][1]}' (SWF-011)",
                )
            )
    return violations


def previous_code_line(lines: list[str], index: int) -> tuple[int, str] | None:
    cursor = index - 1
    while cursor >= 0:
        if lines[cursor].strip():
            return cursor + 1, lines[cursor]
        cursor -= 1
    return None


def load_waivers(root: Path) -> dict[str, dict[str, str]]:
    found: dict[str, dict[str, str]] = {}
    directory = root / "docs" / "waivers"
    if not directory.exists():
        return found
    for path in sorted(directory.glob("WVR-*.md")):
        text = path.read_text(encoding="utf-8")
        fields: dict[str, str] = {"path": path.name}
        for key in ("Status", "Rule", "Issue", "Owner", "Created", "Expires", "Scope"):
            match = re.search(rf"(?m)^- {key}:\s*(.+)$", text)
            if match:
                fields[key] = match.group(1).strip().strip("`")
        found[path.name.split("-", 1)[0] + "-" + path.name.split("-")[1]] = fields
        # WVR-0001 from WVR-0001-something.md
        found[path.stem.split("-")[0] + "-" + path.stem.split("-")[1]] = fields
    return found


def waiver_id_from_filename(path: Path) -> str:
    parts = path.stem.split("-")
    return f"{parts[0]}-{parts[1]}"


def check_suppressions(root: Path, today: date) -> list[Violation]:
    violations: list[Violation] = []
    waivers = load_waivers(root)
    for path in swift_files(root):
        relative = rel(root, path)
        lines = path.read_text(encoding="utf-8").splitlines()
        for number, line in enumerate(lines, 1):
            if "swift-format-ignore-file" in line or re.search(r"swiftlint:disable\s+all\b", line):
                violations.append(
                    Violation("CNF-003", relative, number, "file-wide suppression is forbidden (SWF-015)")
                )
                continue
            file_disable = re.search(r"swiftlint:disable\b", line) and not re.search(
                r"swiftlint:disable:(next|this|previous)\b", line
            )
            if file_disable:
                violations.append(
                    Violation("CNF-003", relative, number, "file-wide suppression is forbidden (SWF-015)")
                )
                continue
            lint = re.search(r"swiftlint:disable:(?:next|this|previous)\s+([A-Za-z0-9_]+)", line)
            format_ignore = "swift-format-ignore" in line and "swift-format-ignore-file" not in line
            if lint is None and not format_ignore:
                continue
            if lint is not None and lint.group(1) == "all":
                violations.append(
                    Violation("CNF-003", relative, number, "disabling all rules is forbidden (SWF-015)")
                )
                continue
            mapped = "QLT-004" if lint is None else SWIFTLINT_RULE.get(lint.group(1))
            if mapped is None:
                violations.append(
                    Violation(
                        "CNF-003",
                        relative,
                        number,
                        f"SwiftLint rule '{lint.group(1)}' has no SWF mapping",
                    )
                )
                continue
            previous = previous_code_line(lines, number - 1)
            if previous is None or WAIVER_REF.match(previous[1].strip()) is None:
                violations.append(
                    Violation(
                        "CNF-003",
                        relative,
                        number,
                        "suppression requires a previous line '// Waiver: WVR-NNNN' (SWF-015)",
                    )
                )
                continue
            waiver_id = WAIVER_REF.match(previous[1].strip()).group(1)
            record = waivers.get(waiver_id)
            if record is None:
                violations.append(
                    Violation("CNF-003", relative, number, f"{waiver_id} is not in docs/waivers")
                )
                continue
            if record.get("Status") != "active":
                violations.append(
                    Violation("CNF-004", relative, number, f"{waiver_id} is not active")
                )
                continue
            if record.get("Rule") != mapped:
                violations.append(
                    Violation(
                        "CNF-004",
                        relative,
                        number,
                        f"{waiver_id} covers {record.get('Rule')}, not {mapped}",
                    )
                )
                continue
            expires = record.get("Expires", "")
            try:
                expiry = date.fromisoformat(expires)
            except ValueError:
                violations.append(
                    Violation("CNF-004", relative, number, f"{waiver_id} has no ISO expiry")
                )
                continue
            if expiry < today:
                violations.append(
                    Violation("CNF-004", relative, number, f"{waiver_id} expired on {expires}")
                )
    return violations


def check_waiver_ledger(root: Path, today: date, known_rules: set[str]) -> list[Violation]:
    violations: list[Violation] = []
    directory = root / "docs" / "waivers"
    if not directory.exists():
        return [Violation("CNF-004", "docs/waivers", 1, "waiver ledger directory is missing")]
    index = directory / "README.md"
    index_text = index.read_text(encoding="utf-8") if index.exists() else ""
    for path in sorted(directory.glob("WVR-*.md")):
        waiver_id = waiver_id_from_filename(path)
        relative = rel(root, path)
        text = path.read_text(encoding="utf-8")
        fields: dict[str, str] = {}
        for key in ("Status", "Rule", "Issue", "Owner", "Created", "Expires", "Scope"):
            match = re.search(rf"(?m)^- {key}:\s*(.+)$", text)
            if match is None:
                violations.append(Violation("CNF-004", relative, 1, f"missing field {key}"))
            else:
                fields[key] = match.group(1).strip().strip("`")
        rule = fields.get("Rule", "")
        if known_rules and rule and rule not in known_rules:
            violations.append(Violation("CNF-004", relative, 1, f"rule {rule} is not defined"))
        expires = fields.get("Expires", "")
        try:
            expiry = date.fromisoformat(expires) if expires else None
        except ValueError:
            expiry = None
            violations.append(Violation("CNF-004", relative, 1, "Expires is not YYYY-MM-DD"))
        if fields.get("Status") == "active" and expiry is not None and expiry < today:
            violations.append(Violation("CNF-004", relative, 1, f"{waiver_id} expired on {expires}"))
        if waiver_id not in index_text:
            violations.append(Violation("CNF-004", "docs/waivers/README.md", 1, f"index omits {waiver_id}"))
    return violations


def check_baseline(root: Path) -> list[Violation]:
    violations: list[Violation] = []
    for path in root.rglob("*"):
        if not path.is_file():
            continue
        relative_path = path.relative_to(root)
        if skipped(relative_path):
            continue
        relative = relative_path.as_posix()
        if "baseline" in path.name.lower():
            violations.append(
                Violation("CNF-005", relative, 1, "baseline files are forbidden (QLT-003)")
            )
    banned_in_build = (
        "--baseline",
        "--write-baseline",
        "ignoreFailures",
        "disabled_rules",
        "-suppress-warnings",
    )
    build_files: list[Path] = []
    makefile = root / "Makefile"
    if makefile.exists():
        build_files.append(makefile)
    package = root / "Package.swift"
    if package.exists():
        build_files.append(package)
    workflow = root / ".github" / "workflows"
    if workflow.exists():
        build_files.extend(sorted(workflow.glob("*.yml")))
    for path in list((root / "eng").glob("*.sh")) if (root / "eng").exists() else []:
        build_files.append(path)
    for path in build_files:
        text = path.read_text(encoding="utf-8")
        for token in banned_in_build:
            if token in text:
                line = next(
                    (number for number, row in enumerate(text.splitlines(), 1) if token in row),
                    1,
                )
                violations.append(
                    Violation("CNF-005", rel(root, path), line, f"forbidden gate escape '{token}' (QLT-003)")
                )
    for path in swift_files(root):
        for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            if "swiftlint:disable all" in line or "swift-format-ignore-file" in line:
                violations.append(
                    Violation("CNF-005", rel(root, path), number, "file-wide suppression is a baseline (QLT-003)")
                )
    return violations


def parse_rules(root: Path) -> tuple[dict[str, tuple[str, int, str | None]], list[Violation]]:
    defined: dict[str, tuple[str, int, str | None]] = {}
    violations: list[Violation] = []
    for path in markdown_files(root):
        relative = rel(root, path)
        lines = path.read_text(encoding="utf-8").splitlines()
        headings = [index for index, line in enumerate(lines) if HEADING.match(line)]
        for position, index in enumerate(headings):
            match = HEADING.match(lines[index])
            assert match is not None
            rule_id = match.group(2)
            if rule_id in defined:
                violations.append(
                    Violation("CNF-006", relative, index + 1, f"{rule_id} is defined more than once")
                )
                continue
            end = headings[position + 1] if position + 1 < len(headings) else len(lines)
            status = None
            for line in lines[index + 1 : end]:
                found = STATUS.search(line)
                if found:
                    status = found.group(1)
                    break
            defined[rule_id] = (relative, index + 1, status)
            if status is None:
                violations.append(
                    Violation("CNF-006", relative, index + 1, f"{rule_id} has no 機械強制 status")
                )
    return defined, violations


def matrix_rows(root: Path) -> tuple[dict[str, tuple[int, str]], list[Violation]]:
    path = root / "docs" / "QUALITY_GATES.md"
    if not path.exists():
        return {}, [Violation("CNF-006", "docs/QUALITY_GATES.md", 1, "quality gates document is missing")]
    lines = path.read_text(encoding="utf-8").splitlines()
    try:
        start = next(index for index, line in enumerate(lines) if line.startswith("## 3."))
        end = next(index for index, line in enumerate(lines) if index > start and line.startswith("## 4."))
    except StopIteration:
        return {}, [Violation("CNF-006", "docs/QUALITY_GATES.md", 1, "matrix section is missing")]
    rows: dict[str, tuple[int, str]] = {}
    violations: list[Violation] = []
    for index in range(start, end):
        match = MATRIX_ROW.match(lines[index])
        if match is None:
            continue
        rule_id, status = match.group(1), match.group(2)
        if rule_id in rows:
            violations.append(
                Violation("CNF-006", "docs/QUALITY_GATES.md", index + 1, f"duplicate matrix row {rule_id}")
            )
            continue
        rows[rule_id] = (index + 1, status)
    return rows, violations


def check_documents(root: Path) -> list[Violation]:
    defined, violations = parse_rules(root)
    rows, row_violations = matrix_rows(root)
    violations.extend(row_violations)
    for rule_id, (path, line, status) in defined.items():
        if rule_id not in rows:
            violations.append(Violation("CNF-006", path, line, f"{rule_id} has no matrix row"))
            continue
        if status is not None and rows[rule_id][1] != status:
            violations.append(
                Violation(
                    "CNF-006",
                    path,
                    line,
                    f"{rule_id} body says {status} but the matrix says {rows[rule_id][1]}",
                )
            )
    for rule_id, (line, _status) in rows.items():
        if rule_id not in defined:
            violations.append(
                Violation("CNF-006", "docs/QUALITY_GATES.md", line, f"matrix row {rule_id} has no definition")
            )
    known = set(defined)
    for path in markdown_files(root):
        relative = rel(root, path)
        for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            for match in ID_REF.finditer(line):
                if match.group(1) not in known:
                    violations.append(
                        Violation("CNF-006", relative, number, f"undefined rule {match.group(1)}")
                    )
    proofs: dict[str, str] = {}
    proof_path = root / "docs" / "quality" / "gate-proofs.md"
    if proof_path.exists():
        for number, line in enumerate(proof_path.read_text(encoding="utf-8").splitlines(), 1):
            match = PROOF_ROW.match(line)
            if match:
                proofs[match.group(1)] = line
    for rule_id, (_line, status) in rows.items():
        if status != "active":
            continue
        proof = proofs.get(rule_id)
        if proof is None:
            violations.append(
                Violation(
                    "CNF-006",
                    "docs/quality/gate-proofs.md",
                    1,
                    f"active rule {rule_id} has no proof line starting '| {rule_id} |'",
                )
            )
        elif "未実測" in proof:
            violations.append(
                Violation(
                    "CNF-006",
                    "docs/quality/gate-proofs.md",
                    1,
                    f"active rule {rule_id} still says 未実測",
                )
            )
    return violations


def imports_allowed(relative: str) -> frozenset[str] | None:
    for prefix, allowed in IMPORTS.items():
        if relative.startswith(prefix):
            return allowed
    return None


def check_imports_and_lexicon(root: Path) -> list[Violation]:
    violations: list[Violation] = []
    for path in swift_files(root):
        relative = rel(root, path)
        allowed = imports_allowed(relative)
        raw_lines = path.read_text(encoding="utf-8").splitlines()
        stripped = strip_comments(path.read_text(encoding="utf-8"))
        if allowed is not None:
            for number, line in enumerate(stripped.splitlines(), 1):
                if "import" not in line:
                    continue
                match = IMPORT_LINE.match(line.strip())
                if match is None:
                    violations.append(
                        Violation("CNF-009", relative, number, "import is not a single allowed form")
                    )
                    continue
                module = match.group(1)
                if module not in allowed:
                    violations.append(
                        Violation(
                            "CNF-009",
                            relative,
                            number,
                            f"import {module} is outside the allowlist for this target",
                        )
                    )
        code = stripped
        if not relative.startswith("Sources/nene-delve/"):
            for pattern in TIME_PATTERNS:
                for match in re.finditer(pattern, code):
                    violations.append(
                        Violation(
                            "ARC-007",
                            relative,
                            line_number(code, match.start()),
                            "time, randomness, locale, or the environment is read outside nene-delve",
                        )
                    )
        for pattern, rule in (
            (r"\bunsafeBitCast\b", "SWF-009"),
            (r"\bunsafeDowncast\b", "SWF-009"),
            (r"\bMirror\s*\(", "SWF-009"),
            (r"\bTask\s*\.\s*detached\b", "SWF-013"),
            (r"\bTask\s*\{", "SWF-013"),
            (r"\bpthread_", "SWF-013"),
            (r"\bNSThread\b", "SWF-013"),
        ):
            for match in re.finditer(pattern, code):
                violations.append(
                    Violation(rule, relative, line_number(code, match.start()), "forbidden construct")
                )
        if not relative.startswith("Sources/NeNeDelveTerminal/"):
            for pattern in UNSAFE_POINTERS:
                for match in re.finditer(pattern, code):
                    violations.append(
                        Violation(
                            "SWF-009",
                            relative,
                            line_number(code, match.start()),
                            "unsafe pointer APIs belong only in NeNeDelveTerminal",
                        )
                    )
        for match in re.finditer(r"\bswitch\b", code):
            brace = code.find("{", match.end())
            if brace < 0:
                continue
            depth = 1
            cursor = brace + 1
            while cursor < len(code) and depth:
                if code[cursor] == "{":
                    depth += 1
                elif code[cursor] == "}":
                    depth -= 1
                cursor += 1
            body = code[brace + 1 : cursor - 1]
            base = line_number(code, brace + 1)
            for offset, line in enumerate(body.splitlines()):
                if re.match(r"\s*(@unknown\s+)?default\s*:", line) or re.match(
                    r"\s*case\s+_\s*(:|where\b|$)", line
                ):
                    violations.append(
                        Violation(
                            "SWF-002",
                            relative,
                            base + offset,
                            "default or case _ disables exhaustiveness",
                        )
                    )
        marker = re.compile(rf"\b({TASK_WORD}|{FIXME_WORD})\b(.*)$")
        for number, line in enumerate(raw_lines, 1):
            found = marker.search(line)
            if found and not re.search(r"#\d+", found.group(2)):
                violations.append(
                    Violation("CNF-008", relative, number, f"{found.group(1)} requires an issue number")
                )
    return violations


def parse_graph_file(text: str) -> dict[str, list[str]]:
    graph: dict[str, list[str]] = {}
    for line in text.splitlines():
        stripped = line.split("#", 1)[0].strip()
        if not stripped or ":" not in stripped:
            continue
        name, rest = stripped.split(":", 1)
        graph[name.strip()] = rest.split()
    return graph


def parse_package_targets(text: str) -> dict[str, list[str]]:
    targets: dict[str, list[str]] = {}
    for match in TARGET_DECL.finditer(text):
        deps = re.findall(r"\"([^\"]+)\"", match.group(2))
        targets[match.group(1)] = deps
    return targets


def check_graph(root: Path) -> list[Violation]:
    graph_path = root / "eng" / "module-graph.txt"
    package_path = root / "Package.swift"
    violations: list[Violation] = []
    if not graph_path.exists() or not package_path.exists():
        return [Violation("ARC-002", "eng/module-graph.txt", 1, "module graph or package manifest is missing")]
    graph = parse_graph_file(graph_path.read_text(encoding="utf-8"))
    package = package_path.read_text(encoding="utf-8")
    targets = parse_package_targets(package)
    if set(graph) != set(targets):
        violations.append(
            Violation(
                "ARC-002",
                "Package.swift",
                1,
                f"targets {sorted(targets)} do not match module graph {sorted(graph)}",
            )
        )
    for name, deps in graph.items():
        if targets.get(name) != deps:
            violations.append(
                Violation(
                    "ARC-002",
                    "Package.swift",
                    1,
                    f"{name} dependencies {targets.get(name)} do not match {deps}",
                )
            )
    if ".plugin(" in package:
        violations.append(Violation("SWF-009", "Package.swift", 1, "build plugins are not allowed"))
    return violations


def check_dependencies(root: Path) -> list[Violation]:
    package_path = root / "Package.swift"
    allow_path = root / "eng" / "dependency-allowlist.txt"
    rules_path = root / "docs" / "CODING_RULES.md"
    violations: list[Violation] = []
    if not package_path.exists() or not allow_path.exists():
        return [Violation("QLT-011", "eng/dependency-allowlist.txt", 1, "allowlist or manifest is missing")]
    package = package_path.read_text(encoding="utf-8")
    urls = PACKAGE_URL.findall(package)
    allowed = [
        line.strip()
        for line in allow_path.read_text(encoding="utf-8").splitlines()
        if line.strip() and not line.strip().startswith("#")
    ]
    if set(urls) != set(allowed):
        violations.append(
            Violation(
                "QLT-011",
                "Package.swift",
                1,
                f"package URLs {urls} do not match the allowlist {allowed}",
            )
        )
    rules = rules_path.read_text(encoding="utf-8") if rules_path.exists() else ""
    for url in allowed:
        if url not in rules:
            violations.append(
                Violation("QLT-011", "docs/CODING_RULES.md", 1, f"allowlist URL {url} is missing from the rules table")
            )
    resolved = root / "Package.resolved"
    if not urls and resolved.exists():
        violations.append(
            Violation("QLT-011", "Package.resolved", 1, "a lockfile exists while the allowlist is empty")
        )
    if urls and not resolved.exists():
        violations.append(
            Violation("QLT-011", "Package.resolved", 1, "dependencies exist but Package.resolved is missing")
        )
    return violations


def referenced_corpus(root: Path) -> str:
    seeds = [root / "Makefile"]
    workflow = root / ".github" / "workflows"
    if workflow.exists():
        seeds.extend(sorted(workflow.glob("*.yml")))
    text = ""
    seen: set[Path] = set()
    queue = [path for path in seeds if path.exists()]
    while queue:
        path = queue.pop()
        if path in seen or not path.is_file():
            continue
        seen.add(path)
        body = path.read_text(encoding="utf-8")
        text += "\n" + body
        for candidate in root.rglob("*"):
            if not candidate.is_file() or skipped(candidate.relative_to(root)):
                continue
            relative = rel(root, candidate)
            if relative in body and candidate not in seen and candidate.suffix in {".py", ".sh"}:
                queue.append(candidate)
    return text


def check_config_wiring(root: Path) -> list[Violation]:
    violations: list[Violation] = []
    listing = root / "eng" / "required-configs.txt"
    if not listing.exists():
        return [Violation("CNF-007", "eng/required-configs.txt", 1, "required config list is missing")]
    corpus = referenced_corpus(root)
    for number, line in enumerate(listing.read_text(encoding="utf-8").splitlines(), 1):
        name = line.split("#", 1)[0].strip()
        if not name:
            continue
        if not (root / name).exists():
            violations.append(Violation("CNF-007", name, 1, "declared config does not exist"))
        if name not in corpus:
            violations.append(
                Violation(
                    "CNF-007",
                    "eng/required-configs.txt",
                    number,
                    f"{name} is not referenced by the Makefile or a script it runs",
                )
            )
    return violations


def check_workflow_shape(root: Path) -> list[Violation]:
    violations: list[Violation] = []
    directory = root / ".github" / "workflows"
    files = sorted(directory.glob("*.yml")) if directory.exists() else []
    if len(files) != 1:
        return [Violation("QLT-001", ".github/workflows", 1, "expected exactly one workflow")]
    text = files[0].read_text(encoding="utf-8")
    relative = rel(root, files[0])
    if "make check" not in text:
        violations.append(Violation("QLT-001", relative, 1, "workflow does not run make check"))
    for token in ("swiftlint", "swift-format", "swift test", "swift build", "conformance.py"):
        if token in text:
            violations.append(
                Violation("QLT-001", relative, 1, f"workflow contains quality logic '{token}'")
            )
    if "contents: read" not in text:
        violations.append(Violation("QLT-001", relative, 1, "workflow permissions are not contents: read"))
    for token in (
        "ready_for_review",
        "synchronize",
        "edited",
        "github.event.pull_request.draft == false",
    ):
        if token not in text:
            violations.append(Violation("QLT-012", relative, 1, f"workflow is missing '{token}'"))
    return violations


def check_hook(root: Path) -> list[Violation]:
    path = root / ".githooks" / "commit-msg"
    if not path.exists():
        return [Violation("GIT-003", ".githooks/commit-msg", 1, "commit-msg hook is missing")]
    text = path.read_text(encoding="utf-8")
    if "eng/commit_message.py" not in text:
        return [
            Violation(
                "GIT-003",
                ".githooks/commit-msg",
                1,
                "hook does not call eng/commit_message.py",
            )
        ]
    return []


def check_version_pin(root: Path, check_toolchain: bool) -> list[Violation]:
    path = root / ".swift-version"
    if not path.exists():
        return [Violation("QLT-001", ".swift-version", 1, "Swift version file is missing")]
    version = path.read_text(encoding="utf-8").strip()
    violations: list[Violation] = []
    corpus_paths = [root / "Makefile", root / "Package.swift"]
    corpus_paths.extend(sorted((root / "eng").glob("*.sh")))
    workflow = root / ".github" / "workflows"
    if workflow.exists():
        corpus_paths.extend(sorted(workflow.glob("*.yml")))
    for candidate in corpus_paths:
        if not candidate.exists():
            continue
        if version and version in candidate.read_text(encoding="utf-8"):
            violations.append(
                Violation(
                    "QLT-001",
                    rel(root, candidate),
                    1,
                    f"Swift version {version} is duplicated outside .swift-version",
                )
            )
    if check_toolchain:
        proc = subprocess.run(
            ["swift", "--version"],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
        )
        if version not in proc.stdout:
            violations.append(
                Violation(
                    "QLT-001",
                    ".swift-version",
                    1,
                    f"swift --version does not contain {version}",
                )
            )
    return violations


def entry_points(root: Path) -> list[Violation]:
    violations: list[Violation] = []
    found: list[tuple[str, int]] = []
    for path in swift_files(root):
        for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            if line.strip() == "@main":
                found.append((rel(root, path), number))
    if len(found) != 1 or not found[0][0].startswith("Sources/nene-delve/"):
        where = found[0][0] if found else "Sources/nene-delve"
        line = found[0][1] if found else 1
        violations.append(
            Violation("CNF-011", where, line, f"expected exactly one @main in Sources/nene-delve, found {len(found)}")
        )
    return violations


def check_product_tests(root: Path) -> list[Violation]:
    makefile = root / "Makefile"
    if not makefile.exists():
        return [Violation("QLT-007", "Makefile", 1, "Makefile is missing")]
    lines = makefile.read_text(encoding="utf-8").splitlines()
    check_line = next((line for line in lines if line.startswith("check:")), "")
    dependencies = check_line.split(":", 1)[1].split() if ":" in check_line else []
    tests = root / "Tests"
    has_tests = tests.is_dir() and any(tests.rglob("*.swift"))
    recipe = "swift test -Xswiftc -warnings-as-errors"
    text = "\n".join(lines)
    if has_tests:
        violations: list[Violation] = []
        if "test" not in dependencies:
            violations.append(
                Violation("QLT-007", "Makefile", 1, "Tests exist but check does not depend on test")
            )
        if recipe not in text:
            violations.append(
                Violation(
                    "QLT-007",
                    "Makefile",
                    1,
                    "swift test must run with -warnings-as-errors",
                )
            )
        return violations
    if "test" in dependencies:
        return [
            Violation(
                "QLT-007",
                "Makefile",
                1,
                "check depends on test, but Tests has no Swift file and swift test then exits 1",
            )
        ]
    return []


def check(root: Path, *, today: date | None = None, check_toolchain: bool = False) -> list[Violation]:
    current = today or date.today()
    defined, _ = parse_rules(root)
    violations: list[Violation] = []
    violations += check_names(root)
    violations += check_one_declaration(root)
    violations += check_suppressions(root, current)
    violations += check_waiver_ledger(root, current, set(defined))
    violations += check_baseline(root)
    violations += check_documents(root)
    violations += check_imports_and_lexicon(root)
    violations += check_graph(root)
    violations += check_dependencies(root)
    violations += check_config_wiring(root)
    violations += check_workflow_shape(root)
    violations += check_hook(root)
    violations += check_version_pin(root, check_toolchain)
    violations += check_product_tests(root)
    violations += entry_points(root)
    return violations


def strip_rule_prefix(message: str) -> str:
    # 検証器の戻り値は既に規則 ID で始まる。描画側がもう一度付けるので、ここは本文だけにする。
    head, separator, tail = message.partition(": ")
    if separator and head.startswith(("GIT-", "ARC-", "SWF-", "QLT-", "CNF-")):
        return tail
    return message


def check_pull_request(event: dict, subjects: list[str], branch: str) -> list[Violation]:
    pull = event.get("pull_request")
    if not isinstance(pull, dict):
        return []
    violations: list[Violation] = []
    title = str(pull.get("title") or "")
    error = commit_message.validate_subject(title)
    if error is not None:
        violations.append(Violation("GIT-003", "pull_request.title", 1, strip_rule_prefix(error)))
    body = str(pull.get("body") or "")
    if "Closes #" not in body:
        violations.append(Violation("GIT-001", "pull_request.body", 1, "PR body must contain Closes #N"))
    branch_error = commit_message.validate_branch(branch)
    if branch_error is not None:
        violations.append(Violation("GIT-002", "pull_request.head", 1, strip_rule_prefix(branch_error)))
    for subject in subjects:
        subject_error = commit_message.validate_subject(subject)
        if subject_error is not None:
            violations.append(
                Violation("GIT-003", "commit", 1, strip_rule_prefix(subject_error) + f" ({subject})")
            )
    return violations


def git_subjects(root: Path, base: str, head: str) -> list[str]:
    proc = subprocess.run(
        ["git", "log", "--format=%s", f"{base}..{head}"],
        cwd=root,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )
    if proc.returncode != 0:
        raise RuntimeError(proc.stdout.strip())
    return [line for line in proc.stdout.splitlines() if line.strip()]


def main() -> int:
    root = Path.cwd()
    violations = check(root, check_toolchain=True)
    event_path = os.environ.get("GITHUB_EVENT_PATH")
    if event_path:
        payload = json.loads(Path(event_path).read_text(encoding="utf-8"))
        pull = payload.get("pull_request") or {}
        head = ((pull.get("head") or {}).get("sha")) or "HEAD"
        base = ((pull.get("base") or {}).get("sha")) or ""
        branch = ((pull.get("head") or {}).get("ref")) or ""
        try:
            subjects = git_subjects(root, base, head) if base else []
        except RuntimeError as exc:
            violations.append(Violation("GIT-003", "commit", 1, f"git log failed: {exc}"))
            subjects = []
        violations += check_pull_request(payload, subjects, branch)
    if violations:
        for violation in violations:
            print(violation.render())
        print(f"conformance: {len(violations)} violation(s)", file=sys.stderr)
        return 1
    print("conformance: ok")
    return 0


if __name__ == "__main__":
    sys.exit(main())
