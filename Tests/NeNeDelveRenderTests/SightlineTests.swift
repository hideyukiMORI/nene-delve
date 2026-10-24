import Testing

@testable import NeNeDelveCore
@testable import NeNeDelveRender

struct SightlineTests {
  @Test func openingFacesTheStairsOnTheDominantAxis() {
    let from = CellPoint(x: 2, y: 4)
    #expect(Sightline.opening(from: from, toward: CellPoint(x: 8, y: 5)) == .east)
    #expect(Sightline.opening(from: from, toward: CellPoint(x: 2, y: 9)) == .south)
    #expect(Sightline.opening(from: from, toward: from) == .north)
  }

  @Test func openingLooksThroughAnOpenCellWhenTheStairsAreBehindAWall() {
    let span = GridSpan(width: 5, height: 5)
    var tiles = Array(repeating: Tile.wall, count: span.count)
    let start = CellPoint(x: 1, y: 1)
    let south = CellPoint(x: 1, y: 2)
    let stairs = CellPoint(x: 3, y: 1)
    tiles[span.offset(start)] = .floor
    tiles[span.offset(south)] = .floor
    tiles[span.offset(stairs)] = .stairs
    let maze = Maze(
      span: span, tiles: tiles, ends: MazeEnds(start: start, stairs: stairs), kind: .rooms)
    #expect(Sightline.opening(in: maze, from: start, toward: stairs) == .south)
  }

  @Test func aStepTurnsAndStandingStillKeepsTheGaze() {
    let here = CellPoint(x: 3, y: 3)
    #expect(Sightline.advanced(from: here, to: CellPoint(x: 4, y: 3), facing: .north) == .east)
    #expect(Sightline.advanced(from: here, to: here, facing: .west) == .west)
  }

  @Test func viewModeTogglesBothWays() {
    #expect(ViewMode.plan.toggled() == .depth)
    #expect(ViewMode.depth.toggled() == .plan)
    #expect(ScreenText.viewLine(.plan) == "2D")
    #expect(ScreenText.viewLine(.depth) == "3D")
  }
}
