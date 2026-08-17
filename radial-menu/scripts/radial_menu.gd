extends Control

const ITEMS: Array[Dictionary] = [
	{"label": "Attack", "color": Color.TOMATO},
	{"label": "Magic",  "color": Color.CORNFLOWER_BLUE},
	{"label": "Item",   "color": Color.GOLD},
	{"label": "Shield", "color": Color.FOREST_GREEN},
	{"label": "Run",    "color": Color.ORCHID},
	{"label": "Info",   "color": Color.SANDY_BROWN},
]

const INNER_R := 40.0
const OUTER_R := 100.0
const CENTER  := Vector2(320.0, 240.0)

var _open    := false
var _hovered := -1

signal item_selected(index: int, label: String)

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_PASS
	set_anchors_preset(Control.PRESET_FULL_RECT)

func _process(_delta: float) -> void:
	var was_open := _open
	_open = Input.is_key_pressed(KEY_TAB)

	if _open:
		_update_hover()
	if was_open and not _open:
		_select()

	queue_redraw()

func _update_hover() -> void:
	_hovered = hovered_for(get_global_mouse_position())

## Which wedge the cursor is over, or -1 for none.
##
## Wedges are drawn centred on each item's angle, so the first one spans half a
## slice either side of zero. Rotating by half a slice before the division lines
## the hit test up with what is on screen — without it the highlight sat half a
## wedge away from the pointer.
func hovered_for(mouse_pos: Vector2) -> int:
	var offset := mouse_pos - CENTER
	if offset.length() < INNER_R:
		return -1
	var slice := TAU / float(ITEMS.size())
	var angle := fmod(offset.angle() + slice * 0.5 + TAU, TAU)
	return int(angle / slice) % ITEMS.size()

func _select() -> void:
	if _hovered >= 0 and _hovered < ITEMS.size():
		item_selected.emit(_hovered, ITEMS[_hovered]["label"])
	_hovered = -1

func _draw() -> void:
	if not _open:
		return

	# Dim background
	draw_rect(Rect2(0, 0, 640, 480), Color(0, 0, 0, 0.4))

	var n := ITEMS.size()
	for i in n:
		var slice_angle := TAU / float(n)
		var start_a := float(i) * slice_angle - slice_angle * 0.5
		var end_a   := start_a + slice_angle
		var is_hovered := (i == _hovered)
		var r := OUTER_R + (12.0 if is_hovered else 0.0)
		var col: Color = ITEMS[i]["color"]
		if is_hovered:
			col = col.lightened(0.25)

		# Build wedge polygon
		var pts := PackedVector2Array()
		var steps := 10
		pts.append(CENTER + Vector2.from_angle(start_a) * INNER_R)
		for s in steps + 1:
			var a := lerpf(start_a, end_a, float(s) / float(steps))
			pts.append(CENTER + Vector2.from_angle(a) * r)
		pts.append(CENTER + Vector2.from_angle(end_a) * INNER_R)

		var colors := PackedColorArray()
		colors.resize(pts.size())
		colors.fill(col)
		draw_polygon(pts, colors)

		# Wedge border
		draw_polyline(pts, Color(1, 1, 1, 0.3), 1.0)

		# Label
		var mid_a := (start_a + end_a) * 0.5
		var label_r := (INNER_R + r) * 0.5
		var lpos := CENTER + Vector2.from_angle(mid_a) * label_r
		var font := ThemeDB.fallback_font
		var font_size := 14
		var text: String = ITEMS[i]["label"]
		var text_w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		draw_string(font, lpos - Vector2(text_w * 0.5, -5.0), text,
				HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)

	# Center circle
	draw_circle(CENTER, INNER_R, Color(0.15, 0.15, 0.15, 0.9))
	draw_arc(CENTER, INNER_R, 0.0, TAU, 32, Color(1, 1, 1, 0.4), 1.5)

	# Hint in center
	var font := ThemeDB.fallback_font
	draw_string(font, CENTER - Vector2(18, 5), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
