class_name Enemies
extends RefCounted

## Combat opponents for the 1944 front: Werk Nachtigall and Hyakki Yakō,
## per Dan's direction that Project 42's party fights the other two
## factions directly in the main game, distinct from the restrained,
## non-magical 1888 Whitechapel vignettes elsewhere in this project (which
## are unchanged and stay that way - Werk Nachtigall is debris-only there,
## Hyakki Yakō is never physically present there, both per lore rulings
## specific to 1888).
##
## WEREK NACHTIGALL: built directly from the established, decided taxonomy
## in world-aflame-godot/docs/WORLD-BESTIARY.md §6a ("24 types... decisions,
## not proposals"). Real canon designations and troop nicknames, not
## invented ones - Muster 12 "patients", Baureihe 7 "whistlers", Muster 4
## "bakers", and so on.
##
## TONE, per Dan directly: "horrific early biologists style... many of them
## were serious monsters." This is not a new direction, it is the bible's
## own thesis (§1 - the Fischer/Mengele lineage, the Herero and Nama
## genocide) applied to how this content actually reads in play. The
## register stays clinical and bureaucratic on purpose - "the Office" euphemism
## is the horror, not decoration on top of it (bible §2 rule 4: no magic, it
## is achievable with cruelty plus budget) - and rule 7: institutions get no
## interiority, no redemption, ever, in the flavour text or anywhere else.
##
## HYAKKI YAKŌ: deliberately NOT built the same way. The lore explicitly
## flags that this faction needs a guard the bestiary does not -
## "the bestiary catalogues products, the roster is a list of what was done
## to people, and the moment it reads as a bestiary this faction has become
## the caricature" - and the file that fixes its 25 canon forms,
## HY-THE-FUSED-ROSTER.md, does not exist in the shared repo yet. Rather
## than invent monster forms ahead of that guard, HY encounters here use
## only what IS already decided: the Fog branch is "concealment that is not
## hiding... a person who is a fact for fewer of the people present," which
## is a disorientation effect, not a creature design. See docs/RESOURCES.md
## for this as an open dependency.

const WERK_NACHTIGALL := [
	{"id":"wn_patients","name":"Muster 12 — \"patients\"","hp":90,"atk":16,"def":16,"spd":8,
	 "flavor":"Armoured, slow, telegraphs. The root of the Kadaver line."},
	{"id":"wn_seconds","name":"Muster 12/b — \"seconds\"","hp":100,"atk":17,"def":17,"spd":8,
	 "flavor":"A rebuilt 12. Reissue on the line item."},
	{"id":"wn_long_shifts","name":"Muster 17 — \"long shifts\"","hp":140,"atk":13,"def":14,"spd":6,
	 "flavor":"Endurance model. Does not stop, and was not designed to be able to."},
	{"id":"wn_whistlers","name":"Baureihe 7 — \"whistlers\"","hp":70,"atk":19,"def":9,"spd":18,
	 "flavor":"Fast, closes distance, answers a whistle."},
	{"id":"wn_night_whistlers","name":"Baureihe 7/n — \"night whistlers\"","hp":74,"atk":20,"def":9,"spd":19,
	 "flavor":"The same, worked in the dark. The whistle carries further than you would like."},
	{"id":"wn_walkers","name":"Gestell 4 — \"walkers\"","hp":60,"atk":22,"def":6,"spd":7,
	 "flavor":"Exoframes. Barely function. Still funded."},
	{"id":"wn_bakers","name":"Muster 4 — \"bakers\"","hp":110,"atk":10,"def":12,"spd":5,
	 "flavor":"Spatial, slow, smells of bread. Not a duel — a room becoming unavailable."},
	{"id":"wn_the_risen","name":"Muster 7 — \"the risen\"","hp":95,"atk":18,"def":11,"spd":10,
	 "flavor":"The Office means it as dough rises. Neither side can tell which meaning applies from the paperwork alone. Never resolved, in either direction."},
]

## A boss-scale extrapolation from the same decided line (Gestell 4
## "walkers", canon per WORLD-BESTIARY.md §6a) rather than an invented
## design pasted on top of it - a command-scale exoframe is the same kind
## of extrapolation a card generator would make from an established root.
const WN_BOSS := {
	"id":"wn_gestell_command","name":"a Gestell command frame","hp":320,"atk":26,"def":22,"spd":9,
	"flavor":"Barely functions, same as every walker. This one is bigger, and the Office funded it anyway."}

## Fog-branch only, per the restraint above. Framed as disorientation and
## observation effects rather than named monster forms - lower HP, but they
## do things to Exposure and to the party's own stances rather than raw
## damage, matching "a person who is a fact for fewer of the people present."
const HYAKKI_YAKO := [
	{"id":"hy_fog_presence","name":"a presence, half-arrived","hp":55,"atk":14,"def":10,"spd":14,
	 "flavor":"Not quite here. Nobody in the party can agree, afterward, on how many there were."},
	{"id":"hy_fog_watcher","name":"something that was already watching","hp":65,"atk":12,"def":13,"spd":11,
	 "flavor":"It does not attack so much as continue to have been here the whole time."},
]


static func make_combatant(entry: Dictionary, index: int) -> Combatant:
	var c := Combatant.new()
	c.id = "%s_%d" % [String(entry["id"]), index]
	c.display_name = String(entry["name"])
	c.is_player_side = false
	c.max_hp = int(entry["hp"])
	c.hp = c.max_hp
	c.atk = int(entry["atk"])
	c.def = int(entry["def"])
	c.spd = int(entry["spd"])
	return c


static func encounter(faction: String, count: int) -> Array[Combatant]:
	var pool: Array = WERK_NACHTIGALL if faction == "werk_nachtigall" else HYAKKI_YAKO
	var out: Array[Combatant] = []
	if pool.is_empty():
		push_error("Enemies.encounter('%s') has no pool to draw from." % faction)
		return out
	for i in count:
		var entry: Dictionary = pool[i % pool.size()]
		out.append(make_combatant(entry, i))
	return out
