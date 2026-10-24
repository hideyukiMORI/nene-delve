import Glibc
import NeNeDelveRender

public struct TerminalSession {
  fileprivate nonisolated(unsafe) static var stopFlag: Int32 = 0
  fileprivate nonisolated(unsafe) static var resizeFlag: Int32 = 0

  private var original = termios()
  private var active = false
  private var previous: CellGrid?

  public static func open() -> TerminalEnter {
    if isatty(STDIN_FILENO) == 0 || isatty(STDOUT_FILENO) == 0 {
      return .notATerminal
    }
    var session = TerminalSession()
    if !session.enter() {
      return .rejected
    }
    return .ready(session)
  }

  public mutating func restore() {
    if !active {
      return
    }
    writeAll("\u{1b}[?25h\u{1b}[?1049l")
    _ = tcsetattr(STDIN_FILENO, TCSAFLUSH, &original)
    _ = signal(SIGINT, SIG_DFL)
    _ = signal(SIGWINCH, SIG_DFL)
    active = false
  }

  public mutating func present(_ grid: CellGrid) {
    let text = AnsiDiff.encode(previous: previous, next: grid)
    previous = grid
    if !text.isEmpty {
      writeAll(text)
    }
  }

  public mutating func showTooSmall() {
    previous = nil
    writeAll("\u{1b}[2J\u{1b}[H" + ScreenText.tooSmall)
  }

  public func pollKey() -> Keystroke {
    if TerminalSession.stopFlag != 0 {
      return .quit
    }
    var descriptor = pollfd(fd: STDIN_FILENO, events: Int16(POLLIN), revents: 0)
    if poll(&descriptor, nfds_t(1), 0) <= 0 {
      return .none
    }
    return readKey()
  }

  public func columnsAndRows() -> (columns: Int, rows: Int)? {
    var size = winsize()
    if ioctl(STDOUT_FILENO, UInt(TIOCGWINSZ), &size) != 0 {
      return nil
    }
    return (Int(size.ws_col), Int(size.ws_row))
  }

  public func consumeResize() -> Bool {
    if TerminalSession.resizeFlag == 0 {
      return false
    }
    TerminalSession.resizeFlag = 0
    return true
  }

  private mutating func enter() -> Bool {
    if tcgetattr(STDIN_FILENO, &original) != 0 {
      return false
    }
    if !applyRaw() {
      return false
    }
    TerminalSession.stopFlag = 0
    TerminalSession.resizeFlag = 0
    _ = signal(SIGINT, noteStop)
    _ = signal(SIGWINCH, noteResize)
    writeAll("\u{1b}[?1049h\u{1b}[?25l")
    active = true
    return true
  }

  private mutating func applyRaw() -> Bool {
    var raw = original
    cfmakeraw(&raw)
    // VMIN と VTIME。0 にすると、入力が無い read は待たない。
    raw.c_cc.6 = 0
    raw.c_cc.5 = 0
    return tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw) == 0
  }

  private func readKey() -> Keystroke {
    var byte: UInt8 = 0
    if read(STDIN_FILENO, &byte, 1) <= 0 {
      return .quit
    }
    return Keystroke.decoded(byte)
  }
}

private func noteStop(_: Int32) {
  TerminalSession.stopFlag = 1
}

private func noteResize(_: Int32) {
  TerminalSession.resizeFlag = 1
}

private func writeAll(_ text: String) {
  let bytes = Array(text.utf8)
  if bytes.isEmpty {
    return
  }
  bytes.withUnsafeBytes { buffer in
    guard let base = buffer.baseAddress else {
      return
    }
    writeBuffer(base, count: buffer.count)
  }
}

private func writeBuffer(_ base: UnsafeRawPointer, count: Int) {
  var sent = 0
  while sent < count {
    let wrote = write(STDOUT_FILENO, base.advanced(by: sent), count - sent)
    if wrote <= 0 {
      return
    }
    sent += wrote
  }
}
