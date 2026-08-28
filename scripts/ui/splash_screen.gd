extends Control

## Brief engine/attribution splash before the title. Skippable on any input
## or after a few seconds - nobody should be made to sit through this twice.

const BG := Color("#050607")
const INK := Color("#8a8f96")

var _elapsed := 0.0
var _advancing := false
const AUTO_ADVANCE_AFTER := 3.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_CENTER)
	col.grow_horizontal = Control.GROW_DIRECTION_BOTH
	col.grow_vertical = Control.GROW_DIRECTION_BOTH
	col.add_theme_constant_override("separation", 6)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(col)

	var engine_label := Label.new()
	engine_label.text = "Made with Godot Engine"
	engine_label.add_theme_font_size_override("font_size", 14)
	engine_label.add_theme_color_override("font_color", INK)
	engine_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(engine_label)

	var vfx_label := Label.new()
	vfx_label.text = "Visual effects: GODOT-VFX-LIBRARY (MIT), github.com/haowg/GODOT-VFX-LIBRARY"
	vfx_label.add_theme_font_size_override("font_size", 10)
	vfx_label.add_theme_color_override("font_color", INK.darkened(0.2))
	vfx_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(vfx_label)

	var skip := Label.new()
	skip.text = "(click, press any key, or wait)"
	skip.add_theme_font_size_override("font_size", 9)
	skip.add_theme_color_override("font_color", INK.darkened(0.4))
	skip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(skip)


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= AUTO_ADVANCE_AFTER:
		_advance()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouseButton:
		_advance()


func _advance() -> void:
	if _advancing:
		return
	_advancing = true
	SceneTransition.go("res://scenes/Boot.tscn")
