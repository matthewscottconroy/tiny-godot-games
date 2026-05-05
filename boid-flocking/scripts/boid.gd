extends Node2D

const MAX_SPEED        := 130.0
const MIN_SPEED        := 55.0
const NEIGHBOR_RADIUS  := 80.0
const SEP_RADIUS       := 28.0
const SEP_WEIGHT       := 2.2
const ALI_WEIGHT       := 1.0
const COH_WEIGHT       := 0.9
const STEER_MAX        := 180.0

var vel: Vector2 = Vector2.ZERO

func init(pos: Vector2) -> void:
	position = pos
	vel = Vector2.from_angle(randf() * TAU) * 80.0

func step(boids: Array, delta: float) -> void:
	var sep := Vector2.ZERO
	var ali := Vector2.ZERO
	var coh := Vector2.ZERO
	var n   := 0

	for other in boids:
		if other == self:
			continue
		var d := other.position - position
		var dist := d.length()
		if dist > NEIGHBOR_RADIUS or dist < 0.001:
			continue
		n   += 1
		ali += other.vel
		coh += other.position
		if dist < SEP_RADIUS:
			sep -= d.normalized() / dist

	var steering := Vector2.ZERO
	if n > 0:
		var ali_desired := (ali / n).normalized() * MAX_SPEED
		var coh_desired := ((coh / n) - position).normalized() * MAX_SPEED
		steering = sep * SEP_WEIGHT + (ali_desired - vel) * ALI_WEIGHT + (coh_desired - vel) * COH_WEIGHT
		if steering.length() > STEER_MAX:
			steering = steering.normalized() * STEER_MAX

	vel += steering * delta
	var spd := vel.length()
	if spd > MAX_SPEED:
		vel = vel.normalized() * MAX_SPEED
	elif spd < MIN_SPEED and spd > 0.001:
		vel = vel.normalized() * MIN_SPEED

	position += vel * delta

	var vp := get_viewport_rect().size
	if position.x < 0.0:         position.x += vp.x
	elif position.x > vp.x:      position.x -= vp.x
	if position.y < 0.0:         position.y += vp.y
	elif position.y > vp.y:      position.y -= vp.y

	queue_redraw()

func _draw() -> void:
	if vel.length() < 0.01:
		return
	var fwd  := vel.normalized()
	var perp := fwd.rotated(PI * 0.5)
	draw_polygon(
		[fwd * 9.0, -fwd * 5.0 + perp * 4.0, -fwd * 5.0 - perp * 4.0],
		[Color(0.40, 0.78, 1.00)]
	)
