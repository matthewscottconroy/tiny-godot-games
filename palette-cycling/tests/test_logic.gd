extends Node

var _pass := 0
var _fail := 0

const COLS := 40
const ROWS := 30

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[palette-cycling] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

func _test_index_shift() -> void:
	print("TEST: index shift basic")
	var raw_idx := 3
	var offset := 5.0
	var shifted := int(raw_idx + offset) % 16
	expect(shifted == 8, "3 + 5 offset = index 8")

func _test_index_wrap() -> void:
	print("TEST: index wraps around 16")
	var raw_idx := 14
	var offset := 5.0
	var shifted := int(raw_idx + offset) % 16
	expect(shifted == 3, "14 + 5 wraps to 3")

func _test_offset_cycles() -> void:
	print("TEST: palette offset cycles at 16")
	var offset := 16.0
	var result := fmod(offset, 16.0)
	expect(result == 0.0, "fmod(16.0, 16.0) == 0.0")
	offset = 17.5
	result = fmod(offset, 16.0)
	expect(abs(result - 1.5) < 0.0001, "fmod(17.5, 16.0) == 1.5")

func _test_palette_size() -> void:
	print("TEST: palette has 16 entries")
	# Build all three palettes and verify each has 16 entries
	for pattern in range(3):
		var palette: Array[Color] = []
		match pattern:
			0:
				var stops := [
					Color(0.0, 0.0, 0.35), Color(0.0, 0.1, 0.6), Color(0.0, 0.3, 0.8),
					Color(0.0, 0.55, 0.9), Color(0.1, 0.75, 1.0), Color(0.3, 0.88, 1.0),
					Color(0.6, 0.95, 1.0), Color(0.85, 1.0, 1.0), Color(1.0, 1.0, 1.0),
					Color(0.85, 1.0, 1.0), Color(0.6, 0.95, 1.0), Color(0.3, 0.88, 1.0),
					Color(0.1, 0.75, 1.0), Color(0.0, 0.55, 0.9), Color(0.0, 0.3, 0.8),
					Color(0.0, 0.1, 0.6)
				]
				palette.assign(stops)
			1:
				var stops := [
					Color(0.0, 0.0, 0.0), Color(0.2, 0.0, 0.0), Color(0.4, 0.03, 0.0),
					Color(0.6, 0.05, 0.0), Color(0.8, 0.1, 0.0), Color(0.9, 0.25, 0.0),
					Color(1.0, 0.4, 0.0), Color(1.0, 0.6, 0.05), Color(1.0, 0.8, 0.1),
					Color(1.0, 0.95, 0.5), Color(1.0, 1.0, 0.9), Color(1.0, 0.95, 0.5),
					Color(1.0, 0.8, 0.1), Color(1.0, 0.4, 0.0), Color(0.7, 0.1, 0.0),
					Color(0.3, 0.02, 0.0)
				]
				palette.assign(stops)
			2:
				for i in range(16):
					palette.append(Color.from_hsv(float(i) / 16.0, 0.9, 1.0))
		var pattern_names := ["water", "lava", "rainbow"]
		expect(palette.size() == 16, "palette size == 16 for pattern: " + pattern_names[pattern])

func _test_index_map_size() -> void:
	print("TEST: index map size")
	var index_map := PackedByteArray()
	index_map.resize(COLS * ROWS)
	expect(index_map.size() == 1200, "index_map.size() == COLS*ROWS == 1200")
	expect(COLS * ROWS == 1200, "40 * 30 == 1200")

func _ready() -> void:
	print("=== Palette Cycling Tests ===")
	_test_index_shift()
	_test_index_wrap()
	_test_offset_cycles()
	_test_palette_size()
	_test_index_map_size()
	_report()
