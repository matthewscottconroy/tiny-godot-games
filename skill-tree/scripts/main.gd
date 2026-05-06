extends Node2D

const NODE_RADIUS := 28.0
const HOVER_RADIUS := 32.0

var _skill_points: int = 3
var _hovered: int = -1
var _pulse_time: float = 0.0

var _skills: Array = []

func _ready() -> void:
	_build_skills()

func _build_skills() -> void:
	_skills = [
		# id  name              desc                                   pos            prereqs  unlocked cost
		{"id": 0, "name": "Strength I",  "desc": "Increase physical attack by 10%.",     "pos": Vector2(320, 400), "prereqs": [],    "unlocked": false, "cost": 1},
		{"id": 1, "name": "Strength II", "desc": "Attack power +20%. Unlock combos.",    "pos": Vector2(220, 310), "prereqs": [0],   "unlocked": false, "cost": 1},
		{"id": 2, "name": "Str. III",    "desc": "Max physical damage multiplied by 2.", "pos": Vector2(220, 220), "prereqs": [1],   "unlocked": false, "cost": 1},
		{"id": 3, "name": "Speed I",     "desc": "Move and attack 15% faster.",          "pos": Vector2(420, 310), "prereqs": [0],   "unlocked": false, "cost": 1},
		{"id": 4, "name": "Speed II",    "desc": "Dodge chance +25%. Sprint available.", "pos": Vector2(420, 220), "prereqs": [3],   "unlocked": false, "cost": 1},
		{"id": 5, "name": "Magic I",     "desc": "Unlock basic spellcasting.",           "pos": Vector2(120, 310), "prereqs": [0],   "unlocked": false, "cost": 1},
		{"id": 6, "name": "Magic II",    "desc": "Spell damage +30%. Mana pool +50.",    "pos": Vector2(120, 220), "prereqs": [5],   "unlocked": false, "cost": 1},
		{"id": 7, "name": "Combo",       "desc": "Combine Strength+Speed for burst.",    "pos": Vector2(320, 220), "prereqs": [1, 3],"unlocked": false, "cost": 2},
		{"id": 8, "name": "Ultimate",    "desc": "Unleash devastating ultimate attack.",  "pos": Vector2(320, 130), "prereqs": [7],   "unlocked": false, "cost": 2},
		{"id": 9, "name": "Passive",     "desc": "Passively regenerate 1 HP/sec.",       "pos": Vector2(520, 310), "prereqs": [0],   "unlocked": false, "cost": 1},
	]

func _can_unlock(skill_idx: int) -> bool:
	if skill_idx < 0 or skill_idx >= _skills.size():
		return false
	var skill = _skills[skill_idx]
	if skill.unlocked:
		return false
	if _skill_points < skill.cost:
		return false
	for prereq_id in skill.prereqs:
		if not _skills[prereq_id].unlocked:
			return false
	return true

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var mouse_pos := get_viewport().get_mouse_position()
		_hovered = -1
		var closest_dist := HOVER_RADIUS
		for i in range(_skills.size()):
			var dist := mouse_pos.distance_to(_skills[i].pos)
			if dist < closest_dist:
				closest_dist = dist
				_hovered = i
		queue_redraw()

	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _hovered >= 0 and _can_unlock(_hovered):
			_skills[_hovered].unlocked = true
			_skill_points -= _skills[_hovered].cost
			queue_redraw()

	elif event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_R:
				for skill in _skills:
					skill.unlocked = false
				_skill_points = 3
				queue_redraw()
			KEY_EQUAL, KEY_KP_ADD, KEY_PLUS:
				_skill_points += 1
				queue_redraw()

func _process(delta: float) -> void:
	_pulse_time += delta * 3.0
	queue_redraw()

func _draw() -> void:
	# Dark background
	draw_rect(Rect2(0, 0, 640, 480), Color(0.06, 0.06, 0.10))

	# Draw connection lines first
	for skill in _skills:
		for prereq_id in skill.prereqs:
			var prereq = _skills[prereq_id]
			var both_unlocked := skill.unlocked and prereq.unlocked
			var line_color := Color(0.75, 0.6, 0.1, 0.9) if both_unlocked else Color(0.3, 0.3, 0.4, 0.7)
			var line_width := 2.5 if both_unlocked else 1.5
			draw_line(prereq.pos, skill.pos, line_color, line_width)

	# Draw skill nodes
	for i in range(_skills.size()):
		var skill = _skills[i]
		var is_hovered := (i == _hovered)
		var radius := HOVER_RADIUS if is_hovered else NODE_RADIUS
		var can_buy := _can_unlock(i)

		# Node fill color
		var fill_color: Color
		if skill.unlocked:
			fill_color = _get_skill_color(i)
		elif can_buy:
			# Pulsing available color
			var pulse := (sin(_pulse_time) + 1.0) * 0.5
			fill_color = Color(0.15, 0.15, 0.25 + pulse * 0.1)
		else:
			fill_color = Color(0.12, 0.12, 0.18)

		draw_circle(skill.pos, radius, fill_color)

		# Outline
		var outline_color: Color
		if skill.unlocked:
			outline_color = Color(1.0, 0.85, 0.2)
		elif can_buy:
			var pulse := (sin(_pulse_time) + 1.0) * 0.5
			outline_color = Color(0.4, 0.6 + pulse * 0.4, 1.0)
		else:
			outline_color = Color(0.25, 0.25, 0.35)

		var outline_w := 3.0 if skill.unlocked else (2.5 if can_buy else 1.5)
		draw_arc(skill.pos, radius, 0, TAU, 32, outline_color, outline_w)

		# Skill name (small, centered)
		var short_name := skill.name
		if short_name.length() > 10:
			short_name = short_name.substr(0, 10)
		var name_offset := Vector2(-short_name.length() * 3.3, 4)
		var text_color := Color(1, 1, 1, 0.95) if skill.unlocked else Color(0.65, 0.65, 0.75)
		draw_string(ThemeDB.fallback_font, skill.pos + name_offset, short_name,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 10, text_color)

		# Cost badge (top-right of node)
		if not skill.unlocked:
			var badge_pos := skill.pos + Vector2(radius - 8, -radius + 8)
			var badge_color := Color(0.9, 0.6, 0.1) if can_buy else Color(0.4, 0.4, 0.5)
			draw_circle(badge_pos, 9, badge_color)
			draw_string(ThemeDB.fallback_font, badge_pos + Vector2(-3, 4),
				str(skill.cost), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0, 0, 0))

	# Tooltip for hovered skill
	if _hovered >= 0:
		_draw_tooltip(_hovered)

	# Skill points counter
	draw_rect(Rect2(8, 8, 160, 28), Color(0.05, 0.05, 0.12, 0.9))
	draw_rect(Rect2(8, 8, 160, 28), Color(0.4, 0.4, 0.6), false, 1)
	draw_string(ThemeDB.fallback_font, Vector2(14, 26), "Skill Points: %d" % _skill_points,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1.0, 0.85, 0.3))

	# Hints
	draw_string(ThemeDB.fallback_font, Vector2(8, 472),
		"Click to unlock   R: reset   +: add point",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.5, 0.5, 0.7))

func _draw_tooltip(skill_idx: int) -> void:
	var skill = _skills[skill_idx]
	var pos := skill.pos

	# Tooltip placement: shift left if near right edge, up if near bottom
	var tip_x := pos.x + 36
	var tip_y := pos.y - 20
	var tip_w := 190
	var tip_h := 95
	if tip_x + tip_w > 635:
		tip_x = pos.x - tip_w - 36
	if tip_y + tip_h > 475:
		tip_y = pos.y - tip_h - 10

	draw_rect(Rect2(tip_x, tip_y, tip_w, tip_h), Color(0.04, 0.04, 0.1, 0.97))
	draw_rect(Rect2(tip_x, tip_y, tip_w, tip_h), Color(0.5, 0.5, 0.75), false, 1)

	draw_string(ThemeDB.fallback_font, Vector2(tip_x + 6, tip_y + 16), skill.name,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.85, 0.3))

	# Wrap description at ~28 chars
	var desc_lines := _wrap_text(skill.desc, 28)
	for i in range(min(desc_lines.size(), 2)):
		draw_string(ThemeDB.fallback_font, Vector2(tip_x + 6, tip_y + 32 + i * 14), desc_lines[i],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.8, 0.8, 0.9))

	# Cost
	var cost_color := Color(0.9, 0.7, 0.1) if _skill_points >= skill.cost else Color(0.8, 0.3, 0.3)
	draw_string(ThemeDB.fallback_font, Vector2(tip_x + 6, tip_y + 64),
		"Cost: %d point%s" % [skill.cost, "s" if skill.cost > 1 else ""],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 10, cost_color)

	# Prereq status
	var prereq_text := "Prereqs: "
	if skill.prereqs.is_empty():
		prereq_text += "none"
	else:
		var prereq_names: Array = []
		for pid in skill.prereqs:
			var pname := _skills[pid].name
			var met := _skills[pid].unlocked
			prereq_names.append(pname + (" [OK]" if met else " [X]"))
		prereq_text += ", ".join(prereq_names)
	if prereq_text.length() > 30:
		prereq_text = prereq_text.substr(0, 30) + "..."
	draw_string(ThemeDB.fallback_font, Vector2(tip_x + 6, tip_y + 80), prereq_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.6, 0.8, 0.6))

func _get_skill_color(skill_idx: int) -> Color:
	match skill_idx:
		0: return Color(0.7, 0.2, 0.2)
		1: return Color(0.8, 0.25, 0.2)
		2: return Color(0.9, 0.3, 0.2)
		3: return Color(0.2, 0.6, 0.8)
		4: return Color(0.2, 0.75, 0.9)
		5: return Color(0.5, 0.2, 0.8)
		6: return Color(0.6, 0.25, 0.9)
		7: return Color(0.8, 0.5, 0.1)
		8: return Color(0.95, 0.7, 0.05)
		9: return Color(0.2, 0.7, 0.4)
		_: return Color(0.4, 0.4, 0.6)

func _wrap_text(text: String, max_chars: int) -> Array:
	var words := text.split(" ")
	var lines: Array = []
	var current := ""
	for word in words:
		if current.length() + word.length() + 1 > max_chars:
			lines.append(current.strip_edges())
			current = word + " "
		else:
			current += word + " "
	if current.strip_edges() != "":
		lines.append(current.strip_edges())
	return lines
