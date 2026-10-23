# いまのタスク — NeNe Delve

> GitHub Issue が正。ここは要約であり、チェックリストをタスク状態として扱わない。
> 更新は実測でだけ行う。

## 段階

| 段階 | 状態 |
| --- | --- |
| Phase 0 言語の実測 | 2026-10-23 に実施。抜粋は `docs/quality/phase0-results.json` |
| Phase 1 文書とゲートの足場 | `make check` が終了コード 0（2026-10-23、この作業木） |
| Phase 2 negative proof | `docs/quality/gate-proofs.md` に記録した規則だけを active にした |
| Phase 3 縦切り 1 本 | 未着手。迷路、描画、端末はまだ無い |

## 動くもの

- `make check` は 2026-10-23 に終了コード 0。内訳は unittest 24 件成功、`conformance: ok`、swift-format、SwiftLint 0 件、`swift build -Xswiftc -warnings-as-errors` 成功
- 実行ファイル `.build/out/Products/Debug-linux-x86_64/nene-delve` は空の `main` で終了コード 0

## 動かないもの

- スクリーンセーバーとしては動かない。迷路の生成、描画、端末の制御は無い
- `swift test -Xswiftc -warnings-as-errors` は `error: no tests found` で終了コード 1。テストターゲットが無いのでゲートは呼んでいない
- ruleset `protect-main`（id 25729406）は 2026-10-23 に読み戻した。抜粋は `docs/quality/gate-proofs.md` 第 4 節。GIT-004 と QLT-012 は planned のまま
- CI は 3 回落ちている。39971534377 は dash が `env.sh` を拒否（終了 2）。39971963866 は `swiftly install` が終了 1。39972237751 は `libcurl4-openssl-dev` の 404 で apt-get が終了 100。成功した run はまだ無い

## 次の 1 手

`apt-get update` を足した導入スクリプトの CI を見る。製品の振る舞いは別の Issue で足す。
