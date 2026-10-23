# 用語集 — NeNe Delve

> Status: normative（規範）/ 2026-10-23 初版
> ここに載っている語は、コード、ドキュメント、Issue で同じ意味で使う。同義語を発明しない。

| 語 | 意味 | 型／場所 |
| --- | --- | --- |
| 階層（floor） | 地下へ潜った段。表示は B1F、B2F のように深いほど数字が増える | Phase 3 で Core の値にする |
| 迷路種（maze kind） | 1 つの階層で選ぶ迷路の閉じた種類 | Phase 3 で Core の enum にする |
| シード（seed） | 同じ値なら同じ迷路、同じ走り、同じフレームになる入力 | 合成ルートだけが乱数源へ渡す |
| テーマ（theme） | 色の組。キーで循環して切り替える | 合成ルートの入力。描画は Render と Terminal |
| 結果（outcome） | 期待される成功と失敗を表す閉じた型 | `*Outcome` |
| 拒否理由（rejection） | 結果に添える閉じた理由 | `*Rejection` |
| ポート（port） | 中核が外の世界を使うための型 | `*Port` |
| アダプタ（adapter） | ポートの実装 | この製品では合成ルートと Terminal |
| 合成ルート | 依存を結ぶ唯一の場所 | `Sources/nene-delve/` |
| セル格子 | 描く直前のセルの並び。端末を知らない | NeNeDelveRender |
| 隔離区画 | 可変性を許した場所 | ARC-005 の表 |
| 規約検査（conformance） | このリポジトリ固有の自作ゲート | `eng/conformance.py` |
| waiver | 1 つの規則に対する期限付きの狭い例外 | `docs/waivers/WVR-NNNN-*.md` |
| 機械強制の状態 | active / planned / 不能 / 不採用 | `docs/QUALITY_GATES.md` の強制マトリクス |
| negative proof | ゲートが意図した規則で落ちることの実測 | `docs/quality/gate-proofs.md` |

## 使ってはいけない語

`Manager`、`Helper`、`Util`、`Utils`、`Common` を型名の語尾に使わない（SWF-010）。
役割を語る名前が思いつかないときは、その型が 2 つの責務を持っている可能性が高い。
