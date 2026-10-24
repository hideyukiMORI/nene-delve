# モジュール構成と依存規則 — NeNe Delve

> Status: normative（規範）/ 2026-10-23 初版
> パッケージルート: リポジトリ直下の `Package.swift`（SwiftPM。Xcode プロジェクトは置かない）

モジュールグラフはアーキテクチャの一部である。機械可読な正本は `eng/module-graph.txt` で、
規約検査が `Package.swift` の依存と突き合わせる（ARC-002）。

---

## 1. 承認されたモジュール

```text
nene-delve
    合成ルート。時計、シード、端末の実装を結ぶ。終了コードを持ってよい唯一の場所

NeNeDelveTerminal
    セル格子を ANSI の差分で書く。termios、SIGWINCH、キー。Glibc に触れてよい

NeNeDelveRender
    Core の値をセル格子にする。端末を知らない

NeNeDelveCore
    迷路、走行、出来事、階層。値だけ。時刻、乱数源、端末、Foundation を知らない
```

永続化モジュールは無い。時刻のアダプタは独立したターゲットにせず、合成ルート `nene-delve` が担う。
同じ責務の節を 2 つ並べない。

製品の型は各ターゲットのディレクトリに置く。Phase 0〜2 のマーカー型は置き換えた。

---

## 2. 許可された依存グラフ

```text
NeNeDelveCore:
    （ターゲット依存は空）

NeNeDelveRender:
    NeNeDelveCore

NeNeDelveTerminal:
    NeNeDelveRender

nene-delve:
    NeNeDelveCore NeNeDelveRender NeNeDelveTerminal
```

ここに無いターゲット依存は禁止である。とくに次は禁止する。

- Core から Render、Terminal、実行ファイルへ
- Render から Terminal、実行ファイルへ
- Terminal から Core へ（Render 経由で Core の型を使う。直接依存しない）
- Terminal から実行ファイルへ
- 何かから合成ルートへ

標準モジュールはターゲット依存に現れない。import してよいモジュールは次だけである（CNF-009）。

| 場所 | import してよいもの |
| --- | --- |
| `Sources/NeNeDelveCore/` | なし |
| `Sources/NeNeDelveRender/` | NeNeDelveCore |
| `Sources/NeNeDelveTerminal/` | NeNeDelveRender、Glibc |
| `Sources/nene-delve/` | NeNeDelveCore、NeNeDelveRender、NeNeDelveTerminal、Glibc |
| `Tests/` | Testing、上記 3 モジュール（`@testable` も可）。XCTest は不可 |

`import` は 1 行に 1 モジュール。`import func` のような形は拒否する。

---

## 3. 各モジュールの責務

### `NeNeDelveCore`

迷路と走行と階層の値。production のターゲット依存は空のままにする。
現在時刻、`Date`、乱数、ファイル、ネットワークを持たない（ARC-007）。

### `NeNeDelveRender`

Core の値からセル格子を作る。端末 API を呼ばない（ARC-011）。

### `NeNeDelveTerminal`

セル格子を端末へ書く。termios と代替画面の可変状態を持ってよい唯一の描画区画である（ARC-005）。
時計と乱数は、Glibc を import していても禁止である（ARC-007）。
`Unsafe` ポインタと `withUnsafe` は、ioctl のためにこのモジュールだけが使ってよい（SWF-009）。

### `nene-delve`

依存を結ぶ。時計、シード、起動引数を読んでよい唯一の場所である（ARC-007）。
`@main` を置いてよい唯一の場所である（CNF-011）。

---

## 4. ソースの置き場

| 種類 | 置き場 |
| --- | --- |
| production | `Sources/<モジュール名>/`。1 ファイル 1 主要型（SWF-011） |
| テスト | `Tests/`。まだ置いていない。Swift Testing だけを使う（ADR 0002） |
| 検査設定 | `.swift-version`、`.swiftlint.yml`、`eng/module-graph.txt`、`eng/dependency-allowlist.txt`、`eng/tool-versions.json`。読み込まれていることを CNF-007 が見る |
| 生成コード | 置いていない。生成物は `.build/` に出て、コミットしない |
| 開発用バイナリ | `.tools/`。コミットしない。SwiftLint の静的バイナリを `eng/install-swiftlint.sh` が置く |

実行時の外部パッケージは 0 である。足すときは ADR、`eng/dependency-allowlist.txt`、[CODING_RULES.md](CODING_RULES.md) の表を同じ変更で揃える（QLT-011）。
