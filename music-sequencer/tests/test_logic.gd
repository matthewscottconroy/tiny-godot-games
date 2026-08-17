extends Node

# Drives the real sequencer from scenes/main.tscn — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_grid_is_laid_out()
	_test_it_starts_on_a_pattern()
	_test_the_playhead_walks_the_bar_and_loops()
	_test_a_step_plays_the_notes_switched_on_for_it()
	_test_a_silent_step_plays_nothing()
	_test_the_tempo_sets_the_step_length()
	_test_space_stops_and_starts_the_playhead()
	_test_the_tempo_keys_have_limits()
	_test_clicking_a_cell_toggles_it()
	_test_the_grid_is_drawn_low_note_at_the_bottom()
	_test_clicks_outside_the_grid_are_ignored()
	_test_c_clears_the_pattern()
	_report()

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

var _scene: Node2D

func _make() -> Node2D:
	if is_instance_valid(_scene):
		remove_child(_scene)
		_scene.free()
	_scene = load("res://scenes/main.tscn").instantiate()
	add_child(_scene)
	return _scene

## The middle of the cell for `note` at `step`, in screen coordinates.
func _cell_centre(m: Node2D, note: int, step: int) -> Vector2:
	var row: int = (m.NOTES - 1) - note
	return Vector2(m.GRID_X + (step + 0.5) * m.CELL_W, m.GRID_Y + (row + 0.5) * m.CELL_H)

func _click(m: Node2D, at: Vector2) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	e.position = at
	m._input(e)

func _key(m: Node2D, code: Key) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.pressed = true
	m._input(e)

func _clear(m: Node2D) -> void:
	for n in m.NOTES:
		for s in m.STEPS:
			m._grid[n][s] = false

func _test_the_grid_is_laid_out() -> void:
	print("the grid")
	var m := _make()
	expect(m._grid.size() == m.NOTES, "a row per note")
	expect(m._grid[0].size() == m.STEPS, "and a column per step")
	expect(m.FREQUENCIES.size() == m.NOTES, "every row has a pitch")
	expect(m.NOTE_NAMES.size() == m.NOTES, "and a name")
	var rising := true
	for i in m.NOTES - 1:
		if m.FREQUENCIES[i] >= m.FREQUENCIES[i + 1]:
			rising = false
	expect(rising, "with the pitches rising up the grid")

func _test_it_starts_on_a_pattern() -> void:
	print("the seed pattern")
	var m := _make()
	var lit := 0
	for row in m._grid:
		for on in row:
			if on:
				lit += 1
	expect(lit > 0, "the sequencer opens with something to hear")
	expect(m._playing, "and already running")

	# Enough of a pattern to demonstrate the thing: a bass line on the lowest
	# row, a chord on the downbeat, and something between the beats.
	var voices := 0
	for row in m._grid:
		for on in row:
			if on:
				voices += 1
				break
	expect(voices >= 3, "with several voices, not a single row")

	var bass := 0
	for on in m._grid[0]:
		if on:
			bass += 1
	expect(bass > 0, "the lowest note carries a bass line")

	var downbeat := 0
	for note in m.NOTES:
		if m._grid[note][0]:
			downbeat += 1
	expect(downbeat >= 2, "the bar opens on a chord rather than one note")

	var offbeat := false
	for note in m.NOTES:
		for step in m.STEPS:
			if m._grid[note][step] and step % 2 == 1:
				offbeat = true
	var between := false
	for note in m.NOTES:
		if m._grid[note][2] or m._grid[note][6]:
			between = true
	expect(offbeat or between, "and something lands between the beats")

func _test_the_playhead_walks_the_bar_and_loops() -> void:
	print("the playhead")
	var m := _make()
	var step_len: float = m._get_step_duration()
	var start: int = m._step
	m._process(step_len * 1.01)
	expect(m._step == (start + 1) % m.STEPS, "a step's worth of time moves the playhead on one")

	for i in m.STEPS:
		m._process(step_len * 1.01)
	expect(m._step == (start + 1) % m.STEPS, "and a bar's worth brings it back round")

func _test_a_step_plays_the_notes_switched_on_for_it() -> void:
	print("what gets played")
	var m := _make()
	_clear(m)
	# Two notes on the step the playhead is about to reach.
	var next: int = (m._step + 1) % m.STEPS
	m._grid[0][next] = true
	m._grid[5][next] = true
	m._advance_step()
	expect(m._active_freqs.size() == 2, "both notes on that step sound")
	expect(m._active_freqs.has(m.FREQUENCIES[0]), "at the pitch of the bottom row")
	expect(m._active_freqs.has(m.FREQUENCIES[5]), "and of the row that was clicked")
	expect(m._note_frames_left > 0, "with a burst of audio queued for them")

func _test_a_silent_step_plays_nothing() -> void:
	print("rests")
	var m := _make()
	_clear(m)
	m._advance_step()
	expect(m._active_freqs.is_empty(), "a step with nothing on it is silent")
	expect(m._note_frames_left == 0, "and queues no audio")

func _test_the_tempo_sets_the_step_length() -> void:
	print("tempo")
	var m := _make()
	var at_120: float = m._get_step_duration()
	m._bpm = 240.0
	expect(m._get_step_duration() < at_120, "a faster tempo makes shorter steps")
	expect(is_equal_approx(m._get_step_duration(), at_120 * 0.5), "twice the tempo, half the step")

func _test_space_stops_and_starts_the_playhead() -> void:
	print("play and pause")
	var m := _make()
	_key(m, KEY_SPACE)
	expect(not m._playing, "space stops the sequencer")
	var stopped_at: int = m._step
	m._process(m._get_step_duration() * 4.0)
	expect(m._step == stopped_at, "and the playhead stays where it was")
	_key(m, KEY_SPACE)
	expect(m._playing, "space again starts it")
	m._process(m._get_step_duration() * 1.01)
	expect(m._step != stopped_at, "and it moves on")

func _test_the_tempo_keys_have_limits() -> void:
	print("tempo limits")
	var m := _make()
	var start: float = m._bpm
	_key(m, KEY_EQUAL)
	expect(m._bpm > start, "= speeds it up")
	_key(m, KEY_MINUS)
	expect(is_equal_approx(m._bpm, start), "and - slows it back down")

	for i in 40:
		_key(m, KEY_EQUAL)
	expect(m._bpm <= 240.0, "the tempo stops at a sensible maximum")
	for i in 60:
		_key(m, KEY_MINUS)
	expect(m._bpm >= 60.0, "and at a minimum — a zero tempo would divide by zero")

func _test_clicking_a_cell_toggles_it() -> void:
	print("editing")
	var m := _make()
	_clear(m)
	_click(m, _cell_centre(m, 3, 6))
	expect(m._grid[3][6], "clicking an empty cell switches the note on")
	_click(m, _cell_centre(m, 3, 6))
	expect(not m._grid[3][6], "and clicking it again switches it off")

func _test_the_grid_is_drawn_low_note_at_the_bottom() -> void:
	print("which row is which")
	var m := _make()
	_clear(m)
	# The lowest note is drawn on the bottom row, so a click near the bottom of
	# the grid has to reach row 0 rather than the top of the array.
	var bottom_row_y: float = m.GRID_Y + (m.NOTES - 0.5) * m.CELL_H
	_click(m, Vector2(m.GRID_X + m.CELL_W * 0.5, bottom_row_y))
	expect(m._grid[0][0], "a click on the bottom row lights the lowest note")
	expect(not m._grid[m.NOTES - 1][0], "not the highest")

func _test_clicks_outside_the_grid_are_ignored() -> void:
	print("off the grid")
	var m := _make()
	_clear(m)
	_click(m, Vector2(m.GRID_X - 30.0, m.GRID_Y + 10.0))
	_click(m, Vector2(m.GRID_X + m.STEPS * m.CELL_W + 30.0, m.GRID_Y + 10.0))
	_click(m, Vector2(m.GRID_X + 10.0, m.GRID_Y - 40.0))
	var lit := 0
	for row in m._grid:
		for on in row:
			if on:
				lit += 1
	expect(lit == 0, "clicks around the edges of the grid switch nothing on")

func _test_c_clears_the_pattern() -> void:
	print("clearing")
	var m := _make()
	_key(m, KEY_C)
	var lit := 0
	for row in m._grid:
		for on in row:
			if on:
				lit += 1
	expect(lit == 0, "C empties the whole grid")
