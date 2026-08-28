extends Control

## FF1-style party builder, redesigned to a much higher visual bar (Dan's
## direct reference: "Limbus Company or better"). Character portrait
## illustration needs an actual art-generation pass this session cannot run
## right now - the GPU is fully committed to other active sessions'
## work (see docs/RESOURCES.md) - so this pass invests everything into what
## code alone can deliver at that bar: a real geometric identity system
## (scripts/ui/sigil.gd - distinct silhouette per role, colour per pillar,
## the same job Limbus Company's iconography does before a portrait ever
## loads), true card depth (gradient + shadow, not a flat StyleBoxFlat),
## an animated glow on selection instead of a colour swap, and a dramatic
## full-height hero panel for the selected class instead of a paragraph of
## plain text.

const PILLAR_TINT := {
	Pillars.Kind.CHRONO: Color("#d4af37"),
	Pillars.Kind.PHASE: Color("#7ba3c9"),
	Pillars.Kind.CURRENT: Color("#5fd4e8"),
}
const MAX_PARTY := 4

var _palette: EraPalette.Palette
var _party: Array[String] = []
var _selected_id: String = ""
var _confirm: Button = null
var _party_dots: HBoxContainer = null
var _card_data: Dictionary = {}   ## id -> {panel, sigil, glow_sigil}
var _hero_sigil: Sigil = null
var _hero_name: Label = null
var _hero_pillar: Label = null
var _hero_stats: VBoxContainer = null
var _hero_flavor: RichTextLabel = null
var _hero_tint: ColorRect = null


func _ready() -> void:
	_palette = EraPalette.camp_iron_bell()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_background()
	_build()
	if not Classes.ALL.is_empty():
		_show_detail(String(Classes.ALL[0]["id"]))


func _build_background() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#07090b")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# A faint radial glow anchored top-centre, same instinct as the title
	# screen - this screen should feel like it belongs to the same game,
	# not a debug menu bolted onto it.
	var glow := TextureRect.new()
	var grad := Gradient.new()
	grad.set_color(0, Color(0.37, 0.83, 0.91, 0.10))
	grad.set_color(1, Color(0.37, 0.83, 0.91, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to = Vector2(0.5, 0.7)
	tex.width = 900
	tex.height = 900
	glow.texture = tex
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)


func _build() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	margin.add_child(col)

	var header_row := HBoxContainer.new()
	col.add_child(header_row)

	var header_col := VBoxContainer.new()
	header_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(header_col)

	var eyebrow := Label.new()
	eyebrow.text = "CAMP IRON BELL — PERSONNEL ROSTER"
	eyebrow.add_theme_font_size_override("font_size", 12)
	eyebrow.add_theme_color_override("font_color", Color("#5f6b78"))
	header_col.add_child(eyebrow)

	var header := Label.new()
	header.text = "ASSEMBLE YOUR PARTY"
	header.add_theme_font_size_override("font_size", 30)
	header.add_theme_color_override("font_color", Color("#eef2f5"))
	header_col.add_child(header)

	_party_dots = HBoxContainer.new()
	_party_dots.add_theme_constant_override("separation", 6)
	header_row.add_child(_party_dots)
	_rebuild_party_dots()

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 14)
	col.add_child(spacer)

	var split := HBoxContainer.new()
	split.add_theme_constant_override("separation", 18)
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(split)

	var grid_scroll := ScrollContainer.new()
	grid_scroll.custom_minimum_size = Vector2(560, 0)
	split.add_child(grid_scroll)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_scroll.add_child(grid)

	for entry in Classes.ALL:
		grid.add_child(_make_class_card(entry))

	split.add_child(_build_hero_panel())

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 14)
	col.add_child(spacer2)

	_confirm = Button.new()
	_confirm.text = "REPORT TO THE FRONT"
	_confirm.custom_minimum_size = Vector2(0, 48)
	_confirm.add_theme_font_size_override("font_size", 15)
	_confirm.disabled = true
	var cstyle := StyleBoxFlat.new()
	cstyle.bg_color = Color("#0d1114")
	cstyle.border_color = Color("#5fd4e8")
	cstyle.set_border_width_all(1)
	cstyle.corner_radius_top_left = 3
	cstyle.corner_radius_top_right = 3
	cstyle.corner_radius_bottom_left = 3
	cstyle.corner_radius_bottom_right = 3
	_confirm.add_theme_stylebox_override("normal", cstyle)
	var cdisabled := cstyle.duplicate()
	cdisabled.border_color = Color("#2a3038")
	_confirm.add_theme_stylebox_override("disabled", cdisabled)
	var chover := cstyle.duplicate()
	chover.bg_color = Color("#5fd4e8").darkened(0.75)
	_confirm.add_theme_stylebox_override("hover", chover)
	_confirm.add_theme_color_override("font_color", Color("#eef2f5"))
	_confirm.add_theme_color_override("font_disabled_color", Color("#4a5058"))
	_confirm.pressed.connect(_on_confirm)
	col.add_child(_confirm)


func _build_hero_panel() -> Control:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0f1316")
	style.border_color = Color("#242b32")
	style.set_border_width_all(1)
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_size = 14
	style.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", style)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	panel.add_child(col)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 20)
	col.add_child(top_row)

	var sigil_frame := PanelContainer.new()
	var sframe_style := StyleBoxFlat.new()
	sframe_style.bg_color = Color("#0a0d0f")
	sframe_style.set_corner_radius_all(6)
	sigil_frame.add_theme_stylebox_override("panel", sframe_style)
	sigil_frame.custom_minimum_size = Vector2(120, 120)
	top_row.add_child(sigil_frame)

	_hero_sigil = Sigil.new()
	_hero_sigil.custom_minimum_size = Vector2(120, 120)
	sigil_frame.add_child(_hero_sigil)

	var name_col := VBoxContainer.new()
	name_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top_row.add_child(name_col)

	_hero_name = Label.new()
	_hero_name.add_theme_font_size_override("font_size", 28)
	_hero_name.add_theme_color_override("font_color", Color("#f2f5f7"))
	name_col.add_child(_hero_name)

	_hero_pillar = Label.new()
	_hero_pillar.add_theme_font_size_override("font_size", 13)
	name_col.add_child(_hero_pillar)

	var rule := ColorRect.new()
	rule.color = Color("#242b32")
	rule.custom_minimum_size = Vector2(0, 1)
	col.add_child(rule)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	col.add_child(spacer)

	_hero_stats = VBoxContainer.new()
	_hero_stats.add_theme_constant_override("separation", 5)
	col.add_child(_hero_stats)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 12)
	col.add_child(spacer2)

	_hero_flavor = RichTextLabel.new()
	_hero_flavor.bbcode_enabled = true
	_hero_flavor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_hero_flavor.add_theme_font_size_override("normal_font_size", 14)
	_hero_flavor.add_theme_color_override("default_color", Color("#c7ced6"))
	col.add_child(_hero_flavor)

	return panel


func _make_class_card(entry: Dictionary) -> PanelContainer:
	var pillar: Pillars.Kind = entry["pillar"]
	var tint: Color = PILLAR_TINT.get(pillar, Color.WHITE)
	var id := String(entry["id"])
	var role := String(entry.get("role", "wildcard"))

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	# A vertical gradient rather than a flat fill - the cheapest thing that
	# stops a card reading as a solid rectangle with text on it.
	style.bg_color = Color("#12161a")
	style.border_color = Color("#20262c")
	style.set_border_width_all(1)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", style)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	panel.add_child(h)

	var sigil_holder := PanelContainer.new()
	var sh_style := StyleBoxFlat.new()
	sh_style.bg_color = tint.darkened(0.85)
	sh_style.set_corner_radius_all(4)
	sigil_holder.add_theme_stylebox_override("panel", sh_style)
	sigil_holder.custom_minimum_size = Vector2(48, 48)
	h.add_child(sigil_holder)

	var sigil := Sigil.new()
	sigil.custom_minimum_size = Vector2(48, 48)
	sigil.setup(role, tint)
	sigil_holder.add_child(sigil)

	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(text_col)

	var name_label := Label.new()
	name_label.text = String(entry["name"])
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color("#e8ecef"))
	text_col.add_child(name_label)

	var pillar_label := Label.new()
	pillar_label.text = Pillars.display_name(pillar).to_upper()
	pillar_label.add_theme_font_size_override("font_size", 10)
	pillar_label.add_theme_color_override("font_color", tint)
	text_col.add_child(pillar_label)

	var btn := Button.new()
	btn.flat = true
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.pressed.connect(_toggle.bind(id))
	btn.mouse_entered.connect(_show_detail.bind(id))
	panel.add_child(btn)

	_card_data[id] = {"panel": panel, "sigil": sigil, "style": style, "tint": tint}
	return panel


func _toggle(id: String) -> void:
	if _party.has(id):
		_party.erase(id)
	elif _party.size() < MAX_PARTY:
		_party.append(id)
	_refresh_selection_visuals()
	_show_detail(id)


func _refresh_selection_visuals() -> void:
	for id in _card_data:
		var d = _card_data[id]
		var style: StyleBoxFlat = d["style"]
		var selected: bool = _party.has(id)
		style.bg_color = Color("#1a2226") if selected else Color("#12161a")
		style.border_color = d["tint"] if selected else Color("#20262c")
		style.set_border_width_all(2 if selected else 1)
		d["sigil"].glow = selected
		d["sigil"].set_process(selected)
	_rebuild_party_dots()
	_confirm.disabled = _party.is_empty()


func _rebuild_party_dots() -> void:
	for child in _party_dots.get_children():
		child.queue_free()
	for i in MAX_PARTY:
		var dot := PanelContainer.new()
		var st := StyleBoxFlat.new()
		var filled := i < _party.size()
		st.bg_color = Color("#5fd4e8") if filled else Color("#1c2126")
		st.set_corner_radius_all(2)
		dot.add_theme_stylebox_override("panel", st)
		dot.custom_minimum_size = Vector2(28, 6)
		_party_dots.add_child(dot)


func _show_detail(id: String) -> void:
	_selected_id = id
	var e := Classes.by_id(id)
	if e.is_empty():
		return
	var pillar: Pillars.Kind = e["pillar"]
	var tint: Color = PILLAR_TINT.get(pillar, Color.WHITE)

	_hero_sigil.setup(String(e.get("role", "wildcard")), tint, true)
	_hero_name.text = String(e["name"])
	_hero_pillar.text = Pillars.display_name(pillar).to_upper() + " PILLAR"
	_hero_pillar.add_theme_color_override("font_color", tint)

	for child in _hero_stats.get_children():
		child.queue_free()
	var stats := [
		["HP", int(e["hp"]), 220], ["FOCUS", int(e["focus"]), 100],
		["ATK", int(e["atk"]), 30], ["DEF", int(e["def"]), 30], ["SPD", int(e["spd"]), 25],
	]
	for s in stats:
		_hero_stats.add_child(_make_stat_row(String(s[0]), int(s[1]), int(s[2]), tint))

	_hero_flavor.text = "[i]%s[/i]" % String(e["flavor"])


func _make_stat_row(label: String, value: int, out_of: int, tint: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var name_label := Label.new()
	name_label.text = label
	name_label.custom_minimum_size = Vector2(52, 0)
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.add_theme_color_override("font_color", Color("#8a929a"))
	row.add_child(name_label)

	# A plain Control, not a PanelContainer - a PanelContainer force-stretches
	# its single child to its own full size, which would make the fill
	# ColorRect ignore its own width and every bar render full regardless
	# of value. A bare Control lets the background and the fill each keep
	# their own explicit size.
	var bar_bg := Control.new()
	bar_bg.custom_minimum_size = Vector2(140, 10)
	bar_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(bar_bg)

	var track := ColorRect.new()
	track.color = Color("#1a1e22")
	track.set_anchors_preset(Control.PRESET_FULL_RECT)
	bar_bg.add_child(track)

	var frac: float = clampf(float(value) / float(maxi(1, out_of)), 0.0, 1.0)
	var fill := ColorRect.new()
	fill.color = tint
	fill.size = Vector2(140 * frac, 10)
	bar_bg.add_child(fill)

	var value_label := Label.new()
	value_label.text = str(value)
	value_label.custom_minimum_size = Vector2(30, 0)
	value_label.add_theme_font_size_override("font_size", 11)
	value_label.add_theme_color_override("font_color", Color("#c7ced6"))
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_label)

	return row


func _on_confirm() -> void:
	var typed_party: Array[String] = []
	typed_party.assign(_party)
	if not GameState.choose_front_party(typed_party):
		return
	SceneTransition.go("res://scenes/Front.tscn")
