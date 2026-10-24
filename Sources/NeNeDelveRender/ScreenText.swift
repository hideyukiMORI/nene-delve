import NeNeDelveCore

public enum ScreenText {
  public static let hudRows = 2
  public static let tooSmall = "端末が小さすぎる"
  public static let notATerminal = "端末ではありません"
  public static let terminalRejected = "端末を初期化できません"
  public static let stuck = "階段にたどり着けません"
  public static let wall: Character = "#"
  public static let floor: Character = " "
  public static let runner: Character = "@"
  public static let stairs: Character = ">"

  public static func rejection(_ reason: LaunchRejection) -> String {
    switch reason {
    case .missingValue:
      "シードの値がありません"
    case .notAnInteger:
      "シードは 0 以上の整数です"
    case .repeated:
      "シードが繰り返されています"
    case .unknownOption:
      "不明な起動オプションです"
    }
  }

  public static func floorLabel(_ floor: FloorIndex) -> String {
    "B\(floor.depth)F"
  }

  public static func hudLine(_ clock: HudClock, floor: FloorIndex) -> String {
    let total = DigitText.elapsed(clock.elapsed.totalSeconds)
    let stage = DigitText.elapsed(clock.elapsed.stageSeconds)
    let when = DigitText.date(clock.date) + " " + DigitText.clock(clock.time)
    let head = floorLabel(floor) + "  total " + total + "  stage " + stage
    return head + "  " + when + "  seed " + String(clock.seed.raw)
  }

  public static func themeLine(_ theme: ThemeName) -> String {
    switch theme {
    case .neonGrid:
      "NEON GRID"
    }
  }
}
