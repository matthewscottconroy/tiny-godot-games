extends Node2D

const BALL_COUNT := 12
const BALL_R := 16.0
const EXPLOSION_RADIUS := 180.0
const EXPLOSION_STRENGTH := 450.0
const GRAVITY := 300.0
const DAMPING := 0.99

var _balls: Array = []
var _shockwaves: Array = []

func _ready() -> void:
	randomize()
	_balls.clear()
	_shockwaves.clear()
	for i in BALL_COUNT:
		_balls.append({
			pos = Vector2(randf_range(50.0, 590.0), randf_range(50.0, 430.0)),
			vel = Vector2.ZERO,
			color = Color(randf_range(0.3, 1.0), randf_range(0.3, 1.0), randf_range(0.3, 1.0)),
		})

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_explode(event.position)
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		_ready()

func _explode(epicenter: Vector2) -> void:
	_shockwaves.append({pos = epicenter, radius = 0.0, alpha = 1.0})
	for ball in _balls:
		var diff: Vector2 = ball.pos - epicenter
		var dist := diff.length()
		if dist < EXPLOSION_RADIUS and dist > 0.1:
			ball.vel += diff.normalized() * EXPLOSION_STRENGTH * (1.0 - dist / EXPLOSION_RADIUS)

func _process(delta: float) -> void:
	for ball in _balls:
		ball.vel.y += GRAVITY * delta
		ball.vel *= pow(DAMPING, delta)
		ball.pos += ball.vel * delta

		# Bounce off screen edges
		if ball.pos.x < BALL_R:
			ball.pos.x = BALL_R
			ball.vel.x = absf(ball.vel.x) * 0.7
		if ball.pos.x > 640.0 - BALL_R:
			ball.pos.x = 640.0 - BALL_R
			ball.vel.x = -absf(ball.vel.x) * 0.7
		if ball.pos.y < BALL_R:
			ball.pos.y = BALL_R
			ball.vel.y = absf(ball.vel.y) * 0.7
		if ball.pos.y > 480.0 - BALL_R:
			ball.pos.y = 480.0 - BALL_R
			ball.vel.y = -absf(ball.vel.y) * 0.7

	# Update shockwaves
	for sw in _shockwaves:
		sw.radius += 280.0 * delta
		sw.alpha -= 1.8 * delta

	# Remove faded shockwaves
	_shockwaves = _shockwaves.filter(func(sw): return sw.alpha > 0.0)

	queue_redraw()

func _draw() -> void:
	var font := ThemeDB.fallback_font

	# Background
	draw_rect(Rect2(0, 0, 640, 480), Color(0.08, 0.08, 0.12))

	# Shockwaves
	for sw in _shockwaves:
		var col := Color(1.0, 0.4, 0.0, sw.alpha)
		draw_arc(sw.pos, sw.radius, 0.0, TAU, 64, col, 3.0)
		draw_circle(sw.pos, 5.0, Color(1.0, 0.8, 0.2, sw.alpha))

	# Balls
	for ball in _balls:
		draw_circle(ball.pos, BALL_R, ball.color)
		draw_arc(ball.pos, BALL_R, 0.0, TAU, 32, Color.BLACK, 2.0)

	# UI
	draw_string(font, Vector2(8, 24), "Explosion Force", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
	draw_string(font, Vector2(8, 46), "Click to explode  R: reset", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.8, 0.8, 0.8))
	draw_string(font, Vector2(8, 470), "Balls: %d   Explosions: click anywhere" % _balls.size(), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.6, 0.6, 0.6))
