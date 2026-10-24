struct RoomBox: Equatable {
  let origin: CellPoint
  let width: Int
  let height: Int

  var center: CellPoint {
    CellPoint(x: origin.x + width / 2, y: origin.y + height / 2)
  }

  func crowds(_ other: RoomBox) -> Bool {
    let apartX =
      origin.x + width + 1 <= other.origin.x
      || other.origin.x + other.width + 1 <= origin.x
    let apartY =
      origin.y + height + 1 <= other.origin.y
      || other.origin.y + other.height + 1 <= origin.y
    return !apartX && !apartY
  }
}
