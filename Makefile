# NeNe Delve の唯一の完了定義は `make check`（QLT-001）。
# CI はこのターゲットを呼ぶだけで、品質判断をワークフローに書かない。
# 振る舞いの Swift テストはまだ無い。2026-10-23 に
# `swift test -Xswiftc -warnings-as-errors` は
# `error: no tests found; create a target in the 'Tests' directory` で終了した。
# Tests に .swift が増えたら、check の依存へ test を戻し、
# レシピは `swift test -Xswiftc -warnings-as-errors` にする。QLT-007 が見る。

.PHONY: check tools conformance format lint build bootstrap

check: tools conformance format lint build

tools:
	eng/install-swiftlint.sh

conformance:
	python3 -m unittest discover -s eng -p '*_test.py'
	python3 eng/conformance.py

format:
	eng/format.sh

lint:
	eng/lint.sh

build:
	swift build -Xswiftc -warnings-as-errors || { echo "QLT-002: swift build failed with warnings as errors"; exit 1; }

bootstrap:
	eng/bootstrap.sh
