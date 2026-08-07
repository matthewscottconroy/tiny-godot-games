extends CharacterBody2D

const SPEED    := 200.0
const JUMP_VEL := -400.0
const GRAVITY  := 900.0

var _kb := Knockback.new()   # reusable recoil + i-frames (scripts/knockback.gd)
var _hp := 5

@onready var _label: Label = $InfoLabel

func take_hit(from: Vector2) -> void:
	# hit() returns false while invincible, so HP only drops on a real hit.
	if _kb.hit(from, global_position):
		_hp = maxi(_hp - 1, 0)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	_kb.update(delta)

	var ctrl_x := Input.get_axis("ui_left", "ui_right") * SPEED
	velocity.x = ctrl_x + _kb.velocity.x
	# The upward pop is applied once, then gravity takes over.
	if _kb.velocity.y != 0.0:
		velocity.y = _kb.velocity.y
		_kb.velocity.y = 0.0

	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = JUMP_VEL

	move_and_slide()
	queue_redraw()
	_label.text = "HP: %d%s" % [_hp, "  [IFRAMES]" if _kb.is_invincible() else ""]

func _draw() -> void:
	var col := Color(1.0, 0.3, 0.3, 0.5) if _kb.is_invincible() else Color.DODGER_BLUE
	draw_rect(Rect2(-12, -24, 24, 48), col)
	draw_rect(Rect2(-6, -20, 5, 5), Color.WHITE)
	draw_rect(Rect2(1,  -20, 5, 5), Color.WHITE)
