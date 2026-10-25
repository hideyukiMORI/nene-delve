enum HudNear {
  static func text(_ row: [HudCell], _ column: Int) -> Bool {
    var reach = 1
    while reach <= 1 {
      if spoken(row, column - reach) || spoken(row, column + reach) {
        return true
      }
      reach += 1
    }
    return false
  }

  private static func spoken(_ row: [HudCell], _ column: Int) -> Bool {
    if column < 0 || column >= row.count {
      return false
    }
    return row[column].kind == .text || row[column].kind == .spark
  }
}
