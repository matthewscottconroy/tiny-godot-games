extends Node2D

const BPM              := 120.0
const BEAT_INTERVAL    := 60.0 / BPM
const FALL_SPEED       := 240.0
const SPAWN_Y          := -20.0
const TARGET_Y         := 400.0
const LANE_X           := 320.0
const PERFECT_DIST     := 10.0
const GOOD_DIST        := 26.0
const NOTE_RADIUS      := 18.0
const NOTE_SPAWN_CHANCE := 0.75

var _notes: Array[Dictionary] = []
var _beat_timer   := 0.0
var _score        := 0
var _combo        := 0
var _feedback     := ""
var _feedback_col := Color.WHITE
var _feedback_t   := 0.0

func _process(delta: float) -> void:
	_beat_timer += delta
	if _beat_timer >= BEAT_INTERVAL:
		_beat_timer -= BEAT_INTERVAL
		if randf() < NOTE_SPAWN_CHANCE:
			_notes.append({"y": SPAWN_Y, "hit": false})

	for note in _notes:
		if not note["hit"]:
			note["y"] += FALL_SPEED * delta

	_notes = _notes.filter(func(n: Dictionary) -> bool:
		if not n["hit"] and n["y"] > TARGET_Y + GOOD_DIST * 2.0:
			_miss()
			return false
		return n["y"] < 520.0)

	_feedback_t = maxf(_feedback_t - delta, 0.0)
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			_judge()

func _judge() -> void:
	var best_note: Dictionary = {}
	var best_dist := 9999.0
	for note in _notes:
		if note["hit"]:
			continue
		var d := absf(note["y"] - TARGET_Y)
		if d < best_dist:
			best_dist = d
			best_note = note

	if best_note.is_empty():
		_miss()
		return

	if best_dist <= PERFECT_DIST:
		_combo += 1
		_score += 100 + _combo * 5
		_set_feedback("PERFECT!", Color.GOLD)
		best_note["hit"] = true
	elif best_dist <= GOOD_DIST:
		_combo += 1
		_score += 50
		_set_feedback("GOOD", Color.LIME_GREEN)
		best_note["hit"] = true
	else:
		_miss()

func _miss() -> void:
	_combo = 0
	_set_feedback("MISS", Color.TOMATO)

func _set_feedback(text: String, col: Color) -> void:
	_feedback     = text
	_feedback_col = col
	_feedback_t   = 0.55

func _draw() -> void:
	# Track line
	draw_line(Vector2(LANE_X, 0), Vector2(LANE_X, 480), Color(1,1,1,0.08), 2)

	# Target zone rings
	draw_arc(Vector2(LANE_X, TARGET_Y), GOOD_DIST, 0, TAU, 32, Color(0.3,0.9,0.3,0.4), 1.5)
	draw_arc(Vector2(LANE_X, TARGET_Y), PERFECT_DIST, 0, TAU, 24, Color(1,0.9,0.2,0.6), 2.0)
	draw_line(Vector2(LANE_X - 40, TARGET_Y), Vector2(LANE_X + 40, TARGET_Y), Color(1,1,1,0.7), 2)

	# Notes
	for note in _notes:
		var col := Color(0.4, 0.4, 0.4, 0.4) if note["hit"] else Color.WHITE
		draw_circle(Vector2(LANE_X, note["y"]), NOTE_RADIUS, col)
		draw_arc(Vector2(LANE_X, note["y"]), NOTE_RADIUS, 0, TAU, 24, Color.BLACK, 2.0)

	# Feedback
	if _feedback_t > 0.0:
		var alpha := minf(_feedback_t * 2.0, 1.0)
		var col   := Color(_feedback_col.r, _feedback_col.g, _feedback_col.b, alpha)
		draw_string(ThemeDB.fallback_font, Vector2(LANE_X - 35, TARGET_Y - 50),
			_feedback, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, col)

	# HUD
	draw_string(ThemeDB.fallback_font, Vector2(8, 20),
		"Score: %d  Combo: x%d" % [_score, _combo], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(8, 465),
		"Space = hit note", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1,1,1,0.5))
