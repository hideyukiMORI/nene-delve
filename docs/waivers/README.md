# 規則の waiver

waiver は、1 つの名前のある機械規則に対する、期限付きで最小範囲の例外である。
別のアーキテクチャではない。方針を変えるものでもない。

Swift の `swiftlint:disable` と `swift-format-ignore` は、言語が封じない。
だから台帳を持つ。理由と規則 ID が無い抑制は CNF-003 が落とす。期限切れの active は CNF-004 が落とす。

## 原則

- waiver は最後の手段である。先に正典の実装経路を試す
- 1 つの規則、1 つの理由、可能な限り小さい範囲に閉じる
- Issue、担当、作成日、期限を持つ
- コードの抑制の直前行と PR 本文の両方から参照する
- 期限切れの waiver はゲートを落とす（CNF-004）
- 恒久化した waiver は、コードを直して消すか、規則を変える ADR に置き換える

lint の baseline、ディレクトリ単位の除外、全面抑制は禁止であり、waiver でも許可できない（QLT-003、CNF-005）。
ファイル全体の `swiftlint:disable` と `swift-format-ignore-file` も、waiver があっても禁止である（SWF-015）。

## waiver で緩められないもの

依存方向、単一のゲート、警告はエラー、依存の再現性。これらを緩めるなら ADR でも足りず、新しい規則として議論する。

## 命名

```text
WVR-NNNN-short-kebab-title.md
```

`0000-template.md` を複製し、下の索引に追加する。Scope はリポジトリ相対のパスと宣言名で書く。
抑制の直前行には `// Waiver: WVR-NNNN` を置く。

## 有効な waiver の索引

有効な waiver は無い。

| Waiver | 規則 | Scope | 解除条件 | 期限 |
| --- | --- | --- | --- | --- |
| （なし） | | | | |
