extends Control

## Act 0, first beat: you are being processed into the programme.
##
## Built in code rather than hand-authored as a .tscn on purpose - the roster
## is data, and a scene file with six hardcoded panels would drift from
## scripts/data/roster.gd the first time anyone edited either one.
##
## Placeholder presentation. This is legibility, not art direction; art
## direction belongs to the lore thread and is not mine to invent.

const BG := Color("#12141a")
const INK := Color("#e8e2d4")
const DIM := Color("#8b8778")
const RULE := Color("#3a3f4a")
const PILLAR_TINT := {
	Pillars.Kind.CHRONO: Color("#c9a227"),
	Pillars.Kind.PHASE: Color("#6f8fae"),
	Pillars.Kind.CURRENT: Color("#7fd4e8"),
}

signal chosen(protagonist_id: String)

var _detail: RichTextLabel = null
var _selected: String = ""


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_paint_background()
	_build()


func _paint_background() -> void:
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)


func _build() -> void:
	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 48)
	root.add_theme_constant_override("margin_right", 48)
	root.add_theme_constant_override("margin_top", 36)
	root.add_theme_constant_override("margin_bottom", 36)
	add_child(root)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	root.add_child(col)

	col.add_child(_heading("CAMP IRON BELL", 30, INK))
	col.add_child(_heading("Mississippi, 1944 — personnel orientation", 15, DIM))
	col.add_child(_hrule())

	var split := HBoxContainer.new()
	split.add_theme_constant_override("separation", 28)
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(split)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	list.custom_minimum_size = Vector2(360, 0)
	split.add_child(list)

	var roster := Roster.PROTAGONISTS
	if roster.is_empty():
		list.add_child(_heading("NO ROSTER LOADED — this screen has nothing to show and is not a working select screen.", 14, Color("#d05a5a")))
		return

	for entry in roster:
		list.add_child(_person_button(entry))

	_detail = RichTextLabel.new()
	_detail.bbcode_enabled = true
	_detail.fit_content = false
	_detail.scroll_active = true
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail.add_theme_font_size_override("normal_font_size", 15)
	split.add_child(_detail)

	var confirm := Button.new()
	confirm.text = "REPORT FOR ORIENTATION"
	confirm.custom_minimum_size = Vector2(0, 42)
	confirm.add_theme_font_size_override("font_size", 15)
	confirm.pressed.connect(_confirm)
	col.add_child(confirm)

	_show(String(roster[0]["id"]))


func _confirm() -> void:
	if not GameState.choose(_selected):
		# GameState.choose already named the bad id. Refuse to start rather
		# than silently beginning somebody else's story.
		return
	chosen.emit(_selected)
	get_tree().change_scene_to_file("res://scenes/Camp.tscn")


func _person_button(entry: Dictionary) -> Button:
	var b := Button.new()
	var pillar: Pillars.Kind = entry["pillar"]
	b.text = "  %s\n  %s · %d" % [
		String(entry["name"]), Pillars.display_name(pillar), int(entry["origin_year"])]
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(0, 58)
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_hover_color", PILLAR_TINT.get(pillar, INK))
	b.add_theme_font_size_override("font_size", 14)
	b.pressed.connect(_show.bind(String(entry["id"])))
	return b


func _show(id: String) -> void:
	var e := Roster.by_id(id)
	if e.is_empty():
		# Roster.by_id already pushed the error naming the bad id. Say so on
		# screen too rather than rendering a blank panel that looks designed.
		_detail.text = "[color=#d05a5a]No such protagonist: %s[/color]" % id
		return
	_selected = id
	var pillar: Pillars.Kind = e["pillar"]
	var tint: Color = PILLAR_TINT.get(pillar, INK)
	var lines := PackedStringArray()
	lines.append("[font_size=24][color=#%s]%s[/color][/font_size]" % [INK.to_html(false), String(e["name"])])
	lines.append("[color=#%s]%s pillar · from %d · %s[/color]" % [
		tint.to_html(false), Pillars.display_name(pillar), int(e["origin_year"]), String(e["role"])])
	lines.append("")
	lines.append("[color=#%s]%d HP · %d focus · %d atk · %d def · %d spd[/color]" % [
		DIM.to_html(false), int(e["hp"]), int(e["focus"]), int(e["atk"]), int(e["def"]), int(e["spd"])])
	lines.append("")
	lines.append("[i]“%s”[/i]" % String(e["thesis"]))
	lines.append("")
	lines.append("[color=#%s]%s[/color]" % [DIM.to_html(false), String(e["bill"])])
	_detail.text = "\n".join(lines)


func _heading(text: String, size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l


func _hrule() -> ColorRect:
	var r := ColorRect.new()
	r.color = RULE
	r.custom_minimum_size = Vector2(0, 1)
	return r


func selected_id() -> String:
	return _selected
