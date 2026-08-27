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
## re-discovered per era.

const BG := Color("#0f1116")
const PAPER := Color("#1b1e26")
const INK := Color("#e8e2d4")
const DIM := Color("#8b8778")
const STAMP := Color("#c9a227")

var graph: Dictionary = {}
var header: Label = null
var body: RichTextLabel = null
var teaches: Label = null
var buttons: VBoxContainer = null


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	_build_chrome()


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
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER
	style.border_color = Color("#2b3038")
	style.set_border_width_all(1)
	style.set_content_margin_all(24)
	scroll_panel.add_theme_stylebox_override("panel", style)
	scroll_panel.clip_contents = true
	margin.add_child(scroll_panel)

	var text_col := VBoxContainer.new()
	text_col.add_theme_constant_override("separation", 16)
	scroll_panel.add_child(text_col)

	header = Label.new()
	header.add_theme_font_size_override("font_size", 17)
	header.add_theme_color_override("font_color", STAMP)
	header.autowrap_mode = TextServer.AUTOWRAP_WORD
	text_col.add_child(header)

	var rule := ColorRect.new()
	rule.color = Color("#2b3038")
	rule.custom_minimum_size = Vector2(0, 1)
	text_col.add_child(rule)

	body = RichTextLabel.new()
	body.bbcode_enabled = true
	body.scroll_active = true
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_font_size_override("normal_font_size", 15)
	body.add_theme_color_override("default_color", INK)
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
	teaches.add_theme_color_override("font_color", DIM)
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
	b.pressed.connect(on_press)
	return b
