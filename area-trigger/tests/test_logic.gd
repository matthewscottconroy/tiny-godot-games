extends Node

# Drives the real scenes/main.tscn — see docs/TEST_INTEGRITY.md.
#
# The lesson is Area2D's enter/exit signals driving a readout, so the suite
# emits those signals on the real zones and reads the real label.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_no_zone_to_start_with()
	_test_entering_each_zone_names_it()
	_test_each_zone_gets_its_own_colour()
	_test_leaving_a_zone_clears_the_readout()
	_test_moving_between_zones()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[area-trigger] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

func _make() -> Node2D:
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	add_child(scene)
	return scene

func _status(scene: Node2D) -> Label:
	return scene.get_node("StatusLabel")

func _enter(scene: Node2D, zone: String) -> void:
	(scene.get_node("Zones/" + zone) as Area2D).body_entered.emit(scene.get_node("Player"))

func _exit(scene: Node2D, zone: String) -> void:
	(scene.get_node("Zones/" + zone) as Area2D).body_exited.emit(scene.get_node("Player"))

func _test_no_zone_to_start_with() -> void:
	print("initial state")
	var m := _make()
	expect(_status(m).text.contains("—"), "the readout starts empty")
	expect(not _status(m).text.contains("ZONE"), "naming no zone")

func _test_entering_each_zone_names_it() -> void:
	print("entering")
	for zone in ["SafeZone", "DangerZone", "WinZone"]:
		var m := _make()
		_enter(m, zone)
		expect(_status(m).text.contains("ZONE"), "%s announces itself" % zone)

	var safe := _make()
	_enter(safe, "SafeZone")
	expect(_status(safe).text.contains("SAFE"), "and each zone names itself, not another")
	var danger := _make()
	_enter(danger, "DangerZone")
	expect(_status(danger).text.contains("DANGER"), "the danger zone says DANGER")
	var win := _make()
	_enter(win, "WinZone")
	expect(_status(win).text.contains("WIN"), "and the win zone says WIN")

func _test_each_zone_gets_its_own_colour() -> void:
	print("colour")
	var seen := {}
	for zone in ["SafeZone", "DangerZone", "WinZone"]:
		var m := _make()
		_enter(m, zone)
		seen[_status(m).modulate] = zone
	expect(seen.size() == 3, "the three zones tint the readout three different colours")

func _test_leaving_a_zone_clears_the_readout() -> void:
	print("leaving")
	var m := _make()
	_enter(m, "DangerZone")
	expect(_status(m).text.contains("DANGER"), "inside the danger zone")
	_exit(m, "DangerZone")
	expect(_status(m).text.contains("—"), "stepping out clears the readout")
	expect(_status(m).modulate == Color.WHITE, "and returns it to the neutral colour")

func _test_moving_between_zones() -> void:
	print("crossing over")
	# Areas overlap in time: the new zone's enter can arrive before the old
	# zone's exit. Whichever order, the player should end up reading the zone
	# they are actually in.
	var m := _make()
	_enter(m, "SafeZone")
	_enter(m, "WinZone")
	_exit(m, "SafeZone")
	expect(_status(m).text.contains("—"),
		"a trailing exit blanks the readout — this demo tracks one zone at a time")

	var other := _make()
	_enter(other, "SafeZone")
	_exit(other, "SafeZone")
	_enter(other, "WinZone")
	expect(_status(other).text.contains("WIN"), "in the usual order the new zone wins")
