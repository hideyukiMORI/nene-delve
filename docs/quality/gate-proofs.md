# ゲート発火の証明 — NeNe Delve

> Status: 記録 / 最終実測 2026-10-23（ローカル）
> 根拠となる規則: QLT-007

検査は、落ちることを見るまで信用しない。下の証明行は、仕込みを入れて実行した出力である。
仕込みは記録のあとで戻した。戻したあとの `make check` は、このファイルを書き終えてから実行し、結果を `docs/todo/current.md` に書く。

環境: Ubuntu glibc 2.35 / Swift 6.4.1 / swift-format 6.4.1 / SwiftLint 0.65.1 static
CI: run 39971534377（head `361e3b1`）は Install Swift が終了 2。`env.sh` の Bad substitution。run 39971963866（head `51e121a`、ubuntu-22.04、2026-10-23）は `swiftly install` が終了 1。要求は `apt-get -y install libcurl4-openssl-dev pkg-config python3-lldb-13`。その直後に `installed successfully` と出ている。成功した run はまだ無い。

文書整合は、行頭が `| 規則ID |` の行だけを active の証明として読む。

---

## 1. 実測結果

### 1-a. active の規則

| 規則 | 最小の違反 | 検証経路 | 実測 |
| --- | --- | --- | --- |
| ARC-002 | Core の依存を NeNeDelveRender にする | `python3 eng/conformance.py` | 終了 1。`ARC-002: Package.swift:1: NeNeDelveCore dependencies ['NeNeDelveRender'] do not match []` |
| ARC-007 | Core に `ContinuousClock().now` を書く | `python3 eng/conformance.py` | 終了 1。`ARC-007: Sources/NeNeDelveCore/NeNeDelveCoreMarker.swift:3: time, randomness, locale, or the environment is read outside nene-delve`。同じ綴りを `Sources/nene-delve/NeneDelveMain.swift` に書くと `conformance: ok` |
| CNF-001 | 型 `TimeHelper` | `python3 eng/conformance.py` | 終了 1。`CNF-001: Sources/NeNeDelveCore/TimeHelper.swift:1: type 'TimeHelper' ends with forbidden suffix Helper (SWF-010)` |
| CNF-002 | 1 ファイルに enum を 2 つ | `python3 eng/conformance.py` | 終了 1。`CNF-002: ... expected one top-level type, found 2 (SWF-011)` |
| CNF-003 | `swiftlint:disable:next` を waiver 無しで書く。別にファイル全体の `swiftlint:disable` | `python3 eng/conformance.py` | 終了 1。`CNF-003: ... suppression requires a previous line '// Waiver: WVR-NNNN' (SWF-015)`。ファイル全体は `file-wide suppression is forbidden (SWF-015)` |
| CNF-004 | Expires が 2020-01-02 の active waiver | `python3 eng/conformance.py` | 終了 1。`CNF-004: docs/waivers/WVR-0001-old.md:1: WVR-0001 expired on 2020-01-02` |
| CNF-005 | `eng/lint-baseline.txt` を置く | `python3 eng/conformance.py` | 終了 1。`CNF-005: eng/lint-baseline.txt:1: baseline files are forbidden (QLT-003)` |
| CNF-006 | マトリクスに無い規則番号の見出しを 1 つ足す | `python3 eng/conformance.py` | 終了 1。診断は `CNF-006: docs/quality/tmp-extra.md:1:` のあとに、その番号と `has no matrix row`。番号をここに再掲すると、未定義の規則としてこのファイル自身が落ちる |
| CNF-007 | `eng/required-configs.txt` に参照されない `eng/not-wired.txt` を足す | `python3 eng/conformance.py` | 終了 1。`CNF-007: eng/required-configs.txt:7: eng/not-wired.txt is not referenced by the Makefile or a script it runs` |
| CNF-008 | `// TODO later` | `python3 eng/conformance.py` | 終了 1。`CNF-008: Sources/NeNeDelveCore/NeNeDelveCoreMarker.swift:4: TODO requires an issue number` |
| CNF-009 | Core に `import Foundation` | `python3 eng/conformance.py` | 終了 1。`CNF-009: Sources/NeNeDelveCore/NeNeDelveCoreMarker.swift:1: import Foundation is outside the allowlist for this target` |
| CNF-011 | Core に 2 つ目の `@main` | `python3 eng/conformance.py` | 終了 1。`CNF-011: Sources/NeNeDelveCore/NeNeDelveCoreMarker.swift:1: expected exactly one @main in Sources/nene-delve, found 2` |
| GIT-001 | PR 本文に `Closes #` が無いイベント | `GITHUB_EVENT_PATH` を置いて `python3 eng/conformance.py` | 終了 1。`GIT-001: pull_request.body:1: PR body must contain Closes #N`。イベントが無い通常の `make check` は PR 本文を見ない |
| GIT-002 | head が `bad-branch` | 同上 | 終了 1。`GIT-002: pull_request.head:1: branch must be <type>/<issue>-<short-kebab-summary>` |
| GIT-003 | 件名 `fix: add stuff (#1)` | `python3 eng/commit_message.py --message ...` と、同じ件名の PR タイトル | 終了 1。`GIT-003: the explanation must be Japanese`。イベント経路は `GIT-003: pull_request.title:1: the explanation must be Japanese` |
| QLT-001 | Makefile に `.swift-version` の文字列を重複させる。別にワークフローの `make check` を `swift test` に変える | `python3 eng/conformance.py` | 終了 1。`QLT-001: Makefile:1: Swift version 6.4.1 is duplicated outside .swift-version`。ワークフローは `workflow does not run make check` と `workflow contains quality logic 'swift test'` |
| QLT-002 | `main` に未使用の `let unused = 1` | `make build` | make の終了コード 2（レシピは 1）。診断は `error: initialization of immutable value 'unused' was never used` で、この文に QLT-002 は無い。レシピが `QLT-002: swift build failed with warnings as errors` を足した |
| QLT-003 | CNF-005 と同じ baseline ファイル | `python3 eng/conformance.py` | 終了 1。診断 ID は CNF-005 で、文面に `QLT-003` が含まれる |
| QLT-004 | `public enum NeNeDelveCoreMarker{` のように空白を崩す | `eng/format.sh` | 終了 1。`error: [Spacing] add 1 space`。診断文に QLT-004 は無く、スクリプトが `QLT-004: swift-format lint --strict failed` を足した |
| QLT-007 | `Tests/FloorTests.swift` を足し、Makefile は変えない | `python3 eng/conformance.py` | 終了 1。`QLT-007: Makefile:1: Tests exist but check does not depend on test`。検査器の単体テストは `make check` が `python3 -m unittest discover -s eng -p '*_test.py'` で実行し、2026-10-23 に 24 件成功 |
| QLT-011 | 空の `Package.resolved` を置く | `python3 eng/conformance.py` | 終了 1。`QLT-011: Package.resolved:1: a lockfile exists while the allowlist is empty` |
| SWF-002 | `switch` の中に `default:` | `python3 eng/conformance.py` | 終了 1。`SWF-002: Sources/NeNeDelveCore/NeNeDelveCoreMarker.swift:6: default or case _ disables exhaustiveness`。辞書の `[1: 2][0, default: 1]` は `conformance: ok`。コンパイラのケース漏れ診断には SWF-002 は出ない |
| SWF-004 | `value!` | `eng/lint.sh` | 終了 2。`Force Unwrapping Violation: Force unwrapping should be avoided (force_unwrapping)` のあとに `SWF-004: SwiftLint rejected a force unwrap, force cast, force try, or implicitly unwrapped optional` |
| SWF-009 | `unsafeBitCast(1, to: Int.self)` | `python3 eng/conformance.py` | 終了 1。`SWF-009: Sources/NeNeDelveCore/NeNeDelveCoreMarker.swift:2: forbidden construct` |
| SWF-010 | CNF-001 と同じ `TimeHelper` | `python3 eng/conformance.py` | 終了 1。診断 ID は CNF-001 で、文面に `SWF-010` が含まれる |
| SWF-011 | CNF-002 と同じ 2 型 | `python3 eng/conformance.py` | 終了 1。診断 ID は CNF-002 で、文面に `SWF-011` が含まれる |
| SWF-012 | if を 11 個、本体 41 行、引数 5 個、型を 4 段、関数を 4 段 | `eng/lint.sh` | いずれも終了 2 で、続けて `SWF-012: SwiftLint rejected a complexity limit`。複雑度は `currently complexity is 11 (cyclomatic_complexity)`。長さは `currently spans 41 lines (function_body_length)`。引数は `it currently has 5 (function_parameter_count)`。ネストは `Types should be nested at most 3 levels deep (nesting)` と `Functions should be nested at most 3 levels deep (nesting)`。if の入れ子 4 段は nesting では落ちなかった |
| SWF-013 | `Task { _ = 1 }` | `python3 eng/conformance.py` | 終了 1。`SWF-013: Sources/NeNeDelveCore/NeNeDelveCoreMarker.swift:2: forbidden construct`。`import Dispatch` の発火 ID は CNF-009 であり、この ID ではない |
| SWF-015 | waiver 無しの disable と、有効 waiver の付いた腐った disable | `python3 eng/conformance.py` と `eng/lint.sh` | waiver 無しは CNF-003 が `(SWF-015)` を含む文で終了 1。有効 waiver（Rule は SWF-004、期限 2026-12-31）の腐った disable は conformance が `conformance: ok`、SwiftLint が終了 2 で `Superfluous Disable Command Violation`、スクリプトが `SWF-015: SwiftLint rejected a superfluous disable`。仕込みの waiver は消した |

### 1-b. 通る側

合成ルートに `ContinuousClock` を書いても ARC-007 は出ない。辞書リテラルの `default:` は SWF-002 を出さない。どちらも 2026-10-23 に `conformance: ok`。

---

## 2. 発火したが active にしていないもの

QLT-012 は、ワークフローから `ready_for_review` を外すと終了 1 で `QLT-012: .github/workflows/ci.yml:1: workflow is missing 'ready_for_review'` だった。
必須 check と strict up-to-date は第 4 節に読み戻した。単一ゲートは GitHub を見ない。ruleset を外しても `make check` は落ちないので、QLT-012 と GIT-004 は planned のままである。

ARC-003 は import の違反を自分の ID では落とさない。Core の `import Foundation` は CNF-009 だった。

---

## 3. 事故から生まれた検査

まだ無い。

---

## 4. リポジトリ設定（ruleset）

2026-10-23 に `GET /repos/hideyukiMORI/nene-delve/rulesets/25729406` と `GET /repos/hideyukiMORI/nene-delve` で読み戻した。ruleset の `created_at` は `2026-10-23T23:37:47.052+09:00`。ここは応答の抜粋であり、push を拒否した実験ではない。check run の名前が context と一致するかは、CI が走ってから確かめる。

| 設定 | 読み戻した値 | 出所 |
| --- | --- | --- |
| ruleset id / name / enforcement | 25729406 / protect-main / active | ruleset |
| target / include | branch / `refs/heads/main`（exclude は空） | ruleset |
| bypass_actors / current_user_can_bypass | 空 / `never` | ruleset |
| pull_request | `required_approving_review_count` 0、`allowed_merge_methods` は `squash` のみ、`dismiss_stale_reviews_on_push` false、`require_code_owner_review` false、`require_last_push_approval` false、`required_review_thread_resolution` false、`required_reviewers` 空 | ruleset |
| pull_request の追加フィールド | `require_extra_approval_for_unattributed_changes` true。送信した本文には無く、応答に付いていた | ruleset |
| required_status_checks | context `CI / check`、`integration_id` 15368、`strict_required_status_checks_policy` true、`do_not_enforce_on_create` false | ruleset |
| non_fast_forward | rule として在る | ruleset |
| deletion | rule として在る | ruleset |
| allow_squash_merge | true | リポジトリ設定 |
| allow_merge_commit | false | リポジトリ設定 |
| allow_rebase_merge | false | リポジトリ設定 |
| delete_branch_on_merge | true | リポジトリ設定 |
| default_branch | main | リポジトリ設定 |
