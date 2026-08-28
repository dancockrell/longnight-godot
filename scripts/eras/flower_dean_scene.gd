extends BeatPresenter

## Presents Flower and Dean Street and wires both choices into real systems.
##
## The investigator choice is the mechanically important one: helping her
## enter someone properly into the record actually changes that person's
## Retrieval.Certainty from DISPUTED to DOCUMENTED, which - per the
## Consistency Finding already built in scripts/core/retrieval.gd - makes
## them un-retrievable. Hindering her leaves them DISPUTED, still reachable.
## The game never states why that matters. It just lets the finding change.

const SUBJECT_ID := FlowerDeanBeats.INVESTIGATOR_SUBJECT_ID
const CELLAR_FACT := "cellar_apparatus"


func _ready() -> void:
	super._ready()
	GameState.mark_current_scene("res://scenes/FlowerDean.tscn")
	apply_palette(EraPalette.london_1888())
	graph = FlowerDeanBeats.beats()
	goto("arrival")


func _populate_buttons(_id: String, beat: Dictionary) -> void:
	match int(beat["kind"]):
		FlowerDeanBeats.Kind.CHOICE:
			for c in beat["choices"]:
				buttons.add_child(make_button(String(c["label"]),
					_advance.bind(String(c["next"]), String(c.get("action", "")))))
		FlowerDeanBeats.Kind.DEPART:
			buttons.add_child(make_button("Continue.", _advance.bind("", "")))
		_:
			buttons.add_child(make_button("Continue", _advance.bind(String(beat.get("next", "")), "")))


func _advance(next_id: String, action: String) -> void:
	match action:
		"help":
			# Before: DISPUTED, liftable (see Retrieval.LIFTABLE_AT_OR_BELOW).
			# Stated plainly now rather than hidden - overridden by Dan
			# directly, 27 Aug 2026: "we are telling the truth. don't lie
			# and don't hide." The cause is a fact, not a verdict; nothing
			# here tells the player how to feel about it.
			GameState.facts.hold(SUBJECT_ID, "flower_dean_parish_ledger", true)
			var finding_after := Retrieval.assess(SUBJECT_ID, Retrieval.Certainty.DOCUMENTED, "",
				"Entered into the parish ledger, Flower and Dean Street, 1888.")
			GameState.sign_finding(finding_after)
		"hinder":
			GameState.facts.hold(SUBJECT_ID, "flower_dean_parish_ledger", false)
			var finding_still := Retrieval.assess(SUBJECT_ID, Retrieval.Certainty.DISPUTED, "",
				"Not entered into the parish ledger. The name given did not survive checking.")
			GameState.sign_finding(finding_still)
		"take":
			GameState.ledger.witness(CELLAR_FACT, 1888)
			GameState.ledger.inscribe(CELLAR_FACT, Ledger.Medium.FILED_PAPER)
			# Real cost per the ruling: an anachronistic object is loud.
			GameState.exposure.spend(45, "removed Werk Nachtigall apparatus from the Flower and Dean Street cellar")
			GameState.exposure.witness("Imperial-origin hardware left the site with a retrieval team")
		"leave":
			GameState.ledger.witness(CELLAR_FACT, 1888)
			GameState.ledger.inscribe(CELLAR_FACT, Ledger.Medium.FILED_PAPER)
			# A report is still a record, just a much quieter one - no
			# Exposure cost, because nothing left the period that shouldn't.
		_:
			pass

	if next_id.is_empty():
		_depart()
		return
	goto(next_id)


func _depart() -> void:
	header.text = "END OF BUILT CONTENT"
	# Deliberately NOT showing what any specific finding says here - per
	# world-aflame-godot's state-not-causation ruling, that belongs only in
	# the register screen, in the register's own flat and uniform shape.
	# Reporting a specific finding on this end-of-scene debug screen would
	# be exactly the "before/after, right after you did it" causation signal
	# the ruling forbids.
	body.text = "\n".join(PackedStringArray([
		"Exposure spent this scene: %d" % GameState.exposure.value,
		"",
		"The cellar record survives, filed.",
	]))
	for child in buttons.get_children():
		child.queue_free()
	buttons.add_child(make_button("Walk on.", func(): get_tree().change_scene_to_file("res://scenes/Mortuary.tscn")))
	buttons.add_child(make_button("Check the register first.", func(): get_tree().change_scene_to_file("res://scenes/Register.tscn")))
	teaches.text = "teaches: the record you are building has more than one street's worth in it now."
