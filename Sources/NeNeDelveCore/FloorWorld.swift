public struct FloorWorld: Equatable, Sendable {
  public let course: FloorCourse
  public let walk: FloorWalk

  public init(course: FloorCourse, walk: FloorWalk) {
    self.course = course
    self.walk = walk
  }
}
