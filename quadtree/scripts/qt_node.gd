class_name QTNode

const MAX_OBJECTS := 4
const MAX_DEPTH := 6

var bounds: Rect2
var depth: int
var objects: Array = []  # items stored here
var children: Array = []  # 4 QTNode children when subdivided

func _init(b: Rect2, d: int = 0) -> void:
	bounds = b
	depth = d

func clear() -> void:
	objects.clear()
	for c in children:
		c.clear()
	children.clear()

func subdivide() -> void:
	var hw := bounds.size.x * 0.5
	var hh := bounds.size.y * 0.5
	var x := bounds.position.x
	var y := bounds.position.y
	children = [
		QTNode.new(Rect2(x,      y,      hw, hh), depth + 1),
		QTNode.new(Rect2(x + hw, y,      hw, hh), depth + 1),
		QTNode.new(Rect2(x,      y + hh, hw, hh), depth + 1),
		QTNode.new(Rect2(x + hw, y + hh, hw, hh), depth + 1),
	]

func insert(obj: Dictionary) -> void:  # obj has "pos", "radius"
	if children.size() > 0:
		for c in _get_quadrants(obj):
			c.insert(obj)
		return
	objects.append(obj)
	if objects.size() > MAX_OBJECTS and depth < MAX_DEPTH:
		subdivide()
		for o in objects:
			for c in _get_quadrants(o):
				c.insert(o)
		objects.clear()

func query(area: Rect2) -> Array:
	var result: Array = []
	if not bounds.intersects(area):
		return result
	for o in objects:
		if area.has_point(o.pos):
			result.append(o)
	for c in children:
		result.append_array(c.query(area))
	return result

func _get_quadrants(obj: Dictionary) -> Array:
	var r: float = obj.get("radius", 5.0)
	var obj_rect := Rect2(obj.pos - Vector2(r, r), Vector2(r * 2, r * 2))
	var result: Array = []
	for c in children:
		if c.bounds.intersects(obj_rect):
			result.append(c)
	return result

func get_all_rects() -> Array:  # for visualization
	var rects: Array = []
	if children.size() > 0:
		for c in children:
			rects.append_array(c.get_all_rects())
	else:
		rects.append(bounds)
	return rects
