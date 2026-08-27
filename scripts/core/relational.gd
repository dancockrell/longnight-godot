class_name Relational
extends RefCounted

## Observer-relative facts. The substrate everything else in the game sits on.
##
## Under Rovelli's relational quantum mechanics (1996 - and the anachronism in
## a 1944 setting is the point, not an oversight) a state is relative to an
## observer and there is no view from nowhere. This file is that idea taken
## literally as a data structure: **nothing is a fact simpliciter. Everything
## is a fact for somebody.**
##
## Two consequences the rest of the game is built out of:
##
## 1. Two characters can hold contradictory accounts of the same event and
##    both be correct. There is no arbiter. `disputed()` finds those, and the
##    gap between observers is where the magical realism lives rather than
##    being a bug to reconcile.
##
## 2. A *person* is held the same way a record is. Someone real to fewer and
##    fewer observers is losing anchoring, and that is not a metaphor for
##    Phase attenuation - it is the same store and the same arithmetic. When
##    the last observer stops holding you, you are not a fact for anyone.
##
## Werk Nachtigall gets none of this, and their exclusion is the tragedy
## rather than a rule imposed from outside: they are the control group in
## their own experiment, locked out of both the geometry and the relation, and
## brute-forcing with bodies what the other two get elegantly.

## fact_id -> { observer_id: bool }
## The bool is what that observer holds to be the case. Absence from the
## dictionary is not "false" - it is "this observer has no state about it",
## which is a third thing and the file refuses to collapse it into either.
var _held: Dictionary = {}


## Record that an observer holds a fact to be true or false. Both are real
## states; disagreement is expected and is not an error.
func hold(fact_id: String, observer_id: String, value: bool = true) -> void:
	if fact_id.is_empty() or observer_id.is_empty():
		push_error("Relational.hold() needs both a fact and an observer, got fact='%s' observer='%s'. There is no view from nowhere in this system and an anonymous holder would be exactly that." % [fact_id, observer_id])
		return
	if not _held.has(fact_id):
		_held[fact_id] = {}
	_held[fact_id][observer_id] = value


## An observer stops holding it at all - not "believes it false", but has no
## state about it. This is how anchoring is lost.
func release(fact_id: String, observer_id: String) -> void:
	if _held.has(fact_id):
		_held[fact_id].erase(observer_id)


## Three-valued on purpose. "true", "false", and "this observer has no state"
## are different, and folding the third into either of the first two is where
## the lie would enter.
enum Stance { HOLDS_TRUE, HOLDS_FALSE, NO_STATE }


func stance_of(fact_id: String, observer_id: String) -> Stance:
	if not _held.has(fact_id):
		return Stance.NO_STATE
	if not _held[fact_id].has(observer_id):
		return Stance.NO_STATE
	return Stance.HOLDS_TRUE if _held[fact_id][observer_id] else Stance.HOLDS_FALSE


## How many observers hold this as a fact. For a person, this is their
## anchoring, and Phase attenuation is this number falling.
func anchoring(fact_id: String) -> int:
	if not _held.has(fact_id):
		return 0
	var n := 0
	for observer in _held[fact_id]:
		if _held[fact_id][observer]:
			n += 1
	return n


## Real to nobody. For a record, forgotten. For a person, something worse, and
## the programme's medical files have a word for it.
func is_fact_for_anyone(fact_id: String) -> bool:
	return anchoring(fact_id) > 0


func observers_holding(fact_id: String) -> PackedStringArray:
	var out := PackedStringArray()
	if not _held.has(fact_id):
		return out
	for observer in _held[fact_id]:
		if _held[fact_id][observer]:
			out.append(String(observer))
	return out


## Facts that at least one observer holds true and at least one holds false.
##
## This is not a list of errors to reconcile. Under RQM both are correct
## relative to their observer, and the game must never resolve them to a
## single account - the disagreement is the content.
func disputed() -> PackedStringArray:
	var out := PackedStringArray()
	for fact_id in _held:
		var any_true := false
		var any_false := false
		for observer in _held[fact_id]:
			if _held[fact_id][observer]:
				any_true = true
			else:
				any_false = true
		if any_true and any_false:
			out.append(String(fact_id))
	return out


## Denominator for anything that reports over this store.
func fact_count() -> int:
	return _held.size()


func known_facts() -> PackedStringArray:
	var out := PackedStringArray()
	for fact_id in _held:
		out.append(String(fact_id))
	return out
