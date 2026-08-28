class_name Sigil
extends Control

## A character portrait STAND-IN, not a permanent identity system. Direct
## correction from Dan: an earlier version of this file drew pure heraldic
## crests (hexagon, diamond, spark) with no human shape at all, and that
## reads as abstract UI decoration - "lorem ipsum" - rather than as "a
## person who is still being drawn." This game is about characters, and a
## stand-in for a character has to have the shape of one.
##
## So the primary mark is now a humanoid bust silhouette - head and
## shoulders, the same proportions a real portrait will eventually fill -
## coloured by pillar. The role shape from the original design (hexagon/
## spark/cross/triangle/lens/diamond) survives as a small badge in the
## corner, the same place a class icon sits over a portrait in most RPGs
## (WoW, FFXIV, Limbus Company itself), rather than as the whole mark.
## When real portrait art exists, it drops in behind this bust's silhouette
## mask and the badge stays exactly where it is.

enum Role { ANCHOR, WILDCARD, MEDIC, INFILTRATOR, ANALYST, QUARTERMASTER, HOSTILE }

const ROLE_BY_NAME := {
	"anchor": Role.ANCHOR,
	"wildcard": Role.WILDCARD,
	"medic": Role.MEDIC,
	"infiltrator": Role.INFILTRATOR,
	"analyst": Role.ANALYST,
	"quartermaster": Role.QUARTERMASTER,
	"hostile": Role.HOSTILE,
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
	var scale: float = minf(size.x, size.y)

	if glow:
		var pulse := 0.7 + 0.3 * sin(_t * 3.0)
		_draw_bust(c, scale * 1.06, Color(tint.r, tint.g, tint.b, 0.22 * pulse))

	_draw_bust(c, scale, tint)
	_draw_bust_outline(c, scale, Color(1, 1, 1, 0.35))
	_draw_role_badge(c, scale, tint)


## Head-and-shoulders silhouette - a bust, not a crest. Proportioned the
## way a real portrait crop would be: head roughly the top third, shoulders
## widening toward the bottom edge and clipped there, the way a chest-up
## portrait is cropped rather than showing a full floating head.
func _draw_bust(c: Vector2, scale: float, col: Color) -> void:
	var head_r: float = scale * 0.185
	var head_center := c + Vector2(0, -scale * 0.14)
	draw_circle(head_center, head_r, col)

	var shoulder_top: float = head_center.y + head_r * 0.55
	var shoulder_half_w: float = scale * 0.30
	var bottom: float = c.y + scale * 0.42
	var pts := PackedVector2Array([
		Vector2(c.x - shoulder_half_w * 0.35, shoulder_top),
		Vector2(c.x - shoulder_half_w, bottom),
		Vector2(c.x + shoulder_half_w, bottom),
		Vector2(c.x + shoulder_half_w * 0.35, shoulder_top),
	])
	draw_colored_polygon(pts, col)
	# A soft neck join so the head and shoulders read as one silhouette
	# rather than a circle sitting on top of a separate trapezoid.
	draw_rect(Rect2(Vector2(c.x - head_r * 0.5, head_center.y), Vector2(head_r, head_r * 0.7)), col)


func _draw_bust_outline(c: Vector2, scale: float, col: Color) -> void:
	var head_r: float = scale * 0.185
	var head_center := c + Vector2(0, -scale * 0.14)
	draw_arc(head_center, head_r, 0, TAU, 24, col, 1.5, true)
	var shoulder_top: float = head_center.y + head_r * 0.55
	var shoulder_half_w: float = scale * 0.30
	var bottom: float = c.y + scale * 0.42
	var pts := PackedVector2Array([
		Vector2(c.x - shoulder_half_w * 0.35, shoulder_top),
		Vector2(c.x - shoulder_half_w, bottom),
		Vector2(c.x + shoulder_half_w, bottom),
		Vector2(c.x + shoulder_half_w * 0.35, shoulder_top),
		Vector2(c.x - shoulder_half_w * 0.35, shoulder_top),
	])
	draw_polyline(pts, col, 1.5, true)


## The small corner badge - this is where the six-shape identity language
## from the original design survives, demoted to a supporting role instead
## of standing in for a whole person by itself.
func _draw_role_badge(c: Vector2, scale: float, col: Color) -> void:
	var badge_r: float = scale * 0.135
	var badge_c := c + Vector2(scale * 0.30, scale * 0.32)

	var badge_bg := Color(0.04, 0.05, 0.06, 0.92)
	draw_circle(badge_c, badge_r * 1.35, badge_bg)
	draw_arc(badge_c, badge_r * 1.35, 0, TAU, 20, col, 1.2, true)

	match role:
		Role.ANCHOR:
			var pts := PackedVector2Array()
			for i in 6:
				var a: float = TAU * i / 6.0 - PI / 6.0
				pts.append(badge_c + Vector2(cos(a), sin(a)) * badge_r)
			draw_colored_polygon(pts, col)
		Role.WILDCARD:
			var pts := PackedVector2Array([
				badge_c + Vector2(0, -badge_r), badge_c + Vector2(badge_r * 0.28, -badge_r * 0.28),
				badge_c + Vector2(badge_r, 0), badge_c + Vector2(badge_r * 0.28, badge_r * 0.28),
				badge_c + Vector2(0, badge_r), badge_c + Vector2(-badge_r * 0.28, badge_r * 0.28),
				badge_c + Vector2(-badge_r, 0), badge_c + Vector2(-badge_r * 0.28, -badge_r * 0.28),
			])
			draw_colored_polygon(pts, col)
		Role.MEDIC:
			var bar: float = badge_r * 0.5
			draw_rect(Rect2(badge_c - Vector2(bar * 0.28, bar), Vector2(bar * 0.56, bar * 2.0)), col)
			draw_rect(Rect2(badge_c - Vector2(bar, bar * 0.28), Vector2(bar * 2.0, bar * 0.56)), col)
		Role.INFILTRATOR:
			var pts := PackedVector2Array([
				badge_c + Vector2(badge_r, 0), badge_c + Vector2(-badge_r * 0.7, -badge_r * 0.85),
				badge_c + Vector2(-badge_r * 0.7, badge_r * 0.85),
			])
			draw_colored_polygon(pts, col)
		Role.ANALYST:
			var pts := PackedVector2Array()
			for i in 20:
				var a: float = TAU * i / 20.0
				var eye_r: float = badge_r * (0.5 + 0.5 * absf(sin(a)))
				pts.append(badge_c + Vector2(cos(a), sin(a) * 0.55) * eye_r)
			draw_colored_polygon(pts, col)
		Role.QUARTERMASTER:
			var pts := PackedVector2Array([
				badge_c + Vector2(0, -badge_r), badge_c + Vector2(badge_r, 0),
				badge_c + Vector2(0, badge_r), badge_c + Vector2(-badge_r, 0),
			])
			draw_colored_polygon(pts, col)
		Role.HOSTILE:
			var pts := PackedVector2Array()
			var spikes := 7
			for i in spikes * 2:
				var a: float = TAU * i / float(spikes * 2)
				var this_r: float = badge_r if i % 2 == 0 else badge_r * 0.42
				pts.append(badge_c + Vector2(cos(a), sin(a)) * this_r)
			draw_colored_polygon(pts, col)
