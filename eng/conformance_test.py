#!/usr/bin/env python3
"""正例と反例。ゲートがこのファイルを呼ぶ（QLT-007）。"""

from __future__ import annotations

import tempfile
import unittest
from datetime import date
from pathlib import Path

import conformance


def write_tree(files: dict[str, str]) -> Path:
    root = Path(tempfile.mkdtemp())
    for name, content in files.items():
        path = root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
    return root


class Names(unittest.TestCase):
    def test_forbidden_suffix_fails(self) -> None:
        root = write_tree(
            {"Sources/NeNeDelveCore/TimeHelper.swift": "public enum TimeHelper {}\n"}
        )
        violations = conformance.check_names(root)
        self.assertTrue(any(item.rule_id == "CNF-001" for item in violations))

    def test_plain_name_passes(self) -> None:
        root = write_tree(
            {"Sources/NeNeDelveCore/Floor.swift": "public enum Floor {}\n"}
        )
        self.assertEqual(conformance.check_names(root), [])


class Declarations(unittest.TestCase):
    def test_two_types_fail(self) -> None:
        root = write_tree(
            {
                "Sources/NeNeDelveCore/Floor.swift":
                "public enum Floor {}\npublic enum Extra {}\n"
            }
        )
        violations = conformance.check_one_declaration(root)
        self.assertTrue(any(item.rule_id == "CNF-002" for item in violations))


class Lexicon(unittest.TestCase):
    def test_date_in_core_fails(self) -> None:
        root = write_tree(
            {"Sources/NeNeDelveCore/Floor.swift": "public func probe() -> Double { Date().timeIntervalSince1970 }\n"}
        )
        violations = conformance.check_imports_and_lexicon(root)
        self.assertTrue(any(item.rule_id == "ARC-007" for item in violations))

    def test_clock_in_composition_root_passes(self) -> None:
        root = write_tree(
            {
                "Sources/nene-delve/NeneDelveMain.swift":
                "public func probe() -> ContinuousClock.Instant { ContinuousClock().now }\n"
            }
        )
        self.assertEqual(conformance.check_imports_and_lexicon(root), [])

    def test_foundation_import_in_core_fails(self) -> None:
        root = write_tree(
            {"Sources/NeNeDelveCore/Floor.swift": "import Foundation\npublic enum Floor {}\n"}
        )
        violations = conformance.check_imports_and_lexicon(root)
        self.assertTrue(any(item.rule_id == "CNF-009" for item in violations))

    def test_default_in_switch_fails(self) -> None:
        root = write_tree(
            {
                "Sources/NeNeDelveCore/Floor.swift":
                "public func probe(_ kind: Floor) {\n  switch kind {\n  case .a: break\n  default: break\n  }\n}\npublic enum Floor { case a }\n"
            }
        )
        violations = conformance.check_imports_and_lexicon(root)
        self.assertTrue(any(item.rule_id == "SWF-002" for item in violations))

    def test_task_fails(self) -> None:
        root = write_tree(
            {"Sources/NeNeDelveCore/Floor.swift": "public func probe() {\n  Task { _ = 1 }\n}\n"}
        )
        violations = conformance.check_imports_and_lexicon(root)
        self.assertTrue(any(item.rule_id == "SWF-013" for item in violations))


class Baseline(unittest.TestCase):
    def test_baseline_filename_fails(self) -> None:
        root = write_tree({"lint-baseline.json": "{}\n"})
        violations = conformance.check_baseline(root)
        self.assertTrue(any(item.rule_id == "CNF-005" for item in violations))


class Suppressions(unittest.TestCase):
    def test_disable_without_waiver_fails(self) -> None:
        root = write_tree(
            {
                "Sources/NeNeDelveCore/Floor.swift":
                "// swiftlint:disable:next force_unwrapping\npublic let value = Optional(1)!\n"
            }
        )
        violations = conformance.check_suppressions(root, date(2026, 10, 23))
        self.assertTrue(any(item.rule_id == "CNF-003" for item in violations))

    def test_file_disable_fails(self) -> None:
        root = write_tree(
            {"Sources/NeNeDelveCore/Floor.swift": "// swiftlint:disable force_unwrapping\npublic enum Floor {}\n"}
        )
        violations = conformance.check_suppressions(root, date(2026, 10, 23))
        self.assertTrue(any(item.rule_id == "CNF-003" for item in violations))


class Waivers(unittest.TestCase):
    def test_expired_waiver_fails(self) -> None:
        root = write_tree(
            {
                "docs/waivers/README.md": "| WVR-0001 | SWF-004 | | | 2020-01-01 |\n",
                "docs/waivers/WVR-0001-old.md": """
                # WVR-0001: old
                - Status: active
                - Rule: `SWF-004`
                - Issue: #1
                - Owner: hide
                - Created: 2020-01-01
                - Expires: 2020-01-01
                - Scope: Sources/NeNeDelveCore/Floor.swift#Floor
                """,
            }
        )
        violations = conformance.check_waiver_ledger(root, date(2026, 10, 23), {"SWF-004"})
        self.assertTrue(any(item.rule_id == "CNF-004" for item in violations))


class Documents(unittest.TestCase):
    def test_missing_matrix_row_fails(self) -> None:
        root = write_tree(
            {
                "docs/QUALITY_GATES.md": "## 3. 強制マトリクス\n\n## 4. gate\n",
                "docs/CODING_RULES.md": "### SWF-001 — 例\n\n- 機械強制: **planned**\n",
            }
        )
        violations = conformance.check_documents(root)
        self.assertTrue(any("no matrix row" in item.message for item in violations))

    def test_active_without_proof_fails(self) -> None:
        root = write_tree(
            {
                "docs/QUALITY_GATES.md": (
                    "## 3. 強制マトリクス\n"
                    "| SWF-001 | active | tool |\n"
                    "## 4. gate\n"
                ),
                "docs/CODING_RULES.md": "### SWF-001 — 例\n\n- 機械強制: **active**\n",
                "docs/quality/gate-proofs.md": "| # | 規則 |\n",
            }
        )
        violations = conformance.check_documents(root)
        self.assertTrue(any("no proof line" in item.message for item in violations))


class PullRequest(unittest.TestCase):
    def test_bad_title_fails(self) -> None:
        violations = conformance.check_pull_request(
            {"pull_request": {"title": "fix: add stuff (#1)", "body": "Closes #1", "head": {"ref": "fix/1-add"}}},
            ["fix(core): 足場を直す (#1)"],
            "fix/1-add",
        )
        self.assertTrue(any(item.rule_id == "GIT-003" for item in violations))

    def test_good_event_passes(self) -> None:
        violations = conformance.check_pull_request(
            {
                "pull_request": {
                    "title": "build(policy): 足場を入れる (#1)",
                    "body": "Closes #1\n",
                    "head": {"ref": "build/1-strict-policy-foundation"},
                }
            },
            ["build(policy): 足場を入れる (#1)"],
            "build/1-strict-policy-foundation",
        )
        self.assertEqual(violations, [])


class ProductTests(unittest.TestCase):
    def test_check_without_tests_passes(self) -> None:
        root = write_tree({"Makefile": "check: tools conformance\n"})
        self.assertEqual(conformance.check_product_tests(root), [])

    def test_check_depending_on_missing_tests_fails(self) -> None:
        root = write_tree({"Makefile": "check: tools test\n"})
        violations = conformance.check_product_tests(root)
        self.assertTrue(any(item.rule_id == "QLT-007" for item in violations))

    def test_tests_must_be_wired(self) -> None:
        root = write_tree(
            {
                "Makefile": "check: tools\n",
                "Tests/FloorTests.swift": "import Testing\n",
            }
        )
        violations = conformance.check_product_tests(root)
        self.assertTrue(any(item.rule_id == "QLT-007" for item in violations))


class Graph(unittest.TestCase):
    def test_dependency_mismatch_fails(self) -> None:
        root = write_tree(
            {
                "eng/module-graph.txt": "NeNeDelveCore:\n",
                "Package.swift": '.target(\n  name: "NeNeDelveCore",\n  dependencies: ["NeNeDelveRender"],\n)\n',
            }
        )
        violations = conformance.check_graph(root)
        self.assertTrue(any(item.rule_id == "ARC-002" for item in violations))


if __name__ == "__main__":
    unittest.main()
