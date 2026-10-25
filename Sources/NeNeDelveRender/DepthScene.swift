import NeNeDelveCore

struct DepthScene {
  let world: FloorWorld
  let palette: ThemePalette
  let canvas: GridSpan
  let look: FrameLook

  mutating func paint(into cells: inout [Cell]) {
    let height = canvas.height - ScreenText.hudRows
    if canvas.width <= 0 || height <= 1 {
      return
    }
    let cast = DepthCaster.Cast(
      maze: world.walk.maze, origin: DepthEye.origin(look.gaze), facing: look.gaze.facing)
    let hits = DepthCaster.columns(cast, count: canvas.width)
    let distances = draw(hits, height: height, into: &cells)
    edges(hits, height: height, into: &cells)
    stair(hits, height: height, into: &cells)
    stampMarks(distances, height: height, into: &cells)
    wonder(hits, height: height, into: &cells)
    grit(hits, into: &cells)
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
    let plane = band(hit.distance, viewHeight: viewHeight)
    var row = 0
    while row < viewHeight {
      let band = Slice(hit: hit, row: row, top: plane.top, bottom: plane.bottom)
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
    return fill(band.hit)
  }

  private func sky() -> Cell {
    let tone = DepthTone.ceiling(palette.ink.wall)
    return Cell(glyph: " ", foreground: tone, background: tone)
  }

  private func fill(_ hit: DepthHit) -> Cell {
    let tone = DepthTone.face(paint(hit), vertical: hit.vertical)
    return Cell(glyph: " ", foreground: tone, background: tone)
  }

  private func paint(_ hit: DepthHit) -> Rgb {
    switch hit.tile {
    case .stairs:
      palette.accent.stairs
    case .wall, .floor:
      palette.ink.wall
    }
  }

  private func ground(column: Int, row: Int, viewHeight: Int) -> Cell {
    guard let point = sample(column: column, row: row, viewHeight: viewHeight) else {
      return sky()
    }
    if world.fixtures.lake(at: point) {
      return lake(column: column, row: row, viewHeight: viewHeight)
    }
    let tone = DepthTone.floor(
      palette.ink.floor, band: DepthTone.FloorBand.at(row: row, viewHeight: viewHeight))
    return Cell(glyph: " ", foreground: tone, background: tone)
  }

  private func lake(column: Int, row: Int, viewHeight: Int) -> Cell {
    let tone = DepthTone.water(palette.accent.mark.water)
    if shore(column: column, row: row, viewHeight: viewHeight) {
      return Cell(glyph: ScreenText.dash, foreground: palette.accent.mark.foam, background: tone)
    }
    return Cell(glyph: " ", foreground: tone, background: tone)
  }

  private func shore(column: Int, row: Int, viewHeight: Int) -> Bool {
    guard let above = sample(column: column, row: row - 1, viewHeight: viewHeight) else {
      return false
    }
    return !world.fixtures.lake(at: above)
  }

  private func edges(_ hits: [DepthHit], height: Int, into cells: inout [Cell]) {
    var column = 1
    while column < hits.count {
      if hits[column].vertical != hits[column - 1].vertical {
        bar(hits[column], column: column, viewHeight: height, into: &cells)
      }
      column += 1
    }
  }

  private func bar(_ hit: DepthHit, column: Int, viewHeight: Int, into cells: inout [Cell]) {
    let plane = band(hit.distance, viewHeight: viewHeight)
    var row = plane.top + 1
    while row < plane.bottom {
      put(post(hit), column: column, row: row, into: &cells)
      row += 1
    }
  }

  private func post(_ hit: DepthHit) -> Cell {
    let tone = DepthTone.face(paint(hit), vertical: hit.vertical)
    return Cell(
      glyph: ScreenText.bar, foreground: DepthTone.edge(paint(hit), vertical: hit.vertical),
      background: tone)
  }

  private func stair(_ hits: [DepthHit], height: Int, into cells: inout [Cell]) {
    guard let column = stairColumn(hits) else {
      return
    }
    let plane = band(hits[column].distance, viewHeight: height)
    if plane.bottom < plane.top {
      return
    }
    let tone = DepthTone.face(palette.accent.stairs, vertical: hits[column].vertical)
    let mark =
      hits[column].point == world.walk.maze.ends.ascent ? ScreenText.ascent : ScreenText.stairs
    put(
      Cell(glyph: mark, foreground: palette.ink.background, background: tone),
      column: column, row: (plane.top + plane.bottom) / 2, into: &cells)
  }

  private func wonder(_ hits: [DepthHit], height: Int, into cells: inout [Cell]) {
    if look.dug != nil {
      return
    }
    guard let cap = DeadEnd.cap(world), let column = capColumn(hits, cap) else {
      return
    }
    let plane = band(hits[column].distance, viewHeight: height)
    if plane.bottom < plane.top {
      return
    }
    let tone = DepthTone.face(palette.ink.wall, vertical: hits[column].vertical)
    put(
      Cell(glyph: ScreenText.wonder, foreground: palette.ink.background, background: tone),
      column: column, row: (plane.top + plane.bottom) / 2, into: &cells)
  }

  private func capColumn(_ hits: [DepthHit], _ cap: CellPoint) -> Int? {
    var chosen: Int?
    var gap = Int.max
    let center = hits.count / 2
    var column = 0
    while column < hits.count {
      if hits[column].point == cap {
        let next = abs(column - center)
        if chosen == nil || next < gap {
          chosen = column
          gap = next
        }
      }
      column += 1
    }
    return chosen
  }

  private func stairColumn(_ hits: [DepthHit]) -> Int? {
    var chosen: Int?
    var gap = Int.max
    let center = hits.count / 2
    var column = 0
    while column < hits.count {
      if hits[column].tile == .stairs {
        let next = abs(column - center)
        if chosen == nil || next < gap {
          chosen = column
          gap = next
        }
      }
      column += 1
    }
    return chosen
  }

  private func band(_ distance: Double, viewHeight: Int) -> DepthPlane {
    DepthPlane.across(distance, viewHeight: viewHeight, horizon: look.gaze.horizon)
  }

  private func sample(column: Int, row: Int, viewHeight: Int) -> CellPoint? {
    let split = Double(viewHeight) / 2 - Double(look.gaze.horizon)
    let horizon = min(max(split, 0), Double(viewHeight))
    let below = Double(row) - horizon
    if below <= 0 {
      return nil
    }
    let heading = DepthCaster.aim(look.gaze.facing)
    let skew = DepthCaster.plane(heading)
    let offset = DepthCaster.camera(column, count: canvas.width)
    let dirX = heading.x + skew.x * offset
    let dirY = heading.y + skew.y * offset
    let distance = horizon / below
    let origin = DepthEye.origin(look.gaze)
    let worldX = origin.x + distance * dirX
    let worldY = origin.y + distance * dirY
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
    if world.walk.maze.tile(at: fixture.point) == .wall {
      return nil
    }
    switch fixture.kind {
    case .lake:
      return nil
    case .chest:
      return sealed(fixture)
    case .pit:
      return armed(fixture)
    case .warp:
      return via(fixture)
    }
  }

  private func via(_ fixture: FloorFixture) -> Mark? {
    switch fixture.phase {
    case .sealed:
      let phase = world.walk.steps + fixture.point.x + fixture.point.y
      return Mark(
        point: fixture.point, glyph: ScreenText.via(phase), foreground: palette.accent.hud)
    case .bursting, .open:
      return nil
    }
  }

  private func armed(_ fixture: FloorFixture) -> Mark? {
    switch fixture.phase {
    case .sealed:
      Mark(point: fixture.point, glyph: ScreenText.pit, foreground: palette.accent.mark.threat)
    case .bursting, .open:
      nil
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
    if world.walk.maze.tile(at: beast.point) == .wall {
      return nil
    }
    switch beast.mood {
    case .gone:
      return nil
    case .blink, .fight, .flee:
      return Mark(
        point: beast.point, glyph: ScreenText.foeGlyph(beast, steps: world.walk.steps),
        foreground: palette.accent.mark.threat)
    }
  }

  private func cast(_ point: CellPoint, viewHeight: Int) -> CastPoint? {
    let origin = DepthEye.origin(look.gaze)
    let dx = Double(point.x) + 0.5 - origin.x
    let dy = Double(point.y) + 0.5 - origin.y
    let heading = DepthCaster.aim(look.gaze.facing)
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
    let raised = (stamp.viewHeight - stamp.cast.size) / 2 - look.gaze.horizon
    let top = min(max(raised, 0), stamp.viewHeight)
    let bottom = min(max(raised + stamp.cast.size - 1, -1), stamp.viewHeight - 1)
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

  private func grit(_ hits: [DepthHit], into cells: inout [Cell]) {
    let found = DepthGrain.dots(
      maze: world.walk.maze, gaze: look.gaze, span: canvas, hits: hits)
    var index = 0
    while index < found.count {
      place(found[index], into: &cells)
      index += 1
    }
  }

  private func place(_ dot: DepthGrain.Dot, into cells: inout [Cell]) {
    let point = CellPoint(x: dot.column, y: dot.row + ScreenText.hudRows)
    if !canvas.contains(point) {
      return
    }
    let behind = cells[canvas.offset(point)]
    if behind.glyph != ScreenText.floor {
      return
    }
    cells[canvas.offset(point)] = Cell(
      glyph: ScreenText.grit, foreground: palette.ink.wall, background: behind.background)
  }

  private func put(_ cell: Cell, column: Int, row: Int, into cells: inout [Cell]) {
    let point = CellPoint(x: column, y: row + ScreenText.hudRows)
    if canvas.contains(point) {
      cells[canvas.offset(point)] = cell
    }
  }
}
