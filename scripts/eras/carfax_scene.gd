extends BeatPresenter

## Presents Carfax. The "reckoning" beat is generated at runtime from the
## actual playthrough's Ledger and Register state - not scripted text - per
## docs/DESIGN.md's commitment that Dracula is never a health bar. This is
## the one beat in the game whose content genuinely depends on everything
## the player did across the whole act, not just the current scene.


func _ready() -> void:
	super._ready()
	GameState.mark_current_scene("res://scenes/Carfax.tscn")
	apply_palette(EraPalette.london_1888())
	graph = CarfaxBeats.beats()
	goto("arrival")


func goto(id: String) -> void:
	if id == "reckoning":
		_populate_reckoning()
	super.goto(id)


func _populate_reckoning() -> void:
	var rows := Register.build(GameState.signed_findings)
	var survived := 0
	var lost := 0
	for r in rows:
		if r.retrieval_available:
			survived += 1
		else:
			lost += 1

	var ledger_survived := GameState.ledger.surviving_ids()
	var ledger_lost := GameState.ledger.lost_ids()

	var lines := PackedStringArray()
	lines.append("Across everything you have done in 1888:")
	lines.append("")
	lines.append("Subjects on record: %d. Reachable: %d. Not reachable: %d." % [
		rows.size(), survived, lost])
	lines.append("Things you personally tried to preserve: %d. Survived: %d. Lost: %d." % [
		ledger_survived.size() + ledger_lost.size(), ledger_survived.size(), ledger_lost.size()])
	lines.append("Exposure carried into this room: %d of %d." % [
		GameState.exposure.value, GameState.exposure.ceiling])
	lines.append("")
	lines.append("He does not comment on any of these numbers. He asked what survived you, and now you both know.")

	graph["reckoning"]["lines"] = lines


func _populate_buttons(_id: String, beat: Dictionary) -> void:
	match int(beat["kind"]):
		CarfaxBeats.Kind.CHOICE:
			for c in beat["choices"]:
				buttons.add_child(make_button(String(c["label"]), _advance.bind(String(c["next"]))))
		CarfaxBeats.Kind.DEPART:
			buttons.add_child(make_button("End of Act One.", _advance.bind("")))
		_:
			buttons.add_child(make_button("Continue", _advance.bind(String(beat.get("next", "")))))


func _advance(next_id: String) -> void:
	if next_id.is_empty():
		_depart()
		return
	goto(next_id)


func _depart() -> void:
	header.text = "ACT ONE, COMPLETE"
	body.text = "Nothing further is built past this point."
	for child in buttons.get_children():
		child.queue_free()
	buttons.add_child(make_button("Check the final register.", func(): get_tree().change_scene_to_file("res://scenes/Register.tscn")))
	teaches.text = "teaches: this is the actual end of the built game."
