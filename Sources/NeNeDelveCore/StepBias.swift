struct StepBias: Equatable, Sendable {
  let lure: CellPoint?
  let avoid: [CellPoint]

  static let none = StepBias(lure: nil, avoid: [])
}
