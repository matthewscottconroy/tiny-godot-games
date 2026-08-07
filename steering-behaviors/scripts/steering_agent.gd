## A framework-agnostic Craig-Reynolds steering agent.
##
## Holds kinematic state (`position`, `velocity`) and produces steering forces;
## the caller integrates them with `step()` and renders however it likes. It is
## a plain `RefCounted` — not a node — so you can drive your own sprites, bodies,
## or particles with it without inheriting from anything.
##
## Each behaviour returns a *steering force* (desired velocity minus current
## velocity, clamped to `max_force`). Add the force with `step(force, delta)`.
class_name SteeringAgent
extends RefCounted

var position: Vector2
var velocity: Vector2

var max_speed := 140.0        ## top speed (px/s)
var max_force := 200.0        ## max steering force per second — controls turn rate
var arrive_radius := 60.0     ## seek slows to a stop within this radius of the target
var flee_radius := 150.0      ## flee only reacts to threats closer than this
var wander_radius := 50.0     ## radius of the projected wander circle
var wander_distance := 80.0   ## how far ahead the wander circle is projected
var wander_jitter := 90.0     ## random angle change (radians/sec) applied to wander

var wander_angle := 0.0       ## internal wander state

## Steer toward `target`, easing to a stop inside `arrive_radius`.
func seek(target: Vector2) -> Vector2:
	var to_target := target - position
	var dist := to_target.length()
	var speed := max_speed
	if dist < arrive_radius:
		speed = max_speed * (dist / arrive_radius)
	var desired := to_target.normalized() * speed if dist > 0.01 else Vector2.ZERO
	return (desired - velocity).limit_length(max_force)

## Steer directly away from `target` when it is within `flee_radius`;
## otherwise decelerate.
func flee(target: Vector2) -> Vector2:
	var to_target := target - position
	var dist := to_target.length()
	if dist < flee_radius and dist > 0.01:
		var desired := -to_target.normalized() * max_speed
		return (desired - velocity).limit_length(max_force)
	return (-velocity).limit_length(max_force)

## Steer toward a jittering point on a circle projected ahead of the agent,
## producing smooth aimless roaming.
func wander(delta: float) -> Vector2:
	wander_angle += randf_range(-wander_jitter, wander_jitter) * delta
	var ahead := velocity.normalized() if velocity.length() > 0.1 else Vector2.RIGHT
	var target := position + ahead * wander_distance \
		+ Vector2(cos(wander_angle), sin(wander_angle)) * wander_radius
	var to_target := target - position
	var desired := to_target.normalized() * max_speed if to_target.length() > 0.01 else Vector2.ZERO
	return (desired - velocity).limit_length(max_force)

## Integrate a steering force and advance the position by `delta`.
func step(force: Vector2, delta: float) -> void:
	velocity = (velocity + force * delta).limit_length(max_speed)
	position += velocity * delta
