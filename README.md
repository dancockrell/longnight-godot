# The Long Night

A time-travel RPG in the Project 42 universe. Godot 4.7, GDScript.

Camp Iron Bell, Mississippi, 1944. Project 42's Chrono pillar mines history
for capability, and retrieval is one-way. You pick one of six operatives,
orient at the camp, and then go back — first to the Victorian period, where
two rival programmes are working the same historical moment, and then further.

This is a ground-up rebuild of [longnight](https://github.com/dancockrell/longnight),
a 9,554-line hand-written canvas RPG. The old game's argument survives; almost
none of its code does.

## The mechanic

**Exposure.** Project 42 technology used in a period with no vocabulary for it
is legible to that period. Every anachronism spends cover, and rival retrieval
teams converge on the noise.

Two meters, and the distinction is the whole design:

- **Cover** accumulates and can be rebuilt — a quiet night, a false trail.
- **Records** are permanent. A single action loud enough to be written down is
  written down, and no amount of lying low afterwards unwrites it.

The second meter exists because the first one did not work on its own, and the
measurement that proved it is in `tests/sweep_exposure.gd`.

## Lore

`world-aflame-godot/docs/LORE-BIBLE.md` governs. This repository proposes;
it does not rule. Two constraints that shape everything here:

- **No real person is ever a playable piece** (bible §2 rule 9). All six
  protagonists are inventions. Real authors and philosophers appear as
  encountered NPCs and never as units.
- **Every protagonist carries a bill** (bible §2 rule 6 — the Allies do not
  get a clean war). The test suite enforces this against the roster count, so
  adding a seventh cannot skip the check.

## Running it

    godot --headless --import                              # once, to register class_name globals
    godot --headless --script res://tests/run_tests.gd     # 19 checks
    godot --headless --script res://tests/sweep_exposure.gd # 400 paired runs

The harness reports three states, not two: pass, fail, and **not checked with
a reason**. A run that skipped something cannot print "all passed".

To prove the suite can actually fail rather than take its word for it:

    LONGNIGHT_SABOTAGE=strip_bill godot --headless --script res://tests/run_tests.gd
    LONGNIGHT_SABOTAGE=flatten_stance_noise godot --headless --script res://tests/run_tests.gd

Each breaks exactly one named check and exits 1. Verified 27 Aug 2026.

## What is not yet true

Kept deliberately, so nothing here reads as further along than it is.

- **There is no playable game.** No scenes, no rendering, no input. The camp
  tutorial, the eras, and every encounter are designed and unbuilt.
- **Nothing is balanced.** Every number is a placeholder. `LOUD_ENOUGH_TO_BE_WRITTEN_DOWN`
  is set to a value that happens to sit between Covered and Forward play; that
  window is measured but not tuned.
- **No story text is written**, and none will be until the open rulings in
  `docs/DESIGN.md` land.
- **The six protagonists have design intents, not written characters.**
- The rival faction encounters are unwritten. Their voice systems belong to
  the World Aflame card canon and will be taken from there, not invented here.
