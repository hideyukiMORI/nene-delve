import Testing

@testable import NeNeDelveCore

struct LaunchParserTests {
  @Test func emptyArgumentsStayUnseeded() {
    #expect(LaunchParser.parse([]) == .unseeded)
  }

  @Test func readsBothSeedForms() {
    #expect(LaunchParser.parse(["--seed", "42"]) == .seeded(Seed(raw: 42)))
    #expect(LaunchParser.parse(["--seed=42"]) == .seeded(Seed(raw: 42)))
  }

  @Test func rejectsBadSeeds() {
    #expect(LaunchParser.parse(["--seed"]) == .rejected(.missingValue))
    #expect(LaunchParser.parse(["--seed", "nope"]) == .rejected(.notAnInteger))
    #expect(LaunchParser.parse(["--seed=1", "--seed", "2"]) == .rejected(.repeated))
    #expect(LaunchParser.parse(["--fast"]) == .rejected(.unknownOption))
  }

  @Test func viewportKeepsAnOddMaze() {
    #expect(ViewportFit.classify(columns: 80, rows: 24, reservedRows: 2) == .maze(GridSpan(width: 79, height: 21)))
    #expect(ViewportFit.classify(columns: 4, rows: 24, reservedRows: 2) == .tooSmall)
    #expect(ViewportFit.classify(columns: 80, rows: 6, reservedRows: 2) == .tooSmall)
  }
}
