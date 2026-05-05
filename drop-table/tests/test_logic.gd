extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_single_item_always_drops()
	test_empty_table_returns_empty()
	test_weights_sum_to_correct_chances()
	test_statistical_distribution()
	test_add_chaining()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		push_error("  FAIL  " + label)

func _report() -> void:
	var msg := "[drop-table] %d/%d passed" % [_pass, _pass + _fail]
	print("\n", msg)
	if _fail > 0:
		push_error(msg)

# Inline DropTable logic for testing
func _roll(entries: Array) -> String:
	if entries.is_empty():
		return ""
	var total := 0.0
	for e in entries:
		total += e["weight"]
	var r := randf() * total
	var acc := 0.0
	for e in entries:
		acc += e["weight"]
		if r <= acc:
			return e["item"]
	return entries[-1]["item"]

func _chances(entries: Array) -> Dictionary:
	var total := 0.0
	for e in entries:
		total += e["weight"]
	var out := {}
	for e in entries:
		out[e["item"]] = e["weight"] / total
	return out

func test_single_item_always_drops() -> void:
	var entries := [{"item": "Sword", "weight": 1.0}]
	for i in 20:
		expect(_roll(entries) == "Sword", "single entry always returns that item (roll %d)" % i)

func test_empty_table_returns_empty() -> void:
	expect(_roll([]) == "", "empty table returns empty string")

func test_weights_sum_to_correct_chances() -> void:
	var entries := [
		{"item": "Common", "weight": 60.0},
		{"item": "Rare",   "weight": 30.0},
		{"item": "Epic",   "weight": 10.0},
	]
	var c := _chances(entries)
	expect(absf(c["Common"] - 0.6) < 0.001, "Common chance is 60%")
	expect(absf(c["Rare"]   - 0.3) < 0.001, "Rare chance is 30%")
	expect(absf(c["Epic"]   - 0.1) < 0.001, "Epic chance is 10%")

func test_statistical_distribution() -> void:
	seed(42)
	var entries := [
		{"item": "A", "weight": 50.0},
		{"item": "B", "weight": 50.0},
	]
	var counts := {"A": 0, "B": 0}
	for i in 1000:
		counts[_roll(entries)] += 1
	var ratio := float(counts["A"]) / 1000.0
	expect(ratio > 0.44 and ratio < 0.56, "50/50 table distributes roughly evenly over 1000 rolls")

func test_add_chaining() -> void:
	var table := DropTable.new()
	table.add("X", 10.0).add("Y", 20.0).add("Z", 30.0)
	var c := table.get_chances()
	expect(c.size() == 3, "chained add() produces 3 entries")
	expect(absf(c["Z"] - 0.5) < 0.001, "Z weight 30 / total 60 = 50%")
