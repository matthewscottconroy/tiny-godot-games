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
	expect(not _make().visible, "_ready() hides the dialogue box")

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

func _report() -> void:
	var summary := "[dialogue-box] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
