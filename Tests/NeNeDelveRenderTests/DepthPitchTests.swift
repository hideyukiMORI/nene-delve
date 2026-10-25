import Testing

@testable import NeNeDelveCore
@testable import NeNeDelveRender

struct DepthPitchTests {
  @Test func aCenteredHorizonKeepsTheOldWallBand() {
    #expect(DepthPlane.across(0.2, viewHeight: 19) == former(0.2, viewHeight: 19))
    #expect(DepthPlane.across(1, viewHeight: 19) == former(1, viewHeight: 19))
    #expect(DepthPlane.across(2, viewHeight: 19) == former(2, viewHeight: 19))
    #expect(DepthPlane.across(5, viewHeight: 19) == former(5, viewHeight: 19))
    #expect(DepthPlane.across(40, viewHeight: 19) == former(40, viewHeight: 19))
  }

  @Test func descendingRaisesTheHorizonAndGrowsTheFloor() {
    let still = DepthPlane.across(2, viewHeight: 19)
    let rows = DepthPitch.descend.horizon(frame: 3)
    let raised = DepthPlane.across(2, viewHeight: 19, horizon: rows)
    #expect(DepthPitch.descend.horizon(frame: 0) == 1)
    #expect(rows == 4)
    #expect(raised.top == still.top - rows)
    #expect(raised.bottom == still.bottom - rows)
    #expect(floorRows(raised, viewHeight: 19) == floorRows(still, viewHeight: 19) + rows)
  }

  @Test func ascendingLowersTheHorizonAndGrowsTheCeiling() {
    let still = DepthPlane.across(2, viewHeight: 19)
    let rows = DepthPitch.ascend.horizon(frame: 3)
    let lowered = DepthPlane.across(2, viewHeight: 19, horizon: rows)
    #expect(DepthPitch.ascend.horizon(frame: 0) == -1)
    #expect(rows == -4)
    #expect(lowered.top == still.top - rows)
    #expect(lowered.bottom == still.bottom - rows)
  }

  @Test func theDepthPictureFollowsThePitch() {
    let still = ceiling(horizon: 0)
    let raised = ceiling(horizon: DepthPitch.descend.horizon(frame: 3))
    let lowered = ceiling(horizon: DepthPitch.ascend.horizon(frame: 3))
    #expect(raised < still)
    #expect(lowered > still)
    #expect(floorAboveOldCenter(horizon: 0) == false)
    #expect(floorAboveOldCenter(horizon: DepthPitch.descend.horizon(frame: 3)))
    #expect(ceilingBelowOldCenter(horizon: 0) == false)
    #expect(ceilingBelowOldCenter(horizon: DepthPitch.ascend.horizon(frame: 3)))
  }

  @Test func thePlanIgnoresTheHorizon() {
    let world = corridor()
    #expect(paint(world, view: .plan, horizon: 0) == paint(world, view: .plan, horizon: 4))
  }

  private func floorRows(_ plane: DepthPlane, viewHeight: Int) -> Int {
    max(0, viewHeight - plane.bottom - 1)
  }

  private func former(_ distance: Double, viewHeight: Int) -> DepthPlane {
    let safe = max(distance, 0.000_001)
    let lines = Int((Double(viewHeight) / (3 * safe)).rounded(.down))
    if lines <= 0 {
      let mid = viewHeight / 2
      return DepthPlane(top: mid, bottom: mid - 1)
    }
    let top = max(0, (viewHeight - lines) / 2)
    let bottom = min(viewHeight - 1, top + lines - 1)
    return DepthPlane(top: top, bottom: bottom)
  }

  private func floorAboveOldCenter(horizon: Int) -> Bool {
    painted(horizon: horizon, above: true)
  }

  private func ceilingBelowOldCenter(horizon: Int) -> Bool {
    painted(horizon: horizon, above: false)
  }

  private func painted(horizon: Int, above: Bool) -> Bool {
    let grid = paint(corridor(), view: .depth, horizon: horizon)
    let palette = ThemePalette.palette(.neonGrid)
    let sky = DepthTone.ceiling(palette.ink.wall)
    let floors = floorTones(palette)
    let mid = ScreenText.hudRows + 19 / 2
    var row = ScreenText.hudRows
    let last = above ? mid : grid.span.height
    if !above {
      row = mid + 1
    }
    while row < last {
      let color = grid.cell(column: grid.span.width / 2, row: row).background
      if above && floors.contains(color) {
        return true
      }
      if !above && color == sky {
        return true
      }
      row += 1
    }
    return false
  }

  private func floorTones(_ palette: ThemePalette) -> [Rgb] {
    [
      DepthTone.floor(palette.ink.floor, band: .near),
      DepthTone.floor(palette.ink.floor, band: .mid),
      DepthTone.floor(palette.ink.floor, band: .far),
    ]
  }

  private func ceiling(horizon: Int) -> Int {
    let grid = paint(corridor(), view: .depth, horizon: horizon)
    let tone = DepthTone.ceiling(ThemePalette.palette(.neonGrid).ink.wall)
    let column = grid.span.width / 2
    var rows = 0
    var row = ScreenText.hudRows
    while row < grid.span.height {
      if grid.cell(column: column, row: row).background == tone {
        rows += 1
      }
      row += 1
    }
    return rows
  }

  private func paint(_ world: FloorWorld, view: ViewMode, horizon: Int) -> CellGrid {
    let gaze = Gaze(facing: .north, place: CellPoint(x: 2, y: 4), horizon: horizon)
    return FramePainter.paint(
      world: world,
      clock: clock(),
      look: FrameLook(theme: .neonGrid, view: view, gaze: gaze),
      canvas: GridSpan(width: 31, height: 19 + ScreenText.hudRows)
    )
  }

  private func corridor() -> FloorWorld {
    let span = GridSpan(width: 5, height: 7)
    var tiles = Array(repeating: Tile.wall, count: span.count)
    var y = 1
    while y <= 5 {
      tiles[span.offset(CellPoint(x: 2, y: y))] = .floor
      y += 1
    }
    let here = CellPoint(x: 2, y: 4)
    let stairs = CellPoint(x: 2, y: 6)
    tiles[span.offset(stairs)] = .stairs
    let maze = Maze(
      span: span, tiles: tiles, ends: MazeEnds(start: here, stairs: stairs), kind: .filledGrid)
    let seen = Array(repeating: true, count: span.count)
    let explorer = Explorer(position: here, path: [here], seen: seen)
    return FloorWorld(
      course: FloorCourse(launchSeed: Seed(raw: 1), floor: .first, pace: .explore),
      walk: FloorWalk(
        maze: maze, explorer: explorer, rng: SplitMix64(seed: Seed(raw: 1)), steps: 1),
      fixtures: FloorFixtureField(fixtures: [], wade: 0),
      aim: .explore)
  }

  private func clock() -> HudClock {
    HudClock(
      elapsed: ElapsedPair(totalSeconds: 1, stageSeconds: 1),
      date: WallDate(year: 2026, month: 10, day: 25),
      time: ClockFace(hour: 12, minute: 0, second: 0),
      seed: Seed(raw: 1))
  }
}
