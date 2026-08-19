extends Node

# Drives the real readout from scenes/main.tscn — see docs/TEST_INTEGRITY.md.
#
# There is no gamepad in a test run, so this covers the parts that do not need
# one: the deadzone rule, the name tables the readout is built from, and what
# the demo shows when nothing is plugged in — which is the state most people
# will actually see it in.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_a_resting_stick_reads_as_zero()
	_test_a_pushed_stick_reads_through_untouched()
	_test_the_deadzone_is_symmetric()
	_test_the_deadzone_is_small_enough_to_be_usable()
	_test_every_axis_is_named()
	_test_every_button_is_named()
	_test_the_names_are_unique()
	_test_it_says_when_nothing_is_plugged_in()
	_test_the_readout_rests_at_zero_without_a_pad()
	_test_vibrating_without_a_pad_is_harmless()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[gamepad-input] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

var _scene: Node2D

func _make() -> Node2D:
	if is_instance_valid(_scene):
		remove_child(_scene)
		_scene.free()
	_scene = load("res://scenes/main.tscn").instantiate()
	add_child(_scene)
	return _scene

func _test_a_resting_stick_reads_as_zero() -> void:
	print("the deadzone")
	var m := _make()
	begin_quiet()
	for drift in [0.0, 0.01, m.DEADZONE * 0.5, -m.DEADZONE * 0.9]:
		expect_quiet(is_zero_approx(m.apply_deadzone(drift)),
			"a drift of %.3f was reported as movement" % drift)
	expect(_quiet_failures == 0, "small readings from a resting stick are ignored")

func _test_a_pushed_stick_reads_through_untouched() -> void:
	print("real movement")
	var m := _make()
	expect(is_equal_approx(m.apply_deadzone(1.0), 1.0), "a stick at full tilt reads full")
	expect(is_equal_approx(m.apply_deadzone(-1.0), -1.0), "in both directions")
	var past: float = m.DEADZONE + 0.05
	expect(is_equal_approx(m.apply_deadzone(past), past),
		"and a push past the deadzone is passed through as it is, not rescaled")

func _test_the_deadzone_is_symmetric() -> void:
	print("both directions")
	var m := _make()
	var push: float = m.DEADZONE + 0.2
	expect(is_equal_approx(m.apply_deadzone(push), -m.apply_deadzone(-push)),
		"pushing left and right of centre are treated the same")

func _test_the_deadzone_is_small_enough_to_be_usable() -> void:
	print("the size of it")
	var m := _make()
	expect(m.DEADZONE > 0.0, "there is a deadzone at all")
	# Too wide and half the stick's travel does nothing.
	expect(m.DEADZONE < 0.5, "and it takes up a small part of the stick's travel")

func _test_every_axis_is_named() -> void:
	print("the axis table")
	var m := _make()
	expect(m.AXIS_NAMES.size() >= 6, "both sticks and both triggers are listed")
	begin_quiet()
	for axis in m.AXIS_NAMES:
		expect_quiet(str(m.AXIS_NAMES[axis]).length() > 0, "an axis has no name")
	expect(_quiet_failures == 0, "every listed axis has a name to show")

func _test_every_button_is_named() -> void:
	print("the button table")
	var m := _make()
	expect(m.BUTTON_NAMES.size() >= 12, "the face, shoulder, stick and d-pad buttons are listed")
	begin_quiet()
	for button in m.BUTTON_NAMES:
		expect_quiet(str(m.BUTTON_NAMES[button]).length() > 0, "a button has no name")
	expect(_quiet_failures == 0, "every listed button has a name to show")

func _test_the_names_are_unique() -> void:
	print("no duplicates")
	var m := _make()
	# A duplicated name means two different inputs report as the same thing,
	# which is exactly what this demo exists to rule out.
	var axis_names := {}
	for axis in m.AXIS_NAMES:
		axis_names[m.AXIS_NAMES[axis]] = true
	expect(axis_names.size() == m.AXIS_NAMES.size(), "no two axes share a name")

	var button_names := {}
	for button in m.BUTTON_NAMES:
		button_names[m.BUTTON_NAMES[button]] = true
	expect(button_names.size() == m.BUTTON_NAMES.size(), "and no two buttons do")

func _test_it_says_when_nothing_is_plugged_in() -> void:
	print("no gamepad")
	var m := _make()
	m._refresh_devices()
	# The state most people will see first, so it has to say something useful
	# rather than sit blank.
	expect(m.connected_label.text.length() > 0, "the demo says something about the missing pad")
	expect(m.connected_label.text.to_lower().contains("no gamepad"), "naming the problem")
	expect(m.connected_label.modulate != Color.WHITE, "and colours it as a warning")

## Without a pad the demo shows the panel at rest rather than nothing at all.
##
## It used to blank the readout, which left anyone without a gamepad — including
## anyone reading the gallery — looking at an empty window. The list of axis
## names is half of what this demo is for and does not need hardware to be worth
## reading. What must not survive is a *reading*: a value left over from a pad
## that has been unplugged would be a lie.
func _test_the_readout_rests_at_zero_without_a_pad() -> void:
	print("the readout")
	var m := _make()
	m.axis_label.text = "stale"
	m.button_label.text = "stale"
	m._process(0.0)

	expect(m.active_pad() == m.NO_PAD, "the demo knows there is no pad")
	expect(not m.axis_label.text.contains("stale"), "the readout is rewritten, not left as it was")
	expect(m.button_label.text.contains("(none)"), "no buttons are reported as pressed")

	_quiet_failures = 0
	for axis_name in m.AXIS_NAMES.values():
		expect_quiet(m.axis_label.text.contains(axis_name), "%s is listed" % axis_name)
	expect(_quiet_failures == 0, "every axis is named even with nothing plugged in")

	# Every reading is zero — the panel is at rest, not reporting phantom input.
	var readings := 0
	for line in m.axis_label.text.split("\n"):
		var parts: PackedStringArray = (line as String).split("  ", false)
		if parts.size() < 2:
			continue
		readings += 1
		expect_quiet(parts[parts.size() - 1].strip_edges() == "0.000",
			"%s reads zero" % parts[0])
	expect(readings == m.AXIS_NAMES.size(), "one line per axis (%d)" % readings)
	expect(_quiet_failures == 0, "and every one of them reads zero")

	# The same call with a pad id must still go through Input, or the readout
	# would be permanently stuck at rest.
	expect(m.axis_value(m.NO_PAD, JOY_AXIS_LEFT_X) == 0.0, "an absent pad reads zero")

	# The axis list used to be blank here, so the button line was positioned as
	# if nothing were above it. Now that the list is always six axes long, the
	# two labels have to be checked against each other rather than eyeballed.
	var axes_bottom: float = m.axis_label.position.y + m.axis_label.get_minimum_size().y
	expect(axes_bottom <= m.button_label.position.y,
		"the axis list ends above the button line (%.0f <= %.0f)"
		% [axes_bottom, m.button_label.position.y])


func _test_vibrating_without_a_pad_is_harmless() -> void:
	print("the vibrate button")
	var m := _make()
	(m.get_node("VibrateBtn") as Button).pressed.emit()
	expect(true, "pressing vibrate with nothing plugged in does not fall over")

var _quiet_failures := 0

## Zero the tally, so one test's failures cannot cascade into the next.
func begin_quiet() -> void:
	_quiet_failures = 0

func expect_quiet(cond: bool, label: String) -> void:
	if not cond:
		_quiet_failures += 1
		print("  (", label, " — failed)")
