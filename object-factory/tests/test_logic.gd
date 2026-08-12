extends Node

# Drives the real EntityFactory from scripts/factory.gd rather than a bare
# Dictionary standing in for the registry.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_register_and_create()
	_test_unknown_type_returns_empty()
	_test_has_type()
	_test_registered_types_list()
	_test_builder_params_passed()
	_test_reregistering_replaces_builder()
	_test_builder_runs_per_call()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _test_register_and_create() -> void:
	print("register and create entity")
	var factory := EntityFactory.new()
	factory.register(&"enemy", func(_p: Dictionary) -> Dictionary: return {"type": "enemy", "hp": 3})
	var e := factory.create(&"enemy")
	expect(not e.is_empty(), "created entity is not empty")
	expect(e.get("hp") == 3, "entity has correct hp")

func _test_unknown_type_returns_empty() -> void:
	print("unknown type returns empty dict")
	# create() also pushes a warning here; the empty dictionary is the contract.
	expect(EntityFactory.new().create(&"unknown_type").is_empty(),
		"unknown type returns empty dictionary")

func _test_has_type() -> void:
	print("has_type check")
	var factory := EntityFactory.new()
	factory.register(&"coin", func(_p: Dictionary) -> Dictionary: return {"value": 10})
	expect(factory.has_type(&"coin"), "registered type found")
	expect(not factory.has_type(&"nope"), "unregistered type not found")

func _test_registered_types_list() -> void:
	print("registered types list")
	var factory := EntityFactory.new()
	for name in [&"a", &"b", &"c"]:
		factory.register(name, func(_p: Dictionary) -> Dictionary: return {})
	expect(factory.registered_types().size() == 3, "3 types registered")
	expect(factory.registered_types().has(&"b"), "registered_types lists each name")

func _test_builder_params_passed() -> void:
	print("builder receives params dict")
	var factory := EntityFactory.new()
	factory.register(&"enemy", func(p: Dictionary) -> Dictionary: return {
		"hp": p.get("hp", 1),
		"name": p.get("name", "unnamed"),
	})
	var e := factory.create(&"enemy", {"hp": 5, "name": "boss"})
	expect(e["hp"] == 5, "param hp=5 passed through")
	expect(e["name"] == "boss", "param name='boss' passed through")
	var d := factory.create(&"enemy")
	expect(d["hp"] == 1 and d["name"] == "unnamed", "omitted params fall back to builder defaults")

func _test_reregistering_replaces_builder() -> void:
	print("re-registering a name replaces its builder")
	var factory := EntityFactory.new()
	factory.register(&"enemy", func(_p: Dictionary) -> Dictionary: return {"v": 1})
	factory.register(&"enemy", func(_p: Dictionary) -> Dictionary: return {"v": 2})
	expect(factory.create(&"enemy")["v"] == 2, "the most recent builder wins")

func _test_builder_runs_per_call() -> void:
	print("each create() runs the builder again")
	var factory := EntityFactory.new()
	var calls := {"n": 0}
	factory.register(&"thing", func(_p: Dictionary) -> Dictionary:
		calls["n"] += 1
		return {"id": calls["n"]})
	var first := factory.create(&"thing")
	var second := factory.create(&"thing")
	expect(calls["n"] == 2, "the builder runs once per create()")
	expect(first["id"] != second["id"], "each call produces a fresh entity")

func _report() -> void:
	var summary := "[object-factory] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
