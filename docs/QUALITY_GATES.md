# 品質ゲート — NeNe Delve

> Status: normative（規範）/ 2026-10-23 初版
> 本書は「いま何が機械で守られているか」の正本である。
> 規範の本文は [ARCHITECTURE_CONSTITUTION.md](ARCHITECTURE_CONSTITUTION.md) と
> [CODING_RULES.md](CODING_RULES.md) にあり、機械側の実体はこの文書に対応する。

`make check` がローカルと CI の唯一の完了定義である。
個別の道具は診断のために単独で回してよい。その成功は完了の代わりにならない。

---

## 1. ゲートの整合性規則（QLT-0xx）

### QLT-001 — ゲートは一つ

ローカルの検証と CI は同じ 1 つのコマンド `make check` を呼ぶ。CI のワークフローに品質判断のロジックを書かない。
ワークフローが `swiftlint`、`swift-format`、`swift test`、`swift build`、`conformance.py` を含むと、この規則で落とす。
`permissions` は `contents: read` でなければならない。ワークフローファイルはちょうど 1 つである。

Swift コンパイラの版は `.swift-version` だけに書く。`Makefile`、`Package.swift`、`eng/*.sh`、ワークフローにその文字列が現れると落とす。
`swift --version` がその文字列を含まないときも落とす。

- 機械強制: **active**

### QLT-002 — 警告は失敗する

`swift build -Xswiftc -warnings-as-errors` をゲートに入れる。失敗したとき、レシピが `QLT-002` を 1 行足す。
コンパイラの診断文自体にはこの ID は無い。`-suppress-warnings` は CNF-005 がビルド定義から拒否する。

- 機械強制: **active**

### QLT-003 — baseline を作らない

lint、静的解析、アーキテクチャ、依存、テストのいずれにも baseline を持たない。
唯一の例外機構は期限付きの狭い waiver である。

- 機械強制: **active**（CNF-005。診断の ID は CNF-005 で、文面に QLT-003 を含む）

### QLT-004 — 整形は検査であって修復ではない

整形の正本は swift-format の toolchain 既定である。設定ファイルは置かない。インデントは 2、行の長さは 100 で、版は `.swift-version` の toolchain に従う。
ゲートは `swift-format lint --strict` だけを呼び、ソースを書き換えない。`--strict` が無いと指摘は warning のまま exit 0 になる。
失敗したとき `eng/format.sh` が `QLT-004` を足す。診断文自体にはこの ID は無い。

- 機械強制: **active**

### QLT-005 — ローカルと CI は同一

CI が呼ぶのは `make check` だけである。検査を足すときは、先にローカルのゲートに足す。
この規則を QLT-001 と別に機械で二重にしない。ワークフローの形は QLT-001 が見る。

- 機械強制: **planned**

### QLT-006 — アーキテクチャは実行可能

モジュール境界、import、状態の経路のうち、機械が見ているものは ARC-002、CNF-009、ARC-007 に分けて書く。
「アーキテクチャが実行可能である」全体を、この ID だけで active にはしない。

- 機械強制: **planned**

### QLT-007 — カスタムゲートには negative proof が要る

自作の検査は、わざと違反させた入力で意図した規則 ID によって落ち、戻すと `make check` が通るまで信用しない。
証拠は [quality/gate-proofs.md](quality/gate-proofs.md) に記録する。
ゲートは `python3 -m unittest discover -s eng -p '*_test.py'` を `eng/conformance.py` の前に呼ぶ。

振る舞いの Swift テストはまだ無い。2026-10-23 に `swift test -Xswiftc -warnings-as-errors` は
`error: no tests found; create a target in the 'Tests' directory` で失敗した。
そのため `make check` は `swift test` を呼ばない。`Tests/` に Swift ファイルが現れたら、
`check` が `test` に依存し、レシピが `swift test -Xswiftc -warnings-as-errors` を含むことをこの規則が見る。
テストが無いのに `check` が `test` に依存しているときも落とす。

- 機械強制: **active**

### QLT-008 — 振る舞いの変更はテストを伴う

振る舞いを変えたら、いちばん狭い安定した境界にテストを足す。不具合の修正は、可能なら先に落ちる回帰テストを書いてから直す。
カバレッジの下限は置いていない（QLT-009）。この規則を機械で見ていない。

- 機械強制: **planned**

### QLT-009 — カバレッジは下げられない

中核の分岐カバレッジ下限は置いていない。未設定（Phase 3 で実測する）。閾値を発明しない。
置いていない層は「置いていない」と書く。

- 機械強制: **planned**

### QLT-010 — ゲートの弱体化はアーキテクチャ変更

重大度、除外、閾値、モジュール境界、必須 CI ジョブを変えるには明示的な根拠が要る。
MUST 規則を弱める変更には ADR か waiver が要る。無関係な作業を通すために検査を切らない。

- 機械強制: **不能**（判断そのものが対象。PR の手続きで残す）

### QLT-011 — 依存は再現可能

実行時依存の URL は `Package.swift` と `eng/dependency-allowlist.txt` が一致し、許可した URL は本書ではなく [CODING_RULES.md](CODING_RULES.md) の表に現れる。
許可リストが空なら `Package.resolved` は無く、URL があるなら lock ファイルが無ければ落とす。
SwiftLint と swiftly の URL と SHA-256 は `eng/tool-versions.json` だけが持つ。

- 機械強制: **active**

### QLT-012 — 検証の頻度は変更に従う

フルゲートは PR を Draft から Ready にする時点で通す。CI の起動は `ready_for_review` と、draft ではない `synchronize` と `edited` である。
draft のあいだはフルゲートを回さない。head が動いたら Draft に戻して再度 Ready にする。

ワークフローに次の 4 つが揃っていることを検査が見る。`ready_for_review`、`synchronize`、`edited`、`github.event.pull_request.draft == false`。
必須 check と strict up-to-date の読み戻しは [quality/gate-proofs.md](quality/gate-proofs.md) 第 4 節にある。単一ゲートは GitHub を見ないので、この規則は planned のままである。起動条件の 4 文字列を欠くと、この ID で落ちる。

- 機械強制: **planned**

### QLT-013 — 環境依存の主張は正直に名付ける

単体テストは表示サーバや実機を必要としない。単体テストが通ったことを「端末でスクリーンセーバーが動く」証拠として扱わない。
表示を伴う確認は [quality/gate-proofs.md](quality/gate-proofs.md) に環境と手順を書いて別に記録する。Phase 3 までは該当が無い。

- 機械強制: **planned**

---

## 2. 規約検査の規則（CNF-0xx）

汎用の lint が見ない、このリポジトリ固有の規約を `eng/conformance.py` が検査する。依存は Python 標準ライブラリだけである。
検出語のうち、ソースに書くと自分自身を違反にする語は、検査器の中で分割して持つ。テストの故意の違反は `eng/*_test.py` の一時ディレクトリに書き、リポジトリの `Sources/` には置かない。

### CNF-001 — 禁止された総称名

SWF-010 の語尾とディレクトリ名を、`Sources/` と `Tests/` の Swift ファイルに対して拒否する。

- 機械強制: **active**

### CNF-002 — 1 ファイル 1 主要宣言

SWF-011 のとおり、行頭の型宣言がちょうど 1 つで、ファイル名と一致することを見る。

- 機械強制: **active**

### CNF-003 — 抑制には waiver ID が要る

SWF-015 の直前行と、ファイル全体の抑制の禁止を見る。対応の無い SwiftLint 規則の disable も拒否する。

- 機械強制: **active**

### CNF-004 — waiver 台帳の整合

`docs/waivers/` が無ければ落とす。各 `WVR-*.md` は Status、Rule、Issue、Owner、Created、Expires、Scope を持ち、
Rule は定義済みの規則 ID であり、索引 `docs/waivers/README.md` に ID が現れる。
Status が active で Expires を過ぎていれば落とす。ファイル単位の抑制は waiver があっても CNF-003 が拒否する。

- 機械強制: **active**

### CNF-005 — baseline とゲート無力化の禁止

ファイル名に `baseline` を含むファイルを拒否する。
`Makefile`、`Package.swift`、ワークフロー、`eng/*.sh` に `--baseline`、`--write-baseline`、`ignoreFailures`、`disabled_rules`、`-suppress-warnings` が現れると拒否する。
Swift ソースの `swiftlint:disable all` と `swift-format-ignore-file` も拒否する。

- 機械強制: **active**

### CNF-006 — 文書整合

規則の見出しは `##` から `####` で、`ID — ` の形である。見出しごとに機械強制の状態が 1 つ要る。
状態は第 3 節のマトリクス行と一致する。本文が言及する規則 ID は定義が無ければ落とす。
active の規則は [quality/gate-proofs.md](quality/gate-proofs.md) に、行頭が `| ID |` の証明行が要る。その行に「未実測」と書いてあってはならない。
候補表のように ID が 2 列目の行は証明にならない。

- 機械強制: **active**

### CNF-007 — 宣言した検査設定がビルドから読まれている

`eng/required-configs.txt` の各ファイルが存在し、`Makefile` またはワークフローから辿れる `.py` と `.sh` の本文に、その相対パスが現れることを見る。

- 機械強制: **active**

### CNF-008 — TODO と FIXME には Issue 番号

Swift ソースの該当語には、同じ行以降に `#` と数字が要る。Markdown と検査器自身は走査しない。検査器は語を分割して持つ。

- 機械強制: **active**

### CNF-009 — import は許可リストだけ

[PROJECT_LAYOUT.md](PROJECT_LAYOUT.md) の表以外の `import` を拒否する。コメントの中は見ない。
`import` が 1 モジュールの形でなければ拒否する。標準モジュールはターゲット依存に出ないので、この許可リストが ARC-003 の漏れを塞ぐ。発火する ID は CNF-009 であり、ARC-003 ではない。

- 機械強制: **active**

### CNF-011 — 入口は合成ルートに 1 つ

`@main` がちょうど 1 つであり、`Sources/nene-delve/` にあることを見る。ARC-006 の全体はこの規則では判定しない。

- 機械強制: **active**

---

## 3. 強制マトリクス

この表が実装と食い違ったら merge を止める。状態は、発火を [quality/gate-proofs.md](quality/gate-proofs.md) に記録するまで planned または 不能 のままにする。

| 規則 | 状態 | 機械強制の実体 |
| --- | --- | --- |
| ARC-001 | planned | 意味の同一性はレビュー。CNF-001 が語尾だけを見る |
| ARC-002 | active | `eng/module-graph.txt` と `Package.swift` |
| ARC-003 | planned | import の発火 ID は CNF-009。この ID では落とさない |
| ARC-004 | planned | 所有者の表はレビュー |
| ARC-005 | planned | 区画の表はレビュー |
| ARC-006 | planned | 入口の個数は CNF-011。全体はレビュー |
| ARC-007 | active | 合成ルート以外の時刻・乱数・環境の字句 |
| ARC-008 | planned | 境界の一度だけの検証はレビュー |
| ARC-009 | planned | 永続化は無い。対象が無い |
| ARC-010 | planned | 結果型の選択はレビュー。SWF-005 も同じ |
| ARC-011 | planned | 描画と意図の分離はレビュー |
| ARC-012 | 不能 | QLT-010 の手続き |
| SWF-001 | planned | 専用型にすべきかはレビュー |
| SWF-002 | active | switch 内の default と case _ |
| SWF-003 | planned | 公開 var を拒否する検査は無い |
| SWF-004 | active | SwiftLint の force 系。`eng/lint.sh` が ID を足す |
| SWF-005 | planned | Optional を失敗に使うことの検査は無い |
| SWF-006 | planned | ExistentialAny は診断にこの ID を含まない |
| SWF-007 | planned | memberwise の穴は未検査。unsafeBitCast は SWF-009 |
| SWF-008 | planned | 公開の最小化はレビュー |
| SWF-009 | active | unsafeBitCast、Mirror、Terminal 以外のポインタ |
| SWF-010 | active | CNF-001 の文面にこの ID が出る |
| SWF-011 | active | CNF-002 の文面にこの ID が出る |
| SWF-012 | active | SwiftLint の複雑度。bool 引数は SWF-016 |
| SWF-013 | active | Task、pthread_、NSThread。Dispatch は CNF-009 |
| SWF-014 | planned | Locale 等の綴りは ARC-007。書式はレビュー |
| SWF-015 | active | CNF-003 と CNF-004 |
| SWF-016 | planned | bool 制御引数の lint は無い |
| GIT-001 | active | イベントがあるとき本文の Closes |
| GIT-002 | active | イベントがあるとき head ブランチ名 |
| GIT-003 | active | `.githooks/commit-msg` と `eng/commit_message.py` |
| GIT-004 | planned | 読み戻しは gate-proofs 第 4 節。ゲートは GitHub を見ない |
| QLT-001 | active | ワークフローが `make check` だけを呼ぶこと、版の単一性 |
| QLT-002 | active | `swift build -Xswiftc -warnings-as-errors` |
| QLT-003 | active | CNF-005 |
| QLT-004 | active | `swift-format lint --strict` |
| QLT-005 | planned | QLT-001 と二重にしない |
| QLT-006 | planned | 個別規則に分けてあり、この ID はレビュー |
| QLT-007 | active | unittest の結線。Swift のテストターゲットはまだ無い |
| QLT-008 | planned | レビュー |
| QLT-009 | planned | 閾値は未設定 |
| QLT-010 | 不能 | PR の手続き |
| QLT-011 | active | 許可リストと `Package.resolved` の有無 |
| QLT-012 | planned | 起動条件の文字列は検査する。必須 check の読み戻しは gate-proofs 第 4 節 |
| QLT-013 | planned | 実機確認は Phase 3。いま主張しない |
| CNF-001 | active | `eng/conformance.py` |
| CNF-002 | active | `eng/conformance.py` |
| CNF-003 | active | `eng/conformance.py` |
| CNF-004 | active | `eng/conformance.py` |
| CNF-005 | active | `eng/conformance.py` |
| CNF-006 | active | `eng/conformance.py` |
| CNF-007 | active | `eng/conformance.py` |
| CNF-008 | active | `eng/conformance.py` |
| CNF-009 | active | `eng/conformance.py` |
| CNF-011 | active | `eng/conformance.py` |

---

## 4. `make check` に入っている層

| 層 | 目的 | 実体 |
| --- | --- | --- |
| 道具 | SwiftLint の静的バイナリ | `eng/install-swiftlint.sh` が `eng/tool-versions.json` の SHA-256 で置く |
| 検査自身のテスト | 規約検査の正例と反例 | `python3 -m unittest discover -s eng -p '*_test.py'` |
| 規約検査 | このリポジトリ固有 | `eng/conformance.py` |
| 整形 | 文字列としての正本 | `eng/format.sh`（`swift-format lint --strict`） |
| 静的解析 | 強制アンラップと複雑度 | `eng/lint.sh`（SwiftLint `--strict` と `.swiftlint.yml` の `only_rules`） |
| コンパイル | 型、網羅性の一部、警告はエラー | `swift build -Xswiftc -warnings-as-errors` |
| 振る舞いの単体テスト | 置いていない | `swift test` はテストターゲットが無く終了コード 1。QLT-007 が結線を保留している |
| カバレッジ | 置いていない | 閾値は未設定（QLT-009） |
| 依存 | 実行時は 0 | QLT-011。lock ファイルは無いのが正しい |

---

## 5. マージゲート

2026-10-23 の読み戻しは [quality/gate-proofs.md](quality/gate-proofs.md) 第 4 節。単一ゲートはこの API を見ない。応答に rule があることと、push を拒否したことは別である。

ruleset `protect-main`（id 25729406、enforcement `active`、対象 `refs/heads/main`）の rule は `pull_request`、`required_status_checks`、`non_fast_forward`、`deletion` である。`pull_request` の `allowed_merge_methods` は `squash` だけ、承認数は 0。`required_status_checks` の context は `check`、`strict_required_status_checks_policy` は true。run 39972426876 の check run 名が `check` だった。context をそれに合わせたあと、head `59ff3a5` の `mergeStateStatus` は `CLEAN` だった。

同じ読み戻しのリポジトリ設定は、`allow_squash_merge` true、`allow_merge_commit` false、`allow_rebase_merge` false、`delete_branch_on_merge` true、`default_branch` は `main`。

期限切れ waiver は CNF-004 がローカルと CI のゲートで見る。
