extends CanvasLayer

## Autoload. Fade-through-black between scenes, the same instinct the old
## canvas engine used for mode changes (docs/DESIGN.md's own account of the
## original game: "a quick fade-through-black on every G.mode change... so
## scene changes read as cuts, not pops"). Not a literal loading bar - every
## scene in this project is lightweight GDScript with no textures to stream,
## so a progress bar would be theatre for a load that is already instant.
## The fade is the honest amount of ceremony for that.

var _rect: ColorRect = null


func _ready() -> void:
	layer = 100
	_rect = ColorRect.new()
	_rect.color = Color(0, 0, 0, 0)
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)


func go(path: String, fade_time: float = 0.18) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var tw := create_tween()
	tw.tween_property(_rect, "color:a", 1.0, fade_time)
	tw.tween_callback(func(): tree.change_scene_to_file(path))
	tw.tween_interval(0.02)
	tw.tween_property(_rect, "color:a", 0.0, fade_time)
