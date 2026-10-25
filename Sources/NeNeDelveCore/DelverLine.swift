/// 画面下に少しだけ残る一言。文言は Render が持つ。
public struct DelverLine: Equatable, Sendable {
  public enum Moment: Equatable, Sendable {
    case quiet
    case descend
    case chest
    case pit
    case lake
    case engage
    case kill
    case drove
    case level
    case faint
    case low
    case ascend
    case warp
    case mimic
  }

  public struct QuipPin: Equatable, Sendable {
    public let seed: Seed
    public let floor: FloorIndex
    public let place: CellPoint

    public init(seed: Seed, floor: FloorIndex, place: CellPoint) {
      self.seed = seed
      self.floor = floor
      self.place = place
    }

    func roll(_ moment: Moment) -> Int {
      let mixed =
        seed.raw
        &+ UInt64(floor.depth) &* 0x9E37_79B9_7F4A_7C15
        &+ UInt64(place.x) &* 13
        &+ UInt64(place.y) &* 131
        &+ salt(moment)
      let (value, _) = SplitMix64(seed: Seed(raw: mixed)).next()
      return Int(value % 10_000)
    }

    private func salt(_ moment: Moment) -> UInt64 {
      switch moment {
      case .quiet:
        0
      case .descend:
        1
      case .chest:
        2
      case .pit:
        3
      case .lake:
        4
      case .engage:
        5
      case .kill:
        6
      case .drove:
        7
      case .level:
        8
      case .faint:
        9
      case .low:
        10
      case .ascend:
        11
      case .warp:
        12
      case .mimic:
        13
      }
    }
  }

  public static let quiet = DelverLine(moment: .quiet, voice: 0, note: 0, left: 0)
  public static let span = 32

  public let moment: Moment
  public let voice: Int
  public let note: Int
  public let left: Int

  public init(moment: Moment, voice: Int, note: Int, left: Int) {
    self.moment = moment
    self.voice = max(voice, 0)
    self.note = note
    self.left = max(left, 0)
  }

  public static func say(_ moment: Moment, pin: QuipPin, note: Int) -> DelverLine {
    DelverLine(moment: moment, voice: pin.roll(moment), note: note, left: span)
  }

  public func aged() -> DelverLine {
    switch moment {
    case .quiet:
      self
    case .descend, .ascend, .chest, .pit, .lake, .engage, .kill, .drove, .level, .faint, .low,
      .warp, .mimic:
      if left <= 1 {
        .quiet
      } else {
        DelverLine(moment: moment, voice: voice, note: note, left: left - 1)
      }
    }
  }
}
