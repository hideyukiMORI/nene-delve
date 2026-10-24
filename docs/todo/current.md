# いまのタスク — NeNe Delve

> GitHub Issue が正。ここは要約であり、チェックリストをタスク状態として扱わない。
> 更新は実測でだけ行う。

## 段階

| 段階 | 状態 |
| --- | --- |
| Phase 0 言語の実測 | 2026-10-23 に実施。抜粋は `docs/quality/phase0-results.json` |
| Phase 1 文書とゲートの足場 | `make check` が終了コード 0（2026-10-23、この作業木） |
| Phase 2 negative proof | `docs/quality/gate-proofs.md` に記録した規則だけを active にした |
| Phase 3 縦切り 1 本 | タイプ B だけ。起動して探索し、階段で次の階へ進む。タイプ A と演出はまだ無い |

## 動くもの

- 2026-10-24 に `make check` は終了コード 0。内訳は unittest 24 件、`conformance: ok`、swift-format、SwiftLint 0 件、Swift Testing（Core 13、Render 2、Terminal 3）、`swift build -Xswiftc -warnings-as-errors` 成功
- 同じ実行で `swift test -Xswiftc -warnings-as-errors` は終了コード 0
- 端末でないとき、実行ファイルは `端末ではありません` を 1 行出して終了コード 1。不明な起動オプションは `不明な起動オプションです` で終了コード 1
- 80 列 24 行の疑似端末で `--seed 1` を起動すると、代替画面に入り壁と走者を描く。`q` とバイト 0x03 のどちらも、代替画面とカーソルを戻して終了コード 0
- PR #2 は `MERGED`（`mergedAt` `2026-10-23T16:10:28Z`、merge commit `c4834cf084b241a6eccbc7de6cb2e75e7bf2d700`）。Issue #1 は `CLOSED`（`closedAt` `2026-10-23T16:10:30Z`）

## 動かないもの

- タイプ A、宝箱、湖、モンスター、テーマ 10 種、`t` / `T`、遊び心の演出は無い
- カバレッジ閾値は未設定（QLT-009）
- ruleset `protect-main`（id 25729406）の必須 check context は `check`。head `59ff3a5` で `mergeStateStatus` は `CLEAN` だった。GIT-004 と QLT-012 は planned のまま。単一ゲートは GitHub を見ない
- CI run 39972426876 は success。それより前の 39971534377、39971963866、39972237751 は Install Swift で落ちた。経過は `docs/quality/gate-proofs.md` の冒頭

## 次の 1 手

施主に端末でタイプ B を見てもらう。見た目と速さのあと、タイプ A、宝箱・湖・モンスター、テーマ 10 種と `t` / `T` を、1 つずつ別の Issue で足す。
