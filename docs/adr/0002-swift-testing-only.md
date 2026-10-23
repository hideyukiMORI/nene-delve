# ADR 0002 — テスト枠組みは Swift Testing だけ

- 状態: 受理
- 日付: 2026-10-23
- Issue: #1
- 影響する規則: QLT-007、CNF-009

## 文脈

テスト枠組みは XCTest か Swift Testing のどちらか一つにする、という前提があった。
2026-10-23 に、両方のテストを置いたパッケージで `swift test -Xswiftc -warnings-as-errors` を実行した。終了コードは 0 で、XCTest の `CoreTests.testMarker` が 1 件成功したあとに、Swift Testing の `markerExists()` も成功した。Testing Library の版は 6.4.1 だった。
Swift Testing だけを置いたパッケージでも、XCTest ランナーが 0 件で先に通り、そのあと Swift Testing が 1 件成功した。

枠組みを 2 つ許すと、1 つのコマンドが両方を実行し、どちらが正典か機械が判定できない。

このリポジトリには、まだテストターゲットが無い。同じフラグの `swift test` は `error: no tests found; create a target in the 'Tests' directory` で終了コード 1 だった。意味のない同一性テストは足さない。

## 決定

テストを書くときは Swift Testing だけを使う。`import XCTest` はテストの許可リストに入れない。CNF-009 が落とす。
`make check` は、`Tests/` に Swift ファイルが現れるまで `swift test` を呼ばない。現れたら QLT-007 が、`check` の依存と `-warnings-as-errors` を要求する。

## 強制

- planned: テストファイルがまだ無いので、XCTest の import をこのリポジトリでは発火させていない。許可リストの反例は `eng/conformance_test.py` が一時ディレクトリで持つ
- 不能: ツールチェーンが XCTest ランナー自体を起動すること。0 件なら成功する。禁止できるのは、こちらのソースが XCTest を import しないことまで

## 結果

得られるもの: テストの書き方が 1 つになる。
失うもの: XCTest の既存資産は使わない。いまは資産が無い。

正直に記録しておくこと: ゲートが `swift test` を呼ばないあいだは、振る舞いの回帰は機械が見ない。Phase 3 で最初の振る舞いテストを足すとき、Makefile の結線も同じ変更に含める。

## 却下した選択肢

| 選択肢 | 却下の理由 |
| --- | --- |
| XCTest だけ | 新しいテストの表現が Swift Testing より広い。両方は同時に走ってしまう |
| 両方を許す | 1 コマンドが 2 枠組みを実行し、正典が 2 つになる |
| 空のテストを 1 件足して `swift test` を緑にする | 振る舞いを検証しない。緑が検証に見える |
| `swift test` の失敗を無視してゲートに入れたままにする | 完了定義が常に赤になる |
