class_name Interactable
extends Area2D

@export var label_text  := "Interact"
@export var response    := "..."
@export var icon_color  := Color.GOLD

var _times_used := 0

@onready var _prompt:     Label = $Prompt
@onready var _resp_label: Label = $ResponseLabel

func _ready() -> void:
	_prompt.text    = "[E] " + label_text
	_prompt.visible = false
	_resp_label.visible = false
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)

func _draw() -> void:
	draw_rect(Rect2(-20, -20, 40, 40), icon_color)
	draw_rect(Rect2(-20, -20, 40, 40), icon_color.lightened(0.4), false, 2.0)

func interact() -> void:
	_times_used += 1
	_resp_label.text    = response + (" (×%d)" % _times_used if _times_used > 1 else "")
	_resp_label.visible = true
	_prompt.modulate    = Color.LIME_GREEN
	var t := create_tween()
	t.tween_interval(1.8)
	t.tween_callback(func() -> void:
		_resp_label.visible = false
		_prompt.modulate    = Color.WHITE
	)

func _on_enter(body: Node) -> void:
	if body.is_in_group("player"):
		body.set_nearby(self)
		_prompt.visible = true

func _on_exit(body: Node) -> void:
	if body.is_in_group("player"):
		body.set_nearby(null)
		_prompt.visible = false
		_resp_label.visible = false
