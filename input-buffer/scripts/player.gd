extends CharacterBody2D

const SPEED   := 180.0
const GRAVITY := 900.0

# Buffering/cooldown timing lives in the reusable InputBuffer; its defaults
# (0.18s window, 0.5s cooldown) match this demo, so no configuration is needed.
var _attack := InputBuffer.new()   # scripts/input_buffer.gd
var _flash  := 0.0
var _hits   := 0

@onready var _info_label:   Label = $InfoLabel
@onready var _status_label: Label = $StatusLabel

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	velocity.x = Input.get_axis("ui_left", "ui_right") * SPEED
	if is_on_floor() and Input.is_action_just_pressed("ui_up"):
		velocity.y = -380.0

	_attack.update(delta)
	_flash = maxf(_flash - delta, 0.0)

	if Input.is_action_just_pressed("ui_accept"):
		_attack.press()
	if _attack.consume():
		_fire_attack()

	move_and_slide()
	_update_labels()
	queue_redraw()

func _fire_attack() -> void:
	_flash = 0.15
	_hits += 1

func _draw() -> void:
	var col := Color.ORANGE_RED if _flash > 0.0 else Color.STEEL_BLUE
	draw_rect(Rect2(-15, -28, 30, 54), col)
	draw_rect(Rect2(-7, -23, 5, 5), Color.WHITE)
	draw_rect(Rect2( 2, -23, 5, 5), Color.WHITE)

	# Cooldown bar (orange) and buffer-window bar (green)
	var bar_w := 44.0
	draw_rect(Rect2(-22, 32, bar_w, 6), Color(0.2, 0.2, 0.2))
	draw_rect(Rect2(-22, 32, bar_w * _attack.cooldown_ratio(), 6), Color.ORANGE_RED)
	draw_rect(Rect2(-22, 40, bar_w, 6), Color(0.2, 0.2, 0.2))
	draw_rect(Rect2(-22, 40, bar_w * _attack.buffer_ratio(), 6), Color.LIME_GREEN)

func _update_labels() -> void:
	var parts: Array[String] = []
	if _attack.cooldown_left() > 0.0:
		parts.append("COOLDOWN %.2fs" % _attack.cooldown_left())
	else:
		parts.append("READY")
	if _attack.buffer_left() > 0.0:
		parts.append("BUFFERED %.2fs" % _attack.buffer_left())
	_info_label.text   = " | ".join(parts)
	_status_label.text = "Attacks: %d" % _hits
