import Testing

@testable import NeNeDelveRender

struct DepthToneTests {
  @Test func aSideFaceIsDarkerThanTheFacingWall() {
    let wall = Rgb(red: 0, green: 150, blue: 170)
    let side = DepthTone.face(wall, vertical: false)
    #expect(DepthTone.face(wall, vertical: true) == wall)
    #expect(side.red + side.green + side.blue < wall.red + wall.green + wall.blue)
  }

  @Test func blackWaterOnTheCubeIsLiftedToNinetyFive() {
    let void = DepthTone.water(Rgb(red: 36, green: 36, blue: 36))
    let toxic = DepthTone.water(Rgb(red: 16, green: 40, blue: 0))
    let neon = DepthTone.water(Rgb(red: 0, green: 60, blue: 120))
    #expect(void == Rgb(red: 95, green: 95, blue: 95))
    #expect(toxic == Rgb(red: 0, green: 95, blue: 0))
    #expect(neon == Rgb(red: 0, green: 60, blue: 120))
  }

  @Test func theNearFloorIsBrighterThanTheFarFloor() {
    let floor = Rgb(red: 120, green: 255, blue: 245)
    let near = DepthTone.floor(floor, band: .near)
    let far = DepthTone.floor(floor, band: .far)
    #expect(near == floor)
    #expect(far.red + far.green + far.blue < near.red + near.green + near.blue)
  }
}
