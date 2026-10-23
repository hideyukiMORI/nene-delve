#!/usr/bin/env python3
"""GIT-003 の正例と反例。"""

from __future__ import annotations

import unittest

import commit_message


class Subject(unittest.TestCase):
    def test_japanese_subject_passes(self) -> None:
        self.assertIsNone(commit_message.validate_subject("build(policy): 足場を入れる (#1)"))

    def test_english_explanation_fails(self) -> None:
        error = commit_message.validate_subject("fix(core): add the floor (#1)")
        self.assertIsNotNone(error)
        self.assertIn("GIT-003", error or "")

    def test_missing_issue_fails(self) -> None:
        error = commit_message.validate_subject("docs: 文書だけ直す")
        self.assertIsNotNone(error)
        self.assertIn("GIT-003", error or "")


class Branch(unittest.TestCase):
    def test_branch_shape(self) -> None:
        self.assertIsNone(commit_message.validate_branch("build/1-strict-policy-foundation"))
        error = commit_message.validate_branch("main")
        self.assertIsNotNone(error)
        self.assertIn("GIT-002", error or "")


if __name__ == "__main__":
    unittest.main()
