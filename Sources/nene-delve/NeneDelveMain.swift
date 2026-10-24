import Glibc
import NeNeDelveCore
import NeNeDelveRender
import NeNeDelveTerminal

/// 合成ルート。時計、シード、端末を結ぶのはここだけ。
@main
struct NeneDelveMain {
  private struct Loop {
    var world: FloorWorld?
    let seed: Seed
    let origin: Int64
    var stage: Int64
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
    var state = Loop(world: nil, seed: seed, origin: origin, stage: origin)
    while true {
      if terminal.pollKey() == .quit {
        return 0
      }
      if let code = frame(&terminal, state: &state) {
        return code
      }
      let pace = state.world?.course.pace.milliseconds ?? StepPace.explore.milliseconds
      sleepMilliseconds(pace)
    }
  }

  private static func frame(_ terminal: inout TerminalSession, state: inout Loop) -> Int32? {
    guard let size = terminal.columnsAndRows() else {
      terminal.showTooSmall()
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
      return nil
    case .maze(let span):
      return draw(&terminal, span: span, state: &state)
    }
  }

  private static func draw(_ terminal: inout TerminalSession, span: GridSpan, state: inout Loop)
    -> Int32?
  {
    let resized = terminal.consumeResize()
    if !ensure(&state.world, seed: state.seed, span: span, resized: resized) {
      terminal.showTooSmall()
      return nil
    }
    guard var current = state.world else {
      return 1
    }
    present(&terminal, world: current, state: state)
    let code = step(&terminal, world: &current, state: &state)
    state.world = current
    return code
  }

  private static func ensure(_ world: inout FloorWorld?, seed: Seed, span: GridSpan, resized: Bool)
    -> Bool
  {
    if let current = world, current.walk.maze.span == span, !resized {
      return true
    }
    let floor = world?.course.floor ?? FloorIndex.first
    let pace = world?.course.pace ?? .explore
    switch FloorReducer.resume(launchSeed: seed, floor: floor, span: span, pace: pace) {
    case .tooSmall:
      return false
    case .world(let next):
      world = next
      return true
    }
  }

  private static func present(_ terminal: inout TerminalSession, world: FloorWorld, state: Loop) {
    let canvas = GridSpan(
      width: world.walk.maze.span.width,
      height: world.walk.maze.span.height + ScreenText.hudRows
    )
    let grid = FramePainter.paint(
      world: world,
      clock: hud(state: state),
      theme: .neonGrid,
      canvas: canvas
    )
    terminal.present(grid)
  }

  private static func step(
    _ terminal: inout TerminalSession, world: inout FloorWorld, state: inout Loop
  ) -> Int32? {
    switch FloorReducer.tick(world) {
    case .running(let next):
      world = next
      return nil
    case .descended(let onStairs):
      present(&terminal, world: onStairs, state: state)
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
      state.stage = monotonic()
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
      totalSeconds: seconds(from: state.origin, to: now),
      stageSeconds: seconds(from: state.stage, to: now)
    )
    return HudClock(elapsed: elapsed, date: date, time: face, seed: state.seed)
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
