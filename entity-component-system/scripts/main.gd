extends Node2D

var _world := ECSWorld.new()

func _ready() -> void:
	_spawn_entities()

func _spawn_entities() -> void:
	for i in 12:
		var e := _world.create_entity()
		_world.add_component(e, &"Position", {
			"x": randf_range(40.0, 600.0),
			"y": randf_range(60.0, 420.0),
		})
		_world.add_component(e, &"Velocity", {
			"x": randf_range(-60.0, 60.0),
			"y": randf_range(-60.0, 60.0),
		})
		_world.add_component(e, &"Health", {
			"hp": randi_range(2, 8),
			"max_hp": 8,
		})
		_world.add_component(e, &"Render", {
			"radius": randf_range(10.0, 20.0),
			"color": Color(randf(), randf_range(0.3, 0.9), randf_range(0.3, 0.9)),
		})

func _process(delta: float) -> void:
	_movement_system(delta)
	_damage_system(delta)
	queue_redraw()

func _movement_system(delta: float) -> void:
	for e in _world.query([&"Position", &"Velocity"]):
		var pos := _world.get_component(e, &"Position")
		var vel := _world.get_component(e, &"Velocity")
		pos["x"] += vel["x"] * delta
		pos["y"] += vel["y"] * delta
		if pos["x"] < 20.0 or pos["x"] > 620.0:
			vel["x"] = -vel["x"]
			pos["x"] = clampf(pos["x"], 20.0, 620.0)
		if pos["y"] < 50.0 or pos["y"] > 460.0:
			vel["y"] = -vel["y"]
			pos["y"] = clampf(pos["y"], 50.0, 460.0)

func _damage_system(delta: float) -> void:
	for e in _world.query([&"Health"]):
		var hp := _world.get_component(e, &"Health")
		hp["hp"] = maxf(0.0, hp["hp"] - delta * 0.3)

func _draw() -> void:
	for e in _world.query([&"Position", &"Render", &"Health"]):
		var pos    := _world.get_component(e, &"Position")
		var render := _world.get_component(e, &"Render")
		var health := _world.get_component(e, &"Health")
		var p      := Vector2(pos["x"], pos["y"])
		var r: float = render["radius"]
		var col: Color = render["color"]
		var hp_ratio: float = health["hp"] / float(health["max_hp"])
		col.a = 0.3 + hp_ratio * 0.7
		draw_circle(p, r, col)
		draw_arc(p, r + 3.0, -PI / 2.0, -PI / 2.0 + TAU * hp_ratio, 24,
			Color.LIME_GREEN if hp_ratio > 0.5 else Color.TOMATO, 2.0)
