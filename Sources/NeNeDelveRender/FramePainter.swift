import NeNeDelveCore

public enum FramePainter {
  public static func paint(world: FloorWorld, clock: HudClock, theme: ThemeName, canvas: GridSpan)
    -> CellGrid
  {
    if canvas.width <= 0 || canvas.height <= 0 {
      return CellGrid(span: canvas, cells: [])
    }
    let palette = ThemePalette.palette(theme)
    var job = Job(
      palette: palette, canvas: canvas, cells: Array(repeating: palette.blank, count: canvas.count))
    let hud = HudLayout.make(
      clock: clock, floor: world.course.floor, theme: theme, width: canvas.width)
    job.writeLine(hud.first, row: 0)
    job.writeLine(hud.second, row: 1)
    job.writeMaze(world)
    return CellGrid(span: canvas, cells: job.cells)
  }

  private struct Job {
    let palette: ThemePalette
    let canvas: GridSpan
    var cells: [Cell]

    mutating func writeLine(_ text: String, row: Int) {
      if row < 0 || row >= canvas.height {
        return
      }
      var column = 0
      for character in text {
        if column >= canvas.width {
          return
        }
        let cell = Cell(
          glyph: character, foreground: palette.accent.hud, background: palette.ink.background)
        put(cell, at: CellPoint(x: column, y: row))
        column += 1
      }
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
        return runner()
      }
      switch world.walk.maze.tile(at: point) {
      case .wall:
        return wall(world, point: point)
      case .floor:
        return floor(world, point: point)
      case .stairs:
        return Cell(
          glyph: ScreenText.stairs, foreground: palette.ink.background,
          background: palette.accent.stairs)
      }
    }

    func wall(_ world: FloorWorld, point: CellPoint) -> Cell {
      Cell(
        glyph: wallGlyph(world, point: point), foreground: palette.ink.wall,
        background: palette.ink.background)
    }

    func wallGlyph(_ world: FloorWorld, point: CellPoint) -> Character {
      if !touchesOpen(world, point) {
        return ScreenText.floor
      }
      let north = edge(world, point, column: 0, row: -1)
      let south = edge(world, point, column: 0, row: 1)
      let west = edge(world, point, column: -1, row: 0)
      let east = edge(world, point, column: 1, row: 0)
      if (north || south) && (west || east) {
        return ScreenText.joint
      }
      if north || south {
        return ScreenText.bar
      }
      return ScreenText.dash
    }

    func edge(_ world: FloorWorld, _ point: CellPoint, column: Int, row: Int) -> Bool {
      let next = CellPoint(x: point.x + column, y: point.y + row)
      if !world.walk.maze.span.contains(next) {
        return false
      }
      switch world.walk.maze.tile(at: next) {
      case .floor, .stairs:
        return false
      case .wall:
        return touchesOpen(world, next)
      }
    }

    func touchesOpen(_ world: FloorWorld, _ point: CellPoint) -> Bool {
      var row = -1
      while row <= 1 {
        var column = -1
        while column <= 1 {
          let beside = column != 0 || row != 0
          let next = CellPoint(x: point.x + column, y: point.y + row)
          if beside && isOpen(world, next) {
            return true
          }
          column += 1
        }
        row += 1
      }
      return false
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
      let glyph = visited(world, point) ? ScreenText.trail : ScreenText.floor
      return Cell(glyph: glyph, foreground: palette.ink.floor, background: palette.ink.background)
    }

    func visited(_ world: FloorWorld, _ point: CellPoint) -> Bool {
      world.walk.explorer.seen[world.walk.maze.span.offset(point)]
    }

    func runner() -> Cell {
      Cell(
        glyph: ScreenText.runner, foreground: palette.ink.runner, background: palette.accent.chip)
    }

    mutating func put(_ cell: Cell, at point: CellPoint) {
      if canvas.contains(point) {
        cells[canvas.offset(point)] = cell
      }
    }
  }
}
