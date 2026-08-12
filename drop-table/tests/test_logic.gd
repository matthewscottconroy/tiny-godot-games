extends Node

# Drives the real DropTable from scripts/drop_table.gd. The previous suite
# recomputed weighted selection inline, so the component's own comparison could
# be inverted unnoticed — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_empty_table()
	_test_single_entry()
	_test_add_chains()
	_test_chances_are_normalised()
	_test_chances_reflect_weights()
	_test_every_entry_is_reachable()
	_test_distribution_follows_weights()
	_test_zero_weight_never_drops()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[drop-table] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const ROLLS := 4000

func _make() -> DropTable:
	var t := DropTable.new()
	t.add("Nothing", 50.0).add("Coin", 30.0).add("Gem", 15.0).add("Crown", 5.0)
	return t

func _roll_many(table: DropTable, n: int = ROLLS) -> Dictionary:
	var counts: Dictionary = {}
	for i in n:
		var item := table.roll()
		counts[item] = int(counts.get(item, 0)) + 1
	return counts

func _test_empty_table() -> void:
	print("an empty table")
	expect(DropTable.new().roll() == "", "rolling nothing returns an empty string, not an error")

func _test_single_entry() -> void:
	print("one entry")
	var t := DropTable.new()
	t.add("Only", 1.0)
	var counts := _roll_many(t, 50)
	expect(counts.size() == 1 and counts.has("Only"), "a single entry always drops")

func _test_add_chains() -> void:
	print("add returns self")
	var t := DropTable.new()
	expect(t.add("A", 1.0) == t, "add chains so a table reads as one expression")

func _test_chances_are_normalised() -> void:
	print("chances are fractions")
	var chances := _make().get_chances()
	var total := 0.0
	for value in chances.values():
		total += float(value)
	expect(is_equal_approx(total, 1.0), "the reported chances sum to 1")

func _test_chances_reflect_weights() -> void:
	print("chances follow the weights")
	var chances := _make().get_chances()
	expect(is_equal_approx(float(chances["Nothing"]), 0.5), "weight 50 of 100 is a 50% chance")
	expect(is_equal_approx(float(chances["Crown"]), 0.05), "weight 5 of 100 is a 5% chance")
	expect(float(chances["Coin"]) > float(chances["Gem"]), "a heavier entry has a higher chance")

func _test_every_entry_is_reachable() -> void:
	print("every entry can drop")
	# The classic weighted-selection bug is an off-by-one that makes the first or
	# last entry unreachable. Enough rolls to make that visible.
	var counts := _roll_many(_make())
	for item in ["Nothing", "Coin", "Gem", "Crown"]:
		expect(counts.has(item), "%s drops at least once in %d rolls" % [item, ROLLS])

func _test_distribution_follows_weights() -> void:
	print("the distribution matches the chances")
	var table := _make()
	var counts := _roll_many(table)
	var chances := table.get_chances()
	for item in chances:
		var expected := float(chances[item])
		var actual := float(counts.get(item, 0)) / ROLLS
		# Generous tolerance: this is sampling, not arithmetic.
		expect(absf(actual - expected) < 0.05,
			"%s landed near its %.0f%% chance (got %.0f%%)" % [item, expected * 100, actual * 100])

func _test_zero_weight_never_drops() -> void:
	print("zero weight")
	var t := DropTable.new()
	t.add("Common", 10.0).add("Impossible", 0.0)
	var counts := _roll_many(t, 2000)
	expect(not counts.has("Impossible"), "a zero-weight entry never drops")
