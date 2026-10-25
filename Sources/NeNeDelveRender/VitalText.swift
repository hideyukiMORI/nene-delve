enum VitalText {
  static func level(_ level: Int) -> String {
    "LV" + DigitText.padded(level, width: 2)
  }
}
