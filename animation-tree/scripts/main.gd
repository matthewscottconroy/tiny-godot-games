extends Node2D

const SPEED := 180.0
const GRAVITY := 620.0
const JUMP_VEL := -330.0
const FLOOR_Y := 420.0

var _vel := Vector2.ZERO
var _on_floor := true
var _facing := 1
var _player: Node2D
var _visual: Node2D
var _anim_player: AnimationPlayer
var _anim_tree: AnimationTree
var _playback: AnimationNodeStateMachinePlayback
var _state_label: Label
var _initialized := false

func _ready() -> void:
	_player = $Player
	_visual = $Player/Visual
	_anim_player = $Player/AnimationPlayer
	_anim_tree = $Player/AnimationTree
	_state_label = $HUD/StateLabel

	_player.position = Vector2(320, FLOOR_Y)

	_build_animations()
	_build_state_machine()

func _build_animations() -> void:
	var lib := AnimationLibrary.new()

	# Idle: gentle squash/stretch breathing cycle
	var idle := Animation.new()
	idle.length = 1.2
	idle.loop_mode = Animation.LOOP_LINEAR
	var it := idle.add_track(Animation.TYPE_VALUE)
	idle.track_set_path(it, "Visual:scale")
	idle.track_set_interpolation_type(it, Animation.INTERPOLATION_LINEAR)
	idle.track_insert_key(it, 0.0, Vector2(1.0, 1.0))
	idle.track_insert_key(it, 0.6, Vector2(1.06, 0.94))
	idle.track_insert_key(it, 1.2, Vector2(1.0, 1.0))
	lib.add_animation("idle", idle)

	# Walk: vertical position bob (two steps per cycle)
	var walk := Animation.new()
	walk.length = 0.36
	walk.loop_mode = Animation.LOOP_LINEAR
	var wt := walk.add_track(Animation.TYPE_VALUE)
	walk.track_set_path(wt, "Visual:position")
	walk.track_insert_key(wt, 0.0,    Vector2(0,  0))
	walk.track_insert_key(wt, 0.09,   Vector2(0, -5))
	walk.track_insert_key(wt, 0.18,   Vector2(0,  0))
	walk.track_insert_key(wt, 0.27,   Vector2(0, -5))
	walk.track_insert_key(wt, 0.36,   Vector2(0,  0))
	lib.add_animation("walk", walk)

	# Jump: launch squash → stretch at peak
	var jump := Animation.new()
	jump.length = 0.28
	jump.loop_mode = Animation.LOOP_NONE
	var jt := jump.add_track(Animation.TYPE_VALUE)
	jump.track_set_path(jt, "Visual:scale")
	jump.track_insert_key(jt, 0.0,  Vector2(1.25, 0.75))
	jump.track_insert_key(jt, 0.14, Vector2(0.85, 1.18))
	jump.track_insert_key(jt, 0.28, Vector2(1.0,  1.0))
	lib.add_animation("jump", jump)

	# Fall: stretched downward
	var fall := Animation.new()
	fall.length = 0.2
	fall.loop_mode = Animation.LOOP_LINEAR
	var ft := fall.add_track(Animation.TYPE_VALUE)
	fall.track_set_path(ft, "Visual:scale")
	fall.track_insert_key(ft, 0.0, Vector2(0.88, 1.12))
	fall.track_insert_key(ft, 0.2, Vector2(0.88, 1.12))
	lib.add_animation("fall", fall)

	# Land: impact squash → settle
	var land := Animation.new()
	land.length = 0.22
	land.loop_mode = Animation.LOOP_NONE
	var lt := land.add_track(Animation.TYPE_VALUE)
	land.track_set_path(lt, "Visual:scale")
	land.track_insert_key(lt, 0.0,  Vector2(1.35, 0.65))
	land.track_insert_key(lt, 0.22, Vector2(1.0,  1.0))
	lib.add_animation("land", land)

	_anim_player.add_animation_library("", lib)

func _build_state_machine() -> void:
	var sm := AnimationNodeStateMachine.new()

	for anim_name in ["idle", "walk", "jump", "fall", "land"]:
		var node := AnimationNodeAnimation.new()
		node.animation = anim_name
		sm.add_node(anim_name, node)

	# Transitions — we control them via travel(), so ADVANCE_MODE_DISABLED
	var pairs := [
		["idle", "walk"], ["walk", "idle"],
		["idle", "jump"], ["walk", "jump"],
		["jump", "fall"], ["fall", "land"],
		["land", "idle"], ["land", "walk"]
	]
	for pair in pairs:
		var t := AnimationNodeStateMachineTransition.new()
		t.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_DISABLED
		t.xfade_time = 0.08
		sm.add_transition(pair[0], pair[1], t)

	# A state machine has no set_start_node(); entry is expressed as a transition
	# from the built-in "Start" node, which is always present under that name.
	var start_transition := AnimationNodeStateMachineTransition.new()
	start_transition.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO
	sm.add_transition("Start", "idle", start_transition)

	_anim_tree.tree_root = sm
	_anim_tree.anim_player = NodePath("../AnimationPlayer")
	_anim_tree.active = true

func _physics_process(delta: float) -> void:
	if not _initialized:
		_playback = _anim_tree["parameters/playback"] as AnimationNodeStateMachinePlayback
		if _playback:
			_playback.travel("idle")
			_initialized = true
		return

	var move_x := Input.get_axis("ui_left", "ui_right")
	_vel.x = move_x * SPEED

	if not _on_floor:
		_vel.y += GRAVITY * delta

	if Input.is_action_just_pressed("ui_accept") and _on_floor:
		_vel.y = JUMP_VEL
		_on_floor = false
		_playback.travel("jump")

	if absf(_vel.x) > 10:
		_facing = sign(_vel.x)

	_player.position += _vel * delta
	_player.position.x = clampf(_player.position.x, 20, 620)

	if _player.position.y >= FLOOR_Y:
		var was_airborne := not _on_floor
		_player.position.y = FLOOR_Y
		_vel.y = 0.0
		_on_floor = true
		if was_airborne:
			_playback.travel("land")

	_update_state()
	queue_redraw()

func _update_state() -> void:
	if not _playback:
		return
	var cur := _playback.get_current_node()

	if _on_floor:
		if cur == "land":
			# Transition out of land once animation finishes
			if _anim_player.current_animation_position >= 0.20:
				if absf(_vel.x) > 10:
					_playback.travel("walk")
				else:
					_playback.travel("idle")
		elif cur == "idle" and absf(_vel.x) > 10:
			_playback.travel("walk")
		elif cur == "walk" and absf(_vel.x) <= 10:
			_playback.travel("idle")
	else:
		if cur in ["jump", "land", "idle", "walk"] and _vel.y > 80:
			_playback.travel("fall")

	var display: String = cur if cur != "" else "—"
	_state_label.text = "State: " + display

func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, FLOOR_Y), Color(0.12, 0.14, 0.22))
	draw_rect(Rect2(0, FLOOR_Y, 640, 480 - FLOOR_Y), Color(0.22, 0.45, 0.18))
	draw_line(Vector2(0, FLOOR_Y), Vector2(640, FLOOR_Y), Color(0.3, 0.6, 0.22), 3)

	# Ground detail lines
	for x in range(0, 640, 60):
		draw_line(Vector2(x, FLOOR_Y + 4), Vector2(x + 20, FLOOR_Y + 4), Color(0.28, 0.55, 0.2), 1)

	if not is_instance_valid(_player):
		return

	var p := _player.position
	var vpos := _visual.position if is_instance_valid(_visual) else Vector2.ZERO
	var vscale := _visual.scale if is_instance_valid(_visual) else Vector2.ONE

	var cx := p.x + vpos.x
	var cy := p.y + vpos.y

	var bw := 18.0 * absf(vscale.x)
	var bh := 24.0 * absf(vscale.y)

	var body_c := Color(0.25, 0.55, 0.92)
	var dark_c := Color(0.18, 0.40, 0.72)
	var skin_c := Color(0.98, 0.82, 0.64)

	# Legs
	draw_rect(Rect2(cx - bw * 0.5, cy - 8.0, bw * 0.45, 14), dark_c)
	draw_rect(Rect2(cx + bw * 0.05, cy - 8.0, bw * 0.45, 14), dark_c)

	# Body
	draw_rect(Rect2(cx - bw * 0.5, cy - bh - 8.0, bw, bh), body_c)

	# Arms
	var arm_y := cy - bh + 4.0
	draw_rect(Rect2(cx - bw * 0.5 - 6, arm_y, 6, bh * 0.55), dark_c)
	draw_rect(Rect2(cx + bw * 0.5, arm_y, 6, bh * 0.55), dark_c)

	# Head
	var head_r := 11.0
	var head_cy := cy - bh - 8.0 - head_r
	draw_circle(Vector2(cx, head_cy), head_r, skin_c)

	# Eye (indicates facing direction)
	draw_circle(Vector2(cx + 4.0 * _facing, head_cy - 2), 2.5, Color.BLACK)
