class_name Ledger
extends RefCounted

## What survives.
##
## The game's philosophy, from Dan, 27 Aug 2026: **never forget**. This is the
## system that philosophy is built out of, and its central claim is one rule:
##
##     Witnessing is not remembering. Only the record survives.
##
## A thing the party sees and does not put into a durable form is gone when
## they are gone. That is not a penalty the designer invented to be cruel; it
## is how the historical record actually works, and it is why the discipline of
## memory is a discipline of *writing things down* rather than of feeling
## strongly about them.
##
## CONTENT-FREE BY CONSTRUCTION. This file hardcodes no names, no events and no
## periods. Entries are supplied by era data, which does not exist yet and will
## not until the lore thread has ruled. That is deliberate: the machinery is
## useful whichever way the ruling goes, and nothing here has to be rewritten
## when the content arrives.

## How durable a form is against someone who wants the thing gone.
##
## Modelled on how records actually survive or fail to. Each value is a real
## mechanism, not a fantasy tier list, and the ordering is the design claim.
enum Medium {
	LIVING_MEMORY,  ## Somebody knows. Dies with them, and they will die.
	CHALK,          ## Written where it can be washed off, and will be.
	FILED_PAPER,    ## In an institution's records - and the institution can burn its own records.
	PHOTOGRAPH,     ## Hard to deny. Easy to seize, if anyone knows it exists.
	BURIED_CACHE,   ## Hidden deliberately, to be found later. Survives the people who made it.
}

## Whether a medium survives a determined attempt to erase it.
const SURVIVES_SUPPRESSION := {
	Medium.LIVING_MEMORY: false,
	Medium.CHALK: false,
	Medium.FILED_PAPER: false,
	Medium.PHOTOGRAPH: false,
	Medium.BURIED_CACHE: true,
}

## Whether a medium outlives the person who made it, absent suppression.
const OUTLIVES_AUTHOR := {
	Medium.LIVING_MEMORY: false,
	Medium.CHALK: false,
	Medium.FILED_PAPER: true,
	Medium.PHOTOGRAPH: true,
	Medium.BURIED_CACHE: true,
}

const MEDIUM_NAME := {
	Medium.LIVING_MEMORY: "living memory",
	Medium.CHALK: "chalk",
	Medium.FILED_PAPER: "filed paper",
	Medium.PHOTOGRAPH: "photograph",
	Medium.BURIED_CACHE: "a buried cache",
}

signal entry_lost(id: String, reason: String)
signal entry_survived(id: String, medium: Medium)

var entries: Dictionary = {}


## The party saw something. This on its own accomplishes nothing, and the
## system is built so the player finds that out.
func witness(id: String, witnessed_year: int) -> void:
	if id.is_empty():
		push_error("Ledger.witness() called with an empty id. Refusing to file an anonymous entry, which could never be looked up again and would inflate every count in the suite.")
		return
	if entries.has(id):
		return
	entries[id] = {
		"witnessed_year": witnessed_year,
		"medium": Medium.LIVING_MEMORY,
		"inscribed": false,
		"suppressed": false,
		"recovered": false,
	}


## Put it into a form. This is the verb the whole game is about.
func inscribe(id: String, medium: Medium) -> bool:
	if not entries.has(id):
		push_error("Ledger.inscribe('%s') on something never witnessed. Refusing to invent a record for an event the party did not see - that is the one thing this system must never do." % id)
		return false
	entries[id]["medium"] = medium
	entries[id]["inscribed"] = medium != Medium.LIVING_MEMORY
	return true


## Somebody wants it gone, and has the authority to act on that.
func suppress(id: String, by_whom: String) -> void:
	if not entries.has(id):
		return
	entries[id]["suppressed"] = true
	entries[id]["suppressed_by"] = by_whom


## A buried cache is found. Historically this is not guaranteed and the game
## should not pretend otherwise: of the three Oneg Shabbat caches, two were
## recovered and the third never was.
func recover(id: String) -> bool:
	if not entries.has(id):
		return false
	if entries[id]["medium"] != Medium.BURIED_CACHE:
		return false
	entries[id]["recovered"] = true
	return true


## The question the whole system exists to answer.
func survives(id: String) -> bool:
	if not entries.has(id):
		return false
	var e: Dictionary = entries[id]
	var medium: Medium = e["medium"]

	if e["suppressed"] and not SURVIVES_SUPPRESSION[medium]:
		return false
	if medium == Medium.BURIED_CACHE:
		return bool(e["recovered"])
	return bool(OUTLIVES_AUTHOR[medium])


## Everything that made it. This is the win condition, not a bonus screen.
func surviving_ids() -> PackedStringArray:
	var out := PackedStringArray()
	for id in entries:
		if survives(String(id)):
			out.append(String(id))
	return out


## Everything the party saw and failed to keep. Named separately because the
## game should be able to show the player this list, and because a system that
## can only report successes is the kind of check CLAUDE.md rule 1 warns about.
func lost_ids() -> PackedStringArray:
	var out := PackedStringArray()
	for id in entries:
		if not survives(String(id)):
			out.append(String(id))
	return out


## Denominator. Any caller reporting "n things survived" must be able to say
## out of how many, or the number means nothing.
func witnessed_count() -> int:
	return entries.size()


func why_lost(id: String) -> String:
	if not entries.has(id):
		return "never witnessed"
	if survives(id):
		return ""
	var e: Dictionary = entries[id]
	var medium: Medium = e["medium"]
	# Only blame suppression when suppression is what actually did it. An
	# earlier version reported "suppressed" for any entry that had been
	# suppressed, including buried caches that survived the attempt - so the
	# game would have told the player a false story about why a record was
	# lost. The test caught it; the prose was wrong, not the survival rule.
	if e["suppressed"] and not SURVIVES_SUPPRESSION[medium]:
		return "suppressed by %s; %s does not survive that" % [
			e.get("suppressed_by", "someone"), MEDIUM_NAME[medium]]
	if medium == Medium.BURIED_CACHE:
		return "buried and never found"
	if not e["inscribed"]:
		return "witnessed but never written down"
	return "%s did not outlive the people who made it" % MEDIUM_NAME[medium]
