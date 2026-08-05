extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_register_and_create()
	_test_unknown_type_returns_empty()
	_test_has_type()
	_test_registered_types_list()
	_test_builder_params_passed()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _make_factory() -> Dictionary:
	var registry: Dictionary = {}
	return registry

func _register(registry: Dictionary, type: StringName, builder: Callable) -> void:
	registry[type] = builder

func _create(registry: Dictionary, type: StringName, params: Dictionary = {}) -> Dictionary:
	if not registry.has(type):
		return {}
	return registry[type].call(params)

func _test_register_and_create() -> void:
	print("register and create entity")
	var reg := _make_factory()
	_register(reg, &"enemy", func(_p): return {"type": "enemy", "hp": 3})
	var e := _create(reg, &"enemy")
	expect(not e.is_empty(), "created entity is not empty")
	expect(e.get("hp") == 3, "entity has correct hp")

func _test_unknown_type_returns_empty() -> void:
	print("unknown type returns empty dict")
	var reg := _make_factory()
	var e := _create(reg, &"unknown_type")
	expect(e.is_empty(), "unknown type returns empty dictionary")

func _test_has_type() -> void:
	print("has_type check")
	var reg := _make_factory()
	_register(reg, &"coin", func(_p): return {"value": 10})
	expect(reg.has(&"coin"), "registered type found")
	expect(not reg.has(&"nope"), "unregistered type not found")

func _test_registered_types_list() -> void:
	print("registered types list")
	var reg := _make_factory()
	_register(reg, &"a", func(_p): return {})
	_register(reg, &"b", func(_p): return {})
	_register(reg, &"c", func(_p): return {})
	expect(reg.keys().size() == 3, "3 types registered")

func _test_builder_params_passed() -> void:
	print("builder receives params dict")
	var reg := _make_factory()
	_register(reg, &"enemy", func(p: Dictionary): return {
		"hp": p.get("hp", 1),
		"name": p.get("name", "unnamed"),
	})
	var e := _create(reg, &"enemy", {"hp": 5, "name": "boss"})
	expect(e["hp"] == 5, "param hp=5 passed through")
	expect(e["name"] == "boss", "param name='boss' passed through")

func _report() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [_pass, _fail])
	if _fail == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")
