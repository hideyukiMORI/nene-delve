import NeNeDelveCore

public enum FramePainter {
  public static func paint(world: FloorWorld, clock: HudClock, look: FrameLook, canvas: GridSpan)
    -> CellGrid
  {
    if canvas.width <= 0 || canvas.height <= 0 {
      return CellGrid(span: canvas, cells: [])
    }
    let palette = ThemePalette.palette(look.theme)
    let shown = revealed(world, frame: look.dug)
    var job = Job(
      palette: palette, canvas: canvas,
      cells: Array(repeating: palette.blank, count: canvas.count), digging: look.dug != nil)
    let brief = HudBrief(
      clock: clock, floor: world.course.floor, look: look, delver: world.course.delver)
    let hud = HudLayout.make(brief, width: canvas.width, step: world.walk.steps)
    var hudRow = 0
    while hudRow < hud.cells.count && hudRow < ScreenText.hudRows {
      job.writeHud(hud.cells[hudRow], row: hudRow)
      hudRow += 1
    }
    switch look.view {
    case .plan:
      job.writeMaze(shown)
    case .depth:
      var scene = DepthScene(world: shown, palette: palette, canvas: canvas, look: look)
      scene.paint(into: &job.cells)
    }
    return CellGrid(span: canvas, cells: job.cells)
  }

  private static func revealed(_ world: FloorWorld, frame: Int?) -> FloorWorld {
    guard let frame else {
      return world
    }
    let walk = FloorWalk(
      maze: DigReveal.maze(world.walk.maze, frame: frame), explorer: world.walk.explorer,
      rng: world.walk.rng, steps: world.walk.steps)
    return FloorWorld(
      course: world.course, walk: walk, fixtures: world.fixtures, aim: world.aim)
  }

  private struct Job {
    let palette: ThemePalette
    let canvas: GridSpan
    var cells: [Cell]
    let digging: Bool

    mutating func writeHud(_ cells: [HudCell], row: Int) {
      if row < 0 || row >= canvas.height {
        return
      }
      var column = 0
      while column < canvas.width {
        put(hudCell(HudCell.gap), at: CellPoint(x: column, y: row))
        column += 1
      }
      column = 0
      for cell in cells {
        if column >= canvas.width {
          return
        }
        put(hudCell(cell), at: CellPoint(x: column, y: row))
        column += 1
      }
    }

    func hudCell(_ cell: HudCell) -> Cell {
      Cell(
        glyph: cell.glyph, foreground: HudTone.ink(cell.role, palette: palette),
        background: palette.ink.background)
    }

    mutating func writeMaze(_ world: FloorWorld) {
      var row = 0
      while row < world.walk.maze.span.height {
        writeMazeRow(world, row: row)
        row += 1
      }
    }

    mutating func writeMazeRow(_ world: FloorWorld, row: Int) {
      let canvasRow = row + ScreenText.hudRows
      if canvasRow >= canvas.height {
        return
      }
      var column = 0
      while column < world.walk.maze.span.width && column < canvas.width {
        let point = CellPoint(x: column, y: row)
        put(glyph(world, point: point), at: CellPoint(x: column, y: canvasRow))
        column += 1
      }
    }

    func glyph(_ world: FloorWorld, point: CellPoint) -> Cell {
      if point == world.walk.explorer.position {
        return runner(world, point: point)
      }
      if let spark = spark(world, point) {
        return spark
      }
      if let flash = glitch(world, point) {
        return flash
      }
      if let beast = prowlerMark(world, point) {
        return beast
      }
      switch world.walk.maze.tile(at: point) {
      case .wall:
        return wall(world, point: point)
      case .floor:
        return floor(world, point: point)
      case .stairs:
        return Cell(
          glyph: stairMark(world, point), foreground: palette.ink.background,
          background: palette.accent.stairs)
      }
    }

    func stairMark(_ world: FloorWorld, _ point: CellPoint) -> Character {
      if point == world.walk.maze.ends.ascent {
        return ScreenText.ascent
      }
      return ScreenText.stairs
    }

    func spark(_ world: FloorWorld, _ point: CellPoint) -> Cell? {
      guard let burst = world.fixtures.burstMark() else {
        return nil
      }
      let column = point.x - burst.point.x
      let row = point.y - burst.point.y
      if abs(column) + abs(row) != 1 || !isOpen(world, point) {
        return nil
      }
      return Cell(
        glyph: ScreenText.spark(burst.age), foreground: palette.accent.mark.loot,
        background: palette.ink.background)
    }

    func glitch(_ world: FloorWorld, _ point: CellPoint) -> Cell? {
      if world.course.delver.line.moment != .warp || world.fixtures.wade <= 0 {
        return nil
      }
      let runner = world.walk.explorer.position
      if abs(point.x - runner.x) + abs(point.y - runner.y) != 1 || !isOpen(world, point) {
        return nil
      }
      let phase = world.walk.steps + point.x + point.y
      return Cell(
        glyph: ScreenText.glitch(phase), foreground: palette.accent.hud,
        background: palette.ink.background)
    }

    func wall(_ world: FloorWorld, point: CellPoint) -> Cell {
      if !digging, DeadEnd.cap(world) == point {
        return Cell(
          glyph: ScreenText.wonder, foreground: palette.ink.runner,
          background: palette.ink.background)
      }
      return Cell(
        glyph: wallGlyph(world, point: point), foreground: palette.ink.wall,
        background: palette.ink.background)
    }

    func wallGlyph(_ world: FloorWorld, point: CellPoint) -> Character {
      let north = openSide(world, point, column: 0, row: -1)
      let south = openSide(world, point, column: 0, row: 1)
      let west = openSide(world, point, column: -1, row: 0)
      let east = openSide(world, point, column: 1, row: 0)
      let facing = faceMark(north: north, south: south, west: west, east: east)
      if facing != ScreenText.floor {
        return facing
      }
      if tightCorner(world, point) {
        return ScreenText.joint
      }
      return ScreenText.floor
    }

    func faceMark(north: Bool, south: Bool, west: Bool, east: Bool) -> Character {
      if (north || south) && (west || east) {
        return ScreenText.joint
      }
      if west || east {
        return ScreenText.bar
      }
      if north || south {
        return ScreenText.dash
      }
      return ScreenText.floor
    }

    func openSide(_ world: FloorWorld, _ point: CellPoint, column: Int, row: Int) -> Bool {
      isOpen(world, CellPoint(x: point.x + column, y: point.y + row))
    }

    func tightCorner(_ world: FloorWorld, _ point: CellPoint) -> Bool {
      if diagonalCorner(world, point, column: -1, row: -1) {
        return true
      }
      if diagonalCorner(world, point, column: 1, row: -1) {
        return true
      }
      if diagonalCorner(world, point, column: -1, row: 1) {
        return true
      }
      return diagonalCorner(world, point, column: 1, row: 1)
    }

    func diagonalCorner(_ world: FloorWorld, _ point: CellPoint, column: Int, row: Int) -> Bool {
      let across = CellPoint(x: point.x + column, y: point.y + row)
      if !isOpen(world, across) {
        return false
      }
      let alongX = CellPoint(x: point.x + column, y: point.y)
      let alongY = CellPoint(x: point.x, y: point.y + row)
      return isWall(world, alongX) && isWall(world, alongY)
    }

    func isWall(_ world: FloorWorld, _ point: CellPoint) -> Bool {
      if !world.walk.maze.span.contains(point) {
        return false
      }
      switch world.walk.maze.tile(at: point) {
      case .wall:
        return true
      case .floor, .stairs:
        return false
      }
    }

    func isOpen(_ world: FloorWorld, _ point: CellPoint) -> Bool {
      if !world.walk.maze.span.contains(point) {
        return false
      }
      switch world.walk.maze.tile(at: point) {
      case .wall:
        return false
      case .floor, .stairs:
        return true
      }
    }

    func floor(_ world: FloorWorld, point: CellPoint) -> Cell {
      if let trap = pit(world, point) {
        return trap
      }
      if world.fixtures.sealed(at: point) {
        return Cell(
          glyph: ScreenText.chest, foreground: palette.accent.mark.loot,
          background: palette.ink.background)
      }
      if let pad = warp(world, point) {
        return pad
      }
      if world.fixtures.lake(at: point) {
        let phase = world.walk.steps + point.x + point.y
        return Cell(
          glyph: ScreenText.ripple(phase), foreground: palette.accent.mark.foam,
          background: palette.accent.mark.water)
      }
      let glyph = visited(world, point) ? ScreenText.trail : ScreenText.floor
      return Cell(glyph: glyph, foreground: palette.ink.floor, background: palette.ink.background)
    }

    func warp(_ world: FloorWorld, _ point: CellPoint) -> Cell? {
      if !world.fixtures.warp(at: point) {
        return nil
      }
      let phase = world.walk.steps + point.x + point.y
      return Cell(
        glyph: ScreenText.via(phase), foreground: palette.accent.hud,
        background: palette.ink.background)
    }

    func pit(_ world: FloorWorld, _ point: CellPoint) -> Cell? {
      if !world.fixtures.pit(at: point) {
        return nil
      }
      return Cell(
        glyph: ScreenText.pit, foreground: palette.accent.mark.threat,
        background: palette.ink.background)
    }

    func visited(_ world: FloorWorld, _ point: CellPoint) -> Bool {
      world.walk.explorer.seen[world.walk.maze.span.offset(point)]
    }

    func prowlerMark(_ world: FloorWorld, _ point: CellPoint) -> Cell? {
      if world.walk.maze.tile(at: point) == .wall {
        return nil
      }
      if let flash = clash(world, point) {
        return flash
      }
      guard let beast = world.fixtures.prowler(at: point) else {
        return nil
      }
      return Cell(
        glyph: ScreenText.foeGlyph(beast, steps: world.walk.steps),
        foreground: palette.accent.mark.threat, background: standing(world, point))
    }

    func clash(_ world: FloorWorld, _ point: CellPoint) -> Cell? {
      guard let beast = world.fixtures.fighting() else {
        return nil
      }
      let column = point.x - beast.point.x
      let row = point.y - beast.point.y
      if abs(column) + abs(row) != 1 || !isOpen(world, point) {
        return nil
      }
      guard let age = fightAge(beast) else {
        return nil
      }
      return Cell(
        glyph: ScreenText.clash(age), foreground: palette.accent.mark.threat,
        background: palette.ink.background)
    }

    func fightAge(_ beast: FloorProwler) -> Int? {
      switch beast.mood {
      case .fight(let age):
        age
      case .blink, .flee, .gone:
        nil
      }
    }

    func standing(_ world: FloorWorld, _ point: CellPoint) -> Rgb {
      if world.fixtures.lake(at: point) {
        return palette.accent.mark.water
      }
      return palette.ink.background
    }

    func runner(_ world: FloorWorld, point: CellPoint) -> Cell {
      let ground =
        world.fixtures.lake(at: point) ? palette.accent.mark.water : palette.accent.chip
      return Cell(
        glyph: ScreenText.runner, foreground: palette.ink.runner, background: ground)
    }

    mutating func put(_ cell: Cell, at point: CellPoint) {
      if canvas.contains(point) {
        cells[canvas.offset(point)] = cell
      }
    }
  }
}
