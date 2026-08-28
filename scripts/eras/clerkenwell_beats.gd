class_name ClerkenwellBeats
extends RefCounted

## Act One, scene four — Clerkenwell.
##
## Three real sites, adapted from the old canvas game's own material (which
## this project owns) into the Ledger/Register framework rather than ported
## as prose: an unconsecrated pauper burial ground, a spiritualist parlour,
## and a body-snatchers' yard behind the anatomy rooms. All three are real,
## well-documented Victorian phenomena - the Anatomy Act of 1832 did not end
## the resurrection trade, it only moved it into fewer, better-paid hands,
## and London's pauper burial grounds and spiritualist scene in 1888 are
## both extensively documented. No claim here needs a lore ruling beyond
## the ones already governing 1888: these are ordinary background facts of
## the period, the same register of reality Flower and Dean Street and the
## mortuary shed already draw on.
##
## The yard ends in a real fight (see battle_screen.gd) - resurrection men,
## a mundane and real criminal trade, never Werk Nachtigall (debris only,
## per the ruling) and never Hyakki Yakō (never physically present).

enum Kind { DOCUMENT, CHOICE, LEDGER_RESULT, BATTLE, DEPART }

const SITES := ["ground", "parlour", "yard"]


static func beats() -> Dictionary:
	return {
		"arrival": {
			"kind": Kind.DOCUMENT,
			"header": "CLERKENWELL",
			"teaches": "The city was not only looking at Whitechapel. It only wrote about Whitechapel.",
			"lines": [
				"Three sites, a short walk from each other, none of them in the papers this autumn.",
				"",
				"None of them needed to be. Whitechapel already had a headline. Clerkenwell has never needed one.",
			],
			"next": "ground",
		},

		"ground": {
			"kind": Kind.DOCUMENT,
			"header": "THE UNCONSECRATED GROUND",
			"teaches": "No headstones. The record here was never going to be kept.",
			"lines": [
				"Not Highgate. The parish would not take these bodies — the unbaptised, the suicides, women the register has no polite column for.",
				"",
				"No headstones. A few wooden stakes, most rotted through, some missing entirely. Nobody replaces one once it falls.",
				"",
				"More names were buried here than stakes were ever cut for. The ground has had a long time to be soft.",
			],
			"next": "parlour",
		},

		"parlour": {
			"kind": Kind.DOCUMENT,
			"header": "THE PARLOUR",
			"teaches": "Half the city wants to hear from the dead. Nobody wants to count the living poor.",
			"lines": [
				"A circular table, five chairs, one gas-jet turned low. The curtains have been drawn since four in the afternoon.",
				"",
				"The medium does not claim to raise anyone. She claims the dead have not finished speaking and that London is loud with them — which, this particular autumn, happens to be true in a sense she does not mean and you do not correct her on.",
				"",
				"A slate on the sideboard has writing on both sides, in two different hands.",
			],
			"next": "yard_approach",
		},

		"yard_approach": {
			"kind": Kind.DOCUMENT,
			"header": "THE YARD BEHIND THE ANATOMY ROOMS",
			"teaches": "The Anatomy Act moved the trade. It did not end it.",
			"lines": [
				"No signboard. Hooks on the wall at the height of a man's shoulders, if the man were being carried rather than walking.",
				"",
				"Cart tracks in the mud, fresh. The hospitals still need bodies, and the men who supply them have never stopped being paid for the work, only stopped being asked about it.",
				"",
				"Two of them are still here, and they have noticed you.",
			],
			"next": "yard_fight",
		},

		"yard_fight": {
			"kind": Kind.BATTLE,
			"header": "CONTACT",
			"teaches": "A fight over supply, not over you. They would rather you left than fought.",
			"lines": [
				"They are not looking for trouble with strangers, and they are absolutely not willing to be reported to anyone.",
				"",
				"Neither of those things stops them being armed.",
			],
			"next": "codex_note",
		},

		"codex_note": {
			"kind": Kind.DOCUMENT,
			"header": "LATER",
			"teaches": "Same soft ground. Different ink.",
			"lines": [
				"You put it together on the walk back, the way you have started to with everything in this city.",
				"",
				"Whitechapel is the story the autumn chose to tell. Clerkenwell is the story it already had — the same poor, the same soft ground, the same absence of a headline, running the whole time underneath the one everyone is reading.",
			],
			"next": "act_one_gap_4",
		},

		"act_one_gap_4": {
			"kind": Kind.DEPART,
			"header": "END OF WHAT IS BUILT",
			"teaches": "One street left.",
			"lines": [
				"Carfax remains.",
			],
			"next": "",
		},
	}
