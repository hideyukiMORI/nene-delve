#!/bin/sh
# QLT-004。整形の正本は swift-format の toolchain 既定。設定ファイルは置かない。
set -eu
cd "$(dirname "$0")/.."
status=0
swift-format lint --strict --recursive Sources Package.swift || status=$?
if [ "$status" -ne 0 ]; then
  echo "QLT-004: swift-format lint --strict failed"
fi
exit "$status"
