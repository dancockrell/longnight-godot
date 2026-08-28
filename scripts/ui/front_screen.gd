extends Control

## The Front: 1944, the party built at ClassSelect fights Werk Nachtigall or
## Hyakki Yakō directly. Uses the same BattleScreen as Clerkenwell's yard
## fight - one combat engine for the whole game, not two.

var _palette: EraPalette.Palette


func _ready() -> void:
	_palette = EraPalette.camp_iron_bell()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = _palette.bg
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_build()


func _build() -> void:
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_CENTER)
	col.grow_horizontal = Control.GROW_DIRECTION_BOTH
	col.grow_vertical = Control.GROW_DIRECTION_BOTH
	col.add_theme_constant_override("separation", 10)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(col)

	var header := Label.new()
	header.text = "THE FRONT — 1944"
	header.add_theme_font_size_override("font_size", 26)
	header.add_theme_color_override("font_color", _palette.ink)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(header)

	var party_names := PackedStringArray()
	for id in GameState.front_party_ids:
		party_names.append(String(Classes.by_id(id).get("name", id)))
	var sub := Label.new()
	sub.text = "Your party: " + (", ".join(party_names) if not party_names.is_empty() else "none")
	sub.add_theme_font_size_override("font_size", 13)
	sub.add_theme_color_override("font_color", _palette.dim)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(sub)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	col.add_child(spacer)

	col.add_child(_make_button("ENGAGE WERK NACHTIGALL", "werk_nachtigall", 3))
	col.add_child(_make_button("ENGAGE THE FUSED (Hyakki Yakō)", "hyakki_yako", 2))
	col.add_child(_make_button("ENGAGE THE COMMAND FRAME (boss)", "wn_boss", 1))


func _make_button(label: String, faction: String, count: int) -> Button:
	var b := Button.new()
	b.text = label
	b.custom_minimum_size = Vector2(320, 42)
	b.add_theme_font_size_override("font_size", 13)
	b.pressed.connect(_start_battle.bind(faction, count))
	return b


func _start_battle(faction: String, count: int) -> void:
	var party := GameState.front_party_combatants()
	if party.is_empty():
		push_error("Front tried to start a battle with no party chosen.")
		return

	var foes: Array[Combatant]
	if faction == "wn_boss":
		foes = [Enemies.make_combatant(Enemies.WN_BOSS, 0)]
	else:
		foes = Enemies.encounter(faction, count)

	var exposure := Exposure.new(10000)  # 1944 front: high ceiling, same reasoning as the camp tutorial
	var battle_screen := preload("res://scenes/BattleScreen.tscn").instantiate()
	get_tree().root.add_child(battle_screen)
	self.visible = false
	battle_screen.setup(party, foes, exposure, _on_battle_finished.bind(battle_screen))


func _on_battle_finished(_won: bool, battle_screen: Node) -> void:
	battle_screen.queue_free()
	self.visible = true
