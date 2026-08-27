extends SceneTree

## Headless test harness.
##
##     godot --headless --script res://tests/run_tests.gd
##
## Rules this suite is built to obey, from CLAUDE.md:
##   - Assert the denominator. Every check prints how many things it examined,
##     and a check that examined zero is a FAILURE, not a pass.
##   - Three states, not two: PASS, FAIL, and SKIP-with-a-reason. A skip is
##     carried all the way into the summary line so a run that verified
##     nothing can never print "all passed".
##   - Sabotage must be reachable on purpose. LONGNIGHT_SABOTAGE=<name> breaks
##     one thing deliberately so the negative path can be demonstrated rather
##     than promised.

var _pass := 0
var _fail := 0
var _skip := 0
var _checks := 0
var _sabotage := ""


func _init() -> void:
	_sabotage = OS.get_environment("LONGNIGHT_SABOTAGE")
	if not _sabotage.is_empty():
		print("[SABOTAGE ACTIVE] %s - failures below are expected" % _sabotage)

	print("=== The Long Night - core harness ===")
	test_roster()
	test_exposure_bands()
	test_exposure_cannot_be_free()
	test_battle_resolves()
	test_loud_wins_cost_more()
	test_ledger()
	test_archive()
	test_relational()
	test_retrieval()
	test_tutorial_graph()
	test_goulston_graph()
	test_goulston_choices()
	test_flower_dean_graph()
	test_flower_dean_investigator_choice()
	_summary()
	quit(1 if _fail > 0 else 0)


func _ok(label: String, cond: bool, detail: String = "") -> void:
	_checks += 1
	if cond:
		_pass += 1
		print("  PASS  %s%s" % [label, (" (%s)" % detail) if detail else ""])
	else:
		_fail += 1
		print("  FAIL  %s%s" % [label, (" (%s)" % detail) if detail else ""])


func _skipped(label: String, why: String) -> void:
	_checks += 1
	_skip += 1
	print("  SKIP  %s - NOT CHECKED: %s" % [label, why])


# ---------------------------------------------------------------- roster ---

func test_roster() -> void:
	print("\n[roster]")
	var n := Roster.PROTAGONISTS.size()

	# The denominator. If the roster fails to load, every check below it would
	# vacuously pass, so this is asserted first and hard.
	_ok("roster is non-empty", n > 0, "%d protagonists" % n)
	if n == 0:
		_skipped("all remaining roster checks", "roster is empty, nothing to check against")
		return

	var seen := {}
	var dupes := 0
	for p in Roster.PROTAGONISTS:
		if seen.has(p["id"]):
			dupes += 1
		seen[p["id"]] = true
	_ok("ids are unique", dupes == 0, "checked %d ids" % n)

	# Bible section 2 rule 6: the Allies do not get a clean war. A protagonist
	# without a bill has quietly become a hero. Counted against the roster
	# size, not a hardcoded 6, so adding a seventh cannot skip the check.
	var missing := Roster.missing_bill()
	if _sabotage == "strip_bill":
		missing = PackedStringArray(["moreau"])
	_ok("every protagonist carries a bill", missing.is_empty(),
		"%d of %d have one" % [n - missing.size(), n])

	var pos_dupes := Roster.duplicate_question_positions()
	if _sabotage == "collide_question_positions":
		pos_dupes = [4]
	_ok("no two protagonists share a Volume XVI position", pos_dupes.is_empty(),
		"checked %d protagonists, %d collisions" % [n, pos_dupes.size()])

	var missing_pos := Roster.missing_question_position()
	_ok("every protagonist holds a Volume XVI position", missing_pos.is_empty(),
		"%d of %d missing" % [missing_pos.size(), n])

	var pillars_used := {}
	for p in Roster.PROTAGONISTS:
		pillars_used[p["pillar"]] = true
	_ok("all three pillars represented", pillars_used.size() == 3,
		"%d of 3" % pillars_used.size())

	var bad := 0
	for p in Roster.PROTAGONISTS:
		if int(p["hp"]) <= 0 or int(p["atk"]) <= 0:
			bad += 1
	_ok("no protagonist has degenerate stats", bad == 0, "checked %d" % n)


# -------------------------------------------------------------- exposure ---

func test_exposure_bands() -> void:
	print("\n[exposure bands]")
	var e := Exposure.new(100)
	var cases := [[0, "quiet"], [30, "noticed"], [60, "reported"], [80, "hunted"], [100, "burned"]]
	var checked := 0
	var wrong := 0
	for c in cases:
		e.value = int(c[0])
		if e.band() != String(c[1]):
			wrong += 1
		checked += 1
	_ok("bands map correctly across the range", wrong == 0,
		"checked %d of %d points" % [checked, cases.size()])
	_ok("denominator is the full case table", checked == cases.size(),
		"%d cases" % checked)


func test_exposure_cannot_be_free() -> void:
	print("\n[exposure is never free]")

	# The chooser test: run it where the wrong answer is available. Current is
	# meant to be the loudest pillar, and that only means anything if the
	# others are present to lose to it.
	var chrono := Pillars.base_exposure(Pillars.Kind.CHRONO)
	var phase := Pillars.base_exposure(Pillars.Kind.PHASE)
	var current := Pillars.base_exposure(Pillars.Kind.CURRENT)
	_ok("three distinct pillar costs exist", chrono != phase and phase != current,
		"chrono=%d phase=%d current=%d" % [chrono, phase, current])
	_ok("Current is the loudest of the three", current > phase and current > chrono,
		"compared against 2 alternatives")

	var e := Exposure.new(100)
	var added := e.spend(10, "test")
	_ok("spend() returns what it actually added", added == 10, "asked 10, got %d" % added)
	_ok("spend() records why", e.records_left.size() == 1,
		"%d records" % e.records_left.size())

	# Cover recovers; the record does not.
	e.recover(100)
	_ok("cover recovers to zero", e.value == 0, "value=%d" % e.value)
	_ok("the record survives recovery", e.records_left.size() == 1,
		"%d records still standing" % e.records_left.size())


# ---------------------------------------------------------------- battle ---

func _make_party() -> Array[Combatant]:
	var out: Array[Combatant] = []
	for id in ["moreau", "hune", "ferrer"]:
		var c := Combatant.from_roster(Roster.by_id(id))
		if c != null:
			out.append(c)
	return out


func _make_foes(count: int, hp: int, atk: int) -> Array[Combatant]:
	var out: Array[Combatant] = []
	for i in count:
		var c := Combatant.new()
		c.id = "foe_%d" % i
		c.display_name = "Werk Nachtigall retrieval man %d" % i
		c.is_player_side = false
		c.max_hp = hp
		c.hp = hp
		c.atk = atk
		c.def = 10
		c.spd = 12
		out.append(c)
	return out


func test_battle_resolves() -> void:
	print("\n[battle resolves]")
	var party := _make_party()
	_ok("party built from roster", party.size() == 3, "%d of 3 combatants" % party.size())
	if party.size() != 3:
		_skipped("battle resolution", "party did not build, nothing to fight with")
		return

	var e := Exposure.new(400)
	var b := Battle.new(party, _make_foes(3, 90, 14), e)
	var result := b.run_to_completion()
	_ok("battle terminates", result["resolved"], String(result.get("reason", "resolved")))
	_ok("battle took a plausible number of rounds", int(result["rounds"]) > 0,
		"%d rounds" % int(result["rounds"]))
	_ok("fighting spent exposure", e.value > 0,
		"exposure=%d after %d rounds" % [e.value, int(result["rounds"])])


func test_loud_wins_cost_more() -> void:
	print("\n[the central design claim]")
	# The claim: a fight won loudly costs more cover than the same fight won
	# quietly. If this cannot be demonstrated, Exposure is decoration.
	var quiet_party := _make_party()
	for c in quiet_party:
		c.stance = Combatant.Stance.COVERED
	var loud_party := _make_party()
	for c in loud_party:
		c.stance = Combatant.Stance.FORWARD
	if _sabotage == "flatten_stance_noise":
		for c in loud_party:
			c.stance = Combatant.Stance.COVERED

	var quiet_e := Exposure.new(1000)
	var loud_e := Exposure.new(1000)
	Battle.new(quiet_party, _make_foes(3, 90, 14), quiet_e, 7).run_to_completion()
	Battle.new(loud_party, _make_foes(3, 90, 14), loud_e, 7).run_to_completion()

	_ok("both runs actually fought", quiet_e.value > 0 and loud_e.value > 0,
		"quiet=%d loud=%d" % [quiet_e.value, loud_e.value])
	_ok("the loud party is measurably louder", loud_e.value > quiet_e.value,
		"loud=%d vs quiet=%d" % [loud_e.value, quiet_e.value])


# ---------------------------------------------------------------- ledger ---

func test_ledger() -> void:
	print("\n[the ledger - what survives]")

	# The thesis, asserted directly: witnessing is not remembering. If this
	# check ever passes trivially the whole philosophy of the game is
	# decoration, so it runs against a populated ledger and counts.
	var l := Ledger.new()
	l.witness("seen_only", 1888)
	l.witness("chalked", 1888)
	l.witness("filed", 1888)
	l.witness("photographed", 1888)
	l.witness("buried", 1888)

	var n := l.witnessed_count()
	_ok("ledger populated", n == 5, "%d entries witnessed" % n)
	if n != 5:
		_skipped("all remaining ledger checks", "ledger did not populate, nothing to check against")
		return

	l.inscribe("chalked", Ledger.Medium.CHALK)
	l.inscribe("filed", Ledger.Medium.FILED_PAPER)
	l.inscribe("photographed", Ledger.Medium.PHOTOGRAPH)
	l.inscribe("buried", Ledger.Medium.BURIED_CACHE)

	var seen_survives := l.survives("seen_only")
	# This sabotage was written as `seen_survives = false`, which is the value
	# it already had - so it changed nothing, the check passed, and the run
	# reported a caught mutation it had not caught. It has to assert the
	# OPPOSITE of the truth to be a sabotage at all: pretend that merely
	# witnessing something is enough to make it survive.
	if _sabotage == "memory_is_enough":
		seen_survives = true
	_ok("a thing only witnessed does NOT survive", not seen_survives,
		l.why_lost("seen_only"))

	# The chooser test: run it where the wrong answer is available. "Durable
	# media survive" means nothing unless a fragile one is present to lose.
	_ok("filed paper outlives its author", l.survives("filed"), "vs 4 other media")
	# This was written as `not l.survives("chalk") or true` against an id that
	# does not exist - a tautology that could never fail, checking nothing, in
	# the suite whose entire purpose is catching exactly that. Rewritten to
	# compare the fragile medium against the durable ones actually present.
	_ok("chalk does not outlive its author, unlike the durable media",
		not l.survives("chalked") and l.survives("filed") and l.survives("photographed"),
		"1 fragile vs 2 durable, all present in the same ledger")

	# Erasure. Modelled on a real and specific failure of the record: a thing
	# written where it could be washed off, washed off on an official order
	# before it could be photographed.
	l.suppress("chalked", "an official order")
	l.suppress("filed", "the institution that held it")
	l.suppress("buried", "the same order")
	_ok("chalk does not survive suppression", not l.survives("chalked"),
		l.why_lost("chalked"))
	_ok("an institution can destroy its own records", not l.survives("filed"),
		l.why_lost("filed"))
	_ok("a buried cache survives suppression", l.why_lost("buried") == "buried and never found",
		"suppression did not reach it; recovery is the open question")

	# Historically honest: burial is not a guarantee. Two of the three Oneg
	# Shabbat caches were recovered and the third never was, so the system
	# must be able to represent a record that was made correctly and still
	# lost. A mechanic that always rewards the right action is not a mechanic.
	_ok("a buried cache is lost until it is found", not l.survives("buried"),
		"burial alone is not survival")
	l.recover("buried")
	_ok("a recovered cache survives", l.survives("buried"), "recovered")

	# The denominator, and the honest reporting of failure.
	var survived := l.surviving_ids().size()
	var lost := l.lost_ids().size()
	_ok("every entry is accounted for as survived or lost", survived + lost == n,
		"%d survived + %d lost = %d of %d witnessed" % [survived, lost, survived + lost, n])
	_ok("the ledger can report losses, not only successes", lost > 0,
		"%d lost, each with a stated reason" % lost)


# --------------------------------------------------------------- archive ---

func test_archive() -> void:
	print("\n[the archive - real history, sourced or withheld]")
	var a := Archive.build_default()
	var n := a.count()
	_ok("archive has entries", n > 0, "%d entries" % n)
	if n == 0:
		_skipped("all remaining archive checks", "archive is empty, nothing to check against")
		return

	# The rule the whole layer exists for: an unsourced claim about real people
	# cannot reach a player. Run where the wrong answer is available - there
	# are both sourced and unsourced entries in the same archive, so this is
	# a chooser test rather than a check that everything is one way.
	var shown := a.displayable()
	var held := a.withheld()
	_ok("every entry is either displayable or withheld with a reason",
		shown.size() + held.size() == n,
		"%d shown + %d withheld = %d of %d" % [shown.size(), held.size(), shown.size() + held.size(), n])
	_ok("the archive contains both kinds, so this is a real test",
		shown.size() > 0 and held.size() > 0,
		"%d sourced, %d not" % [shown.size(), held.size()])

	var unsourced_shown := 0
	for e in shown:
		if e.sources.is_empty() or not e.verified:
			unsourced_shown += 1
	if _sabotage == "publish_unsourced":
		unsourced_shown = 1
	_ok("no unsourced or unverified entry is displayable", unsourced_shown == 0,
		"checked all %d displayable entries" % shown.size())

	# A withheld entry must say why. "Not shown" with no reason is the silent
	# skip CLAUDE.md rule 1 is about.
	var reasonless := 0
	for id in held:
		if String(held[id]).strip_edges().is_empty():
			reasonless += 1
	_ok("every withheld entry states its reason", reasonless == 0,
		"checked %d withheld" % held.size())

	# Real names belong here and nowhere else. Assert the seam directly: a
	# name that appears in the Archive must not appear on the roster.
	var roster_names := ""
	for p in Roster.PROTAGONISTS:
		roster_names += String(p["name"]) + " "
	var leaked := PackedStringArray()
	for real_name in ["Eddowes", "Kafka", "Ringelblum", "Warren", "Halse", "Arnold"]:
		if roster_names.contains(real_name):
			leaked.append(real_name)
	_ok("no real person named in the archive appears on the playable roster",
		leaked.is_empty(),
		"checked %d real names against %d protagonists" % [6, Roster.PROTAGONISTS.size()])


# ------------------------------------------------------------ relational ---

func test_relational() -> void:
	print("\n[relational facts - no view from nowhere]")
	var r := Relational.new()

	# Three states, not two. "Holds false" and "has no state about it" are
	# different things, and collapsing them is where the lie would enter.
	r.hold("the_wall_said_x", "halse_analogue", true)
	r.hold("the_wall_said_x", "long_analogue", false)
	# A third observer deliberately holds nothing.
	var n := r.fact_count()
	_ok("store populated", n > 0, "%d facts" % n)

	_ok("an observer who holds it true reads as such",
		r.stance_of("the_wall_said_x", "halse_analogue") == Relational.Stance.HOLDS_TRUE, "")
	_ok("an observer who holds it false is distinct from one who holds nothing",
		r.stance_of("the_wall_said_x", "long_analogue") == Relational.Stance.HOLDS_FALSE
		and r.stance_of("the_wall_said_x", "never_saw_it") == Relational.Stance.NO_STATE,
		"3 states present: true, false, no-state")

	# The disagreement is content, not error. Run where the wrong answer is
	# available: an undisputed fact is in the same store.
	r.hold("apron_was_found", "halse_analogue", true)
	r.hold("apron_was_found", "long_analogue", true)
	var disputed := r.disputed()
	if _sabotage == "reconcile_observers":
		disputed = PackedStringArray()
	_ok("contradictory accounts are surfaced, not reconciled",
		disputed.size() == 1 and disputed[0] == "the_wall_said_x",
		"%d disputed of %d facts, with an undisputed one present to lose" % [disputed.size(), r.fact_count()])

	# Anchoring: a person is held exactly like a record. Attenuation is this
	# number falling, which is Phase's documented cost rather than a metaphor.
	r.hold("cpl_hune", "moreau", true)
	r.hold("cpl_hune", "doig", true)
	r.hold("cpl_hune", "ferrer", true)
	_ok("a person's anchoring is the count of observers holding them",
		r.anchoring("cpl_hune") == 3, "3 observers")
	r.release("cpl_hune", "doig")
	r.release("cpl_hune", "ferrer")
	_ok("attenuation is anchoring falling", r.anchoring("cpl_hune") == 1, "1 observer left")
	_ok("still a fact for somebody", r.is_fact_for_anyone("cpl_hune"), "")
	r.release("cpl_hune", "moreau")
	_ok("real to nobody when the last observer releases",
		not r.is_fact_for_anyone("cpl_hune") and r.anchoring("cpl_hune") == 0,
		"anchoring 0")


# ------------------------------------------------------------- retrieval ---

func test_retrieval() -> void:
	print("\n[the consistency finding]")

	# The constraint, asserted across the whole enum rather than at one point,
	# so the denominator is the full range of record states.
	var all := [Retrieval.Certainty.UNRECORDED, Retrieval.Certainty.DISPUTED,
		Retrieval.Certainty.ATTESTED, Retrieval.Certainty.DOCUMENTED]
	var liftable := 0
	for c in all:
		if Retrieval.liftable(c):
			liftable += 1
	_ok("only some record states permit a retrieval", liftable > 0 and liftable < all.size(),
		"%d of %d certainty levels are liftable" % [liftable, all.size()])

	var doc := Retrieval.assess("subject_a", Retrieval.Certainty.DOCUMENTED, "NW")
	var unrec := Retrieval.assess("subject_b", Retrieval.Certainty.UNRECORDED, "NW")
	_ok("a person history is certain about cannot be taken", not doc.consistent,
		Retrieval.CERTAINTY_NAME[doc.certainty])
	_ok("a person history loses can be", unrec.consistent,
		Retrieval.CERTAINTY_NAME[unrec.certainty])

	# The programme produces paperwork, not decisions.
	_ok("the finding is a form and says who initialled it",
		doc.form_line.contains("Is the subject's absence consistent") and doc.form_line.contains("NW"),
		"form text present")

	# The ambiguity must stay open. The system computes eligibility and never
	# supplies a motive - if it ever gains a "reason refused" field beyond the
	# record's own certainty, it has answered the question the game exists to
	# keep open. Asserted structurally rather than trusted to a comment.
	var has_motive_field := false
	for prop in doc.get_property_list():
		var pname := String(prop["name"]).to_lower()
		if pname.contains("motive") or pname.contains("reason") or pname.contains("because"):
			has_motive_field = true
	if _sabotage == "explain_the_refusal":
		has_motive_field = true
	_ok("the finding never states a motive", not has_motive_field,
		"checked %d properties" % doc.get_property_list().size())

	# RQM: two observers reading two archives can disagree about the same
	# person and both be consistent. The programme has no procedure for this.
	var contested := Retrieval.assess_for_observer("subject_c", {
		"camp_iron_bell": Retrieval.Certainty.DISPUTED,
		"a_rival_team": Retrieval.Certainty.DOCUMENTED,
	})
	_ok("two observers can reach opposite findings about one person",
		Retrieval.is_contested(contested), "2 observers, opposite findings")

	var agreed := Retrieval.assess_for_observer("subject_d", {
		"camp_iron_bell": Retrieval.Certainty.DOCUMENTED,
		"a_rival_team": Retrieval.Certainty.DOCUMENTED,
	})
	_ok("agreement is distinguishable from contest",
		not Retrieval.is_contested(agreed), "both refuse, so not contested")


# -------------------------------------------------------- tutorial graph ---

func test_tutorial_graph() -> void:
	print("\n[act 0 - tutorial graph]")

	# Run it for EVERY protagonist, not one. The beats interpolate a practice
	# subject chosen relative to who the player picked, so checking a single
	# protagonist would test the chooser where the wrong answer is unavailable.
	var protagonists := Roster.ids()
	_ok("checking the graph for every protagonist", protagonists.size() == 6,
		"%d protagonists" % protagonists.size())

	var total_dangling := 0
	var total_orphans := 0
	var subject_is_self := 0
	var graphs_checked := 0

	for pid in protagonists:
		var g := TutorialBeats.beats(pid)
		graphs_checked += 1

		# The practice subject must never be the player. Signing the form that
		# retrieved yourself is a different scene and not this one.
		var subject := TutorialBeats.practice_subject(pid)
		if String(subject.get("id", "")) == pid:
			subject_is_self += 1

		# Every "next" and every choice target must exist. A beat pointing at
		# nothing ends the tutorial silently, which reads as finishing it.
		for id in g:
			var beat: Dictionary = g[id]
			var nxt := String(beat.get("next", ""))
			if not nxt.is_empty() and not g.has(nxt):
				total_dangling += 1
			for c in beat.get("choices", []):
				if not g.has(String(c["next"])):
					total_dangling += 1

		# No orphans: every authored beat must be reachable from the entry.
		var reachable := TutorialBeats.reachable_from("arrival", g)
		if _sabotage == "orphan_a_beat":
			reachable = PackedStringArray(["arrival"])
		for id in g:
			if not reachable.has(String(id)):
				total_orphans += 1

	_ok("every graph was actually built", graphs_checked == protagonists.size(),
		"%d of %d graphs" % [graphs_checked, protagonists.size()])
	_ok("no beat points at a beat that does not exist", total_dangling == 0,
		"%d dangling across %d graphs" % [total_dangling, graphs_checked])
	_ok("every authored beat is reachable from the entry", total_orphans == 0,
		"%d orphaned across %d graphs" % [total_orphans, graphs_checked])
	_ok("the practice subject is never the player", subject_is_self == 0,
		"checked all %d protagonists" % protagonists.size())

	# Exactly one terminal beat, and it is the departure. More than one means
	# a branch quietly stops; none means it cannot finish.
	var g0 := TutorialBeats.beats("moreau")
	var terminals := PackedStringArray()
	for id in g0:
		var beat: Dictionary = g0[id]
		if String(beat.get("next", "")).is_empty() and beat.get("choices", []).is_empty():
			terminals.append(String(id))
	_ok("exactly one terminal beat", terminals.size() == 1,
		"%d terminal(s): %s" % [terminals.size(), str(terminals)])

	# The refusal branch must rejoin. A player who asks what happens if they
	# write NO has to end up back at the form, because the loop is closed.
	_ok("the refusal branch rejoins the form",
		g0.has("refuse") and String(g0["refuse"]["next"]) == "the_form_again",
		"refuse -> the_form_again")


# ---------------------------------------------------- goulston street ---

func test_goulston_graph() -> void:
	print("\n[act one - goulston street graph]")
	var g := GoulstonBeats.beats()
	_ok("graph built", g.size() > 0, "%d beats" % g.size())

	var dangling := 0
	for id in g:
		var beat: Dictionary = g[id]
		var nxt := String(beat.get("next", ""))
		if not nxt.is_empty() and not g.has(nxt):
			dangling += 1
		for c in beat.get("choices", []):
			if not g.has(String(c["next"])):
				dangling += 1
	_ok("no beat points at a beat that does not exist", dangling == 0,
		"checked %d beats" % g.size())

	# Reuse TutorialBeats.reachable_from - it only reads "next"/"choices" keys
	# generically and never touches TutorialBeats.Kind, so it works on any
	# beat graph shaped this way. Reusing the checked implementation rather
	# than re-writing graph traversal a second time.
	var reachable := TutorialBeats.reachable_from("arrival", g)
	if _sabotage == "orphan_goulston_beat":
		reachable = PackedStringArray(["arrival"])
	var orphans := 0
	for id in g:
		if not reachable.has(String(id)):
			orphans += 1
	_ok("every beat is reachable from arrival", orphans == 0,
		"%d orphaned of %d" % [orphans, g.size()])

	# The three choices must lead to three DIFFERENT outcome beats. If two
	# collapsed to the same aftermath, the choice would be cosmetic.
	var choice_beat: Dictionary = g["the_choice"]
	var destinations := {}
	for c in choice_beat["choices"]:
		destinations[String(c["next"])] = true
	if _sabotage == "collapse_goulston_choices":
		destinations = {"aftermath_watched": true}
	_ok("the three choices lead to three distinct outcomes",
		destinations.size() == 3, "%d distinct destinations" % destinations.size())

	# Every terminal beat must eventually reach codex_note. A choice that
	# skipped the reflection beat would let the player miss the point.
	for outcome in ["aftermath_watched", "aftermath_transcribed", "aftermath_intervened"]:
		_ok("%s leads to the codex reflection" % outcome,
			g.has(outcome) and String(g[outcome]["next"]) == "codex_note",
			"checked directly")


func test_goulston_choices() -> void:
	print("\n[act one - the three choices produce three different survivals]")

	# Fresh GameState-shaped systems per run, without depending on the
	# autoload (this suite runs via --script, which does not init autoloads -
	# see the Act 0 commit's note on this exact trap). Build the pieces by
	# hand instead.
	var scenarios := [
		{"action": "watch", "expect_survives": false},
		{"action": "transcribe", "expect_survives": true},
		{"action": "intervene", "expect_survives": false},
	]

	# Two DISTINCT facts, matching the fix in goulston_scene.gd: the wall
	# (always suppressed, Warren has custody of it) and the player's own
	# record (never suppressed - a notebook in someone's pocket is not a
	# thing Warren can send a constable to sponge). An earlier version
	# suppressed both under one fact id, which meant "transcribe" - the
	# choice specifically designed to survive - never could. This test is
	# what caught that, and it stays written against the two-fact model so
	# the same conflation cannot silently come back.
	var checked := 0
	for s in scenarios:
		var ledger := Ledger.new()
		var facts := Relational.new()
		var exposure := Exposure.new(120)
		var wall := "wall_test"
		var record := "record_test"

		ledger.witness(wall, 1888)
		ledger.inscribe(wall, Ledger.Medium.CHALK)
		ledger.suppress(wall, "Metropolitan Police, on Warren's order")

		match String(s["action"]):
			"watch":
				facts.hold(record, "protagonist", true)
				ledger.witness(record, 1888)
			"transcribe":
				facts.hold(record, "protagonist", true)
				ledger.witness(record, 1888)
				ledger.inscribe(record, Ledger.Medium.FILED_PAPER)
				facts.hold(record, "halse_transcription", true)
			"intervene":
				facts.hold(record, "protagonist", true)
				ledger.witness(record, 1888)
				exposure.spend(30, "test intervention")
				exposure.witness("test intervention witnessed")

		_ok("the wall is lost regardless of the player's choice ('%s')" % String(s["action"]),
			not ledger.survives(wall), ledger.why_lost(wall))

		var survives: bool = ledger.survives(record)
		if _sabotage == "flip_transcribe_survival" and String(s["action"]) == "transcribe":
			survives = false
		_ok("'%s' record survival matches design intent" % String(s["action"]),
			survives == bool(s["expect_survives"]),
			"got survives=%s, expected=%s" % [survives, s["expect_survives"]])
		checked += 1

	_ok("all three scenarios were actually run", checked == scenarios.size(),
		"%d of %d" % [checked, scenarios.size()])


# ---------------------------------------------------- flower and dean ---

func test_flower_dean_graph() -> void:
	print("\n[act one, scene two - flower and dean street graph]")
	var g := FlowerDeanBeats.beats()
	_ok("graph built", g.size() > 0, "%d beats" % g.size())

	var dangling := 0
	for id in g:
		var beat: Dictionary = g[id]
		var nxt := String(beat.get("next", ""))
		if not nxt.is_empty() and not g.has(nxt):
			dangling += 1
		for c in beat.get("choices", []):
			if not g.has(String(c["next"])):
				dangling += 1
	_ok("no beat points at a beat that does not exist", dangling == 0,
		"checked %d beats" % g.size())

	var reachable := TutorialBeats.reachable_from("arrival", g)
	if _sabotage == "orphan_flower_dean_beat":
		reachable = PackedStringArray(["arrival"])
	var orphans := 0
	for id in g:
		if not reachable.has(String(id)):
			orphans += 1
	_ok("every beat is reachable from arrival", orphans == 0,
		"%d orphaned of %d" % [orphans, g.size()])

	# Both choice points in this scene must lead to genuinely distinct beats,
	# same reasoning as Goulston Street's chooser test.
	for choice_beat_id in ["the_choice", "the_cellar_choice"]:
		var beat: Dictionary = g[choice_beat_id]
		var destinations := {}
		for c in beat["choices"]:
			destinations[String(c["next"])] = true
		_ok("%s leads to distinct outcomes" % choice_beat_id, destinations.size() == beat["choices"].size(),
			"%d distinct of %d choices" % [destinations.size(), beat["choices"].size()])

	# The two things this scene must never say out loud must never appear as
	# literal text in any beat's lines. This is a blunt lexical check, not a
	# semantic one, but it catches the most likely accidental regression: a
	# future edit adding an explanatory line that states the point instead
	# of letting the mechanic make it.
	var forbidden := ["programme benefits", "could retrieve", "nobody has suggested retrieving"]
	var violations := PackedStringArray()
	for id in g:
		var beat: Dictionary = g[id]
		var text := " ".join(PackedStringArray(beat.get("lines", []))).to_lower()
		for phrase in forbidden:
			if text.contains(phrase):
				violations.append("%s contains '%s'" % [id, phrase])
	if _sabotage == "state_the_unspoken_thing":
		violations.append("codex_note contains 'programme benefits' (forced)")
	_ok("neither unspoken conclusion is stated as dialogue anywhere in the scene",
		violations.is_empty(), "checked %d beats against %d forbidden phrases" % [g.size(), forbidden.size()])


func test_flower_dean_investigator_choice() -> void:
	print("\n[the investigator choice actually changes the finding]")

	# Mirror flower_dean_scene.gd's _advance() logic directly for "help",
	# without depending on the autoload (see the Act 0 note on --script mode).
	var facts_help := Relational.new()
	var sid := "resident_test"
	facts_help.hold(sid, "flower_dean_parish_ledger", true)
	var finding_help := Retrieval.assess(sid, Retrieval.Certainty.DOCUMENTED, "")

	var facts_hinder := Relational.new()
	facts_hinder.hold(sid, "flower_dean_parish_ledger", false)
	var finding_hinder := Retrieval.assess(sid, Retrieval.Certainty.DISPUTED, "")

	if _sabotage == "flatten_investigator_choice":
		finding_help.consistent = finding_hinder.consistent

	_ok("helping her enter the record makes the subject un-retrievable",
		not finding_help.consistent, Retrieval.CERTAINTY_NAME[finding_help.certainty])
	_ok("hindering her leaves the subject retrievable",
		finding_hinder.consistent, Retrieval.CERTAINTY_NAME[finding_hinder.certainty])
	_ok("the two choices produce genuinely different findings",
		finding_help.consistent != finding_hinder.consistent,
		"help=%s hinder=%s" % [finding_help.consistent, finding_hinder.consistent])


# --------------------------------------------------------------- summary ---

func _summary() -> void:
	print("\n=== %d checks: %d passed, %d failed, %d not checked ===" % [_checks, _pass, _fail, _skip])
	if _checks == 0:
		print("!! ZERO CHECKS RAN. The harness is broken, not the code.")
		_fail += 1
		return

	# A sabotage that breaks nothing is not evidence that the code is sound;
	# it is evidence that the sabotage stopped matching. Without this guard the
	# run prints "all passed" and reads exactly like proof. Caught here after
	# memory_is_enough silently did nothing for a full run.
	if not _sabotage.is_empty() and _fail == 0:
		print("!! SABOTAGE '%s' BROKE NOTHING." % _sabotage)
		print("   Expected at least one FAIL. Either the sabotage no longer")
		print("   matches the code it was written against, or the check it")
		print("   targets is not actually checking anything. This is a hard")
		print("   failure - it is not a passing run.")
		_fail += 1
		return
	if _fail == 0 and _skip > 0:
		print("no failures, but %d NOT CHECKED - this run did not verify everything" % _skip)
	elif _fail == 0:
		print("all passed")
