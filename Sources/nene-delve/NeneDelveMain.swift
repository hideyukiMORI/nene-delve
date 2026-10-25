import Glibc
import NeNeDelveCore
import NeNeDelveRender
import NeNeDelveTerminal

/// 合成ルート。時計、シード、端末を結ぶのはここだけ。
@main
struct NeneDelveMain {
  private struct Play {
    let seed: Seed
    let origin: Int64
    var stage: Int64
    var theme: ThemeName
  }

  private struct Loop {
    var world: FloorWorld?
    var play: Play
    var view: ViewMode
    var facing: Direction
  }

  private struct Frame {
    let world: FloorWorld
    let along: Double
  }

  private struct Stage {
    let columns: Int
    let span: GridSpan
  }

  private struct Beat {
    var phase: Phase
    var slice: Int
    var hold: Int

    enum Phase {
      case show
      case decide
      case turn
      case glide
      case step
    }
  }

  private enum Ready {
    case world(FloorWorld)
    case skip
    case stop
  }

  /// 3D の表示拍。世界の一歩は StepPace のまま。中間の待ちは静止の待ちと別。
  private enum DepthHold {
    static let settled = 167
    static let slice = 80
    static let slices = 4
  }

  static func main() {
    let code = run()
    if code != 0 {
      exit(code)
    }
  }

  private static func run() -> Int32 {
    switch launch() {
    case .rejected(let reason):
      report(ScreenText.rejection(reason))
      return 1
    case .seeded(let seed):
      return session(seed)
    case .unseeded:
      return session(seedFromClock())
    }
  }

  private static func launch() -> LaunchChoice {
    LaunchParser.parse(Array(CommandLine.arguments.dropFirst()))
  }

  private static func session(_ seed: Seed) -> Int32 {
    switch TerminalSession.open() {
    case .notATerminal:
      report(ScreenText.notATerminal)
      return 1
    case .rejected:
      report(ScreenText.terminalRejected)
      return 1
    case .ready(var terminal):
      defer { terminal.restore() }
      return loop(&terminal, seed: seed)
    }
  }

  private static func loop(_ terminal: inout TerminalSession, seed: Seed) -> Int32 {
    let origin = monotonic()
    let play = Play(seed: seed, origin: origin, stage: origin, theme: .neonGrid)
    var state = Loop(world: nil, play: play, view: .plan, facing: .north)
    var beat = Beat(phase: .show, slice: 0, hold: StepPace.explore.milliseconds)
    while true {
      if !steer(terminal.pollKey(), state: &state) {
        return 0
      }
      if state.view == .plan {
        beat.phase = park(beat.phase)
      }
      if let code = frame(&terminal, state: &state, beat: &beat) {
        return code
      }
      sleepMilliseconds(beat.hold)
    }
  }

  private static func steer(_ key: Keystroke, state: inout Loop) -> Bool {
    switch key {
    case .quit:
      return false
    case .nextTheme:
      state.play.theme = state.play.theme.next()
      return true
    case .previousTheme:
      state.play.theme = state.play.theme.previous()
      return true
    case .toggleView:
      state.view = state.view.toggled()
      return true
    case .none:
      return true
    }
  }

  private static func frame(
    _ terminal: inout TerminalSession, state: inout Loop, beat: inout Beat
  ) -> Int32? {
    guard let size = terminal.columnsAndRows() else {
      terminal.showTooSmall()
      beat.hold = wait(state)
      return nil
    }
    let fit = ViewportFit.classify(
      columns: size.columns,
      rows: size.rows,
      reservedRows: ScreenText.hudRows
    )
    switch fit {
    case .tooSmall:
      terminal.showTooSmall()
      beat.hold = wait(state)
      return nil
    case .maze(let span):
      return act(&terminal, span: span, state: &state, beat: &beat)
    }
  }

  private static func park(_ phase: Beat.Phase) -> Beat.Phase {
    switch phase {
    case .show, .decide, .step:
      phase
    case .turn, .glide:
      .show
    }
  }

  private static func act(
    _ terminal: inout TerminalSession, span: GridSpan, state: inout Loop, beat: inout Beat
  ) -> Int32? {
    guard let stage = stage(&terminal, span: span, state: state, beat: &beat) else {
      return nil
    }
    switch beat.phase {
    case .show:
      return show(&terminal, stage: stage, state: &state, beat: &beat)
    case .decide:
      return decide(state, beat: &beat)
    case .turn:
      return turn(&terminal, stage: stage, state: &state, beat: &beat)
    case .glide:
      return glide(&terminal, stage: stage, state: &state, beat: &beat)
    case .step:
      return advance(&terminal, stage: stage, state: &state, beat: &beat)
    }
  }

  private static func stage(
    _ terminal: inout TerminalSession, span: GridSpan, state: Loop, beat: inout Beat
  ) -> Stage? {
    guard let columns = terminal.columnsAndRows()?.columns else {
      terminal.showTooSmall()
      beat.hold = wait(state)
      return nil
    }
    return Stage(columns: columns, span: span)
  }

  private static func show(
    _ terminal: inout TerminalSession, stage: Stage, state: inout Loop, beat: inout Beat
  ) -> Int32? {
    switch ready(&terminal, stage: stage, state: &state) {
    case .skip:
      beat.hold = wait(state)
      return nil
    case .stop:
      return 1
    case .world(let current):
      present(
        &terminal, frame: Frame(world: current, along: 0), columns: stage.columns, state: state)
      beat.hold = wait(state)
      beat.phase = .decide
      return nil
    }
  }

  private static func decide(_ state: Loop, beat: inout Beat) -> Int32? {
    guard let current = state.world else {
      return 1
    }
    beat.hold = 0
    if state.view == .depth && upcoming(current, facing: state.facing) != nil {
      beat.phase = .turn
      return nil
    }
    if state.view == .depth && translating(current) {
      beat.slice = 0
      beat.phase = .glide
      return nil
    }
    beat.phase = .step
    return nil
  }

  private static func turn(
    _ terminal: inout TerminalSession, stage: Stage, state: inout Loop, beat: inout Beat
  ) -> Int32? {
    switch ready(&terminal, stage: stage, state: &state) {
    case .skip:
      beat.hold = wait(state)
      return nil
    case .stop:
      return 1
    case .world(let current):
      if let aimed = upcoming(current, facing: state.facing) {
        state.facing = aimed
      }
      present(
        &terminal, frame: Frame(world: current, along: 0), columns: stage.columns, state: state)
      beat.hold = DepthHold.settled
      beat.phase = .decide
      return nil
    }
  }

  private static func glide(
    _ terminal: inout TerminalSession, stage: Stage, state: inout Loop, beat: inout Beat
  ) -> Int32? {
    switch ready(&terminal, stage: stage, state: &state) {
    case .skip:
      beat.hold = wait(state)
      return nil
    case .stop:
      return 1
    case .world(let current):
      let along = Double(beat.slice + 1) / Double(DepthHold.slices + 1)
      present(
        &terminal, frame: Frame(world: current, along: along), columns: stage.columns, state: state)
      beat.hold = glideHold(current)
      if beat.slice + 1 >= DepthHold.slices {
        beat.phase = .step
        return nil
      }
      beat.slice += 1
      return nil
    }
  }

  private static func advance(
    _ terminal: inout TerminalSession, stage: Stage, state: inout Loop, beat: inout Beat
  ) -> Int32? {
    switch ready(&terminal, stage: stage, state: &state) {
    case .skip:
      beat.hold = wait(state)
      return nil
    case .stop:
      return 1
    case .world:
      return commit(&terminal, stage: stage, state: &state, beat: &beat)
    }
  }

  private static func commit(
    _ terminal: inout TerminalSession, stage: Stage, state: inout Loop, beat: inout Beat
  ) -> Int32? {
    guard var current = state.world else {
      return 1
    }
    let depth = current.course.floor.depth
    let seen = current
    let code = step(&terminal, columns: stage.columns, world: &current, state: &state)
    state.world = current
    retarget(&state, before: seen)
    beat.phase = .show
    beat.hold = landed(code, depth: depth, state: state)
    return code
  }

  private static func landed(_ code: Int32?, depth: Int, state: Loop) -> Int {
    if code == nil, let shown = state.world, shown.course.floor.depth != depth {
      return DepthHold.settled
    }
    return 0
  }

  private static func ready(
    _ terminal: inout TerminalSession, stage: Stage, state: inout Loop
  ) -> Ready {
    let resized = terminal.consumeResize()
    let before = state.world
    if !ensure(&state.world, seed: state.play.seed, span: stage.span, resized: resized) {
      terminal.showTooSmall()
      return .skip
    }
    retarget(&state, before: before)
    guard let current = state.world else {
      return .stop
    }
    return .world(current)
  }

  private static func upcoming(_ world: FloorWorld, facing: Direction) -> Direction? {
    let origin = world.walk.explorer.position
    let next: FloorWorld
    switch FloorReducer.tick(world) {
    case .running(let stepped):
      next = stepped
    case .descended(let onStairs):
      next = onStairs
    case .stuck:
      return nil
    }
    if next.walk.explorer.position == origin {
      return nil
    }
    let aimed = Sightline.advanced(from: origin, to: next.walk.explorer.position, facing: facing)
    if aimed == facing {
      return nil
    }
    return aimed
  }

  private static func translating(_ world: FloorWorld) -> Bool {
    let origin = world.walk.explorer.position
    switch FloorReducer.tick(world) {
    case .running(let stepped):
      return stepped.walk.explorer.position != origin
    case .descended(let onStairs):
      return onStairs.walk.explorer.position != origin
    case .stuck:
      return false
    }
  }

  private static func wait(_ state: Loop) -> Int {
    guard let world = state.world else {
      return StepPace.explore.milliseconds
    }
    if state.view == .depth {
      let paced = WalkLine.continues(world) ? StepPace.dash.milliseconds : DepthHold.settled
      return WalkTempo.lengthened(world, from: paced)
    }
    return WalkTempo.lengthened(world, from: WalkLine.milliseconds(world))
  }

  private static func glideHold(_ world: FloorWorld) -> Int {
    let paced = WalkLine.continues(world) ? StepPace.dash.milliseconds : DepthHold.slice
    return WalkTempo.lengthened(world, from: paced)
  }

  private static func retarget(_ state: inout Loop, before: FloorWorld?) {
    guard let world = state.world else {
      return
    }
    if let before, sameRoom(before, world) {
      state.facing = Sightline.advanced(
        from: before.walk.explorer.position, to: world.walk.explorer.position, facing: state.facing)
      return
    }
    state.facing = Sightline.opening(
      in: world.walk.maze, from: world.walk.explorer.position, toward: world.walk.maze.stairs)
  }

  private static func sameRoom(_ before: FloorWorld, _ world: FloorWorld) -> Bool {
    before.course.floor.depth == world.course.floor.depth
      && before.walk.maze.span == world.walk.maze.span
  }

  private static func ensure(_ world: inout FloorWorld?, seed: Seed, span: GridSpan, resized: Bool)
    -> Bool
  {
    if let current = world, current.walk.maze.span == span, !resized {
      return true
    }
    let floor = world?.course.floor ?? FloorIndex.first
    let pace = StepPace.forSpan(span)
    switch FloorReducer.resume(launchSeed: seed, floor: floor, span: span, pace: pace) {
    case .tooSmall:
      return false
    case .world(let next):
      world = kept(next, previous: world)
      return true
    }
  }

  private static func kept(_ rebuilt: FloorWorld, previous: FloorWorld?) -> FloorWorld {
    guard let previous else {
      return rebuilt
    }
    return FloorWorld(
      course: rebuilt.course.with(delver: previous.course.delver), walk: rebuilt.walk,
      fixtures: rebuilt.fixtures,
      aim: previous.aim)
  }

  private static func present(
    _ terminal: inout TerminalSession, frame: Frame, columns: Int, state: Loop
  ) {
    let canvas = GridSpan(
      width: columns, height: frame.world.walk.maze.span.height + ScreenText.hudRows)
    let gaze = Gaze(
      facing: state.facing, place: frame.world.walk.explorer.position, along: frame.along)
    let grid = FramePainter.paint(
      world: frame.world,
      clock: hud(state: state),
      look: FrameLook(theme: state.play.theme, view: state.view, gaze: gaze),
      canvas: canvas
    )
    terminal.present(grid)
  }

  private static func step(
    _ terminal: inout TerminalSession, columns: Int, world: inout FloorWorld, state: inout Loop
  ) -> Int32? {
    switch FloorReducer.tick(world) {
    case .running(let next):
      world = next
      return nil
    case .descended(let onStairs):
      present(&terminal, frame: Frame(world: onStairs, along: 0), columns: columns, state: state)
      return descend(&world, onStairs: onStairs, state: &state)
    case .stuck:
      report(ScreenText.stuck)
      return 1
    }
  }

  private static func descend(_ world: inout FloorWorld, onStairs: FloorWorld, state: inout Loop)
    -> Int32?
  {
    switch FloorReducer.nextFloor(onStairs) {
    case .ready(let next):
      world = next
      state.play.stage = monotonic()
      return nil
    case .stuck:
      report(ScreenText.stuck)
      return 1
    }
  }

  private static func hud(state: Loop) -> HudClock {
    let now = monotonic()
    let (date, face) = wall()
    let elapsed = ElapsedPair(
      totalSeconds: seconds(from: state.play.origin, to: now),
      stageSeconds: seconds(from: state.play.stage, to: now)
    )
    return HudClock(elapsed: elapsed, date: date, time: face, seed: state.play.seed)
  }

  private static func seconds(from start: Int64, to end: Int64) -> Int {
    let delta = end - start
    if delta <= 0 {
      return 0
    }
    return Int(delta / 1_000_000_000)
  }

  private static func monotonic() -> Int64 {
    var sample = timespec()
    _ = clock_gettime(CLOCK_MONOTONIC, &sample)
    return Int64(sample.tv_sec) * 1_000_000_000 + Int64(sample.tv_nsec)
  }

  private static func wall() -> (WallDate, ClockFace) {
    var sample = timespec()
    _ = clock_gettime(CLOCK_REALTIME, &sample)
    var parts = Glibc.tm()
    var wholeSeconds = sample.tv_sec
    _ = localtime_r(&wholeSeconds, &parts)
    return (date(parts), face(parts))
  }

  private static func date(_ parts: Glibc.tm) -> WallDate {
    WallDate(year: Int(parts.tm_year) + 1900, month: Int(parts.tm_mon) + 1, day: Int(parts.tm_mday))
  }

  private static func face(_ parts: Glibc.tm) -> ClockFace {
    ClockFace(hour: Int(parts.tm_hour), minute: Int(parts.tm_min), second: Int(parts.tm_sec))
  }

  private static func seedFromClock() -> Seed {
    let mixed = UInt64(bitPattern: monotonic())
    let (value, _) = SplitMix64(seed: Seed(raw: mixed)).next()
    return Seed(raw: value)
  }

  private static func sleepMilliseconds(_ milliseconds: Int) {
    let seconds = milliseconds / 1000
    let nanos = (milliseconds % 1000) * 1_000_000
    var request = timespec(tv_sec: seconds, tv_nsec: nanos)
    _ = nanosleep(&request, nil)
  }

  private static func report(_ line: String) {
    "w".withCString { mode in
      guard let stream = fdopen(STDERR_FILENO, mode) else {
        return
      }
      var text = line
      text.append("\n")
      text.withCString { pointer in
        _ = fputs(pointer, stream)
      }
      _ = fclose(stream)
    }
  }
}
