# NeNe Delve — Agent Guide

Short English entry point. The authoritative handbook is [CLAUDE.md](CLAUDE.md) (Japanese);
the normative documents live in [docs/](docs/).

The governing sentence, kept in Japanese so it is not paraphrased into a second canon:

> 一つの意味には一つの正典経路しか無い状態を作り、それを人の記憶ではなく機械に守らせる。

## Project identity

- Product: NeNe Delve, a terminal maze screensaver that descends floors. Type A, type B, chests, lakes, monsters, and ten themes run.
- Language / UI: Swift / ANSI terminal
- Package root: `Package.swift` (SwiftPM only)
- Done: `make check`

## Required reading before changing production code

1. `docs/ARCHITECTURE_CONSTITUTION.md`
2. `docs/PROJECT_LAYOUT.md`
3. `docs/CODING_RULES.md`
4. `docs/QUALITY_GATES.md`
5. `docs/DEVELOPMENT_WORKFLOW.md`
6. `docs/COMMIT_CONVENTIONS.md`
7. `docs/GLOSSARY.md`

Then the active issue, the relevant accepted ADRs, and any active waivers.

## Agent rules

- Do not invent a second implementation path because it is locally convenient (ARC-001, ARC-012).
- Do not weaken a gate to make a change pass. Fix the code instead (QLT-010).
- Do not mark a rule `active` in `docs/QUALITY_GATES.md` before a failing run is recorded.
- Do not read the current time, randomness, locale, or environment outside `Sources/nene-delve/` (ARC-007).
- Do not write `default`, `@unknown default`, or `case _` in a switch (SWF-002).
- Do not add suppressions or lint baselines without an active waiver (SWF-015, QLT-003).
- Do not claim a command passed unless it was actually executed.
- Do not add maze, rendering, or terminal behavior in the policy-foundation change. That is a later issue.

## The only definition of done

```text
make check
```

Local and CI run exactly this. Use narrow checks while iterating; run the full gate before
moving the PR from Draft to Ready.

## Required completion report

Issue and rule IDs, files and behavior changed, verification commands and results,
documentation or schema changes, active waiver IDs (or `none`), remaining risks.

Investigation-only requests do not authorize editing, committing, pushing, or opening PRs.
