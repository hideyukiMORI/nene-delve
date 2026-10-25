import Testing

@testable import NeNeDelveTerminal

struct KeystrokeTests {
  @Test func teeCyclesAndQStillQuits() {
    #expect(Keystroke.decoded(UInt8(ascii: "t")) == .nextTheme)
    #expect(Keystroke.decoded(UInt8(ascii: "T")) == .previousTheme)
    #expect(Keystroke.decoded(UInt8(ascii: "q")) == .quit)
    #expect(Keystroke.decoded(0x03) == .quit)
    #expect(Keystroke.decoded(UInt8(ascii: "v")) == .toggleView)
    #expect(Keystroke.decoded(UInt8(ascii: "V")) == .toggleView)
    #expect(Keystroke.decoded(UInt8(ascii: "x")) == .none)
  }

  @Test func nDropsToTheNextFloor() {
    #expect(Keystroke.decoded(UInt8(ascii: "n")) == .drop)
    #expect(Keystroke.decoded(UInt8(ascii: "N")) == .drop)
  }
}
