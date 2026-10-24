# NeNe Delve の唯一の完了定義は `make check`（QLT-001）。
# CI はこのターゲットを呼ぶだけで、品質判断をワークフローに書かない。
# Tests に Swift があるあいだ、check は test に依存する（QLT-007）。

.PHONY: check tools conformance format lint test build bootstrap

check: tools conformance format lint test build

tools:
	eng/install-swiftlint.sh

conformance:
	python3 -m unittest discover -s eng -p '*_test.py'
	python3 eng/conformance.py

format:
	eng/format.sh

lint:
	eng/lint.sh

test:
	swift test -Xswiftc -warnings-as-errors

build:
	swift build -Xswiftc -warnings-as-errors || { echo "QLT-002: swift build failed with warnings as errors"; exit 1; }

bootstrap:
	eng/bootstrap.sh
