# いまのタスク — NeNe Delve

> GitHub Issue が正。ここは要約であり、チェックリストをタスク状態として扱わない。
> 更新は実測でだけ行う。

## 段階

| 段階 | 状態 |
| --- | --- |
| Phase 0 言語の実測 | 2026-10-23 に実施。抜粋は `docs/quality/phase0-results.json` |
| Phase 1 文書とゲートの足場 | `make check` が終了コード 0（2026-10-23、この作業木） |
| Phase 2 negative proof | `docs/quality/gate-proofs.md` に記録した規則だけを active にした |
| Phase 3 縦切り 1 本 | タイプ A（部屋と通路）とタイプ B が階のシードで選ばれる。壁は開いた床に接する一筆、踏破は `.`。宝箱とテーマ切替はまだ無い |

## 動くもの

- 2026-10-24 13:56 に `make check` は終了コード 0。内訳は unittest 24 件、`conformance: ok`、swift-format、SwiftLint 0 件（51 files）、Swift Testing（Core 19、Render 8、Terminal 3）、`swift build -Xswiftc -warnings-as-errors` 成功
- 同じ実行で `swift test -Xswiftc -warnings-as-errors` は終了コード 0
- 端末でないとき、実行ファイルは `端末ではありません` を 1 行出して終了コード 1。不明な起動オプションは `不明な起動オプションです` で終了コード 1
- 80 列 24 行の疑似端末で `--seed 1` を 6 秒見ると、HUD 1 行に階層・通算・この階・日時・シード・`NEON GRID` が出て、壁は `+` `-` `|`、踏んだ床は `.`、走者は `@`。`q` で終了コード 0
- 同じ大きさでシード `18446744073709551615` は 1 行目に全桁が出て、`NEON GRID` は 2 行目。40 列 16 行では日時とシードが 2 行目に欠けずに出る
- 一歩は 5×5 で 80ms、79×21 で 28ms
- `--seed 1` と `--seed 7` の 1 階は部屋と通路。13:55 の 80 列 24 行と 110 列 36 行で、部屋は一筆の枠、踏破は `.`、階段は白地、走者は `@`。厚い岩の `+++++` は消えた。`--seed 9` の升目も `+` `-` `|` のまま。`q` で終了コード 0
- PR #2 は `MERGED`（`mergedAt` `2026-10-23T16:10:28Z`、merge commit `c4834cf084b241a6eccbc7de6cb2e75e7bf2d700`）。Issue #1 は `CLOSED`（`closedAt` `2026-10-23T16:10:30Z`）

## 動かないもの

- 宝箱、湖、モンスター、テーマ 10 種、`t` / `T`、落とし穴、ワープ、ボス階は無い
- カバレッジ閾値は未設定（QLT-009）
- ruleset `protect-main`（id 25729406）の必須 check context は `check`。head `59ff3a5` で `mergeStateStatus` は `CLEAN` だった。GIT-004 と QLT-012 は planned のまま。単一ゲートは GitHub を見ない
- CI run 39972426876 は success。それより前の 39971534377、39971963866、39972237751 は Install Swift で落ちた。経過は `docs/quality/gate-proofs.md` の冒頭

## 次の 1 手

宝箱・湖・モンスター、テーマ 10 種と `t` / `T` を、1 つずつ別の Issue で足す。実機の Windows Terminal での見た目は、まだ施主の画面では見ていない。
