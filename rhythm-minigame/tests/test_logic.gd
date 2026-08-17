extends Node

# Drives the real game from scripts/main.gd — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_it_starts_empty()
	_test_notes_fall()
	_test_a_note_dead_on_the_line_is_perfect()
	_test_a_note_near_the_line_is_good()
	_test_a_note_nowhere_near_the_line_is_a_miss()
	_test_pressing_with_no_notes_is_a_miss()
	_test_a_note_can_only_be_hit_once()
	_test_the_nearest_note_is_the_one_judged()
	_test_a_note_falling_past_the_line_is_a_miss()
	_test_the_combo_builds_and_breaks()
	_test_a_longer_combo_is_worth_more()
	_test_notes_spawn_on_the_beat()
	_test_the_feedback_fades()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[rhythm-minigame] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const STEP := 1.0 / 60.0
var _script: GDScript = load("res://scripts/main.gd")

func _make() -> Node2D:
	var m: Node2D = _script.new()
	add_child(m)
	return m

## One note, placed a given distance short of the target line.
func _note_at(m: Node2D, y: float) -> Dictionary:
	var note := {"y": y, "hit": false}
	m._notes.append(note)
	return note

func _press_space(m: Node2D) -> void:
	var e := InputEventKey.new()
	e.keycode = KEY_SPACE
	e.pressed = true
	m._input(e)

func _test_it_starts_empty() -> void:
	print("the opening bar")
	var m := _make()
	expect(m._notes.is_empty(), "no notes on screen yet")
	expect(m._score == 0 and m._combo == 0, "and nothing scored")

func _test_notes_fall() -> void:
	print("falling")
	var m := _make()
	var note := _note_at(m, 100.0)
	m._process(STEP)
	expect(note["y"] > 100.0, "a note moves down the track")
	expect(is_equal_approx(note["y"], 100.0 + m.FALL_SPEED * STEP), "at the fall speed")

func _test_a_note_dead_on_the_line_is_perfect() -> void:
	print("perfect")
	var m := _make()
	var note := _note_at(m, m.TARGET_Y)
	_press_space(m)
	expect(m._feedback == "PERFECT!", "a note exactly on the line is perfect")
	expect(m._score > 100, "worth more than a good hit")
	expect(note["hit"], "and the note is spent")

func _test_a_note_near_the_line_is_good() -> void:
	print("good")
	var m := _make()
	_note_at(m, m.TARGET_Y + (m.PERFECT_DIST + m.GOOD_DIST) * 0.5)
	_press_space(m)
	expect(m._feedback == "GOOD", "a note inside the outer ring is good")
	expect(m._score == 50, "worth a flat fifty")

func _test_a_note_nowhere_near_the_line_is_a_miss() -> void:
	print("too early")
	var m := _make()
	var note := _note_at(m, m.TARGET_Y - m.GOOD_DIST * 3.0)
	_press_space(m)
	expect(m._feedback == "MISS", "hitting well before the note arrives is a miss")
	expect(m._score == 0, "and scores nothing")
	expect(not note["hit"], "the note stays in play")

func _test_pressing_with_no_notes_is_a_miss() -> void:
	print("mashing")
	var m := _make()
	_press_space(m)
	expect(m._feedback == "MISS", "pressing with an empty track is a miss")

func _test_a_note_can_only_be_hit_once() -> void:
	print("double hits")
	var m := _make()
	_note_at(m, m.TARGET_Y)
	_press_space(m)
	var scored: int = m._score
	_press_space(m)
	expect(m._score == scored, "hitting a spent note again scores nothing")
	expect(m._feedback == "MISS", "it counts as a miss instead")

func _test_the_nearest_note_is_the_one_judged() -> void:
	print("choosing a note")
	var m := _make()
	var far := _note_at(m, m.TARGET_Y - 200.0)
	var near := _note_at(m, m.TARGET_Y + 2.0)
	_press_space(m)
	expect(near["hit"], "the note closest to the line is the one hit")
	expect(not far["hit"], "not the one still on its way down")

func _test_a_note_falling_past_the_line_is_a_miss() -> void:
	print("letting one go")
	var m := _make()
	_note_at(m, m.TARGET_Y + m.GOOD_DIST * 2.0 + 1.0)
	m._combo = 5
	m._process(STEP)
	expect(m._feedback == "MISS", "a note that falls past the line is missed")
	expect(m._combo == 0, "which breaks the combo")
	var live := 0
	for note in m._notes:
		if not note["hit"]:
			live += 1
	expect(live == 0, "and the note is taken off the track")

func _test_the_combo_builds_and_breaks() -> void:
	print("the combo")
	var m := _make()
	for i in 3:
		_note_at(m, m.TARGET_Y)
		_press_space(m)
	expect(m._combo == 3, "three hits in a row is a three-combo")
	_press_space(m)
	expect(m._combo == 0, "and one miss resets it to nothing")

func _test_a_longer_combo_is_worth_more() -> void:
	print("combo scoring")
	var m := _make()
	_note_at(m, m.TARGET_Y)
	_press_space(m)
	var first: int = m._score

	var later := _make()
	later._combo = 10
	_note_at(later, later.TARGET_Y)
	_press_space(later)
	expect(later._score > first, "the same note is worth more deep into a combo")

func _test_notes_spawn_on_the_beat() -> void:
	print("the beat")
	var m := _make()
	# Not every beat spawns a note, so this counts beats' worth of time rather
	# than expecting one note per beat.
	for i in int(m.BEAT_INTERVAL * 60.0) * 8:
		m._process(STEP)
	expect(m._notes.size() > 0, "notes appear as the beats go by")
	expect(m._notes.size() <= 8, "at most one per beat")
	var playable := 0
	for note in m._notes:
		if not note["hit"]:
			playable += 1
	expect(playable == m._notes.size(), "and every one of them is still there to be hit")

func _test_the_feedback_fades() -> void:
	print("the feedback flash")
	var m := _make()
	_note_at(m, m.TARGET_Y)
	_press_space(m)
	expect(m._feedback_t > 0.0, "a judgement puts a word on screen")
	var first: float = m._feedback_t
	m._process(STEP)
	expect(m._feedback_t < first, "which starts fading immediately")
	for i in 120:
		m._process(STEP)
	expect(is_zero_approx(m._feedback_t), "and is gone a second later")
