extends SceneTree

## Volume test for the central design claim.
##
##     godot --headless --script res://tests/sweep_exposure.gd
##
## The single-seed check in run_tests.gd passed at loud=84 vs quiet=80 - a 5%
## margin, which is thin enough to be noise rather than a mechanic. CLAUDE.md
## rule 18 says to ask what N would have to be before the bug could occur and
## run at least that many. One seed cannot distinguish "the system works" from
## "this seed happened to agree", so this runs the comparison across many.

const SEEDS := 400


func _init() -> void:
	print("=== stance noise sweep: %d paired runs ===" % SEEDS)
	var loud_wins := 0
	var quiet_wins := 0
	var ties := 0
	var loud_total := 0
	var quiet_total := 0
	var rounds_loud := 0
	var rounds_quiet := 0
	var wit_loud := 0
	var wit_quiet := 0

	for s in SEEDS:
		var q := _run(Combatant.Stance.COVERED, s)
		var l := _run(Combatant.Stance.FORWARD, s)
		quiet_total += int(q["exposure"])
		loud_total += int(l["exposure"])
		rounds_quiet += int(q["rounds"])
		rounds_loud += int(l["rounds"])
		wit_loud += int(l["witnesses"])
		wit_quiet += int(q["witnesses"])
		if int(l["exposure"]) > int(q["exposure"]):
			loud_wins += 1
		elif int(l["exposure"]) < int(q["exposure"]):
			quiet_wins += 1
		else:
			ties += 1

	var checked := loud_wins + quiet_wins + ties
	print("paired runs compared: %d (denominator - must equal %d)" % [checked, SEEDS])
	if checked != SEEDS:
		print("!! the sweep did not run every pair. Result below is meaningless.")
		quit(1)
		return

	print("loud louder: %d   quiet louder: %d   tied: %d" % [loud_wins, quiet_wins, ties])
	print("mean exposure  loud=%.1f  quiet=%.1f  (ratio %.2fx)" % [
		float(loud_total) / SEEDS, float(quiet_total) / SEEDS,
		float(loud_total) / maxf(1.0, float(quiet_total))])
	print("mean rounds    loud=%.1f  quiet=%.1f" % [
		float(rounds_loud) / SEEDS, float(rounds_quiet) / SEEDS])

	var rate := float(loud_wins) / float(SEEDS)
	print("\nloud-is-louder in total noise: %.1f%% of runs" % (rate * 100.0))

	# The property, not the call. "Loud is louder" was the wrong assertion -
	# it passed at a 1.07x ratio while the loud party won in half the rounds,
	# which made going loud strictly better and the meter decorative. What has
	# to be true is that going loud leaves a mark that cannot be undone.
	print("mean witnesses  loud=%.2f  quiet=%.2f" % [
		float(wit_loud) / SEEDS, float(wit_quiet) / SEEDS])

	var failures := PackedStringArray()
	if rate < 0.95:
		failures.append("total noise is not reliably higher for a loud party")
	if wit_loud <= wit_quiet:
		failures.append("a loud party leaves no more permanent records than a quiet one - the threshold is doing nothing")
	if wit_quiet > 0 and float(wit_loud) / float(maxi(1, wit_quiet)) < 2.0:
		failures.append("loud leaves under 2x the records of quiet - not enough to change a decision")

	if failures.is_empty():
		print("VERDICT: holds. Going loud is priced.")
		quit(0)
	else:
		print("VERDICT: FAIL.")
		for f in failures:
			print("  - %s" % f)
		quit(1)


func _run(stance: Combatant.Stance, seed_value: int) -> Dictionary:
	var party: Array[Combatant] = []
	for id in ["moreau", "hune", "ferrer"]:
		var c := Combatant.from_roster(Roster.by_id(id))
		c.stance = stance
		party.append(c)
	var foes: Array[Combatant] = []
	for i in 3:
		var f := Combatant.new()
		f.id = "foe_%d" % i
		f.display_name = "retrieval man %d" % i
		f.is_player_side = false
		f.max_hp = 90
		f.hp = 90
		f.atk = 14
		f.def = 10
		f.spd = 12
		foes.append(f)
	var e := Exposure.new(100000)
	var r := Battle.new(party, foes, e, seed_value).run_to_completion()
	return {"exposure": e.value, "rounds": int(r["rounds"]), "witnesses": e.witnesses.size()}
