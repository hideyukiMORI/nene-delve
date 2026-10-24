import Testing

@testable import NeNeDelveCore
@testable import NeNeDelveRender

struct DepthEyeTests {
  @Test func aDeadEndShowsTheSideWalls() {
    let maze = pocket()
    let hits = columns(maze, gaze: Gaze(facing: .north, place: CellPoint(x: 2, y: 2)))
    let center = hits[hits.count / 2]
    let edge = hits[0]
    #expect(center.vertical == false)
    #expect(edge.vertical == true)
    #expect(edge.distance < center.distance)
  }

  @Test func advancingClosesTheFrontWall() {
    let maze = pocket()
    let place = CellPoint(x: 2, y: 2)
    let rest = columns(maze, gaze: Gaze(facing: .north, place: place, along: 0))
    let near = columns(maze, gaze: Gaze(facing: .north, place: place, along: 0.8))
    let middle = rest.count / 2
    #expect(near[middle].distance < rest[middle].distance)
  }

  private func columns(_ maze: Maze, gaze: Gaze) -> [DepthHit] {
    let cast = DepthCaster.Cast(
      maze: maze, origin: DepthEye.origin(gaze), facing: gaze.facing)
    return DepthCaster.columns(cast, count: 21)
  }

  private func pocket() -> Maze {
    let span = GridSpan(width: 5, height: 5)
    var tiles = Array(repeating: Tile.wall, count: span.count)
    let place = CellPoint(x: 2, y: 2)
    let stairs = CellPoint(x: 2, y: 3)
    tiles[span.offset(place)] = .floor
    tiles[span.offset(stairs)] = .stairs
    return Maze(
      span: span, tiles: tiles, ends: MazeEnds(start: place, stairs: stairs), kind: .filledGrid)
  }
}
