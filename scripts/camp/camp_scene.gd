extends Control

## Act 0 presenter. Renders one beat at a time and advances the graph.
##
## Built in code for the same reason the select screen is: the beats are data,
## and a hand-authored scene per beat would drift from tutorial_beats.gd the
## first time anyone edited either.

const BG := Color("#0f1116")
const PAPER := Color("#1b1e26")
const INK := Color("#e8e2d4")
const DIM := Color("#8b8778")
const STAMP := Color("#c9a227")

var _graph: Dictionary = {}
var _current: String = ""
var _header: Label = null
var _body: RichTextLabel = null
var _teaches: Label = null
var _buttons: VBoxContainer = null


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_graph = TutorialBeats.beats(GameState.protagonist_id)
	_build_chrome()
	_goto("arrival")

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


func _build_chrome() -> void:
	# STRUCTURE, and why it is shaped this way.
	#
	# The previous version nested everything inside one PanelContainer and
	# relied on VBoxContainer's expand/shrink math to leave room for the
	# footer below a growable body. On a design-sized window that math
	# happened to work out; at 1024x640 it did not, the button row was pushed
	# a few dozen pixels below the visible client area, and the tutorial was
	# unplayable while looking, in a static screenshot of the top of the
	# panel, completely finished. The graph tests (58 of them) could not have
	# caught this - they never touch layout - and neither would a screenshot
	# that only captured the top of a tall panel and was read as "it works".
	#
	# Fix: the footer is a direct sibling of the scroll area in one outer
	# VBoxContainer, not a descendant of a container whose own size is
	# ambiguous. The footer gets SIZE_SHRINK_BEGIN so it only ever claims its
	# own minimum; the scroll area gets EXPAND_FILL and clip_contents so
	# anything that overflows is clipped inside the scroll area rather than
	# spilling into the footer's territory. A footer built this way cannot be
	# pushed off the window by body text length, at any resolution.
	var outer := VBoxContainer.new()
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("separation", 0)
	for side in ["left", "right", "top", "bottom"]:
		outer.add_theme_constant_override("margin_" + side, 0)
	add_child(outer)

	var margin := MarginContainer.new()
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 12)
	outer.add_child(margin)

	var scroll_panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER
	style.border_color = Color("#2b3038")
	style.set_border_width_all(1)
	style.set_content_margin_all(24)
	scroll_panel.add_theme_stylebox_override("panel", style)
	scroll_panel.clip_contents = true
	margin.add_child(scroll_panel)

	var text_col := VBoxContainer.new()
	text_col.add_theme_constant_override("separation", 16)
	scroll_panel.add_child(text_col)

	_header = Label.new()
	_header.add_theme_font_size_override("font_size", 17)
	_header.add_theme_color_override("font_color", STAMP)
	_header.autowrap_mode = TextServer.AUTOWRAP_WORD
	text_col.add_child(_header)

	var rule := ColorRect.new()
	rule.color = Color("#2b3038")
	rule.custom_minimum_size = Vector2(0, 1)
	text_col.add_child(rule)

	_body = RichTextLabel.new()
	_body.bbcode_enabled = true
	_body.scroll_active = true
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_theme_font_size_override("normal_font_size", 15)
	_body.add_theme_color_override("default_color", INK)
	text_col.add_child(_body)

	var footer_margin := MarginContainer.new()
	footer_margin.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	for side in ["left", "right"]:
		footer_margin.add_theme_constant_override("margin_" + side, 40)
	footer_margin.add_theme_constant_override("margin_top", 10)
	footer_margin.add_theme_constant_override("margin_bottom", 16)
	outer.add_child(footer_margin)

	var footer := VBoxContainer.new()
	footer.add_theme_constant_override("separation", 8)
	footer_margin.add_child(footer)

	_buttons = VBoxContainer.new()
	_buttons.add_theme_constant_override("separation", 8)
	footer.add_child(_buttons)

	_teaches = Label.new()
	_teaches.add_theme_font_size_override("font_size", 11)
	_teaches.add_theme_color_override("font_color", DIM)
	footer.add_child(_teaches)


func _goto(id: String) -> void:
	if not _graph.has(id):
		# Do not silently stop on a bad id. A tutorial that ends early looks
		# exactly like a tutorial that finished.
		push_error("Camp tutorial has no beat '%s'. Known: %s" % [id, str(_graph.keys())])
		_header.text = "BEAT MISSING: " + id
		_body.text = "[color=#d05a5a]This is a bug, not an ending.[/color]"
		return

	_current = id
	var beat: Dictionary = _graph[id]
	_header.text = String(beat["header"])
	_body.text = "\n".join(PackedStringArray(beat["lines"]))
	_teaches.text = "teaches: " + String(beat.get("teaches", ""))

	for child in _buttons.get_children():
		child.queue_free()

	match int(beat["kind"]):
		TutorialBeats.Kind.CHOICE:
			for c in beat["choices"]:
				_buttons.add_child(_make_button(String(c["label"]), String(c["next"]), bool(c.get("finding", false))))
		TutorialBeats.Kind.DEPART:
			_buttons.add_child(_make_button("Board.", "", false))
		_:
			_buttons.add_child(_make_button("Continue", String(beat.get("next", "")), false))


func _make_button(label: String, next_id: String, records_finding: bool) -> Button:
	var b := Button.new()
	b.text = label
	b.custom_minimum_size = Vector2(0, 38)
	b.add_theme_font_size_override("font_size", 14)
	b.pressed.connect(_advance.bind(next_id, records_finding))
	return b


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
	_goto(next_id)


## The camp's Exposure ceiling is enormous because 1944 Mississippi has a word
## for a building full of humming. The Victorian period does not, and the drop
## is meant to be felt rather than explained.
func _depart() -> void:
	GameState.go_to_era("london_1888", 120)
	_header.text = "LONDON, 1888"
	_body.text = "[color=#8b8778]Act One is not built yet.[/color]\n\nExposure ceiling has dropped from %d to %d. Everything you are carrying is now loud.\n\nFindings you initialled at the camp: %d." % [
		10000, GameState.exposure.ceiling, GameState.signed_findings.size()]
	for child in _buttons.get_children():
		child.queue_free()
	_teaches.text = "teaches: the cost of every anachronism, from here on."


static func _initials_of(full_name: String) -> String:
	var parts := full_name.split(" ", false)
	if parts.is_empty():
		return "--"
	var out := ""
	for p in parts:
		if p.length() > 0 and p[0] == p[0].to_upper():
			out += p[0]
	return out if out.length() >= 2 else "--"
