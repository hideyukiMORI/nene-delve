/// 走者の数値と、いま画面に出している一言。
public struct Delver: Equatable, Sendable {
  public let vitals: DelverVitals
  public let line: DelverLine
  public let trace: DelverTrace

  public static let quiet = Delver(vitals: .fresh(), line: .quiet, trace: .blank)

  public init(vitals: DelverVitals, line: DelverLine, trace: DelverTrace = .blank) {
    self.vitals = vitals
    self.line = line
    self.trace = trace
  }

  public static func fresh(_ pin: DelverLine.QuipPin) -> Delver {
    Delver(vitals: .fresh(), line: DelverLine.say(.descend, pin: pin, note: pin.floor.depth))
  }

  func carrying(vitals: DelverVitals, line: DelverLine) -> Delver {
    Delver(vitals: vitals, line: line, trace: trace)
  }

  func noted() -> Delver {
    Delver(vitals: vitals, line: line, trace: trace.noting(vitals.hitPoints))
  }

  func aged() -> Delver {
    Delver(vitals: vitals, line: line.aged(), trace: trace)
  }
}
