extends Node2D

@onready var _target: Node2D = $Target

var _fired := 0

func _process(_delta: float) -> void:
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_select"):
		_fire()

func _fire() -> void:
	var proj := HomingProjectile.new()
	add_child(proj)
	proj.init(Vector2(90, 240), Vector2.RIGHT, _target)
	_fired += 1

func _draw() -> void:
	draw_rect(Rect2(40, 220, 24, 40), Color.DODGER_BLUE)
	draw_rect(Rect2(64, 232, 26, 16), Color(0.55, 0.65, 0.75))
	draw_string(ThemeDB.fallback_font, Vector2(8, 20), "Fired: %d" % _fired, HORIZONTAL_ALIGNMENT_LEFT, -1, 13)
