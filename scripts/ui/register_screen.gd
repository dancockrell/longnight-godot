extends Control

## The codex/reflection screen. A flat list, in the programme's own voice -
## per world-aflame-godot's ruling, this is the ONE place in the game where
## state is allowed to be shown at all, and only in the exact permitted
## shape: subject, current consistency, current retrieval availability.
## Nothing else. No headline, no summary sentence, no "you changed this."

const BG := Color("#0c0f14")
const PAPER := Color("#171c24")
const INK := Color("#c7ceD6")
const DIM := Color("#5f6b78")
const RULE := Color("#2a3644")


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 60)
	margin.add_theme_constant_override("margin_right", 60)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	margin.add_child(col)

	var header := Label.new()
	header.text = "FORM 42-D — CONSISTENCY REGISTER"
	header.add_theme_font_size_override("font_size", 20)
	header.add_theme_color_override("font_color", INK)
	col.add_child(header)

	var sub := Label.new()
	sub.text = "Every subject assessed against the surviving record. No entry is annotated."
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", DIM)
	col.add_child(sub)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 16)
	col.add_child(spacer)

	var rule := ColorRect.new()
	rule.color = RULE
	rule.custom_minimum_size = Vector2(0, 1)
	col.add_child(rule)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 10)
	col.add_child(spacer2)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(scroll)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 0)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	var rows := Register.build(GameState.signed_findings)
	if rows.is_empty():
		var empty := Label.new()
		empty.text = "No subjects have been assessed yet."
		empty.add_theme_color_override("font_color", DIM)
		list.add_child(empty)
	else:
		for r in rows:
			list.add_child(_row(r))

	var spacer3 := Control.new()
	spacer3.custom_minimum_size = Vector2(0, 16)
	col.add_child(spacer3)

	# Returns to the era the register was reached from rather than a
	# hardcoded scene, since more than one scene now links here (Flower and
	# Dean Street, the mortuary shed) and hardcoding one would silently
	# break as soon as a third did.
	var back := Button.new()
	back.text = "Close"
	back.custom_minimum_size = Vector2(160, 38)
	back.pressed.connect(func(): get_tree().change_scene_to_file(GameState.era_scene_path()))
	col.add_child(back)


func _row(r: Register.Row) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER
	style.border_color = RULE
	style.border_width_bottom = 1
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)

	var h := HBoxContainer.new()
	panel.add_child(h)

	var name_label := Label.new()
	name_label.text = r.subject_id.replace("_", " ").capitalize()
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_color_override("font_color", INK)
	name_label.add_theme_font_size_override("font_size", 13)
	h.add_child(name_label)

	# to_line() is the ONLY string this screen ever renders for a subject's
	# state, deliberately - see the class doc on Register.Row.to_line().
	var state_label := Label.new()
	state_label.text = r.to_line()
	state_label.add_theme_color_override("font_color", DIM)
	state_label.add_theme_font_size_override("font_size", 13)
	h.add_child(state_label)

	return panel
