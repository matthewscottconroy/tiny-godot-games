extends Node

# Drives the real LevelSystem from scripts/level_system.gd. The previous suite
# recomputed the XP curve inline, so every rule in the component could be
# inverted without a single assertion noticing — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_starting_state()
	_test_xp_threshold_curve()
	_test_threshold_grows()
	_test_gain_without_levelling()
	_test_level_up()
	_test_overflow_carries()
	_test_multiple_levels_from_one_award()
	_test_max_level_caps()
	_test_signals()
	_test_tuning_changes_the_curve()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[experience-leveling] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const BASE_XP := 50

func _test_starting_state() -> void:
	print("starting state")
	var s := LevelSystem.new()
	expect(s.level == 1, "starts at level 1")
	expect(s.xp == 0, "with no XP")
	expect(s.xp_for_next == BASE_XP, "and the level-1 threshold already computed")

func _test_xp_threshold_curve() -> void:
	print("threshold curve")
	var s := LevelSystem.new()
	expect(s.threshold(1) == 50, "level 1 needs 50")
	expect(s.threshold(2) == int(50 * 1.4), "level 2 needs 70")
	# pow(1.4, 2) lands just under 1.96 and int() truncates, so this is 97.
	expect(s.threshold(3) == 97, "level 3 needs 97 — int() truncates the curve")

func _test_threshold_grows() -> void:
	print("each level costs more")
	var s := LevelSystem.new()
	var previous := 0
	for lvl in range(1, 8):
		var t := s.threshold(lvl)
		expect(t > previous, "level %d costs more than level %d" % [lvl, lvl - 1])
		previous = t

func _test_gain_without_levelling() -> void:
	print("XP below the threshold")
	var s := LevelSystem.new()
	s.gain(30)
	expect(s.level == 1, "no level-up below the threshold")
	expect(s.xp == 30, "the XP is banked")

func _test_level_up() -> void:
	print("crossing the threshold")
	var s := LevelSystem.new()
	s.gain(50)
	expect(s.level == 2, "hitting the threshold exactly levels up")
	expect(s.xp == 0, "and consumes the XP")
	expect(s.xp_for_next == s.threshold(2), "the next threshold is recomputed")

func _test_overflow_carries() -> void:
	print("overflow")
	var s := LevelSystem.new()
	s.gain(65)
	expect(s.level == 2, "levelled up")
	expect(s.xp == 15, "the surplus carries into the new level rather than being lost")

func _test_multiple_levels_from_one_award() -> void:
	print("a big award")
	var s := LevelSystem.new()
	s.gain(500)
	expect(s.level > 3, "one large award applies several level-ups")
	expect(s.xp < s.xp_for_next, "and stops with less XP than the next level needs")

func _test_max_level_caps() -> void:
	print("max level")
	var s := LevelSystem.new()
	s.max_level = 3
	s.gain(1000000)
	expect(s.level == 3, "levelling stops at max_level")
	expect(s.xp > 0, "the leftover XP is not silently discarded")

func _test_signals() -> void:
	print("signals")
	var s := LevelSystem.new()
	var levels: Array[int] = []
	var gains: Array = []
	s.leveled_up.connect(func(new_level: int) -> void: levels.append(new_level))
	s.xp_gained.connect(func(current: int, needed: int) -> void: gains.append([current, needed]))

	s.gain(10)
	expect(levels.is_empty(), "no leveled_up below the threshold")
	expect(gains.size() == 1, "xp_gained fires on every award")

	s.gain(200)
	expect(levels.size() >= 2, "leveled_up fires once per level crossed")
	expect(levels == range(2, 2 + levels.size()), "and reports consecutive levels")
	expect(gains.back()[1] == s.xp_for_next, "xp_gained reports the current requirement")

func _test_tuning_changes_the_curve() -> void:
	print("tuning")
	var gentle := LevelSystem.new()
	gentle.growth = 1.1
	var steep := LevelSystem.new()
	steep.growth = 2.0
	expect(steep.threshold(5) > gentle.threshold(5), "a higher growth factor costs more per level")

	var cheap := LevelSystem.new()
	cheap.base_xp = 10
	expect(cheap.threshold(1) == 10, "base_xp sets the first threshold")
