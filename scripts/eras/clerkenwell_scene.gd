extends BeatPresenter

## Presents Clerkenwell. The yard_fight beat is a real BATTLE - the first
## combat encounter wired into the actual playable game rather than only
## the test harness.

const RESURRECTION_MEN_HP := 60
const RESURRECTION_MEN_ATK := 12


func _ready() -> void:
	super._ready()
	GameState.mark_current_scene("res://scenes/Clerkenwell.tscn")
	apply_palette(EraPalette.london_1888())
	graph = ClerkenwellBeats.beats()
	goto("arrival")


func _populate_buttons(_id: String, beat: Dictionary) -> void:
	match int(beat["kind"]):
		ClerkenwellBeats.Kind.BATTLE:
			buttons.add_child(make_button("They notice you first.", _start_battle))
		ClerkenwellBeats.Kind.DEPART:
			buttons.add_child(make_button("Continue.", _advance.bind("")))
		_:
			buttons.add_child(make_button("Continue", _advance.bind(String(beat.get("next", "")))))


func _advance(next_id: String) -> void:
	if next_id.is_empty():
		_depart()
		return
	goto(next_id)


func _start_battle() -> void:
	var protagonist_data := GameState.protagonist()
	var party: Array[Combatant] = []
	var c := Combatant.from_roster(protagonist_data)
	if c != null:
		GameState.apply_wound_penalty(c)
		party.append(c)
	if party.is_empty():
		# No protagonist chosen (reached this scene directly, e.g. in a
		# screenshot check) - refuse to start an empty-party battle, which
		# Battle.gd's own constructor already treats as a bug, not a fight.
		push_error("Clerkenwell tried to start a battle with no protagonist chosen.")
		goto("codex_note")
		return

	var foes: Array[Combatant] = []
	for i in 2:
		var f := Combatant.new()
		f.id = "resurrection_man_%d" % i
		f.display_name = "a resurrection man"
		f.is_player_side = false
		f.max_hp = RESURRECTION_MEN_HP
		f.hp = RESURRECTION_MEN_HP
		f.atk = RESURRECTION_MEN_ATK
		f.def = 8
		f.spd = 9
		foes.append(f)

	var battle_screen := preload("res://scenes/BattleScreen.tscn").instantiate()
	get_parent().add_child(battle_screen)
	self.visible = false
	battle_screen.setup(party, foes, GameState.exposure, _on_battle_finished.bind(battle_screen))


func _on_battle_finished(_won: bool, downed_ids: PackedStringArray, battle_screen: Node) -> void:
	for id in downed_ids:
		GameState.record_wound(id)
	battle_screen.queue_free()
	self.visible = true
	goto("codex_note")


func _depart() -> void:
	header.text = "END OF BUILT CONTENT"
	body.text = "\n".join(PackedStringArray([
		"Exposure spent this scene: %d" % GameState.exposure.value,
	]))
	for child in buttons.get_children():
		child.queue_free()
	buttons.add_child(make_button("Walk on.", func(): get_tree().change_scene_to_file("res://scenes/Carfax.tscn")))
	buttons.add_child(make_button("Check the register first.", func(): get_tree().change_scene_to_file("res://scenes/Register.tscn")))
	teaches.text = "teaches: one street of Act One remains."
