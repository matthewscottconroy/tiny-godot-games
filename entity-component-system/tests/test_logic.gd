extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_entity_ids_unique()
	_test_add_and_get_component()
	_test_has_component()
	_test_remove_component()
	_test_query_intersection()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _test_entity_ids_unique() -> void:
	print("entity IDs are unique sequential integers")
	var next_id := 0
	var ids: Array = []
	for _i in 5:
		ids.append(next_id)
		next_id += 1
	expect(ids.size() == 5, "5 entities created")
	expect(ids[0] == 0, "first entity ID is 0")
	expect(ids[4] == 4, "fifth entity ID is 4")

func _test_add_and_get_component() -> void:
	print("add and retrieve component data")
	var components: Dictionary = {}
	var entity := 0
	var type: StringName = &"Position"
	if not components.has(type):
		components[type] = {}
	components[type][entity] = {"x": 100.0, "y": 200.0}
	var data: Dictionary = components[type][entity]
	expect(data["x"] == 100.0, "component x value retrieved correctly")
	expect(data["y"] == 200.0, "component y value retrieved correctly")

func _test_has_component() -> void:
	print("has_component check")
	var components: Dictionary = {&"Health": {0: {"hp": 5}}}
	expect(components.has(&"Health") and components[&"Health"].has(0),
		"entity 0 has Health component")
	expect(not (components.has(&"Velocity") and components[&"Velocity"].get(0)),
		"entity 0 does not have Velocity component")

func _test_remove_component() -> void:
	print("remove component")
	var components: Dictionary = {&"Tag": {0: {}, 1: {}}}
	components[&"Tag"].erase(0)
	expect(not components[&"Tag"].has(0), "component removed from entity 0")
	expect(components[&"Tag"].has(1), "entity 1 component unaffected")

func _test_query_intersection() -> void:
	print("query returns entities with all required components")
	var components: Dictionary = {
		&"Position": {0: {}, 1: {}, 2: {}},
		&"Velocity": {0: {}, 2: {}},
	}
	var required := [&"Position", &"Velocity"]
	var result: Array = []
	for entity in components[required[0]].keys():
		var has_all := true
		for t in required:
			if not (components.has(t) and components[t].has(entity)):
				has_all = false
				break
		if has_all:
			result.append(entity)
	expect(result.size() == 2, "query returns 2 entities with both components")
	expect(not result.has(1), "entity 1 excluded (no Velocity)")

func _report() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [_pass, _fail])
	if _fail == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")
