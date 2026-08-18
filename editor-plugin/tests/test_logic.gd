extends Node

# Drives the real plugin's node and its demo driver — see docs/TEST_INTEGRITY.md.
#
# The plugin itself only runs inside the editor, so what is testable is the
# part the plugin exists to deliver: the custom node it registers, and the
# symmetry between what it adds on enable and removes on disable.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_plugin_is_declared()
	_test_what_it_adds_it_also_removes()
	_test_the_ring_is_a_closed_figure()
	_test_more_points_make_a_rounder_ring()
	_test_the_radius_sets_the_size()
	_test_a_stride_makes_a_star()
	_test_a_stride_that_divides_the_ring_closes_early()
	_test_degenerate_settings_do_not_break_it()
	_test_the_node_clamps_its_own_properties()
	_test_the_keys_drive_the_spawner()
	_test_the_readout_reports_the_shape()
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

const SPAWNER := preload("res://addons/ring_tools/ring_spawner.gd")
var _scene: Node2D

func _make() -> Node2D:
	if is_instance_valid(_scene):
		remove_child(_scene)
		_scene.free()
	_scene = load("res://scenes/main.tscn").instantiate()
	add_child(_scene)
	return _scene

func _press(m: Node2D, code: Key) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.pressed = true
	m._unhandled_key_input(e)

func _test_the_plugin_is_declared() -> void:
	print("the plugin")
	expect(FileAccess.file_exists("res://addons/ring_tools/plugin.cfg"),
		"the plugin declares itself in a plugin.cfg")
	var cfg := ConfigFile.new()
	expect(cfg.load("res://addons/ring_tools/plugin.cfg") == OK, "which parses")
	expect(str(cfg.get_value("plugin", "script", "")) != "", "and names its entry script")
	expect(ResourceLoader.exists("res://addons/ring_tools/plugin.gd"), "which is there")

func _test_what_it_adds_it_also_removes() -> void:
	print("teardown")
	var source: String = (load("res://addons/ring_tools/plugin.gd") as GDScript).source_code
	# Godot cleans up neither docks nor custom types, so a plugin that adds
	# without removing leaves duplicates behind every time it reloads — and it
	# reloads constantly while you are writing it.
	expect(source.contains("add_custom_type"), "the plugin registers its node type")
	expect(source.contains("remove_custom_type"), "and unregisters it again")
	expect(source.contains("add_control_to_dock"), "it adds its dock")
	expect(source.contains("remove_control_from_docks"), "and takes it away again")

func _test_the_ring_is_a_closed_figure() -> void:
	print("the ring")
	var ring := SPAWNER.build(12, 100.0, 1)
	expect(ring.size() == 12, "twelve points make twelve vertices")
	begin_quiet()
	for point in ring:
		expect_quiet(is_equal_approx(point.length(), 100.0),
			"a vertex sits %.1f from the centre rather than on the ring" % point.length())
	expect(_quiet_failures == 0, "every vertex sits on the circle")

func _test_more_points_make_a_rounder_ring() -> void:
	print("resolution")
	expect(SPAWNER.build(6, 100.0, 1).size() == 6, "six points, six vertices")
	expect(SPAWNER.build(24, 100.0, 1).size() == 24, "and twenty-four, twenty-four")

func _test_the_radius_sets_the_size() -> void:
	print("radius")
	var small := SPAWNER.build(8, 50.0, 1)
	var large := SPAWNER.build(8, 200.0, 1)
	expect(is_equal_approx(small[0].length(), 50.0), "a small ring is small")
	expect(is_equal_approx(large[0].length(), 200.0), "and a large one large")
	expect(small.size() == large.size(), "with the same number of vertices either way")

func _test_a_stride_makes_a_star() -> void:
	print("stars")
	var ring := SPAWNER.build(7, 100.0, 1)
	var star := SPAWNER.build(7, 100.0, 2)
	expect(star.size() == ring.size(), "a stride of two over seven points visits them all")
	# Same vertices, different order — that is what turns a ring into a star.
	expect(star[1] != ring[1], "but in a different order, which is the star")

func _test_a_stride_that_divides_the_ring_closes_early() -> void:
	print("closing early")
	# Two into eight comes back to the start after four, so the walk has to
	# stop there rather than going round for ever.
	var figure := SPAWNER.build(8, 100.0, 2)
	expect(figure.size() == 4, "a stride of two over eight points closes after four")
	var unique := {}
	for point in figure:
		unique[point] = true
	expect(unique.size() == figure.size(), "with no vertex used twice")

func _test_degenerate_settings_do_not_break_it() -> void:
	print("bad settings")
	begin_quiet()
	for settings in [[0, 100.0, 1], [1, 100.0, 1], [12, 100.0, 0], [-4, 100.0, -2]]:
		var figure: PackedVector2Array = SPAWNER.build(settings[0], settings[1], settings[2])
		# A zero point count or a zero stride would divide by zero or loop for
		# ever; the clamps inside build() are what stop it.
		expect_quiet(figure.size() >= 1, "settings %s produced nothing at all" % str(settings))
		for point in figure:
			expect_quiet(not is_nan(point.x) and not is_nan(point.y),
				"settings %s produced a NaN vertex" % str(settings))
	expect(_quiet_failures == 0, "no setting produces an empty or broken figure")

func _test_the_node_clamps_its_own_properties() -> void:
	print("the node")
	var node: Node2D = SPAWNER.new()
	node.points = -5
	expect(node.points >= 1, "the point count cannot go below one")
	node.skip = 0
	expect(node.skip >= 1, "the stride cannot go below one")
	node.radius = -50.0
	expect(node.radius > 0.0, "and the radius stays positive")
	node.free()

func _test_the_keys_drive_the_spawner() -> void:
	print("the keys")
	var m := _make()
	var spawner: Node2D = m.get_node("RingSpawner")
	var points: int = spawner.points
	_press(m, KEY_2)
	expect(spawner.points == points + 1, "a key adds a point")
	_press(m, KEY_1)
	expect(spawner.points == points, "and another takes it away")

	var radius: float = spawner.radius
	_press(m, KEY_6)
	expect(spawner.radius > radius, "a key grows the ring")
	_press(m, KEY_5)
	expect(is_equal_approx(spawner.radius, radius), "and another shrinks it")

	for i in 40:
		_press(m, KEY_1)
	expect(spawner.points >= 3, "the point count stops at a figure that is still a shape")

func _test_the_readout_reports_the_shape() -> void:
	print("the readout")
	var m := _make()
	var spawner: Node2D = m.get_node("RingSpawner")
	var status: Label = m.get_node("HUD/StatusLabel")
	expect(status.text.contains(str(spawner.points)), "the readout names the point count")
	expect(status.text.contains(str(spawner.polygon().size())),
		"and how many vertices that actually drew, which differ once a stride closes early")

var _quiet_failures := 0

## Zero the tally, so one test's failures cannot cascade into the next.
func begin_quiet() -> void:
	_quiet_failures = 0

func expect_quiet(cond: bool, label: String) -> void:
	if not cond:
		_quiet_failures += 1
		print("  (", label, " — failed)")
