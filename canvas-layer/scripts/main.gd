extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var pos_label: Label = $HUD/PositionLabel

func _process(_delta: float) -> void:
	pos_label.text = "World pos: (%.0f, %.0f)" % [player.position.x, player.position.y]

func _draw() -> void:
	# World decorations — pillars scattered across the wide level
	for i in range(5):
		var x := 300 + i * 250
		draw_rect(Rect2(x - 20, 240, 40, 220), Color.DIM_GRAY)
		draw_rect(Rect2(x - 30, 235, 60, 15), Color.GRAY)
	# Ground color strip
	draw_rect(Rect2(0, 455, 1400, 30), Color(0.2, 0.15, 0.1))
