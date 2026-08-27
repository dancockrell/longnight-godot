extends Control

## Act 0, first beat: you are being processed into the programme.
##
## Built in code rather than hand-authored as a .tscn on purpose - the roster
## is data, and a scene file with six hardcoded panels would drift from
## scripts/data/roster.gd the first time anyone edited either one.

const PILLAR_TINT := {
	Pillars.Kind.CHRONO: Color("#c9a227"),
	Pillars.Kind.PHASE: Color("#6f8fae"),
	Pillars.Kind.CURRENT: Color("#8fd4e8"),
}

signal chosen(protagonist_id: String)

var _palette: EraPalette.Palette = EraPalette.camp_iron_bell()
var _detail: RichTextLabel = null
var _selected: String = ""
var _row_buttons: Dictionary = {}   ## id -> Button, so selection can be shown persistently


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_paint_background()
	_build()
	if has_node("/root/Ambience"):
		get_node("/root/Ambience").apply_palette(_palette)


func _paint_background() -> void:
	var bg := ColorRect.new()
	bg.color = _palette.bg
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var vignette := TextureRect.new()
	var grad := Gradient.new()
	grad.set_color(0, Color(0, 0, 0, 0))
	grad.set_color(1, Color(0, 0, 0, 0.5))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 1.0)
	tex.width = 512
	tex.height = 512
	vignette.texture = tex
	vignette.stretch_mode = TextureRect.STRETCH_SCALE
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)


func _build() -> void:
	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 48)
	root.add_theme_constant_override("margin_right", 48)
	root.add_theme_constant_override("margin_top", 32)
	root.add_theme_constant_override("margin_bottom", 32)
	add_child(root)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	root.add_child(col)

	col.add_child(_heading("CAMP IRON BELL", 28, _palette.ink))
	col.add_child(_heading("Mississippi, 1944 — personnel orientation. Choose who reported tonight.", 14, _palette.dim))
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 14)
	col.add_child(spacer)
	col.add_child(_hrule())
	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 14)
	col.add_child(spacer2)

	var split := HBoxContainer.new()
	split.add_theme_constant_override("separation", 24)
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(split)

	var list_scroll := ScrollContainer.new()
	list_scroll.custom_minimum_size = Vector2(380, 0)
	split.add_child(list_scroll)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_scroll.add_child(list)

	var roster := Roster.PROTAGONISTS
	if roster.is_empty():
		list.add_child(_heading("NO ROSTER LOADED — this screen has nothing to show and is not a working select screen.", 14, Color("#d05a5a")))
		return

	for entry in roster:
		list.add_child(_person_row(entry))

	var detail_panel := PanelContainer.new()
	var dstyle := StyleBoxFlat.new()
	dstyle.bg_color = _palette.paper
	dstyle.border_color = _palette.rule
	dstyle.set_border_width_all(1)
	dstyle.set_content_margin_all(20)
	detail_panel.add_theme_stylebox_override("panel", dstyle)
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(detail_panel)

	_detail = RichTextLabel.new()
	_detail.bbcode_enabled = true
	_detail.fit_content = false
	_detail.scroll_active = true
	_detail.add_theme_font_size_override("normal_font_size", 15)
	_detail.add_theme_constant_override("line_separation", 5)
	detail_panel.add_child(_detail)

	var confirm := Button.new()
	confirm.text = "REPORT FOR ORIENTATION"
	confirm.custom_minimum_size = Vector2(0, 44)
	confirm.add_theme_font_size_override("font_size", 15)
	var cstyle := StyleBoxFlat.new()
	cstyle.bg_color = Color("#12161c")
	cstyle.border_color = _palette.stamp
	cstyle.set_border_width_all(1)
	cstyle.set_content_margin_all(8)
	confirm.add_theme_stylebox_override("normal", cstyle)
	var chover := cstyle.duplicate()
	chover.bg_color = _palette.stamp.darkened(0.65)
	confirm.add_theme_stylebox_override("hover", chover)
	confirm.add_theme_color_override("font_color", _palette.ink)
	confirm.add_theme_color_override("font_hover_color", _palette.stamp)
	confirm.pressed.connect(_confirm)
	var spacer3 := Control.new()
	spacer3.custom_minimum_size = Vector2(0, 12)
	col.add_child(spacer3)
	col.add_child(confirm)

	_show(String(roster[0]["id"]))


func _confirm() -> void:
	if not GameState.choose(_selected):
		# GameState.choose already named the bad id. Refuse to start rather
		# than silently beginning somebody else's story.
		return
	chosen.emit(_selected)
	get_tree().change_scene_to_file("res://scenes/Camp.tscn")


func _person_row(entry: Dictionary) -> PanelContainer:
	var pillar: Pillars.Kind = entry["pillar"]
	var tint: Color = PILLAR_TINT.get(pillar, _palette.ink)
	var id := String(entry["id"])

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = _palette.paper
	style.border_color = _palette.rule
	# The pillar colour lives on the left edge of every card, not just in
	# text - it's the one visual cue that reads at a glance across all six,
	# the way a spine colour tells you which shelf a book is on.
	style.set_border_width_all(1)
	style.border_width_left = 4
	style.border_color = tint
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)

	var b := Button.new()
	b.flat = true
	b.text = "%s\n%s · %d" % [
		String(entry["name"]), Pillars.display_name(pillar), int(entry["origin_year"])]
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(0, 54)
	b.add_theme_color_override("font_color", _palette.ink)
	b.add_theme_color_override("font_hover_color", tint)
	b.add_theme_font_size_override("font_size", 14)
	b.pressed.connect(_show.bind(id))
	panel.add_child(b)

	_row_buttons[id] = panel
	return panel


func _show(id: String) -> void:
	var e := Roster.by_id(id)
	if e.is_empty():
		# Roster.by_id already pushed the error naming the bad id. Say so on
		# screen too rather than rendering a blank panel that looks designed.
		_detail.text = "[color=#d05a5a]No such protagonist: %s[/color]" % id
		return
	_selected = id

	# Persistent selection state, not just a hover colour - a hover-only cue
	# disappears the instant the mouse moves away, which is exactly when a
	# player wants to confirm what they picked.
	for row_id in _row_buttons:
		var panel: PanelContainer = _row_buttons[row_id]
		var sb: StyleBoxFlat = panel.get_theme_stylebox("panel")
		sb.bg_color = _palette.paper.lightened(0.08) if row_id == id else _palette.paper

	var pillar: Pillars.Kind = e["pillar"]
	var tint: Color = PILLAR_TINT.get(pillar, _palette.ink)
	var lines := PackedStringArray()
	lines.append("[font_size=26][color=#%s]%s[/color][/font_size]" % [_palette.ink.to_html(false), String(e["name"])])
	lines.append("[color=#%s]%s pillar · from %d · %s[/color]" % [
		tint.to_html(false), Pillars.display_name(pillar), int(e["origin_year"]), String(e["role"])])
	lines.append("")
	lines.append("[color=#%s]%d HP    %d focus    %d atk    %d def    %d spd[/color]" % [
		_palette.dim.to_html(false), int(e["hp"]), int(e["focus"]), int(e["atk"]), int(e["def"]), int(e["spd"])])
	lines.append("")
	lines.append("[i]“%s”[/i]" % String(e["thesis"]))
	lines.append("")
	lines.append("[color=#%s]%s[/color]" % [_palette.dim.to_html(false), String(e["bill"])])
	_detail.text = "\n".join(lines)


func _heading(text: String, size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l


func _hrule() -> ColorRect:
	var r := ColorRect.new()
	r.color = _palette.rule
	r.custom_minimum_size = Vector2(0, 1)
	return r


func selected_id() -> String:
	return _selected
