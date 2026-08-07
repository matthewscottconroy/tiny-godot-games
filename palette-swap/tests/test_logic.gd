extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_exact_match_swaps()
	test_close_match_swaps()
	test_far_color_unchanged()
	test_transparent_pixel_unchanged()
	test_palette_cycle_wraps()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[palette-swap] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const THRESHOLD := 0.18
const PALETTES  := 5

func _swap(pixel: Color, src: Color, dst: Color, threshold: float) -> Color:
	if pixel.a < 0.01:
		return pixel
	if pixel.rgb.distance_to(src.rgb) < threshold:
		return Color(dst.r, dst.g, dst.b, pixel.a)
	return pixel

func test_exact_match_swaps() -> void:
	var src := Color(0.12, 0.56, 1.0)
	var dst := Color(0.85, 0.12, 0.12)
	var out := _swap(Color(0.12, 0.56, 1.0, 1.0), src, dst, THRESHOLD)
	expect(out.r > 0.8, "exact source color is swapped to destination")

func test_close_match_swaps() -> void:
	var src := Color(0.12, 0.56, 1.0)
	var dst := Color(1.0, 0.0, 0.0)
	var pixel := Color(0.13, 0.55, 0.99, 1.0)  # very close to src
	var out := _swap(pixel, src, dst, THRESHOLD)
	expect(out.r > 0.9, "pixel close to source color is swapped")

func test_far_color_unchanged() -> void:
	var src := Color(0.12, 0.56, 1.0)
	var dst := Color(1.0, 0.0, 0.0)
	var pixel := Color(1.0, 0.84, 0.0, 1.0)  # gold, far from blue
	var out := _swap(pixel, src, dst, THRESHOLD)
	expect(absf(out.r - pixel.r) < 0.01, "color far from source is not swapped")

func test_transparent_pixel_unchanged() -> void:
	var src := Color(0.12, 0.56, 1.0)
	var dst := Color(1.0, 0.0, 0.0)
	var pixel := Color(0.12, 0.56, 1.0, 0.0)  # alpha=0
	var out := _swap(pixel, src, dst, THRESHOLD)
	expect(out.a < 0.01, "transparent pixel passes through unchanged")

func test_palette_cycle_wraps() -> void:
	var idx := PALETTES - 1
	idx = (idx + 1) % PALETTES
	expect(idx == 0, "palette index wraps to 0 after last palette")
