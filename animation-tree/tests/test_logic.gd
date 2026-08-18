extends Node

# Drives the real state machine from scenes/main.tscn — see docs/TEST_INTEGRITY.md.
#
# The AnimationTree needs a couple of frames before its playback object exists,
# so the suite waits for the demo's own initialisation.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_every_state_has_an_animation()
	_test_the_looping_states_loop_and_the_one_shots_do_not()
	_test_the_animations_drive_the_visual()
	_test_the_state_machine_has_a_way_in()
	_test_every_transition_joins_two_real_states()
	_test_the_graph_has_no_dead_ends()
	await _test_it_settles_into_idle()
	await _test_walking_and_stopping()
	await _test_jumping_falling_and_landing()
	await _test_the_player_stays_on_screen()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[animation-tree] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

const STATES := ["idle", "walk", "jump", "fall", "land"]
const STEP := 1.0 / 60.0
var _scene: Node2D

func _make() -> Node2D:
	if is_instance_valid(_scene):
		remove_child(_scene)
		_scene.free()
	_scene = load("res://scenes/main.tscn").instantiate()
	add_child(_scene)
	return _scene

## Run the demo until its playback is live, then a few frames more.
func _start(m: Node2D) -> void:
	for i in 20:
		await get_tree().physics_frame
		if m._initialized:
			break

func _machine(m: Node2D) -> AnimationNodeStateMachine:
	return (m.get_node("Player/AnimationTree") as AnimationTree).tree_root

func _test_every_state_has_an_animation() -> void:
	print("the states")
	var m := _make()
	var machine := _machine(m)
	var player: AnimationPlayer = m.get_node("Player/AnimationPlayer")
	begin_quiet()
	for name in STATES:
		expect_quiet(machine.has_node(name), "the machine has no %s state" % name)
		expect_quiet(player.has_animation(name), "there is no %s animation to play" % name)
	expect(_quiet_failures == 0, "every state names an animation that exists")

func _test_the_looping_states_loop_and_the_one_shots_do_not() -> void:
	print("looping")
	var m := _make()
	var player: AnimationPlayer = m.get_node("Player/AnimationPlayer")
	# A held state that does not loop freezes on its last frame; a one-shot
	# that loops never lets the machine move on.
	for name in ["idle", "walk", "fall"]:
		expect(player.get_animation(name).loop_mode != Animation.LOOP_NONE,
			"%s is a state the player can sit in, so it loops" % name)
	for name in ["jump", "land"]:
		expect(player.get_animation(name).loop_mode == Animation.LOOP_NONE,
			"%s plays once and hands over" % name)

func _test_the_animations_drive_the_visual() -> void:
	print("what they animate")
	var m := _make()
	var player: AnimationPlayer = m.get_node("Player/AnimationPlayer")
	begin_quiet()
	for name in STATES:
		var animation := player.get_animation(name)
		expect_quiet(animation.get_track_count() > 0, "%s animates nothing" % name)
		for track in animation.get_track_count():
			var path := str(animation.track_get_path(track))
			expect_quiet(path.begins_with("Visual"), "%s animates %s, not the visual" % [name, path])
	expect(_quiet_failures == 0, "every animation drives the visual")

func _test_the_state_machine_has_a_way_in() -> void:
	print("the entry")
	var m := _make()
	var machine := _machine(m)
	# Without a transition from Start the machine never begins and the player
	# stands frozen.
	expect(machine.has_transition("Start", "idle"), "the machine starts in idle")

func _test_every_transition_joins_two_real_states() -> void:
	print("the transitions")
	var m := _make()
	var machine := _machine(m)
	begin_quiet()
	for i in machine.get_transition_count():
		var from := str(machine.get_transition_from(i))
		var to := str(machine.get_transition_to(i))
		expect_quiet(from == "Start" or machine.has_node(from),
			"a transition comes from %s, which is not a state" % from)
		expect_quiet(machine.has_node(to), "a transition goes to %s, which is not a state" % to)
	expect(_quiet_failures == 0, "every transition joins states that exist")

func _test_the_graph_has_no_dead_ends() -> void:
	print("dead ends")
	var m := _make()
	var machine := _machine(m)
	begin_quiet()
	for name in STATES:
		var out := 0
		for i in machine.get_transition_count():
			if str(machine.get_transition_from(i)) == name:
				out += 1
		# A state with no way out traps the animation there for good.
		expect_quiet(out > 0, "%s has no transition out of it" % name)
	expect(_quiet_failures == 0, "every state has a way out again")

func _test_it_settles_into_idle() -> void:
	print("starting up")
	var m := _make()
	await _start(m)
	expect(m._initialized, "the playback comes up")
	expect(m._playback != null, "and the demo takes hold of it")
	for i in 10:
		await get_tree().physics_frame
	expect(m._playback.get_current_node() == "idle", "the player settles into idle")

## Let the tree act on a travel() request. It is a request processed on the
## tree's own frame, not an assignment.
##
## One frame, not several: the demo reads the movement keys every physics
## frame, so a velocity set by hand survives exactly one before the demo puts
## it back to nothing and the machine returns to idle.
func _settle(m: Node2D) -> void:
	await get_tree().physics_frame

func _test_walking_and_stopping() -> void:
	print("walking")
	var m := _make()
	await _start(m)
	m._vel.x = 100.0
	m._update_state()
	await _settle(m)
	expect(m._playback.get_current_node() == "walk", "moving switches to the walk")

	m._vel.x = 0.0
	m._update_state()
	await _settle(m)
	expect(m._playback.get_current_node() == "idle", "and stopping switches back")

	m._vel.x = 5.0
	m._update_state()
	await _settle(m)
	# The threshold sits above zero, so a trace of drift is still standing still.
	expect(m._playback.get_current_node() == "idle", "a trace of drift is not walking")

func _test_jumping_falling_and_landing() -> void:
	print("the jump arc")
	var m := _make()
	await _start(m)
	# Lifted well clear of the floor, not merely flagged as airborne: the
	# demo's own physics lands anything at or below FLOOR_Y on the next frame,
	# which would take the state to "land" before the tree ever saw the fall.
	m._player.position.y = m.FLOOR_Y - 150.0
	m._on_floor = false
	m._vel.y = 200.0
	m._update_state()
	await _settle(m)
	expect(m._playback.get_current_node() == "fall", "falling switches to the fall")

	m._on_floor = true
	m._playback.travel("land")
	await _settle(m)
	m._vel.x = 0.0
	m._update_state()
	await _settle(m)
	expect(m._playback.get_current_node() in ["land", "idle"],
		"landing plays the land before returning to idle")

func _test_the_player_stays_on_screen() -> void:
	print("the edges")
	var m := _make()
	await _start(m)
	m._player.position.x = 10.0
	m._vel = Vector2(-500.0, 0.0)
	await get_tree().physics_frame
	expect(m._player.position.x >= 20.0, "walking off the left is stopped at the edge")
	m._player.position.x = 700.0
	m._vel = Vector2(500.0, 0.0)
	await get_tree().physics_frame
	expect(m._player.position.x <= 620.0, "and the right")
	expect(m._player.position.y <= m.FLOOR_Y, "and the player never sinks below the floor")

var _quiet_failures := 0

## Zero the tally, so one test's failures cannot cascade into the next.
func begin_quiet() -> void:
	_quiet_failures = 0

func expect_quiet(cond: bool, label: String) -> void:
	if not cond:
		_quiet_failures += 1
		print("  (", label, " — failed)")
