# アーキテクチャ憲章 — NeNe Delve

> Status: normative（規範）/ 2026-10-23 初版
> 判断の根拠は [ADR 0001](adr/0001-strictness-is-mechanically-enforced.md)。
> 本書が沈黙している領域は [CODING_RULES.md](CODING_RULES.md) と Swift の公式言語モードに従う。

---

## 0. この文書の読み方

**すべての規則は「機械強制」の状態を持つ。**

| 表記 | 意味 |
| --- | --- |
| **active** | 違反すると `make check` が落ちる。人の記憶に依存しない |
| **planned** | 規範だが、まだ機械が見ていない。この行に触れる変更は PR で明示的に自己レビューする |
| **不能** | 言語・道具の仕様上、機械では塞げない。塞げないことを明記して残す |
| **不採用** | 検討して採らなかった。理由を必ず併記する |

機械が見ていない規則を active と書かない。どの規則がいまどの状態かの正本は
[QUALITY_GATES.md](QUALITY_GATES.md) の強制マトリクスであり、文書整合検査が
「本書に定義があるのにマトリクスに行が無い」状態を拒否する。

### 強制の実体は 5 層ある

| 層 | 実体 | 守るもの |
| --- | --- | --- |
| コンパイラ | Swift 6、`-warnings-as-errors`、`ExistentialAny` | 網羅性の一部、未使用、可視性、`any` |
| ビルドのモジュールグラフ | `eng/module-graph.txt` と `Package.swift` | ターゲット間の依存方向 |
| 字句の禁止 | `eng/conformance.py` | 時刻・乱数・非網羅の switch・unsafe・並行の入口 |
| 静的解析 | SwiftLint（名前を挙げた規則だけ）と swift-format | 強制アンラップ、複雑度、空白 |
| 規約検査 | `eng/conformance.py`（Python 標準ライブラリだけ） | 名前、ファイル、抑制、文書、import、入口 |

同じ規則を 2 つの道具で二重に設定しない。swift-format の NeverForceUnwrap は採らない。強制アンラップは SwiftLint だけが見る。

### Swift がどこまで届いたか

出典は [quality/phase0-results.json](quality/phase0-results.json)（2026-10-23、Swift 6.4.1、glibc 2.35）。
先行言語の列は、公開の比較としてここに要約する。

| 規則 | Kotlin | Go | Rust | C# | Java | **Swift（本リポジトリの実測）** |
| --- | --- | --- | --- | --- | --- | --- |
| 不正状態を表現不能に・網羅性 | ある | 無い | ある | ある | ある | 不十分。ケース漏れは error。`default` と `case _:` は診断無し。`@unknown default` の既知ケース漏れは warning のままで `-warnings-as-errors` がエラーにしない |
| 公開状態は不変 | ある | 無い | ある | ある | ほぼある | 不十分。`let` と `private(set)` は代入を拒否する。`public var` と class の `public var` は通る |
| `null` の意味は一つ | 不十分 | 不十分 | ある | ある | 不十分 | 不十分。本コンパイルでは未初期化 `let` が error（`-typecheck` だけでは出ない）。非 Optional への `nil` は error。IUO と強制アンラップは通る。空 struct の `Marker()` は通る |
| 非公開コンストラクタ＋唯一のファクトリ | ある | 不十分 | ある | ある | ある | 不十分。`private init` は他ファイル・他モジュールから不可。明示 init が無い public struct の memberwise は internal（他モジュールは不可、同一モジュールの他ファイルは可）。`unsafeBitCast` は private init を迂回する |
| 決定性（時刻・乱数・環境を読ませない） | planned | planned | ある | ある | ある | 不十分。Foundation / Glibc / Dispatch は依存宣言なしで import できる。`Date()` は import が要る。`Int.random`、`SystemRandomNumberGenerator`、`ContinuousClock`、`SuspendingClock` は標準ライブラリだけでコンパイルできる。no_std 相当は無い |
| 依存方向は物理的 | ある | ある | ある | ある | ある | ターゲット間は有る（`no such module` / `cyclic dependency`）。標準モジュールは漏れる |
| 抑制は例外であって道具ではない | waiver 台帳 | 理由必須 | forbid 層 | 全面禁止 | waiver 台帳 | 不十分。コンパイラに警告抑制の pragma は無い。`-suppress-warnings` は未使用の warning を隠す。`swift-format-ignore` と `swiftlint:disable`（ファイル全体を含む）は理由なしで効く。腐った disable は `superfluous_disable_command` が落とす。waiver 台帳で補う |

穴が残ることを書かずに厳格さを主張しない。塞げなかったものは第 1 節と [CODING_RULES.md](CODING_RULES.md) に planned または 不能 として残す。

---

## 1. 憲章規則

理念は次の一文である。

> 一つの意味には一つの正典経路しか無い状態を作り、それを人の記憶ではなく機械に守らせる。

### ARC-001 — 一つの意味に一つの正典経路

一つの意味には、正典となる型・所有者・振る舞いの経路がちょうど 1 つ存在する。
並行するサービス、同義の別モデル、アダプタ固有の業務ロジック、同じ概念の別名を作らない。
置き換えが必要なら、呼び出し側の移行と旧経路の削除を同じ変更で行う。

- 機械強制: **planned**（意味が同じかは機械が判定できない）
- 補助: CNF-001 が、役割の分からない第 2 経路の温床になる語尾を拒否する

### ARC-002 — 依存方向は物理的である

依存は [PROJECT_LAYOUT.md](PROJECT_LAYOUT.md) と `eng/module-graph.txt` に従う。
`Package.swift` のターゲット依存がグラフと 1 文字でも違えば検査が落とす。循環は許さない。
標準ライブラリのモジュール（Foundation、Glibc、Dispatch）は依存宣言なしで import できる。そこは ARC-002 の範囲外であり、CNF-009 が import の許可リストで塞ぐ。

- 機械強制: **active**（`eng/conformance.py` がグラフと `Package.swift` の不一致を落とす）

### ARC-003 — 中核はプラットフォームから独立している

NeNeDelveCore は端末・ファイル・ネットワーク・現在時刻・既定ロケール・既定タイムゾーンを知らない。
NeNeDelveRender はセル格子だけを知り、端末を知らない。
プラットフォームの入口は合成ルート `Sources/nene-delve/` に寄せる。端末装置そのものは NeNeDelveTerminal に閉じる。

Foundation のように依存を宣言しなくても import できるモジュールは、ビルドグラフでは塞げない。
import の許可リストは CNF-009 が落とす。発火した ID が ARC-003 ではないので、この規則自体は planned のままにする。

- 機械強制: **planned**

### ARC-004 — 状態には唯一の所有者がいる

| 状態 | 意味 | 所有者 | 変更経路 |
| --- | --- | --- | --- |
| 階の世界 | 迷路、走行、出来事、階層の値 | NeNeDelveCore | 合成ルートが次の値を作って置き換える |
| セル格子 | 描くためのセル | NeNeDelveRender | Core の値から計算する |
| 端末モード | termios と代替画面 | NeNeDelveTerminal | 入場と、必ず対になる復元 |
| テーマ、シード、時計 | 起動時の入力と経過 | nene-delve | 引数と、合成ルートのループ変数 |

同じ事実を 2 つのモジュールに独立して持たない。派生値は再計算する。

- 機械強制: **planned**

### ARC-005 — 可変性は隔離区画にのみ存在する

外から見える Core と Render の値は不変にする。可変な状態を持ってよいのは次だけである。

| 区画 | 何が可変か | なぜ必要か |
| --- | --- | --- |
| NeNeDelveTerminal | termios と、差分描画のための直前フレーム | 端末は装置であり、値にできない |
| nene-delve | いまの階を指すループ変数 | プロセスが潜り続けるため |

区画を増やすときは、この表と ADR を先に変える。

- 機械強制: **planned**

### ARC-006 — 合成は明示的である

依存を結んでよいのは実行ファイル `nene-delve` だけである。サービスロケータ、リフレクションによる発見、暗黙のシングルトンを使わない。
プロセスの終了コードを扱ってよいのも合成ルートだけである。起動できなかった理由を出すなら 1 行だけとし、ログの手段にしない。

`@main` がちょうど 1 つであることを CNF-011 が見る。リフレクションの `Mirror` は SWF-009 が見る。
「合成が明示的か」全体は、その 2 つでは判定できない。

- 機械強制: **planned**

### ARC-007 — 既定で決定的である

現在時刻、乱数、既定ロケール、既定タイムゾーン、環境変数、プロセス状態を直接読んでよいのは `Sources/nene-delve/` だけである。
NeNeDelveTerminal は Glibc を import できるが、時計と乱数は読めない。テストソースにも同じ禁止を適用する。

検査は字句である。コメントは読み飛ばす。文字列を分割して書けば通る。AST ではない。
禁止する綴りは次である。

`ContinuousClock`、`SuspendingClock`、`SystemRandomNumberGenerator`、`.random(`、`Date`、`ProcessInfo`、`getenv`、`clock_gettime`、`gettimeofday`、`arc4random`、`Locale`、`TimeZone`、`Calendar`、`FileManager`、`CommandLine`、`time(`、`fopen`、`URLSession`。

- 機械強制: **active**（`eng/conformance.py` が合成ルート以外の上記の綴りを落とす。字句であり、文字列の分割は通る）

### ARC-008 — 境界は一度だけ検証する

外から来た値（起動引数、端末の大きさ、キー）は、最初の自前の境界で検証し、Core の型へ変換する。
検証前の生の値を Core へ流さない。

- 機械強制: **planned**

### ARC-009 — 永続化の契約は版を持つ

この製品は保存しない。永続化モジュールは作らない。保存形式を足すときは、この規則に従って版と移行を先に決め、モジュール一覧に節を 1 つ足す。節を 2 つに分けて同じモジュールを二重に書かない。

- 機械強制: **planned**（永続化が無いので、検査する対象も無い）

### ARC-010 — 期待される結果は型で表す

期待される失敗は閉じた結果型で返す。`nil`、`Bool`、文字列、汎用の `Error` で複数の業務的な結果を表さない。
例外はプログラム上の欠陥に限る。Optional を失敗の意味に使うことの検査は、まだ機械に無い（SWF-005）。

- 機械強制: **planned**

### ARC-011 — UI は状態を描き、意図を発行する

NeNeDelveRender は Core の値をセル格子に写す。テーマの選択、階の遷移、乱数を Render に置かない。
NeNeDelveTerminal はセル格子を端末へ差分で書く。迷路の意味を Terminal に置かない。

- 機械強制: **planned**

### ARC-012 — アーキテクチャは利便性に優先する

道具の近道やライブラリの便利機能が、状態の所有者とモジュールグラフを迂回することを許さない。
アーキテクチャが間違っているなら ADR で変える。ユーティリティを装った局所的な例外を作らない。

- 機械強制: **不能**（判断そのものが対象。QLT-010 の手続きで残す）

---

## 2. 強制を置く順番

1. 言語の型、可視性、網羅性
2. SwiftPM のターゲット依存
3. `-warnings-as-errors` と `ExistentialAny`
4. 字句と import の禁止
5. SwiftLint と swift-format
6. `eng/conformance.py`
7. CI は `make check` を呼ぶだけ
8. まだ自動化できない判断だけをレビューへ

レビューだけの強制は planned としてマトリクスに残す。
