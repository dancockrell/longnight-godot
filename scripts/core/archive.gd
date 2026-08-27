class_name Archive
extends RefCounted

## The Archive is our history. It is not the game.
##
## Ruled by the Project 42 lore master, 27 Aug 2026. Two layers that never
## trade places:
##
##   ARCHIVE - our own history. Real names, sourced, plainly told. It is NOT
##             in the alternate history and never says "in this world".
##   GAME    - the alternate history. Invented names throughout.
##
## The seam: **names go in the record, not on the roster.** Yad Vashem names
## Ottla Kafka; it does not give her a stat line. No real person is ever a
## playable unit. Real people are named here, where naming is the point.
##
## THE RULE THIS FILE ENFORCES IN CODE: an entry without a source cannot be
## displayed. Not "should not" - cannot. A memorial project that will repeat a
## claim it cannot substantiate is worth less than no memorial project, because
## the first error someone catches discredits every true thing next to it.
##
## That is CLAUDE.md rule 19 pointed at the product rather than at our notes:
## record the check, not the claim.

class Entry extends RefCounted:
	var id: String = ""
	var title: String = ""
	var body: String = ""
	var sources: PackedStringArray = []
	## Set true only when a human or a session has actually checked the claims
	## against the sources. Defaults false, and false means invisible.
	var verified: bool = false
	## What still needs checking. Displayed to us, never to the player.
	var open_questions: PackedStringArray = []

	func is_displayable() -> bool:
		return verified and not sources.is_empty() and not body.strip_edges().is_empty()


var entries: Dictionary = {}


func add(id: String, title: String, body: String, sources: PackedStringArray,
		verified: bool = false, open_questions: PackedStringArray = []) -> void:
	if id.is_empty():
		push_error("Archive.add() with an empty id. Refusing: an entry that cannot be addressed cannot be corrected later, and this is the layer where being correctable matters most.")
		return
	var e := Entry.new()
	e.id = id
	e.title = title
	e.body = body
	e.sources = sources
	e.verified = verified
	e.open_questions = open_questions
	entries[id] = e


## What the player can actually be shown.
func displayable() -> Array:
	var out := []
	for id in entries:
		var e: Entry = entries[id]
		if e.is_displayable():
			out.append(e)
	return out


## What is written but withheld, and why. Reported separately and loudly,
## because an Archive that can only report what it has is the same shape as a
## check that can only report success.
func withheld() -> Dictionary:
	var out := {}
	for id in entries:
		var e: Entry = entries[id]
		if e.is_displayable():
			continue
		var reason := ""
		if e.sources.is_empty():
			reason = "no source recorded"
		elif not e.verified:
			reason = "sources recorded but never checked against the text"
		else:
			reason = "empty body"
		out[id] = reason
	return out


func count() -> int:
	return entries.size()


## Seed the Archive. Content here is ruled and approved; anything not verified
## is marked so and will not display until somebody checks it.
static func build_default() -> Archive:
	var a := Archive.new()

	# Approved by the lore master as the tutorial for the whole thesis, with
	# three conditions: name Catherine Eddowes; be honest about why it was
	# erased; no Ripper mythology. All three are met below.
	#
	# Verified 27 Aug 2026 by this session against the source listed. That
	# check also corrected an error carried in the original canvas game, which
	# has Abberline arguing to preserve the writing and losing. He did not.
	# The dispute was between forces, not men: City of London officers wanted
	# it photographed because the apron belonged to a City victim, and the
	# writing sat on Metropolitan ground.
	a.add(
		"goulston_street",
		"Goulston Street, 30 September 1888",
		"""A police constable found a piece of a woman's apron in a stairwell doorway in Goulston Street. It had been cut from the clothing of Catherine Eddowes, murdered a few hours earlier in Mitre Square. Chalked on the wall above it was a single line, whose exact wording and spelling were transcribed differently by the men who saw it and were never reconciled.

Detective Constable Daniel Halse of the City of London Police wanted the writing photographed before anything was done to it, and sent another officer to fetch instructions from his own department to that effect. Superintendent Thomas Arnold of the Metropolitan Police wanted it erased. Arnold's reason was not indifference: Goulston Street ran into a Jewish quarter, the market would open at daylight, and he judged that a line of writing about Jews, found beside a murdered woman's clothing, would set off attacks on the people living there.

Sir Charles Warren, Commissioner of the Metropolitan Police, arrived a little after five in the morning. The wall was on Metropolitan ground. He sided with Arnold, and the writing was sponged off before it was light.

There is no photograph. No handwriting could ever be examined. Both things are true at once and neither cancels the other: the erasure had a real reason, and it destroyed the only copy of the evidence. That is the whole of what this game is about, and it happened in one hour, to one wall, over one line of chalk.""",
		PackedStringArray([
			"https://www.casebook.org/official_documents/inquests/inquest_eddowes.html",
			"https://wiki.casebook.org/daniel_halse.html",
		]),
		true,
		PackedStringArray([
			"The line's exact wording is disputed between the surviving transcriptions. Do not quote it as settled, and consider not quoting it at all - the lore ruling is that the story is the erasure, not the message.",
			"RESOLVED 27 Aug 2026: Halse was a Detective Constable, not an Inspector. The lore master caught this by applying my own verify-the-source rule back at me, and was right. The first draft had it wrong because it came off a summary rather than the testimony.",
			"Arnold's rank still wants a third check. He is consistently given as Superintendent, Metropolitan Police, H Division, but I have not read that off a primary document.",
			"Wikipedia is a finding aid and is no longer cited here. Sources are now the inquest testimony and the officer record it supports.",
		])
	)

	# Ruled: the memorial spine of the game points AT this rather than staging
	# it. The mechanic is abstract; the place is named here and nowhere else.
	# Deliberately unverified - written from this session's own knowledge and
	# NOT yet checked against a source, so it cannot display. That is the file
	# doing its job rather than me promising to come back to it.
	a.add(
		"oneg_shabbat",
		"The Oneg Shabbat archive",
		"",
		PackedStringArray(),
		false,
		PackedStringArray([
			"NOT WRITTEN. Needs a sourced pass before a word of it goes in.",
			"Check: the group around Emanuel Ringelblum in the Warsaw Ghetto, what was collected, how it was sealed and buried, how many caches, how many recovered, and the names of the compilers.",
			"Ruling: abstract the principle, do not stage the place. No level set there, the player is never them, their burial is never a quest objective.",
		])
	)

	# Ruled: naming them is closer to required than permitted. Also
	# deliberately unverified for now, for the same reason as above.
	a.add(
		"kafka_sisters",
		"Elli, Valli and Ottla Kafka",
		"",
		PackedStringArray(),
		false,
		PackedStringArray([
			"NOT WRITTEN. Needs a sourced pass.",
			"Check each sister's full name, and the circumstances of Ottla's death, against primary or scholarly sources. The lore ruling is that this needs no embellishment whatsoever - it is a register, not a story.",
			"Their brother stays off the roster. He was not a victim of this and his presence would be there for the irony, which is using their murder as atmosphere.",
		])
	)

	return a
