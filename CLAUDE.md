# CLAUDE.md — NeNe Delve

Claude Code / AI エージェントがこのリポジトリで作業するための中核ハンドブック。
簡潔な英語版の入口は [AGENTS.md](AGENTS.md)。詳細の正本は `docs/` にあり、ここには複製しない。

---

## 0. まず読むもの

production コードに触れる前に、次を読む。

1. [docs/ARCHITECTURE_CONSTITUTION.md](docs/ARCHITECTURE_CONSTITUTION.md) — 憲章（ARC）
2. [docs/PROJECT_LAYOUT.md](docs/PROJECT_LAYOUT.md) — モジュールと依存方向
3. [docs/CODING_RULES.md](docs/CODING_RULES.md) — Swift 規約（SWF）
4. [docs/QUALITY_GATES.md](docs/QUALITY_GATES.md) — いま何が機械で守られているか（QLT / CNF）
5. [docs/DEVELOPMENT_WORKFLOW.md](docs/DEVELOPMENT_WORKFLOW.md) — 手順
6. [docs/COMMIT_CONVENTIONS.md](docs/COMMIT_CONVENTIONS.md) — Issue、ブランチ、コミット、PR（GIT）
7. [docs/GLOSSARY.md](docs/GLOSSARY.md) — 用語
8. 該当する ADR（`docs/adr/`）と有効な waiver（`docs/waivers/`）

---

## 1. このリポジトリの統治原則

> 一つの意味には一つの正典経路しか無い状態を作り、それを人の記憶ではなく機械に守らせる。

その帰結として、次の 3 つを常に守る。

1. 正典の経路を先に特定してから編集する。局所的に早いという理由で第 2 の経路を作らない（ARC-001、ARC-012）
2. ゲートを弱めて通さない。検査が落ちたらコードを直す。閾値、除外、重大度を触るのは ADR 相当の判断（QLT-010）
3. planned を active と書かない。未実装の強制を実装済みに見せるのは、この規約体系で信頼を壊す行為である（[ADR 0001](docs/adr/0001-strictness-is-mechanically-enforced.md)）

---

## 2. このプロジェクトで間違えやすい所

### 現在時刻を読む場所は 1 つしかない

現在時刻、乱数、既定ロケール、環境変数を読んでよいのは `Sources/nene-delve/` だけである（ARC-007）。
Terminal は Glibc を import できるが、時計と乱数は読めない。テストソースにも同じ禁止がかかる。

### 網羅性検査を殺す分岐を書かない

閉じた選択肢の switch に `default`、`@unknown default`、`case _` を書かない（SWF-002）。
コンパイラはケース漏れを error にするが、`default` は診断を出さない。

### 期待される失敗は例外にしない

検証エラー、見つからない、拒否は閉じた結果型で返す（ARC-010、SWF-005）。この部分はまだ planned である。

### 製品の振る舞いを先に書かない

迷路、描画、端末制御は Phase 3 の別 Issue である。この足場の変更に混ぜない。

### Swift の導入スクリプトは bash で読む

`eng/install-swift.sh` の shebang は `/bin/bash` である。swiftly の `env.sh` は `${PATH//}` を使い、ubuntu の `/bin/sh`（dash）は Bad substitution で終了 2 になる。CI の次のステップは、このプロセスの PATH を継がない。渡すときは `GITHUB_PATH` と `GITHUB_ENV` だけを使う。ubuntu-22.04 では `swiftly install` が `libcurl4-openssl-dev`、`pkg-config`、`python3-lldb-13` を要求して終了 1 になった。パッケージを足す前に、その一覧を変えない。

---

## 3. 検証コマンド

```text
make check
```

これが唯一の完了定義である。ローカルと CI で同じコマンドを使う。
開発中は最も狭い検査を使ってよい。フルゲートは、PR を Draft から Ready にする直前に必ず通す。

`make check` が通っていないものを「できた」と報告しない。
実行していないコマンドの結果を書かない。テストの失敗を隠さない。

---

## 4. 変更の進め方

[docs/DEVELOPMENT_WORKFLOW.md](docs/DEVELOPMENT_WORKFLOW.md) が正本。要約すると次である。

Issue、正典経路の特定、ブランチ、設計を変えるなら先に ADR、最小の実装、テスト、狭い検査、`make check`、規則 ID ごとの自己レビュー、draft の PR、Ready、squash merge。

コミットの形の正本は GIT-003。`type` と `scope` は英語、説明は日本語、末尾に `(#N)`。

---

## 5. 完了報告の形

```text
Issue / 規則 ID:
変更したファイルと振る舞い:
実行した検証コマンドと結果:
ドキュメント・スキーマの変更:
Waivers: none | WVR-NNNN
残るリスク:
```

調査だけを頼まれたときは、編集、コミット、push、PR 作成、外部状態の変更を行わない。

---

## 6. いまの状況

現在のタスクは [docs/todo/current.md](docs/todo/current.md)。GitHub Issue が正で、そこは要約。
タイプ B の縦切りは起動する。タイプ A と演出はまだ無い。
