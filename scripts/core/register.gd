class_name Register
extends RefCounted

## The codex screen's data layer.
##
## OVERRIDDEN BY DAN DIRECTLY, 27 Aug 2026, superseding the lore thread's
## "state, not causation" ruling this file was originally built against:
## "we are not politically safe. we are telling the truth. don't lie and
## don't hide. don't volunteer either... let the truth or not truth happen."
##
## The earlier version of this file banned the words "because", "now", "no
## longer" and "since" from ever appearing in a rendered row, on the theory
## that showing why something changed would be the game handing down a
## verdict. That was the thing to stop doing, not a safeguard worth keeping.
## A row may now say plainly what happened - a fact, not a judgment. "Don't
## volunteer" is still respected: the cause is one flat clause, present only
## when something genuinely caused it, never a sentence telling the reader
## what to feel about it.
##
## What is kept from the original design, because it was never about hiding:
## background entries the player never touched are still mixed in with
## whatever their choices produced. That is not concealment, it is an
## honest population - the parish register has more people in it than the
## player's own actions, and showing only the rows the player caused would
## be the dishonest picture, a scoreboard pretending to be a world.

class Row extends RefCounted:
	var subject_id: String = ""
	var certainty_name: String = ""
	var retrieval_available: bool = false
	## Plain statement of what happened, when something genuinely did.
	## Empty for background entries - nothing caused those, so there is
	## nothing true to say about why. Never a value judgment.
	var cause: String = ""

	func to_line() -> String:
		var base := "Consistency: %s. Retrieval: %s." % [
			certainty_name.to_upper(),
			"AVAILABLE" if retrieval_available else "NOT AVAILABLE"]
		if not cause.is_empty():
			base += " " + cause
		return base


## Background entries: parish register subjects nobody in this playthrough
## has ever acted on. Invented, per the no-real-people rule - nobody here is
## a real Whitechapel resident, and NO REAL PERSON MAY EVER BE ADDED TO THIS
## MAP, not even in the "safe" DOCUMENTED/unavailable direction. The mortuary
## shed ruling (world-aflame-godot docs/wiki/places/the-mortuary-shed.md) is
## explicit that a real murdered woman is "not an objective, not a subject,
## not a choice" - giving her a Row at all, even one that correctly reads
## NOT AVAILABLE, would still make her a subject of a system whose entire
## schema is "is this person retrievable." That fact stays in scene prose,
## never in this table. Enforced by a test that scans this list for known
## real names.
##
## CERTAINTY IS PER-SUBJECT, NOT UNIFORM, and an earlier version of this file
## got the default backwards. Volume XI (WORLD-1888.md) and the Flower and
## Dean Street ruling both establish that the Whitechapel casual poor
## overwhelmingly PASS 42-D - "every one of them passes it on the first
## reading" - meaning DISPUTED/reachable is the ordinary case here, not
## DOCUMENTED/unavailable. Caught by re-reading the lore rather than trusting
## the original assumption, before it became load-bearing in the mortuary
## shed, where the contrast between a documented case and an unclaimed one
## is the entire point of the room.
const BACKGROUND_SUBJECTS := {
	"a_carman_lodging_on_thrawl_street": Retrieval.Certainty.DISPUTED,
	"a_seamstress_no_fixed_address": Retrieval.Certainty.DISPUTED,
	"a_dock_labourer_hired_by_the_half_day": Retrieval.Certainty.DISPUTED,
	"a_pedlar_three_names_in_two_years": Retrieval.Certainty.DISPUTED,
	# A parish clerk's occasional exception - even here, documentation is not
	# impossible, only unlikely. All-DISPUTED would be as false a picture as
	# the original all-DOCUMENTED one.
	"an_unnamed_infant_workhouse_register": Retrieval.Certainty.DOCUMENTED,
	# From the mortuary shed: an unclaimed body, off the river, no name given.
	# Seeded here as ordinary register content rather than created by any
	# choice in that scene - the ruling requires that no unclaimed body be
	# retrieved on screen, and this entry is never touched by player action,
	# only ever observed, exactly like every other background row.
	"an_unclaimed_body_found_off_the_river": Retrieval.Certainty.DISPUTED,
}

## Real surnames that must never appear as a Register subject_id, checked by
## a test rather than trusted to review. Not exhaustive - a denominator this
## small is meant to catch an accidental literal addition, not to be a
## complete list of every real person in the setting.
const FORBIDDEN_REAL_NAMES := ["eddowes", "nichols", "chapman", "stride", "kelly", "halloran-sze"]


## Build the full register for this playthrough: background entries plus
## whatever the player's own signed Retrieval findings changed, mixed
## together with no distinguishing field between the two kinds.
static func build(signed_findings: Array) -> Array:
	var rows := []

	for subject_id in BACKGROUND_SUBJECTS:
		var certainty: Retrieval.Certainty = BACKGROUND_SUBJECTS[subject_id]
		var r := Row.new()
		r.subject_id = subject_id
		r.certainty_name = Retrieval.CERTAINTY_NAME[certainty]
		r.retrieval_available = Retrieval.liftable(certainty)
		rows.append(r)

	for f in signed_findings:
		if f == null:
			continue
		var r2 := Row.new()
		r2.subject_id = String(f.subject_id)
		r2.certainty_name = Retrieval.CERTAINTY_NAME[f.certainty]
		r2.retrieval_available = f.consistent
		r2.cause = String(f.cause)
		rows.append(r2)

	# Sorted by subject id rather than left in insertion order. Insertion
	# order would put every player-caused row after every background row,
	# which is itself a causation signal - the ruling forbids revealing
	# "when it changed", and position-by-recency is exactly that, just
	# spatial instead of textual.
	rows.sort_custom(func(a, b): return a.subject_id < b.subject_id)
	return rows
