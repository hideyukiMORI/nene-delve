/// 走者の LV、HP、MP、EXP。階をまたいで残る。
public struct DelverVitals: Equatable, Sendable {
  public struct Growth: Equatable, Sendable {
    public let vitals: DelverVitals
    public let leveled: Bool
  }

  public let level: Int
  public let experience: Int
  public let hitPoints: Int
  public let magicPoints: Int

  public static let chestHeal = 4
  public static let chestMagic = 2
  public static let chestExperience = 3

  public init(level: Int, experience: Int, hitPoints: Int, magicPoints: Int) {
    let stepped = max(level, 1)
    self.level = stepped
    self.experience = max(experience, 0)
    self.hitPoints = min(max(hitPoints, 0), Self.hitCap(stepped))
    self.magicPoints = min(max(magicPoints, 0), Self.magicCap(stepped))
  }

  public static func fresh() -> DelverVitals {
    DelverVitals(level: 1, experience: 0, hitPoints: hitCap(1), magicPoints: magicCap(1))
  }

  public var hitMax: Int {
    Self.hitCap(level)
  }

  public var magicMax: Int {
    Self.magicCap(level)
  }

  public var experienceGoal: Int {
    Self.goal(level)
  }

  public var blow: Int {
    2 + (level - 1)
  }

  public static func foeLife(depth: Int, chases: Bool) -> Int {
    14 + max(depth, 1) * 2 + (chases ? 4 : 0)
  }

  public static func foeBlow(depth: Int, chases: Bool) -> Int {
    let extra = max(0, depth - 1) / 2
    if chases {
      return 2 + extra
    }
    return 1 + extra
  }

  public static func killExperience(depth: Int, chases: Bool) -> Int {
    5 + max(depth, 1) + (chases ? 3 : 0)
  }

  public static func driveExperience(depth: Int) -> Int {
    2 + max(depth, 1) / 2
  }

  public static func pitDamage(_ depth: Int) -> Int {
    3 + max(0, depth - 1) / 2
  }

  func hurt(_ damage: Int) -> DelverVitals {
    DelverVitals(
      level: level, experience: experience, hitPoints: hitPoints - max(damage, 0),
      magicPoints: magicPoints)
  }

  func spend(_ cost: Int) -> DelverVitals {
    DelverVitals(
      level: level, experience: experience, hitPoints: hitPoints,
      magicPoints: magicPoints - max(cost, 0))
  }

  func healed(hit: Int, magic: Int) -> DelverVitals {
    DelverVitals(
      level: level, experience: experience, hitPoints: hitPoints + max(hit, 0),
      magicPoints: magicPoints + max(magic, 0))
  }

  func revived() -> DelverVitals {
    DelverVitals(
      level: level, experience: experience, hitPoints: max(1, hitMax / 2),
      magicPoints: magicPoints)
  }

  func rested() -> DelverVitals {
    healed(hit: 2, magic: 1)
  }

  func gain(_ amount: Int) -> Growth {
    var stepped = level
    var banked = experience + max(amount, 0)
    var leveled = false
    while banked >= Self.goal(stepped) {
      banked -= Self.goal(stepped)
      stepped += 1
      leveled = true
    }
    var next = DelverVitals(
      level: stepped, experience: banked, hitPoints: hitPoints, magicPoints: magicPoints)
    if leveled {
      next = DelverVitals(
        level: stepped, experience: banked, hitPoints: next.hitMax, magicPoints: next.magicMax)
    }
    return Growth(vitals: next, leveled: leveled)
  }

  private static func hitCap(_ level: Int) -> Int {
    16 + (max(level, 1) - 1) * 4
  }

  private static func magicCap(_ level: Int) -> Int {
    6 + (max(level, 1) - 1) * 2
  }

  private static func goal(_ level: Int) -> Int {
    12 + (max(level, 1) - 1) * 8
  }
}
