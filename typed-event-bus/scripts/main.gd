extends Node2D

const ENEMY_COUNT := 8

var _bus: EventBus

var _enemies: Array = []
var _score: int = 0
var _xp: int = 0
var _level: int = 1
var _xp_to_next: int = 100

var _score_log: Array = []
var _audio_log: Array = []
var _ui_log: Array = []

const ENEMY_COLORS: Array = [
	Color(1.0, 0.27, 0.0),
	Color(0.25, 0.41, 1.0),
	Color(0.56, 0.93, 0.56),
	Color(0.93, 0.51, 0.93),
	Color(1.0, 0.84, 0.0),
	Color(0.8, 0.52, 0.25),
	Color(0.15, 0.85, 0.75),
	Color(0.95, 0.45, 0.65),
]

const ENEMY_XP: Array = [10, 15, 8, 20, 12, 18, 25, 10]
const ENEMY_NAMES: Array = ["Goblin", "Troll", "Bat", "Ogre", "Wolf", "Orc", "Mage", "Sprite"]

# Positions spread across the main area (above the log panels)
const ENEMY_POSITIONS: Array = [
	Vector2(80, 160),
	Vector2(200, 120),
	Vector2(330, 155),
	Vector2(460, 130),
	Vector2(560, 175),
	Vector2(130, 260),
	Vector2(290, 240),
	Vector2(430, 255),
]


func _ready() -> void:
	_bus = EventBus.new()

	# Subscribe systems
	_bus.on("enemy_died", _score_system)
	_bus.on("enemy_died", _xp_system)
	_bus.on("enemy_died", _ui_system)
	_bus.on("enemy_died", _audio_system)
	_bus.on("level_up", _level_system)
	_bus.on("level_up", _ui_system)
	_bus.on("level_up", _audio_system)
	_bus.on("score_changed", _ui_system)

	# Spawn enemies
	_enemies = []
	for i in range(ENEMY_COUNT):
		_enemies.append({
			"id": i,
			"pos": ENEMY_POSITIONS[i],
			"radius": 24.0,
			"xp": ENEMY_XP[i],
			"color": ENEMY_COLORS[i],
			"name": ENEMY_NAMES[i],
			"alive": true,
		})


# ---------------------------------------------------------------------------
# Event handlers — each system is independent
# ---------------------------------------------------------------------------
func _score_system(data: Dictionary) -> void:
	var xp_val: int = data.get("xp", 10)
	var pts := xp_val * 10
	_score += pts
	_push_score_log("+%d pts (total: %d)" % [pts, _score])
	_bus.emit("score_changed", {"score": _score, "delta": pts})


func _xp_system(data: Dictionary) -> void:
	var xp_val: int = data.get("xp", 10)
	_xp += xp_val
	while _xp >= _xp_to_next:
		_xp -= _xp_to_next
		_level += 1
		_xp_to_next = int(_xp_to_next * 1.5)
		_bus.emit("level_up", {"level": _level})


func _level_system(data: Dictionary) -> void:
	var lvl: int = data.get("level", 1)
	_push_ui_log("LEVEL UP! Now level %d" % lvl)


func _ui_system(data: Dictionary) -> void:
	if data.has("delta"):
		_push_ui_log("Score +%d" % data.get("delta", 0))
	elif data.has("level"):
		_push_ui_log("UI: Level %d achieved" % data.get("level", 1))
	elif data.has("xp"):
		_push_ui_log("UI: Enemy %d killed" % data.get("id", -1))


func _audio_system(data: Dictionary) -> void:
	if data.has("level"):
		_push_audio_log("SFX: level-up fanfare")
	elif data.has("xp"):
		_push_audio_log("SFX: death sound")


# ---------------------------------------------------------------------------
# Log helpers
# ---------------------------------------------------------------------------
func _push_score_log(msg: String) -> void:
	_score_log.append(msg)
	if _score_log.size() > 4:
		_score_log.pop_front()


func _push_ui_log(msg: String) -> void:
	_ui_log.append(msg)
	if _ui_log.size() > 4:
		_ui_log.pop_front()


func _push_audio_log(msg: String) -> void:
	_audio_log.append(msg)
	if _audio_log.size() > 4:
		_audio_log.pop_front()


# ---------------------------------------------------------------------------
# Input
# ---------------------------------------------------------------------------
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			for enemy in _enemies:
				if enemy["alive"] and mb.position.distance_to(enemy["pos"]) <= enemy["radius"]:
					enemy["alive"] = false
					_bus.emit("enemy_died", {
						"id": enemy["id"],
						"pos": enemy["pos"],
						"xp": enemy["xp"],
					})
					break


func _process(_delta: float) -> void:
	queue_redraw()


# ---------------------------------------------------------------------------
# Drawing
# ---------------------------------------------------------------------------
func _draw() -> void:
	# Background
	draw_rect(Rect2(0, 0, 640, 480), Color(0.07, 0.07, 0.12), true)

	# Title
	draw_string(ThemeDB.fallback_font, Vector2(16, 26), "Typed Event Bus",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color(0.9, 0.9, 1.0))
	draw_string(ThemeDB.fallback_font, Vector2(16, 46),
			"Click enemies to fire events  |  Systems react independently",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.5, 0.5, 0.6))

	# Score + XP + Level HUD
	draw_string(ThemeDB.fallback_font, Vector2(400, 26),
			"Score: %d" % _score, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1.0, 0.9, 0.3))
	draw_string(ThemeDB.fallback_font, Vector2(400, 48),
			"Level %d   XP: %d / %d" % [_level, _xp, _xp_to_next],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.7, 0.9, 0.7))

	# XP bar
	var xp_bar_w := 200.0
	var xp_fill := (float(_xp) / float(_xp_to_next)) * xp_bar_w
	draw_rect(Rect2(400, 56, xp_bar_w, 8), Color(0.2, 0.2, 0.3), true)
	draw_rect(Rect2(400, 56, xp_fill, 8), Color(0.3, 0.85, 0.3), true)
	draw_rect(Rect2(400, 56, xp_bar_w, 8), Color(0.5, 0.5, 0.6, 0.5), false, 1.0)

	# Enemies
	for enemy in _enemies:
		if enemy["alive"]:
			draw_circle(enemy["pos"], enemy["radius"], enemy["color"])
			draw_arc(enemy["pos"], enemy["radius"], 0.0, TAU, 32,
					Color(1.0, 1.0, 1.0, 0.3), 1.5)
			# XP label
			draw_string(ThemeDB.fallback_font,
					enemy["pos"] + Vector2(-12, 5),
					"+%d" % enemy["xp"],
					HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 0.5))
			draw_string(ThemeDB.fallback_font,
					enemy["pos"] + Vector2(-18, enemy["radius"] + 14),
					enemy["name"],
					HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.8, 0.8, 0.8))
		else:
			# Dead enemy — faded X
			draw_circle(enemy["pos"], enemy["radius"], Color(0.3, 0.3, 0.3, 0.4))
			var d := enemy["radius"] * 0.6
			var p := enemy["pos"]
			draw_line(p + Vector2(-d, -d), p + Vector2(d, d), Color(0.7, 0.2, 0.2, 0.6), 2.0)
			draw_line(p + Vector2(d, -d), p + Vector2(-d, d), Color(0.7, 0.2, 0.2, 0.6), 2.0)

	# Three subscriber log panels at the bottom
	_draw_log_panel(Vector2(8, 310), "Score System", _score_log, Color(1.0, 0.9, 0.3))
	_draw_log_panel(Vector2(222, 310), "UI System", _ui_log, Color(0.4, 0.75, 1.0))
	_draw_log_panel(Vector2(436, 310), "Audio System", _audio_log, Color(0.65, 0.9, 0.55))


func _draw_log_panel(top_left: Vector2, title: String, log_entries: Array, accent: Color) -> void:
	var panel_w := 200.0
	var panel_h := 155.0

	draw_rect(Rect2(top_left, Vector2(panel_w, panel_h)), Color(0.09, 0.09, 0.15, 0.95), true)
	draw_rect(Rect2(top_left, Vector2(panel_w, panel_h)), accent.darkened(0.3), false, 1.5)

	# Accent header bar
	draw_rect(Rect2(top_left, Vector2(panel_w, 22)), accent.darkened(0.4), true)

	draw_string(ThemeDB.fallback_font, top_left + Vector2(6, 15),
			title, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, accent)

	for i in range(log_entries.size()):
		draw_string(ThemeDB.fallback_font,
				top_left + Vector2(6, 36 + i * 28),
				log_entries[i],
				HORIZONTAL_ALIGNMENT_LEFT, int(panel_w) - 12, 11,
				Color(0.82, 0.82, 0.82))

	if log_entries.is_empty():
		draw_string(ThemeDB.fallback_font, top_left + Vector2(6, 50),
				"(no events yet)", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.4, 0.4, 0.45))
