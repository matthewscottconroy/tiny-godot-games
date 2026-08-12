extends Node2D

const BALL_COUNT := 60
const BALL_R := 8.0
const WIDTH := 640.0
const HEIGHT := 480.0

var _qt: QTNode
var _balls: Array = []
var _brute_checks: int = 0
var _qt_checks: int = 0

func _ready() -> void:
	randomize()
	for i in range(BALL_COUNT):
		var angle := randf() * TAU
		var speed := randf_range(40.0, 120.0)
		_balls.append({
			"pos": Vector2(randf_range(BALL_R, WIDTH - BALL_R), randf_range(BALL_R, HEIGHT - BALL_R)),
			"vel": Vector2(cos(angle), sin(angle)) * speed,
			"color": Color(randf_range(0.4, 1.0), randf_range(0.4, 1.0), randf_range(0.4, 1.0)),
			"colliding": false,
			"radius": BALL_R,
		})
	_qt = QTNode.new(Rect2(0, 0, WIDTH, HEIGHT))

func _process(delta: float) -> void:
	# Move balls and bounce off edges
	for ball in _balls:
		ball.pos += ball.vel * delta
		if ball.pos.x - BALL_R < 0:
			ball.pos.x = BALL_R
			ball.vel.x = abs(ball.vel.x)
		elif ball.pos.x + BALL_R > WIDTH:
			ball.pos.x = WIDTH - BALL_R
			ball.vel.x = -abs(ball.vel.x)
		if ball.pos.y - BALL_R < 0:
			ball.pos.y = BALL_R
			ball.vel.y = abs(ball.vel.y)
		elif ball.pos.y + BALL_R > HEIGHT:
			ball.pos.y = HEIGHT - BALL_R
			ball.vel.y = -abs(ball.vel.y)
		ball.colliding = false

	# Rebuild quadtree
	_qt.clear()
	for ball in _balls:
		_qt.insert(ball)

	# Collision detection via quadtree
	_qt_checks = 0
	_brute_checks = BALL_COUNT * (BALL_COUNT - 1) / 2

	for ball in _balls:
		var query_rect := Rect2(
			ball.pos - Vector2(BALL_R * 2, BALL_R * 2),
			Vector2(BALL_R * 4, BALL_R * 4)
		)
		var nearby := _qt.query(query_rect)
		for other in nearby:
			if other == ball:
				continue
			_qt_checks += 1
			var dist: float = ball.pos.distance_to(other.pos)
			if dist < BALL_R * 2.0:
				ball.colliding = true
				other.colliding = true

	# Each pair is counted from both sides, normalize
	_qt_checks = _qt_checks / 2

	queue_redraw()

func _draw() -> void:
	# Draw quadtree cell boundaries
	var rects := _qt.get_all_rects()
	var line_col := Color(1.0, 1.0, 1.0, 0.18)
	for rect in rects:
		draw_rect(rect, line_col, false, 1.0)

	# Draw balls
	for ball in _balls:
		var col: Color = ball.color
		if ball.colliding:
			col = col.lightened(0.5)
		draw_circle(ball.pos, BALL_R, col)
		draw_arc(ball.pos, BALL_R, 0, TAU, 12, Color(1, 1, 1, 0.3), 1.0)

	# Stats panel background
	draw_rect(Rect2(4, 4, 260, 90), Color(0, 0, 0, 0.65))

	# Stats text
	var saved_pct := 0.0
	if _brute_checks > 0:
		saved_pct = float(_brute_checks - _qt_checks) / float(_brute_checks) * 100.0
	saved_pct = clampf(saved_pct, 0.0, 100.0)

	draw_string(ThemeDB.fallback_font, Vector2(10, 20), "Quadtree Spatial Partitioning", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1))
	draw_string(ThemeDB.fallback_font, Vector2(10, 38), "Balls: %d" % BALL_COUNT, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.9, 0.9, 0.9))
	draw_string(ThemeDB.fallback_font, Vector2(10, 54), "Brute force checks: %d" % _brute_checks, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.5, 0.5))
	draw_string(ThemeDB.fallback_font, Vector2(10, 70), "Quadtree checks: %d" % _qt_checks, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.5, 1.0, 0.5))
	draw_string(ThemeDB.fallback_font, Vector2(10, 86), "Saved: %.1f%%" % saved_pct, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.9, 0.3))

	var hint := "Balls bounce and collide — quadtree reduces collision checks each frame"
	draw_string(ThemeDB.fallback_font, Vector2(4, 475), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.6, 0.6, 0.6))
