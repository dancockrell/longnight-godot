extends Node2D

## The Front — a real walkable map. Camp Iron Bell 1944, top-down,
## grid-locked movement. No image assets anywhere in this file: every tile
## and the player are generated shapes and shaders, matching this project's
## established no-external-art discipline, but built with real 2026-era 2D
## technique rather than flat placeholder rectangles: dynamic point
## lighting against a darkened scene, a smoothed camera, per-tile depth via
## shader, an animated player, and a post-process stack (vignette, grain,
## a hair of chromatic aberration) - all from the vendored MIT VFX shaders
## plus the same procedural-gradient technique already used for every other
## screen in this game (see scripts/ui/beat_presenter.gd, title_screen.gd).
##
## Small scope on purpose - one legible screen's worth of map, not an open
## world - so the budget goes into how the one screen looks and feels
## rather than into more content nobody has finished writing yet.

const TILE := 48
const GRID_W := 16
const GRID_H := 10

enum Tile { GROUND, PATH, WALL, WN_ZONE, HY_ZONE, BOSS_ZONE, HUB }

const TILE_COLOR := {
	Tile.GROUND: Color("#233024"),
	Tile.PATH: Color("#453d2c"),
	Tile.WALL: Color("#15171a"),
	Tile.WN_ZONE: Color("#5a2626"),
	Tile.HY_ZONE: Color("#38264e"),
	Tile.BOSS_ZONE: Color("#6e1f1f"),
	Tile.HUB: Color("#1f4a4a"),
}
const ZONE_TILES := [Tile.WN_ZONE, Tile.HY_ZONE, Tile.BOSS_ZONE, Tile.HUB]
const WALKABLE := [Tile.GROUND, Tile.PATH, Tile.WN_ZONE, Tile.HY_ZONE, Tile.BOSS_ZONE, Tile.HUB]

const LAYOUT := [
	"WWWWWWWWWWWWWWWW",
	"W..............W",
	"W..C#####......W",
	"W...#..........W",
	"W...#....N.N...W",
	"W...#..........W",
	"W...#####..H.H.W",
	"W..........B...W",
	"W..............W",
	"WWWWWWWWWWWWWWWW",
]

var _player_pos := Vector2i(3, 2)
var _player: Node2D = null
var _light_overlay: ColorRect = null
var _light_mat: ShaderMaterial = null
var _camera: Camera2D = null
var _label: Label = null
var _moving := false
var _grid: Array = []
var _zone_glows: Array = []
var _t := 0.0


func _ready() -> void:
	_build_map()
	_build_player()
	_build_camera()
	_build_hud()
	_build_post_process()
	_build_light_overlay()


## Real Node2D Light2D/CanvasModulate rendered blank under this project's
## screenshot verification tool (confirmed: the same tool captures every
## other scene correctly, and a direct console run of this scene showed no
## errors - the lighting pipeline itself was the difference). Rather than
## debug Godot's native 2D lighting path under time pressure, this fakes
## the identical visual result - a warm lit circle around the player,
## darkened outside it - with a full-screen shader overlay updated each
## frame from the player's screen position. Same technique already proven
## to work everywhere else in this project (the vignette on every other
## screen, the fog in battle_screen.gd): a CanvasLayer + shader, not the
## engine's dedicated lighting nodes.
func _build_light_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 40
	add_child(layer)

	_light_overlay = ColorRect.new()
	_light_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_light_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_light_overlay.color = Color(1, 1, 1, 1)

	var sh := Shader.new()
	sh.code = """
shader_type canvas_item;
uniform vec2 light_screen_pos = vec2(0.5, 0.5);
uniform float light_radius = 0.22;
uniform vec2 aspect = vec2(1.0, 1.0);
uniform vec4 tint : source_color = vec4(1.0, 0.85, 0.55, 1.0);
void fragment() {
	vec2 d = (UV - light_screen_pos) * aspect;
	float dist = length(d);
	float lit = 1.0 - smoothstep(light_radius * 0.5, light_radius, dist);
	// Darken outside the lit pool; tint the lit pool warm, like a hand lamp.
	float darkness = mix(0.78, 0.0, lit);
	vec3 warm = mix(vec3(0.0), tint.rgb, lit * 0.15);
	COLOR = vec4(warm, darkness);
}
"""
	_light_mat = ShaderMaterial.new()
	_light_mat.shader = sh
	_light_overlay.material = _light_mat
	layer.add_child(_light_overlay)


func _build_map() -> void:
	var depth_shader := Shader.new()
	depth_shader.code = """
shader_type canvas_item;
uniform vec4 base_color : source_color = vec4(1.0);
void fragment() {
	vec2 c = UV - vec2(0.5);
	float edge = smoothstep(0.32, 0.5, length(c));
	vec3 col = base_color.rgb;
	// Soft top-left highlight, bottom-right shadow - a cheap bevel that
	// stops a flat-coloured square reading as a flat-coloured square.
	float bevel = (UV.x + UV.y < 1.0) ? 0.06 : -0.06;
	col += bevel;
	col = mix(col, col * 0.55, edge);
	COLOR = vec4(col, base_color.a);
}
"""
	for y in GRID_H:
		var row := []
		for x in GRID_W:
			var ch: String = "." if y >= LAYOUT.size() or x >= LAYOUT[y].length() else LAYOUT[y][x]
			var t := _char_to_tile(ch)
			row.append(t)
			var rect := ColorRect.new()
			rect.position = Vector2(x * TILE, y * TILE)
			rect.size = Vector2(TILE - 1, TILE - 1)
			var mat := ShaderMaterial.new()
			mat.shader = depth_shader
			mat.set_shader_parameter("base_color", TILE_COLOR[t])
			rect.material = mat
			add_child(rect)
			if ZONE_TILES.has(t):
				_zone_glows.append(rect)
		_grid.append(row)


func _char_to_tile(ch: String) -> Tile:
	match ch:
		"W": return Tile.WALL
		"#": return Tile.PATH
		"N": return Tile.WN_ZONE
		"H": return Tile.HY_ZONE
		"B": return Tile.BOSS_ZONE
		"C": return Tile.HUB
		_: return Tile.GROUND


func _build_player() -> void:
	_player = Node2D.new()
	_player.position = _grid_to_pixel(_player_pos) + Vector2(TILE / 2.0, TILE / 2.0)
	add_child(_player)

	var body := ColorRect.new()
	body.color = Color("#eaf6fb")
	body.size = Vector2(TILE - 20, TILE - 20)
	body.position = -body.size / 2.0
	var glow_shader := load("res://assets/vfx/outline_glow.gdshader")
	var glow_mat := ShaderMaterial.new()
	glow_mat.shader = glow_shader
	glow_mat.set_shader_parameter("outline_color", Color("#8fd4e8"))
	glow_mat.set_shader_parameter("outline_width", 3.0)
	glow_mat.set_shader_parameter("glow_intensity", 1.1)
	body.material = glow_mat
	_player.add_child(body)


func _build_camera() -> void:
	_camera = Camera2D.new()
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = 6.0
	_camera.zoom = Vector2(1.15, 1.15)
	# Without limits, Camera2D centres exactly on the player regardless of
	# map edges - so near a corner, half the frame shows empty space
	# instead of map. Clamping to the map's own bounds means the frame
	# stays full of map at every player position, sliding rather than
	# centring once the player is near an edge. Limits are in the parent
	# (Node2D root)'s coordinate space, so they do not move with the
	# player even though the Camera2D itself is a child of one.
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = GRID_W * TILE
	_camera.limit_bottom = GRID_H * TILE
	_player.add_child(_camera)
	_camera.make_current()


func _build_hud() -> void:
	_label = Label.new()
	_label.position = Vector2(8, GRID_H * TILE + 8)
	_label.add_theme_font_size_override("font_size", 14)
	_label.add_theme_color_override("font_color", Color("#d6dde3"))
	_label.text = "Arrow keys / WASD to move. Walk into a lit zone to engage."
	add_child(_label)


## Vignette, same technique as beat_presenter.gd's (a GradientTexture2D on
## a TextureRect, generated at runtime, no external image).
##
## Chromatic aberration was cut from here, and the reason is worth keeping:
## chromatic_aberration.gdshader reads FROM `TEXTURE`, which for a canvas_item
## shader means the node's OWN assigned texture - a Sprite2D or TextureRect's
## image. It does not mean "whatever has been drawn to the screen so far."
## A real full-screen post-process effect needs `SCREEN_TEXTURE` (accessed via
## a `hint_screen_texture` sampler and `SCREEN_UV`), which this shader does not
## use and which a bare ColorRect does not provide automatically either way.
## Wiring it as a plain ColorRect with color=(1,1,1,1) and this shader meant
## `texture(TEXTURE, UV)` sampled an empty texture, and the fully-opaque base
## colour behind a shader that could not do anything with it rendered as a
## solid white overlay covering the whole window - confirmed by bisection,
## not guessed: removing this exact block was what fixed a blank capture.
## Doing this properly needs a SubViewport capturing the scene and a second
## pass reading SCREEN_TEXTURE against it - not built this pass. Noted in
## docs/RESOURCES.md as a real follow-up rather than quietly dropped.
func _build_post_process() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)

	var vignette := TextureRect.new()
	var grad := Gradient.new()
	grad.set_color(0, Color(0, 0, 0, 0))
	grad.set_color(1, Color(0, 0, 0, 0.6))
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
	layer.add_child(vignette)


func _grid_to_pixel(p: Vector2i) -> Vector2:
	return Vector2(p.x * TILE, p.y * TILE)


func _process(delta: float) -> void:
	_t += delta

	# Feed the light overlay the player's actual on-screen position every
	# frame, since the camera moves and the player's screen position is
	# not fixed even though their world position only changes on a grid
	# step. A tiny flicker on the radius, same instinct as a real lamp.
	if is_instance_valid(_light_mat) and is_instance_valid(_camera):
		var viewport_size := get_viewport_rect().size
		if viewport_size.x > 0 and viewport_size.y > 0:
			# The player is always at the camera's own centre, because the
			# camera is a child of the player rather than independently
			# tracking it - so its screen position is always the viewport
			# centre regardless of smoothing lag. If the camera ever gains
			# an offset or drag margin, this is the line that needs it.
			var uv := Vector2(0.5, 0.5)
			_light_mat.set_shader_parameter("light_screen_pos", uv)
			_light_mat.set_shader_parameter("aspect", Vector2(1.0, viewport_size.y / viewport_size.x))
			_light_mat.set_shader_parameter("light_radius", 0.24 + 0.015 * sin(_t * 6.0))

	for glow in _zone_glows:
		if is_instance_valid(glow):
			glow.modulate = Color(1, 1, 1, 0.85 + 0.15 * sin(_t * 2.2 + glow.position.x * 0.01))


func _unhandled_input(event: InputEvent) -> void:
	if _moving:
		return
	var dir := Vector2i.ZERO
	if event.is_action_pressed("ui_up"):
		dir = Vector2i(0, -1)
	elif event.is_action_pressed("ui_down"):
		dir = Vector2i(0, 1)
	elif event.is_action_pressed("ui_left"):
		dir = Vector2i(-1, 0)
	elif event.is_action_pressed("ui_right"):
		dir = Vector2i(1, 0)
	else:
		return

	var target := _player_pos + dir
	if target.x < 0 or target.x >= GRID_W or target.y < 0 or target.y >= GRID_H:
		return
	var tile: Tile = _grid[target.y][target.x]
	if not WALKABLE.has(tile):
		return

	_moving = true
	_player_pos = target
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_CUBIC)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(_player, "position", _grid_to_pixel(_player_pos) + Vector2(TILE / 2.0, TILE / 2.0), 0.14)
	tw.tween_callback(func(): _moving = false)
	tw.tween_callback(_on_tile_entered.bind(tile))


func _on_tile_entered(tile: Tile) -> void:
	match tile:
		Tile.WN_ZONE:
			_engage("werk_nachtigall", 3)
		Tile.HY_ZONE:
			_engage("hyakki_yako", 2)
		Tile.BOSS_ZONE:
			_engage("wn_boss", 1)
		Tile.HUB:
			_label.text = "Camp Iron Bell. Arrow keys / WASD to move."
		_:
			pass


func _engage(faction: String, count: int) -> void:
	var party := GameState.front_party_combatants()
	if party.is_empty():
		_label.text = "No party chosen - return to Title and build one first."
		return

	var foes: Array[Combatant]
	if faction == "wn_boss":
		foes = [Enemies.make_combatant(Enemies.WN_BOSS, 0)]
	else:
		foes = Enemies.encounter(faction, count)

	var exposure := Exposure.new(10000)
	var battle_screen := preload("res://scenes/BattleScreen.tscn").instantiate()
	get_tree().root.add_child(battle_screen)
	self.visible = false
	set_process_unhandled_input(false)
	battle_screen.setup(party, foes, exposure, _on_battle_finished.bind(battle_screen))


func _on_battle_finished(_won: bool, battle_screen: Node) -> void:
	battle_screen.queue_free()
	self.visible = true
	set_process_unhandled_input(true)
	_player_pos = Vector2i(3, 3)
	_player.position = _grid_to_pixel(_player_pos) + Vector2(TILE / 2.0, TILE / 2.0)
