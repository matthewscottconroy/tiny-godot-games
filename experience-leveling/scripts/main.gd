extends Node2D

# XP/level logic lives in the reusable LevelSystem (scripts/level_system.gd);
# this file handles enemies, input, and drawing.
var _leveling := LevelSystem.new()
var _stat_attack: int = 10
var _enemies: Array = []
var _level_up_flash: float = 0.0
var _xp_history: Array[String] = []


func _ready() -> void:
	# Stat rewards are game-specific — apply them when a level is gained.
	_leveling.leveled_up.connect(func(_lvl: int) -> void:
		_stat_attack += 5
		_level_up_flash = 1.5)
	_init_enemies()


func _init_enemies() -> void:
	var enemy_data := [
		{"pos": Vector2(120, 120), "radius": 22, "xp_value": 15, "color": Color(0.9, 0.2, 0.2)},
		{"pos": Vector2(520, 120), "radius": 18, "xp_value": 10, "color": Color(0.2, 0.8, 0.3)},
		{"pos": Vector2(320, 100), "radius": 26, "xp_value": 20, "color": Color(0.8, 0.4, 0.1)},
		{"pos": Vector2(160, 280), "radius": 20, "xp_value": 12, "color": Color(0.6, 0.1, 0.8)},
		{"pos": Vector2(480, 280), "radius": 24, "xp_value": 18, "color": Color(0.1, 0.5, 0.9)},
		{"pos": Vector2(320, 260), "radius": 16, "xp_value": 8,  "color": Color(0.9, 0.9, 0.1)},
		{"pos": Vector2(80,  200), "radius": 20, "xp_value": 14, "color": Color(0.9, 0.3, 0.6)},
		{"pos": Vector2(560, 200), "radius": 22, "xp_value": 16, "color": Color(0.2, 0.9, 0.8)},
	]
	for d in enemy_data:
		var e := {
			"pos": d["pos"],
			"radius": d["radius"],
			"xp_value": d["xp_value"],
			"color": d["color"],
			"alive": true,
			"_respawn_timer": 0.0,
		}
		_enemies.append(e)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			var click_pos := mb.position
			for enemy in _enemies:
				if not enemy["alive"]:
					continue
				var dist: float = click_pos.distance_to(enemy["pos"])
				if dist <= enemy["radius"]:
					enemy["alive"] = false
					enemy["_respawn_timer"] = 2.0
					_gain_xp(enemy["xp_value"])
					break


func _gain_xp(amount: int) -> void:
	_xp_history.append("+%d XP" % amount)
	if _xp_history.size() > 4:
		_xp_history.pop_front()
	_leveling.gain(amount)   # handles thresholds, overflow, and level-up signals


func _process(delta: float) -> void:
	for enemy in _enemies:
		if not enemy["alive"]:
			enemy["_respawn_timer"] -= delta
			if enemy["_respawn_timer"] <= 0.0:
				enemy["alive"] = true
	_level_up_flash = maxf(0.0, _level_up_flash - delta)
	queue_redraw()


func _draw() -> void:
	# Background
	draw_rect(Rect2(0, 0, 640, 480), Color(0.05, 0.05, 0.12))

	# Title
	draw_string(ThemeDB.fallback_font, Vector2(10, 24), "Experience & Leveling",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.9, 0.9, 1.0))
	draw_string(ThemeDB.fallback_font, Vector2(10, 46), "Click enemies to gain XP",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.6, 0.6, 0.8))

	# Draw enemies
	for enemy in _enemies:
		if enemy["alive"]:
			draw_circle(enemy["pos"], enemy["radius"], enemy["color"])
			draw_arc(enemy["pos"], enemy["radius"] + 2, 0, TAU, 32, Color(1, 1, 1, 0.3), 1.5)
			var label := str(enemy["xp_value"]) + "xp"
			draw_string(ThemeDB.fallback_font, enemy["pos"] + Vector2(-12, 5), label,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, 0.9))
		else:
			draw_circle(enemy["pos"], enemy["radius"], Color(0.25, 0.25, 0.25))
			var t_left := int(ceil(enemy["_respawn_timer"]))
			draw_string(ThemeDB.fallback_font, enemy["pos"] + Vector2(-6, 5), str(t_left),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.5, 0.5, 0.5))

	# XP bar area
	var bar_x := 30.0
	var bar_y := 420.0
	var bar_w := 580.0
	var bar_h := 22.0
	draw_rect(Rect2(bar_x, bar_y, bar_w, bar_h), Color(0.15, 0.15, 0.25))
	var fill_frac := 0.0
	if _leveling.xp_for_next > 0:
		fill_frac = clampf(float(_leveling.xp) / float(_leveling.xp_for_next), 0.0, 1.0)
	draw_rect(Rect2(bar_x, bar_y, bar_w * fill_frac, bar_h), Color(0.2, 0.7, 1.0))
	draw_rect(Rect2(bar_x, bar_y, bar_w, bar_h), Color(0.4, 0.4, 0.6), false, 1.5)
	var xp_label := "XP: %d / %d" % [_leveling.xp, _leveling.xp_for_next]
	draw_string(ThemeDB.fallback_font, Vector2(bar_x + bar_w / 2 - 40, bar_y + 16), xp_label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1))

	# Level display
	draw_string(ThemeDB.fallback_font, Vector2(bar_x, bar_y - 30), "Level %d / %d" % [_leveling.level, _leveling.max_level],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1.0, 0.85, 0.2))

	# Stat display
	draw_string(ThemeDB.fallback_font, Vector2(bar_x + 260, bar_y - 30), "Attack: %d" % _stat_attack,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.9, 0.5, 0.3))

	# XP history
	for i in _xp_history.size():
		var alpha := 0.4 + 0.6 * (float(i + 1) / float(_xp_history.size()))
		draw_string(ThemeDB.fallback_font, Vector2(10, 380 - (_xp_history.size() - 1 - i) * 20),
			_xp_history[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.4, 1.0, 0.4, alpha))

	# Level-up flash
	if _level_up_flash > 0.0:
		var alpha := _level_up_flash / 1.5
		draw_rect(Rect2(0, 0, 640, 480), Color(1.0, 0.85, 0.0, alpha * 0.25))
		draw_string(ThemeDB.fallback_font, Vector2(220, 250), "LEVEL UP!",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 48, Color(1.0, 0.95, 0.2, alpha))
