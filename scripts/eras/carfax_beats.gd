class_name CarfaxBeats
extends RefCounted

## Act One's finale — Carfax, Purfleet.
##
## Dracula is Bram Stoker's invention, public domain, not a real person -
## none of the real-people restrictions elsewhere in this project touch him.
##
## PER docs/DESIGN.md: "Dracula was never a health bar and never will be one
## here." His argument is the game's thesis, restated with a full act's
## worth of evidence behind it instead of a promise: four hundred columns
## about Whitechapel, and Clerkenwell's soft ground runs under the whole
## autumn without needing one. The reckoning at the end of this scene tallies
## what the ACTUAL playthrough preserved - the Ledger and the Register -
## rather than resolving a fight. That is a deliberate, load-bearing design
## choice, not a placeholder for a fight that will be added later.

enum Kind { DOCUMENT, CHOICE, RECKONING, DEPART }


static func beats() -> Dictionary:
	return {
		"arrival": {
			"kind": Kind.DOCUMENT,
			"header": "CARFAX",
			"teaches": "This is the end of Act One. There is no fight here.",
			"lines": [
				"The chapel at Purfleet has been empty long enough that empty is what the neighbours call it. It is not empty tonight.",
				"",
				"He is sitting perfectly still, in evening dress, and he has been waiting for you a while, without seeming to have been waiting for anything.",
			],
			"next": "the_argument",
		},

		"the_argument": {
			"kind": Kind.DOCUMENT,
			"header": "COUNT DRACULA SPEAKS",
			"teaches": "His argument is the game's thesis, and he has evidence now instead of a boast.",
			"lines": [
				"\"Four hundred columns this autumn about a man who kills women in Whitechapel,\" he says, \"and not one line about a ship that came into Whitby with a dead crew. I did not have to hide. You were all looking somewhere else, and you paid a penny for the privilege.\"",
				"",
				"\"You went and looked at the chalk, though. And the beds on Flower and Dean Street. And the shed. And Clerkenwell, which nobody was going to ask you to look at, because nobody has ever needed to hide Clerkenwell — it was never news to begin with.\"",
				"",
				"\"That was not in any paper. That was you, doing the work. How tiresome of you.\"",
			],
			"next": "the_challenge",
		},

		"the_challenge": {
			"kind": Kind.CHOICE,
			"header": "HE ASKS YOU A QUESTION, NOT A FAVOUR",
			"teaches": "There is no combat option here on purpose.",
			"lines": [
				"\"Tell me,\" he says, \"honestly, since it will cost you nothing now — what did you actually keep? Not what you saw. I do not care what you saw. Everyone in this city saw something and did nothing useful with it. What survived you?\"",
			],
			"choices": [
				{
					"label": "Answer him honestly.",
					"next": "reckoning",
					"action": "answer",
				},
				{
					"label": "Say nothing. Let the record answer for you.",
					"next": "reckoning",
					"action": "silent",
				},
			],
		},

		"reckoning": {
			"kind": Kind.RECKONING,
			"header": "THE RECKONING",
			"teaches": "This is generated from what you actually did across Act One, not from a script.",
			"lines": [],  # populated at runtime from GameState.ledger / Register
			"next": "the_dawn_or_the_night",
		},

		"the_dawn_or_the_night": {
			"kind": Kind.CHOICE,
			"header": "ONE MORE QUESTION",
			"teaches": "Two endings. Neither is a fail state, and the game will not tell you which one it prefers.",
			"lines": [
				"\"You could publish what you have,\" he says. \"Circulation would rise. It always does, when there is a name attached. Or you could leave the shutters closed, and let the autumn go on being about one man in Whitechapel, and nobody will ever come looking for a reason.\"",
				"",
				"\"I am not going to tell you which is worse. I have found, over rather a long time, that people only ever ask me that question when they already know.\"",
			],
			"choices": [
				{
					"label": "DAWN — publish what you have.",
					"next": "ending_dawn",
					"action": "dawn",
				},
				{
					"label": "NIGHT — leave it closed.",
					"next": "ending_night",
					"action": "night",
				},
			],
		},

		"ending_dawn": {
			"kind": Kind.DOCUMENT,
			"header": "DAWN",
			"teaches": "Not a victory. A choice, with the same reckoning attached to it as the other one.",
			"lines": [
				"It runs three columns, on an inside page, under someone else's byline. Whitechapel gets the front page again the next morning, and the morning after that. This is not a story that beats that one. It was never going to.",
				"",
				"But it exists now, in type, where it did not before. Somebody, eventually, reads three columns on an inside page and remembers them longer than they remember the front page. That has always been how the quiet story wins, when it wins at all — not by beating the loud one, by outlasting it.",
			],
			"next": "act_one_complete",
		},

		"ending_night": {
			"kind": Kind.DOCUMENT,
			"header": "NIGHT",
			"teaches": "Not a failure. The easier choice, and the game says so without saying it was wrong.",
			"lines": [
				"You say nothing. Circulation rises anyway, on the story that was already running, and the boxes go out by cart to Piccadilly and Bermondsey the same as every other week this autumn.",
				"",
				"Nobody asks you why you did not publish. Nobody knew there was anything to publish. That was, if you are honest with yourself the way he asked you to be, most of the reason it was easier.",
			],
			"next": "act_one_complete",
		},

		"act_one_complete": {
			"kind": Kind.DEPART,
			"header": "END OF ACT ONE",
			"teaches": "This is where the built game currently ends.",
			"lines": [
				"Whatever you preserved across four scenes in 1888 is what you preserved. The record does not get a second draft.",
				"",
				"Act Two — the eras beyond 1888 — is designed and not yet built.",
			],
			"next": "",
		},
	}
