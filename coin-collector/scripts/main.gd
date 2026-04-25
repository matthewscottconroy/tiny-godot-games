extends Node2D

var score := 0
var total := 0

func _ready() -> void:
	total = $Coins.get_child_count()
	for coin in $Coins.get_children():
		coin.collected.connect(_on_coin_collected)
	_update_label()

func _on_coin_collected() -> void:
	score += 1
	_update_label()

func _update_label() -> void:
	$ScoreLabel.text = "Coins: %d / %d" % [score, total]
	if score == total:
		$ScoreLabel.text += "  — All collected!"
