extends Node2D

## Demo driver: the buttons call the reusable Health model (scripts/health.gd);
## this script is the *view* — it reacts to `health_changed` by animating the
## ProgressBar, updating the label and player sprite, and flashing on change.

@onready var health: Health = $Health
@onready var hp_bar: ProgressBar = $HPBar
@onready var hp_label: Label = $HPLabel
@onready var game_over_label: Label = $GameOverLabel
@onready var player_display: Node2D = $PlayerDisplay

var _shown_hp := 0

func _ready() -> void:
	$DamageBtn.pressed.connect(func() -> void: health.damage(10))
	$HealBtn.pressed.connect(func() -> void: health.heal(10))
	health.health_changed.connect(_on_health_changed)

	hp_bar.max_value = health.max_hp
	_refresh(health.hp, health.max_hp)   # initial paint, no flash
	_shown_hp = health.hp

func _on_health_changed(hp: int, max_hp: int) -> void:
	# health_changed only fires on an actual change, so the direction tells us
	# whether to flash red (damage) or green (heal).
	if hp < _shown_hp:
		_flash(Color.TOMATO)
	elif hp > _shown_hp:
		_flash(Color.LIME_GREEN)
	_shown_hp = hp
	_refresh(hp, max_hp)

func _refresh(hp: int, max_hp: int) -> void:
	var tween := create_tween()
	tween.tween_property(hp_bar, "value", float(hp), 0.2)
	hp_label.text = "HP: %d / %d" % [hp, max_hp]
	player_display.hp_ratio = float(hp) / max_hp
	game_over_label.visible = hp == 0

func _flash(color: Color) -> void:
	var tween := create_tween()
	tween.tween_property(hp_bar, "modulate", color, 0.05)
	tween.tween_property(hp_bar, "modulate", Color.WHITE, 0.35)
