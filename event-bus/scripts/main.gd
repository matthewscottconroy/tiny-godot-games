extends Node2D

const CoinPositions := [
	Vector2(100, 200), Vector2(200, 140), Vector2(400, 180),
	Vector2(520, 240), Vector2(300, 300), Vector2(460, 350),
]

var log_lines : Array[String] = []

@onready var log_label  : Label  = $LogLabel
@onready var coins_node : Node2D = $Coins

func _ready() -> void:
	EventBus.item_collected.connect(func(name: String): _log("[item_collected] " + name))
	EventBus.player_hurt.connect(func(dmg: int):     _log("[player_hurt] -%d HP" % dmg))
	EventBus.player_healed.connect(func(amt: int):   _log("[player_healed] +%d HP" % amt))
	EventBus.enemy_died.connect(func(name: String):  _log("[enemy_died] " + name))

	for pos in CoinPositions:
		_spawn_coin(pos)

func _spawn_coin(pos: Vector2) -> void:
	var coin := Area2D.new()
	var col  := CollisionShape2D.new()
	col.shape = CircleShape2D.new()
	(col.shape as CircleShape2D).radius = 10.0
	coin.add_child(col)
	coin.position = pos
	# Draw on the coin node so it disappears when queue_free() is called
	coin.draw.connect(func():
		coin.draw_circle(Vector2.ZERO, 10, Color.GOLD)
		coin.draw_circle(Vector2.ZERO, 10, Color.YELLOW, false, 2))
	coin.body_entered.connect(func(_b):
		EventBus.item_collected.emit("Gold Coin")
		coin.queue_free())
	coins_node.add_child(coin)
	coin.set_deferred("monitoring", true)

func _log(msg: String) -> void:
	log_lines.push_front(msg)
	if log_lines.size() > 9:
		log_lines.pop_back()
	log_label.text = "\n".join(log_lines)
