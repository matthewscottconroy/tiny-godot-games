extends Node2D

const BOID_COUNT := 35

const BoidScript := preload("res://scripts/boid.gd")

var _boids: Array = []

func _ready() -> void:
	randomize()
	for i in BOID_COUNT:
		var b := Node2D.new()
		b.set_script(BoidScript)
		add_child(b)
		b.init(Vector2(randf_range(40, 600), randf_range(40, 440)))
		_boids.append(b)

func _process(delta: float) -> void:
	for b in _boids:
		b.step(_boids, delta)
