extends Node

# Drives the real SubtitleQueue from scripts/subtitles.gd.

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_duration_scales_with_length()
	test_duration_has_a_floor_and_ceiling()
	test_first_line_shows_immediately()
	test_second_line_waits()
	test_queue_drains_in_order()
	test_empty_text_is_ignored()
	test_speaker_formatting()
	test_cue_formatting()
	test_cues_can_be_switched_off()
	test_skip_advances()
	test_clear_drops_everything()
	test_signals()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[subtitle-system] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

func _make() -> SubtitleQueue:
	var q := SubtitleQueue.new()
	add_child(q)
	return q

# Age the queue past the visible caption.
func _run_out(q: SubtitleQueue) -> void:
	var guard := 0
	while q.is_showing() and guard < 10000:
		q.update(0.1)
		guard += 1

func test_duration_scales_with_length() -> void:
	print("duration follows reading time")
	var q := _make()
	var short_line := q.duration_for("A short line that is still long enough to scale.")
	var long_line := q.duration_for("A considerably longer line of dialogue that should stay on screen for more time.")
	expect(long_line > short_line, "a longer caption stays up longer")

func test_duration_has_a_floor_and_ceiling() -> void:
	print("duration limits")
	var q := _make()
	expect(is_equal_approx(q.duration_for("Hi."), q.min_duration),
		"a very short line still gets the minimum")
	var wall := ""
	for i in 400:
		wall += "word "
	expect(is_equal_approx(q.duration_for(wall), q.max_duration),
		"a very long line is capped rather than parked forever")

func test_first_line_shows_immediately() -> void:
	print("the first caption appears at once")
	var q := _make()
	q.say("Hello there.", "Guard")
	expect(q.is_showing(), "a caption is on screen")
	expect(q.pending() == 0, "nothing is waiting behind it")

func test_second_line_waits() -> void:
	print("captions do not overlap")
	var q := _make()
	q.say("First line.", "A")
	q.say("Second line.", "B")
	expect(q.current()["text"] == "First line.", "the first is showing")
	expect(q.pending() == 1, "the second is queued, not drawn over the first")

func test_queue_drains_in_order() -> void:
	print("FIFO order")
	var q := _make()
	q.say("one")
	q.say("two")
	q.say("three")
	var seen: Array[String] = []
	var guard := 0
	while q.is_showing() and guard < 10000:
		var text := String(q.current()["text"])
		if seen.is_empty() or seen[-1] != text:
			seen.append(text)
		q.update(0.1)
		guard += 1
	expect(seen == ["one", "two", "three"], "captions play in the order they were queued")
	expect(q.pending() == 0, "the queue is empty afterwards")

func test_empty_text_is_ignored() -> void:
	print("empty captions")
	var q := _make()
	q.say("")
	q.say("   ")
	expect(not q.is_showing(), "blank text never becomes a caption")

func test_speaker_formatting() -> void:
	print("speaker prefix")
	var q := _make()
	q.say("Halt!", "Guard")
	expect(q.current_text() == "Guard: Halt!", "speech is prefixed with the speaker")
	q.clear()
	q.say("The bridge was out.")
	expect(q.current_text() == "The bridge was out.", "a narrator line has no prefix")

func test_cue_formatting() -> void:
	print("sound cues are marked")
	var q := _make()
	q.cue("a door opens")
	expect(q.current_text() == "[a door opens]", "non-speech cues are bracketed")
	expect(q.current()["is_cue"], "and flagged, so a view can style them differently")

func test_cues_can_be_switched_off() -> void:
	print("sound cues respect the setting")
	var q := _make()
	q.sound_cues = false
	q.cue("a door opens")
	expect(not q.is_showing(), "cues are dropped when the player turns them off")
	q.say("But speech still shows.", "A")
	expect(q.is_showing(), "speech is unaffected by the cue setting")

func test_skip_advances() -> void:
	print("skip")
	var q := _make()
	q.say("first")
	q.say("second")
	q.skip()
	expect(q.current()["text"] == "second", "skipping moves to the next caption")
	q.skip()
	expect(not q.is_showing(), "skipping the last one leaves nothing showing")
	q.skip()
	expect(not q.is_showing(), "skipping an empty queue is harmless")

func test_clear_drops_everything() -> void:
	print("clear")
	var q := _make()
	q.say("a")
	q.say("b")
	q.say("c")
	q.clear()
	expect(not q.is_showing(), "nothing is on screen")
	expect(q.pending() == 0, "nothing is queued")
	expect(q.current_text() == "", "the formatted text is empty too")

func test_signals() -> void:
	print("signals")
	var q := _make()
	var events: Array[String] = []
	q.caption_shown.connect(func(e: Dictionary) -> void: events.append("show:" + String(e["text"])))
	q.caption_hidden.connect(func(e: Dictionary) -> void: events.append("hide:" + String(e["text"])))
	q.queue_empty.connect(func() -> void: events.append("empty"))
	q.say("only")
	expect(events == ["show:only"], "caption_shown fires when it appears")
	_run_out(q)
	expect(events.has("hide:only"), "caption_hidden fires when it times out")
	expect(events.back() == "empty", "queue_empty fires once nothing is left")
