extends Node

var _pass: int = 0
var _fail: int = 0

func expect(condition: bool, label: String) -> void:
	if condition:
		_pass += 1
		print("  PASS: " + label)
	else:
		_fail += 1
		print("  FAIL: " + label)

func _report() -> void:
	print("Results: %d passed, %d failed" % [_pass, _fail])

# --- Constants mirroring main.gd ---
const COLS := 20
const ROWS := 15

# --- Logic helpers ---

func _cell_visible(cell_noise: float, threshold: float) -> bool:
	return cell_noise > threshold

func _edge_glow_active(cell_noise: float, threshold: float) -> bool:
	return abs(cell_noise - threshold) < 0.1 and cell_noise > threshold

func _clamp_threshold(t: float) -> float:
	return clampf(t, 0.0, 1.0)

# --- Tests ---

func _test_cell_visible_below_threshold() -> void:
	# cell_noise=0.8 > threshold=0.5 → visible
	var visible = _cell_visible(0.8, 0.5)
	expect(visible == true, "cell_visible: noise 0.8 > threshold 0.5 → visible")

func _test_cell_hidden_above_threshold() -> void:
	# cell_noise=0.3 < threshold=0.5 → hidden
	var visible = _cell_visible(0.3, 0.5)
	expect(visible == false, "cell_hidden: noise 0.3 < threshold 0.5 → hidden")

func _test_edge_glow() -> void:
	# cell_noise=0.52, threshold=0.5 → difference is 0.02 < 0.1 → edge glow
	var glow = _edge_glow_active(0.52, 0.5)
	expect(glow == true, "edge_glow: noise 0.52 within 0.1 of threshold 0.5 → glow active")
	# cell_noise=0.7, threshold=0.5 → difference is 0.2 >= 0.1 → no glow
	var no_glow = _edge_glow_active(0.7, 0.5)
	expect(no_glow == false, "edge_glow: noise 0.7 far from threshold 0.5 → no glow")

func _test_threshold_clamp() -> void:
	# threshold incremented past 1.0 → clamp to 1.0
	var t: float = 0.95
	t += 0.2  # would become 1.15
	t = _clamp_threshold(t)
	expect(t == 1.0, "threshold_clamp: value past 1.0 clamped to 1.0")
	# threshold decremented below 0.0 → clamp to 0.0
	var t2: float = 0.05
	t2 -= 0.2  # would become -0.15
	t2 = _clamp_threshold(t2)
	expect(t2 == 0.0, "threshold_clamp: value below 0.0 clamped to 0.0")

func _test_grid_size() -> void:
	var expected: int = COLS * ROWS
	expect(expected == 300, "grid_size: COLS*ROWS = 20*15 = 300 cells")
	# Simulate a noise grid
	var noise_grid: Array[float] = []
	noise_grid.resize(COLS * ROWS)
	for i in range(COLS * ROWS):
		noise_grid[i] = 0.5
	expect(noise_grid.size() == 300, "grid_size: noise_grid has 300 entries")

func _ready() -> void:
	print("=== Dissolve Effect Tests ===")
	_test_cell_visible_below_threshold()
	_test_cell_hidden_above_threshold()
	_test_edge_glow()
	_test_threshold_clamp()
	_test_grid_size()
	_report()
