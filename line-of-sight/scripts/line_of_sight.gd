## A one-call physics line-of-sight test. Casts a ray from `from` to `to` and
## reports whether nothing on `obstacle_mask` blocks it. Give it the caller's
## world space state (`get_world_2d().direct_space_state`) and the RIDs to
## ignore — usually the observer and the target so they don't block themselves.
class_name LineOfSight

static func is_clear(space_state: PhysicsDirectSpaceState2D, from: Vector2, to: Vector2, obstacle_mask: int, exclude: Array = []) -> bool:
	var params := PhysicsRayQueryParameters2D.create(from, to)
	params.exclude = exclude
	params.collision_mask = obstacle_mask
	return space_state.intersect_ray(params).is_empty()
