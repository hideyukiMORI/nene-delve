import NeNeDelveCore

struct DepthScene {
  let world: FloorWorld
  let palette: ThemePalette
  let canvas: GridSpan
  let facing: Direction

  mutating func paint(into cells: inout [Cell]) {
    let height = canvas.height - ScreenText.hudRows
    if canvas.width <= 0 || height <= 1 {
      return
    }
    let cast = DepthCaster.Cast(
      maze: world.walk.maze, from: world.walk.explorer.position, facing: facing)
    let hits = DepthCaster.columns(cast, count: canvas.width)
    let distances = draw(hits, height: height, into: &cells)
    stampMarks(distances, height: height, into: &cells)
    reticle(height: height, into: &cells)
  }

  private struct Slice {
    let hit: DepthHit
    let row: Int
    let top: Int
    let bottom: Int
  }

  private struct Mark {
    let point: CellPoint
    let glyph: Character
    let foreground: Rgb
  }

  private struct CastPoint {
    let column: Int
    let distance: Double
    let size: Int
  }

  private struct Stamp {
    let mark: Mark
    let cast: CastPoint
    let column: Int
    let viewHeight: Int
  }

  private func draw(_ hits: [DepthHit], height: Int, into cells: inout [Cell]) -> [Double] {
    var distances: [Double] = []
    var column = 0
    while column < hits.count {
      distances.append(draw(hits[column], column: column, viewHeight: height, into: &cells))
      column += 1
    }
    return distances
  }

  private func draw(_ hit: DepthHit, column: Int, viewHeight: Int, into cells: inout [Cell])
    -> Double
  {
    let lines = min(viewHeight, Int(Double(viewHeight) / hit.distance))
    let top = max(0, (viewHeight - lines) / 2)
    let bottom = min(viewHeight - 1, top + max(lines, 1) - 1)
    var row = 0
    while row < viewHeight {
      let band = Slice(hit: hit, row: row, top: top, bottom: bottom)
      put(
        slice(band, column: column, viewHeight: viewHeight), column: column, row: row, into: &cells)
      row += 1
    }
    return hit.distance
  }

  private func slice(_ band: Slice, column: Int, viewHeight: Int) -> Cell {
    if band.row < band.top {
      return sky()
    }
    if band.row > band.bottom {
      return ground(column: column, row: band.row, viewHeight: viewHeight)
    }
    return wall(band.hit)
  }

  private func sky() -> Cell {
    Cell(glyph: " ", foreground: palette.ink.wall, background: palette.ink.background)
  }

  private func wall(_ hit: DepthHit) -> Cell {
    let color = face(hit).dimmed(shade(hit))
    if hit.tile == .stairs {
      return Cell(glyph: ScreenText.stairs, foreground: palette.ink.background, background: color)
    }
    return Cell(
      glyph: DepthShade.glyph(hit.distance), foreground: color, background: palette.ink.background)
  }

  private func face(_ hit: DepthHit) -> Rgb {
    switch hit.tile {
    case .stairs:
      palette.accent.stairs
    case .wall, .floor:
      palette.ink.wall
    }
  }

  private func shade(_ hit: DepthHit) -> Int {
    let raw = Int(240 / max(hit.distance, 0.4))
    let capped = min(100, max(22, raw))
    if hit.vertical {
      return capped
    }
    return capped * 4 / 5
  }

  private func ground(column: Int, row: Int, viewHeight: Int) -> Cell {
    guard let point = sample(column: column, row: row, viewHeight: viewHeight) else {
      return sky()
    }
    if world.fixtures.lake(at: point) {
      let phase = world.walk.steps + point.x + point.y
      return Cell(
        glyph: ScreenText.ripple(phase), foreground: palette.accent.mark.foam,
        background: palette.accent.mark.water)
    }
    let percent = 28 + (row * 55 / max(viewHeight, 1))
    let glyph: Character = row.isMultiple(of: 2) ? "." : " "
    return Cell(
      glyph: glyph, foreground: palette.ink.floor.dimmed(percent),
      background: palette.ink.background)
  }

  private func sample(column: Int, row: Int, viewHeight: Int) -> CellPoint? {
    let horizon = Double(viewHeight) / 2
    let below = Double(row) - horizon
    if below <= 0 {
      return nil
    }
    let heading = DepthCaster.aim(facing)
    let skew = DepthCaster.plane(heading)
    let offset = DepthCaster.camera(column, count: canvas.width)
    let dirX = heading.x + skew.x * offset
    let dirY = heading.y + skew.y * offset
    let distance = horizon / below
    let worldX = Double(world.walk.explorer.position.x) + 0.5 + distance * dirX
    let worldY = Double(world.walk.explorer.position.y) + 0.5 + distance * dirY
    return CellPoint(x: Int(worldX.rounded(.down)), y: Int(worldY.rounded(.down)))
  }

  private func stampMarks(_ distances: [Double], height: Int, into cells: inout [Cell]) {
    for mark in marks() {
      guard let cast = cast(mark.point, viewHeight: height) else {
        continue
      }
      let half = max(0, cast.size / 6)
      var column = cast.column - half
      while column <= cast.column + half {
        let stamp = Stamp(mark: mark, cast: cast, column: column, viewHeight: height)
        paintMark(stamp, distances: distances, into: &cells)
        column += 1
      }
    }
  }

  private func marks() -> [Mark] {
    var found: [Mark] = []
    for fixture in world.fixtures.fixtures {
      if let mark = chest(fixture) {
        found.append(mark)
      }
    }
    for beast in world.fixtures.prowlers {
      if let mark = prowler(beast) {
        found.append(mark)
      }
    }
    return found
  }

  private func chest(_ fixture: FloorFixture) -> Mark? {
    switch fixture.kind {
    case .lake:
      nil
    case .chest:
      sealed(fixture)
    }
  }

  private func sealed(_ fixture: FloorFixture) -> Mark? {
    switch fixture.phase {
    case .open:
      nil
    case .sealed, .bursting:
      Mark(point: fixture.point, glyph: ScreenText.chest, foreground: palette.accent.mark.loot)
    }
  }

  private func prowler(_ beast: FloorProwler) -> Mark? {
    switch beast.mood {
    case .gone:
      return nil
    case .blink:
      let glyph = world.walk.steps.isMultiple(of: 2) ? ScreenText.prowler : ScreenText.alarm
      return Mark(point: beast.point, glyph: glyph, foreground: palette.accent.mark.threat)
    case .fight, .flee:
      return Mark(
        point: beast.point, glyph: ScreenText.prowler, foreground: palette.accent.mark.threat)
    }
  }

  private func cast(_ point: CellPoint, viewHeight: Int) -> CastPoint? {
    let dx = Double(point.x - world.walk.explorer.position.x)
    let dy = Double(point.y - world.walk.explorer.position.y)
    let heading = DepthCaster.aim(facing)
    let skew = DepthCaster.plane(heading)
    let det = skew.x * heading.y - heading.x * skew.y
    if det == 0 {
      return nil
    }
    let inv = 1 / det
    let transformX = inv * (heading.y * dx - heading.x * dy)
    let transformY = inv * (-skew.y * dx + skew.x * dy)
    if transformY <= 0.25 {
      return nil
    }
    let screen = Int((Double(canvas.width) / 2) * (1 + transformX / transformY))
    let size = max(1, Int(Double(viewHeight) / transformY))
    return CastPoint(column: screen, distance: transformY, size: size)
  }

  private func paintMark(_ stamp: Stamp, distances: [Double], into cells: inout [Cell]) {
    if stamp.column < 0 || stamp.column >= distances.count {
      return
    }
    if stamp.cast.distance >= distances[stamp.column] {
      return
    }
    let top = max(0, (stamp.viewHeight - stamp.cast.size) / 2)
    let bottom = min(stamp.viewHeight - 1, top + stamp.cast.size - 1)
    var row = top
    while row <= bottom {
      let behind = existing(column: stamp.column, row: row, in: cells)
      let cell = Cell(
        glyph: stamp.mark.glyph, foreground: stamp.mark.foreground, background: behind)
      put(cell, column: stamp.column, row: row, into: &cells)
      row += 1
    }
  }

  private func existing(column: Int, row: Int, in cells: [Cell]) -> Rgb {
    let point = CellPoint(x: column, y: row + ScreenText.hudRows)
    if canvas.contains(point) {
      return cells[canvas.offset(point)].background
    }
    return palette.ink.background
  }

  private func reticle(height: Int, into cells: inout [Cell]) {
    let column = canvas.width / 2
    let row = height / 2
    let point = CellPoint(x: column, y: row + ScreenText.hudRows)
    if !canvas.contains(point) {
      return
    }
    let current = cells[canvas.offset(point)]
    if current.glyph != " " && current.glyph != "." {
      return
    }
    cells[canvas.offset(point)] = Cell(
      glyph: "+", foreground: palette.ink.runner, background: current.background)
  }

  private func put(_ cell: Cell, column: Int, row: Int, into cells: inout [Cell]) {
    let point = CellPoint(x: column, y: row + ScreenText.hudRows)
    if canvas.contains(point) {
      cells[canvas.offset(point)] = cell
    }
  }
}
