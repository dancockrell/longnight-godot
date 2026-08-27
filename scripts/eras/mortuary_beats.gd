class_name MortuaryBeats
extends RefCounted

## Act One, scene three — the mortuary shed.
##
## Ruled by the Chrono fork of the lore thread
## (world-aflame-godot/docs/wiki/places/the-mortuary-shed.md), verified in
## git before a line of this was written.
##
## WHY THIS SCENE HAS NO RETRIEVAL-AFFECTING CHOICE, unlike Flower and Dean
## Street. There, the player's action genuinely changed a Consistency
## Finding, because the record was still being written. Here it cannot: the
## murdered women's status is already fixed, permanently, by the volume of
## documentation their deaths already produced - "the physics has already
## refused." A choice pretending to affect their retrievability would
## itself violate the ruling ("not a subject, not a choice"), so this scene
## does not offer one. The unclaimed body's DISPUTED/available status is
## seeded as ordinary background content in scripts/core/register.gd, not
## created by anything the player does here - per the ruling, "no unclaimed
## body is retrieved on screen," full stop, in either direction.
##
## What the player DOES choose here is entirely about their OWN record:
## whether their party's report notes what the room contains, or says
## nothing. That is the same shape as Goulston Street's witness/inscribe
## choice and Flower and Dean Street's cellar choice - the only kind of
## agency every ruling so far has actually granted the player in 1888.
##
## THINGS THAT MUST NEVER APPEAR IN THIS FILE'S TEXT, enforced by a lexical
## test in tests/run_tests.gd: any Ripper/murderer/investigation/suspect
## language (the ruling: "No Ripper. No murderer, no investigation, no
## suspects, no mythology"), any description of a body (the ruling: "No
## body is described. Not the murdered women, not the unclaimed."), and any
## sentence stating the room's actual meaning ("the programme cannot take
## them because they're documented, and it could take her because nobody
## looked") - that has to be arrived at, never delivered.

enum Kind { DOCUMENT, CHOICE, LEDGER_RESULT, DEPART }

## Invented, per real-people.md. Not the dead - the living clerk who
## processes them. "He is the closest thing in 1888 to Prentiss."
const ATTENDANT_NAME := "Mr. Alfred Sedge"


static func beats() -> Dictionary:
	return {
		"arrival": {
			"kind": Kind.DOCUMENT,
			"header": "THE SHED",
			"teaches": "This is a building where paperwork is done about people.",
			"lines": [
				"Whitechapel has no mortuary. It has a shed behind the workhouse, and %s has run it, alone, for the better part of a decade." % ATTENDANT_NAME,
				"",
				"He does not ask who you are or why you are looking at his ledger. People look at his ledger. It is, as far as he is concerned, the only interesting thing about the job.",
			],
			"next": "the_ledger",
		},

		"the_ledger": {
			"kind": Kind.DOCUMENT,
			"header": "THE LEDGER",
			"teaches": "Two kinds of entry, in the same book, in the same room.",
			"lines": [
				"One page is thick with cross-references: an inquest date, a coroner's initials, a newspaper clipping pinned behind it gone soft with handling. A name you already know is on it. You do not need to open the drawer to know what is inside, and you do not.",
				"",
				"The next page has one line. A place instead of a name — off the river, this one — and a date, and nothing pinned behind it, because nobody has ever come to ask %s a second question about it." % ATTENDANT_NAME,
				"",
				"He turns both pages the same way. It has not occurred to him that there is a difference between them worth remarking on, and if you asked him, you do not think he would find one.",
			],
			"next": "the_choice",
		},

		"the_choice": {
			"kind": Kind.CHOICE,
			"header": "YOUR OWN REPORT",
			"teaches": "This is the only choice this room actually offers you.",
			"lines": [
				"You will file something about this visit, eventually, to somebody at the far end of the frame who will read it once and put it away.",
				"",
				"You have not decided yet whether it says anything about the ledger.",
			],
			"choices": [
				{
					"label": "Write down what the room actually contains.",
					"next": "wrote_it_down",
					"action": "record",
				},
				{
					"label": "File the visit as routine. Say nothing about the ledger.",
					"next": "said_nothing",
					"action": "silent",
				},
			],
		},

		"wrote_it_down": {
			"kind": Kind.LEDGER_RESULT,
			"header": "FILED",
			"teaches": "Writing it down does not explain it to anyone who reads the report.",
			"lines": [
				"You write it plainly, the way %s turns his pages — one paragraph, no emphasis, nothing underlined." % ATTENDANT_NAME,
				"",
				"Whoever reads this at Iron Bell will read it as a note about local record-keeping practices in 1888. That is all it will say to them. It is not all it said to you.",
			],
			"next": "the_departure",
		},

		"said_nothing": {
			"kind": Kind.LEDGER_RESULT,
			"header": "FILED, ROUTINE",
			"teaches": "Not writing it down is also a choice about what your own record will say.",
			"lines": [
				"Your report says you visited the shed and confirms the location for the file. Nothing else.",
				"",
				"Nobody at the far end will ever know there were two kinds of page in that ledger, because the only person who saw them decided it was not worth the ink.",
			],
			"next": "the_departure",
		},

		"the_departure": {
			"kind": Kind.DOCUMENT,
			"header": "OUTSIDE",
			"teaches": "Nobody in the room explained any of this. That was the point.",
			"lines": [
				"%s says goodnight to you the way he says goodnight to everyone, which is to say precisely, and returns to his ledger." % ATTENDANT_NAME,
				"",
				"You walk back into the street carrying whatever you decided to carry.",
			],
			"next": "act_one_gap_3",
		},

		"act_one_gap_3": {
			"kind": Kind.DEPART,
			"header": "END OF WHAT IS BUILT",
			"teaches": "This is where the built game currently stops.",
			"lines": [
				"Clerkenwell and Carfax are designed in the old canvas game and not yet ported.",
				"",
				"What you just played is the third and last finished scene of Act One.",
			],
			"next": "",
		},
	}
