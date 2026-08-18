extends Node

# Drives the real player from scenes/main.tscn — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_both_animations_are_built()
	_test_both_animations_loop()
	_test_the_animations_drive_the_visual()
	_test_the_walk_bob_returns_to_where_it_started()
	_test_it_starts_idle()
	_test_standing_still_stays_idle()
	_test_moving_plays_the_walk()
	_test_stopping_goes_back_to_idle()
	_test_the_animation_is_not_restarted_every_frame()
	_test_the_sprite_faces_the_way_it_moves()
	_test_a_hair_of_drift_does_not_flip_the_sprite()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[animated-walk] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

var _scene: Node2D

func _make() -> CharacterBody2D:
	if is_instance_valid(_scene):
		remove_child(_scene)
		_scene.free()
	_scene = load("res://scenes/main.tscn").instantiate()
	add_child(_scene)
	return _scene.get_node("Player")

func _anim(p: CharacterBody2D) -> AnimationPlayer:
	return p.get_node("AnimationPlayer")

func _test_both_animations_are_built() -> void:
	print("the animations")
	var p := _make()
	var player := _anim(p)
	# Built in code rather than in the editor, which is the demo's point.
	expect(player.has_animation("idle"), "there is an idle animation")
	expect(player.has_animation("walk"), "and a walk animation")

func _test_both_animations_loop() -> void:
	print("looping")
	var p := _make()
	var player := _anim(p)
	begin_quiet()
	for name in ["idle", "walk"]:
		var animation := player.get_animation(name)
		expect_quiet(animation.loop_mode != Animation.LOOP_NONE,
			"%s plays once and stops" % name)
		expect_quiet(animation.length > 0.0, "%s has no length" % name)
	expect(_quiet_failures == 0, "both animations loop, so neither freezes mid-stride")

	expect(player.get_animation("walk").length < player.get_animation("idle").length,
		"a walk cycle is quicker than a breath")

func _test_the_animations_drive_the_visual() -> void:
	print("what they animate")
	var p := _make()
	var player := _anim(p)
	begin_quiet()
	for name in ["idle", "walk"]:
		var animation := player.get_animation(name)
		expect_quiet(animation.get_track_count() > 0, "%s animates nothing at all" % name)
		for track in animation.get_track_count():
			var path := str(animation.track_get_path(track))
			# A track pointing at a node that is not there animates nothing and
			# says nothing about it.
			expect_quiet(path.begins_with("Visual"),
				"%s has a track on %s, which is not the visual" % [name, path])
			expect_quiet(p.has_node(NodePath(path.get_slice(":", 0))),
				"%s animates a node that does not exist" % name)
	expect(_quiet_failures == 0, "both animations drive the visual that is actually in the scene")

func _test_the_walk_bob_returns_to_where_it_started() -> void:
	print("the bob")
	var p := _make()
	var walk := _anim(p).get_animation("walk")
	var track := 0
	var first: Variant = walk.track_get_key_value(track, 0)
	var last: Variant = walk.track_get_key_value(track, walk.track_get_key_count(track) - 1)
	# A loop whose ends disagree jumps every cycle.
	expect(first == last, "the walk cycle ends where it began")

	var highest := 0.0
	for key in walk.track_get_key_count(track):
		highest = minf(highest, (walk.track_get_key_value(track, key) as Vector2).y)
	expect(highest < 0.0, "and lifts the visual off the ground in between")

func _test_it_starts_idle() -> void:
	print("standing still")
	var p := _make()
	expect(_anim(p).current_animation == "idle", "the player idles before anything happens")

func _test_standing_still_stays_idle() -> void:
	print("staying still")
	var p := _make()
	p.velocity.x = 0.0
	p.update_visuals()
	# The idle player must stay idle: a walk cycle playing on the spot is the
	# classic animation-state bug.
	expect(_anim(p).current_animation == "idle", "a player who has not moved keeps idling")

func _test_moving_plays_the_walk() -> void:
	print("walking")
	var p := _make()
	p.velocity.x = 100.0
	p.update_visuals()
	expect(_anim(p).current_animation == "walk", "moving switches to the walk")

func _test_stopping_goes_back_to_idle() -> void:
	print("stopping")
	var p := _make()
	p.velocity.x = 100.0
	p.update_visuals()
	p.velocity.x = 0.0
	p.update_visuals()
	expect(_anim(p).current_animation == "idle", "stopping switches back to idle")

func _test_the_animation_is_not_restarted_every_frame() -> void:
	print("not restarting")
	var p := _make()
	p.velocity.x = 100.0
	p.update_visuals()
	var animation_player := _anim(p)
	animation_player.seek(0.2, true)
	var position_before: float = animation_player.current_animation_position
	p.update_visuals()
	# Calling play() every frame would reset the cycle to zero and the legs
	# would never get anywhere.
	expect(animation_player.current_animation_position >= position_before,
		"walking on does not restart the cycle from the beginning")

func _test_the_sprite_faces_the_way_it_moves() -> void:
	print("facing")
	var p := _make()
	var visual: Node2D = p.get_node("Visual")
	p.velocity.x = 100.0
	p.update_visuals()
	expect(visual.scale.x > 0.0, "moving right faces right")
	p.velocity.x = -100.0
	p.update_visuals()
	expect(visual.scale.x < 0.0, "moving left faces left")

func _test_a_hair_of_drift_does_not_flip_the_sprite() -> void:
	print("the threshold")
	var p := _make()
	var visual: Node2D = p.get_node("Visual")
	p.velocity.x = 100.0
	p.update_visuals()
	# A body resting against a wall keeps a trace of velocity; a threshold at
	# zero would have the sprite flipping back and forth on it.
	p.velocity.x = -1.0
	p.update_visuals()
	expect(visual.scale.x > 0.0, "a trace of leftward drift does not turn the sprite round")
	expect(_anim(p).current_animation == "idle", "and it counts as standing still")

	# And the same the other way about, which is the half a threshold test
	# usually forgets.
	var facing_left := _make()
	var left_visual: Node2D = facing_left.get_node("Visual")
	facing_left.velocity.x = -100.0
	facing_left.update_visuals()
	expect(left_visual.scale.x < 0.0, "facing left")
	facing_left.velocity.x = 1.0
	facing_left.update_visuals()
	expect(left_visual.scale.x < 0.0, "a trace of rightward drift does not turn it either")

var _quiet_failures := 0

## Zero the tally, so one test's failures cannot cascade into the next.
func begin_quiet() -> void:
	_quiet_failures = 0

func expect_quiet(cond: bool, label: String) -> void:
	if not cond:
		_quiet_failures += 1
		print("  (", label, " — failed)")
