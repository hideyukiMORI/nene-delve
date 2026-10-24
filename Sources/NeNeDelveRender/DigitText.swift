import NeNeDelveCore

enum DigitText {
  static func padded(_ value: Int, width: Int) -> String {
    let digits = String(abs(value))
    if digits.count >= width {
      return digits
    }
    return String(repeating: "0", count: width - digits.count) + digits
  }

  static func elapsed(_ seconds: Int) -> String {
    let safe = max(seconds, 0)
    let hours = padded(safe / 3600, width: 2)
    let minutes = padded((safe % 3600) / 60, width: 2)
    let remain = padded(safe % 60, width: 2)
    return hours + ":" + minutes + ":" + remain
  }

  static func date(_ date: WallDate) -> String {
    let year = padded(date.year, width: 4)
    let month = padded(date.month, width: 2)
    let day = padded(date.day, width: 2)
    return year + "-" + month + "-" + day
  }

  static func clock(_ face: ClockFace) -> String {
    let hour = padded(face.hour, width: 2)
    let minute = padded(face.minute, width: 2)
    let second = padded(face.second, width: 2)
    return hour + ":" + minute + ":" + second
  }
}
