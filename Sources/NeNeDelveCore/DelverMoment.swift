/// 歩いたマスで宝箱、罠、水面を数値と一言に変える。
enum DelverMoment {
  static func notice(_ world: FloorWorld, explorer: Explorer) -> Delver {
    let place = explorer.position
    if world.fixtures.sealed(at: place) {
      return loot(world, place: place)
    }
    if world.fixtures.pit(at: place) {
      return snare(world, place: place)
    }
    if world.fixtures.lake(at: place) && world.fixtures.wade == 0
      && !continuing(world, explorer: explorer)
    {
      return wet(world, place: place)
    }
    return world.course.delver.aged()
  }

  private static func loot(_ world: FloorWorld, place: CellPoint) -> Delver {
    let healed = world.course.delver.vitals.healed(
      hit: DelverVitals.chestHeal, magic: DelverVitals.chestMagic)
    let reward = healed.gain(DelverVitals.chestExperience)
    let pin = pin(world, place: place)
    if reward.leveled {
      let line = DelverLine.say(.level, pin: pin, note: reward.vitals.level)
      return world.course.delver.carrying(vitals: reward.vitals, line: line)
    }
    let line = DelverLine.say(.chest, pin: pin, note: DelverVitals.chestExperience)
    return world.course.delver.carrying(vitals: reward.vitals, line: line)
  }

  private static func snare(_ world: FloorWorld, place: CellPoint) -> Delver {
    let damage = DelverVitals.pitDamage(world.course.floor.depth)
    let hurt = world.course.delver.vitals.hurt(damage)
    let pin = pin(world, place: place)
    if hurt.hitPoints == 0 {
      let line = DelverLine.say(.faint, pin: pin, note: 0)
      return world.course.delver.carrying(vitals: hurt.revived(), line: line)
    }
    let line = DelverLine.say(.pit, pin: pin, note: damage)
    return world.course.delver.carrying(vitals: hurt, line: line)
  }

  static func glitch(_ world: FloorWorld, place: CellPoint) -> Delver {
    let line = DelverLine.say(.warp, pin: pin(world, place: place), note: 0)
    return world.course.delver.carrying(vitals: world.course.delver.vitals, line: line)
  }

  private static func wet(_ world: FloorWorld, place: CellPoint) -> Delver {
    let line = DelverLine.say(.lake, pin: pin(world, place: place), note: 0)
    return world.course.delver.carrying(vitals: world.course.delver.vitals, line: line)
  }

  private static func continuing(_ world: FloorWorld, explorer: Explorer) -> Bool {
    let path = explorer.path
    if path.count < 2 {
      return false
    }
    return world.fixtures.lake(at: path[path.count - 2])
  }

  private static func pin(_ world: FloorWorld, place: CellPoint) -> DelverLine.QuipPin {
    DelverLine.QuipPin(seed: world.course.launchSeed, floor: world.course.floor, place: place)
  }
}
