extends Control

const SLOT_SIZE := 64
const COLS      := 4
const ROWS      := 4

# Item definitions: {name, color, symbol}
const ITEM_DEFS := [
	{name = "Sword",   color = Color.SILVER,      symbol = "⚔"},
	{name = "Shield",  color = Color.CORNFLOWER_BLUE, symbol = "🛡"},
	{name = "Potion",  color = Color.TOMATO,       symbol = "⚗"},
	{name = "Gold",    color = Color.GOLD,          symbol = "★"},
	{name = "Bow",     color = Color.SANDY_BROWN,   symbol = "🏹"},
	{name = "Gem",     color = Color.ORCHID,         symbol = "◆"},
]

# The slot model (scripts/inventory.gd). This file is the view: buttons, the
# held-item cursor, and world items. `_inv` owns place/take/swap semantics.
var _inv := Inventory.new(ROWS * COLS)
var _world_items : Array = []    # Items in the world
var _held_item  : Dictionary = {}

@onready var grid       : GridContainer = $InvPanel/VBox/Grid
@onready var info       : Label         = $InfoLabel
@onready var world_node : Node2D        = $WorldItems

func _ready() -> void:
	# Create inventory slots; the model refreshes their labels via `changed`.
	for i in ROWS * COLS:
		var slot := _make_slot_button(i)
		grid.add_child(slot)
	_inv.changed.connect(_refresh_slots)

	# Spawn world items
	var positions := [Vector2(60, 150), Vector2(120, 280), Vector2(180, 180),
						Vector2(80, 350), Vector2(200, 320), Vector2(50, 220)]
	for i in ITEM_DEFS.size():
		_spawn_world_item(ITEM_DEFS[i], positions[i])

func _make_slot_button(idx: int) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	btn.pressed.connect(func(): _on_slot_clicked(idx, false))
	btn.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_RIGHT and ev.pressed:
			_on_slot_clicked(idx, true))
	_refresh_slot_text(btn, idx)
	return btn

func _spawn_world_item(item_def: Dictionary, pos: Vector2) -> void:
	var witem := {pos = pos, item = item_def}
	_world_items.append(witem)
	queue_redraw()

func _on_slot_clicked(idx: int, right_click: bool) -> void:
	if right_click:
		if not _inv.is_empty(idx):
			_world_items.append({pos = Vector2(150, 250) + Vector2(randf_range(-40, 40), 0),
				item = _inv.take(idx)})
			queue_redraw()
		return
	if _inv.is_empty(idx) and not _held_item.is_empty():
		info.text = "%s placed in slot %d" % [_held_item.name, idx]
		_inv.place(idx, _held_item)
		_held_item = {}
	elif not _inv.is_empty(idx) and _held_item.is_empty():
		_held_item = _inv.take(idx)
		info.text = "Picked up %s from inventory" % _held_item.name
	elif not _inv.is_empty(idx) and not _held_item.is_empty():
		_held_item = _inv.swap(idx, _held_item)
		info.text = "Swapped items"

func _refresh_slots() -> void:
	var buttons := grid.get_children()
	for i in buttons.size():
		_refresh_slot_text(buttons[i], i)

func _refresh_slot_text(btn: Button, idx: int) -> void:
	var item = _inv.get_item(idx)
	if item:
		btn.text = item.symbol + "\n" + item.name
		btn.modulate = item.color
	else:
		btn.text = ""
		btn.modulate = Color.WHITE

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		for i in _world_items.size():
			if _world_items[i].pos.distance_to(event.position) < 22:
				if _held_item.is_empty():
					_held_item = _world_items[i].item
					info.text = "Picked up %s — click a slot to store" % _held_item.name
				else:
					var tmp = _held_item
					_held_item = _world_items[i].item
					_world_items[i].item = tmp
					info.text = "Swapped with %s" % _world_items[i].item.name
					queue_redraw()
					return
				_world_items.remove_at(i)
				queue_redraw()
				return

func _draw() -> void:
	for w in _world_items:
		draw_circle(w.pos, 20, w.item.color)
		draw_string(ThemeDB.fallback_font, w.pos + Vector2(-10, 6),
			w.item.symbol, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
	if not _held_item.is_empty():
		var m := get_viewport().get_mouse_position()
		draw_circle(m, 18, _held_item.color.lightened(0.3))
		draw_string(ThemeDB.fallback_font, m + Vector2(-8, 6),
			_held_item.symbol, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
