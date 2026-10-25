struct StepBias: Equatable, Sendable {
  let lure: CellPoint?
  let avoid: [CellPoint]
  let blocked: CellPoint?

  static let none = StepBias(lure: nil, avoid: [], blocked: nil)

  init(lure: CellPoint?, avoid: [CellPoint], blocked: CellPoint? = nil) {
    self.lure = lure
    self.avoid = avoid
    self.blocked = blocked
  }
}
