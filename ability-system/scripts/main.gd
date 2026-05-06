extends Node2D

const MANA_REGEN := 8.0
const MAX_MANA := 100.0

var _mana: float = 100.0
var _log: Array[String] = []

var _abilities: Array = [
	{"name": "Fireball",  "key": KEY_Q, "cooldown": 2.0, "cost": 20, "color": Color.TOMATO,           "timer": 0.0, "effect_timer": 0.0},
	{"name": "Shield",    "key": KEY_W, "cooldown": 5.0, "cost": 35, "color": Color.CORNFLOWER_BLUE,   "timer": 0.0, "effect_timer": 0.0},
	{"name": "Dash",      "key": KEY_E, "cooldown": 3.0, "cost": 15, "color": Color.MEDIUM_SEA_GREEN,  "timer": 0.0, "effect_timer": 0.0},
	{"name": "Heal",      "key": KEY_R, "cooldown": 8.0, "cost": 40, "color": Color.GOLD,              "timer": 0.0, "effect_timer": 0.0},
]

const PLAYER_POS := Vector2(320, 210)
const PLAYER_RADIUS := 28.0


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var ke := event as InputEventKey
		if ke.pressed and not ke.echo:
			for i in _abilities.size():
				if ke.keycode == _abilities[i]["key"]:
					_try_use_ability(i)
					break


func _try_use_ability(i: int) -> void:
	var ability: Dictionary = _abilities[i]
	if ability["timer"] > 0.0:
		_add_log("%s is on cooldown!" % ability["name"])
		return
	if _mana < ability["cost"]:
		_add_log("Not enough mana for %s!" % ability["name"])
		return
	_mana -= float(ability["cost"])
	ability["timer"] = ability["cooldown"]
	ability["effect_timer"] = 0.6
	_add_log("%s activated!" % ability["name"])


func _add_log(msg: String) -> void:
	_log.append(msg)
	if _log.size() > 5:
		_log.pop_front()


func _process(delta: float) -> void:
	_mana = minf(MAX_MANA, _mana + MANA_REGEN * delta)
	for ability in _abilities:
		ability["timer"] = maxf(0.0, ability["timer"] - delta)
		ability["effect_timer"] = maxf(0.0, ability["effect_timer"] - delta)
	queue_redraw()


func _draw() -> void:
	# Background
	draw_rect(Rect2(0, 0, 640, 480), Color(0.05, 0.05, 0.12))

	# Title
	draw_string(ThemeDB.fallback_font, Vector2(10, 24), "Ability System",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.9, 0.9, 1.0))
	draw_string(ThemeDB.fallback_font, Vector2(10, 46), "Q / W / E / R to use abilities",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.6, 0.6, 0.8))

	# Mana bar at top right
	var mb_x := 320.0
	var mb_y := 10.0
	var mb_w := 310.0
	var mb_h := 18.0
	draw_rect(Rect2(mb_x, mb_y, mb_w, mb_h), Color(0.1, 0.1, 0.25))
	var mana_frac := _mana / MAX_MANA
	draw_rect(Rect2(mb_x, mb_y, mb_w * mana_frac, mb_h), Color(0.2, 0.4, 1.0))
	draw_rect(Rect2(mb_x, mb_y, mb_w, mb_h), Color(0.4, 0.5, 0.9), false, 1.5)
	draw_string(ThemeDB.fallback_font, Vector2(mb_x + 4, mb_y + 13),
		"Mana: %d / %d" % [int(_mana), int(MAX_MANA)],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.8, 0.8, 1.0))

	# Ability effect rings around player
	for ability in _abilities:
		if ability["effect_timer"] > 0.0:
			var frac: float = ability["effect_timer"] / 0.6
			var ring_radius := PLAYER_RADIUS + 10.0 + (1.0 - frac) * 50.0
			draw_arc(PLAYER_POS, ring_radius, 0, TAU, 48,
				Color(ability["color"].r, ability["color"].g, ability["color"].b, frac),
				3.0 * frac)

	# Player circle
	draw_circle(PLAYER_POS, PLAYER_RADIUS, Color(0.3, 0.6, 0.9))
	draw_arc(PLAYER_POS, PLAYER_RADIUS, 0, TAU, 32, Color(0.6, 0.9, 1.0), 2.0)

	# Ability panel at bottom
	var panel_y := 320.0
	var box_w := 130.0
	var box_h := 120.0
	var panel_x := 30.0
	var gap := 20.0
	var key_labels := ["Q", "W", "E", "R"]

	for i in _abilities.size():
		var ability: Dictionary = _abilities[i]
		var bx := panel_x + i * (box_w + gap)
		var by := panel_y

		# Box background
		var ready := ability["timer"] <= 0.0
		var bg_color := Color(0.12, 0.12, 0.2) if not ready else Color(0.15, 0.18, 0.28)
		draw_rect(Rect2(bx, by, box_w, box_h), bg_color)
		draw_rect(Rect2(bx, by, box_w, box_h), ability["color"] if ready else Color(0.3, 0.3, 0.4), false, 2.0)

		# Ability color swatch
		draw_rect(Rect2(bx + 6, by + 6, 20, 20), ability["color"])

		# Key label
		draw_string(ThemeDB.fallback_font, Vector2(bx + 32, by + 20),
			"[%s]" % key_labels[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 16,
			Color(1, 1, 1) if ready else Color(0.5, 0.5, 0.5))

		# Ability name
		draw_string(ThemeDB.fallback_font, Vector2(bx + 6, by + 44),
			ability["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 15,
			Color(0.9, 0.9, 0.9) if ready else Color(0.45, 0.45, 0.45))

		# Mana cost
		draw_string(ThemeDB.fallback_font, Vector2(bx + 6, by + 62),
			"Cost: %d" % ability["cost"], HORIZONTAL_ALIGNMENT_LEFT, -1, 13,
			Color(0.4, 0.6, 1.0))

		# Cooldown arc
		var center := Vector2(bx + box_w / 2, by + 92)
		draw_arc(center, 18, -PI / 2, -PI / 2 + TAU, 32, Color(0.2, 0.2, 0.3), 14.0)
		if ability["timer"] > 0.0:
			var sweep := TAU * (ability["timer"] / ability["cooldown"])
			draw_arc(center, 18, -PI / 2, -PI / 2 + sweep, 32, Color(0.8, 0.2, 0.2), 14.0)
			draw_string(ThemeDB.fallback_font, center + Vector2(-10, 5),
				"%.1f" % ability["timer"], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 0.5, 0.5))
		else:
			draw_string(ThemeDB.fallback_font, center + Vector2(-8, 5),
				"RDY", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.3, 1.0, 0.4))

	# Log messages
	for i in _log.size():
		var alpha := 0.4 + 0.6 * (float(i + 1) / float(_log.size()))
		draw_string(ThemeDB.fallback_font, Vector2(10, 280 - (_log.size() - 1 - i) * 22),
			_log[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.9, 0.9, 0.6, alpha))
