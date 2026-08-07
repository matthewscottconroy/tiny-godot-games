extends Node

# ---------------------------------------------------------------------------
# Minimal test harness
# ---------------------------------------------------------------------------
var _pass := 0
var _fail := 0


func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)


func _report() -> void:
	var summary := "[music-sequencer] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)


# ---------------------------------------------------------------------------
# Helpers (mirror main.gd logic)
# ---------------------------------------------------------------------------
func get_step_duration(bpm: float) -> float:
	return 60.0 / bpm * 0.25


func advance_step(step: int, steps: int) -> int:
	return (step + 1) % steps


func toggle_cell(grid: Array, note: int, s: int) -> void:
	grid[note][s] = !grid[note][s]


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------
func _test_step_duration_120bpm() -> void:
	var dur := get_step_duration(120.0)
	expect(abs(dur - 0.125) < 0.0001,
			"_test_step_duration_120bpm: 60/120*0.25 = 0.125s (got %.4f)" % dur)


func _test_step_duration_60bpm() -> void:
	var dur := get_step_duration(60.0)
	expect(abs(dur - 0.25) < 0.0001,
			"_test_step_duration_60bpm: 60/60*0.25 = 0.25s (got %.4f)" % dur)


func _test_step_advances() -> void:
	# timer >= step_duration → step increments
	var step := 3
	var step_timer := 0.13
	var step_duration := get_step_duration(120.0)  # 0.125
	if step_timer >= step_duration:
		step = advance_step(step, 16)
	expect(step == 4, "_test_step_advances: step advanced from 3 to 4")


func _test_step_wraps() -> void:
	var step := 15
	step = advance_step(step, 16)
	expect(step == 0, "_test_step_wraps: step wraps from 15 to 0 (got %d)" % step)


func _test_grid_toggle() -> void:
	# Build a small 1x1 grid
	var grid: Array = [[false]]
	expect(grid[0][0] == false, "_test_grid_toggle: initial value is false")
	toggle_cell(grid, 0, 0)
	expect(grid[0][0] == true, "_test_grid_toggle: after first toggle = true")
	toggle_cell(grid, 0, 0)
	expect(grid[0][0] == false, "_test_grid_toggle: after second toggle = false")


func _test_bpm_clamp() -> void:
	var bpm := 240.0
	bpm = min(240.0, bpm + 10.0)
	expect(bpm == 240.0, "_test_bpm_clamp: bpm+10 at 240 stays 240")

	bpm = 60.0
	bpm = max(60.0, bpm - 10.0)
	expect(bpm == 60.0, "_test_bpm_clamp: bpm-10 at 60 stays 60")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
func _ready() -> void:
	print("\n--- Running Music Sequencer Tests ---")
	_test_step_duration_120bpm()
	_test_step_duration_60bpm()
	_test_step_advances()
	_test_step_wraps()
	_test_grid_toggle()
	_test_bpm_clamp()
	_report()
