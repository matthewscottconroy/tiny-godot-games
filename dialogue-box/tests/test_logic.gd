extends Node

# Drives the real DialogueBox from scripts/dialogue_box.gd via the demo scene
# (the control needs its Panel/VBox/Label children).

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_starts_hidden()
	test_start_shows_the_first_line()
	test_advance_moves_to_the_next_line()
	test_advance_past_end_finishes()
	test_advance_while_typing_skips_the_typewriter()
	test_empty_speaker_fallback()
	test_restart_resets_the_index()
	await test_the_typewriter_actually_types()
	await test_the_talk_button_waits_for_the_conversation()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _make() -> DialogueBox:
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	add_child(scene)
	return scene.get_node("CanvasLayer/DialogueBox")

const LINES: Array[String] = ["Hello", "Line 2", "Last line"]
const SPEAKERS: Array[String] = ["Guide", "Guide", "Guide"]

func test_starts_hidden() -> void:
	print("the box starts hidden")
	var box := _make()
	expect(not box.visible, "_ready() hides the dialogue box")
	# Nothing is being typed before there is anything to type. A box that starts
	# out believing it is mid-line swallows the first press of Next as a
	# skip-the-typewriter instead of an advance.
	expect(not box._typing, "and it is not typing anything yet")

func test_start_shows_the_first_line() -> void:
	print("start() opens on the first line")
	var box := _make()
	box.start(LINES, SPEAKERS)
	expect(box.visible, "the box becomes visible")
	expect(box._index == 0, "the first line is index 0")
	expect(box._lines[0] == "Hello", "first line is 'Hello'")
	expect(box.speaker_label.text == "Guide", "the speaker label is set from the speakers array")
	expect(box.next_btn.disabled, "Next is disabled while the line is still typing")

func test_advance_moves_to_the_next_line() -> void:
	print("advancing moves to the next line")
	var box := _make()
	box.start(LINES, SPEAKERS)
	box._typing = false          # the line has finished revealing
	box._advance()
	expect(box._index == 1, "the index advances")
	expect(box._lines[box._index] == "Line 2", "current line is 'Line 2'")

func test_advance_past_end_finishes() -> void:
	print("advancing past the last line finishes")
	var box := _make()
	var finished := {"count": 0}
	box.finished.connect(func() -> void: finished["count"] += 1)
	box.start(["Only line"])
	expect(finished["count"] == 0, "not finished initially")
	box._typing = false
	box._advance()
	expect(finished["count"] == 1, "finished emits after advancing past the last line")
	expect(not box.visible, "the box hides itself when the script runs out")

func test_advance_while_typing_skips_the_typewriter() -> void:
	print("advancing mid-type skips to the full line")
	var box := _make()
	box.start(LINES, SPEAKERS)
	box._typing = true
	box._advance()
	expect(not box._typing, "the first press stops the typewriter")
	expect(box._index == 0, "and does not advance the line")

func test_empty_speaker_fallback() -> void:
	print("missing speakers fall back to an empty label")
	var box := _make()
	box.start(LINES)             # no speakers supplied
	expect(box.speaker_label.text == "", "an empty speaker list leaves the label blank")

func test_restart_resets_the_index() -> void:
	print("start() can be called again")
	var box := _make()
	box.start(LINES, SPEAKERS)
	box._typing = false
	box._advance()
	box.start(["Fresh"])
	expect(box._index == 0, "a new script starts from the beginning")
	expect(box._lines == ["Fresh"], "and replaces the previous lines")

## The reveal, allowed to run.
##
## Every test above sets `_typing` by hand and never lets `_type_out` run — it
## is deferred and awaits a timer per character — so the loop that reveals the
## text, both ends of the typing flag, and the button being re-enabled when the
## line finishes were all unheld.
func test_the_typewriter_actually_types() -> void:
	print("the typewriter")
	var box := _make()
	box.chars_per_sec = 60.0
	box.start(LINES, SPEAKERS)

	# _show_line defers the reveal, so it begins on the next frame.
	await get_tree().process_frame
	await get_tree().process_frame
	expect(box._typing, "the box is typing once the line opens")
	expect(box.next_btn.disabled, "and Next is refused until the line is done")

	# Partway through: some of the line is shown, and what is shown is the start
	# of it. `left(i - 1)` would reveal one character behind and never finish.
	var seen: Array[String] = []
	for _i in 6:
		await get_tree().process_frame
		seen.append(box.text_label.text)
	var partial := ""
	for shown in seen:
		if shown.length() > 0 and shown.length() < LINES[0].length():
			partial = shown
	expect(partial != "", "the line is revealed a piece at a time (%s)" % [seen])
	expect(LINES[0].begins_with(partial),
		"and each piece is the beginning of the line (%s of %s)" % [partial, LINES[0]])

	# Left alone it finishes, releases the flag and unlocks the button.
	for _i in 90:
		await get_tree().process_frame
		if not box._typing:
			break
	expect(not box._typing, "the reveal ends by clearing the typing flag")
	expect(box.text_label.text == LINES[0],
		"with the whole line shown (%s)" % box.text_label.text)
	expect(not box.next_btn.disabled, "and Next enabled, so the reader can move on")

	# Pressing Next mid-type shows the rest at once rather than advancing.
	box._advance()
	await get_tree().process_frame
	await get_tree().process_frame
	expect(box._index == 1, "a press on a finished line advances it")
	expect(box._typing, "and the next line starts typing")
	box._advance()
	await get_tree().process_frame
	expect(not box._typing, "a press mid-type stops the typewriter")
	expect(box._index == 1, "without skipping the line")
	await get_tree().process_frame
	await get_tree().process_frame
	expect(box.text_label.text == LINES[1],
		"and the whole line appears at once (%s)" % box.text_label.text)

## The talk button is locked for as long as the conversation runs.
func test_the_talk_button_waits_for_the_conversation() -> void:
	print("the talk button")
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	add_child(scene)
	await get_tree().process_frame
	var talk: Button = scene.get_node("TalkBtn")
	var box: DialogueBox = scene.get_node("CanvasLayer/DialogueBox")

	expect(not talk.disabled, "Talk is available before the conversation starts")
	talk.pressed.emit()
	expect(talk.disabled,
		"and locked while it runs — a second press would restart it mid-line")
	expect(box.visible, "with the box open")

	# Run it out. finished fires when the last line is advanced past, and that
	# is what puts the button back.
	box._typing = false
	for _i in box._lines.size() + 1:
		box._advance()
		await get_tree().process_frame
		box._typing = false
	expect(not box.visible, "the box closes at the end of the conversation")
	expect(not talk.disabled, "and Talk comes back, so it can be started again")

	scene.queue_free()

func _report() -> void:
	var summary := "[dialogue-box] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
