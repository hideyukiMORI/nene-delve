# コミットとリポジトリの規約 — NeNe Delve

> Status: normative（規範）/ 2026-10-23 初版

変更の経路は一つである。Issue から、焦点を持つブランチ、一貫したコミット、PR、必須 check、squash merge、同期した `main` へ進む。

読み方（active / planned / 不能 / 不採用）は [ARCHITECTURE_CONSTITUTION.md](ARCHITECTURE_CONSTITUTION.md) 第 0 節と同じ。

---

### GIT-001 — すべての変更は 1 つの Issue から始まる

Issue には問題と根拠、意図する結果、影響する規則 ID とモジュール、受け入れ条件、検証の計画、やらないことを書く。
読み取りだけの調査は Issue 無しでよい。リポジトリの初期化コミットだけが、この形の例外である。

`GITHUB_EVENT_PATH` があるとき、規約検査は PR 本文に `Closes #` が含まれることを見る。
Issue 本文の妥当性は機械が見ない。イベントファイルが無いローカル実行は、PR 本文を見ない。

- 機械強制: **active**

### GIT-002 — ブランチ名は一つの形

```text
<type>/<issue番号>-<short-kebab-summary>
```

`type` は `feat` / `fix` / `docs` / `refactor` / `test` / `build` / `ci` / `chore` のいずれか。
例: `build/1-strict-policy-foundation`。

`GITHUB_EVENT_PATH` があるとき、規約検査は PR の head ブランチ名をこの形で見る。
`main` への直接 push、force push、ブランチ削除の禁止は、リポジトリの ruleset が担う。読み戻しは [quality/gate-proofs.md](quality/gate-proofs.md) 第 4 節。単一ゲートは GitHub を見ないので、その禁止は active と書かない。

- 機械強制: **active**

### GIT-003 — コミットメッセージは一つの形

```text
<type>(<scope>): <日本語の説明> (#<issue番号>)
```

- `type` は GIT-002 と同じ 8 つ。`scope` は小文字と数字とハイフンで、省略できる
- 件名は 100 文字以内。説明にはひらがな、カタカナ、または漢字を 1 文字以上入れる
- 互換性を壊す公開契約の変更は `:` の前に `!` を付けてよい
- 件名には判断を置く

ローカルの `.githooks/commit-msg` と、CI の `make check` が、同じ `eng/commit_message.py` を呼ぶ。
イベントがあるとき、PR タイトルと `base..head` の各件名も同じ関数で見る。
初期化コミット `Initial commit` はこの形ではない。検査は新しいコミットから適用する。

- 機械強制: **active**（`.githooks/commit-msg` と `eng/commit_message.py`。イベントがあるときは PR タイトルと各コミット件名も同じ関数で見る）

### GIT-004 — PR が統合の境界

PR には目的、変更の要約、使った正典経路、規則 ID、検証結果、waiver、残るリスク、`Closes #N` を書く。
1 つの PR に 1 つの作業単位。マージは squash のみ。実装中は draft のままにし、Draft から Ready にする直前に `make check` を通す。

squash のみ、PR 必須、force push 禁止、ブランチ削除禁止の読み戻しは [quality/gate-proofs.md](quality/gate-proofs.md) 第 4 節にある。単一ゲートは GitHub を見ない。ruleset を外しても `make check` は落ちないので、この規則は planned のままである。

- 機械強制: **planned**

---

## フックの導入

フックはリポジトリが所有する。clone 直後に 1 回、次を実行する。

```text
eng/bootstrap.sh
```

これは `git config --local core.hooksPath .githooks` だけを行う。グローバル設定は変えない。
フックは件名の検査だけを行い、フルゲートの代わりにならない。
`--no-verify` でフックは迂回できる。CI が同じ検証器を呼ぶことで、迂回した件名も見える。
