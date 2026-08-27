class_name Roster
extends RefCounted

## The six playable protagonists. You pick one; the rest of the party is
## recruited across the eras.
##
## EVERY ONE IS AN INVENTION. No real person is ever a playable piece in this
## universe - LORE-BIBLE.md section 2 rule 9. Real authors, philosophers and
## historical figures appear as encountered NPCs and never as units.
##
## THREE OF THESE ARE CANON, not local invention: Ferrer, Kell and Ruhl are
## filed in world-aflame-godot/docs/WORLD-THE-SETTLED.md as three of the
## nineteen people Camp Iron Bell has ever retrieved. That volume explicitly
## reserves open slots for this ("add them here when you make them, do not
## keep them in a game's local file") - the stat blocks below are downstream
## of that entry, not the other way round. If the two ever disagree, the
## shared doc wins and this file needs fixing.
##
## Moreau, Hune and Doig are camp-native (1944, never retrieved) and are
## filed in the Personnel section of
## world-aflame-godot/docs/WORLD-CAMP-IRON-BELL.md for the same reason.
##
## Six because each has to carry a distinct argument about the programme, and
## six distinct arguments is as many as this story actually has. They are not
## six flavours of soldier; they are six answers to "what is Camp Iron Bell
## entitled to do?", and the party's internal disagreement is the spine of the
## writing.
##
## THAT QUESTION IS NOW CANON, not a house rule: LORE-BIBLE Volume XVI
## (world-aflame-godot/docs/WORLD-THE-QUESTION.md, "What is Camp Iron Bell
## entitled to do?") names seven positions, each held by somebody an
## intelligent person could actually be, each with a counter that is also
## good. Two of the seven are held, in that volume, by characters who are
## also two of these six protagonists - Ferrer holds position 2 and Kell
## holds position 4 there directly, not by analogy, since they are the same
## characters across both documents. The mapping below extends that to the
## other four. §00 governs: the game never resolves which position is right,
## and no two protagonists hold the same one. Position 1 ("it is a rescue")
## is deliberately left unheld by any protagonist - it belongs to Colonel
## Wexford, an NPC, so the party has an institutional line to react against
## rather than everyone already agreeing with the commanding officer.
##
## Per the volume's own instruction, nobody holds a position purely - people
## hold one publicly, a second privately, and drift toward a third at four in
## the morning. Hune is written that way deliberately: his public line reads
## as position 7 turned inward rather than outward.
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
		"question_position": 5,
		"question_label": "It is owed",
		"question_note": "Vosburgh's position, held by an anchor rather than an administrator: every hour spent debating entitlement is an hour of the actual war. Its own counter is the sharpest in the volume - the same justification is available verbatim to Werk Nachtigall.",
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
		"question_position": 7,
		"question_label": "We should be taking far more",
		"question_note": "Bright's position, held privately. Publicly he volunteers for everything; the 4am version of that is a belief that the limit is cost, not conscience, and that a programme afraid to find its own ceiling is a programme still deciding how much right to do. He does not say this out loud. Attenuation is what happens to a man who acts on it without saying it.",
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
		"question_position": 4,
		"question_label": "It does not matter, because nothing changes",
		"question_note": "Her position directly, per WORLD-THE-QUESTION.md - the loop is already closed, so there was never a decision. The volume's own counter is what she has already worked out and won't say: knowing the loop is closed does not tell you what is in it. A fatalist still has to fill in the form.",
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
		"question_position": 2,
		"question_label": "It is a conscription",
		"question_note": "His position directly, per WORLD-THE-QUESTION.md - W.D. 42-A has a box for the authorising officer and none for consent. Its own counter is the one he has never had an answer for: you cannot ask a man in 1799 whether he consents to a retrieval in 1943, so a standard nobody could meet is not a standard.",
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
		"question_position": 3,
		"question_label": "The criteria are the crime",
		"question_note": "Osei's position, carried by a wildcard rather than a mathematician: not that the programme takes, but who it can take. Its sharpest form, per the volume, credits an observation this project made independently before the volume existed - the programme benefits from people going uncounted, and has never written that down.",
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
		"question_position": 6,
		"question_label": "The question is a distraction",
		"question_note": "Prentiss's position, held by a quartermaster instead of a clerk - it fits him exactly. Follow the appropriations: who authorised this, against what budget, expecting what return. Its own counter is that describing an institution is not answering the question; following the money tells you who benefits, not what is permitted.",
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


## Every protagonist must hold a distinct question_position (Volume XVI has
## seven; six protagonists means one position, by design, is left to an NPC).
## Two protagonists sharing a position would mean the party's central
## disagreement has a gap in it. Counted against roster size, same reasoning
## as missing_bill().
static func duplicate_question_positions() -> Array:
	var seen := {}
	var dupes := []
	for p in PROTAGONISTS:
		var pos: int = int(p.get("question_position", -1))
		if pos < 1:
			continue
		if seen.has(pos):
			dupes.append(pos)
		seen[pos] = true
	return dupes


static func missing_question_position() -> PackedStringArray:
	var out := PackedStringArray()
	for p in PROTAGONISTS:
		if int(p.get("question_position", -1)) < 1:
			out.append(String(p["id"]))
	return out
