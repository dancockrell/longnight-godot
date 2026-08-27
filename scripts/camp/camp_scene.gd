extends BeatPresenter

## Act 0 presenter. Renders one beat at a time and advances the graph.
##
## Built in code for the same reason the select screen is: the beats are data,
## and a hand-authored scene per beat would drift from tutorial_beats.gd the
## first time anyone edited either. Chrome is inherited from BeatPresenter,
## extracted here at the second era that needed the identical layout.


func _ready() -> void:
	super._ready()
	graph = TutorialBeats.beats(GameState.protagonist_id)
	goto("arrival")

	if OS.get_environment("LONGNIGHT_DUMP_LAYOUT") == "1":
		call_deferred("_dump_layout_once")


## Diagnostic only, gated behind an env var so it never runs in a real
## session. Prints the ACTUAL computed rects rather than anything inferred
## from a screenshot - added after a screenshot-driven layout fix looked
## right and was not, per CLAUDE.md rule 16b: a displayed image is not the
## pixels, and neither is a static capture the whole story.
func _dump_layout_once() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	print("LAYOUT_DUMP viewport(logical)=%s window(physical)=%s screen_scale=%s content_scale_factor=%s" % [
		str(get_viewport_rect().size),
		str(DisplayServer.window_get_size()),
		str(DisplayServer.screen_get_scale()),
		str(get_viewport().content_scale_factor)])
	_dump_node(self, 0)
	get_tree().quit()


func _dump_node(n: Node, depth: int) -> void:
	if n is Control:
		var c: Control = n
		print("LAYOUT_DUMP %s%s [%s] pos=%s size=%s min=%s" % [
			"  ".repeat(depth), n.name, n.get_class(),
			str(c.position), str(c.size), str(c.get_combined_minimum_size())])
	for child in n.get_children():
		_dump_node(child, depth + 1)


func _populate_buttons(_id: String, beat: Dictionary) -> void:
	match int(beat["kind"]):
		TutorialBeats.Kind.CHOICE:
			for c in beat["choices"]:
				buttons.add_child(make_button(String(c["label"]),
					_advance.bind(String(c["next"]), bool(c.get("finding", false)))))
		TutorialBeats.Kind.DEPART:
			buttons.add_child(make_button("Board.", _advance.bind("", false)))
		_:
			buttons.add_child(make_button("Continue", _advance.bind(String(beat.get("next", "")), false)))


func _advance(next_id: String, records_finding: bool) -> void:
	if records_finding:
		var subject := TutorialBeats.practice_subject(GameState.protagonist_id)
		var initials := _initials_of(String(GameState.protagonist().get("name", "")))
		var finding := Retrieval.assess(
			String(subject.get("id", "unknown")),
			Retrieval.Certainty.DISPUTED,
			initials)
		GameState.sign_finding(finding)

	if next_id.is_empty():
		_depart()
		return
	goto(next_id)


## The camp's Exposure ceiling is enormous because 1944 Mississippi has a word
## for a building full of humming. The Victorian period does not, and the drop
## is meant to be felt rather than explained.
func _depart() -> void:
	GameState.go_to_era("london_1888", 120)
	get_tree().change_scene_to_file("res://scenes/Goulston.tscn")


static func _initials_of(full_name: String) -> String:
	var parts := full_name.split(" ", false)
	if parts.is_empty():
		return "--"
	var out := ""
	for p in parts:
		if p.length() > 0 and p[0] == p[0].to_upper():
			out += p[0]
	return out if out.length() >= 2 else "--"
