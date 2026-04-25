extends Node2D

const Coin = preload("res://scenes/coin.tscn")

var count := 0

func _ready() -> void:
	var timer := Timer.new()
	add_child(timer)
	timer.wait_time = 1.0
	timer.timeout.connect(_spawn)
	timer.start()
	_spawn()

func _spawn() -> void:
	var coin := Coin.instantiate()
	coin.position = Vector2(randf_range(30, 610), randf_range(50, 440))
	add_child(coin)
	count += 1
	$CountLabel.text = "Coins spawned: %d  (each lives 4 seconds)" % count
