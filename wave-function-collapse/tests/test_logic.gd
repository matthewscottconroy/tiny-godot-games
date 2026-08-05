extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_tile_count()
	_test_adjacency_rules()
	_test_constraint_propagation()
	_test_min_entropy_selection()
	_test_weighted_choice()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

const NUM_TILES := 4
const RULES := {0: [0,1], 1: [0,1,2], 2: [1,2,3], 3: [2,3]}

func _test_tile_count() -> void:
	print("tile type count")
	expect(NUM_TILES == 4, "4 tile types: DEEP, SHALLOW, SAND, GRASS")

func _test_adjacency_rules() -> void:
	print("adjacency rule symmetry")
	for tile_a in NUM_TILES:
		for tile_b in NUM_TILES:
			var a_allows_b := tile_b in RULES[tile_a]
			var b_allows_a := tile_a in RULES[tile_b]
			expect(a_allows_b == b_allows_a,
				"rule symmetry: tile %d / tile %d" % [tile_a, tile_b])

func _test_constraint_propagation() -> void:
	print("constraint removes incompatible tiles")
	var cell_a := [false, false, false, true]  # GRASS only
	var cell_b := [true, true, true, true]     # all possible
	var changed := false
	for tile in NUM_TILES:
		if not cell_b[tile]:
			continue
		var ok := false
		for my_tile in NUM_TILES:
			if cell_a[my_tile] and tile in RULES[my_tile]:
				ok = true
				break
		if not ok:
			cell_b[tile] = false
			changed = true
	expect(changed, "constraint removed impossible tiles from neighbor")
	expect(cell_b[2] or cell_b[3], "SAND and/or GRASS remain next to GRASS")
	expect(not cell_b[0], "DEEP removed — cannot be adjacent to GRASS")

func _test_min_entropy_selection() -> void:
	print("minimum entropy cell has fewest possibilities")
	var cells := [[true,true,true,true], [true,false,true,false], [true,false,false,false]]
	var min_e := NUM_TILES + 1
	var best_idx := -1
	for i in cells.size():
		var e := 0
		for v in cells[i]:
			if v: e += 1
		if e > 0 and e < min_e:
			min_e = e
			best_idx = i
	expect(best_idx == 2, "cell with 1 possibility has lowest entropy")

func _test_weighted_choice() -> void:
	print("weighted choice always returns valid index")
	const WEIGHTS := [1.0, 2.0, 2.0, 3.0]
	var possible := [true, true, false, true]
	var total := 0.0
	for t in NUM_TILES:
		if possible[t]: total += WEIGHTS[t]
	var r := 0.5 * total
	var acc := 0.0
	var chosen := -1
	for t in NUM_TILES:
		if possible[t]:
			acc += WEIGHTS[t]
			if acc >= r:
				chosen = t
				break
	expect(chosen >= 0 and chosen < NUM_TILES, "chosen tile is a valid index")
	expect(possible[chosen], "chosen tile was in the possible set")

func _report() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [_pass, _fail])
	if _fail == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")
