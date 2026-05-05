extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_revive_text_on_zero_hp()
	test_damage_clamps_hp_to_zero()
	test_color_based_on_damage()
	test_hp_resets_after_death()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		push_error("  FAIL  " + label)

func _report() -> void:
	var msg := "[floating-text] %d/%d passed" % [_pass, _pass + _fail]
	print("\n", msg)
	if _fail > 0:
		push_error(msg)

func _apply_damage(hp: int, max_hp: int, dmg: int) -> Dictionary:
	var new_hp := max(hp - dmg, 0)
	var revived := new_hp == 0
	var new_after := max_hp if revived else new_hp
	return {"hp": new_after, "revived": revived}

func _dmg_color(dmg: int) -> Color:
	return Color.RED if dmg >= 25 else Color.ORANGE_RED

func test_revive_text_on_zero_hp() -> void:
	var r := _apply_damage(10, 100, 50)
	expect(r["revived"], "hp reaching 0 triggers revive")

func test_damage_clamps_hp_to_zero() -> void:
	var r := _apply_damage(10, 100, 9999)
	expect(r["revived"], "massive damage still clamps to 0 and revives")

func test_color_based_on_damage() -> void:
	expect(_dmg_color(10) == Color.ORANGE_RED, "low damage → orange-red")
	expect(_dmg_color(50) == Color.RED,         "high damage → red")
	expect(_dmg_color(25) == Color.RED,         "threshold 25 → red")

func test_hp_resets_after_death() -> void:
	var r := _apply_damage(5, 150, 20)
	expect(r["hp"] == 150, "hp resets to max_hp after death")
