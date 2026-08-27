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
