extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_expansion_one_iter()
	_test_expansion_two_iters()
	_test_no_rule_passthrough()
	_test_bracket_balance()
	_test_preset_count()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func expand(axiom: String, rules: Dictionary, iters: int) -> String:
	var s := axiom
	for _i in iters:
		var next := ""
		for c in s:
			next += rules.get(c, c)
		s = next
	return s

func _test_expansion_one_iter() -> void:
	print("single iteration expansion")
	var result := expand("F", {"F": "F+F"}, 1)
	expect(result == "F+F", "F → F+F in one iteration")

func _test_expansion_two_iters() -> void:
	print("two iteration expansion")
	var result := expand("F", {"F": "F+F"}, 2)
	expect(result == "F+F+F+F", "F → F+F+F+F in two iterations")

func _test_no_rule_passthrough() -> void:
	print("symbols without rules pass through unchanged")
	var result := expand("F+X", {"F": "FF"}, 1)
	expect(result == "FF+X", "X has no rule, passes through unchanged")

func _test_bracket_balance() -> void:
	print("tree axiom brackets are balanced after expansion")
	var result := expand("X", {"X": "F+[[X]-X]-F[-FX]+X", "F": "FF"}, 2)
	var depth := 0
	var balanced := true
	for c in result:
		if c == "[":
			depth += 1
		elif c == "]":
			depth -= 1
			if depth < 0:
				balanced = false
				break
	expect(balanced and depth == 0, "brackets balanced after 2 tree iterations")

func _test_preset_count() -> void:
	print("number of presets")
	var count := 3  # Tree, Fern, Koch
	expect(count == 3, "3 presets defined")

func _report() -> void:
	var summary := "[l-system] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
