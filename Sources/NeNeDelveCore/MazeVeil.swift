/// 階に重ねる修飾。種類とは別で、描画と動く壁だけが読む。
struct MazeVeil: Equatable, Sendable {
  let shade: Bool
  let shifts: [CellPoint]
  let phase: Int

  static let plain = MazeVeil(shade: false, shifts: [], phase: 0)
}
