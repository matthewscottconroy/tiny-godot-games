extends Node

# Drives the real addon: the RingSpawner geometry, and the plugin's own
# configuration. A plugin's editor behaviour cannot run headlessly, but the
# things that actually break — a malformed plugin.cfg, a missing script, an
# _enter_tree without a matching _exit_tree — are all checkable here.

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_plugin_cfg_is_wellformed()
	test_plugin_files_exist()
	test_plugin_teardown_is_symmetric()
	test_simple_ring()
	test_star_polygon()
	test_walk_closes_rather_than_repeating()
	test_degenerate_inputs()
	test_radius_is_respected()
	test_spawner_setters_clamp()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[editor-plugin] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const ADDON := "res://addons/ring_tools/"

func test_plugin_cfg_is_wellformed() -> void:
	print("plugin.cfg")
	var cfg := ConfigFile.new()
	expect(cfg.load(ADDON + "plugin.cfg") == OK, "plugin.cfg parses as a ConfigFile")
	for key in ["name", "description", "author", "version", "script"]:
		expect(cfg.get_value("plugin", key, "") != "", "plugin.cfg declares '%s'" % key)
	# Godot resolves `script` relative to the addon folder; a typo here is a
	# silent no-op where the plugin simply never loads.
	var script_path: String = ADDON + str(cfg.get_value("plugin", "script", ""))
	expect(ResourceLoader.exists(script_path), "the declared script exists at %s" % script_path)

func test_plugin_files_exist() -> void:
	print("addon contents")
	for path in ["plugin.gd", "ring_spawner.gd", "ring_dock.gd", "ring_dock.tscn"]:
		expect(ResourceLoader.exists(ADDON + path), "%s is present" % path)

func test_plugin_teardown_is_symmetric() -> void:
	print("teardown mirrors setup")
	# Godot does not clean up docks or custom types for you. A plugin that adds
	# something in _enter_tree and forgets to remove it in _exit_tree leaves
	# duplicates behind on every reload — and plugins reload constantly.
	var source := FileAccess.get_file_as_string(ADDON + "plugin.gd")
	expect(source.contains("add_custom_type("), "the plugin registers a custom type")
	expect(source.contains("remove_custom_type("), "and removes it again")
	expect(source.contains("add_control_to_dock("), "the plugin adds a dock")
	expect(source.contains("remove_control_from_docks("), "and removes it again")

func _spawner_script() -> GDScript:
	return load(ADDON + "ring_spawner.gd")

func test_simple_ring() -> void:
	print("a plain ring")
	var poly: PackedVector2Array = _spawner_script().build(6, 100.0, 1)
	expect(poly.size() == 6, "six points for six vertices")
	for p in poly:
		expect(is_equal_approx(p.length(), 100.0), "every point sits on the radius")

func test_star_polygon() -> void:
	print("a star polygon")
	# Stepping 2 at a time round 5 points draws a pentagram, visiting all five.
	var poly: PackedVector2Array = _spawner_script().build(5, 100.0, 2)
	expect(poly.size() == 5, "a stride of 2 over 5 points visits every vertex")
	expect(not poly[0].is_equal_approx(poly[1]), "consecutive points differ")
	# Consecutive points are two steps apart, so further than on a plain ring.
	var ring: PackedVector2Array = _spawner_script().build(5, 100.0, 1)
	expect(poly[0].distance_to(poly[1]) > ring[0].distance_to(ring[1]),
		"the stride makes consecutive points further apart — that is the star")

func test_walk_closes_rather_than_repeating() -> void:
	print("the walk stops when it revisits a vertex")
	# A stride that shares a factor with the count closes early: 2 over 6 only
	# reaches the even vertices. Stopping there beats drawing the same triangle
	# twice.
	var poly: PackedVector2Array = _spawner_script().build(6, 100.0, 2)
	expect(poly.size() == 3, "stride 2 over 6 points closes after three vertices")
	var seen: Dictionary = {}
	for p in poly:
		var key := "%.3f,%.3f" % [p.x, p.y]
		expect(not seen.has(key), "no vertex is emitted twice")
		seen[key] = true

func test_degenerate_inputs() -> void:
	print("degenerate inputs")
	expect(_spawner_script().build(1, 100.0, 1).size() == 1, "a single point is allowed")
	expect(_spawner_script().build(0, 100.0, 1).size() == 1, "a zero count is floored to one")
	expect(_spawner_script().build(6, 100.0, 0).size() == 6, "a zero stride is floored to one")

func test_radius_is_respected() -> void:
	print("radius")
	for p in _spawner_script().build(8, 42.0, 3):
		expect(is_equal_approx(p.length(), 42.0), "points sit on the requested radius")

func test_spawner_setters_clamp() -> void:
	print("exported setters guard their ranges")
	var node := Node2D.new()
	node.set_script(_spawner_script())
	add_child(node)
	node.points = -5
	expect(node.points == 1, "points clamps to at least one")
	node.radius = -10.0
	expect(node.radius >= 1.0, "radius clamps to a positive value")
	node.skip = 0
	expect(node.skip == 1, "skip clamps to at least one")
	expect(node.polygon().size() > 0, "polygon() still produces geometry after clamping")
