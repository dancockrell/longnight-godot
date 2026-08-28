class_name Sigil
extends Control

## A drawn geometric identity mark, standing in for character portrait art
## until an actual art pipeline is available (the GPU is shared with other
## active sessions right now - see docs/RESOURCES.md). This is a deliberate
## design system, not a placeholder apology: six roles get six distinct
## silhouettes, three pillars get three distinct colours, and the pairing
## is what a player learns to recognise at a glance - the same job Limbus
## Company's sharp per-character iconography does before you ever see a
## portrait. Zero external assets - every mark is drawn with _draw().

enum Role { ANCHOR, WILDCARD, MEDIC, INFILTRATOR, ANALYST, QUARTERMASTER }

const ROLE_BY_NAME := {
	"anchor": Role.ANCHOR,
	"wildcard": Role.WILDCARD,
	"medic": Role.MEDIC,
	"infiltrator": Role.INFILTRATOR,
	"analyst": Role.ANALYST,
	"quartermaster": Role.QUARTERMASTER,
}

var role: Role = Role.ANCHOR
var tint: Color = Color.WHITE
var glow: bool = false
var _t := 0.0


func setup(role_name: String, color: Color, animated_glow: bool = false) -> void:
	role = ROLE_BY_NAME.get(role_name, Role.WILDCARD)
	tint = color
	glow = animated_glow
	if glow:
		set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var c := size / 2.0
	var r: float = minf(size.x, size.y) * 0.36

	if glow:
		var pulse := 0.75 + 0.25 * sin(_t * 3.0)
		_draw_role_shape(c, r * 1.35, Color(tint.r, tint.g, tint.b, 0.18 * pulse))

	_draw_role_shape(c, r, tint)
	_draw_role_shape(c, r, Color(1, 1, 1, 0.9), true)


func _draw_role_shape(c: Vector2, r: float, col: Color, outline_only: bool = false) -> void:
	var width := 2.2 if outline_only else 0.0
	match role:
		Role.ANCHOR:
			# A hexagon - holds a line, geometrically stable.
			var pts := PackedVector2Array()
			for i in 6:
				var a := TAU * i / 6.0 - PI / 6.0
				pts.append(c + Vector2(cos(a), sin(a)) * r)
			if outline_only:
				pts.append(pts[0])
				draw_polyline(pts, col, width, true)
			else:
				draw_colored_polygon(pts, col)
		Role.WILDCARD:
			# A four-point spark - volatile, asymmetric risk/reward.
			var pts := PackedVector2Array([
				c + Vector2(0, -r), c + Vector2(r * 0.28, -r * 0.28),
				c + Vector2(r, 0), c + Vector2(r * 0.28, r * 0.28),
				c + Vector2(0, r), c + Vector2(-r * 0.28, r * 0.28),
				c + Vector2(-r, 0), c + Vector2(-r * 0.28, -r * 0.28),
			])
			if outline_only:
				var closed := pts.duplicate(); closed.append(pts[0])
				draw_polyline(closed, col, width, true)
			else:
				draw_colored_polygon(pts, col)
		Role.MEDIC:
			# A cross in a circle - the oldest, plainest medical mark.
			if outline_only:
				draw_arc(c, r, 0, TAU, 32, col, width, true)
			else:
				draw_circle(c, r, col)
			var bar := r * 0.34
			var cross_col := Color(0, 0, 0, 1) if not outline_only else col
			draw_rect(Rect2(c - Vector2(bar * 0.32, r * 0.65), Vector2(bar * 0.64, r * 1.3)), cross_col)
			draw_rect(Rect2(c - Vector2(r * 0.65, bar * 0.32), Vector2(r * 1.3, bar * 0.64)), cross_col)
		Role.INFILTRATOR:
			# A forward-leaning triangle - closes distance, commits to one direction.
			var pts := PackedVector2Array([
				c + Vector2(r, 0), c + Vector2(-r * 0.7, -r * 0.85), c + Vector2(-r * 0.7, r * 0.85),
			])
			if outline_only:
				var closed := pts.duplicate(); closed.append(pts[0])
				draw_polyline(closed, col, width, true)
			else:
				draw_colored_polygon(pts, col)
		Role.ANALYST:
			# A lens/eye shape - reads the record before anyone else does.
			if outline_only:
				draw_arc(c, r, 0, TAU, 32, col, width, true)
			else:
				var pts := PackedVector2Array()
				for i in 24:
					var a: float = TAU * i / 24.0
					var eye_r: float = r * (0.5 + 0.5 * absf(sin(a)))
					pts.append(c + Vector2(cos(a), sin(a) * 0.55) * eye_r)
				draw_colored_polygon(pts, col)
		Role.QUARTERMASTER:
			# A square, rotated to a diamond - a filed form, a stamped requisition.
			var pts := PackedVector2Array([
				c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0),
			])
			if outline_only:
				var closed := pts.duplicate(); closed.append(pts[0])
				draw_polyline(closed, col, width, true)
			else:
				draw_colored_polygon(pts, col)
