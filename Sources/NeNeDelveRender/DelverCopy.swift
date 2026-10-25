import NeNeDelveCore

enum DelverCopy {
  static func line(_ spoken: DelverLine) -> String {
    if spoken.left <= 0 {
      return ""
    }
    let mark = note(spoken)
    return composed(
      tag(spoken.moment), note: mark, voice: voice(spoken.moment), index: spoken.voice)
  }

  private static func composed(_ tag: String, note: String, voice: [String], index: Int) -> String {
    if tag.isEmpty {
      return ""
    }
    let mutter = spoken(voice, index: index)
    if note.isEmpty {
      return ">> " + tag + "  " + mutter
    }
    return ">> " + tag + "  " + note + "  " + mutter
  }

  private static func spoken(_ voice: [String], index: Int) -> String {
    if voice.isEmpty {
      return ""
    }
    return voice[index % voice.count]
  }

  private static func note(_ spoken: DelverLine) -> String {
    switch spoken.moment {
    case .quiet, .lake, .warp:
      ""
    case .descend, .ascend:
      "B" + String(spoken.note) + "F"
    case .chest, .kill, .drove:
      "EXP+" + String(spoken.note)
    case .pit, .engage:
      "HP-" + String(spoken.note)
    case .level:
      "LV" + String(spoken.note)
    case .faint:
      "HP0"
    case .low:
      "HP" + String(spoken.note)
    }
  }

  private static func tag(_ moment: DelverLine.Moment) -> String {
    switch moment {
    case .quiet:
      ""
    case .descend:
      "IN"
    case .ascend:
      "UP"
    case .chest:
      "CHEST $"
    case .pit:
      "TRAP ^"
    case .lake:
      "WET ~"
    case .engage:
      "ENGAGE &"
    case .kill:
      "DOWN &"
    case .drove:
      "BACK &"
    case .level:
      "LV UP"
    case .faint:
      "REBOOT"
    case .low:
      "HP LOW"
    case .warp:
      "VIA o"
    }
  }

  private static func voice(_ moment: DelverLine.Moment) -> [String] {
    switch moment {
    case .quiet:
      []
    case .descend:
      ["ﾏﾀ ｼﾀｶ", "ｸﾗｲ", "ｲｸﾖ"]
    case .ascend:
      ["ﾓﾄﾞﾙ", "ｳｴﾀﾞ", "ﾏﾀ ｳｴ"]
    case .chest:
      ["ﾏﾀ ｶﾈｶ", "ｶﾗｯﾎﾟ", "ﾅﾆﾓﾅｲ"]
    case .pit:
      ["ｲﾀｯ", "ｱｼﾓﾄﾐﾛ", "ﾜﾅｶﾖ"]
    case .lake:
      ["ｸﾂﾇﾚﾀ", "ﾂﾒﾀｲ", "ｵﾖｹﾞﾅｲ"]
    case .engage:
      ["ｺｲﾖ", "ｳｾｴﾅ", "ﾔﾙｶ"]
    case .kill:
      ["ﾌｩ", "ﾖﾜ", "ｼｽﾞｶﾆ"]
    case .drove:
      ["ﾆｹﾞﾀ", "ﾂﾏﾝﾈ", "ﾏﾀﾞｶ"]
    case .level:
      ["ﾂﾖｸﾅｯﾀ", "ｲｲｶﾝｼﾞ", "ｶﾅ"]
    case .faint:
      ["ﾁｮｯﾄｼﾝﾀﾞ", "ﾏﾀﾅ", "ｳﾜｰ"]
    case .low:
      ["ﾔﾊﾞｲ", "ｲﾀｲ", "ﾑﾘ"]
    case .warp:
      ["ｽﾞﾚﾀ", "ﾅﾆｺﾚ", "ﾋﾞｶｯ"]
    }
  }
}
