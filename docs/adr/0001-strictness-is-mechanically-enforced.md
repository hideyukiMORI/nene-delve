# ADR 0001 — 厳格さは機械で強制する

- 状態: 受理
- 日付: 2026-10-23
- Issue: #1
- 影響する規則: 憲章、Swift 規約、品質ゲート、コミット規約のすべて

## 文脈

このリポジトリの規約は、先行する製品で確立した考え方を Swift へ持ち込んだものである。中核は 1 つである。

> 一つの意味には一つの正典経路しか無い状態を作り、それを人の記憶ではなく機械に守らせる。

規約は、破ったときに何も起きなければ、時間とともに腐る。実装が空のうちに検査を入れる。baseline は要らない。

### Swift 6.4.1 で実測したこと

環境は Ubuntu glibc 2.35、`Swift version 6.4.1 (swift-6.4.1-RELEASE)`、target `x86_64-unknown-linux-gnu`、swift-format 6.4.1、SwiftLint 0.65.1 の静的バイナリ。抜粋の正本は [../quality/phase0-results.json](../quality/phase0-results.json)。

網羅性。ケース漏れは error である。

```text
error: switch must be exhaustive
note: add missing case: '.grid'
```

`default:` と `case _:` は `-warnings-as-errors` でも診断が無く exit 0。`@unknown default` で既知ケースを欠くと warning のまま exit 0。`-warnings-as-errors` を付けても exit 0。library evolution 越しでも、ケース漏れは error、`default:` は exit 0、既知ケースを欠く `@unknown default` は warning のままである。

公開状態。`let` への代入は `cannot assign to property: 'column' is a 'let' constant`。`private(set)` は `setter is inaccessible`。`public var` と class の `public var` は exit 0。

null。`-typecheck` では未初期化の `let` が exit 0 で診断無し。同じソースを `-c` すると `error: constant 'value' used before being initialized`。ゲートは本コンパイルを使う。非 Optional への `nil` は error。IUO と強制アンラップは `-warnings-as-errors` でも exit 0。空 struct の `Marker()` は exit 0。引数不足の memberwise は `missing argument for parameter 'column'`。

ファクトリ。他ファイルからの `private init` は `inaccessible due to 'private' protection level`。明示 init が無い public struct は、同一モジュールの他ファイルから memberwise を呼べる。他モジュールからは `inaccessible due to 'internal' protection level`。`unsafeBitCast` による迂回は exit 0。

決定性。依存宣言の無いターゲットで `import Foundation` と `Date()`、`import Glibc`、`import Dispatch` は exit 0。`Int.random`、`ContinuousClock`、`SuspendingClock` は標準ライブラリだけで exit 0。`SystemRandomNumberGenerator().next()` を一時値に呼ぶと mutating の error になるが、`var` に受ければ exit 0。API は存在する。no_std 相当のフラグは無い。

依存方向。依存していないターゲットの import は `error: no such module 'Side'`。`Package.swift` の循環は `cyclic dependency declaration found`。標準モジュールはこの検査を通る。

抑制。未使用 `let` は warning で exit 0。`-warnings-as-errors` では `error: initialization of immutable value 'unused' was never used`。`-suppress-warnings` は同じ未使用を隠して exit 0。両方を同時に渡すと `conflicting options '-warnings-as-errors' and '-suppress-warnings'`。`#pragma warning` は抑制にならず構文エラー。`swift-format lint --strict` は spacing を error にし、`--strict` が無いと warning のまま exit 0。`swift-format-ignore` と `swift-format-ignore-file` は `--strict` でも診断を消す。SwiftLint の `force_unwrapping` は exit 2。`swiftlint:disable:next` とファイル全体の disable は理由なしで exit 0。腐った disable は `superfluous_disable_command` で exit 2。複雑度 11 は `Function should have complexity 10 or less; currently complexity is 11`。`swiftlint lint --help` に `--baseline` がある。

言語モード。裸の protocol 型は Swift 6 と `-warnings-as-errors` でも exit 0。`ExistentialAny` を有効にすると `use of protocol 'P' as a type must be written 'any P'`。`@Sendable` クロージャが class を捕獲すると error。`Task { }` の同じ捕獲は exit 0 であり、Swift 6 が無効である証拠には使わない。

テスト。XCTest と Swift Testing を同じパッケージに置くと、1 回の `swift test` が両方を実行した（exit 0）。Swift Testing だけでも XCTest ランナーが 0 件で先に通った。このリポジトリにテストターゲットが無い状態の `swift test` は `error: no tests found` で exit 1。

依存 0 の `swift package resolve` は exit 0 で、`Package.resolved` は生成されない。

動的 SwiftLint 0.65.1 は `GLIBC_2.38` と `GLIBCXX_3.4.32` が無く exit 1。同じ zip の `swiftlint-static` は `0.65.1` を出して exit 0。

| 先行事例の規則 | Swift（実測） |
| --- | --- |
| 不正状態を表現不能に・網羅性 | 不十分。ケース漏れは error。default と case _ は診断無し |
| 公開状態は不変 | 不十分。let は拒否する。public var は通る |
| null の意味は一つ | 不十分。本コンパイルの未初期化は error。IUO と強制アンラップは通る |
| 非公開コンストラクタと唯一のファクトリ | 不十分。private init は守られる。memberwise と unsafeBitCast が迂回する |
| 中核の決定性を構文的に塞げるか | 不十分。標準ライブラリだけで時計と乱数がコンパイルできる |
| 依存方向をビルドが拒むか | ターゲット間は拒む。標準モジュールは漏れる |
| 抑制を言語で封じられるか | 不十分。pragma は無い。formatter と lint の ignore は理由なしで効く |
| baseline を作る経路が塞がっているか | 言語では塞がらない。SwiftLint に `--baseline` がある |

実装はマーカーと空の `main` だけである。違反ゼロから始められる時点は今だけである。

## 決定

すべての規範規則に機械強制の状態を持たせ、その状態を文書の側で機械検査する。

1. 正本は `docs/ARCHITECTURE_CONSTITUTION.md`、`docs/CODING_RULES.md`、`docs/QUALITY_GATES.md` に置く。状態は active / planned / 不能 / 不採用。planned を active と書かない
2. `make check` を唯一の入口にする。CI は同じコマンドを呼ぶだけにし、ワークフローに品質判断を書かない
3. baseline を持たない。例外は期限付きの狭い waiver だけ
4. 抑制には直前行の waiver ID と台帳を要求する。ファイル全体の抑制は waiver があっても拒否する
5. ゲートを弱める変更は ADR を要する
6. Swift コンパイラの版は `.swift-version` だけが決める。SwiftLint と swiftly のピンは `eng/tool-versions.json` だけが決める
7. active と書く前に、意図した ID で落ちることを `docs/quality/gate-proofs.md` に記録する
8. 規約検査は Python 標準ライブラリだけで書く

モジュールは NeNeDelveCore、NeNeDelveRender、NeNeDelveTerminal、実行ファイル nene-delve の 4 つ。永続化モジュールは作らない。時刻を読んでよいのは実行ファイルだけ。

## 強制

発火を [../quality/gate-proofs.md](../quality/gate-proofs.md) に記録した規則だけを active にした。記録が無い規則は planned のままである。ARC-012 と QLT-010 は 不能。
「planned を勝手に active と書き換えないこと」は、証明行の有無を CNF-006 が見る。意味の正しさまでは機械が見ない。
ruleset の必須 check は、`gh api` で読み戻すまで GIT-004 と QLT-012 を active にしない。

## 結果

得られるもの:

- 規約が自分について嘘をつく経路が、証明行とマトリクスの不一致で塞がる
- 何がいま守られているかを 1 か所で読める
- 規約を緩めるコストが上がる

失うもの:

- 規則を足すたびに本文、マトリクス、検査、証明が同期を要求する
- 字句検査は AST ではないので、文字列の分割で通る

正直に記録しておくこと:

- 網羅性、公開 var、IUO、memberwise、標準モジュールの import、formatter の ignore は、言語だけでは塞がらない
- カバレッジ閾値は置いていない
- 配布コマンドは未実測である
- 緑であることは、規則が良いことの証明ではない。検査対象がまだ小さいことの結果でもある

## 却下した選択肢

| 選択肢 | 却下の理由 |
| --- | --- |
| 散文だけの規約 | 破っても何も起きない |
| 既製の lint だけ | 名前、import、文書を見ない |
| SwiftLint の全規則一括 | 整形と矛盾する |
| baseline を許す | 違反を無かったことにする。`--baseline` は実在する |
| 実装のあとで規約を入れる | 空のうちにしか、baseline 無しでは入れられない |
| XCTest | 1 回の `swift test` が両方の枠組みを実行する。ADR 0002 |
| ncurses | 実行時依存を 0 から始める |
| SwiftLint の動的バイナリ | glibc 2.35 で起動しない |
| swift-format の NeverForceUnwrap | SWF-004 と二重になる |
| `@unknown default` を網羅の戦略にする | 既知ケースの漏れが warning のまま残る |
| `-suppress-warnings` | 未使用の warning を隠す |
| setup-swift の v2.4.0 | 既定が Swift 6.1.0 で、`.swift-version` を読まない |
| Xcode プロジェクト | SwiftPM を唯一のビルドにする |
| 警告を baseline で先送りする | マーカーしか無い今、警告は 0 である |
