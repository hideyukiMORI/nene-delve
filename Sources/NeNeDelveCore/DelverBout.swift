/// 隣接したモンスターとの 1 拍。先に殴り、残っていれば殴り返される。
enum DelverBout {
  struct Outcome {
    let field: FloorFixtureField
    let delver: Delver
  }

  struct Strike {
    let damage: Int
    let spent: Int
  }

  static func step(_ world: FloorWorld) -> Outcome {
    guard let foe = world.fixtures.fighting(), let age = age(of: foe) else {
      return idle(world)
    }
    return exchange(world, foe: foe, age: age)
  }

  private static func exchange(_ world: FloorWorld, foe: FloorProwler, age: Int) -> Outcome {
    let hit = strike(world.course.delver.vitals, age: age)
    let spent = world.course.delver.vitals.spend(hit.spent)
    let wounded = foe.wounded(hit.damage)
    if wounded.life <= 0 {
      return killed(world, foe: foe, vitals: spent)
    }
    return living(world, foe: wounded, age: age, vitals: spent)
  }

  private static func living(
    _ world: FloorWorld, foe: FloorProwler, age: Int, vitals: DelverVitals
  ) -> Outcome {
    let blow = DelverVitals.foeBlow(depth: world.course.floor.depth, chases: foe.chases)
    let hurt = vitals.hurt(blow)
    if hurt.hitPoints == 0 {
      return fainted(world, foe: foe, vitals: hurt)
    }
    if age == FloorProwler.fightSpan - 1 {
      return drove(world, foe: foe, vitals: hurt)
    }
    return trading(world, foe: foe, age: age, after: hurt)
  }

  private static func killed(_ world: FloorWorld, foe: FloorProwler, vitals: DelverVitals)
    -> Outcome
  {
    let exp = DelverVitals.killExperience(depth: world.course.floor.depth, chases: foe.chases)
    let reward = vitals.gain(exp)
    let line = rewardLine(world, reward: reward, moment: .kill, note: exp)
    let delver = world.course.delver.carrying(vitals: reward.vitals, line: line)
    return Outcome(field: world.fixtures.cleared(foe), delver: delver)
  }

  private static func drove(_ world: FloorWorld, foe: FloorProwler, vitals: DelverVitals) -> Outcome
  {
    let exp = DelverVitals.driveExperience(depth: world.course.floor.depth)
    let reward = vitals.gain(exp)
    let line = rewardLine(world, reward: reward, moment: .drove, note: exp)
    let aged = performed(world, foe: foe)
    return Outcome(
      field: aged, delver: world.course.delver.carrying(vitals: reward.vitals, line: line))
  }

  private static func fainted(_ world: FloorWorld, foe: FloorProwler, vitals: DelverVitals)
    -> Outcome
  {
    let line = DelverLine.say(.faint, pin: pin(world), note: 0)
    let field = world.fixtures.holding(foe.fleeing(), span: FloorProwler.fleeSpan)
    return Outcome(
      field: field, delver: world.course.delver.carrying(vitals: vitals.revived(), line: line))
  }

  private static func trading(
    _ world: FloorWorld, foe: FloorProwler, age: Int, after: DelverVitals
  ) -> Outcome {
    let line = banner(world, age: age, before: world.course.delver.vitals, after: after)
    let delver = world.course.delver.carrying(vitals: after, line: line)
    return Outcome(field: performed(world, foe: foe), delver: delver)
  }

  private static func rewardLine(
    _ world: FloorWorld, reward: DelverVitals.Growth, moment: DelverLine.Moment, note: Int
  ) -> DelverLine {
    if reward.leveled {
      return DelverLine.say(.level, pin: pin(world), note: reward.vitals.level)
    }
    return DelverLine.say(moment, pin: pin(world), note: note)
  }

  private static func banner(
    _ world: FloorWorld, age: Int, before: DelverVitals, after: DelverVitals
  ) -> DelverLine {
    let pin = pin(world)
    if age == 0 {
      return DelverLine.say(.engage, pin: pin, note: before.hitPoints - after.hitPoints)
    }
    if after.hitPoints * 2 <= after.hitMax && before.hitPoints * 2 > before.hitMax {
      return DelverLine.say(.low, pin: pin, note: after.hitPoints)
    }
    return world.course.delver.line.aged()
  }

  private static func idle(_ world: FloorWorld) -> Outcome {
    let field =
      world.fixtures.performing(in: world.walk.maze, runner: world.walk.explorer.position)
      ?? world.fixtures
    return Outcome(field: field, delver: world.course.delver.aged())
  }

  private static func performed(_ world: FloorWorld, foe: FloorProwler) -> FloorFixtureField {
    let replaced = world.fixtures.replacing(foe)
    return replaced.performing(in: world.walk.maze, runner: world.walk.explorer.position)
      ?? replaced
  }

  private static func strike(_ vitals: DelverVitals, age: Int) -> Strike {
    if vitals.magicPoints > 0 && age.isMultiple(of: 2) {
      return Strike(damage: vitals.blow + 3, spent: 1)
    }
    return Strike(damage: vitals.blow, spent: 0)
  }

  private static func age(of foe: FloorProwler) -> Int? {
    switch foe.mood {
    case .fight(let age):
      age
    case .blink, .flee, .gone:
      nil
    }
  }

  private static func pin(_ world: FloorWorld) -> DelverLine.QuipPin {
    DelverLine.QuipPin(
      seed: world.course.launchSeed, floor: world.course.floor,
      place: world.walk.explorer.position)
  }
}
