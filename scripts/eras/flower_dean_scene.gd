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
			# The investigator's own record-keeping is what moves this -
			# nothing the player says makes the point, the mechanic does.
			GameState.facts.hold(SUBJECT_ID, "flower_dean_parish_ledger", true)
			var finding_after := Retrieval.assess(SUBJECT_ID, Retrieval.Certainty.DOCUMENTED, "")
			GameState.sign_finding(finding_after)
		"hinder":
			GameState.facts.hold(SUBJECT_ID, "flower_dean_parish_ledger", false)
			var finding_still := Retrieval.assess(SUBJECT_ID, Retrieval.Certainty.DISPUTED, "")
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
	var f: Retrieval.Finding = GameState.signed_findings[-1] if not GameState.signed_findings.is_empty() else null
	var finding_line := "No finding was recorded this scene." if f == null else f.to_form_text()
	# The cellar record has no suppressor anywhere in this scene - nobody in
	# 1888 has reason to erase a field report about a German cellar the way
	# Warren had reason to erase the Goulston Street wall - so it always
	# survives under the current design. Reporting that plainly rather than
	# keeping a why_lost() branch that nothing in this scene can trigger.
	body.text = "\n".join(PackedStringArray([
		"Exposure spent this scene: %d" % GameState.exposure.value,
		"",
		"Most recent finding on file:",
		finding_line,
		"",
		"The cellar record survives, filed.",
	]))
	for child in buttons.get_children():
		child.queue_free()
	teaches.text = "teaches: nothing further is built past this point yet."
