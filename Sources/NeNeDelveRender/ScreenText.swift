import NeNeDelveCore

public enum ScreenText {
  public static let hudRows = 5
  public static let tooSmall = "端末が小さすぎる"
  public static let notATerminal = "端末ではありません"
  public static let terminalRejected = "端末を初期化できません"
  public static let stuck = "階段にたどり着けません"
  public static let joint: Character = "+"
  public static let bar: Character = "|"
  public static let dash: Character = "-"
  public static let floor: Character = " "
  public static let trail: Character = "."
  public static let runner: Character = "@"
  public static let stairs: Character = ">"
  public static let ascent: Character = "<"
  public static let chest: Character = "$"
  public static let prowler: Character = "&"
  public static let alarm: Character = "!"
  public static let pit: Character = "^"
  public static let wonder: Character = "?"

  public static func spark(_ age: Int) -> Character {
    let marks = Array("*%~^")
    let index = age % marks.count
    return marks[index]
  }

  public static func ripple(_ phase: Int) -> Character {
    let marks = Array("~`'")
    let index = phase % marks.count
    return marks[index]
  }

  public static func clash(_ age: Int) -> Character {
    let marks = Array("*#%x")
    let index = age % marks.count
    return marks[index]
  }

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

  public static func facingLine(_ facing: Direction) -> String {
    switch facing {
    case .north:
      "N"
    case .east:
      "E"
    case .south:
      "S"
    case .west:
      "W"
    }
  }

  public static func placeLine(_ place: CellPoint) -> String {
    "X" + DigitText.padded(place.x, width: 3) + " Y" + DigitText.padded(place.y, width: 3)
  }

  public static func viewLine(_ view: ViewMode) -> String {
    switch view {
    case .plan:
      "2D"
    case .depth:
      "3D"
    }
  }

  public static func themeLine(_ theme: ThemeName) -> String {
    switch theme {
    case .neonGrid:
      "NEON GRID"
    case .phosphor:
      "PHOSPHOR"
    case .amberTerm:
      "AMBER TERM"
    case .iceCore:
      "ICE CORE"
    case .synthwave:
      "SYNTHWAVE"
    case .deepSea:
      "DEEP SEA"
    case .void:
      "VOID"
    case .toxic:
      "TOXIC"
    case .aurora:
      "AURORA"
    case .carbon:
      "CARBON"
    }
  }
}
