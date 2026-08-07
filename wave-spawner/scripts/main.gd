extends Node2D

## Demo driver. The wave/phase loop lives in WaveSpawner (scripts/wave_spawner.gd);
## this file responds to its signals by spawning and ticking enemies, and reports
## `wave_cleared()` when the arena is empty.

const ENEMY_COLORS := [Color.TOMATO, Color.ORANGE_RED, Color.FIREBRICK]

var _spawner := WaveSpawner.new()

@onready var wave_label  : Label = $WaveLabel
@onready var status      : Label = $StatusLabel
@onready var count_label : Label = $EnemyCountLabel
@onready var enemies     : Node2D = $Enemies

func _ready() -> void:
	$Buttons/StartBtn.pressed.connect(_spawner.start)
	$Buttons/SkipBtn.pressed.connect(_spawner.skip_intermission)
	_spawner.intermission_started.connect(_on_intermission_started)
	_spawner.wave_started.connect(_on_wave_started)
	_spawner.all_waves_cleared.connect(_on_all_cleared)

func _on_intermission_started(wave: int, duration: float) -> void:
	status.modulate = Color.GOLD
	status.text = "Wave %d incoming in %.0f…" % [wave, duration]

func _on_wave_started(wave: int, count: int) -> void:
	var speed := 40.0 + wave * 12.0
	for i in count:
		_spawn_enemy(speed)
	status.modulate = Color.TOMATO
	status.text = "Wave %d — survive!" % wave
	wave_label.text = "Wave %d" % wave
	_refresh_count()

func _on_all_cleared() -> void:
	status.modulate = Color.SEA_GREEN
	status.text = "You survived all %d waves!" % _spawner.max_waves

func _spawn_enemy(speed: float) -> void:
	var e := Node2D.new()
	var vel := Vector2(randf_range(-speed, speed), randf_range(-speed, speed))
	if vel.length() < 10: vel = Vector2(speed, 0)
	e.set_meta("vel", vel)
	e.set_meta("hp", 2 + _spawner.wave)
	e.position = Vector2(randf_range(60, 580), randf_range(120, 420))
	var wave := _spawner.wave
	e.draw.connect(func():
		e.draw_circle(Vector2.ZERO, 14, ENEMY_COLORS[wave % ENEMY_COLORS.size()])
		e.draw_circle(Vector2(-4, -3), 3, Color.WHITE)
		e.draw_circle(Vector2( 4, -3), 3, Color.WHITE))
	enemies.add_child(e)

func _process(delta: float) -> void:
	_spawner.update(delta)
	match _spawner.phase:
		WaveSpawner.Phase.INTERMISSION:
			status.text = "Wave %d incoming in %.1f…" % [_spawner.wave, maxf(_spawner.timer, 0.0)]
		WaveSpawner.Phase.WAVE:
			_tick_enemies(delta)
			_refresh_count()
			if enemies.get_child_count() == 0:
				_spawner.wave_cleared()

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
		if _spawner.phase != WaveSpawner.Phase.WAVE: return
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
