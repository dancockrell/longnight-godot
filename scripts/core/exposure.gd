class_name Exposure
extends RefCounted

## The central meter of the game.
##
## Project 42 technology used in a period that has no vocabulary for it is
## legible to that period. Every anachronism spends cover. The historical
## record notices, and rival retrieval teams converge on the noise.
##
## This is the old Long Night thesis - a city looking hard in one direction is
## not looking anywhere else - rebuilt as something the player operates rather
## than reads. It survives era changes because it is about the relationship
## between the programme and history, not about London.
##
## NOT BALANCED. Every number here is a placeholder until the harness has run
## it at volume. See docs/DESIGN.md.

signal threshold_crossed(band: String, value: int)

## Periods differ in how much they can absorb before something is written down.
## A century with a mass press notices faster than one without.
var ceiling: int = 100

var value: int = 0

## Set when a period has been permanently marked. Retrieval teams that leave a
## record behind do not get to un-leave it: the run can recover cover, but the
## record stands.
var records_left: Array[String] = []

## Witnessed events: single actions loud enough that somebody wrote them down.
##
## This exists because the accumulating meter alone did not work. Measured over
## 400 paired runs, a party fighting Forward ended fights in 6.4 rounds against
## 13.9 for a Covered party, and finished only 1.07x louder in total - so going
## loud was strictly better and the meter changed no decisions. Sum-of-noise
## rewards ending things quickly, which is the opposite of the intended play.
##
## A witness is not a sum. One Tesla arc in a public street is written down
## whether the fight lasted two rounds or twenty, and it cannot be recovered.
var witnesses: Array[String] = []

var _last_band: String = ""


func _init(period_ceiling: int) -> void:
	if period_ceiling <= 0:
		push_error("Exposure built with ceiling %d. A period that cannot notice anything makes every anachronism free and silently removes the game's central cost." % period_ceiling)
		return
	ceiling = period_ceiling
	_last_band = band()


## Bands are what the rest of the game reads. They are deliberately coarse:
## the player should feel a state change, not watch a number.
func band() -> String:
	var pct := float(value) / float(ceiling)
	if pct < 0.25:
		return "quiet"
	elif pct < 0.50:
		return "noticed"
	elif pct < 0.75:
		return "reported"
	elif pct < 1.0:
		return "hunted"
	return "burned"


## Returns the amount actually added. Callers that need to assert the mechanism
## fired can compare against what they asked for.
func spend(amount: int, reason: String) -> int:
	if amount < 0:
		push_error("Exposure.spend() called with negative amount %d (reason: %s). Use recover() to reduce; a negative spend hides a bug as a benefit." % [amount, reason])
		return 0
	value = mini(ceiling, value + amount)
	if not reason.is_empty():
		records_left.append(reason)
	_check_band()
	return amount


## A single action loud enough to be written down. Permanent by design:
## recover() does not touch this, because the whole point is that cover is
## rebuildable and the historical record is not.
func witness(reason: String) -> void:
	witnesses.append(reason)


## Cover can be rebuilt - a quiet night, a false trail, a body of work that
## explains the noise as something else. The record cannot.
func recover(amount: int) -> void:
	value = maxi(0, value - absi(amount))
	_check_band()


func is_burned() -> bool:
	return value >= ceiling


func _check_band() -> void:
	var b := band()
	if b != _last_band:
		_last_band = b
		threshold_crossed.emit(b, value)
