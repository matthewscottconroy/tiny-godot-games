extends Node2D

## Demo driver: wires the player's `fired` signal to the ObjectPool and shows
## live pool statistics. The pool itself (scripts/object_pool.gd) knows nothing
## about this demo — it is a reusable component.

@onready var pool: ObjectPool = $BulletPool
@onready var player: CharacterBody2D = $Player
@onready var stats_label: Label = $StatsLabel

func _ready() -> void:
	player.fired.connect(_on_fired)

func _on_fired(from: Vector2, dir: Vector2) -> void:
	var bullet := pool.acquire()
	if bullet:
		bullet.fire(from, dir)

func _process(_delta: float) -> void:
	stats_label.text = "Pool: %d/%d active   Reuses: %d   Pool misses: %d" % [
		pool.active_count(), pool.size, pool.reuse_count, pool.miss_count,
	]
