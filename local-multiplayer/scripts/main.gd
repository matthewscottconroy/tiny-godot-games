extends Node2D

const CoinScript = preload("res://scripts/coin.gd")

var scores := [0, 0]
var coin_positions := [
	Vector2(100, 200), Vector2(200, 150), Vector2(320, 100),
	Vector2(440, 150), Vector2(540, 200), Vector2(160, 300),
	Vector2(480, 300), Vector2(320, 260), Vector2(80,  350),
	Vector2(560, 350),
]

@onready var score_label : Label   = $ScoreLabel
@onready var coins_node  : Node2D  = $Coins

func _ready() -> void:
	for pos in coin_positions:
		_spawn_coin(pos)
	_refresh()

func _spawn_coin(pos: Vector2) -> void:
	var coin := Area2D.new()
	coin.set_script(CoinScript)
	coin.position = pos
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 10.0
	col.shape = shape
	coin.add_child(col)
	coin.collected.connect(_on_collected)
	coins_node.add_child(coin)

func _on_collected(pid: int) -> void:
	scores[pid - 1] += 1
	_refresh()
	if coins_node.get_child_count() == 0:
		score_label.text += "  — All collected!"

func _refresh() -> void:
	score_label.text = "P1 (WASD): %d     P2 (Arrows): %d" % [scores[0], scores[1]]
