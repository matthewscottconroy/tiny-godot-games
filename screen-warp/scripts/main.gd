extends Node2D

var _time: float = 0.0

# Ball state: [position, velocity, color, radius]
var _balls: Array = []

func _ready() -> void:
	# Initialize bouncing balls
	_balls = [
		[Vector2(160, 120), Vector2(95, 67), Color(1.0, 0.3, 0.3), 22.0],
		[Vector2(480, 200), Vector2(-80, 90), Color(0.3, 0.7, 1.0), 18.0],
		[Vector2(320, 300), Vector2(110, -75), Color(0.4, 1.0, 0.5), 26.0],
		[Vector2(100, 350), Vector2(70, -100), Color(1.0, 0.85, 0.2), 16.0],
		[Vector2(540, 380), Vector2(-105, -60), Color(0.9, 0.4, 1.0), 20.0],
	]

func _process(delta: float) -> void:
	_time += delta
	for ball in _balls:
		ball[0] += ball[1] * delta
		# Bounce off walls
		if ball[0].x - ball[3] < 0.0:
			ball[0].x = ball[3]
			ball[1].x = abs(ball[1].x)
		elif ball[0].x + ball[3] > 640.0:
			ball[0].x = 640.0 - ball[3]
			ball[1].x = -abs(ball[1].x)
		if ball[0].y - ball[3] < 0.0:
			ball[0].y = ball[3]
			ball[1].y = abs(ball[1].y)
		elif ball[0].y + ball[3] > 480.0:
			ball[0].y = 480.0 - ball[3]
			ball[1].y = -abs(ball[1].y)
	queue_redraw()

func _draw() -> void:
	# Checkerboard background
	var tile := 40
	for row in range(480 / tile + 1):
		for col in range(640 / tile + 1):
			var is_light := (row + col) % 2 == 0
			var col_color := Color(0.22, 0.22, 0.28) if is_light else Color(0.14, 0.14, 0.2)
			draw_rect(Rect2(col * tile, row * tile, tile, tile), col_color)

	# Grid lines for warp visibility
	for x in range(0, 641, 80):
		draw_line(Vector2(x, 0), Vector2(x, 480), Color(0.35, 0.35, 0.45, 0.5), 1.0)
	for y in range(0, 481, 60):
		draw_line(Vector2(0, y), Vector2(640, y), Color(0.35, 0.35, 0.45, 0.5), 1.0)

	# Animated ring decorations
	for i in range(3):
		var cx := 160.0 + i * 160.0
		var cy := 240.0
		var r := 40.0 + sin(_time * 0.8 + i * 1.2) * 8.0
		draw_arc(Vector2(cx, cy), r, 0.0, TAU, 32, Color(0.5, 0.5, 0.8, 0.4), 2.0)

	# Bouncing balls
	for ball in _balls:
		var pos: Vector2 = ball[0]
		var color: Color = ball[2]
		var radius: float = ball[3]
		draw_circle(pos, radius + 2.0, color.darkened(0.4))
		draw_circle(pos, radius, color)
		# Highlight
		draw_circle(pos + Vector2(-radius * 0.3, -radius * 0.3), radius * 0.25, Color(1, 1, 1, 0.5))

	# Title
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(0, 0, 640, 26), Color(0, 0, 0, 0.5))
	draw_string(font, Vector2(8, 18), "Screen Warp — World View (inside SubViewport)",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 0.9, 0.5))
