class_name Register
extends RefCounted

## The codex screen's data layer. Ruled by the lore thread, 27 Aug 2026
## (world-aflame-godot/docs/wiki/concepts/state-not-causation.md), verified
## in git before a line of this was written.
##
## THE RULE THIS FILE ENFORCES: show the state, never the causation. A row
## may say what is true now. It may never say what made it true, when it
## changed, or who changed it. Concretely: no timestamps, no "before", no
## flag distinguishing a player-caused entry from a background one, and the
## rendered text can never use the words "because", "now", "no longer", or
## "since" - enforced as a lexical test in tests/run_tests.gd, the same
## mechanism already used for the Flower and Dean Street beats.
##
## THE SECOND HALF OF THE RULE, and it is the one that actually does the
## work: the register must show entries the player never touched, in the
## same shape as the ones they did. A field that only appears where the
## player acted is a scoreboard. This file mixes background entries in with
## real signed findings and gives both the identical row shape on purpose -
## there is no field anywhere in a Row that could tell a caller which is
## which, because the programme's own paperwork would not know to ask.

class Row extends RefCounted:
	var subject_id: String = ""
	var certainty_name: String = ""
	var retrieval_available: bool = false

	## The programme's own voice: flat, complete, incurious. This string is
	## the ONLY thing a screen should ever render for a row - building a
	## sentence around it in the UI layer is exactly the drift the ruling
	## warns about.
	func to_line() -> String:
		return "Consistency: %s. Retrieval: %s." % [
			certainty_name.to_upper(),
			"AVAILABLE" if retrieval_available else "NOT AVAILABLE"]


## Background entries: parish register subjects nobody in this playthrough
## has ever acted on. Most real registers are DOCUMENTED already for reasons
## that have nothing to do with any player - that is simply what a parish
## does - so these default to DOCUMENTED/unavailable, the ordinary case, per
## the ruling's own reasoning. Invented, per the no-real-people rule -
## nobody here is a real Whitechapel resident.
const BACKGROUND_SUBJECTS := [
	"a_carman_lodging_on_thrawl_street",
	"a_seamstress_no_fixed_address",
	"a_dock_labourer_hired_by_the_half_day",
	"an_unnamed_infant_workhouse_register",
	"a_pedlar_three_names_in_two_years",
]


## Build the full register for this playthrough: background entries plus
## whatever the player's own signed Retrieval findings changed, mixed
## together with no distinguishing field between the two kinds.
static func build(signed_findings: Array) -> Array:
	var rows := []

	for subject_id in BACKGROUND_SUBJECTS:
		var r := Row.new()
		r.subject_id = subject_id
		r.certainty_name = Retrieval.CERTAINTY_NAME[Retrieval.Certainty.DOCUMENTED]
		r.retrieval_available = Retrieval.liftable(Retrieval.Certainty.DOCUMENTED)
		rows.append(r)

	for f in signed_findings:
		if f == null:
			continue
		var r2 := Row.new()
		r2.subject_id = String(f.subject_id)
		r2.certainty_name = Retrieval.CERTAINTY_NAME[f.certainty]
		r2.retrieval_available = f.consistent
		rows.append(r2)

	# Sorted by subject id rather than left in insertion order. Insertion
	# order would put every player-caused row after every background row,
	# which is itself a causation signal - the ruling forbids revealing
	# "when it changed", and position-by-recency is exactly that, just
	# spatial instead of textual.
	rows.sort_custom(func(a, b): return a.subject_id < b.subject_id)
	return rows
