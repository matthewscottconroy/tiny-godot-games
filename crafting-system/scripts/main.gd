extends Node2D

const INGREDIENTS := ["Wood", "Stone", "Iron", "Fire", "Water", "Herbs", "Cloth", "Gold"]
const INGREDIENT_COLORS := {
	"Wood":  Color(0.6, 0.4, 0.2),
	"Stone": Color(0.5, 0.5, 0.5),
	"Iron":  Color(0.7, 0.7, 0.8),
	"Fire":  Color(1.0, 0.4, 0.1),
	"Water": Color(0.2, 0.5, 0.9),
	"Herbs": Color(0.2, 0.8, 0.3),
	"Cloth": Color(0.9, 0.8, 0.6),
	"Gold":  Color(1.0, 0.85, 0.0),
}

const RECIPES := {
	"Cloth+Wood":  "Tent",
	"Fire+Wood":   "Torch",
	"Iron+Stone":  "Axe",
	"Iron+Wood":   "Sword",
	"Herbs+Water": "Potion",
	"Gold+Stone":  "Gem Ring",
	"Fire+Iron":   "Steel",
	"Stone+Wood":  "Hammer",
}

const RECIPE_HINTS := [
	"Fire + Wood = Torch",
	"Iron + Wood = Sword",
	"Iron + Stone = Axe",
	"Herbs + Water = Potion",
	"Cloth + Wood = Tent",
	"Gold + Stone = Gem Ring",
]

# Grid layout: 4 columns × 2 rows
const GRID_COLS := 4
const GRID_ROWS := 2
const BOX_W := 100.0
const BOX_H := 80.0
const GRID_X := 20.0
const GRID_Y := 80.0
const BOX_GAP := 8.0

# Craft button
const CRAFT_RECT := Rect2(240, 310, 120, 40)

var _selected: Array[String] = []
var _result: String = ""
var _result_timer: float = 0.0


func _ready() -> void:
	pass


func _get_ingredient_rect(index: int) -> Rect2:
	var col := index % GRID_COLS
	var row := index / GRID_COLS
	var x := GRID_X + col * (BOX_W + BOX_GAP)
	var y := GRID_Y + row * (BOX_H + BOX_GAP)
	return Rect2(x, y, BOX_W, BOX_H)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			# Check craft button
			if CRAFT_RECT.has_point(mb.position):
				_try_craft()
				return
			# Check ingredient boxes
			for i in INGREDIENTS.size():
				var rect := _get_ingredient_rect(i)
				if rect.has_point(mb.position):
					_toggle_ingredient(INGREDIENTS[i])
					return


func _toggle_ingredient(ing: String) -> void:
	var idx := _selected.find(ing)
	if idx >= 0:
		# Deselect
		_selected.remove_at(idx)
	else:
		if _selected.size() >= 2:
			# Replace oldest
			_selected.pop_front()
		_selected.append(ing)


func _try_craft() -> void:
	if _selected.size() < 2:
		_result = "Select 2 ingredients first!"
		_result_timer = 2.0
		return
	var sorted_pair := _selected.duplicate()
	sorted_pair.sort()
	var key := "%s+%s" % [sorted_pair[0], sorted_pair[1]]
	if RECIPES.has(key):
		_result = "Crafted: " + RECIPES[key] + "!"
	else:
		_result = "Unknown recipe"
	_result_timer = 2.5
	_selected.clear()


func _process(delta: float) -> void:
	if _result_timer > 0.0:
		_result_timer = maxf(0.0, _result_timer - delta)
		queue_redraw()
	queue_redraw()


func _draw() -> void:
	# Background
	draw_rect(Rect2(0, 0, 640, 480), Color(0.07, 0.06, 0.12))

	# Title
	draw_string(ThemeDB.fallback_font, Vector2(10, 26), "Crafting System",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.95, 0.9, 1.0))
	draw_string(ThemeDB.fallback_font, Vector2(10, 50), "Click 2 ingredients then Craft",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.6, 0.6, 0.8))

	# Ingredient grid
	for i in INGREDIENTS.size():
		var ing: String = INGREDIENTS[i]
		var rect := _get_ingredient_rect(i)
		var is_selected := _selected.has(ing)

		# Box background
		draw_rect(rect, INGREDIENT_COLORS[ing] * Color(0.4, 0.4, 0.4, 1.0))
		draw_rect(rect, INGREDIENT_COLORS[ing], false, 2.0)

		# Color swatch in top portion
		draw_rect(Rect2(rect.position.x + 6, rect.position.y + 6, 30, 30), INGREDIENT_COLORS[ing])

		# Selection highlight
		if is_selected:
			draw_rect(rect, Color(1.0, 0.9, 0.1), false, 3.5)

		# Ingredient name
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(4, rect.size.y - 10),
			ing, HORIZONTAL_ALIGNMENT_LEFT, -1, 13,
			Color(1, 1, 1) if is_selected else Color(0.85, 0.85, 0.85))

	# Selected slots display
	var sel_text := "Selected: "
	if _selected.size() == 0:
		sel_text += "(none)"
	elif _selected.size() == 1:
		sel_text += _selected[0] + " + ?"
	else:
		sel_text += _selected[0] + " + " + _selected[1]
	draw_string(ThemeDB.fallback_font, Vector2(GRID_X, 275), sel_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.9, 0.9, 0.5))

	# Craft button
	var can_craft := _selected.size() == 2
	var btn_color := Color(0.2, 0.65, 0.2) if can_craft else Color(0.25, 0.25, 0.3)
	draw_rect(CRAFT_RECT, btn_color)
	draw_rect(CRAFT_RECT, Color(0.5, 0.8, 0.5) if can_craft else Color(0.4, 0.4, 0.5), false, 2.0)
	draw_string(ThemeDB.fallback_font,
		CRAFT_RECT.position + Vector2(28, 26),
		"CRAFT", HORIZONTAL_ALIGNMENT_LEFT, -1, 20,
		Color(1, 1, 1) if can_craft else Color(0.5, 0.5, 0.5))

	# Result display
	if _result_timer > 0.0 and _result != "":
		var alpha := clampf(_result_timer / 2.5, 0.0, 1.0)
		var is_success := _result.begins_with("Crafted")
		var result_color := Color(0.3, 1.0, 0.4, alpha) if is_success else Color(1.0, 0.4, 0.3, alpha)
		draw_string(ThemeDB.fallback_font, Vector2(GRID_X, 370),
			_result, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, result_color)

	# Recipe hint panel on right
	var hint_x := 440.0
	var hint_y := 80.0
	draw_rect(Rect2(hint_x - 8, hint_y - 8, 196, 200), Color(0.1, 0.1, 0.18))
	draw_rect(Rect2(hint_x - 8, hint_y - 8, 196, 200), Color(0.3, 0.3, 0.5), false, 1.5)
	draw_string(ThemeDB.fallback_font, Vector2(hint_x, hint_y + 10), "Recipes:",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.8, 0.8, 1.0))
	for i in RECIPE_HINTS.size():
		draw_string(ThemeDB.fallback_font, Vector2(hint_x, hint_y + 30 + i * 24),
			RECIPE_HINTS[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.65, 0.75, 0.65))
