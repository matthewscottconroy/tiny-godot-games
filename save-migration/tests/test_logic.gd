extends Node

# Drives the real SaveMigrator from scripts/save_migrator.gd.

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_version_defaults_to_zero()
	test_current_save_needs_nothing()
	test_single_step()
	test_chains_across_several_versions()
	test_version_field_is_stamped()
	test_missing_step_refuses()
	test_future_save_refuses()
	test_original_is_not_mutated()
	test_steps_are_reported()
	test_demo_chain_upgrades_a_v0_save()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[save-migration] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

# A migrator whose steps just leave a breadcrumb, so ordering is observable.
func _counting_migrator(latest: int) -> SaveMigrator:
	var m := SaveMigrator.new(latest)
	for v in latest:
		m.add_step(v, func(d: Dictionary) -> Dictionary:
			var trail: Array = d.get("trail", [])
			trail.append(v)
			d["trail"] = trail
			return d)
	return m

func test_version_defaults_to_zero() -> void:
	print("a save with no version field")
	var m := SaveMigrator.new(1)
	# Saves written before anyone added versioning have no field at all.
	expect(m.version_of({}) == 0, "a missing version reads as 0")
	expect(m.version_of({"version": 2}) == 2, "an explicit version is read back")

func test_current_save_needs_nothing() -> void:
	print("an already-current save")
	var m := _counting_migrator(3)
	var r := m.migrate({"version": 3, "hp": 10})
	expect(not m.needs_migration({"version": 3}), "needs_migration is false at the current version")
	expect(r["ok"], "migrate succeeds")
	expect(r["steps"].is_empty(), "no steps run")
	expect(r["data"]["hp"] == 10, "the payload is untouched")

func test_single_step() -> void:
	print("one version behind")
	var m := SaveMigrator.new(2)
	m.add_step(1, func(d: Dictionary) -> Dictionary:
		d["hp"] = int(d["hp"]) * 2
		return d)
	var r := m.migrate({"version": 1, "hp": 25})
	expect(r["ok"], "migrate succeeds")
	expect(r["data"]["hp"] == 50, "the step ran")
	expect(r["to"] == 2, "the result reports the version it reached")

func test_chains_across_several_versions() -> void:
	print("several versions behind")
	var m := _counting_migrator(4)
	var r := m.migrate({"version": 0})
	expect(r["ok"], "migrate succeeds")
	expect(r["data"]["trail"] == [0, 1, 2, 3], "every step ran, in order")
	expect(r["from"] == 0 and r["to"] == 4, "from/to span the whole chain")

func test_version_field_is_stamped() -> void:
	print("the version field is advanced")
	var m := _counting_migrator(3)
	var r := m.migrate({"version": 1})
	expect(r["data"]["version"] == 3, "the migrated save carries the current version")

func test_missing_step_refuses() -> void:
	print("a gap in the chain")
	var m := SaveMigrator.new(3)
	m.add_step(0, func(d: Dictionary) -> Dictionary: return d)
	# No step registered for 1 -> 2.
	var r := m.migrate({"version": 0})
	expect(not r["ok"], "migrate refuses rather than skipping the gap")
	expect(r["error"].contains("version 1"), "the error names the missing step")
	expect(r["to"] == 1, "it reports how far it got")

func test_future_save_refuses() -> void:
	print("a save from a newer build")
	var m := _counting_migrator(2)
	var r := m.migrate({"version": 9, "hp": 3})
	expect(not r["ok"], "a newer save is refused, not downgraded")
	expect(r["data"]["hp"] == 3, "the data is handed back untouched")

func test_original_is_not_mutated() -> void:
	print("the caller's dictionary is left alone")
	var m := SaveMigrator.new(2)
	m.add_step(1, func(d: Dictionary) -> Dictionary:
		d["added"] = true
		return d)
	var original := {"version": 1, "nested": {"keep": 1}}
	var r := m.migrate(original)
	expect(not original.has("added"), "the step wrote to a copy, not the original")
	expect(original["version"] == 1, "the original version field is unchanged")
	expect(r["data"]["nested"]["keep"] == 1, "nested data survives the deep copy")

func test_steps_are_reported() -> void:
	print("the applied steps are reported")
	var m := _counting_migrator(3)
	var r := m.migrate({"version": 1})
	expect(Array(r["steps"]) == ["1→2", "2→3"], "each applied step is listed for logging")

func test_demo_chain_upgrades_a_v0_save() -> void:
	print("the demo's own migration chain")
	# Build the same chain main.gd registers, and run the oldest sample through it.
	var m := SaveMigrator.new(3)
	m.add_step(0, func(d: Dictionary) -> Dictionary:
		d["items"] = d.get("items", [])
		return d)
	m.add_step(1, func(d: Dictionary) -> Dictionary:
		d["pos"] = {"x": d.get("x", 0.0), "y": d.get("y", 0.0)}
		d.erase("x")
		d.erase("y")
		return d)
	m.add_step(2, func(d: Dictionary) -> Dictionary:
		var stacks: Dictionary = {}
		for item in d.get("items", []):
			stacks[item] = int(stacks.get(item, 0)) + 1
		d["inventory"] = stacks
		d.erase("items")
		return d)

	var r := m.migrate({"name": "Hero", "hp": 80, "x": 100.0, "y": 240.0, "gold": 15})
	expect(r["ok"], "a v0 save migrates cleanly")
	expect(r["data"]["pos"] == {"x": 100.0, "y": 240.0}, "loose x/y became a packed position")
	expect(not r["data"].has("x"), "the old fields are gone")
	expect(r["data"]["inventory"] == {}, "an absent inventory became empty stacks")
	expect(r["data"]["hp"] == 80, "untouched fields survive every step")

	var r2 := m.migrate({"version": 1, "x": 5.0, "y": 6.0, "items": ["potion", "potion", "rope"]})
	expect(r2["data"]["inventory"] == {"potion": 2, "rope": 1}, "repeated items became stacks")
