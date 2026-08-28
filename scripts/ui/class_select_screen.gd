extends Control

## FF1-style party builder: choose up to 4 of 20 classes. Additive to the
## existing six-protagonist story flow, not a replacement for it - this
## powers "THE FRONT" (fighting Werk Nachtigall and Hyakki Yakō directly in
## 1944), the six named protagonists still own the 1888 story scenes.

const PILLAR_TINT := {
	Pillars.Kind.CHRONO: Color("#c9a227"),
	Pillars.Kind.PHASE: Color("#6f8fae"),
	Pillars.Kind.CURRENT: Color("#8fd4e8"),
}
const MAX_PARTY := 4

var _palette: EraPalette.Palette
var _party: Array[String] = []
var _detail: RichTextLabel = null
var _party_label: Label = null
var _confirm: Button = null
var _card_buttons: Dictionary = {}


func _ready() -> void:
	_palette = EraPalette.camp_iron_bell()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = _palette.bg
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_build()


func _build() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	margin.add_child(col)

	var header := Label.new()
	header.text = "CAMP IRON BELL — THE FRONT"
	header.add_theme_font_size_override("font_size", 24)
	header.add_theme_color_override("font_color", _palette.ink)
	col.add_child(header)

	_party_label = Label.new()
	_party_label.add_theme_font_size_override("font_size", 13)
	_party_label.add_theme_color_override("font_color", _palette.stamp)
	col.add_child(_party_label)

	var split := HBoxContainer.new()
	split.add_theme_constant_override("separation", 20)
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(split)

	var grid_scroll := ScrollContainer.new()
	grid_scroll.custom_minimum_size = Vector2(620, 0)
	split.add_child(grid_scroll)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_scroll.add_child(grid)

	for entry in Classes.ALL:
		grid.add_child(_make_class_card(entry))

	var detail_panel := PanelContainer.new()
	var dstyle := StyleBoxFlat.new()
	dstyle.bg_color = _palette.paper
	dstyle.border_color = _palette.rule
	dstyle.set_border_width_all(1)
	dstyle.set_content_margin_all(16)
	detail_panel.add_theme_stylebox_override("panel", dstyle)
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(detail_panel)

	_detail = RichTextLabel.new()
	_detail.bbcode_enabled = true
	_detail.add_theme_font_size_override("normal_font_size", 14)
	_detail.text = "[i]Choose up to four. FF1-style: a class, not a biography — the people are still being written.[/i]"
	detail_panel.add_child(_detail)

	_confirm = Button.new()
	_confirm.text = "REPORT TO THE FRONT"
	_confirm.custom_minimum_size = Vector2(0, 44)
	_confirm.disabled = true
	_confirm.pressed.connect(_on_confirm)
	col.add_child(_confirm)

	_update_party_label()


func _make_class_card(entry: Dictionary) -> PanelContainer:
	var pillar: Pillars.Kind = entry["pillar"]
	var tint: Color = PILLAR_TINT.get(pillar, _palette.ink)
	var id := String(entry["id"])

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = _palette.paper
	style.border_width_left = 3
	style.border_color = tint
	style.set_content_margin_all(6)
	panel.add_theme_stylebox_override("panel", style)

	var b := Button.new()
	b.flat = true
	b.text = "%s\n%s" % [String(entry["name"]), Pillars.display_name(pillar)]
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(0, 44)
	b.add_theme_font_size_override("font_size", 12)
	b.add_theme_color_override("font_color", _palette.ink)
	b.add_theme_color_override("font_hover_color", tint)
	b.pressed.connect(_toggle.bind(id))
	panel.add_child(b)

	_card_buttons[id] = panel
	return panel


func _toggle(id: String) -> void:
	if _party.has(id):
		_party.erase(id)
	elif _party.size() < MAX_PARTY:
		_party.append(id)
	_refresh_selection_visuals()
	_show_detail(id)


func _refresh_selection_visuals() -> void:
	for id in _card_buttons:
		var panel: PanelContainer = _card_buttons[id]
		var sb: StyleBoxFlat = panel.get_theme_stylebox("panel")
		sb.bg_color = _palette.paper.lightened(0.15) if _party.has(id) else _palette.paper
	_update_party_label()
	_confirm.disabled = _party.is_empty()


func _update_party_label() -> void:
	var names := PackedStringArray()
	for id in _party:
		names.append(String(Classes.by_id(id).get("name", id)))
	_party_label.text = "Party (%d/%d): %s" % [
		_party.size(), MAX_PARTY, (", ".join(names) if not names.is_empty() else "none yet")]


func _show_detail(id: String) -> void:
	var e := Classes.by_id(id)
	if e.is_empty():
		return
	var pillar: Pillars.Kind = e["pillar"]
	var tint: Color = PILLAR_TINT.get(pillar, _palette.ink)
	var lines := PackedStringArray()
	lines.append("[font_size=22][color=#%s]%s[/color][/font_size]" % [_palette.ink.to_html(false), String(e["name"])])
	lines.append("[color=#%s]%s pillar[/color]" % [tint.to_html(false), Pillars.display_name(pillar)])
	lines.append("")
	lines.append("%d HP    %d focus    %d atk    %d def    %d spd" % [
		int(e["hp"]), int(e["focus"]), int(e["atk"]), int(e["def"]), int(e["spd"])])
	lines.append("")
	lines.append("[i]%s[/i]" % String(e["flavor"]))
	_detail.text = "\n".join(lines)


func _on_confirm() -> void:
	var typed_party: Array[String] = []
	typed_party.assign(_party)
	if not GameState.choose_front_party(typed_party):
		return
	SceneTransition.go("res://scenes/Front.tscn")
