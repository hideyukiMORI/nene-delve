#!/bin/sh
# このクローンだけで commit-msg フックを有効にする。グローバル設定は変えない。
set -eu
cd "$(dirname "$0")/.."
git config --local core.hooksPath .githooks
echo "core.hooksPath=$(git config --local core.hooksPath)"
