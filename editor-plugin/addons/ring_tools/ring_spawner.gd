@tool
## The custom node type the plugin registers. Because the plugin declares it via
## add_custom_type(), it shows up in the Add Node dialog with its own icon.
##
## The generation itself is a static, pure function so it can be tested and
## reasoned about without an editor — the same split that makes @tool scripts
## manageable.
extends Node2D

@export_range(1, 64) var points := 12:
	set(value):
		points = maxi(value, 1)
		queue_redraw()

@export var radius := 100.0:
	set(value):
		radius = maxf(value, 1.0)
		queue_redraw()

## Turns per full pass — above 1 the ring becomes a star polygon.
@export_range(1, 8) var skip := 1:
	set(value):
		skip = maxi(value, 1)
		queue_redraw()

## The ring (or star) as a closed polygon.
static func build(points: int, radius: float, skip: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := maxi(points, 1)
	var step := maxi(skip, 1)
	var visited: Dictionary = {}
	var index := 0
	# Walking with a stride draws a star; stop when the walk returns to a vertex
	# it has already used, which is what closes the figure.
	for i in n:
		if visited.has(index):
			break
		visited[index] = true
		out.append(Vector2.from_angle(TAU * float(index) / float(n)) * radius)
		index = (index + step) % n
	return out

func polygon() -> PackedVector2Array:
	return build(points, radius, skip)

func _draw() -> void:
	var poly := polygon()
	if poly.size() < 2:
		return
	var closed := poly.duplicate()
	closed.append(poly[0])
	draw_polyline(closed, Color(0.4, 0.75, 0.95), 2.0)
	for p in poly:
		draw_circle(p, 4.0, Color(0.95, 0.8, 0.3))
