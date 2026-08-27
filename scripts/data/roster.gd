class_name Roster
extends RefCounted

## The six playable protagonists. You pick one; the rest of the party is
## recruited across the eras.
##
## EVERY ONE IS AN INVENTION. No real person is ever a playable piece in this
## universe - LORE-BIBLE.md section 2 rule 9. Real authors, philosophers and
## historical figures appear as encountered NPCs and never as units.
##
## Six because each has to carry a distinct argument about the programme, and
## six distinct arguments is as many as this story actually has. They are not
## six flavours of soldier; they are six answers to "what is Camp Iron Bell
## entitled to do?", and the party's internal disagreement is the spine of the
## writing.
##
## Bios here are one-line design intents, not final text. No story prose is
## written until the faction and period rulings land.

const CHRONO := Pillars.Kind.CHRONO
const PHASE := Pillars.Kind.PHASE
const CURRENT := Pillars.Kind.CURRENT

## Fields:
##   origin_year  - when they are from. 1944 means camp staff.
##   thesis       - their answer to what the programme is entitled to do.
##   bill         - the cost the bible requires this character to keep visible
##                  (section 2 rule 6: the Allies do not get a clean war).
const PROTAGONISTS := [
	{
		"id": "moreau",
		"name": "Staff Sergeant Ada Moreau",
		"pillar": CURRENT,
		"origin_year": 1944,
		"role": "anchor",
		"hp": 170, "focus": 60, "atk": 16, "def": 20, "spd": 11,
		"thesis": "The work is worth doing and I am the one doing it.",
		"bill": "A segregated army in a Jim Crow state. The programme's own paperwork is more egalitarian than Mississippi is, because the programme only cares about capability - which is its own kind of cold, and she is the one who has to stand in the gap between the two.",
	},
	{
		"id": "hune",
		"name": "Corporal Silas Hune",
		"pillar": PHASE,
		"origin_year": 1944,
		"role": "infiltrator",
		"hp": 120, "focus": 95, "atk": 21, "def": 12, "spd": 17,
		"thesis": "Somebody has to go in first and it may as well be me.",
		"bill": "He has phased too often. The medical files use the word attenuation. He is not reliably here, and the game should let the player notice before he admits it.",
	},
	{
		"id": "kell",
		"name": "Marta Kell",
		"pillar": CHRONO,
		"origin_year": 2011,
		"role": "analyst",
		"hp": 128, "focus": 88, "atk": 18, "def": 14, "spd": 14,
		"thesis": "You are asking the wrong question and I am not going to tell you the right one.",
		"bill": "Mined from the future. She knows how it ends and will not say, and every time she is right about something the party trusts her less. The most useful device in the game, per bible section 5.",
	},
	{
		"id": "ferrer",
		"name": "Ensign Tobias Ferrer",
		"pillar": CHRONO,
		"origin_year": 1799,
		"role": "medic",
		"hp": 148, "focus": 76, "atk": 13, "def": 17, "spd": 10,
		"thesis": "I did not ask to be here and you have never once acknowledged that.",
		"bill": "A naval surgeon taken, not asked. Retrieval is one-way; the programme calls it settlement and he calls it other things. He is the standing argument that rescue and recruitment are not the same word.",
	},
	{
		"id": "ruhl",
		"name": "Nadia Ruhl",
		"pillar": PHASE,
		"origin_year": 1926,
		"role": "wildcard",
		"hp": 134, "focus": 84, "atk": 19, "def": 13, "spd": 16,
		"thesis": "Your criteria are a list of people you decided to leave.",
		"bill": "The programme has criteria and the list is short. It reached into her century and pulled out the useful ones. She has opinions about everyone it did not pull out, and the game does not answer her - it keeps the question in the room.",
	},
	{
		"id": "doig",
		"name": "Warrant Officer Emmet Doig",
		"pillar": CURRENT,
		"origin_year": 1944,
		"role": "quartermaster",
		"hp": 156, "focus": 68, "atk": 15, "def": 19, "spd": 12,
		"thesis": "I do not have to believe in it to be good at it.",
		"bill": "Complicity as texture, per bible section 3. He signs the forms, he sources the parts, he is friendly and competent and he has never once asked what the requisitions are for.",
	},
]


static func ids() -> PackedStringArray:
	var out := PackedStringArray()
	for p in PROTAGONISTS:
		out.append(p["id"])
	return out


static func by_id(id: String) -> Dictionary:
	for p in PROTAGONISTS:
		if p["id"] == id:
			return p
	push_error("Roster.by_id('%s') found nothing. Known ids: %s. Returning empty rather than a default, so a typo cannot silently spawn the wrong character." % [id, str(ids())])
	return {}


## Every protagonist must carry a bill. Bible section 2 rule 6 is not optional
## and a character without one has quietly become a hero. The test suite
## asserts this against the roster count, not against a hardcoded six, so that
## adding a seventh cannot skip the check.
static func missing_bill() -> PackedStringArray:
	var out := PackedStringArray()
	for p in PROTAGONISTS:
		if not p.has("bill") or String(p["bill"]).strip_edges().is_empty():
			out.append(String(p["id"]))
	return out
