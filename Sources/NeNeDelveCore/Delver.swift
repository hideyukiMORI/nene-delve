/// 走者の数値と、いま画面に出している一言。
public struct Delver: Equatable, Sendable {
  public let vitals: DelverVitals
  public let line: DelverLine
  public let trace: DelverTrace

  /// すでに上った最も深い階。0 はまだ上っていない。
  public let risen: Int

  public static let quiet = Delver(vitals: .fresh(), line: .quiet, trace: .blank)

  public init(
    vitals: DelverVitals, line: DelverLine, trace: DelverTrace = .blank, risen: Int = 0
  ) {
    self.vitals = vitals
    self.line = line
    self.trace = trace
    self.risen = risen
  }

  public static func fresh(_ pin: DelverLine.QuipPin) -> Delver {
    Delver(vitals: .fresh(), line: DelverLine.say(.descend, pin: pin, note: pin.floor.depth))
  }

  func carrying(vitals: DelverVitals, line: DelverLine) -> Delver {
    Delver(vitals: vitals, line: line, trace: trace, risen: risen)
  }

  func remembering(_ depth: Int) -> Delver {
    Delver(vitals: vitals, line: line, trace: trace, risen: max(risen, depth))
  }

  func noted() -> Delver {
    Delver(vitals: vitals, line: line, trace: trace.noting(vitals.hitPoints), risen: risen)
  }

  func aged() -> Delver {
    Delver(vitals: vitals, line: line.aged(), trace: trace, risen: risen)
  }
}
