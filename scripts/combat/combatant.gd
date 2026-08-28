class_name Combatant
extends RefCounted

## One participant in a battle. Used for both the player's party and for the
## rival retrieval teams they run into working the same historical moment.

enum Stance { MEASURED, FORWARD, COVERED }

## Stance trades damage dealt against damage taken, and - new for this game -
## against how loud you are. Going forward in a public street in 1888 is not
## just risky, it is legible.
const STANCE_DATA := {
	Stance.MEASURED: {"out": 1.0, "inn": 1.0, "noise": 1.0, "label": "Measured"},
	Stance.FORWARD: {"out": 1.25, "inn": 1.3, "noise": 1.5, "label": "Forward"},
	Stance.COVERED: {"out": 0.75, "inn": 0.7, "noise": 0.6, "label": "Covered"},
}

var id: String = ""
var display_name: String = ""
var pillar: Pillars.Kind = Pillars.Kind.CHRONO
var is_player_side: bool = true
## Read directly by Battle for threat-rate lookup, rather than Battle doing
## a live Roster.by_id(actor.id) call - that call only ever found protagonists
## in roster.gd and silently returned {} for anyone built from classes.gd,
## which would have made every class-based party member threat-rate 1.0
## with no error to notice it by. Set once at construction; the source data
## (Roster or Classes) never needs to be looked up again after this.
var role: String = ""

var max_hp: int = 1
var hp: int = 1
var max_focus: int = 0
var focus: int = 0
var atk: int = 0
var def: int = 0
var spd: int = 0

var stance: Stance = Stance.MEASURED
var threat: float = 0.0
var alive: bool = true

## How much of the era's attention this combatant personally attracts by
## existing here. A man from 1799 in 1888 is nearly invisible. A woman from
## 2011 is not.
var anachronism: int = 0


static func from_roster(entry: Dictionary) -> Combatant:
	if entry.is_empty():
		push_error("Combatant.from_roster() given an empty entry. Refusing to build a placeholder combatant, which would run the whole battle against a character that does not exist.")
		return null
	var c := Combatant.new()
	c.id = String(entry["id"])
	c.display_name = String(entry["name"])
	c.pillar = entry["pillar"]
	c.max_hp = int(entry["hp"])
	c.hp = c.max_hp
	c.max_focus = int(entry["focus"])
	c.focus = c.max_focus
	c.atk = int(entry["atk"])
	c.def = int(entry["def"])
	c.spd = int(entry["spd"])
	c.role = String(entry.get("role", ""))
	c.anachronism = _anachronism_for(int(entry["origin_year"]))
	return c


## Distance from the host period, in either direction. Set per-era at battle
## start; 1888 is the default host until the era system lands.
static func _anachronism_for(origin_year: int, host_year: int = 1888) -> int:
	var gap: int = absi(origin_year - host_year)
	return int(clampf(float(gap) / 20.0, 0.0, 8.0))


func stance_out() -> float:
	return STANCE_DATA[stance]["out"]


func stance_in() -> float:
	return STANCE_DATA[stance]["inn"]


func stance_noise() -> float:
	return STANCE_DATA[stance]["noise"]


func take_damage(n: int) -> int:
	var applied: int = maxi(0, n)
	hp = maxi(0, hp - applied)
	if hp == 0:
		alive = false
	return applied


func heal(n: int) -> int:
	if not alive:
		return 0
	var before := hp
	hp = mini(max_hp, hp + maxi(0, n))
	return hp - before


func spend_focus(n: int) -> bool:
	if n > focus:
		return false
	focus -= n
	return true
