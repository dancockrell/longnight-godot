class_name Battle
extends RefCounted

## Turn-based combat, evolved from the canvas engine's threat/stance model and
## wired into Exposure so that fighting is never free.
##
## The design claim this is built to test: a fight the player wins loudly can
## be worse than one they lose quietly. If the harness cannot produce that
## outcome, the claim is wrong and the numbers need to change - not the test.

signal acted(actor_id: String, description: String)
signal battle_ended(player_won: bool)

## The threshold at which one action stops being noise and becomes a record.
## Placeholder, and deliberately reachable by a Forward pillar user and not by
## a Covered one - if it ever sits outside that window it is doing nothing.
const LOUD_ENOUGH_TO_BE_WRITTEN_DOWN := 5

const THREAT_RATE := {
	"anchor": 2.4,
	"quartermaster": 1.6,
	"infiltrator": 1.0,
	"wildcard": 1.0,
	"analyst": 0.8,
	"medic": 0.55,
}

var party: Array[Combatant] = []
var foes: Array[Combatant] = []
var exposure: Exposure = null

var round_number: int = 0
var log_lines: PackedStringArray = []

## Deterministic by default. A combat model that cannot be replayed cannot be
## debugged, and Date.now()/randomize() would make the harness unrepeatable.
var _rng := RandomNumberGenerator.new()


func _init(p: Array[Combatant], f: Array[Combatant], exp_meter: Exposure, seed_value: int = 42) -> void:
	if p.is_empty() or f.is_empty():
		push_error("Battle started with %d party and %d foes. An empty side means every round resolves instantly and the winner is whoever was not empty, which reads exactly like a working fight." % [p.size(), f.size()])
		return
	party = p
	foes = f
	exposure = exp_meter
	_rng.seed = seed_value


func living_party() -> Array[Combatant]:
	return party.filter(func(c): return c.alive)


func living_foes() -> Array[Combatant]:
	return foes.filter(func(c): return c.alive)


## Initiative order, fastest first, recomputed each round so speed buffs matter.
func turn_order() -> Array[Combatant]:
	var all: Array[Combatant] = []
	all.append_array(living_party())
	all.append_array(living_foes())
	all.sort_custom(func(a, b): return a.spd > b.spd)
	return all


## The core action. Returns the damage dealt, and spends Exposure for the
## noise it made - which is the whole point of the system.
func attack(actor: Combatant, target: Combatant, power: float = 1.0, use_pillar: bool = false) -> int:
	if not actor.alive or not target.alive:
		return 0

	var raw := (float(actor.atk) * power * actor.stance_out()) - (float(target.def) * 0.5)
	var jitter := _rng.randf_range(0.92, 1.08)
	var dealt: int = maxi(1, int(raw * jitter * target.stance_in()))
	target.take_damage(dealt)

	if actor.is_player_side:
		_add_threat(actor, float(dealt))
		_spend_noise(actor, use_pillar, dealt)

	var line := "%s hits %s for %d" % [actor.display_name, target.display_name, dealt]
	log_lines.append(line)
	acted.emit(actor.id, line)
	return dealt


## Using programme technology in a period with no vocabulary for it is the
## expensive move. A plain fist-fight in 1888 costs almost nothing; a Tesla
## arc in a public street costs a great deal.
func _spend_noise(actor: Combatant, use_pillar: bool, magnitude: int) -> void:
	if exposure == null:
		return
	var base := 1
	if use_pillar:
		base = Pillars.base_exposure(actor.pillar)
		if base < 0:
			return
	var amount: int = maxi(1, int(float(base) * actor.stance_noise() + float(actor.anachronism) * 0.5))
	var why := "%s used %s (%d dmg)" % [
		actor.display_name,
		Pillars.display_name(actor.pillar) if use_pillar else "nothing the period cannot explain",
		magnitude,
	]
	exposure.spend(amount, why)

	# A single action past this line is not noise the period absorbs. Somebody
	# saw it and somebody wrote it down, and no amount of lying low afterwards
	# unwrites it. This is the part that actually prices going loud - see the
	# comment on Exposure.witnesses for the measurement that forced it.
	if amount >= LOUD_ENOUGH_TO_BE_WRITTEN_DOWN:
		exposure.witness(why)


func _add_threat(actor: Combatant, amount: float) -> void:
	# Reads actor.role directly rather than calling Roster.by_id(actor.id).
	# That call only ever found protagonists in roster.gd - it silently
	# returned {} (and pushed an error) for anyone built from classes.gd,
	# so every class-based party member got role_rate 1.0 with no signal
	# that the lookup had failed for the wrong reason.
	var role_rate: float = THREAT_RATE.get(actor.role, 1.0)
	actor.threat += amount * role_rate


## Whoever the enemy is looking at. Threat is attention, and attention is the
## same currency the era spends - that symmetry is deliberate.
func threat_target() -> Combatant:
	var alive_party := living_party()
	if alive_party.is_empty():
		return null
	var best: Combatant = alive_party[0]
	for c in alive_party:
		if c.threat > best.threat:
			best = c
	return best


## Runs one full round. Returns true while the battle is still going.
func step_round() -> bool:
	if living_party().is_empty() or living_foes().is_empty():
		return false
	round_number += 1
	for actor in turn_order():
		if not actor.alive:
			continue
		if living_party().is_empty() or living_foes().is_empty():
			break
		if actor.is_player_side:
			var t := living_foes()
			if not t.is_empty():
				attack(actor, t[0], 1.0, actor.focus > 20)
				actor.focus = maxi(0, actor.focus - 6)
		else:
			var t := threat_target()
			if t != null:
				attack(actor, t)
	var over := living_party().is_empty() or living_foes().is_empty()
	if over:
		battle_ended.emit(not living_party().is_empty())
	return not over


## Convenience for the harness. max_rounds is a guard against a model that
## cannot resolve - it reports rather than looping forever, and the caller is
## expected to treat hitting it as a failure, not a draw.
func run_to_completion(max_rounds: int = 200) -> Dictionary:
	while step_round():
		if round_number >= max_rounds:
			return {
				"resolved": false,
				"rounds": round_number,
				"player_won": false,
				"reason": "hit max_rounds - the damage model cannot kill anything",
			}
	return {
		"resolved": true,
		"rounds": round_number,
		"player_won": not living_party().is_empty(),
		"reason": "",
	}
