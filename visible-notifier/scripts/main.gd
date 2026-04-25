extends Node2D

const COLS         := 12
const ROWS         := 8
const SPACING      := 80
const OBJECT_COUNT := COLS * ROWS

@onready var count_label : Label   = $HUD/CountLabel
@onready var objects     : Node2D  = $Objects
@onready var camera      : Camera2D = $Camera2D

var _pan_vel := Vector2.ZERO

func _ready() -> void:
	for row in ROWS:
		for col in COLS:
			_make_object(Vector2(col * SPACING + 60, row * SPACING + 110))
	_refresh_count()

func _make_object(pos: Vector2) -> void:
	var obj := Node2D.new()
	obj.position = pos
	obj.set_meta("active", true)
	obj.set_meta("angle", randf() * TAU)
	obj.set_meta("color", Color(randf(), randf(), randf()))

	# VisibleOnScreenNotifier2D handles culling
	var notifier := VisibleOnScreenNotifier2D.new()
	notifier.rect = Rect2(-20, -20, 40, 40)
	notifier.screen_entered.connect(func():
		obj.set_meta("active", true)
		_refresh_count())
	notifier.screen_exited.connect(func():
		obj.set_meta("active", false)
		_refresh_count())
	obj.add_child(notifier)

	obj.draw.connect(func():
		var col: Color = obj.get_meta("color")
		var a: float   = obj.get_meta("angle")
		if obj.get_meta("active"):
			obj.draw_circle(Vector2.ZERO, 18, col)
			obj.draw_line(Vector2.ZERO, Vector2(cos(a), sin(a)) * 18, Color.WHITE, 2)
		else:
			obj.draw_rect(Rect2(-18, -18, 36, 36), col.darkened(0.6))
	)
	objects.add_child(obj)

func _process(delta: float) -> void:
	# Pan camera with arrow keys / WASD
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	camera.position += dir * 300 * delta

	# Only rotate active (on-screen) objects
	var active_count := 0
	for obj in objects.get_children():
		if obj.get_meta("active"):
			active_count += 1
			obj.set_meta("angle", obj.get_meta("angle") + delta * 1.5)
		obj.queue_redraw()

func _refresh_count() -> void:
	var on  := objects.get_children().filter(func(o): return o.get_meta("active", false)).size()
	var total := objects.get_child_count()
	count_label.text = "Processing: %d / %d objects  (off-screen objects are paused)" % [on, total]

func _draw() -> void:
	draw_rect(Rect2(40, 90, COLS * SPACING + 40, ROWS * SPACING + 40), Color(0.07, 0.07, 0.09))
