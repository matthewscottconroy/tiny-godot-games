extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_default_values()
	test_goblin_preset()
	test_dragon_preset()
	test_random_preset_in_bounds()
	test_color_assigned()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		push_error("  FAIL  " + label)

func _report() -> void:
	var msg := "[custom-resource] %d/%d passed" % [_pass, _pass + _fail]
	print("\n", msg)
	if _fail > 0:
		push_error(msg)

# Inline the preset-building logic from main.gd
func _make_goblin() -> EnemyStats:
	var s        := EnemyStats.new()
	s.enemy_name  = "Goblin"
	s.max_hp      = 30
	s.speed       = 140.0
	s.attack      = 5
	s.color       = Color.SEA_GREEN
	return s

func _make_dragon() -> EnemyStats:
	var s        := EnemyStats.new()
	s.enemy_name  = "Dragon"
	s.max_hp      = 500
	s.speed       = 60.0
	s.attack      = 80
	s.color       = Color.FIREBRICK
	return s

func _make_random() -> EnemyStats:
	var s        := EnemyStats.new()
	s.enemy_name  = "???"
	s.max_hp      = randi_range(10, 500)
	s.speed       = randf_range(40.0, 220.0)
	s.attack      = randi_range(1, 100)
	s.color       = Color(randf(), randf(), randf())
	return s

# --- tests ---

func test_default_values() -> void:
	var s := EnemyStats.new()
	expect(s.enemy_name == "Unknown", "default name is 'Unknown'")
	expect(s.max_hp     == 100,       "default max_hp is 100")
	expect(s.speed      == 80.0,      "default speed is 80.0")
	expect(s.attack     == 10,        "default attack is 10")

func test_goblin_preset() -> void:
	var s := _make_goblin()
	expect(s.enemy_name == "Goblin", "goblin name")
	expect(s.max_hp     == 30,       "goblin max_hp")
	expect(s.speed      == 140.0,    "goblin speed")
	expect(s.attack     == 5,        "goblin attack")

func test_dragon_preset() -> void:
	var s := _make_dragon()
	expect(s.enemy_name == "Dragon", "dragon name")
	expect(s.max_hp     == 500,      "dragon max_hp")
	expect(s.speed      == 60.0,     "dragon speed")
	expect(s.attack     == 80,       "dragon attack")

func test_random_preset_in_bounds() -> void:
	for _i in 10:   # run multiple times to catch randomness issues
		var s := _make_random()
		expect(s.max_hp >= 10 and s.max_hp <= 500,   "random max_hp in [10,500]")
		expect(s.speed >= 40.0 and s.speed <= 220.0, "random speed in [40,220]")
		expect(s.attack >= 1 and s.attack <= 100,     "random attack in [1,100]")

func test_color_assigned() -> void:
	var g := _make_goblin()
	var d := _make_dragon()
	expect(g.color == Color.SEA_GREEN,  "goblin is sea green")
	expect(d.color == Color.FIREBRICK,  "dragon is firebrick")
	expect(g.color != d.color,          "goblin and dragon colors differ")
