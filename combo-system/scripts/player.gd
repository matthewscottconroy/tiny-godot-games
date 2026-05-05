extends CharacterBody2D

const SPEED   := 180.0
const GRAVITY := 900.0

var _combo := ComboSystem.new()
var _flash_timer := 0.0
var _last_combo  := ""

@onready var _combo_label:   Label = $ComboLabel
@onready var _history_label: Label = $HistoryLabel

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	velocity.x = Input.get_axis("ui_left", "ui_right") * SPEED
	if is_on_floor() and Input.is_action_just_pressed("ui_up"):
		velocity.y = -380.0

	_check_attacks()

	_flash_timer = maxf(_flash_timer - delta, 0.0)
	move_and_slide()
	queue_redraw()

func _check_attacks() -> void:
	var fired := ""
	if Input.is_action_just_pressed("ui_accept"):
		fired = _combo.add_input("L")
	elif Input.is_action_just_pressed("ui_cancel"):
		fired = _combo.add_input("H")

	_history_label.text = _combo.get_history_string()

	if not fired.is_empty():
		_last_combo  = fired
		_flash_timer = 0.5
		_combo_label.text    = fired + "!"
		_combo_label.modulate = Color.LIME_GREEN
	elif _flash_timer <= 0.0:
		_combo_label.text    = ""
		_combo_label.modulate = Color.WHITE

func _draw() -> void:
	var col := Color.CRIMSON.lerp(Color.ORANGE_RED, _flash_timer * 2.0) if _flash_timer > 0.0 else Color.STEEL_BLUE
	draw_rect(Rect2(-15, -28, 30, 54), col)
	draw_rect(Rect2(-7, -23, 5, 5), Color.WHITE)
	draw_rect(Rect2(2, -23, 5, 5), Color.WHITE)
