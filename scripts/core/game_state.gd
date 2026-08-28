extends Node

## Autoload. The one place a running game keeps its state.
##
## Deliberately thin. The systems it holds are plain RefCounted objects that
## can be built and tested without a scene tree, and this node exists only to
## give them a lifetime and let scenes find them.

signal protagonist_chosen(id: String)
signal era_changed(era_id: String)

var protagonist_id: String = ""
var era_id: String = "camp_iron_bell"

## The actual current scene path, tracked separately from era_id. era_id
## covers a whole period (three scenes so far share "london_1888") and
## cannot tell them apart; this is what the register screen uses to return
## to whichever specific scene actually opened it, so hardcoding a return
## path in that screen does not silently break as soon as a third scene
## links there. Set by each scene's own _ready(), not inferred.
var current_scene_path: String = "res://scenes/Camp.tscn"

var exposure: Exposure = null
var ledger: Ledger = null
var facts: Relational = null
var archive: Archive = null

## Findings the player has initialled. Kept because the game never tells you
## whether signing was rescue or selection, and the list should be there at
## the end to be read back.
var signed_findings: Array = []


func _ready() -> void:
	reset()


func reset() -> void:
	protagonist_id = ""
	era_id = "camp_iron_bell"
	# The camp is not a period that has to be hidden from. 1944 Mississippi
	# has vocabulary for electricity, so Current costs almost nothing here -
	# a high ceiling means the tutorial can be loud for free, and the player
	# should feel it get expensive the moment they leave.
	exposure = Exposure.new(10000)
	ledger = Ledger.new()
	facts = Relational.new()
	archive = Archive.build_default()
	signed_findings.clear()


func choose(id: String) -> bool:
	var entry := Roster.by_id(id)
	if entry.is_empty():
		# Roster.by_id already named the bad id. Do not fall through to a
		# default protagonist - starting the wrong person's story silently is
		# worse than refusing to start.
		return false
	protagonist_id = id
	# You are a fact for yourself. Everyone else has to be told.
	facts.hold(id, id, true)
	protagonist_chosen.emit(id)
	return true


func protagonist() -> Dictionary:
	if protagonist_id.is_empty():
		return {}
	return Roster.by_id(protagonist_id)


func sign_finding(finding) -> void:
	if finding == null:
		return
	signed_findings.append(finding)


func go_to_era(id: String, ceiling: int) -> void:
	era_id = id
	exposure = Exposure.new(ceiling)
	era_changed.emit(id)


func mark_current_scene(path: String) -> void:
	current_scene_path = path


func era_scene_path() -> String:
	return current_scene_path


## The 1944 front: a class-built party fighting Werk Nachtigall and Hyakki
## Yakō directly, per Dan's direction. Kept entirely separate from
## protagonist_id/party_class_ids namespacing collision risk - the 1888
## story scenes (Camp, Goulston, Flower and Dean, the mortuary shed,
## Clerkenwell) are unchanged and keep using the six named protagonists in
## roster.gd. This is an additive second mode, not a replacement.
var front_party_ids: Array[String] = []


func choose_front_party(ids: Array[String]) -> bool:
	if ids.is_empty():
		push_error("choose_front_party() called with no classes. Refusing to start the front with an empty party - Battle.gd already treats that as a bug, not a fight.")
		return false
	for id in ids:
		if Classes.by_id(id).is_empty():
			# Classes.by_id already named the bad id.
			return false
	front_party_ids = ids
	return true


func front_party_combatants() -> Array[Combatant]:
	var out: Array[Combatant] = []
	for id in front_party_ids:
		var c := Combatant.from_roster(Classes.by_id(id))
		if c != null:
			out.append(c)
	return out
