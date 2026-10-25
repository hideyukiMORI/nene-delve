enum HudMorph {
  static func blend(_ read: HudRead, _ beat: HudBeat) -> [[HudCell]] {
    switch beat {
    case .aim:
      shown(read, aim: true, scan: true)
    case .rain:
      shown(read, aim: false, scan: false)
    case .intoRain(let age):
      towardRain(read, age)
    case .intoAim(let age):
      towardAim(read, age)
    }
  }

  private static func shown(_ read: HudRead, aim: Bool, scan: Bool) -> [[HudCell]] {
    guard let draft = HudBase.plate(read, aim: aim) else {
      return blank(read.width)
    }
    if aim {
      return HudAim.overlay(draft, read, scan: scan)
    }
    return HudRain.overlay(draft, read)
  }

  private static func towardRain(_ read: HudRead, _ age: Int) -> [[HudCell]] {
    var rows = shown(read, aim: true, scan: false)
    let rain = shown(read, aim: false, scan: false)
    var column = 0
    while column < read.width {
      let risen = age - passed(read.width, column)
      var row = 0
      while row < 4 {
        if risen >= 0 && row <= risen {
          rows[row][column] = rain[row][column]
        }
        row += 1
      }
      column += 1
    }
    HudScan.lay(&rows, column: head(read.width, age), through: true)
    return rows
  }

  private static func towardAim(_ read: HudRead, _ age: Int) -> [[HudCell]] {
    var rows = shown(read, aim: true, scan: false)
    let rain = shown(read, aim: false, scan: false)
    var column = 0
    while column < read.width {
      let when = dry(read.width, column)
      var row = 0
      while row < 4 {
        rows[row][column] = settle(
          rain[row][column], rows[row][column], age, (when, column, row, read.step))
        row += 1
      }
      column += 1
    }
    return rows
  }

  private static func settle(
    _ rain: HudCell, _ aim: HudCell, _ age: Int, _ when: (Int, Int, Int, Int)
  )
    -> HudCell
  {
    if age < when.0 {
      return rain
    }
    if age == when.0 {
      return thin(rain, when.1, when.2, when.3)
    }
    if age == when.0 + 1 {
      return lock(aim)
    }
    return aim
  }

  private static func thin(_ cell: HudCell, _ column: Int, _ row: Int, _ step: Int) -> HudCell {
    if cell.kind == .text || cell.glyph == " " {
      return cell
    }
    if HudHash.mix(column: column, row: row, time: step) % 3 == 0 {
      return HudCell(glyph: cell.glyph, role: .soft, kind: cell.kind)
    }
    return HudCell(glyph: " ", role: .faint, kind: cell.kind)
  }

  private static func lock(_ cell: HudCell) -> HudCell {
    if cell.kind == .frame {
      return HudCell(glyph: cell.glyph, role: .firm, kind: .frame)
    }
    if cell.kind == .gauge && "v|<>".contains(cell.glyph) {
      return HudCell(glyph: cell.glyph, role: .flash, kind: .gauge)
    }
    return cell
  }

  private static func head(_ width: Int, _ age: Int) -> Int {
    ((age + 1) * (width + 6) + HudBeat.shift / 2) / HudBeat.shift - 3
  }

  private static func passed(_ width: Int, _ column: Int) -> Int {
    var age = 0
    while age < HudBeat.shift {
      if head(width, age) - 1 > column {
        return age
      }
      age += 1
    }
    return HudBeat.shift
  }

  private static func dry(_ width: Int, _ column: Int) -> Int {
    let edge = width >= 60 ? 3 : 1
    if column < edge || column >= width - edge {
      return HudBeat.shift - 2
    }
    return Int(HudHash.mix(column: column, row: 11, time: 0) % UInt32(HudBeat.shift - 2))
  }

  private static func blank(_ width: Int) -> [[HudCell]] {
    Array(repeating: HudCell.spaces(max(width, 0)), count: ScreenText.hudRows)
  }
}
