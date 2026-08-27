extends Control

## The actual front door of the game. Boot.tscn used to point straight at
## the select screen, which meant the first thing a player ever saw was a
## personnel roster with no context - correct information, no identity.
## docs/CONCEPT.md exists so a screen like this has something to say.

const BG := Color("#0a0c10")
const INK := Color("#e7ecf2")
const DIM := Color("#6f7d8c")
const GOLD := Color("#c9a227")
const CYAN := Color("#8fd4e8")

var _t := 0.0
var _title_glow: Label = null


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# A slow radial glow behind the title, cyan-white per the bible's own
	# Project 42 effects colour ("like a photograph taken with too much
	# flash") - the one visual idea borrowed from canon rather than invented,
	# because this is the moment the game gets to say which universe it's in.
	var glow := TextureRect.new()
	var grad := Gradient.new()
	grad.set_color(0, Color(CYAN.r, CYAN.g, CYAN.b, 0.14))
	grad.set_color(1, Color(CYAN.r, CYAN.g, CYAN.b, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.42)
	tex.fill_to = Vector2(0.5, 0.85)
	tex.width = 800
	tex.height = 800
	glow.texture = tex
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)

	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_CENTER)
	col.grow_horizontal = Control.GROW_DIRECTION_BOTH
	col.grow_vertical = Control.GROW_DIRECTION_BOTH
	col.add_theme_constant_override("separation", 6)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(col)

	var eyebrow := Label.new()
	eyebrow.text = "PROJECT 42 — THE CHRONO PILLAR"
	eyebrow.add_theme_font_size_override("font_size", 13)
	eyebrow.add_theme_color_override("font_color", DIM)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(eyebrow)

	_title_glow = Label.new()
	_title_glow.text = "THE LONG NIGHT"
	_title_glow.add_theme_font_size_override("font_size", 52)
	_title_glow.add_theme_color_override("font_color", INK)
	_title_glow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_title_glow)

	var tag := Label.new()
	tag.text = "You cannot change what happened. You can only choose what survives it."
	tag.add_theme_font_size_override("font_size", 14)
	tag.add_theme_color_override("font_color", GOLD)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(tag)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 28)
	col.add_child(spacer)

	var begin := Button.new()
	begin.text = "REPORT FOR ORIENTATION"
	begin.custom_minimum_size = Vector2(280, 44)
	begin.add_theme_font_size_override("font_size", 15)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#12161c")
	style.border_color = GOLD
	style.set_border_width_all(1)
	style.set_content_margin_all(8)
	begin.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate()
	hover.bg_color = GOLD.darkened(0.65)
	begin.add_theme_stylebox_override("hover", hover)
	begin.add_theme_color_override("font_color", INK)
	begin.add_theme_color_override("font_hover_color", GOLD)
	begin.pressed.connect(_begin)
	col.add_child(begin)

	var footnote := Label.new()
	footnote.text = "Camp Iron Bell, Mississippi, 1944"
	footnote.add_theme_font_size_override("font_size", 11)
	footnote.add_theme_color_override("font_color", DIM)
	footnote.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(footnote)

	if has_node("/root/Ambience"):
		get_node("/root/Ambience").apply_palette(EraPalette.camp_iron_bell())


func _process(delta: float) -> void:
	# A slow pulse rather than a static title - the smallest possible amount
	# of motion that stops the front door reading as a still image.
	_t += delta
	if is_instance_valid(_title_glow):
		_title_glow.modulate = Color(1, 1, 1, 0.88 + 0.12 * sin(_t * 0.9))


func _begin() -> void:
	get_tree().change_scene_to_file("res://scenes/Select.tscn")
