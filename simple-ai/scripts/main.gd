extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var enemy: CharacterBody2D = $Enemy
@onready var sight_line: Line2D = $SightLine

func _process(_delta: float) -> void:
	sight_line.set_point_position(0, enemy.global_position)
	sight_line.set_point_position(1, player.global_position)

	var dist := enemy.global_position.distance_to(player.global_position)
	$DistanceLabel.text = "Distance: %.0f px" % dist
