/// 走者の数値と、いま画面に出している一言。
public struct Delver: Equatable, Sendable {
  public let vitals: DelverVitals
  public let line: DelverLine
  public let trace: DelverTrace

  /// すでに上った最も深い階。0 はまだ上っていない。
  public let risen: Int

  /// この起動で着いた最も深い階。1 は B1F。
  public let deepest: Int

  private struct Memory {
    let risen: Int
    let deepest: Int
  }

  public static let quiet = Delver(vitals: .fresh(), line: .quiet, trace: .blank)

  public init(
    vitals: DelverVitals, line: DelverLine, trace: DelverTrace = .blank, risen: Int = 0
  ) {
    self.vitals = vitals
    self.line = line
    self.trace = trace
    self.risen = risen
    self.deepest = 1
  }

  public static func fresh(_ pin: DelverLine.QuipPin) -> Delver {
    Delver(vitals: .fresh(), line: DelverLine.say(.descend, pin: pin, note: pin.floor.depth))
      .reaching(pin.floor.depth)
  }

  func carrying(vitals: DelverVitals, line: DelverLine) -> Delver {
    copied(vitals: vitals, line: line, trace: trace, risen: risen)
  }

  func remembering(_ depth: Int) -> Delver {
    copied(vitals: vitals, line: line, trace: trace, risen: max(risen, depth))
  }

  func noted() -> Delver {
    copied(vitals: vitals, line: line, trace: trace.noting(vitals.hitPoints), risen: risen)
  }

  func aged() -> Delver {
    copied(vitals: vitals, line: line.aged(), trace: trace, risen: risen)
  }

  func reaching(_ depth: Int) -> Delver {
    Delver(
      vitals: vitals, line: line, trace: trace,
      memory: Memory(risen: risen, deepest: max(deepest, depth)))
  }

  private func copied(vitals: DelverVitals, line: DelverLine, trace: DelverTrace, risen: Int)
    -> Delver
  {
    Delver(
      vitals: vitals, line: line, trace: trace, memory: Memory(risen: risen, deepest: deepest))
  }

  private init(vitals: DelverVitals, line: DelverLine, trace: DelverTrace, memory: Memory) {
    self.vitals = vitals
    self.line = line
    self.trace = trace
    self.risen = memory.risen
    self.deepest = max(memory.deepest, 1)
  }
}
