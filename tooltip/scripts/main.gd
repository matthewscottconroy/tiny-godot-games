extends Node2D

const HOVER_DELAY := 0.4
const FADE_IN_TIME := 0.15
const FADE_OUT_TIME := 0.1

var _items: Array = []
var _hovered_idx: int = -1
var _hover_timer: float = 0.0
var _tooltip_alpha: float = 0.0
var _mouse_pos: Vector2 = Vector2.ZERO


func _ready() -> void:
	_items = [
		{
			"pos": Vector2(100, 150),
			"radius": 30,
			"color": Color(1.0, 0.27, 0.0),
			"title": "Fire Rune",
			"desc": "Deals 25 fire damage.\nBurns enemies for 3 seconds."
		},
		{
			"pos": Vector2(280, 120),
			"radius": 28,
			"color": Color(0.25, 0.41, 1.0),
			"title": "Ice Crystal",
			"desc": "Slows movement by 50%.\nLasts 5 seconds on impact."
		},
		{
			"pos": Vector2(480, 160),
			"radius": 32,
			"color": Color(0.56, 0.93, 0.56),
			"title": "Nature Seed",
			"desc": "Heals 15 HP over 10 seconds.\nStackable up to 3 times."
		},
		{
			"pos": Vector2(150, 320),
			"radius": 26,
			"color": Color(0.93, 0.51, 0.93),
			"title": "Arcane Gem",
			"desc": "Boosts spell power by 30%.\nExplodes on death dealing 40 damage."
		},
		{
			"pos": Vector2(360, 300),
			"radius": 34,
			"color": Color(1.0, 0.84, 0.0),
			"title": "Lightning Orb",
			"desc": "Chains to 3 nearby enemies.\nEach chain reduces damage by 25%."
		},
		{
			"pos": Vector2(540, 350),
			"radius": 28,
			"color": Color(0.8, 0.52, 0.25),
			"title": "Earth Stone",
			"desc": "Creates a shockwave on impact.\nStuns grounded enemies for 2 seconds."
		}
	]


func _process(delta: float) -> void:
	_mouse_pos = get_global_mouse_position()

	var new_hovered := -1
	for i in range(_items.size()):
		var item = _items[i]
		if _mouse_pos.distance_to(item["pos"]) <= item["radius"]:
			new_hovered = i
			break

	if new_hovered != _hovered_idx:
		_hovered_idx = new_hovered
		_hover_timer = 0.0
		_tooltip_alpha = 0.0
	elif _hovered_idx >= 0:
		_hover_timer += delta

	if _hover_timer >= HOVER_DELAY:
		_tooltip_alpha = min(1.0, _tooltip_alpha + delta / FADE_IN_TIME)
	else:
		_tooltip_alpha = max(0.0, _tooltip_alpha - delta / FADE_OUT_TIME)

	queue_redraw()


func _clamp_tooltip_rect(mouse_pos: Vector2, size: Vector2) -> Vector2:
	var preferred := mouse_pos + Vector2(14.0, 14.0)
	var bounds := Rect2(4.0, 4.0, 632.0, 472.0)
	preferred.x = clamp(preferred.x, bounds.position.x, bounds.position.x + bounds.size.x - size.x)
	preferred.y = clamp(preferred.y, bounds.position.y, bounds.position.y + bounds.size.y - size.y)
	return preferred


func _draw() -> void:
	# Background
	draw_rect(Rect2(0, 0, 640, 480), Color(0.08, 0.08, 0.15), true)

	# Title
	draw_string(ThemeDB.fallback_font, Vector2(16, 28), "Tooltip Demo",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.9, 0.9, 1.0))
	draw_string(ThemeDB.fallback_font, Vector2(16, 52), "Hover items to see tooltips",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.6, 0.6, 0.7))

	# Draw items
	for i in range(_items.size()):
		var item = _items[i]
		var is_hovered := i == _hovered_idx

		var circle_color: Color = item["color"]
		if is_hovered:
			circle_color = circle_color.lightened(0.2)

		draw_circle(item["pos"], item["radius"], circle_color)
		draw_arc(item["pos"], item["radius"], 0.0, TAU, 32,
				Color(1.0, 1.0, 1.0, 0.3 if not is_hovered else 0.8), 2.0)

		var label_pos: Vector2 = item["pos"] + Vector2(-item["radius"], item["radius"] + 16)
		draw_string(ThemeDB.fallback_font, label_pos, item["title"],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.9, 0.9, 0.9))

	# Draw tooltip
	if _tooltip_alpha > 0.0 and _hovered_idx >= 0:
		var item = _items[_hovered_idx]
		var tooltip_size := Vector2(220.0, 70.0)
		var pos := _clamp_tooltip_rect(_mouse_pos, tooltip_size)

		# Shadow
		draw_rect(Rect2(pos + Vector2(3, 3), tooltip_size),
				Color(0.0, 0.0, 0.0, 0.4 * _tooltip_alpha), true)

		# Background
		draw_rect(Rect2(pos, tooltip_size),
				Color(0.1, 0.1, 0.1, 0.92 * _tooltip_alpha), true)

		# Border
		draw_rect(Rect2(pos, tooltip_size),
				Color(0.8, 0.8, 0.8, _tooltip_alpha), false, 1.5)

		# Accent line at top using item color
		draw_rect(Rect2(pos, Vector2(tooltip_size.x, 3)),
				Color(item["color"].r, item["color"].g, item["color"].b, _tooltip_alpha), true)

		# Title
		draw_string(ThemeDB.fallback_font, pos + Vector2(8, 18),
				item["title"], HORIZONTAL_ALIGNMENT_LEFT, -1, 15,
				Color(1.0, 0.95, 0.7, _tooltip_alpha))

		# Description lines
		var desc_lines: PackedStringArray = item["desc"].split("\n")
		for li in range(desc_lines.size()):
			draw_string(ThemeDB.fallback_font,
					pos + Vector2(8, 36 + li * 16),
					desc_lines[li], HORIZONTAL_ALIGNMENT_LEFT, -1, 12,
					Color(0.82, 0.82, 0.82, _tooltip_alpha))
