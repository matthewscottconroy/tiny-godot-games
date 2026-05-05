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
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		push_error("  FAIL  " + label)

func _report() -> void:
	var msg := "[combo-system] %d/%d passed" % [_pass, _pass + _fail]
	print("\n", msg)
	if _fail > 0:
		push_error(msg)

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

func _check_sequence(inputs: Array[String]) -> String:
	for combo in COMBOS:
		var pat: Array = combo["pattern"]
		if inputs.size() >= pat.size():
			var tail := inputs.slice(inputs.size() - pat.size())
			if tail == pat:
				return combo["name"]
	return ""

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
	var combo := ComboSystem.new()
	combo.add_input("L")
	var result := combo.add_input("L")
	expect(result == "Double Cut", "L+L fires Double Cut")
	# After a combo fires, history is cleared — next L alone gives no combo
	var after := combo.add_input("L")
	expect(after == "", "history cleared after combo fires; single L gives no new combo")

func test_no_cross_combo() -> void:
	expect(_check_sequence(["H", "H", "L"]) == "Counter", "H+H+L tail matches Counter (H+L)")
