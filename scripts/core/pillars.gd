class_name Pillars
extends RefCounted

## Project 42's three programme branches, per LORE-BIBLE.md section 5.
##
## These are not elements and they are not magic. Each one is a technology the
## programme does not fully understand, and each one has a documented cost that
## the paperwork gives a bloodless name to.

enum Kind {
	CHRONO,   ## Retrieval. One-way. The programme calls it "settlement".
	PHASE,    ## Infiltration. Overuse is filed as "attenuation".
	CURRENT,  ## Tesla. Runs on theory nobody at the camp can close.
}

## How loudly each pillar reads to a period that has no vocabulary for it.
## Chrono is quiet because arriving is a single event. Current is loud because
## it is light and noise and it does not stop.
const BASE_EXPOSURE := {
	Kind.CHRONO: 1,
	Kind.PHASE: 2,
	Kind.CURRENT: 4,
}

const DISPLAY := {
	Kind.CHRONO: "Chrono",
	Kind.PHASE: "Phase",
	Kind.CURRENT: "Current",
}

## The euphemism each branch's medical files use for what it does to people.
## Bible section 8: the voice system is documents, and the register is the horror.
const COST_EUPHEMISM := {
	Kind.CHRONO: "settlement",
	Kind.PHASE: "attenuation",
	Kind.CURRENT: "load tolerance",
}


static func display_name(k: Kind) -> String:
	return DISPLAY.get(k, "UNKNOWN")


static func base_exposure(k: Kind) -> int:
	if not BASE_EXPOSURE.has(k):
		push_error("base_exposure() called with unknown pillar %s. Refusing to return a silent zero, which would make an anachronism free." % str(k))
		return -1
	return BASE_EXPOSURE[k]
