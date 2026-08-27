extends BeatPresenter

## Presents the mortuary shed. No Retrieval.assess() call anywhere in this
## file - see the design note at the top of mortuary_beats.gd for why. The
## only system this scene touches is the player's own Ledger record of
## having been here, exactly like Goulston Street's transcription choice.

const OWN_REPORT_FACT := "mortuary_own_report"


func _ready() -> void:
	super._ready()
	GameState.mark_current_scene("res://scenes/Mortuary.tscn")
	apply_palette(EraPalette.london_1888())
	graph = MortuaryBeats.beats()
	goto("arrival")


func _populate_buttons(_id: String, beat: Dictionary) -> void:
	match int(beat["kind"]):
		MortuaryBeats.Kind.CHOICE:
			for c in beat["choices"]:
				buttons.add_child(make_button(String(c["label"]),
					_advance.bind(String(c["next"]), String(c.get("action", "")))))
		MortuaryBeats.Kind.DEPART:
			buttons.add_child(make_button("Continue.", _advance.bind("", "")))
		_:
			buttons.add_child(make_button("Continue", _advance.bind(String(beat.get("next", "")), "")))


func _advance(next_id: String, action: String) -> void:
	match action:
		"record":
			GameState.ledger.witness(OWN_REPORT_FACT, 1888)
			GameState.ledger.inscribe(OWN_REPORT_FACT, Ledger.Medium.FILED_PAPER)
		"silent":
			GameState.ledger.witness(OWN_REPORT_FACT, 1888)
			# No inscribe() call - stays at the default medium, so it does
			# not survive. Choosing silence here has the same shape as
			# Goulston Street's "watch" choice: witnessed, never written
			# down, gone the moment the person who saw it is.
		_:
			pass

	if next_id.is_empty():
		_depart()
		return
	goto(next_id)


func _depart() -> void:
	header.text = "END OF BUILT CONTENT"
	body.text = "\n".join(PackedStringArray([
		"Exposure spent this scene: %d" % GameState.exposure.value,
		"",
		"Whether your own account of the shed survives is a question for the register, not for this screen.",
	]))
	for child in buttons.get_children():
		child.queue_free()
	buttons.add_child(make_button("Check the register.", func(): get_tree().change_scene_to_file("res://scenes/Register.tscn")))
	teaches.text = "teaches: nothing further is built past this point yet."
