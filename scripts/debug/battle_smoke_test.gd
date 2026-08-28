extends Control

## Throwaway verification harness, NOT part of the game's real scene flow.
## Boots straight into a populated battle so the battle screen can be looked
## at directly, without needing click automation to walk the real Boot ->
## Select -> Clerkenwell path. Never referenced by project.godot's
## run/main_scene outside of a manual verification pass.


func _ready() -> void:
	var party: Array[Combatant] = []
	var c := Combatant.from_roster(Roster.by_id("moreau"))
	party.append(c)
	var foes: Array[Combatant] = []
	for i in 2:
		var f := Combatant.new()
		f.id = "resurrection_man_%d" % i
		f.display_name = "a resurrection man"
		f.is_player_side = false
		f.max_hp = 60
		f.hp = 60
		f.atk = 12
		f.def = 8
		f.spd = 9
		foes.append(f)
	var exposure := Exposure.new(120)
	var battle_screen := preload("res://scenes/BattleScreen.tscn").instantiate()
	add_child(battle_screen)
	battle_screen.setup(party, foes, exposure, func(_won): pass)
