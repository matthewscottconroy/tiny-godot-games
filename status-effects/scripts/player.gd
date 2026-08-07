extends CharacterBody2D

const SPEED    := 200.0
const JUMP_VEL := -400.0
const GRAVITY  := 900.0
const MAX_HP   := 100.0

# The catalog is game data: what each effect does. It's handed to the reusable
# StatusEffectStack, which owns the timing and stacking logic. `color` is only
# used by this demo's _draw().
const EFFECT_CFG := {
	"poison": {"color": Color(0.20, 0.90, 0.20), "dps": 10.0, "slow": 1.00, "duration": 5.0},
	"burn":   {"color": Color(1.00, 0.30, 0.10), "dps": 22.0, "slow": 1.00, "duration": 3.0},
	"freeze": {"color": Color(0.30, 0.70, 1.00), "dps":  0.0, "slow": 0.35, "duration": 4.0},
}

var _hp: float = MAX_HP
var _fx := StatusEffectStack.new(EFFECT_CFG)   # scripts/status_effect_stack.gd

@onready var _hp_bar:  ProgressBar = $HPBar
@onready var _fx_label: Label      = $FXLabel

func apply_effect(name: String) -> void:
	_fx.apply(name)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	var result := _fx.tick(delta)
	_hp = maxf(_hp - result["damage"], 0.0)
	var slow: float = result["slow"]

	velocity.x = Input.get_axis("ui_left", "ui_right") * SPEED * slow
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = JUMP_VEL

	move_and_slide()
	queue_redraw()
	_hp_bar.value = _hp

	var parts: Array[String] = []
	for fx in _fx.active():
		parts.append("%s %.1fs" % [fx.to_upper(), _fx.time_left(fx)])
	_fx_label.text = " | ".join(parts) if parts.size() > 0 else "(none)"

func _draw() -> void:
	var col := Color.DODGER_BLUE
	for fx in _fx.active():
		col = col.lerp(EFFECT_CFG[fx]["color"], 0.65)
	draw_rect(Rect2(-12, -24, 24, 48), col)
	draw_rect(Rect2(-6, -20, 5, 5), Color.WHITE)
	draw_rect(Rect2(1,  -20, 5, 5), Color.WHITE)
