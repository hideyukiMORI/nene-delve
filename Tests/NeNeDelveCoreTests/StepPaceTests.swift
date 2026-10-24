import Testing

@testable import NeNeDelveCore

struct StepPaceTests {
  @Test func aWideFloorStepsFasterThanATinyOne() {
    let tiny = StepPace.forSpan(GridSpan(width: 5, height: 5))
    let wide = StepPace.forSpan(GridSpan(width: 79, height: 21))
    #expect(tiny.milliseconds == StepPace.explore.milliseconds)
    #expect(wide.milliseconds == StepPace.rush.milliseconds)
    #expect(wide.milliseconds < tiny.milliseconds)
  }
}
