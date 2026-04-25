extends Node2D

const POOL_SIZE := 20

var _hits := 0
var _misses := 0

@onready var stats_label: Label = $"../StatsLabel"

func _ready() -> void:
	for i in POOL_SIZE:
		var b := Node2D.new()
		b.set_script(load("res://scripts/bullet.gd"))
		b.visible = false
		add_child(b)

func request_bullet() -> Node2D:
	for child in get_children():
		if not child.visible:
			_hits += 1
			_update_stats()
			return child
	# Pool exhausted — in a real game you'd either grow the pool or skip
	_misses += 1
	_update_stats()
	return null

func _update_stats() -> void:
	var active := get_children().filter(func(c): return c.visible).size()
	stats_label.text = (
		"Pool: %d/%d active   Reuses: %d   Pool misses: %d" % [active, POOL_SIZE, _hits, _misses]
	)
