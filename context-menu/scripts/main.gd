extends Node2D

const MENU_W := 180.0
const ITEM_H := 34.0

var _menu_items: Array = []
var _menu_visible: bool = false
var _menu_pos: Vector2 = Vector2.ZERO
var _highlighted_item: int = -1
var _bg_color: Color = Color(0.12, 0.12, 0.18)
var _shapes: Array = []
var _log: Array = []

# Color palette for spawned shapes
const SHAPE_COLORS: Array = [
	Color(1.0, 0.27, 0.0),
	Color(0.25, 0.41, 1.0),
	Color(0.56, 0.93, 0.56),
	Color(0.93, 0.51, 0.93),
	Color(1.0, 0.84, 0.0),
]
var _color_idx: int = 0

# Last right-click position for spawning shapes there
var _last_right_click: Vector2 = Vector2(320, 240)


func _ready() -> void:
	_menu_items = [
		{"label": "Spawn Circle",  "color": Color(0.25, 0.55, 1.0),  "action": _action_spawn_circle},
		{"label": "Spawn Square",  "color": Color(0.56, 0.93, 0.56), "action": _action_spawn_square},
		{"label": "Clear All",     "color": Color(1.0, 0.27, 0.0),   "action": _action_clear_all},
		{"label": "Change BG",     "color": Color(0.93, 0.51, 0.93), "action": _action_change_bg},
		{"label": "Show Info",     "color": Color(1.0, 0.84, 0.0),   "action": _action_show_info},
	]


func _action_spawn_circle() -> void:
	var c := SHAPE_COLORS[_color_idx % SHAPE_COLORS.size()]
	_color_idx += 1
	_shapes.append({"type": "circle", "pos": _last_right_click, "color": c})
	_push_log("Spawned circle at (%d,%d)" % [int(_last_right_click.x), int(_last_right_click.y)])


func _action_spawn_square() -> void:
	var c := SHAPE_COLORS[_color_idx % SHAPE_COLORS.size()]
	_color_idx += 1
	_shapes.append({"type": "square", "pos": _last_right_click, "color": c})
	_push_log("Spawned square at (%d,%d)" % [int(_last_right_click.x), int(_last_right_click.y)])


func _action_clear_all() -> void:
	_shapes.clear()
	_push_log("Cleared all shapes")


func _action_change_bg() -> void:
	var options: Array = [
		Color(0.12, 0.12, 0.18),
		Color(0.05, 0.15, 0.10),
		Color(0.15, 0.08, 0.08),
		Color(0.10, 0.08, 0.18),
	]
	var current_idx := 0
	for i in range(options.size()):
		if _bg_color.is_equal_approx(options[i]):
			current_idx = i
			break
	_bg_color = options[(current_idx + 1) % options.size()]
	_push_log("Background color changed")


func _action_show_info() -> void:
	_push_log("Shapes: %d | Right-click for menu" % _shapes.size())


func _push_log(msg: String) -> void:
	_log.append(msg)
	if _log.size() > 5:
		_log.pop_front()


func _clamp_menu_pos(click_pos: Vector2) -> Vector2:
	var pos := click_pos
	var menu_h := _menu_items.size() * ITEM_H
	if pos.x + MENU_W > 636.0:
		pos.x = 636.0 - MENU_W
	if pos.y + menu_h > 476.0:
		pos.y = 476.0 - menu_h
	return pos


func _get_item_at_mouse(mouse_pos: Vector2) -> int:
	if not _menu_visible:
		return -1
	var menu_h := _menu_items.size() * ITEM_H
	var menu_rect := Rect2(_menu_pos, Vector2(MENU_W, menu_h))
	if not menu_rect.has_point(mouse_pos):
		return -1
	var rel_y := mouse_pos.y - _menu_pos.y
	return int(rel_y / ITEM_H)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			if mb.button_index == MOUSE_BUTTON_RIGHT:
				_last_right_click = mb.position
				_menu_pos = _clamp_menu_pos(mb.position)
				_menu_visible = true
				_highlighted_item = -1
				queue_redraw()

			elif mb.button_index == MOUSE_BUTTON_LEFT:
				if _menu_visible:
					var idx := _get_item_at_mouse(mb.position)
					if idx >= 0 and idx < _menu_items.size():
						_menu_items[idx]["action"].call()
					_menu_visible = false
					_highlighted_item = -1
					queue_redraw()

	elif event is InputEventMouseMotion:
		if _menu_visible:
			var new_hi := _get_item_at_mouse((event as InputEventMouseMotion).position)
			if new_hi != _highlighted_item:
				_highlighted_item = new_hi
				queue_redraw()

	elif event is InputEventKey:
		var ke := event as InputEventKey
		if ke.pressed and ke.keycode == KEY_ESCAPE:
			if _menu_visible:
				_menu_visible = false
				_highlighted_item = -1
				queue_redraw()


func _draw() -> void:
	# Background
	draw_rect(Rect2(0, 0, 640, 480), _bg_color, true)

	# Title + hints
	draw_string(ThemeDB.fallback_font, Vector2(16, 28), "Context Menu Demo",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.9, 0.9, 1.0))
	draw_string(ThemeDB.fallback_font, Vector2(16, 50), "Right-click for menu  |  Esc: close",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.55, 0.55, 0.65))

	# Spawned shapes
	for shape in _shapes:
		if shape["type"] == "circle":
			draw_circle(shape["pos"], 22.0, shape["color"])
			draw_arc(shape["pos"], 22.0, 0.0, TAU, 32, Color(1, 1, 1, 0.25), 1.5)
		else:
			var r := Rect2(shape["pos"] - Vector2(18, 18), Vector2(36, 36))
			draw_rect(r, shape["color"], true)
			draw_rect(r, Color(1, 1, 1, 0.25), false, 1.5)

	# Action log on right side
	draw_rect(Rect2(430, 65, 200, 110), Color(0.06, 0.06, 0.12, 0.9), true)
	draw_rect(Rect2(430, 65, 200, 110), Color(0.4, 0.4, 0.5, 0.6), false, 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(438, 83), "Action Log",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.7, 0.7, 0.9))
	for i in range(_log.size()):
		draw_string(ThemeDB.fallback_font, Vector2(438, 98 + i * 15),
				_log[i], HORIZONTAL_ALIGNMENT_LEFT, 190, 11, Color(0.75, 0.75, 0.75))

	# Context menu
	if _menu_visible:
		var menu_h := _menu_items.size() * ITEM_H

		# Shadow
		draw_rect(Rect2(_menu_pos + Vector2(4, 4), Vector2(MENU_W, menu_h)),
				Color(0.0, 0.0, 0.0, 0.4), true)

		# Menu background
		draw_rect(Rect2(_menu_pos, Vector2(MENU_W, menu_h)),
				Color(0.15, 0.15, 0.22, 0.97), true)
		draw_rect(Rect2(_menu_pos, Vector2(MENU_W, menu_h)),
				Color(0.6, 0.6, 0.75, 0.8), false, 1.2)

		for i in range(_menu_items.size()):
			var item = _menu_items[i]
			var row_y := _menu_pos.y + i * ITEM_H

			# Highlight
			if i == _highlighted_item:
				draw_rect(Rect2(_menu_pos.x + 1, row_y + 1, MENU_W - 2, ITEM_H - 2),
						Color(0.3, 0.35, 0.55, 0.7), true)

			# Color square icon
			draw_rect(Rect2(_menu_pos.x + 8, row_y + 9, 16, 16), item["color"], true)
			draw_rect(Rect2(_menu_pos.x + 8, row_y + 9, 16, 16),
					Color(1, 1, 1, 0.3), false, 1.0)

			# Label
			var text_color := Color(0.95, 0.95, 0.95) if i == _highlighted_item else Color(0.8, 0.8, 0.8)
			draw_string(ThemeDB.fallback_font, Vector2(_menu_pos.x + 32, row_y + ITEM_H * 0.62),
					item["label"], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, text_color)

			# Separator after item index 2 ("Clear All")
			if i == 2:
				draw_line(
					Vector2(_menu_pos.x + 4, row_y + ITEM_H),
					Vector2(_menu_pos.x + MENU_W - 4, row_y + ITEM_H),
					Color(0.5, 0.5, 0.6, 0.5), 1.0
				)
