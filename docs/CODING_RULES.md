# Swift コーディング規約 — NeNe Delve

> Status: normative（規範）/ 2026-10-23 初版
> 判断の根拠は [ADR 0001](adr/0001-strictness-is-mechanically-enforced.md)。
> 本書は Swift を、このリポジトリで承認した部分集合に狭める。沈黙している領域は Swift の言語モードに従う。

読み方（active / planned / 不能 / 不採用）は [ARCHITECTURE_CONSTITUTION.md](ARCHITECTURE_CONSTITUTION.md) 第 0 節と同じ。
実測の出典は [quality/phase0-results.json](quality/phase0-results.json)。

---

## 1. 型と状態（SWF-0xx）

### SWF-001 — 境界でのプリミティブ執着を禁じる

単位や不変条件を持つ値（階層、シード、セル座標）は専用の型にする。生の `Int` を深いところまで運ばない。

- 機械強制: **planned**（専用型にすべき値かどうかは機械が判定できない）

### SWF-002 — 閉じた選択肢は閉じた型で表し、網羅性検査を殺さない

モードは enum で表す。boolean の組み合わせ、マジック整数、裸の文字列で表さない。

コンパイラは、ケースを書き漏らした switch を error にする。これは同一モジュールでも、library evolution 越しでも同じである。
ただし次は `-warnings-as-errors` でも診断が出ない。

- `default:`
- `case _:`
- 両ケースを書いた `@unknown default`
- 網羅しない `if case`

`@unknown default` で既知ケースを書き漏らすと warning が出るが、`-warnings-as-errors` はそれを error にしない（exit 0）。
library evolution と `@unknown default` を網羅の戦略にすることは不採用である。

規約検査は、switch の波括弧の中の `default:`、`@unknown default:`、`case _:` を拒否する。
`else` と、switch の外にある `_` は拒否しない。辞書の `default:` は switch の外なら拒否しない。switch の中に書くと拒否する。検査は字句であり、文字列を分割すれば通る。

- 機械強制: **active**（`eng/conformance.py` が switch 内の `default` と `case _` を落とす。コンパイラの診断にはこの ID は出ない）

### SWF-003 — 公開状態は不変

公開する格納プロパティは `let` にする。`public var` と、class の公開 var はコンパイルが通る。
`private(set)` は他ファイルからの代入を拒否する。返した `Array` への変更は、コピーに対する操作としてコンパイルできる。

公開 var を機械が拒否する検査は、まだ無い。

- 機械強制: **planned**

### SWF-004 — 強制アンラップと IUO を使わない

`nil` が意味してよいのは「省略可能な値が無い」だけである。無効、未読込、失敗、未知を `nil` で表さない。
非 Optional への `nil` はコンパイラが error にする。強制アンラップ、強制キャスト、`try!`、暗黙アンラップ Optional はコンパイラが通す。

SwiftLint の次の規則だけを error にする。`force_unwrapping`、`force_cast`、`force_try`、`implicitly_unwrapped_optional`。
失敗時のゲート出力に `SWF-004` を足すのは `eng/lint.sh` である。道具の診断文自体にはこの ID は無い。

Optional を失敗の意味に使うことは、この規則の機械範囲に含めない。それは SWF-005 である。

- 機械強制: **active**

### SWF-005 — 期待される失敗は例外で表さない

検証エラー、見つからない、拒否は閉じた結果型で返す。広い `catch` を書かない。Optional や `Bool` で複数の結果を表さない。

これを見る lint は置いていない。SWF-004 の構文禁止とは別の規則として残す。

- 機械強制: **planned**

### SWF-006 — 汎用データバッグを禁じる

`Any`、意味だけのタプル、文字列キーの辞書で型を代用しない。

Swift 6.4.1 の既定では、protocol を `any` 無しで書いても error にならない。
全ターゲットの `Package.swift` は `.enableUpcomingFeature("ExistentialAny")` を付ける。
この設定と `-warnings-as-errors` の組み合わせで、`any` の書き忘れは error になる。
診断文に SWF-006 は含まれない。辞書や `Any` を拒否する検査は無い。規則全体は planned のままにする。

- 機械強制: **planned**

### SWF-007 — 構築が不変条件を守る

不変条件を持つ型は `init` を非公開にし、生成を 1 つのファクトリに集める。ファクトリは想定内の不正入力に対して結果型を返す。

`private init` は他ファイルと他モジュールから呼べない。明示 init が無い public struct の memberwise は internal であり、同一モジュールの他ファイルからは呼べる。
`unsafeBitCast` は private init を迂回する。この迂回は SWF-009 が綴りで拒否する。memberwise の穴を塞ぐ検査は無い。

- 機械強制: **planned**

### SWF-008 — 可視性は最小

既定は internal。他モジュールが使うものだけ `public` にする。テストのためだけに公開しない。テストは `@testable` を使う。

- 機械強制: **planned**

### SWF-009 — 言語マジックを制限する

次の綴りは、どのソースでも拒否する。`unsafeBitCast`、`unsafeDowncast`、`Mirror(`。
`UnsafePointer`、`UnsafeMutablePointer`、`UnsafeRawPointer`、`UnsafeMutableRawPointer`、`UnsafeBufferPointer`、`UnsafeMutableBufferPointer`、`OpaquePointer`、`withUnsafeBytes`、`withUnsafeMutableBytes`、`withUnsafePointer`、`withUnsafeMutablePointer` は、`Sources/NeNeDelveTerminal/` 以外で拒否する。
ビルドプラグイン（`Package.swift` の `.plugin(`）も拒否する。

検査は字句である。ポインタを Terminal に限る理由は、将来の ioctl である。リフレクションはどこでも禁止する。

- 機械強制: **active**

### SWF-010 — 名前が役割を語る

型名の語尾として常に禁止する: `Manager`、`Helper`、`Util`、`Utils`、`Common`。
ディレクトリ名として常に禁止する: `utils`、`helpers`、`managers`、`misc`、`common`。

承認された役割の語尾は `Port`、`Adapter`、`Query`、`Command`、`Handler`、`Policy`、`Factory`、`Codec`、`Mapper`、`Renderer`、`Reducer`、`Outcome`。その型がその役割そのものであるときだけ使う。
`Processor` や `Data` のように文脈次第で妥当な語は機械が拒否しない。

- 機械強制: **active**（CNF-001。診断の ID は CNF-001 で、文面に SWF-010 を含む）

### SWF-011 — 1 ファイル 1 主要宣言

ファイルは、行頭の `struct` / `class` / `enum` / `protocol` / `actor` をちょうど 1 つ持つ。ファイル名はその型名と一致する。
`extension` は数えない。同じ型の extension を同じファイルに足すことはできる。extension だけのファイルは、主要宣言が 0 個なので拒否する。

- 機械強制: **active**（CNF-002。診断の ID は CNF-002 で、文面に SWF-011 を含む）

### SWF-012 — 複雑度に上限を置く

| 指標 | 上限 | 道具 |
| --- | --- | --- |
| 循環的複雑度 | 10 | SwiftLint `cyclomatic_complexity`（warning 10、error 10） |
| 関数の長さ | 40 行 | SwiftLint `function_body_length` |
| ネスト | 型 3、関数 3 | SwiftLint `nesting` |
| 引数の数 | 4 | SwiftLint `function_parameter_count` |

`ignores_case_statements: true` とする。網羅 switch の case は分岐の複雑さに数えない。
bool の制御引数は SwiftLint に対応する規則が無い。SWF-016 として分け、この表の機械範囲に含めない。
閾値を満たすためだけに意味のある処理を割らない。超える必要があるときは ADR にする。
失敗時に `SWF-012` を足すのは `eng/lint.sh` である。

- 機械強制: **active**

### SWF-013 — 並行性の形は一つ

この製品の実行は、合成ルートの同期ループ 1 本である。`Task {`、`Task.detached`、`pthread_`、`NSThread` はどのソースでも拒否する。
`import Dispatch` は許可リストに無いので、発火する ID は CNF-009 である。SWF-013 自身の ID では落とさない。

`@Sendable` クロージャが非 Sendable な class を捕獲すると、Swift 6 の既定で error になる。
`Task { }` で同じ捕獲を書いても、2026-10-23 の実測では診断が出なかった。だから Task はコンパイラに任せず、字句で拒否する。

- 機械強制: **active**

### SWF-014 — 日時・数値・文字集合の扱いを一つに固定する

日時を読むのは合成ルートだけであり、表示用の値は Core の値として渡す。ロケール依存の API を既定ロケールで呼ばない。
文字は UTF-8 の Swift `String` に固定する。

`Locale`、`TimeZone`、`Calendar` の綴りは ARC-007 が合成ルート以外で拒否する。書式の選択そのものは機械が見ない。

- 機械強制: **planned**

### SWF-015 — 抑制は例外であって道具ではない

抑制には、直前の空でない行が `// Waiver: WVR-NNNN` であり、`docs/waivers/` に active で期限前の項目があり、その Rule が抑制する規則と一致するときだけ書ける。
ファイル全体の `swiftlint:disable`、`swiftlint:disable all`、`swift-format-ignore-file` は、waiver があっても拒否する。
対応表に無い SwiftLint 規則の disable も拒否する。対応は次である。

| SwiftLint / swift-format | Rule |
| --- | --- |
| `force_unwrapping` `force_cast` `force_try` `implicitly_unwrapped_optional` | SWF-004 |
| `cyclomatic_complexity` `function_body_length` `function_parameter_count` `nesting` | SWF-012 |
| `swift-format-ignore` | QLT-004 |

`superfluous_disable_command` は disable の対象にしない。腐った disable は SwiftLint が落とす。waiver が無い行は、SwiftLint の前に CNF-003 が落とす。

- 機械強制: **active**（CNF-003 と CNF-004）

### SWF-016 — bool の制御引数を公開しない

公開関数の引数で、挙動のモードを `Bool` にしない。モードは enum にする。
SwiftLint にこの規則は無い。SWF-012 の複雑度とは分けて残す。

- 機械強制: **planned**

---

## 2. 構築と可視性

構築と可視性は SWF-007 と SWF-008 に書いた。節を二重にしない。

---

## 3. 実行時の規律

並行性は SWF-013、日時は SWF-014、抑制は SWF-015 に書いた。

---

## 4. 端末の規約

端末の描き方（代替画面、差分、復元）は製品コードと一緒に Phase 3 で足す。この節の規則 ID はまだ無い。

---

## 5. 依存の方針

新しい実行時依存を足すときは、次の 3 つを同じ変更で揃える。1 つでも欠けたら足していない。

1. ADR を 1 本立てる
2. `eng/dependency-allowlist.txt` に URL を 1 行足す
3. 下の表に 1 行足す

| 依存 | 用途 | 根拠 |
| --- | --- | --- |
| （なし） | 実行時依存は 0 | ADR 0001 |

許可リストが空のあいだ、`Package.resolved` があってはならない。依存が 0 の `swift package resolve` は lock ファイルを作らない（2026-10-23）。
開発用の SwiftLint と swiftly は実行時依存ではない。版と URL と SHA-256 は `eng/tool-versions.json` だけに書く。
Swift コンパイラの版は `.swift-version` だけに書く。

---

## 6. 採用しなかった検査と、その理由

再提案するときは、ここに書かれた理由への反論から始める。

| 検査 | 不採用の理由 |
| --- | --- |
| 散文だけの規約 | 破っても何も起きない |
| 既製の lint だけ | 名前、import、文書整合を見ない |
| SwiftLint の全規則一括 | 整形と矛盾し、道具の機嫌に従うことになる |
| baseline、`disabled_rules`、ディレクトリ除外 | 既存の違反を無かったことにする。CNF-005 が拒否する |
| 実装を書いてから規約を被せる | 違反が溜まり、baseline が必要になる |
| XCTest | 1 回の `swift test` が XCTest と Swift Testing の両方を実行する。枠組みは Swift Testing だけにする（ADR 0002） |
| ncurses | 端末は ANSI と Glibc で足りる。実行時依存を 0 から始める |
| SwiftLint の動的バイナリ | glibc 2.35 では `GLIBC_2.38` と `GLIBCXX_3.4.32` が無く起動しない。同じ zip の静的バイナリを使う |
| swift-format の NeverForceUnwrap | SWF-004 と二重になる |
| `@unknown default` を網羅の戦略にする | 既知ケースの漏れが warning のまま残る |
| `-suppress-warnings` | 未使用の warning を隠す。`-warnings-as-errors` と同時に書くとコンパイラが衝突で落ちる |
| `actions/setup-swift` の v2.4.0 | 既定が Swift 6.1.0 で、`.swift-version` を読まない |
| Xcode プロジェクト | ビルドの正本は SwiftPM の 1 本にする |

---

## 7. 規約に違反したくなったとき

1. まず、規約が間違っている可能性を検討する
2. 規約が正しいなら、設計を変える。抑制で通さない
3. どうしても抑制が要るなら、SWF-015 の最小スコープで waiver を書く
4. 規則そのものを緩めるなら ADR を書く（QLT-010）
