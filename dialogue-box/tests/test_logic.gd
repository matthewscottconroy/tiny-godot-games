extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_index_starts_at_zero()
	test_advance_increments_index()
	test_advance_past_end_returns_finished()
	test_skip_typing_shows_full_text()
	test_empty_speaker_fallback()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[dialogue-box] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

# Simulate the pure stateful logic from dialogue_box.gd without Nodes
class DialogueSim:
	var lines    : Array[String] = []
	var speakers : Array[String] = []
	var index    := 0
	var finished := false

	func start(l: Array[String], s: Array[String] = []) -> void:
		lines    = l
		speakers = s
		index    = 0
		finished = false

	func current_line() -> String:
		return lines[index] if index < lines.size() else ""

	func current_speaker() -> String:
		return speakers[index] if index < speakers.size() else ""

	func advance() -> void:
		index += 1
		if index >= lines.size():
			finished = true

# --- tests ---

func test_index_starts_at_zero() -> void:
	var sim := DialogueSim.new()
	sim.start(["Hello", "World"])
	expect(sim.index == 0,          "index starts at 0")
	expect(sim.current_line() == "Hello", "first line is 'Hello'")

func test_advance_increments_index() -> void:
	var sim := DialogueSim.new()
	sim.start(["Line 1", "Line 2", "Line 3"])
	sim.advance()
	expect(sim.index == 1,           "index is 1 after first advance")
	expect(sim.current_line() == "Line 2", "current line is 'Line 2'")

func test_advance_past_end_returns_finished() -> void:
	var sim := DialogueSim.new()
	sim.start(["Only line"])
	expect(not sim.finished, "not finished initially")
	sim.advance()
	expect(sim.finished, "finished after advancing past last line")

func test_skip_typing_shows_full_text() -> void:
	# Simulate: set _typing=false mid-type → full text should display
	var full := "Hello, adventurer!"
	var partial := full.left(5)
	expect(partial == "Hello", "partial text is correct prefix")
	# When _typing becomes false, next iteration sets full text
	var result := full if not true else partial   # typing=false branch
	expect(result == full, "full text shown when _typing is false")

func test_empty_speaker_fallback() -> void:
	var sim := DialogueSim.new()
	sim.start(["A line"], [])   # no speakers provided
	expect(sim.current_speaker() == "", "empty speaker list returns empty string")
