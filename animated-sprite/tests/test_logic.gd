extends Node

# Drives the real demo from scripts/main.gd — see docs/TEST_INTEGRITY.md.
#
# This suite used to restate the animation rules inline and check its own copy
# against itself, which is why every mutation to the demo survived it: the demo
# and the test could disagree and only the test was ever consulted.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_constants()
	_test_gravity_accumulation()
	_test_floor_clamp()
	_test_screen_wrap()
	_test_animation_state_ground()
	_test_animation_state_airborne()
	await _test_the_clips_are_built_the_way_each_is_used()
	await _test_the_facing_holds_when_the_key_is_released()
	await _test_the_character_starts_on_the_ground()
	await _test_landing_puts_it_back_on_the_floor()
	await _test_the_legs_alternate_through_the_walk_cycle()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func expect_near(a: float, b: float, label: String, tol: float = 0.01) -> void:
	expect(absf(a - b) <= tol, label)

func _test_constants() -> void:
	print("constants")
	# Read the values off the demo's own script rather than restating literals —
	# comparing 180.0 to 180.0 asserts nothing and cannot fail.
	var player: GDScript = load("res://scripts/main.gd")
	expect(player.SPEED == 180.0, "SPEED is 180")
	expect(player.JUMP_VEL == -420.0, "JUMP_VEL is -420")
	expect(player.GRAVITY == 900.0, "GRAVITY is 900")

func _test_gravity_accumulation() -> void:
	print("gravity accumulation")
	const GRAVITY := 900.0
	var vel_y := 0.0
	vel_y += GRAVITY * 0.016
	expect_near(vel_y, 14.4, "gravity accumulates after one frame")
	vel_y += GRAVITY * 0.016
	expect_near(vel_y, 28.8, "gravity accumulates after two frames")

func _test_floor_clamp() -> void:
	print("floor clamp at y=450")
	var pos_y := 460.0
	var vel_y := 30.0
	if pos_y >= 450.0:
		pos_y = 450.0
		vel_y = 0.0
	expect(pos_y == 450.0, "position clamped to 450")
	expect(vel_y == 0.0, "vertical velocity zeroed on floor")

func _test_screen_wrap() -> void:
	print("screen wrap wrapf(-20, 660)")
	expect_near(wrapf(-25.0, -20.0, 660.0), 655.0, "wrap below min")
	expect_near(wrapf(661.0, -20.0, 660.0), -19.0, "wrap above max")
	expect_near(wrapf(320.0, -20.0, 660.0), 320.0, "mid value unchanged")

func _test_animation_state_ground() -> void:
	print("animation state on ground")
	var m := _script()
	expect(m.animation_for(true, Vector2.ZERO) == "idle", "stationary on floor -> idle")
	expect(m.animation_for(true, Vector2(50, 0)) == "walk", "moving on floor -> walk")
	expect(m.animation_for(true, Vector2(-50, 0)) == "walk", "and moving the other way too")

	# The threshold is what stops a fraction of a pixel of drift playing the
	# walk cycle, so both sides of it are worth pinning.
	var t: float = m.WALK_THRESHOLD
	expect(m.animation_for(true, Vector2(t - 0.5, 0)) == "idle",
		"just under the walk threshold is still idle")
	expect(m.animation_for(true, Vector2(t + 0.5, 0)) == "walk",
		"just over it is walking")
	expect(m.animation_for(true, Vector2(-(t + 0.5), 0)) == "walk",
		"the threshold is on speed, not direction")
	m.free()

func _test_animation_state_airborne() -> void:
	print("animation state airborne")
	var m := _script()
	# Up is negative Y. Getting this backwards plays the falling frame on the
	# way up, which is the sort of thing nobody notices in code review.
	expect(m.animation_for(false, Vector2(0, -200)) == "jump", "rising -> jump")
	expect(m.animation_for(false, Vector2(0, 100)) == "fall", "falling -> fall")
	expect(m.animation_for(false, Vector2(0, 0)) == "fall", "and the apex counts as falling")
	# Airborne wins over horizontal speed, or a running jump plays the walk.
	expect(m.animation_for(false, Vector2(300, -200)) == "jump",
		"a running jump is still a jump, not a walk")
	m.free()

var _scene_node: Node2D = null

## The real scene, one at a time.
func _scene() -> Node2D:
	if _scene_node != null and is_instance_valid(_scene_node):
		remove_child(_scene_node)
		_scene_node.queue_free()
	_scene_node = load("res://scenes/main.tscn").instantiate()
	add_child(_scene_node)
	return _scene_node

## A bare instance of the demo script, for the rules that need no scene.
func _script() -> Node2D:
	return load("res://scripts/main.gd").new()

## Each clip is built to match how the demo uses it: the two ground states cycle
## forever, and the two airborne ones are single poses that must hold on their
## last frame rather than restarting under the character.
func _test_the_clips_are_built_the_way_each_is_used() -> void:
	print("the clips")
	var scene := _scene()
	await get_tree().process_frame
	var frames: SpriteFrames = scene.anim.sprite_frames

	_quiet_failures = 0
	for name in ["idle", "walk", "jump", "fall"]:
		expect_quiet(frames.has_animation(name), "%s exists" % name)
		expect_quiet(frames.get_frame_count(name) > 0, "%s has at least one frame" % name)
	expect(_quiet_failures == 0, "all four clips exist and have frames")

	expect(frames.get_animation_loop("idle"), "idle loops")
	expect(frames.get_animation_loop("walk"), "and so does walk")
	expect(not frames.get_animation_loop("jump"), "jump does not loop — it is one held pose")
	expect(not frames.get_animation_loop("fall"), "nor does fall")

	expect(frames.get_frame_count("walk") > frames.get_frame_count("jump"),
		"walk is a cycle and jump is not (%d frames vs %d)"
		% [frames.get_frame_count("walk"), frames.get_frame_count("jump")])
	expect(frames.get_animation_speed("walk") > frames.get_animation_speed("idle"),
		"and walk plays faster than idle")

	# Pixel art wants no mipmaps: a mipmapped 16x20 sprite blurs into mush the
	# moment it is drawn at anything other than 1:1.
	_quiet_failures = 0
	for name in ["idle", "walk", "jump", "fall"]:
		for i in frames.get_frame_count(name):
			var img: Image = frames.get_frame_texture(name, i).get_image()
			expect_quiet(not img.has_mipmaps(), "%s frame %d has no mipmaps" % [name, i])
	expect(_quiet_failures == 0, "no generated frame carries mipmaps")

	# The idle clip blinks on its last frame. A blink is the eye whites painted
	# over in body colour, so it is the *open* frames that have to be counted —
	# "exactly one frame is different" would pass just as happily if three of
	# the four blinked and one stared.
	var open_eyes := []
	var shut_eyes := []
	for i in frames.get_frame_count("idle"):
		var idle_img: Image = frames.get_frame_texture("idle", i).get_image()
		# (7,4) is eye white on an open frame and body blue on a shut one.
		# Compared by brightness rather than against the literal colour: an
		# RGBA8 image quantises each channel to 1/255, so is_equal_approx never
		# matches a colour written as 0.3.
		var c := idle_img.get_pixel(7, 4)
		if c.r + c.g + c.b > 2.5:
			open_eyes.append(i)
		else:
			shut_eyes.append(i)
	expect(shut_eyes.size() == 1, "exactly one idle frame has its eyes shut (%s)" % [shut_eyes])
	expect(open_eyes.size() == frames.get_frame_count("idle") - 1,
		"the rest are open (%s)" % [open_eyes])
	expect(shut_eyes == [frames.get_frame_count("idle") - 1],
		"and the blink is the last frame of the cycle, not the first (%s)" % [shut_eyes])

## Letting go of the key leaves the character facing the way it was going.
func _test_the_facing_holds_when_the_key_is_released() -> void:
	print("facing")
	var m := _script()
	expect(m.facing_flip(-1.0, false), "pushing left faces left")
	expect(not m.facing_flip(1.0, true), "pushing right faces right")
	expect(m.facing_flip(0.0, true), "releasing while facing left keeps facing left")
	expect(not m.facing_flip(0.0, false), "and releasing while facing right keeps right")
	# Inside the dead zone nothing changes, which is what stops a resting stick
	# from flipping the sprite back and forth.
	var d: float = m.FACING_DEADZONE
	expect(m.facing_flip(d * 0.5, true), "a nudge inside the dead zone changes nothing")
	expect(not m.facing_flip(-d * 0.5, false), "in either direction")
	m.free()

## The demo opens with the character standing, not falling from off-screen.
func _test_the_character_starts_on_the_ground() -> void:
	print("the opening state")
	var scene := _scene()
	await get_tree().process_frame
	expect(scene._on_floor, "the character starts on the floor")
	expect(scene.anim.animation == "idle", "and idling (%s)" % scene.anim.animation)

	# Left to itself it stays there: gravity only applies once it is airborne.
	var started: float = scene.player.position.y
	for _i in 20:
		await get_tree().physics_frame
	expect(absf(scene.player.position.y - started) < 1.0,
		"and does not sink or drift with nothing pressed (%.1f -> %.1f)"
		% [started, scene.player.position.y])
	expect(scene.anim.animation == "idle", "still idling after twenty frames")

	# ...and the idle cycle is actually cycling, rather than holding frame 0
	# forever — which is what a clip built with the wrong speed, or one never
	# played at all, looks like.
	var reached := 0
	for _i in 60:
		await get_tree().process_frame
		reached = maxi(reached, scene.anim.frame)
	expect(reached > 0,
		"the idle clip advances past its first frame (reached %d)" % reached)

## Falling and landing, driven through the demo's own manual physics.
##
## This demo integrates position itself rather than using move_and_slide, so the
## floor is a clamp in _physics_process. That clamp is the whole ground contact:
## get it wrong and the character either sinks through the world or sticks to a
## height it never reached.
func _test_landing_puts_it_back_on_the_floor() -> void:
	print("landing")
	var scene := _scene()
	await get_tree().process_frame

	# High above the floor: a frame of falling must move it a little way down,
	# not snap it to the floor. The clamp only applies at or below the line.
	scene._on_floor = false
	scene.velocity = Vector2(0, 200)
	scene.player.position.y = 300.0
	scene._physics_process(1.0 / 60.0)
	expect(scene.player.position.y > 300.0 and scene.player.position.y < 320.0,
		"a character well above the floor just falls a little (%.1f)" % scene.player.position.y)
	expect(not scene._on_floor, "and is still airborne")

	# Airborne and falling, one frame above the floor line.
	scene._on_floor = false
	scene.velocity = Vector2(0, 200)
	scene.player.position.y = 440.0
	expect(scene.animation_for(scene._on_floor, scene.velocity) == "fall",
		"a falling character plays the fall clip")

	scene._physics_process(1.0 / 60.0)
	expect(scene.player.position.y <= 450.0,
		"it never ends up below the floor (%.1f)" % scene.player.position.y)

	# Keep stepping until it has certainly reached the floor line.
	for _i in 10:
		scene._physics_process(1.0 / 60.0)
	expect(scene.player.position.y == 450.0,
		"and settles exactly on it (%.1f)" % scene.player.position.y)
	expect(scene._on_floor, "landing puts it back on the floor")
	expect(scene.velocity.y == 0.0, "with its fall speed cleared (%.1f)" % scene.velocity.y)
	expect(scene.animation_for(scene._on_floor, scene.velocity) == "idle",
		"so it goes back to idling")

	# And once landed it stays landed: gravity only applies while airborne, so a
	# character on the floor must not accumulate downward speed.
	for _i in 20:
		scene._physics_process(1.0 / 60.0)
	expect(scene.player.position.y == 450.0, "it stays on the floor")
	expect(scene.velocity.y == 0.0, "without gathering speed into it")

## The walk cycle actually moves the legs, and moves them in opposition.
##
## The artwork is generated rather than authored, so it is checkable: the two
## legs take offsets of opposite sign, which is what reads as a stride rather
## than a hop.
func _test_the_legs_alternate_through_the_walk_cycle() -> void:
	print("the walk cycle")
	var scene := _scene()
	await get_tree().process_frame
	var frames: SpriteFrames = scene.anim.sprite_frames

	var rows_left: Array = []
	var rows_right: Array = []
	_quiet_failures = 0
	for i in frames.get_frame_count("walk"):
		var img: Image = frames.get_frame_texture("walk", i).get_image()
		expect_quiet(img.get_height() == 20 and img.get_width() == 16,
			"frame %d is 16x20" % i)
		rows_left.append(_leg_row(img, 6))
		rows_right.append(_leg_row(img, 9))
	expect(_quiet_failures == 0, "every walk frame is the expected size")

	var distinct := {}
	for row in rows_left:
		distinct[row] = true
	expect(distinct.size() > 1,
		"the left leg is not drawn at the same height every frame (%s)" % [rows_left])

	# Opposition: when one leg is forward the other is back. Summing the two
	# rows removes the stride and leaves a constant if they mirror each other.
	var sums := {}
	for i in rows_left.size():
		sums[rows_left[i] + rows_right[i]] = true
	expect(sums.size() == 1,
		"the legs move in opposite directions (%s vs %s)" % [rows_left, rows_right])

## Which row the leg pixel at column `x` is drawn on.
##
## The leg is body_col.darkened(0.3) painted over the body, so it cannot be
## found by transparency — the body is opaque there too. It is the darkest
## pixel in the column, which is exactly what "darkened" means.
func _leg_row(img: Image, x: int) -> int:
	var darkest := 17
	var lowest := 2.0
	for y in range(16, 20):
		var c := img.get_pixel(x, y)
		var luma := c.r + c.g + c.b
		if c.a > 0.5 and luma < lowest:
			lowest = luma
			darkest = y
	return darkest

var _quiet_failures := 0

func expect_quiet(cond: bool, label: String) -> void:
	if not cond:
		_quiet_failures += 1
		print("  (", label, " — failed)")

func _report() -> void:
	var summary := "[animated-sprite] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
