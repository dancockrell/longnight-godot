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

`world-aflame-godot/docs/LORE-BIBLE.md` governs, and the Project 42 lore
master owns it. This repository proposes; it does not rule.

**Two layers, and they never trade places.**

- The **Archive** is our own history. Real names, sourced, plainly told. It is
  not in the alternate history and never says "in this world".
- The **game** is the alternate history, with invented names throughout.

The seam between them is the project's governing philosophy — **never forget**
— resolved into a rule: **names go in the record, not on the roster.** Yad
Vashem names Ottla Kafka; it does not give her a stat line. No real person is
ever a playable unit, and real people are named in the Archive, where naming
is the whole point.

`scripts/core/archive.gd` enforces that in code rather than in a comment: an
entry without a recorded source, or with sources nobody has checked against
the text, **cannot be displayed**. Not "should not" — cannot. Entries that
are withheld report why. A memorial project that will repeat a claim it cannot
substantiate is worth less than none, because the first error someone catches
discredits every true thing next to it.

The other standing constraint: **every protagonist carries a bill** — the
Allies do not get a clean war. The suite enforces this against the roster
count, so adding a seventh cannot skip the check.

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

## What is true now, and what still is not

Updated as of the visual/audio pass, so this stays a live claim rather than a
stale one (CLAUDE.md rule 12: a stale warning is worse than none). Verify any
line here yourself with `tools/shot.ps1` rather than trusting the prose.

**True:** Title → Select → Camp Iron Bell tutorial → Goulston Street is
playable start to finish. Two eras have distinct visual identity (palette,
vignette, grain, per `scripts/core/era_palette.gd`) and a procedural ambient
bed (`scripts/core/ambience.gd` — the bible's own 60Hz mains-hum spec for
Project 42, and a fog-noise bed for 1888 with no bible entry to answer to).
The camp tutorial and the Goulston Street scene are both written, not
placeholder text.

**Not yet true:**
- **Nothing is balanced.** Every combat number is a placeholder.
  `LOUD_ENOUGH_TO_BE_WRITTEN_DOWN` sits between Covered and Forward play by
  measurement, not by tuning.
- **The six protagonists have a thesis and a bill each, not a written arc.**
  Good enough for a select screen, not for a party that argues with itself.
- **Two scenes of Act One are built: Goulston Street and Flower and Dean
  Street.** The mortuary shed, Clerkenwell, and Carfax are designed in the
  old canvas game and not yet ported.
- **The register screen (`scenes/Register.tscn`) is built** — a flat
  parish-register view of every subject assessed, in the programme's own
  voice. Ruled by the lore thread as "state, not causation": a row may say
  what is true now, never what made it true or who changed it, and
  background entries the player never touched sit in the same list, in the
  same shape, as the ones they did — a field that only appears where the
  player acted would be a scoreboard. Both the causation-word ban and the
  no-scoreboard rule are enforced as tests, not just followed by convention.
- **Werk Nachtigall's presence in 1888 is built, Hyakki Yakō's is not.**
  Per `world-aflame-godot/docs/wiki/` (ruled by the Chrono fork of the lore
  thread), neither faction gets a rival retrieval team — only Project 42
  has Chrono. Werk Nachtigall in 1888 is debris, built as the cellar beat
  in Flower and Dean Street: a failed Imperial attempt, apparatus and
  possibly a body, no German character ever on screen, and the fact that a
  Werk Nachtigall casualty passes the Consistency Finding perfectly is
  never stated by anyone — it's enforced as a lexical check in the test
  suite rather than a line of dialogue. Hyakki Yakō is never physically
  present at all and has no scene yet.
  Hyakki Yakō is never physically present at all — the watcher isn't bound
  by time, so an already-fused agent simply feels what they always feel,
  and it is never confirmed or explained on screen. Both unwritten.
