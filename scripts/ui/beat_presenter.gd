class_name BeatPresenter
extends Control

## Shared chrome for any beat-graph scene (Act 0's camp, Act 1's Whitechapel,
## and whatever comes after). Extracted from camp_scene.gd at the second use
## of this exact pattern rather than the first - two copies of ~90 lines of
## container setup was already one too many, and a third era would have made
## the drift between copies somebody's bug.
##
## A subclass supplies the graph and reacts to choices; this class owns the
## layout math that took three attempts to get right (see the DPI/layout
## postmortem in the Act 0 commit) so that fix is inherited rather than
## re-discovered per era, and now owns the per-era visual identity too
## (docs/CONCEPT.md: "what nice means for this game" - two places should not
## look like the same dark theme twice).

var palette: EraPalette.Palette = EraPalette.camp_iron_bell()

var graph: Dictionary = {}
var header: Label = null
var body: RichTextLabel = null
var teaches: Label = null
var buttons: VBoxContainer = null

var _scroll_style: StyleBoxFlat = null
var _rule: ColorRect = null
var _grain: ColorRect = null


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_background()
	_build_chrome()


## Subclasses call this in their own _ready(), before goto(), once the era
## is known. Re-colours everything already built rather than requiring
## build order to matter.
func apply_palette(p: EraPalette.Palette) -> void:
	palette = p
	if is_instance_valid(_scroll_style):
		_scroll_style.bg_color = p.paper
		_scroll_style.border_color = p.rule
	if is_instance_valid(header):
		header.add_theme_color_override("font_color", p.stamp)
	if is_instance_valid(_rule):
		_rule.color = p.rule
	if is_instance_valid(body):
		body.add_theme_color_override("default_color", p.ink)
	if is_instance_valid(teaches):
		teaches.add_theme_color_override("font_color", p.dim)
	if has_node("/root/Ambience"):
		get_node("/root/Ambience").apply_palette(p)
	queue_redraw()


func _build_background() -> void:
	var bg := ColorRect.new()
	bg.color = palette.bg
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# A soft radial vignette - the cheapest thing that stops a screen reading
	# as "a colour fill with text on it." Built from a GradientTexture2D
	# (engine-generated, no image asset) rather than shipped art, matching
	# the project's no-external-assets discipline.
	var vignette := TextureRect.new()
	var grad := Gradient.new()
	grad.set_color(0, Color(0, 0, 0, 0))
	grad.set_color(1, Color(0, 0, 0, 0.55))
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

	# Faint animated grain over the whole screen, same instinct as the
	# canvas engine's 10_modern.js post-process pass (film grain over a
	# duotone grade) - a static screen reads as a slide, a screen with one
	# degree of constant motion reads as a place.
	_grain = ColorRect.new()
	_grain.set_anchors_preset(Control.PRESET_FULL_RECT)
	_grain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grain.color = Color(1, 1, 1, 1)
	var sh := Shader.new()
	sh.code = """
shader_type canvas_item;
uniform float amount = 0.03;
float hash(vec2 p){ return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453); }
void fragment(){
	vec2 uv = FRAGCOORD.xy;
	float n = hash(uv + vec2(TIME * 60.0, 0.0));
	COLOR = vec4(vec3(n), amount);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("amount", palette.noise_amount)
	_grain.material = mat
	add_child(_grain)


func _build_chrome() -> void:
	# Footer is a direct sibling of the scroll area in one outer
	# VBoxContainer, not nested inside it - a footer built any other way can
	# be starved of space by long body text at some resolution and pushed off
	# the visible window while still being "correctly" laid out by the box
	# model. clip_contents on the scroll panel keeps overflow from spilling
	# into the footer's territory instead of relying on size math to be exact.
	var outer := VBoxContainer.new()
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("separation", 0)
	add_child(outer)

	var margin := MarginContainer.new()
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 12)
	outer.add_child(margin)

	var scroll_panel := PanelContainer.new()
	_scroll_style = StyleBoxFlat.new()
	_scroll_style.bg_color = palette.paper
	_scroll_style.border_color = palette.rule
	_scroll_style.set_border_width_all(1)
	_scroll_style.set_content_margin_all(24)
	_scroll_style.shadow_color = Color(0, 0, 0, 0.35)
	_scroll_style.shadow_size = 10
	scroll_panel.add_theme_stylebox_override("panel", _scroll_style)
	scroll_panel.clip_contents = true
	margin.add_child(scroll_panel)

	var text_col := VBoxContainer.new()
	text_col.add_theme_constant_override("separation", 16)
	scroll_panel.add_child(text_col)

	header = Label.new()
	header.add_theme_font_size_override("font_size", 19)
	header.add_theme_color_override("font_color", palette.stamp)
	header.add_theme_constant_override("outline_size", 0)
	header.autowrap_mode = TextServer.AUTOWRAP_WORD
	text_col.add_child(header)

	_rule = ColorRect.new()
	_rule.color = palette.rule
	_rule.custom_minimum_size = Vector2(0, 1)
	text_col.add_child(_rule)

	body = RichTextLabel.new()
	body.bbcode_enabled = true
	body.scroll_active = true
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_font_size_override("normal_font_size", 15)
	body.add_theme_color_override("default_color", palette.ink)
	body.add_theme_constant_override("line_separation", 4)
	text_col.add_child(body)

	var footer_margin := MarginContainer.new()
	footer_margin.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	for side in ["left", "right"]:
		footer_margin.add_theme_constant_override("margin_" + side, 40)
	footer_margin.add_theme_constant_override("margin_top", 10)
	footer_margin.add_theme_constant_override("margin_bottom", 16)
	outer.add_child(footer_margin)

	var footer := VBoxContainer.new()
	footer.add_theme_constant_override("separation", 8)
	footer_margin.add_child(footer)

	buttons = VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	footer.add_child(buttons)

	teaches = Label.new()
	teaches.add_theme_font_size_override("font_size", 11)
	teaches.add_theme_color_override("font_color", palette.dim)
	footer.add_child(teaches)


## Render one beat. `kind_labels` maps a beat's numeric kind to the button
## label(s) it should show when it is not a CHOICE - subclasses define their
## own Kind enum, so this stays generic rather than importing one era's enum.
func goto(id: String) -> void:
	if not graph.has(id):
		push_error("BeatPresenter: no beat '%s'. Known: %s" % [id, str(graph.keys())])
		header.text = "BEAT MISSING: " + id
		body.text = "[color=#d05a5a]This is a bug, not an ending.[/color]"
		return

	var beat: Dictionary = graph[id]
	header.text = String(beat["header"])
	body.text = "\n".join(PackedStringArray(beat["lines"]))
	teaches.text = "teaches: " + String(beat.get("teaches", ""))

	for child in buttons.get_children():
		child.queue_free()

	_populate_buttons(id, beat)


## Subclasses override this to add their own buttons (they know their own
## Kind enum and what a "choice" vs "continue" vs "terminal" beat needs).
func _populate_buttons(_id: String, _beat: Dictionary) -> void:
	pass


func make_button(label: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = label
	b.custom_minimum_size = Vector2(0, 38)
	b.add_theme_font_size_override("font_size", 14)
	var style := StyleBoxFlat.new()
	style.bg_color = palette.paper.lightened(0.06)
	style.border_color = palette.stamp
	style.set_border_width_all(1)
	style.set_content_margin_all(8)
	style.set_corner_radius_all(2)
	b.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate()
	hover.bg_color = palette.stamp.darkened(0.6)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_color_override("font_color", palette.ink)
	b.add_theme_color_override("font_hover_color", palette.stamp)
	b.pressed.connect(on_press)
	return b
