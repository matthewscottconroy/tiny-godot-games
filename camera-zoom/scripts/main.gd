extends Node2D

const ZOOM_MIN   := 0.25
const ZOOM_MAX   := 4.0
const ZOOM_STEP  := 0.15
const ZOOM_SPEED := 6.0   # lerp speed

var _target_zoom := 1.0

@onready var camera    : Camera2D = $Camera2D
@onready var zoom_label: Label    = $HUD/ZoomLabel

func _ready() -> void:
	$HUD/Buttons/InBtn.pressed.connect(func(): _adjust(ZOOM_STEP))
	$HUD/Buttons/OutBtn.pressed.connect(func(): _adjust(-ZOOM_STEP))
	$HUD/Buttons/ResetBtn.pressed.connect(func(): _target_zoom = 1.0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP   and event.pressed:
			_adjust(ZOOM_STEP)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_adjust(-ZOOM_STEP)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			_target_zoom = 1.0
		elif event.keycode == KEY_EQUAL or event.keycode == KEY_KP_ADD:
			_adjust(ZOOM_STEP)
		elif event.keycode == KEY_MINUS or event.keycode == KEY_KP_SUBTRACT:
			_adjust(-ZOOM_STEP)

func _process(delta: float) -> void:
	var current := camera.zoom.x
	var new_z   := lerpf(current, _target_zoom, ZOOM_SPEED * delta)
	camera.zoom  = Vector2(new_z, new_z)
	zoom_label.text = "Zoom: %.2fx" % new_z

## The zoom the camera is easing towards. Clamped here rather than after the
## lerp, so the limits hold no matter how many times the wheel is spun.
func _adjust(delta_zoom: float) -> void:
	_target_zoom = clampf(_target_zoom + delta_zoom, ZOOM_MIN, ZOOM_MAX)

func target_zoom() -> float:
	return _target_zoom

func _draw() -> void:
	# Grid to make zoom obvious
	for x in range(0, 1280, 80):
		draw_line(Vector2(x, -400), Vector2(x, 900), Color(1, 1, 1, 0.08), 1)
	for y in range(-400, 900, 80):
		draw_line(Vector2(-200, y), Vector2(1400, y), Color(1, 1, 1, 0.08), 1)
	# Coloured reference objects
	draw_circle(Vector2(320, 240), 40, Color.CORNFLOWER_BLUE)
	draw_rect(Rect2(100, 120, 80, 80), Color.TOMATO)
	draw_rect(Rect2(460, 300, 60, 100), Color.SEA_GREEN)
	draw_circle(Vector2(520, 140), 25, Color.GOLD)
	draw_circle(Vector2(160, 340), 18, Color.ORCHID)
	draw_string(ThemeDB.fallback_font, Vector2(290, 248), "origin",
		HORIZONTAL_ALIGNMENT_CENTER, 80, 14, Color.WHITE)
