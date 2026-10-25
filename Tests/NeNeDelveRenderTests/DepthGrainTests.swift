import Testing

@testable import NeNeDelveCore
@testable import NeNeDelveRender

struct DepthGrainTests {
  @Test func aFarFloorShowsCellCorners() {
    let grid = paint(court())
    let frame = picture(grid)
    #expect(DepthGrain.reach == 4)
    #expect(grains(grid) >= 8)
    #expect(frame.contains(String(ScreenText.grit)))
    #expect(!frame.contains(",,"))
    #expect(!frame.contains(", ,"))
    #expect(!frame.contains(",  ,"))
    #expect(!frame.contains(",   ,"))
    #expect(!frame.contains(",    ,"))
    #expect(!frame.contains(String(ScreenText.dash)))
    #expect(grainInk(grid) == ThemePalette.palette(.neonGrid).ink.wall)
  }

  @Test func aLongHallKeepsAFewCorners() {
    let grid = paint(longLane())
    let count = grains(grid)
    #expect(count > 0)
    #expect(count < 8)
    #expect(!picture(grid).contains(",,"))
  }

  private func longLane() -> Maze {
    let span = GridSpan(width: 15, height: 11)
    var tiles = Array(repeating: Tile.wall, count: span.count)
    var x = 1
    while x <= 12 {
      tiles[span.offset(CellPoint(x: x, y: 5))] = .floor
      x += 1
    }
    let stairs = CellPoint(x: 13, y: 5)
    tiles[span.offset(stairs)] = .stairs
    return Maze(
      span: span, tiles: tiles, ends: MazeEnds(start: CellPoint(x: 1, y: 5), stairs: stairs),
      kind: .filledGrid)
  }

  @Test func aCloseWallLeavesTheFloorBare() {
    let grid = paint(lane())
    #expect(grains(grid) == 0)
  }

  private func paint(_ maze: Maze) -> CellGrid {
    FramePainter.paint(
      world: world(maze), clock: clock(), look: eyed(maze),
      canvas: GridSpan(width: 80, height: 24))
  }

  private func court() -> Maze {
    let span = GridSpan(width: 21, height: 15)
    var tiles = Array(repeating: Tile.wall, count: span.count)
    var y = 1
    while y < span.height - 1 {
      var x = 1
      while x < span.width - 1 {
        tiles[span.offset(CellPoint(x: x, y: y))] = .floor
        x += 1
      }
      y += 1
    }
    let start = CellPoint(x: 2, y: 7)
    let stairs = CellPoint(x: 18, y: 7)
    tiles[span.offset(stairs)] = .stairs
    return Maze(
      span: span, tiles: tiles, ends: MazeEnds(start: start, stairs: stairs), kind: .filledGrid)
  }

  private func lane() -> Maze {
    let span = GridSpan(width: 15, height: 11)
    var tiles = Array(repeating: Tile.wall, count: span.count)
    tiles[span.offset(CellPoint(x: 1, y: 5))] = .floor
    tiles[span.offset(CellPoint(x: 2, y: 5))] = .floor
    let stairs = CellPoint(x: 3, y: 5)
    tiles[span.offset(stairs)] = .stairs
    return Maze(
      span: span, tiles: tiles, ends: MazeEnds(start: CellPoint(x: 1, y: 5), stairs: stairs),
      kind: .filledGrid)
  }

  private func world(_ maze: Maze) -> FloorWorld {
    FloorWorld(
      course: FloorCourse(launchSeed: Seed(raw: 1), floor: .first, pace: .explore),
      walk: FloorWalk(
        maze: maze, explorer: Explorer.begin(maze), rng: SplitMix64(seed: Seed(raw: 1)), steps: 0),
      fixtures: FloorFixtureField(fixtures: [], wade: 0),
      aim: .explore
    )
  }

  private func eyed(_ maze: Maze) -> FrameLook {
    FrameLook(
      theme: .neonGrid, view: .depth, gaze: Gaze(facing: .east, place: maze.start))
  }

  private func clock() -> HudClock {
    HudClock(
      elapsed: ElapsedPair(totalSeconds: 3661, stageSeconds: 5),
      date: WallDate(year: 2026, month: 10, day: 24),
      time: ClockFace(hour: 12, minute: 40, second: 0),
      seed: Seed(raw: 9)
    )
  }

  private func grains(_ grid: CellGrid) -> Int {
    var count = 0
    var row = ScreenText.hudRows
    while row < grid.span.height {
      var column = 0
      while column < grid.span.width {
        if grid.cell(column: column, row: row).glyph == ScreenText.grit {
          count += 1
        }
        column += 1
      }
      row += 1
    }
    return count
  }

  private func grainInk(_ grid: CellGrid) -> Rgb? {
    var row = ScreenText.hudRows
    while row < grid.span.height {
      var column = 0
      while column < grid.span.width {
        let cell = grid.cell(column: column, row: row)
        if cell.glyph == ScreenText.grit {
          return cell.foreground
        }
        column += 1
      }
      row += 1
    }
    return nil
  }

  private func picture(_ grid: CellGrid) -> String {
    var text = ""
    var row = ScreenText.hudRows
    while row < grid.span.height {
      var column = 0
      while column < grid.span.width {
        text.append(grid.cell(column: column, row: row).glyph)
        column += 1
      }
      text.append("\n")
      row += 1
    }
    return text
  }
}
