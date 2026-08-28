extends Control

## The visual battle screen. Drives Battle.gd's granular attack() calls
## directly rather than its auto-resolving step_round()/run_to_completion(),
## which exist for the headless test harness and assume both sides play
## themselves. A real player needs to choose a target and whether to spend
## Exposure on a pillar before each of their own attacks.
##
## DESIGN INTENT, since a screen is worth deciding on rather than just
## laying out. Exposure, not HP, is this game's real stake - a fight can be
## won and still cost the whole act. So Exposure gets the banner across the
## top of the screen, colour-coded to its own band (quiet/noticed/reported/
## hunted/burned), and it is the thing that visibly changes the most during
## a fight that uses a pillar. HP bars still exist because a fight needs
## them, but they are not what this screen is trying to make the player
## watch.
##
## Enemies here are deliberately unnamed and mundane - "resurrection men",
## not monsters, not Werk Nachtigall, not Hyakki Yakō. Per the lore ruling,
## neither of the other two factions gets a physical presence in 1888 combat,
## and body-snatching gangs are a real, well-documented Victorian criminal
## trade (the Anatomy Act of 1832 did not end it, it only changed who paid).

const PILLAR_TINT := {
	Pillars.Kind.CHRONO: Color("#c9a227"),
	Pillars.Kind.PHASE: Color("#6f8fae"),
	Pillars.Kind.CURRENT: Color("#8fd4e8"),
}

const BAND_COLOR := {
	"quiet": Color("#5fae7f"),
	"noticed": Color("#c9a227"),
	"reported": Color("#d68a3c"),
	"hunted": Color("#c9552f"),
	"burned": Color("#8f2b2b"),
}

var battle: Battle = null
var _palette: EraPalette.Palette
var _party_rows: Dictionary = {}
var _foe_rows: Dictionary = {}
var _log: RichTextLabel = null
var _action_panel: VBoxContainer = null
var _exposure_banner: PanelContainer = null
var _exposure_fill: ColorRect = null
var _exposure_label: Label = null
var _on_finished: Callable = Callable()
var _flash_shader: Shader = null
var _fog: ColorRect = null


func setup(party: Array[Combatant], foes: Array[Combatant], exposure: Exposure, on_finished: Callable) -> void:
	battle = Battle.new(party, foes, exposure)
	_on_finished = on_finished
	_build()
	call_deferred("_run_next_turn")


func _ready() -> void:
	_palette = EraPalette.london_1888()
	_flash_shader = load("res://assets/vfx/flash_white.gdshader")


func _build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = _palette.bg
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Fog atmosphere, per the vendored MIT shader (assets/vfx/fog.gdshader,
	# github.com/haowg/GODOT-VFX-LIBRARY) - a period-appropriate wash rather
	# than a flat colour behind the fight. The noise texture is engine-
	# generated at runtime (FastNoiseLite), no external image asset needed.
	_fog = ColorRect.new()
	_fog.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fog.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fog.color = Color(0.55, 0.58, 0.6)
	var fog_shader := load("res://assets/vfx/fog.gdshader")
	var fog_mat := ShaderMaterial.new()
	fog_mat.shader = fog_shader
	var noise := FastNoiseLite.new()
	noise.seed = 7
	noise.frequency = 0.02
	var noise_tex := NoiseTexture2D.new()
	noise_tex.noise = noise
	noise_tex.width = 256
	noise_tex.height = 256
	noise_tex.seamless = true
	fog_mat.set_shader_parameter("noise_texture", noise_tex)
	fog_mat.set_shader_parameter("density", 0.12)
	_fog.material = fog_mat
	add_child(_fog)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	margin.add_child(col)

	var header := Label.new()
	header.text = "CONTACT"
	header.add_theme_font_size_override("font_size", 20)
	header.add_theme_color_override("font_color", _palette.stamp)
	col.add_child(header)

	# The Exposure banner. This is the screen's actual centrepiece - a solid
	# bar whose fill colour is the CURRENT band, not a generic progress bar,
	# so "we just went from quiet to reported" reads as a colour change a
	# player notices without reading the number.
	_exposure_banner = PanelContainer.new()
	var eb_style := StyleBoxFlat.new()
	eb_style.bg_color = Color("#0a0c0e")
	eb_style.border_color = _palette.rule
	eb_style.set_border_width_all(1)
	eb_style.set_content_margin_all(2)
	_exposure_banner.add_theme_stylebox_override("panel", eb_style)
	_exposure_banner.custom_minimum_size = Vector2(0, 22)
	col.add_child(_exposure_banner)

	var eb_stack := Control.new()
	eb_stack.custom_minimum_size = Vector2(0, 18)
	_exposure_banner.add_child(eb_stack)

	_exposure_fill = ColorRect.new()
	_exposure_fill.color = BAND_COLOR["quiet"]
	_exposure_fill.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	eb_stack.add_child(_exposure_fill)

	_exposure_label = Label.new()
	_exposure_label.add_theme_font_size_override("font_size", 11)
	_exposure_label.add_theme_color_override("font_color", Color("#eee"))
	_exposure_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_exposure_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	eb_stack.add_child(_exposure_label)

	var split := HBoxContainer.new()
	split.add_theme_constant_override("separation", 24)
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(split)

	var party_col := VBoxContainer.new()
	party_col.add_theme_constant_override("separation", 6)
	party_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(party_col)
	for c in battle.party:
		party_col.add_child(_make_combatant_row(c, true))

	var foe_col := VBoxContainer.new()
	foe_col.add_theme_constant_override("separation", 6)
	foe_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(foe_col)
	for c in battle.foes:
		foe_col.add_child(_make_combatant_row(c, false))

	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.custom_minimum_size = Vector2(0, 80)
	_log.add_theme_font_size_override("normal_font_size", 12)
	_log.add_theme_color_override("default_color", _palette.ink)
	col.add_child(_log)

	_action_panel = VBoxContainer.new()
	_action_panel.add_theme_constant_override("separation", 6)
	col.add_child(_action_panel)

	_update_exposure_banner()


func _make_combatant_row(c: Combatant, is_party: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = _palette.paper
	# Party rows carry their pillar's colour as a spine, same visual grammar
	# as the select screen - one identity language across the whole game
	# rather than combat inventing its own. Foe rows get a flat iron-grey
	# edge instead: unnamed, undifferentiated, exactly as written.
	if is_party:
		style.border_width_left = 4
		style.border_color = PILLAR_TINT.get(c.pillar, _palette.rule)
	else:
		style.set_border_width_all(1)
		style.border_color = Color("#3a3632")
	style.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", style)

	var col := VBoxContainer.new()
	panel.add_child(col)

	var name_label := Label.new()
	name_label.text = c.display_name
	name_label.add_theme_color_override("font_color", _palette.ink)
	name_label.add_theme_font_size_override("font_size", 13)
	col.add_child(name_label)

	# A custom-styled fill rather than the default ProgressBar look, and the
	# fill colour itself shifts with HP fraction (healthy/hurt/critical) so
	# the row communicates state at a glance, the same instinct as the
	# Exposure banner one level up.
	var bar_bg := PanelContainer.new()
	var bar_style := StyleBoxFlat.new()
	bar_style.bg_color = Color("#1a1a1a")
	bar_style.set_content_margin_all(1)
	bar_bg.add_theme_stylebox_override("panel", bar_style)
	bar_bg.custom_minimum_size = Vector2(0, 10)
	col.add_child(bar_bg)
	var hp_fill := ColorRect.new()
	hp_fill.custom_minimum_size = Vector2(0, 8)
	bar_bg.add_child(hp_fill)

	var hp_label := Label.new()
	hp_label.text = "%d / %d HP" % [c.hp, c.max_hp]
	hp_label.add_theme_font_size_override("font_size", 10)
	hp_label.add_theme_color_override("font_color", _palette.dim)
	col.add_child(hp_label)

	var row_data := {"panel": panel, "hp_fill": hp_fill, "hp_label": hp_label, "bar_bg": bar_bg}
	if is_party:
		_party_rows[c] = row_data
	else:
		_foe_rows[c] = row_data
	_refresh_one_row(c, row_data)
	return panel


func _refresh_one_row(c: Combatant, row: Dictionary) -> void:
	var frac := float(c.hp) / float(maxi(1, c.max_hp))
	var col: Color
	if frac > 0.5:
		col = Color("#5fae7f")
	elif frac > 0.2:
		col = Color("#c9a227")
	else:
		col = Color("#c9552f")
	row["hp_fill"].color = col
	var full_w: float = row["bar_bg"].size.x if row["bar_bg"].size.x > 0 else 200.0
	row["hp_fill"].custom_minimum_size = Vector2(full_w * frac, 8)
	row["hp_label"].text = "%d / %d HP" % [c.hp, c.max_hp]
	row["panel"].modulate = Color(1, 1, 1, 1) if c.alive else Color(1, 1, 1, 0.35)


func _refresh_rows() -> void:
	for c in _party_rows:
		_refresh_one_row(c, _party_rows[c])
	for c in _foe_rows:
		_refresh_one_row(c, _foe_rows[c])


func _update_exposure_banner() -> void:
	if battle.exposure == null:
		return
	var band := battle.exposure.band()
	var target_color: Color = BAND_COLOR.get(band, BAND_COLOR["quiet"])
	var frac := float(battle.exposure.value) / float(maxi(1, battle.exposure.ceiling))
	var full_w: float = _exposure_banner.size.x if _exposure_banner.size.x > 0 else 400.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_exposure_fill, "color", target_color, 0.3)
	tw.tween_property(_exposure_fill, "custom_minimum_size:x", full_w * frac, 0.3)
	_exposure_label.text = "EXPOSURE — %s (%d / %d)" % [band.to_upper(), battle.exposure.value, battle.exposure.ceiling]


func _log_line(text: String) -> void:
	_log.append_text(text + "\n")


func _run_next_turn() -> void:
	_refresh_rows()
	_update_exposure_banner()

	if battle.living_party().is_empty() or battle.living_foes().is_empty():
		_end_battle()
		return

	var order := battle.turn_order()
	if order.is_empty():
		_end_battle()
		return
	var actor := order[0]

	if not actor.alive:
		call_deferred("_run_next_turn")
		return

	if actor.is_player_side:
		_offer_player_action(actor)
	else:
		var target := battle.threat_target()
		if target != null:
			battle.attack(actor, target)
			_log_line("%s strikes %s." % [actor.display_name, target.display_name])
			_hit_feedback(target, false)
		call_deferred("_run_next_turn")


func _offer_player_action(actor: Combatant) -> void:
	for child in _action_panel.get_children():
		child.queue_free()

	var prompt := Label.new()
	prompt.text = "%s's turn." % actor.display_name
	prompt.add_theme_color_override("font_color", PILLAR_TINT.get(actor.pillar, _palette.stamp))
	_action_panel.add_child(prompt)

	var targets := battle.living_foes()
	for t in targets:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		_action_panel.add_child(row)

		row.add_child(_make_button("Attack " + t.display_name, func():
			battle.attack(actor, t, 1.0, false)
			_log_line("%s attacks %s, plainly." % [actor.display_name, t.display_name])
			_hit_feedback(t, false)
			call_deferred("_run_next_turn")))

		if actor.focus > 20:
			row.add_child(_make_button("Use %s on %s" % [Pillars.display_name(actor.pillar), t.display_name], func():
				actor.focus = maxi(0, actor.focus - 20)
				battle.attack(actor, t, 1.6, true)
				_log_line("%s uses %s on %s. That will be noticed." % [
					actor.display_name, Pillars.display_name(actor.pillar), t.display_name])
				_hit_feedback(t, true)
				call_deferred("_run_next_turn")))


func _make_button(label: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = label
	b.custom_minimum_size = Vector2(0, 32)
	b.add_theme_font_size_override("font_size", 12)
	b.pressed.connect(on_press)
	return b


## Hit feedback: a white flash via the vendored shader, plus a screen shake
## proportional to whether the hit was loud (pillar use) or plain. Cheap,
## standard "juice" - the smallest amount of motion that stops a hit from
## reading as a number changing in a spreadsheet.
func _hit_feedback(target: Combatant, loud: bool) -> void:
	var row = _foe_rows.get(target, _party_rows.get(target, null))
	if row == null:
		return
	var panel: Control = row["panel"]
	var mat := ShaderMaterial.new()
	mat.shader = _flash_shader
	mat.set_shader_parameter("flash_amount", 0.85)
	panel.material = mat
	var tw := create_tween()
	tw.tween_method(func(v): mat.set_shader_parameter("flash_amount", v), 0.85, 0.0, 0.25)
	tw.tween_callback(func(): panel.material = null)

	var shake_tw := create_tween()
	var amount := 6.0 if loud else 3.0
	var base_pos := position
	shake_tw.tween_property(self, "position", base_pos + Vector2(amount, 0), 0.03)
	shake_tw.tween_property(self, "position", base_pos - Vector2(amount, 0), 0.03)
	shake_tw.tween_property(self, "position", base_pos, 0.03)


func _end_battle() -> void:
	var won := not battle.living_party().is_empty()
	for child in _action_panel.get_children():
		child.queue_free()
	_log_line("")
	_log_line("[b]%s[/b]" % ("The others withdraw." if won else "Your party is overwhelmed."))
	var cont := _make_button("Continue.", func():
		if _on_finished.is_valid():
			_on_finished.call(won))
	_action_panel.add_child(cont)
