extends Node2D

@onready var enemy       : Node2D = $Enemy
@onready var stats_label : Label  = $StatsLabel

func _ready() -> void:
	$Buttons/GoblinBtn.pressed.connect(_apply_goblin)
	$Buttons/DragonBtn.pressed.connect(_apply_dragon)
	$Buttons/RandomBtn.pressed.connect(_apply_random)
	_apply_goblin()

func _apply_goblin() -> void:
	var s        := EnemyStats.new()
	s.enemy_name  = "Goblin"
	s.max_hp      = 30
	s.speed       = 140.0
	s.attack      = 5
	s.color       = Color.SEA_GREEN
	_apply(s)

func _apply_dragon() -> void:
	var s        := EnemyStats.new()
	s.enemy_name  = "Dragon"
	s.max_hp      = 500
	s.speed       = 60.0
	s.attack      = 80
	s.color       = Color.FIREBRICK
	_apply(s)

func _apply_random() -> void:
	var s        := EnemyStats.new()
	s.enemy_name  = "???"
	s.max_hp      = randi_range(10, 500)
	s.speed       = randf_range(40.0, 220.0)
	s.attack      = randi_range(1, 100)
	s.color       = Color(randf(), randf(), randf())
	_apply(s)

func _apply(s: EnemyStats) -> void:
	enemy.stats = s
	stats_label.text = "%s\nHP: %d    Speed: %.0f    ATK: %d" % [
		s.enemy_name, s.max_hp, s.speed, s.attack]
