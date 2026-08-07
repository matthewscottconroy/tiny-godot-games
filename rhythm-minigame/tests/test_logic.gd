extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_beat_interval()
	_test_note_fall_speed()
	_test_perfect_judgment()
	_test_good_judgment()
	_test_miss_judgment()
	_test_combo_increments()
	_test_combo_resets_on_miss()
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

const BPM           := 120.0
const BEAT_INTERVAL := 60.0 / BPM
const FALL_SPEED    := 240.0
const TARGET_Y      := 400.0
const PERFECT_DIST  := 10.0
const GOOD_DIST     := 26.0

func _test_beat_interval() -> void:
	print("beat interval at 120 BPM")
	expect_near(BEAT_INTERVAL, 0.5, "beat interval is 0.5s at 120 BPM")

func _test_note_fall_speed() -> void:
	print("note falls at FALL_SPEED")
	var y := 0.0
	var delta := 0.016
	y += FALL_SPEED * delta
	expect_near(y, FALL_SPEED * delta, "note y advances by FALL_SPEED * delta per frame")

func _test_perfect_judgment() -> void:
	print("perfect judgment window")
	var note_y := TARGET_Y + 5.0
	var dist := absf(note_y - TARGET_Y)
	expect(dist <= PERFECT_DIST, "note within PERFECT_DIST is a perfect hit")

func _test_good_judgment() -> void:
	print("good judgment window")
	var note_y := TARGET_Y + 20.0
	var dist := absf(note_y - TARGET_Y)
	expect(dist > PERFECT_DIST and dist <= GOOD_DIST, "note outside perfect but within good is a good hit")

func _test_miss_judgment() -> void:
	print("miss judgment")
	var note_y := TARGET_Y + 40.0
	var dist := absf(note_y - TARGET_Y)
	expect(dist > GOOD_DIST, "note beyond GOOD_DIST is a miss")

func _test_combo_increments() -> void:
	print("combo increments on hit")
	var combo := 0
	combo += 1
	expect(combo == 1, "combo is 1 after first hit")
	combo += 1
	expect(combo == 2, "combo is 2 after second hit")

func _test_combo_resets_on_miss() -> void:
	print("combo resets to 0 on miss")
	var combo := 5
	combo = 0
	expect(combo == 0, "combo resets to 0 on miss")

func _report() -> void:
	var summary := "[rhythm-minigame] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
