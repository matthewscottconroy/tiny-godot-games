extends CharacterBody2D

const SPEED        := 200.0
const SPRINT_SPEED := 360.0
const JUMP_VEL     := -400.0
const GRAVITY      := 900.0
const STAMINA_MAX  := 100.0
const DRAIN_RATE   := 38.0
const REGEN_RATE   := 18.0
const REGEN_DELAY  := 0.8

## Below this the bar turns amber — warning before the sprint cuts out, rather
## than at the moment it does.
const LOW_STAMINA  := 30.0

var _stamina:       float = STAMINA_MAX
var _sprinting:     bool  = false
var _regen_wait:    float = 0.0

@onready var _bar:   ProgressBar = $StaminaBar
@onready var _label: Label       = $InfoLabel

## Drain while sprinting, regenerate otherwise — but only after a delay.
##
## The delay is what stops stamina from being a free resource: releasing sprint
## for a single frame must not start it refilling, or tapping the key
## indefinitely costs nothing. Every sprinting frame re-arms it.
func tick_stamina(delta: float, wants_to_sprint: bool) -> void:
	# Wanting to sprint is not enough — an empty bar refuses.
	_sprinting = wants_to_sprint and _stamina > 0.0

	if _sprinting:
		_stamina    = maxf(_stamina - DRAIN_RATE * delta, 0.0)
		_regen_wait = REGEN_DELAY
	else:
		_regen_wait = maxf(_regen_wait - delta, 0.0)
		if _regen_wait <= 0.0:
			_stamina = minf(_stamina + REGEN_RATE * delta, STAMINA_MAX)

func current_speed() -> float:
	return SPRINT_SPEED if _sprinting else SPEED

func stamina() -> float:
	return _stamina

func is_sprinting() -> bool:
	return _sprinting

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	var h := Input.get_axis("ui_left", "ui_right")
	tick_stamina(delta, wants_to_sprint(Input.is_key_pressed(KEY_SHIFT), h))
	velocity.x = h * current_speed()
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = JUMP_VEL
	move_and_slide()
	queue_redraw()

	if _bar:
		_bar.value  = _stamina
		_bar.modulate = bar_colour()
	if _label:
		_label.text = status_text()

## Sprinting takes both a held key and somewhere to run: standing still with
## the key down must not burn stamina, or the meter empties while the player is
## not moving. Separated from _physics_process because the key comes from Input.
static func wants_to_sprint(key_held: bool, h_input: float) -> bool:
	return key_held and h_input != 0.0

## The stamina bar goes amber when it is running low, so the reader has warning
## before it runs out rather than at the moment it does.
func bar_colour() -> Color:
	return Color.GREEN if _stamina > LOW_STAMINA else Color.ORANGE_RED

## What the readout says. Three states, and they have to be told apart: a bar
## that reads DEPLETED while it is full is worse than no bar at all.
func status_text() -> String:
	if _sprinting:
		return "SPRINTING"
	return "DEPLETED" if _stamina <= 0.0 else "READY"

func _draw() -> void:
	var col := Color.GOLD if _sprinting else Color.DODGER_BLUE
	draw_rect(Rect2(-12, -24, 24, 48), col)
	draw_rect(Rect2(-6, -20, 5, 5), Color.WHITE)
	draw_rect(Rect2(1,  -20, 5, 5), Color.WHITE)
