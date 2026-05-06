extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_initial_active()
	_test_transition()
	_test_exit_called()
	_test_enter_default_child()
	_test_active_path()
	_test_parent_exit_exits_child()
	_report()

func expect(condition: bool, label: String) -> void:
	if condition:
		_pass += 1
		print("  PASS: %s" % label)
	else:
		_fail += 1
		print("  FAIL: %s" % label)

func _report() -> void:
	print("--- Results: %d passed, %d failed ---" % [_pass, _fail])

# ──────────────────────── Tests ────────────────────────

func _test_initial_active() -> void:
	print("Test: initial active child after enter()")
	var root  := HFSMState.new("Root")
	var alive := HFSMState.new("Alive")
	var dead  := HFSMState.new("Dead")
	root.add_child(alive)
	root.add_child(dead)
	root.enter()
	expect(root.active_child == alive, "root.active_child is alive (first child)")

func _test_transition() -> void:
	print("Test: transition_to changes active child")
	var root  := HFSMState.new("Root")
	var idle  := HFSMState.new("Idle")
	var walk  := HFSMState.new("Walk")
	root.add_child(idle)
	root.add_child(walk)
	root.enter()
	expect(idle.is_active(), "idle is active before transition")
	root.transition_to(walk)
	expect(walk.is_active(), "walk is active after transition")
	expect(not idle.is_active(), "idle is not active after transition")

func _test_exit_called() -> void:
	print("Test: exit callable fires on transition away")
	var root    := HFSMState.new("Root")
	var idle    := HFSMState.new("Idle")
	var walk    := HFSMState.new("Walk")
	var exited  := false
	idle._on_exit = func(): exited = true
	root.add_child(idle)
	root.add_child(walk)
	root.enter()
	root.transition_to(walk)
	expect(exited, "_on_exit was called when leaving idle")

func _test_enter_default_child() -> void:
	print("Test: transitioning to Combat enters first child (Attack) by default")
	var root    := HFSMState.new("Root")
	var alive   := HFSMState.new("Alive")
	var combat  := HFSMState.new("Combat")
	var attack  := HFSMState.new("Attack")
	var block   := HFSMState.new("Block")
	root.add_child(alive)
	alive.add_child(combat)
	combat.add_child(attack)
	combat.add_child(block)
	root.enter()
	alive.transition_to(combat)
	expect(combat.active_child == attack, "combat.active_child is attack (default first child)")
	expect(attack.is_active(), "attack.is_active() == true")

func _test_active_path() -> void:
	print("Test: get_active_path returns full hierarchy")
	var root    := HFSMState.new("Root")
	var alive   := HFSMState.new("Alive")
	var combat  := HFSMState.new("Combat")
	var attack  := HFSMState.new("Attack")
	var block   := HFSMState.new("Block")
	root.add_child(alive)
	alive.add_child(combat)
	combat.add_child(attack)
	combat.add_child(block)
	root.enter()
	alive.transition_to(combat)
	combat.transition_to(block)
	var path := root.get_active_path()
	expect(path.size() == 4, "path has 4 elements (got %d)" % path.size())
	expect(path.size() >= 1 and path[0] == "Root",   "path[0] == Root")
	expect(path.size() >= 2 and path[1] == "Alive",  "path[1] == Alive")
	expect(path.size() >= 3 and path[2] == "Combat", "path[2] == Combat")
	expect(path.size() >= 4 and path[3] == "Block",  "path[3] == Block")

func _test_parent_exit_exits_child() -> void:
	print("Test: exiting Alive also exits its active child (Combat)")
	var root    := HFSMState.new("Root")
	var alive   := HFSMState.new("Alive")
	var dead    := HFSMState.new("Dead")
	var combat  := HFSMState.new("Combat")
	var attack  := HFSMState.new("Attack")
	var combat_exited := false
	combat._on_exit = func(): combat_exited = true
	root.add_child(alive)
	root.add_child(dead)
	alive.add_child(combat)
	combat.add_child(attack)
	root.enter()
	alive.transition_to(combat)
	# Now transition root away from alive (which should exit combat too)
	root.transition_to(dead)
	expect(combat_exited, "combat._on_exit fired when alive was exited")
