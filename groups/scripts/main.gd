extends Node2D

const EnemyScript = preload("res://scripts/enemy.gd")

@onready var log_label : Label   = $LogLabel
@onready var enemies   : Node2D  = $Enemies

func _ready() -> void:
	for i in 7:
		_spawn_enemy()

	$Buttons/FlashBtn.pressed.connect(func():
		get_tree().call_group("enemies", "flash")
		_log("flash() called on all %d enemies" % get_tree().get_nodes_in_group("enemies").size()))

	$Buttons/FreezeBtn.pressed.connect(func():
		get_tree().call_group("enemies", "freeze_toggle")
		_log("freeze_toggle() called on all enemies"))

	$Buttons/DamageBtn.pressed.connect(func():
		get_tree().call_group("enemies", "take_damage", 25)
		_log("take_damage(25) — %d enemies remain" % get_tree().get_nodes_in_group("enemies").size()))

	$Buttons/SpawnBtn.pressed.connect(func():
		_spawn_enemy()
		_log("Spawned enemy — total: %d" % get_tree().get_nodes_in_group("enemies").size()))

func _spawn_enemy() -> void:
	var e := Node2D.new()
	e.set_script(EnemyScript)
	e.position = Vector2(randf_range(80, 560), randf_range(100, 380))
	enemies.add_child(e)

func _log(msg: String) -> void:
	log_label.text = msg
