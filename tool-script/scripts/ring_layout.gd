@tool
## Places its children evenly around a ring — and does it in the editor, not just
## at runtime.
##
## `@tool` makes a script run inside the editor as well as in the game. That is
## how you get level-design helpers: arrange things by changing a number instead
## of dragging each one, and see the result immediately without pressing play.
##
## Two rules make @tool scripts safe. First, guard anything with side effects
## with `Engine.is_editor_hint()` — an editor run has no game state, and a script
## that assumes one will spam errors in the Inspector. Second, keep the layout
## itself a pure function of the exported values, so re-running it is harmless.
## `positions_for()` below is that pure function, which is also what makes it
## testable without an editor at all.
class_name RingLayout
extends Node2D

@export var radius := 120.0:
	set(value):
		radius = maxf(value, 0.0)
		_apply()

@export_range(0, 64) var count := 8:
	set(value):
		count = maxi(value, 0)
		_apply()

## Rotation of the whole ring, in degrees.
@export_range(-360, 360) var start_angle := 0.0:
	set(value):
		start_angle = value
		_apply()

## Fraction of a full turn to spread across — 1.0 is a full ring, 0.5 a half arc.
@export_range(0.05, 1.0) var arc := 1.0:
	set(value):
		arc = clampf(value, 0.05, 1.0)
		_apply()

## Point the children outward from the centre.
@export var face_outward := true:
	set(value):
		face_outward = value
		_apply()

## The ring positions, as a pure function of the exported values. No node
## access, so it can be tested — and reasoned about — on its own.
static func positions_for(count: int, radius: float, start_angle_deg: float,
		arc_fraction: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	if count <= 0:
		return out
	var start := deg_to_rad(start_angle_deg)
	var span := TAU * clampf(arc_fraction, 0.0, 1.0)
	# A full ring wraps, so the last slot must not land on the first. A partial
	# arc does not wrap, so both ends should be occupied.
	var divisor := count if is_equal_approx(span, TAU) else maxi(count - 1, 1)
	for i in count:
		var angle := start + span * (float(i) / float(divisor))
		out.append(Vector2.from_angle(angle) * radius)
	return out

## The angle each child should face, given the same inputs.
static func rotations_for(count: int, start_angle_deg: float, arc_fraction: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for p in positions_for(count, 1.0, start_angle_deg, arc_fraction):
		out.append(p.angle())
	return out

func _ready() -> void:
	_apply()

## Position the children. Safe to call any number of times.
func _apply() -> void:
	if not is_inside_tree():
		return
	var children := get_children()
	var slots := positions_for(children.size(), radius, start_angle, arc)
	for i in children.size():
		var child := children[i] as Node2D
		if child == null:
			continue
		child.position = slots[i]
		if face_outward:
			child.rotation = slots[i].angle()
	queue_redraw()

func _draw() -> void:
	# Draw the guide ring in the editor only — it is a design aid, not art.
	if not Engine.is_editor_hint():
		return
	draw_arc(Vector2.ZERO, radius, 0, TAU * arc, 64, Color(1, 1, 1, 0.25), 1.0)
