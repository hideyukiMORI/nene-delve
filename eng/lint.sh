#!/bin/sh
# SwiftLint の規則名を、このリポジトリの規則 ID に対応づける。
# 道具の診断文には ID が無いので、失敗したときだけここで足す。
set -eu
cd "$(dirname "$0")/.."
out=$(mktemp)
status=0
.tools/swiftlint lint --strict --config .swiftlint.yml Sources Package.swift >"$out" 2>&1 || status=$?
cat "$out"
if [ "$status" -ne 0 ]; then
  # 規則名だけの一致は、腐った disable の説明文に force_unwrapping が出るため使わない。
  if grep -Eq 'Force Unwrapping Violation|Force Cast Violation|Force Try Violation|Implicitly Unwrapped Optional Violation' "$out"; then
    echo "SWF-004: SwiftLint rejected a force unwrap, force cast, force try, or implicitly unwrapped optional"
  fi
  if grep -Eq 'Cyclomatic Complexity Violation|Function Body Length Violation|Function Parameter Count Violation|Nesting Violation' "$out"; then
    echo "SWF-012: SwiftLint rejected a complexity limit"
  fi
  if grep -Eq 'Superfluous Disable Command Violation' "$out"; then
    echo "SWF-015: SwiftLint rejected a superfluous disable"
  fi
fi
rm -f "$out"
exit "$status"
