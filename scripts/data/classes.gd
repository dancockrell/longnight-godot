class_name Classes
extends RefCounted

## Twenty playable classes, FF1-style: archetypes the player names and
## assembles into a party, not pre-written individuals with finished
## biographies. This exists because "waiting for characters" (finished,
## lore-approved named protagonists) does not have to block a playable
## party system - a class is a role and a stat spread, and none of that
## needs the deeper writing the six named protagonists in roster.gd still
## do. Those six remain as pre-built notable individuals for story scenes;
## this file is what the player actually builds a party FROM.
##
## Six roles per pillar (Current, Chrono, Phase) plus two hybrids = 20.
## Every class is an invention - no real person, per the standing rule.
## Every origin_year is 1944: these are camp trainees, not settled people
## displaced from another century, which is a different and unrelated
## status this project already models elsewhere (see WORLD-THE-SETTLED.md
## and roster.gd's three canon Settled protagonists).

const CHRONO := Pillars.Kind.CHRONO
const PHASE := Pillars.Kind.PHASE
const CURRENT := Pillars.Kind.CURRENT

## Fields mirror roster.gd's protagonist shape closely enough that
## Combatant.from_roster() works unmodified on a class entry - a class is
## simply a lighter-weight version of the same shape, with a role/flavor
## instead of a thesis/bill (classes make no ethical argument themselves;
## that is a property of a written individual, not an archetype).
const ALL := [
	# ---------------------------------------------------------- CURRENT --
	{"id":"anchor_current","name":"Charged Guard","pillar":CURRENT,"origin_year":1944,"role":"anchor",
	 "hp":180,"focus":50,"atk":15,"def":22,"spd":9,
	 "flavor":"Holds the line and the current both. Highest guard of any class."},
	{"id":"livewire","name":"Live Wire","pillar":CURRENT,"origin_year":1944,"role":"wildcard",
	 "hp":100,"focus":70,"atk":24,"def":9,"spd":15,
	 "flavor":"Trades guard for damage. A Live Wire who is caught loud does not get a second warning."},
	{"id":"conduit","name":"Current Handler","pillar":CURRENT,"origin_year":1944,"role":"quartermaster",
	 "hp":130,"focus":85,"atk":13,"def":15,"spd":11,
	 "flavor":"Routes current to whoever needs it. Every buff a Current Handler grants is paid for in Exposure."},
	{"id":"arc_medic","name":"Arc Medic","pillar":CURRENT,"origin_year":1944,"role":"medic",
	 "hp":128,"focus":90,"atk":11,"def":14,"spd":12,
	 "flavor":"Field medicine run through a coil. Effective, and never once explained to the patient."},
	{"id":"groundsman","name":"Grounded Guard","pillar":CURRENT,"origin_year":1944,"role":"anchor",
	 "hp":160,"focus":55,"atk":12,"def":24,"spd":8,
	 "flavor":"Earths a fight before it earths someone's nervous system. Slow, and very hard to move."},
	{"id":"voltaic_scout","name":"Charged Scout","pillar":CURRENT,"origin_year":1944,"role":"infiltrator",
	 "hp":112,"focus":75,"atk":18,"def":11,"spd":18,
	 "flavor":"First across the wire, first to draw attention. Fast enough that it rarely matters."},
	# ----------------------------------------------------------- CHRONO --
	{"id":"archivist","name":"Record Clerk","pillar":CHRONO,"origin_year":1944,"role":"analyst",
	 "hp":118,"focus":95,"atk":12,"def":13,"spd":13,
	 "flavor":"Weakens what the record already doubts. Strongest against anything undocumented."},
	{"id":"forecaster","name":"Forecaster","pillar":CHRONO,"origin_year":1944,"role":"analyst",
	 "hp":122,"focus":92,"atk":16,"def":12,"spd":14,
	 "flavor":"Knows how a fight ends before the first blow. Says nothing, and lands the second one."},
	{"id":"loop_runner","name":"Loop Runner","pillar":CHRONO,"origin_year":1944,"role":"wildcard",
	 "hp":108,"focus":80,"atk":20,"def":10,"spd":20,
	 "flavor":"Acts first, always. A closed loop has to start somewhere."},
	{"id":"custodian","name":"Record Custodian","pillar":CHRONO,"origin_year":1944,"role":"anchor",
	 "hp":172,"focus":60,"atk":14,"def":21,"spd":9,
	 "flavor":"Keeps a record from being altered by keeping the people near it alive."},
	{"id":"witness","name":"Ledger Medic","pillar":CHRONO,"origin_year":1944,"role":"medic",
	 "hp":124,"focus":88,"atk":10,"def":15,"spd":12,
	 "flavor":"Heals by making sure a wound was seen and logged. Slower than a bandage. More permanent."},
	{"id":"actuary","name":"Actuary","pillar":CHRONO,"origin_year":1944,"role":"wildcard",
	 "hp":114,"focus":78,"atk":22,"def":9,"spd":16,
	 "flavor":"Works entirely in probabilities. Devastating when the odds run long, silent when they don't."},
	# ------------------------------------------------------------ PHASE --
	{"id":"wraith","name":"Ghost Scout","pillar":PHASE,"origin_year":1944,"role":"infiltrator",
	 "hp":102,"focus":90,"atk":21,"def":8,"spd":19,
	 "flavor":"Half out of phase at all times. Hard to hit. Harder, some nights, to be sure of."},
	{"id":"cipher","name":"Cipher","pillar":PHASE,"origin_year":1944,"role":"analyst",
	 "hp":110,"focus":88,"atk":14,"def":11,"spd":15,
	 "flavor":"Nothing about a Cipher is where it appears to be, including the Cipher."},
	{"id":"threshold","name":"Threshold Guard","pillar":PHASE,"origin_year":1944,"role":"anchor",
	 "hp":164,"focus":65,"atk":13,"def":20,"spd":10,
	 "flavor":"Stands in the doorway between here and not-quite-here. Foes find it difficult to commit to a target."},
	{"id":"shadow_medic","name":"Shadow Medic","pillar":PHASE,"origin_year":1944,"role":"medic",
	 "hp":120,"focus":86,"atk":10,"def":13,"spd":14,
	 "flavor":"Treats wounds that have not fully arrived yet. The patient usually feels better before understanding why."},
	{"id":"rumour","name":"Rumour Runner","pillar":PHASE,"origin_year":1944,"role":"quartermaster",
	 "hp":116,"focus":82,"atk":12,"def":12,"spd":16,
	 "flavor":"Spreads a misdirection thin enough that everyone believes a different piece of it."},
	{"id":"attenuator","name":"Faded Soldier","pillar":PHASE,"origin_year":1944,"role":"wildcard",
	 "hp":98,"focus":96,"atk":26,"def":7,"spd":17,
	 "flavor":"The furthest out of phase a person can go and still come back. Most nights."},
	# ---------------------------------------------------------- HYBRIDS --
	{"id":"proprietor","name":"The Proprietor","pillar":CURRENT,"origin_year":1944,"role":"quartermaster",
	 "hp":150,"focus":70,"atk":13,"def":18,"spd":11,
	 "flavor":"Signs the requisitions. Has never once asked what they were for, and is very good at the job."},
	{"id":"the_question","name":"The Question","pillar":CHRONO,"origin_year":1944,"role":"wildcard",
	 "hp":126,"focus":84,"atk":18,"def":13,"spd":13,
	 "flavor":"Carries no fixed position on what the programme is entitled to do. Neither does the fight."},
]


static func ids() -> PackedStringArray:
	var out := PackedStringArray()
	for c in ALL:
		out.append(c["id"])
	return out


static func by_id(id: String) -> Dictionary:
	for c in ALL:
		if c["id"] == id:
			return c
	push_error("Classes.by_id('%s') found nothing. Known ids: %s." % [id, str(ids())])
	return {}


static func by_pillar(pillar: Pillars.Kind) -> Array:
	return ALL.filter(func(c): return c["pillar"] == pillar)
