class_name GoulstonBeats
extends RefCounted

## Act One, first scene — Goulston Street, dawn, 30 September 1888.
##
## The tutorial's dark mirror. Camp Iron Bell taught the Consistency Finding
## as paperwork, signed in a warm room. This teaches it in the field: the
## player CANNOT prevent the erasure. History is certain what happened here,
## which is exactly why - per the Finding - nobody could ever have been sent
## to stop it. The only real choice is how the player personally responds to
## watching a record get destroyed they know they cannot save.
##
## Content ruled by the Project 42 lore master, 27 Aug 2026, three
## conditions, all met here:
##   a) Name Catherine Eddowes. Not "a murdered woman".
##   b) Be honest about why Warren erased it - fear of anti-Jewish violence at
##      dawn market - and that the erasure was still an irrecoverable loss.
##      Both true at once. Do not flatten to "erasure bad".
##   c) No Ripper mythology. The story is Warren, Halse, Arnold and the dawn
##      deadline, not the murderer.
##
## Sourced against docs/core/archive.gd's "goulston_street" entry (inquest
## testimony, not a summary), including the correction that Halse was a
## Detective Constable, City of London Police - not an Inspector - caught
## when the lore master applied this project's own verify-the-source rule
## back at its author.

enum Kind { DOCUMENT, CHOICE, LEDGER_RESULT, DEPART }


static func beats() -> Dictionary:
	return {
		"arrival": {
			"kind": Kind.DOCUMENT,
			"header": "GOULSTON STREET — BEFORE DAWN, 30 SEPTEMBER 1888",
			"teaches": "The ceiling just dropped. This is what that means.",
			"lines": [
				"Camp Iron Bell had a word for a building full of humming. Whitechapel does not.",
				"",
				"Your orders were plain and you did not question them at the time: observe, do not intervene, do not be seen doing anything a person standing here in 1888 could not also be doing.",
				"",
				"That instruction reads differently now that you are standing in the doorway.",
			],
			"next": "witness",
		},

		"witness": {
			"kind": Kind.DOCUMENT,
			"header": "THE DOORWAY",
			"teaches": "Witnessing is not remembering.",
			"lines": [
				"A constable is crouched over a torn piece of cloth in the passage entrance. It will turn out to be part of the apron of Catherine Eddowes, murdered a few hours ago in Mitre Square, on ground the City of London Police work rather than the Metropolitan force.",
				"",
				"Above it, chalked on the black brick, a single line. You can read it from here. So can four other men, and by the time this is over none of their transcriptions will quite agree with each other.",
				"",
				"Nobody has photographed it. Nobody has a camera here at half past two in the morning that could.",
			],
			"next": "dispute",
			"on_enter": "witness_the_wall",
		},

		"dispute": {
			"kind": Kind.DOCUMENT,
			"header": "TWO FORCES, ONE WALL",
			"teaches": "The erasure had a reason. It was still a loss. Both are true.",
			"lines": [
				"Detective Constable Daniel Halse, City of London Police, wants it left exactly as it is until it can be photographed. The apron came from a City murder; the writing is his force's business as much as anyone's.",
				"",
				"Superintendent Thomas Arnold, Metropolitan Police, wants it gone. The wall stands on his ground. In a few hours this doorway will be on the way to a Sunday market that serves a Jewish quarter, and Arnold has read the line the same way you just did.",
				"",
				"\"Leave it up,\" Halse says, \"and by eight o'clock this is not evidence. It is a reason for a crowd.\"",
				"",
				"Sir Charles Warren, Commissioner of the Metropolitan Police, arrives a little after five. The wall is his ground, not Halse's. He does not deliberate long.",
			],
			"next": "the_choice",
		},

		"the_choice": {
			"kind": Kind.CHOICE,
			"header": "A SPONGE IS SENT FOR",
			"teaches": "You cannot change what happened. The Finding, in the field.",
			"lines": [
				"You have perhaps four minutes before the wall is clean.",
				"",
				"You already know, in a way none of these men do, exactly how this comes out: there is no photograph in any record you have ever read. There never was one. Whatever you do in the next four minutes, that fact is not going to move.",
			],
			"choices": [
				{
					"label": "Stay covered. Watch it happen.",
					"next": "aftermath_watched",
					"action": "watch",
				},
				{
					"label": "Copy the line into your own notebook before it goes.",
					"next": "aftermath_transcribed",
					"action": "transcribe",
				},
				{
					"label": "Try to stop it. Argue, delay, anything.",
					"next": "aftermath_intervened",
					"action": "intervene",
				},
			],
		},

		"aftermath_watched": {
			"kind": Kind.LEDGER_RESULT,
			"header": "SPONGED OFF",
			"teaches": "A thing only witnessed does not survive.",
			"lines": [
				"You say nothing and do nothing, which is what you were told to do, and the wet sponge takes eleven seconds.",
				"",
				"You saw it. That is all that happened. You saw it, and now the only copy of what you saw is a memory that is already starting to disagree with itself about the exact wording, the way everyone's does.",
			],
			"next": "codex_note",
		},

		"aftermath_transcribed": {
			"kind": Kind.LEDGER_RESULT,
			"header": "SPONGED OFF",
			"teaches": "Filed paper outlives its author. This is why that matters.",
			"lines": [
				"You copy it into your own notebook, quickly, in a hand that will look rushed later because it was. A man writing in a notebook near a crime scene is not a thing 1888 has no word for. Nobody looks at you twice.",
				"",
				"Your version does not exactly match Halse's, which does not exactly match the version a City reporter will publish next week. None of you is lying. This is what a record looks like when four honest people write down the same four minutes.",
			],
			"next": "codex_note",
		},

		"aftermath_intervened": {
			"kind": Kind.LEDGER_RESULT,
			"header": "SPONGED OFF ANYWAY",
			"teaches": "The loop was already closed. It cost you to learn that here instead of on a form.",
			"lines": [
				"You step forward. You get perhaps one sentence out before a City constable has your arm and Warren has not so much as turned his head — this is, to him, a member of the public interfering with police business at a murder scene, and he has a form for that too.",
				"",
				"You are moved off. The sponge goes ahead on schedule. Nothing you did changed a single minute of it, because nothing available to you could have: the record already says how this went, and you are standing inside a period that has no space in it for you to have stopped it.",
				"",
				"It was loud, though. Loud enough that somebody will write an incident up.",
			],
			"next": "codex_note",
		},

		"codex_note": {
			"kind": Kind.DOCUMENT,
			"header": "LATER",
			"teaches": "Both things stay true. The tutorial did not flatten it, and neither does this.",
			"lines": [
				"Arnold was not indifferent. He read a line about a people who did not write it, next to a murdered woman's clothing, and moved to stop a nine o'clock crowd from reading it the same way.",
				"",
				"He was also wrong, and there is no version of this where he was not: nobody can now examine the handwriting, and nobody ever will, and that was true the moment the sponge touched the wall regardless of why it was picked up.",
				"",
				"Catherine Eddowes had a name before this morning gave her a case number. The line on the wall was never about her. The apron under it was.",
			],
			"next": "act_one_gap",
		},

		"act_one_gap": {
			"kind": Kind.DEPART,
			"header": "END OF WHAT IS BUILT",
			"teaches": "This is where the built game currently stops.",
			"lines": [
				"The rest of 1888 — the party, the scenes at Flower and Dean Street, the mortuary shed, Clerkenwell, and Carfax — is designed in the old canvas game and not yet ported.",
				"",
				"What you just played is the only finished scene of Act One.",
			],
			"next": "",
		},
	}
