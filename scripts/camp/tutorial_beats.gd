class_name TutorialBeats
extends RefCounted

## Act 0 — Camp Iron Bell, Mississippi, 1944. Orientation.
##
## Story arrives as evidence rather than narration: personnel files, standing
## orders, a form. Bible section 3 takes that from Fallout and section 8 makes
## it the voice system, and the tonal gap is the point - the register is calm
## and procedural and the content is not.
##
## The beats are a graph rather than a list so the suite can prove every beat
## is reachable and nothing dead-ends. A tutorial with an unreachable branch
## is the same defect as an unreachable code path: it is where the bugs go to
## survive.

enum Kind { DOCUMENT, CHOICE, DRILL, DEPART }

## Whichever retrieved character is not the one the player picked. The camp
## teaches the Consistency Finding on a real case, and it has to be somebody
## the player has already read about on the select screen.
static func practice_subject(protagonist_id: String) -> Dictionary:
	for id in ["ferrer", "kell", "ruhl"]:
		if id != protagonist_id:
			return Roster.by_id(id)
	return Roster.by_id("ferrer")


static func beats(protagonist_id: String) -> Dictionary:
	var subject := practice_subject(protagonist_id)
	var subject_name: String = String(subject.get("name", "the subject"))
	var subject_year: int = int(subject.get("origin_year", 1799))

	return {
		"arrival": {
			"kind": Kind.DOCUMENT,
			"header": "PERSONNEL — INTAKE",
			"teaches": "Story arrives as documents.",
			"lines": [
				"You are issued a file with your own name on it. It is thicker than it should be for somebody who arrived this morning.",
				"",
				"Most of it is forms you have not filled in yet. Two pages are dated last week.",
				"",
				"The clerk does not think this is remarkable, and you work out quite quickly that saying so out loud marks you as new.",
			],
			"next": "current_room",
		},

		"current_room": {
			"kind": Kind.DOCUMENT,
			"header": "STANDING ORDER 6 — LOAD",
			"teaches": "Exposure exists, and here it is free.",
			"lines": [
				"The camp draws more current than the county. There is a substation behind the motor pool that is not on any state map, and the lights in the mess dim twice a night on a schedule nobody has posted.",
				"",
				"Nobody outside asks. A war plant draws current. That is what a war plant is for, and Mississippi in 1944 has a perfectly good word for a building full of humming.",
				"",
				"Remember that, because it is the last place where it will be true.",
			],
			"next": "consistency_brief",
		},

		"consistency_brief": {
			"kind": Kind.DOCUMENT,
			"header": "ORIENTATION — THE CONSISTENCY FINDING",
			"teaches": "You cannot change what happened. You were always part of it.",
			"lines": [
				"The officer taking orientation is not dramatic about it. He has given this talk many times and he reads most of it.",
				"",
				"\"You cannot change what happened. That is not a rule of this programme, it is a property of the arrangement. Anything you do back there, you already did. The record you are going to read tonight already includes you.\"",
				"",
				"\"What follows from that is the part people find difficult, so I will say it slowly.\"",
				"",
				"\"A retrieval only holds together if the subject's absence fits what the record already says. If history is certain what became of a man, we cannot lift him, because lifting him would make the record wrong, and the record is not wrong.\"",
				"",
				"\"So we can only take the ones history loses.\"",
				"",
				"He lets that sit for exactly as long as the schedule allows, and then moves on to fire drill.",
			],
			"next": "the_form",
		},

		"the_form": {
			"kind": Kind.CHOICE,
			"header": "FORM IB-1132 — RETRIEVAL CONSISTENCY ASSESSMENT",
			"teaches": "The Consistency Finding, as paperwork you sign.",
			"lines": [
				"They give you a live one to practise on. It is not a hypothetical; the file is worn.",
				"",
				"SUBJECT: %s" % subject_name,
				"ORIGIN: %d" % subject_year,
				"RECORD STATE: disputed. Two accounts survive of what became of the subject. They do not agree with each other.",
				"",
				"There is one question on the form.",
				"",
				"    Is the subject's absence consistent with the surviving record?   [ YES ]   [ NO ]",
				"",
				"Under it there is a box for your initials, and the box is the only part of the form that is not already filled in.",
			],
			"choices": [
				{
					"label": "Initial the box. YES.",
					"next": "after_signing",
					"finding": true,
				},
				{
					"label": "Ask what happens if you write NO.",
					"next": "refuse",
					"finding": false,
				},
			],
		},

		"refuse": {
			"kind": Kind.DOCUMENT,
			"header": "FORM IB-1132 — CONTINUED",
			"teaches": "The loop is closed. Refusal is not an exit from it.",
			"lines": [
				"\"Then the assessment is negative and the retrieval does not proceed,\" the officer says. \"Which raises a question you are going to have to sit with, so you may as well sit with it now.\"",
				"",
				"He turns the file around so you can see the top sheet.",
				"",
				"\"%s has been at this camp for eleven months. You have met them. They are on the duty roster for Thursday.\"" % subject_name,
				"",
				"\"So we already know what you put in the box.\"",
			],
			"next": "the_form_again",
		},

		"the_form_again": {
			"kind": Kind.CHOICE,
			"header": "FORM IB-1132 — INITIALS",
			"teaches": "You were always going to sign it.",
			"lines": [
				"The form is still in front of you. The box is still empty.",
				"",
				"It is going to have your initials in it, because you have seen the subject eating breakfast.",
				"",
				"Nobody in the room thinks this is a paradox. They think it is Tuesday.",
			],
			"choices": [
				{
					"label": "Initial the box.",
					"next": "after_signing",
					"finding": true,
				},
			],
		},

		"after_signing": {
			"kind": Kind.DOCUMENT,
			"header": "FILED",
			"teaches": "The ambiguity, and that it never resolves.",
			"lines": [
				"The clerk takes the form, checks the box has initials in it, and files it. That is the whole ceremony.",
				"",
				"Walking out you work through it properly for the first time, and you cannot make it come out clean.",
				"",
				"The rule is real. The arrangement will not permit a retrieval that contradicts the record, and every engineer here will show you the arithmetic.",
				"",
				"And the rule happens to mean the programme reaches for people nobody wrote down, and leaves the ones somebody did. Which is exactly what a programme with a short list and a budget would have done anyway.",
				"",
				"You cannot tell which of those is doing the work. Neither can the officer. Neither, as far as you can establish over the following months, can anybody at this camp, including the men who designed it.",
			],
			"next": "drill",
		},

		"drill": {
			"kind": Kind.DRILL,
			"header": "DRILL — CONTACT PROCEDURE",
			"teaches": "Combat: stance, threat, and that noise costs.",
			"lines": [
				"The drill yard is a stretch of red dirt behind the substation with a painted line on it.",
				"",
				"You are taught to hold attention deliberately rather than accidentally, which is most of what a fight is, and you are taught two ways to stand.",
				"",
				"Forward finishes it quickly. Covered takes longer and is quieter.",
				"",
				"Here it makes no difference at all. That is the point of doing it here.",
			],
			"next": "depart",
		},

		"depart": {
			"kind": Kind.DEPART,
			"header": "MOVEMENT ORDER",
			"teaches": "Exposure stops being free.",
			"lines": [
				"The order does not say where. It says when, and the when is a year.",
				"",
				"The last page is a single line of standing instruction, printed rather than typed, which means it is on every one of these.",
				"",
				"    NOTHING YOU CARRY HAS A WORD IN THAT PERIOD. BE ACCORDINGLY QUIET.",
			],
			"next": "",
		},
	}


## Every beat that can be reached from the entry point. Used by the suite to
## prove there are no orphans and no dead ends.
static func reachable_from(start: String, graph: Dictionary) -> PackedStringArray:
	var seen := {}
	var queue := [start]
	while not queue.is_empty():
		var id: String = queue.pop_front()
		if seen.has(id) or not graph.has(id):
			continue
		seen[id] = true
		var beat: Dictionary = graph[id]
		if beat.has("next") and not String(beat["next"]).is_empty():
			queue.append(String(beat["next"]))
		for c in beat.get("choices", []):
			queue.append(String(c["next"]))
	var out := PackedStringArray()
	for id in seen:
		out.append(String(id))
	return out
