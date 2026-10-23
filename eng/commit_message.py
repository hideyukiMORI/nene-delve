#!/usr/bin/env python3
"""GIT-003。件名の形はフックと CI と単体テストが同じ関数を呼ぶ。"""

from __future__ import annotations

import argparse
import re
import sys

SUBJECT = re.compile(
    r"^(feat|fix|docs|refactor|test|build|ci|chore)"
    r"(?:\([a-z0-9]+(?:-[a-z0-9]+)*\))?!?: "
    r"(.+) \(#(\d+)\)$"
)
JAPANESE = re.compile(r"[\u3040-\u30ff\u3400-\u9fff]")
BRANCH = re.compile(r"^(feat|fix|docs|refactor|test|build|ci|chore)/\d+-[a-z0-9-]+$")
MAX_SUBJECT = 100


def validate_subject(subject: str) -> str | None:
    if subject != subject.strip():
        return "GIT-003: subject has leading or trailing whitespace"
    if len(subject) > MAX_SUBJECT:
        return f"GIT-003: subject is {len(subject)} characters; the maximum is {MAX_SUBJECT}"
    match = SUBJECT.fullmatch(subject)
    if match is None:
        return (
            "GIT-003: subject must be "
            "<type>(<scope>): <日本語の説明> (#<issue>)"
        )
    if JAPANESE.search(match.group(2)) is None:
        return "GIT-003: the explanation must be Japanese"
    return None


def validate_branch(name: str) -> str | None:
    if BRANCH.fullmatch(name) is None:
        return (
            "GIT-002: branch must be "
            "<type>/<issue>-<short-kebab-summary>"
        )
    return None


def subject_from_message(text: str) -> str:
    for line in text.splitlines():
        if line.strip():
            return line
    return ""


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument("--message")
    source.add_argument("--file")
    args = parser.parse_args(argv)
    if args.file is not None:
        text = open(args.file, encoding="utf-8").read()
        subject = subject_from_message(text)
    else:
        subject = args.message
    error = validate_subject(subject)
    if error is not None:
        print(error, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
