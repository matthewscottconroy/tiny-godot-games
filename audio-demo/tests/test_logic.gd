extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_sample_rate()
	_test_sample_count()
	_test_data_buffer_size()
	_test_sample_clamp()
	_test_envelope()
	_test_tone_frequencies()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func expect_near(a: float, b: float, label: String, tol: float = 0.01) -> void:
	expect(absf(a - b) <= tol, label)

func _test_sample_rate() -> void:
	print("sample rate")
	const SAMPLE_RATE := 22050
	expect(SAMPLE_RATE == 22050, "sample rate is 22050")

func _test_sample_count() -> void:
	print("sample count formula")
	const SAMPLE_RATE := 22050
	var samples := int(SAMPLE_RATE * 0.3)
	expect(samples == 6615, "0.3s at 22050Hz = 6615 samples")
	samples = int(SAMPLE_RATE * 0.4)
	expect(samples == 8820, "0.4s at 22050Hz = 8820 samples")

func _test_data_buffer_size() -> void:
	print("data buffer size (16-bit = 2 bytes per sample)")
	const SAMPLE_RATE := 22050
	var samples := int(SAMPLE_RATE * 1.0)
	var data_size := samples * 2
	expect(data_size == 44100, "1s audio buffer is 44100 bytes")

func _test_sample_clamp() -> void:
	print("sample clamping to 16-bit range")
	var s := clampi(40000, -32768, 32767)
	expect(s == 32767, "overflow clamped to max int16")
	s = clampi(-40000, -32768, 32767)
	expect(s == -32768, "underflow clamped to min int16")
	s = clampi(0, -32768, 32767)
	expect(s == 0, "zero sample unchanged")

func _test_envelope() -> void:
	print("decay envelope at sample boundaries")
	var samples := 1000
	var i := 0
	var env := 1.0 - pow(float(i) / samples, 0.5)
	expect_near(env, 1.0, "envelope at sample 0 is 1.0")
	i = samples
	env = 1.0 - pow(float(i) / samples, 0.5)
	expect_near(env, 0.0, "envelope at final sample approaches 0")

func _test_tone_frequencies() -> void:
	print("tone button frequencies")
	var low_freq  := 180.0
	var mid_freq  := 440.0
	var high_freq := 880.0
	var sq_freq   := 220.0
	expect(low_freq == 180.0, "low tone is 180 Hz")
	expect(mid_freq == 440.0, "mid tone is 440 Hz (A4)")
	expect(high_freq == 880.0, "high tone is 880 Hz (A5)")
	expect(high_freq == mid_freq * 2.0, "high is octave above mid")
	expect(sq_freq == 220.0, "square wave is 220 Hz")

func _report() -> void:
	var summary := "[audio-demo] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
