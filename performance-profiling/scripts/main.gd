extends Node2D

# Demo driver. Three sections of deliberately variable cost, so the report
# changes as you make one of them expensive.

@onready var _report: Label = $HUD/ReportLabel
@onready var _hint: Label = $HUD/HintLabel

var _budget: FrameBudget
var _particles: Array[Vector2] = []
var _particle_count := 200
var _sort_size := 200
var _engine_stats := {}

func _ready() -> void:
	_budget = FrameBudget.new(60.0, 60)
	_hint.text = "1/2 particles   3/4 sort work   R reset samples"
	_respawn()

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_1: _particle_count = maxi(_particle_count - 200, 0); _respawn()
		KEY_2: _particle_count = mini(_particle_count + 200, 4000); _respawn()
		KEY_3: _sort_size = maxi(_sort_size - 400, 0)
		KEY_4: _sort_size = mini(_sort_size + 400, 8000)
		KEY_R: _budget.reset()

func _respawn() -> void:
	_particles.clear()
	for i in _particle_count:
		_particles.append(Vector2(randf() * 640.0, randf() * 200.0 + 60.0))

func _process(delta: float) -> void:
	_budget.begin("simulate")
	for i in _particles.size():
		var p := _particles[i]
		p.y += 40.0 * delta
		if p.y > 260.0:
			p.y = 60.0
		_particles[i] = p
	_budget.end("simulate")

	# Stand-in for the sort/AI/pathfinding work most games do somewhere.
	_budget.begin("sort")
	var work: Array[float] = []
	for i in _sort_size:
		work.append(fmod(float(i) * 2654435761.0, 1000.0))
	work.sort()
	_budget.end("sort")

	_budget.begin("report")
	_engine_stats = {
		"fps": Engine.get_frames_per_second(),
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"objects": Performance.get_monitor(Performance.OBJECT_COUNT),
		"static_mem": Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
	}
	_refresh()
	_budget.end("report")

	_budget.end_frame()
	queue_redraw()

func _refresh() -> void:
	var lines: Array[String] = []
	lines.append("budget %.2f ms/frame   used %.0f%%   %s" % [
		_budget.budget_ms, _budget.budget_used() * 100.0,
		"OVER" if _budget.over_budget() else "ok"])
	lines.append("")
	for row in _budget.worst_first():
		lines.append("  %-10s %6.3f ms   %4.0f%%" % [row["section"], row["ms"], row["share"] * 100.0])
	lines.append("")
	lines.append("particles %d    sort %d" % [_particles.size(), _sort_size])
	lines.append("engine: %d fps   %d draw calls   %d objects   %.1f MB" % [
		_engine_stats.get("fps", 0), _engine_stats.get("draw_calls", 0),
		_engine_stats.get("objects", 0), _engine_stats.get("static_mem", 0.0)])
	_report.text = "\n".join(lines)

func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 480), Color(0.09, 0.10, 0.14))
	for p in _particles:
		draw_rect(Rect2(p, Vector2(2, 2)), Color(0.4, 0.65, 0.9, 0.8))
	# Budget bar: how much of a frame the measured sections took.
	var used := clampf(_budget.budget_used(), 0.0, 1.5)
	draw_rect(Rect2(16, 300, 600, 18), Color(0.16, 0.17, 0.22))
	draw_rect(Rect2(16, 300, 600.0 * minf(used, 1.0) / 1.5, 18),
		Color(0.85, 0.3, 0.3) if _budget.over_budget() else Color(0.3, 0.75, 0.45))
	draw_line(Vector2(16 + 600.0 / 1.5, 296), Vector2(16 + 600.0 / 1.5, 322),
		Color(0.9, 0.9, 0.5), 2.0)
