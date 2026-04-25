extends Node2D

const ENEMY_COLORS := [Color.TOMATO, Color.ORANGE_RED, Color.FIREBRICK]

enum Phase { IDLE, INTERMISSION, WAVE }

var wave        := 0
var phase       := Phase.IDLE
var alive       := 0
var timer       := 0.0
var intermission_duration := 3.0

@onready var wave_label  : Label = $WaveLabel
@onready var status      : Label = $StatusLabel
@onready var count_label : Label = $EnemyCountLabel
@onready var enemies     : Node2D = $Enemies

func _ready() -> void:
	$Buttons/StartBtn.pressed.connect(_start)
	$Buttons/SkipBtn.pressed.connect(func(): if phase == Phase.INTERMISSION: timer = 0.0)

func _start() -> void:
	if phase != Phase.IDLE:
		return
	wave = 0
	_begin_intermission()

func _begin_intermission() -> void:
	phase = Phase.INTERMISSION
	timer = intermission_duration
	wave += 1
	status.modulate = Color.GOLD
	status.text = "Wave %d incoming in %.0f…" % [wave, timer]

func _begin_wave() -> void:
	phase = Phase.WAVE
	var count := 3 + (wave - 1) * 2   # grows each wave
	var speed := 40.0 + wave * 12.0
	for i in count:
		_spawn_enemy(speed)
	alive = enemies.get_child_count()
	status.modulate = Color.TOMATO
	status.text = "Wave %d — survive!" % wave
	wave_label.text = "Wave %d" % wave
	_refresh_count()

func _spawn_enemy(speed: float) -> void:
	var e := Node2D.new()
	var vel := Vector2(randf_range(-speed, speed), randf_range(-speed, speed))
	if vel.length() < 10: vel = Vector2(speed, 0)
	e.set_meta("vel", vel)
	e.set_meta("hp", 2 + wave)
	e.position = Vector2(randf_range(60, 580), randf_range(120, 420))
	e.draw.connect(func():
		e.draw_circle(Vector2.ZERO, 14, ENEMY_COLORS[wave % ENEMY_COLORS.size()])
		e.draw_circle(Vector2(-4, -3), 3, Color.WHITE)
		e.draw_circle(Vector2( 4, -3), 3, Color.WHITE))
	enemies.add_child(e)

func _process(delta: float) -> void:
	match phase:
		Phase.INTERMISSION:
			timer -= delta
			status.text = "Wave %d incoming in %.1f…" % [wave, maxf(timer, 0.0)]
			if timer <= 0.0:
				_begin_wave()
		Phase.WAVE:
			_tick_enemies(delta)
			_refresh_count()
			if enemies.get_child_count() == 0:
				if wave >= 5:
					status.modulate = Color.SEA_GREEN
					status.text = "You survived all 5 waves!"
					phase = Phase.IDLE
				else:
					_begin_intermission()

func _tick_enemies(delta: float) -> void:
	for e in enemies.get_children():
		var vel : Vector2 = e.get_meta("vel")
		e.position += vel * delta
		if e.position.x < 40 or e.position.x > 600: vel.x *= -1
		if e.position.y < 110 or e.position.y > 440: vel.y *= -1
		e.set_meta("vel", vel)
		e.queue_redraw()

func _refresh_count() -> void:
	count_label.text = "Enemies remaining: %d" % enemies.get_child_count()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if phase != Phase.WAVE: return
		for e in enemies.get_children():
			if e.position.distance_to(event.position) < 18:
				var hp: int = e.get_meta("hp") - 1
				if hp <= 0:
					e.queue_free()
				else:
					e.set_meta("hp", hp)
				break

func _draw() -> void:
	draw_rect(Rect2(0, 100, 640, 360), Color(0.06, 0.06, 0.08))
	draw_string(ThemeDB.fallback_font, Vector2(8, 472),
		"Click enemies to damage them (each has 2+wave HP)  |  5 waves total",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1,1,1,0.5))
