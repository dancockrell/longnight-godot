extends BeatPresenter

## Presents Act One's first scene and wires the player's choice into the
## real systems rather than just narrating an outcome.
##
## The fact id "goulston_street_graffito" here is deliberately distinct from
## the Archive's "goulston_street" entry (scripts/core/archive.gd): the
## Archive is our sourced history of what actually happened, unconditional on
## play. This ledger entry is what THIS PLAYTHROUGH's protagonist personally
## managed to preserve, which depends on their choice and can differ run to
## run. Conflating the two would let a player's in-fiction failure erase our
## own historical record, which is backwards.

## Two DISTINCT facts, tracked separately, because they have different
## custody. Warren's order reaches the wall. It never reaches whatever the
## player personally did with what they saw - a notebook in a coat pocket is
## not a wall he can send a constable to sponge. An earlier version of this
## scene suppressed both under one fact id and every choice came out "lost",
## including "transcribe", which was supposed to be the one that survives.
## The test that caught it is in tests/run_tests.gd.
const FACT_WALL := "goulston_street_wall"        ## The chalk itself. Always suppressed.
const FACT_RECORD := "goulston_street_player_record"  ## What the player did with it.


func _ready() -> void:
	super._ready()
	graph = GoulstonBeats.beats()
	goto("arrival")


func _populate_buttons(_id: String, beat: Dictionary) -> void:
	match int(beat["kind"]):
		GoulstonBeats.Kind.CHOICE:
			for c in beat["choices"]:
				buttons.add_child(make_button(String(c["label"]),
					_advance.bind(String(c["next"]), String(c.get("action", "")))))
		GoulstonBeats.Kind.DEPART:
			buttons.add_child(make_button("Continue.", _advance.bind("", "")))
		_:
			buttons.add_child(make_button("Continue", _advance.bind(String(beat.get("next", "")), "")))


func _advance(next_id: String, action: String) -> void:
	if not action.is_empty():
		# The wall is suppressed no matter what the player does - that is the
		# entire lesson of this scene, and it is NOT conditional on their
		# choice. This models the object Warren actually has custody of.
		GameState.ledger.witness(FACT_WALL, 1888)
		GameState.ledger.inscribe(FACT_WALL, Ledger.Medium.CHALK)
		GameState.ledger.suppress(FACT_WALL, "Metropolitan Police, on Warren's order")

	match action:
		"watch":
			# Witnessed, never written down anywhere. Nobody suppressed this -
			# it simply never left living memory, which does not outlive its
			# holder. No inscribe() call, so it stays at the default medium.
			GameState.facts.hold(FACT_RECORD, GameState.protagonist_id, true)
			GameState.ledger.witness(FACT_RECORD, 1888)
		"transcribe":
			# In the player's own notebook, in their own pocket. Warren's
			# order never reaches this - he does not know it exists.
			GameState.facts.hold(FACT_RECORD, GameState.protagonist_id, true)
			GameState.ledger.witness(FACT_RECORD, 1888)
			GameState.ledger.inscribe(FACT_RECORD, Ledger.Medium.FILED_PAPER)
			# A second, independent observer holding a DIFFERENT exact
			# wording is the historically accurate outcome - the surviving
			# transcriptions disagree - and it is the Relational system's
			# whole point: both the protagonist and Halse are right, relative
			# to themselves. Deliberately not "resolved" to one true wording.
			GameState.facts.hold(FACT_RECORD, "halse_transcription", true)
		"intervene":
			# A failed attempt, never written down either - same as "watch"
			# in terms of what the player personally preserves.
			GameState.facts.hold(FACT_RECORD, GameState.protagonist_id, true)
			GameState.ledger.witness(FACT_RECORD, 1888)
			# It still happened and was seen - spending Exposure even on
			# failure is the point: a loud mistake costs the same as a loud
			# success, because the period does not grade the attempt, only
			# whether it noticed.
			GameState.exposure.spend(30, "attempted to interfere with police at Goulston Street and was physically removed")
			GameState.exposure.witness("a member of the public was forcibly removed from a murder scene at Goulston Street, 30 Sept 1888")
		_:
			pass

	if next_id.is_empty():
		_depart()
		return
	goto(next_id)


func _depart() -> void:
	# Nothing further built yet. Report state honestly rather than pretend
	# there's a next scene - see docs/DESIGN.md section 7, "not yet true".
	header.text = "END OF BUILT CONTENT"
	var survived := GameState.ledger.survives(FACT_RECORD)
	var why := GameState.ledger.why_lost(FACT_RECORD)
	var disputed := GameState.facts.disputed()
	body.text = "\n".join(PackedStringArray([
		"Exposure spent this scene: %d" % GameState.exposure.value,
		"",
		"Did what you preserved of the Goulston Street writing survive? %s" % ("YES" if survived else "NO"),
		("Why not: " + why) if not survived else "It is filed, and it does not match every other filed account of the same four minutes - which is correct, not an error.",
		"",
		"Disputed facts in this playthrough: %d" % disputed.size(),
	]))
	for child in buttons.get_children():
		child.queue_free()
	teaches.text = "teaches: nothing further is built past this point yet."
