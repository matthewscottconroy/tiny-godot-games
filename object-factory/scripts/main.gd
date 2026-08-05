extends Node2D

const COLORS := {
	"enemy_basic": Color.TOMATO,
	"enemy_fast":  Color.GOLD,
	"enemy_tank":  Color.ORCHID,
	"item_coin":   Color.YELLOW,
	"item_health": Color.LIME_GREEN,
}

var _factory := EntityFactory.new()
var _entities: Array[Dictionary] = []

func _ready() -> void:
	_factory.register(&"enemy_basic", func(_p: Dictionary) -> Dictionary:
		return {"type": "enemy_basic", "hp": 3,  "speed": 80.0,  "radius": 14.0})
	_factory.register(&"enemy_fast",  func(_p: Dictionary) -> Dictionary:
		return {"type": "enemy_fast",  "hp": 1,  "speed": 200.0, "radius": 10.0})
	_factory.register(&"enemy_tank",  func(_p: Dictionary) -> Dictionary:
		return {"type": "enemy_tank",  "hp": 10, "speed": 40.0,  "radius": 22.0})
	_factory.register(&"item_coin",   func(_p: Dictionary) -> Dictionary:
		return {"type": "item_coin",   "value": 10, "radius": 9.0})
	_factory.register(&"item_health", func(_p: Dictionary) -> Dictionary:
		return {"type": "item_health", "restore": 2, "radius": 11.0})

	for t in _factory.registered_types():
		_spawn(t)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: _spawn(&"enemy_basic")
			KEY_2: _spawn(&"enemy_fast")
			KEY_3: _spawn(&"enemy_tank")
			KEY_4: _spawn(&"item_coin")
			KEY_5: _spawn(&"item_health")
			KEY_C: _entities.clear(); queue_redraw()

func _spawn(type_name: StringName) -> void:
	var e := _factory.create(type_name)
	if not e.is_empty():
		e["pos"] = Vector2(randf_range(40.0, 600.0), randf_range(60.0, 440.0))
		_entities.append(e)
		queue_redraw()

func _draw() -> void:
	for e in _entities:
		var pos: Vector2 = e["pos"]
		var r: float     = e.get("radius", 12.0)
		var col: Color   = COLORS.get(e["type"], Color.WHITE)
		draw_circle(pos, r, col)
		draw_circle(pos, r, Color(0, 0, 0, 0.3), false, 1.5)
		var label := "%s\nhp:%s spd:%s" % [
			e["type"],
			str(e.get("hp", e.get("value", e.get("restore", "?")))),
			str(e.get("speed", "-")),
		]
		draw_string(ThemeDB.fallback_font, pos + Vector2(-30, r + 14),
			label, HORIZONTAL_ALIGNMENT_LEFT, 80, 10, Color.WHITE)
