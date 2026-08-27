class_name FlowerDeanBeats
extends RefCounted

## Act One, scene two — Flower and Dean Street.
##
## Ruled by the Chrono fork of the lore thread (world-aflame-godot
## docs/wiki/places/flower-and-dean-street.md and three linked pages),
## verified in git before a line of this was written.
##
## TWO THINGS THIS SCENE MUST NEVER SAY OUT LOUD, per the ruling, and the
## whole design problem is building a scene that can still make a player
## arrive at them:
##
##   1. That the programme benefits from people remaining uncounted, because
##      an investigator who succeeds makes her subject unreachable.
##   2. That a Werk Nachtigall casualty in 1888 passes the Consistency
##      Finding perfectly and nobody has suggested retrieving them.
##
## Neither is a line of dialogue anywhere in this file. Both are mechanical
## consequences: the investigator choice actually changes a Retrieval
## finding via Relational facts, and the cellar beat ends on found objects
## with no character interpreting them. If a future edit adds a character
## who says either of these sentences, that edit is wrong regardless of how
## good the sentence is - ask the lore thread before restoring anything
## that reads like an explanation.

enum Kind { DOCUMENT, CHOICE, LEDGER_RESULT, DEPART }

## Invented. No real Victorian social investigator (Booth, Webb, etc.) is
## ever a playable-adjacent NPC here - the rule that real people are named
## in documents/codex and never as units applies to interactive NPCs too,
## not just party members.
const INVESTIGATOR_NAME := "Miss Eleanor Voss"
const INVESTIGATOR_SUBJECT_ID := "flower_dean_resident"


static func beats() -> Dictionary:
	return {
		"arrival": {
			"kind": Kind.DOCUMENT,
			"header": "FLOWER AND DEAN STREET",
			"teaches": "You are standing in the richest ground the programme has ever found.",
			"lines": [
				"In 1888 this was called the worst street in London, and nobody who wrote that down meant it as an exaggeration.",
				"",
				"Common lodging houses, most of them. Beds let by the night. The people who sleep in them tonight will not necessarily be the ones who slept in them last night, and half give a different name at the desk each time, because a name costs nothing and a reputation does.",
				"",
				"You were not briefed on anyone specific. There was nobody specific to brief you on.",
			],
			"next": "the_investigator",
		},

		"the_investigator": {
			"kind": Kind.DOCUMENT,
			"header": "A WOMAN WITH A NOTEBOOK",
			"teaches": "Somebody is doing, by hand, the opposite of what you are here to do.",
			"lines": [
				"%s has been on this street for three weeks, by her own account, going door to door with a ledger of questions: occupation, birthplace, dependents, length of residence." % INVESTIGATOR_NAME,
				"",
				"She is patient about it in a way that makes people patient back. A woman on the step next to you has just given her a name, an age, and the fact of two children, one living.",
				"",
				"You watch it get written down. It occurs to you, and you cannot say why it should feel like anything, that this is the first time in that woman's life anyone has done that.",
			],
			"next": "the_choice",
		},

		"the_choice": {
			"kind": Kind.CHOICE,
			"header": "SHE ASKS FOR YOUR NAME",
			"teaches": "This choice changes what the record says. It does not explain why that matters.",
			"lines": [
				"%s turns to you next, pencil ready, entirely unremarkable about it. She has asked forty people today." % INVESTIGATOR_NAME,
				"",
				"You have no reason to refuse that would not sound stranger than answering.",
			],
			"choices": [
				{
					"label": "Give a name. Answer honestly enough to be entered properly.",
					"next": "helped_aftermath",
					"action": "help",
				},
				{
					"label": "Give a name that will not survive checking, and move the conversation along.",
					"next": "hindered_aftermath",
					"action": "hinder",
				},
			],
		},

		"helped_aftermath": {
			"kind": Kind.LEDGER_RESULT,
			"header": "ENTERED",
			"teaches": "Being counted is not the same as being safe. It is the opposite of unreachable.",
			"lines": [
				"She writes it down properly, thanks you, and moves to the next door.",
				"",
				"You have no orders about this and no way to raise it with anyone who could act on it before the ledger is bound and filed with the parish. Whatever just happened to your own file, it happened.",
			],
			"next": "the_cellar",
		},

		"hindered_aftermath": {
			"kind": Kind.LEDGER_RESULT,
			"header": "NOTED, AND WRONG",
			"teaches": "Staying uncounted is not a favour you did anyone. It is just what it always was here.",
			"lines": [
				"She writes down what you gave her without suspicion — it is a street where nobody expects the truth, and she has clearly stopped being surprised by that.",
				"",
				"Nothing about you changes. That was already true of nearly everyone on this street before you arrived, which is the entire reason you were sent to it.",
			],
			"next": "the_cellar",
		},

		"the_cellar": {
			"kind": Kind.DOCUMENT,
			"header": "TWO STREETS OVER",
			"teaches": "No confrontation. Somebody tried this and nobody came back for them.",
			"lines": [
				"A cellar under a boarded shopfront, the kind of door that looks locked and is not, because the lock rusted through years ago and nobody thought it worth a new one.",
				"",
				"Equipment, down there. Not tools you recognise and not tools 1888 would recognise either — coiled wire gone green, a frame of some kind, cracked glass, a smell that is not damp.",
				"",
				"It is cold. It has been cold for a long time. Nothing about it has worked in a long time.",
				"",
				"There is no body, or there is, and the cellar has had long enough that the difference stopped mattering before you got here.",
			],
			"next": "the_cellar_choice",
		},

		"the_cellar_choice": {
			"kind": Kind.CHOICE,
			"header": "THE APPARATUS",
			"teaches": "The Finding does not care whose failure it is.",
			"lines": [
				"You could take something. A fragment, a sample, proof that somebody else's programme reached for the same geometry and reached wrong.",
				"",
				"Or you could leave it exactly as found, the way you were briefed to leave everything in this century.",
			],
			"choices": [
				{
					"label": "Take a fragment. It will cost you.",
					"next": "took_fragment",
					"action": "take",
				},
				{
					"label": "Leave it. Log it and go.",
					"next": "left_it",
					"action": "leave",
				},
			],
		},

		"took_fragment": {
			"kind": Kind.LEDGER_RESULT,
			"header": "LOGGED",
			"teaches": "An object history would have noticed is an object that cannot be there.",
			"lines": [
				"You take it anyway. It is heavier than it looks and colder than the cellar, and you spend the walk back working out how to explain a pocketful of Imperial hardware to a customs officer neither of you will meet.",
				"",
				"Nobody stops you. That is not the same as nobody noticing.",
			],
			"next": "codex_note",
		},

		"left_it": {
			"kind": Kind.LEDGER_RESULT,
			"header": "LOGGED, UNTOUCHED",
			"teaches": "Leaving it is also a record. It is just a quieter one.",
			"lines": [
				"You leave it where it lay and note the location in the report you will file when you are somewhere that has paper worth filing on.",
				"",
				"Whoever built it is still down there, or isn't, in exactly the state you found them. Nothing you did changed that, and nothing you could have done would have.",
			],
			"next": "codex_note",
		},

		"codex_note": {
			"kind": Kind.DOCUMENT,
			"header": "LATER",
			"teaches": "Nobody says either of the two things this scene is actually about. That is deliberate.",
			"lines": [
				"You do not report the woman with the notebook. There is no form for her, and it would not occur to you that there should be one.",
				"",
				"You do not report the body in the cellar as a subject, only as debris. Nobody asks you why not, and you do not ask yourself either, out loud.",
			],
			"next": "act_one_gap_2",
		},

		"act_one_gap_2": {
			"kind": Kind.DEPART,
			"header": "END OF WHAT IS BUILT",
			"teaches": "This is where the built game currently stops.",
			"lines": [
				"The mortuary shed, Clerkenwell, and Carfax are designed in the old canvas game and not yet ported.",
				"",
				"What you just played is the second and last finished scene of Act One.",
			],
			"next": "",
		},
	}
