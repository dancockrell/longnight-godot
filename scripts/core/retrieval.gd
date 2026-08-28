class_name Retrieval
extends RefCounted

## The Consistency Finding.
##
## Ruled into the bible by the Project 42 lore master, 27 Aug 2026. Chrono is
## this game's pillar, so the machinery is here.
##
## The loop is already closed. Camp Iron Bell cannot change what happened; it
## can only ever have already been part of it. From which the programme's
## operating constraint falls out:
##
##     A retrieval is consistent only if the subject's absence is already
##     accommodated by the surviving record. You cannot lift a person history
##     is certain about. The programme can only take the people history
##     already loses.
##
## THE AMBIGUITY IS PERMANENT AND THIS FILE MUST NOT RESOLVE IT. That rule is
## a real physical constraint, and it is also an extraordinarily convenient
## excuse for a programme that was going to be selective anyway. Nobody at the
## camp can tell which is doing the work, including whoever initials the form.
## The code therefore computes eligibility and *never* reports a motive - there
## is deliberately no field here for why a subject was refused beyond the
## record's own certainty, because supplying one would answer the question the
## game exists to keep open.
##
## Under RQM the constraint is stranger still: "what happened" is not
## single-valued across observers, so a loop can be self-consistent relative to
## each observer while they still disagree. Certainty is therefore measured
## per-observer, not absolutely, and a subject can be liftable for one
## retrieval team and not another. That gap is where the magical realism lives.

## How firmly the surviving record fixes what became of a person.
##
## Deliberately not a float. A programme that reports a subject as 0.62
## certain has implied a precision the archive does not have, and the form
## does not have that box either.
enum Certainty {
	UNRECORDED,   ## History does not know this person existed.
	DISPUTED,     ## Accounts survive and disagree with each other.
	ATTESTED,     ## One account survives and nothing contradicts it.
	DOCUMENTED,   ## Multiple independent records fix what became of them.
}

const CERTAINTY_NAME := {
	Certainty.UNRECORDED: "unrecorded",
	Certainty.DISPUTED: "disputed",
	Certainty.ATTESTED: "attested",
	Certainty.DOCUMENTED: "documented",
}

## The line the form draws. At or below this, an absence can be accommodated.
const LIFTABLE_AT_OR_BELOW := Certainty.DISPUTED


class Finding extends RefCounted:
	var subject_id: String = ""
	var certainty: Certainty = Certainty.DOCUMENTED
	var consistent: bool = false
	## The form's own words. Bible section 8: the voice is documents, and the
	## register is the horror.
	var form_line: String = ""
	var initialled_by: String = ""
	## What specific event in the story produced this record - "entered into
	## the parish ledger", not why the programme's criteria happen to select
	## these people. That second question is the permanent, deliberate
	## ambiguity above and this field never answers it. Empty when nothing
	## in particular caused the finding. Overridden by Dan directly, 27 Aug
	## 2026, superseding an earlier design that hid this from the player
	## entirely: "we are telling the truth. don't lie and don't hide."
	var cause: String = ""

	func to_form_text() -> String:
		return "Subject %s. Record: %s. Is the subject's absence consistent with the surviving record? %s. %s" % [
			subject_id,
			CERTAINTY_NAME[certainty],
			"YES" if consistent else "NO",
			("Initialled: " + initialled_by) if not initialled_by.is_empty() else "Unsigned.",
		]


## Assess one subject. Returns a Finding rather than a bool, because the
## programme does not make decisions, it produces paperwork.
static func assess(subject_id: String, certainty: Certainty, initials: String = "", cause: String = "") -> Finding:
	if subject_id.is_empty():
		push_error("Retrieval.assess() with no subject. Refusing to produce an unsigned finding about nobody - a blank form that reads as a completed one is exactly the failure this system is about.")
		return null
	var f := Finding.new()
	f.subject_id = subject_id
	f.certainty = certainty
	f.consistent = certainty <= LIFTABLE_AT_OR_BELOW
	f.initialled_by = initials
	f.cause = cause
	f.form_line = f.to_form_text()
	return f


## The uncomfortable consequence, stated plainly so nobody has to rediscover
## it: the better documented a person is, the more certainly the programme
## must leave them where they are.
##
## In a period where the state records some people exhaustively and others not
## at all, that is not a neutral filter. It selects along exactly the lines
## the period already selected along, and the programme can point at physics
## while it does so.
static func liftable(certainty: Certainty) -> bool:
	return certainty <= LIFTABLE_AT_OR_BELOW


## Per-observer assessment, which is the RQM form of the constraint. Two teams
## reading two archives can reach opposite findings about the same person and
## both be consistent. The programme has no procedure for this and the game
## should never supply one.
static func assess_for_observer(subject_id: String, certainty_by_observer: Dictionary) -> Dictionary:
	var out := {}
	for observer in certainty_by_observer:
		out[observer] = assess(subject_id, certainty_by_observer[observer], String(observer))
	return out


## Do the observers disagree about whether this person can be taken? If so,
## there is no fact of the matter about it, and that is not a bug to fix.
static func is_contested(findings: Dictionary) -> bool:
	var any_yes := false
	var any_no := false
	for observer in findings:
		var f: Finding = findings[observer]
		if f == null:
			continue
		if f.consistent:
			any_yes = true
		else:
			any_no = true
	return any_yes and any_no
