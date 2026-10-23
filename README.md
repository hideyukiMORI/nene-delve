# NeNe Delve

WSL の Ubuntu 端末で動かす、Swift の CUI スクリーンセーバーです。
迷路を自動で作り、キャラクターが探索しながら地下への階段まで走り、次の階へ潜り続けます。

ライセンスは MIT です。

## いま動くこと

まだスクリーンセーバーとしては動きません。実行ファイルの `main` は空で、すぐに終了します。
迷路、描画、端末制御は、この足場のあとで別の変更として入れます。

ビルドの正本は SwiftPM です。コンパイラの版は `.swift-version` だけが決めます。

```text
swift build -Xswiftc -warnings-as-errors
```

完了の定義は、ローカルと CI で同じ次のコマンドです。

```text
make check
```

## モジュール

依存は次の方向だけです。詳細は [docs/PROJECT_LAYOUT.md](docs/PROJECT_LAYOUT.md)。

```text
NeNeDelveCore → NeNeDelveRender → NeNeDelveTerminal → nene-delve
```

Core は値だけを持ちます。時計、乱数、端末を読んでよいのは実行ファイル `nene-delve` だけです。

## 規約

正本は `docs/` です。入口は [CLAUDE.md](CLAUDE.md) と [AGENTS.md](AGENTS.md)。
機械が見ている規則と、まだ見ていない規則の違いは [docs/QUALITY_GATES.md](docs/QUALITY_GATES.md) の表が正です。

clone したあと、コミット件名の検査を有効にするには次を 1 回実行します。

```text
eng/bootstrap.sh
```
