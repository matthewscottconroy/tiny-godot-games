## Reusable field-of-view test. Given an observer's position and facing, decides
## whether a target is visible: inside the view cone, within range, and not
## occluded by any wall Rect2. Pure geometry — no physics engine — so it works
## on plain positions and hand-authored obstacle rectangles.
class_name VisionCone
extends RefCounted

var half_angle := PI / 3.0   ## half the field of view (total FOV = 2 × this)
var max_range := 180.0       ## how far the observer can see (px)

func _init(cone_half_angle := PI / 3.0, cone_range := 180.0) -> void:
	half_angle = cone_half_angle
	max_range = cone_range

## True if `target` is within range, inside the cone from `origin` facing
## `facing` (radians), and not blocked by any Rect2 in `walls`.
func can_see(origin: Vector2, facing: float, target: Vector2, walls: Array = []) -> bool:
	if origin.distance_to(target) > max_range:
		return false
	var angle_diff := angle_difference((target - origin).angle(), facing)
	if absf(angle_diff) > half_angle:
		return false
	for w in walls:
		if _segment_intersects_rect(origin, target, w):
			return false
	return true

## Liang-Barsky slab test: does segment p1→p2 cross rect r?
func _segment_intersects_rect(p1: Vector2, p2: Vector2, r: Rect2) -> bool:
	var d := p2 - p1
	var t_min := 0.0
	var t_max := 1.0
	var tests := [
		[d.x, r.position.x - p1.x, r.position.x + r.size.x - p1.x],
		[d.y, r.position.y - p1.y, r.position.y + r.size.y - p1.y],
	]
	for t in tests:
		var dv: float = t[0]
		var lo: float = t[1]
		var hi: float = t[2]
		if absf(dv) < 1e-6:
			if lo > 0.0 or hi < 0.0:
				return false
		else:
			var t1 := lo / dv
			var t2 := hi / dv
			if t1 > t2:
				var tmp := t1; t1 = t2; t2 = tmp
			t_min = maxf(t_min, t1)
			t_max = minf(t_max, t2)
			if t_min > t_max:
				return false
	return true
