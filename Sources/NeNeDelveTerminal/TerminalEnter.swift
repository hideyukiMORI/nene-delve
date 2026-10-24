public enum TerminalEnter {
  case ready(TerminalSession)
  case notATerminal
  case rejected
}
