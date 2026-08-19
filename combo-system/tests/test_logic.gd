extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_single_input_no_combo()
	test_ll_gives_double_cut()
	test_lh_gives_launcher()
	test_hl_gives_counter()
	test_lll_gives_triple_slash()
	test_lll_beats_ll()
	test_combo_clears_history()
	test_no_cross_combo()
	test_a_longer_history_still_matches_its_tail()
	await test_inputs_expire_after_the_window()
	await test_the_player_holds_the_combo_on_screen()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[combo-system] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

# Pure combo-check logic extracted for testing (no timers needed)
const COMBOS: Array[Dictionary] = [
	{"pattern": ["L", "L", "L"], "name": "Triple Slash"},
	{"pattern": ["L", "H", "L"], "name": "Spin Attack"},
	{"pattern": ["H", "H", "H"], "name": "Ground Slam"},
	{"pattern": ["L", "L"],      "name": "Double Cut"},
	{"pattern": ["L", "H"],      "name": "Launcher"},
	{"pattern": ["H", "L"],      "name": "Counter"},
	{"pattern": ["H", "H"],      "name": "Overhead Slam"},
]

## Feed a sequence to a fresh ComboSystem and return what the last input fired.
##
## This used to be a copy of ComboSystem._check(), which is why every combo test
## passed while three of the seven combos could not be performed in the demo at
## all: the copy matched patterns against a list it was handed, and the real one
## threw its history away on the first match.
func _check_sequence(inputs: Array[String]) -> String:
	var combo := ComboSystem.new()
	var last := ""
	for inp in inputs:
		last = combo.add_input(inp)
	return last

func test_single_input_no_combo() -> void:
	expect(_check_sequence(["L"]) == "", "single L → no combo")
	expect(_check_sequence(["H"]) == "", "single H → no combo")

func test_ll_gives_double_cut() -> void:
	expect(_check_sequence(["L", "L"]) == "Double Cut", "L+L → Double Cut")

func test_lh_gives_launcher() -> void:
	expect(_check_sequence(["L", "H"]) == "Launcher", "L+H → Launcher")

func test_hl_gives_counter() -> void:
	expect(_check_sequence(["H", "L"]) == "Counter", "H+L → Counter")

func test_lll_gives_triple_slash() -> void:
	expect(_check_sequence(["L", "L", "L"]) == "Triple Slash", "L+L+L → Triple Slash")

func test_lll_beats_ll() -> void:
	# L+L+L should match Triple Slash, not Double Cut (longest-first matching)
	var result := _check_sequence(["L", "L", "L"])
	expect(result == "Triple Slash", "Triple Slash takes priority over Double Cut for L+L+L")

func test_combo_clears_history() -> void:
	# A combo that nothing longer can grow out of takes its inputs with it, so
	# the next press starts a new combo rather than extending a spent one.
	var counter := ComboSystem.new()
	counter.add_input("H")
	expect(counter.add_input("L") == "Counter", "H+L fires Counter")
	expect(counter.add_input("L") == "",
		"and clears, because no longer combo starts H+L — a single L is nothing")
	expect(counter.add_input("L") == "Double Cut", "so the next two L's start over")

	# A combo that *can* be extended keeps its inputs, or the third press of a
	# three-key combo would be starting from nothing.
	var slash := ComboSystem.new()
	slash.add_input("L")
	expect(slash.add_input("L") == "Double Cut", "L+L fires Double Cut")
	expect(slash.add_input("L") == "Triple Slash",
		"and keeps its history, because L+L+L grows out of it")
	expect(slash.add_input("L") == "",
		"Triple Slash then clears, since nothing is longer")

func test_no_cross_combo() -> void:
	expect(_check_sequence(["H", "H", "L"]) == "Counter", "H+H+L tail matches Counter (H+L)")

## A combo fires on the last few inputs, not on the whole history.
##
## `recent.size() >= pat.size()` is what allows a pattern shorter than the
## history to match its tail. Flip it and a player who has pressed anything at
## all before the combo gets nothing.
func test_a_longer_history_still_matches_its_tail() -> void:
	print("matching the tail")
	var c := ComboSystem.new()
	expect(c.add_input("H") == "", "one input is not a combo")
	expect(c.add_input("L") == "Counter", "H then L is a Counter")
	# Counter cannot be extended, so it clears — the next inputs start fresh.
	expect(c.add_input("L") == "", "and the history starts again after it")
	expect(c.add_input("L") == "Double Cut",
		"so the two L's after it are their own combo")

	# Every three-input combo has to be reachable by pressing three keys, which
	# is the whole reason a short match keeps its history when a longer pattern
	# could still grow out of it.
	expect(_check_sequence(["L", "L", "L"]) == "Triple Slash", "L L L is reachable")
	expect(_check_sequence(["L", "H", "L"]) == "Spin Attack", "so is L H L")
	expect(_check_sequence(["H", "H", "H"]) == "Ground Slam", "and H H H")

	# A four-long run does not keep firing: the three-long match clears, so the
	# fourth press starts a new combo rather than repeating the last one.
	expect(_check_sequence(["L", "L", "L", "L"]) == "",
		"a fourth L starts over rather than repeating Triple Slash")

## Inputs older than the window are forgotten.
##
## The window is measured as `now - then`, and this suite runs within the first
## second of the engine starting — where `now - then` and `now + then` are both
## small and both under the window, so a sum passes for a difference. Waiting
## past the window first is what separates them.
func test_inputs_expire_after_the_window() -> void:
	print("the window")
	var c := ComboSystem.new()
	c.add_input("L")
	expect(c.get_history_string() == "L", "the input is remembered (%s)" % c.get_history_string())

	# Sit out the whole window and a little more.
	var waited := 0.0
	while waited < ComboSystem.WINDOW + 0.15:
		await get_tree().process_frame
		waited += get_process_delta_time()

	expect(c.get_history_string() == "",
		"and forgotten once the window passes (%s)" % c.get_history_string())
	expect(c.add_input("L") == "",
		"so a second L long afterwards is not a Double Cut")
	expect(c.add_input("L") == "Double Cut",
		"while two together still are")

## The player shows the combo it landed, then stops showing it.
func test_the_player_holds_the_combo_on_screen() -> void:
	print("the readout")
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	add_child(scene)
	await get_tree().physics_frame
	var player: CharacterBody2D = scene.get_node("Player")
	var label: Label = player.get_node("ComboLabel")

	player._flash_timer = 0.0
	player._check_attacks()
	expect(label.text == "", "nothing is shown with no combo landed (%s)" % label.text)

	# Land one by hand — the input itself comes from Input, which cannot be
	# pressed headless, but everything after it can be driven.
	player._combo.add_input("L")
	var fired: String = player._combo.add_input("L")
	expect(fired == "Double Cut", "a Double Cut lands (%s)" % fired)
	player._last_combo = fired
	player._flash_timer = 0.5
	label.text = fired + "!"

	# The flash counts down, not up: it has to reach zero for the name to clear.
	var started: float = player._flash_timer
	player._physics_process(1.0 / 60.0)
	expect(player._flash_timer < started,
		"the flash timer counts down (%.3f -> %.3f)" % [started, player._flash_timer])

	# While it is still running the name stays put.
	player._check_attacks()
	expect(label.text.contains("Double Cut"),
		"the combo name stays up while the flash runs (%s)" % label.text)

	# Once it has run out, the name clears.
	for _i in 60:
		player._physics_process(1.0 / 60.0)
	expect(player._flash_timer == 0.0,
		"the flash timer reaches zero (%.3f)" % player._flash_timer)
	player._check_attacks()
	expect(label.text == "", "and the name clears (%s)" % label.text)

	# Nothing pressed, nothing happens — the grounded half of the jump.
	for _i in 60:
		await get_tree().physics_frame
	expect(player.is_on_floor(), "the player settles on the ground")
	var resting: float = player.global_position.y
	var highest := resting
	for _i in 40:
		await get_tree().physics_frame
		highest = minf(highest, player.global_position.y)
	expect(resting - highest < 4.0,
		"and stays there with no key pressed (rose %.1f px)" % (resting - highest))

	scene.queue_free()
