/// 直近の体力。HUD の折れ線が読む。表示の字は Render が決める。
public struct DelverTrace: Equatable, Sendable {
  public let samples: [Int]

  public static let blank = DelverTrace(samples: [])
  public static let kept = 11

  public init(samples: [Int]) {
    if samples.count <= DelverTrace.kept {
      self.samples = samples
      return
    }
    self.samples = Array(samples.suffix(DelverTrace.kept))
  }

  public func noting(_ hitPoints: Int) -> DelverTrace {
    DelverTrace(samples: samples + [hitPoints])
  }
}
