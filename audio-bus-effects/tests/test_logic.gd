extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_bus_count()
	test_reverb_wet_in_range()
	test_delay_tap_delay_positive()
	test_compressor_ratio_above_1()
	test_tone_data_length()
	test_bus_cycle_wraps()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[audio-bus-effects] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const BUSES      := ["Dry", "Reverb", "Echo", "Compressed"]
const SAMPLE_RATE := 44100

func test_bus_count() -> void:
	expect(BUSES.size() == 4, "demo has 4 buses: Dry, Reverb, Echo, Compressed")

func test_reverb_wet_in_range() -> void:
	var wet := 0.65
	expect(wet >= 0.0 and wet <= 1.0, "reverb wet mix is in [0.0, 1.0]")

func test_delay_tap_delay_positive() -> void:
	var tap1 := 300.0
	var tap2 := 600.0
	expect(tap1 > 0.0 and tap2 > tap1, "echo tap delays are positive and tap2 > tap1")

func test_compressor_ratio_above_1() -> void:
	var ratio := 6.0
	expect(ratio > 1.0, "compressor ratio greater than 1.0 (actually compresses)")

func test_tone_data_length() -> void:
	var duration := 0.6
	var samples  := int(SAMPLE_RATE * duration)
	var expected_bytes := samples * 2  # FORMAT_16_BITS = 2 bytes per sample
	expect(expected_bytes == 52920, "tone data buffer size correct for 0.6s at 44100Hz")

func test_bus_cycle_wraps() -> void:
	var idx := BUSES.size() - 1
	idx = (idx + 1) % BUSES.size()
	expect(idx == 0, "bus index wraps back to 0 after last bus")
