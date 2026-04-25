extends Node2D

const MAX_HP := 100
var hp := MAX_HP

@onready var hp_bar: ProgressBar = $HPBar
@onready var hp_label: Label = $HPLabel
@onready var game_over_label: Label = $GameOverLabel
@onready var player_display: Node2D = $PlayerDisplay

func _ready() -> void:
	$DamageBtn.pressed.connect(_damage)
	$HealBtn.pressed.connect(_heal)
	hp_bar.max_value = MAX_HP
	hp_bar.value = MAX_HP
	game_over_label.visible = false
	_refresh()

func _damage() -> void:
	if hp <= 0:
		return
	hp = max(0, hp - 10)
	_refresh()
	_flash(Color.TOMATO)
	if hp == 0:
		game_over_label.visible = true

func _heal() -> void:
	if hp >= MAX_HP:
		return
	hp = min(MAX_HP, hp + 10)
	game_over_label.visible = false
	_refresh()
	_flash(Color.LIME_GREEN)

func _refresh() -> void:
	var tween := create_tween()
	tween.tween_property(hp_bar, "value", float(hp), 0.2)
	hp_label.text = "HP: %d / %d" % [hp, MAX_HP]
	player_display.hp_ratio = float(hp) / MAX_HP

func _flash(color: Color) -> void:
	var tween := create_tween()
	tween.tween_property(hp_bar, "modulate", color, 0.05)
	tween.tween_property(hp_bar, "modulate", Color.WHITE, 0.35)
