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


# --------------------------------------------------------------- summary ---

func _summary() -> void:
	print("\n=== %d checks: %d passed, %d failed, %d not checked ===" % [_checks, _pass, _fail, _skip])
	if _checks == 0:
		print("!! ZERO CHECKS RAN. The harness is broken, not the code.")
		_fail += 1
		return
	if _fail == 0 and _skip > 0:
		print("no failures, but %d NOT CHECKED - this run did not verify everything" % _skip)
	elif _fail == 0:
		print("all passed")
