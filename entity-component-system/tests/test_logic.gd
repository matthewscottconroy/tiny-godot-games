extends Node

# Drives the real ECSWorld from scripts/ecs_world.gd rather than a hand-rolled
# copy of its component dictionaries.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_entity_ids_unique()
	_test_add_and_get_component()
	_test_get_missing_component_returns_empty()
	_test_has_component()
	_test_remove_component()
	_test_query_intersection()
	_test_query_edge_cases()
	_test_system_mutates_component_data()
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
	var world := ECSWorld.new()
	var ids: Array = []
	for _i in 5:
		ids.append(world.create_entity())
	expect(ids.size() == 5, "5 entities created")
	expect(ids[0] == 0, "first entity ID is 0")
	expect(ids[4] == 4, "fifth entity ID is 4")

func _test_add_and_get_component() -> void:
	print("add and retrieve component data")
	var world := ECSWorld.new()
	var e := world.create_entity()
	world.add_component(e, &"Position", {"x": 100.0, "y": 200.0})
	var data := world.get_component(e, &"Position")
	expect(data["x"] == 100.0, "component x value retrieved correctly")
	expect(data["y"] == 200.0, "component y value retrieved correctly")

func _test_get_missing_component_returns_empty() -> void:
	print("get_component on a missing component")
	var world := ECSWorld.new()
	var e := world.create_entity()
	expect(world.get_component(e, &"Velocity").is_empty(),
		"unknown component type returns an empty dictionary")
	world.add_component(e, &"Velocity", {"dx": 1.0})
	expect(world.get_component(world.create_entity(), &"Velocity").is_empty(),
		"known type but unknown entity returns an empty dictionary")

func _test_has_component() -> void:
	print("has_component check")
	var world := ECSWorld.new()
	var e := world.create_entity()
	world.add_component(e, &"Health", {"hp": 5})
	expect(world.has_component(e, &"Health"), "entity has Health component")
	expect(not world.has_component(e, &"Velocity"), "entity does not have Velocity component")

func _test_remove_component() -> void:
	print("remove component")
	var world := ECSWorld.new()
	var a := world.create_entity()
	var b := world.create_entity()
	world.add_component(a, &"Tag", {})
	world.add_component(b, &"Tag", {})
	world.remove_component(a, &"Tag")
	expect(not world.has_component(a, &"Tag"), "component removed from entity a")
	expect(world.has_component(b, &"Tag"), "entity b component unaffected")

func _test_query_intersection() -> void:
	print("query returns entities with all required components")
	var world := ECSWorld.new()
	var ids: Array = []
	for _i in 3:
		ids.append(world.create_entity())
	for id in ids:
		world.add_component(id, &"Position", {})
	world.add_component(ids[0], &"Velocity", {})
	world.add_component(ids[2], &"Velocity", {})

	var result := world.query([&"Position", &"Velocity"])
	expect(result.size() == 2, "query returns 2 entities with both components")
	expect(not result.has(ids[1]), "entity 1 excluded (no Velocity)")

func _test_query_edge_cases() -> void:
	print("query edge cases")
	var world := ECSWorld.new()
	expect(world.query([]).is_empty(), "an empty type list matches nothing")
	expect(world.query([&"Nothing"]).is_empty(), "an unknown type matches nothing")

func _test_system_mutates_component_data() -> void:
	print("systems mutate component data in place")
	var world := ECSWorld.new()
	var e := world.create_entity()
	world.add_component(e, &"Position", {"x": 0.0})
	world.add_component(e, &"Velocity", {"dx": 5.0})

	# A "movement system": query, then write through the returned dictionaries.
	for entity in world.query([&"Position", &"Velocity"]):
		var pos := world.get_component(entity, &"Position")
		var vel := world.get_component(entity, &"Velocity")
		pos["x"] += vel["dx"]

	expect(world.get_component(e, &"Position")["x"] == 5.0,
		"component dictionaries are returned by reference, so systems can write to them")

func _report() -> void:
	var summary := "[entity-component-system] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
