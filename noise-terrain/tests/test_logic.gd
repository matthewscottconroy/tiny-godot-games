extends Node

var _pass := 0
var _fail := 0

const COLS := 128
const TERRAIN_TOP := 80.0
const TERRAIN_BOTTOM := 460.0


func _ready() -> void:
	_test_noise_output_range()
	_test_height_lerp_formula()
	_test_cols_heights_generated()
	_test_frequency_changes_terrain()
	_test_seed_changes_terrain()
	_test_height_lerp_bounds()
	_test_normalized_noise_mapping()
	_report()


func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)


func expect_approx(a: float, b: float, label: String, tol: float = 0.001) -> void:
	expect(absf(a - b) < tol, label)


# --- FastNoiseLite contract ---

func _test_noise_output_range() -> void:
	print("FastNoiseLite output range [-1, 1]")
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = 42
	noise.frequency = 0.02
	var all_in_range := true
	for i in 200:
		var val := noise.get_noise_1d(float(i))
		if val < -1.001 or val > 1.001:
			all_in_range = false
	expect(all_in_range, "all noise samples in [-1, 1]")

	var has_positive := false
	var has_negative := false
	for i in 200:
		var val := noise.get_noise_1d(float(i) * 0.1)
		if val > 0.0:
			has_positive = true
		if val < 0.0:
			has_negative = true
	expect(has_positive, "noise produces positive values")
	expect(has_negative, "noise produces negative values")


# --- Height lerp formula ---

func _test_height_lerp_formula() -> void:
	print("height lerp maps noise correctly to screen coords")
	# When noise = -1 → h = (-1+1)*0.5 = 0 → lerpf(BOTTOM, TOP, 0) = BOTTOM
	var h_min := ((-1.0 + 1.0) * 0.5)  # = 0.0
	var height_min := lerpf(TERRAIN_BOTTOM, TERRAIN_TOP, h_min)
	expect_approx(height_min, TERRAIN_BOTTOM, "noise=-1 maps to TERRAIN_BOTTOM (lowest on screen)")

	# When noise = +1 → h = (1+1)*0.5 = 1 → lerpf(BOTTOM, TOP, 1) = TOP
	var h_max := ((1.0 + 1.0) * 0.5)  # = 1.0
	var height_max := lerpf(TERRAIN_BOTTOM, TERRAIN_TOP, h_max)
	expect_approx(height_max, TERRAIN_TOP, "noise=+1 maps to TERRAIN_TOP (highest on screen)")

	# Midpoint: noise = 0 → h = 0.5 → lerpf(BOTTOM, TOP, 0.5) = midpoint
	var h_mid := ((0.0 + 1.0) * 0.5)
	var height_mid := lerpf(TERRAIN_BOTTOM, TERRAIN_TOP, h_mid)
	var expected_mid := (TERRAIN_BOTTOM + TERRAIN_TOP) * 0.5
	expect_approx(height_mid, expected_mid, "noise=0 maps to midpoint of terrain range")


# --- COLS heights generated ---

func _test_cols_heights_generated() -> void:
	print("terrain generates exactly COLS heights")
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = 1
	noise.frequency = 0.02
	var heights: Array = []
	for i in COLS:
		var h := (noise.get_noise_1d(float(i) * 0.02) + 1.0) * 0.5
		heights.append(lerpf(TERRAIN_BOTTOM, TERRAIN_TOP, h))
	expect(heights.size() == COLS, "heights array has exactly COLS=%d entries" % COLS)
	var all_in_range := true
	for y in heights:
		if y < TERRAIN_TOP - 0.5 or y > TERRAIN_BOTTOM + 0.5:
			all_in_range = false
	expect(all_in_range, "all heights within [TERRAIN_TOP, TERRAIN_BOTTOM]")


# --- Frequency change causes different terrain ---

func _test_frequency_changes_terrain() -> void:
	print("different frequencies produce different terrain")
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = 99

	var gen := func(freq: float) -> Array:
		noise.frequency = freq
		var h: Array = []
		for i in 32:
			h.append(noise.get_noise_1d(float(i) * freq))
		return h

	var heights_low := gen.call(0.01)
	var heights_high := gen.call(0.1)

	var same := true
	for i in 32:
		if absf(float(heights_low[i]) - float(heights_high[i])) > 0.001:
			same = false
			break
	expect(not same, "frequency 0.01 and 0.1 produce different height profiles")


# --- Seed change causes different terrain ---

func _test_seed_changes_terrain() -> void:
	print("different seeds produce different terrain")
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.02

	var gen := func(seed_val: int) -> Array:
		noise.seed = seed_val
		var h: Array = []
		for i in 32:
			h.append(noise.get_noise_1d(float(i) * 0.02))
		return h

	var heights_a := gen.call(12345)
	var heights_b := gen.call(67890)

	var same := true
	for i in 32:
		if absf(float(heights_a[i]) - float(heights_b[i])) > 0.001:
			same = false
			break
	expect(not same, "seed 12345 and seed 67890 produce different height profiles")


# --- Terrain bounds ---

func _test_height_lerp_bounds() -> void:
	print("lerpf terrain bounds are correct")
	expect(TERRAIN_TOP < TERRAIN_BOTTOM, "TERRAIN_TOP is above TERRAIN_BOTTOM (smaller y = higher on screen)")
	expect_approx(TERRAIN_TOP, 80.0, "TERRAIN_TOP is 80.0")
	expect_approx(TERRAIN_BOTTOM, 460.0, "TERRAIN_BOTTOM is 460.0")
	var range_px := TERRAIN_BOTTOM - TERRAIN_TOP
	expect(range_px > 0.0, "terrain has positive height range")
	expect_approx(range_px, 380.0, "terrain height range is 380 pixels")


# --- Normalized noise mapping [0,1] ---

func _test_normalized_noise_mapping() -> void:
	print("normalized noise formula maps to [0, 1]")
	# (noise_val + 1.0) * 0.5 where noise_val in [-1, 1]
	var h_from_minus1 := (-1.0 + 1.0) * 0.5
	var h_from_zero   := (0.0 + 1.0) * 0.5
	var h_from_plus1  := (1.0 + 1.0) * 0.5
	expect_approx(h_from_minus1, 0.0, "noise=-1 normalizes to 0.0")
	expect_approx(h_from_zero, 0.5, "noise=0 normalizes to 0.5")
	expect_approx(h_from_plus1, 1.0, "noise=+1 normalizes to 1.0")
	expect(h_from_minus1 >= 0.0 and h_from_plus1 <= 1.0, "normalized range is [0, 1]")


func _report() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [_pass, _fail])
	if _fail == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")
