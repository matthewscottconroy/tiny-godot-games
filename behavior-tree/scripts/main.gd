extends Node2D

const PATROL_MIN := 80.0
const PATROL_MAX := 200.0
const CHASE_SPEED := 80.0
const PATROL_SPEED := 40.0
const INVESTIGATE_SPEED := 60.0
const PLAYER_SPEED := 120.0
const ATTACK_RANGE := 25.0
const SIGHT_RANGE := 160.0

var _player_pos: Vector2 = Vector2(500, 350)
var _enemy: Dictionary = {
	"pos": Vector2(140, 380),
	"vel": Vector2.ZERO,
	"state": "patrol",
	"alert_pos": null,
	"patrol_target": PATROL_MAX
}

var _bt_root: BTNode
var _last_statuses: Dictionary = {}
var _attack_flash: float = 0.0
var _noise_pulse: float = 0.0

# Node layout for visualization
var _node_layout: Array = []

func _ready() -> void:
	_build_tree()

func _build_tree() -> void:
	# Leaf nodes
	var can_see = BTNode.Leaf.new("CanSeePlayer", _can_see_player)
	var chase = BTNode.Leaf.new("ChasePlayer", _chase_player)
	var attack = BTNode.Leaf.new("AttackPlayer", _attack_player)
	var heard_noise = BTNode.Leaf.new("HeardNoise", _heard_noise)
	var investigate = BTNode.Leaf.new("InvestigateNoise", _investigate_noise)
	var patrol = BTNode.Leaf.new("Patrol", _patrol)

	# Chase sequence
	var chase_seq = BTNode.Sequence.new()
	chase_seq.children.assign([can_see, chase, attack])

	# Investigate sequence
	var investigate_seq = BTNode.Sequence.new()
	investigate_seq.children.assign([heard_noise, investigate])

	# Root selector
	var root = BTNode.Selector.new()
	root.children.assign([chase_seq, investigate_seq, patrol])

	_bt_root = root

	# Build layout info for visualization (x=420..630 panel)
	_node_layout = [
		{"node": root,          "label": "Selector",        "x": 525, "y": 60,  "parent_idx": -1},
		{"node": chase_seq,     "label": "Sequence(Chase)",  "x": 455, "y": 120, "parent_idx": 0},
		{"node": can_see,       "label": "CanSeePlayer",     "x": 430, "y": 180, "parent_idx": 1},
		{"node": chase,         "label": "ChasePlayer",      "x": 455, "y": 235, "parent_idx": 1},
		{"node": attack,        "label": "AttackPlayer",     "x": 430, "y": 290, "parent_idx": 1},
		{"node": investigate_seq,"label":"Sequence(Inv)",    "x": 525, "y": 120, "parent_idx": 0},
		{"node": heard_noise,   "label": "HeardNoise",       "x": 510, "y": 180, "parent_idx": 5},
		{"node": investigate,   "label": "InvestigateNoise", "x": 510, "y": 235, "parent_idx": 5},
		{"node": patrol,        "label": "Patrol",           "x": 600, "y": 120, "parent_idx": 0},
	]

# --- BT Leaf Callables ---

func _can_see_player(ctx: Dictionary) -> BTNode.Status:
	var dist: float = _enemy.pos.distance_to(_player_pos)
	var result := BTNode.Status.SUCCESS if dist < SIGHT_RANGE else BTNode.Status.FAILURE
	_last_statuses["CanSeePlayer"] = result
	return result

func _chase_player(ctx: Dictionary) -> BTNode.Status:
	var dist: float = _enemy.pos.distance_to(_player_pos)
	if dist <= ATTACK_RANGE:
		_last_statuses["ChasePlayer"] = BTNode.Status.SUCCESS
		return BTNode.Status.SUCCESS
	var dir: Vector2 = (_player_pos - _enemy.pos).normalized()
	_enemy.vel = dir * CHASE_SPEED
	_enemy.state = "chase"
	_last_statuses["ChasePlayer"] = BTNode.Status.RUNNING
	return BTNode.Status.RUNNING

func _attack_player(ctx: Dictionary) -> BTNode.Status:
	var dist: float = _enemy.pos.distance_to(_player_pos)
	if dist <= ATTACK_RANGE:
		_enemy.state = "attack"
		_attack_flash = 0.25
		_last_statuses["AttackPlayer"] = BTNode.Status.SUCCESS
		return BTNode.Status.SUCCESS
	_last_statuses["AttackPlayer"] = BTNode.Status.FAILURE
	return BTNode.Status.FAILURE

func _heard_noise(ctx: Dictionary) -> BTNode.Status:
	var result := BTNode.Status.SUCCESS if _enemy.alert_pos != null else BTNode.Status.FAILURE
	_last_statuses["HeardNoise"] = result
	return result

func _investigate_noise(ctx: Dictionary) -> BTNode.Status:
	if _enemy.alert_pos == null:
		_last_statuses["InvestigateNoise"] = BTNode.Status.FAILURE
		return BTNode.Status.FAILURE
	var dist: float = _enemy.pos.distance_to(_enemy.alert_pos)
	if dist <= 15.0:
		_enemy.alert_pos = null
		_enemy.state = "patrol"
		_last_statuses["InvestigateNoise"] = BTNode.Status.SUCCESS
		return BTNode.Status.SUCCESS
	var dir: Vector2 = (_enemy.alert_pos - _enemy.pos).normalized()
	_enemy.vel = dir * INVESTIGATE_SPEED
	_enemy.state = "investigate"
	_last_statuses["InvestigateNoise"] = BTNode.Status.RUNNING
	return BTNode.Status.RUNNING

func _patrol(ctx: Dictionary) -> BTNode.Status:
	var target_x: float = _enemy.patrol_target
	var dist: float = abs(_enemy.pos.x - target_x)
	if dist <= 5.0:
		_enemy.patrol_target = PATROL_MIN if target_x == PATROL_MAX else PATROL_MAX
	var dir: float = sign(target_x - _enemy.pos.x)
	_enemy.vel = Vector2(dir * PATROL_SPEED, 0)
	_enemy.state = "patrol"
	_last_statuses["Patrol"] = BTNode.Status.RUNNING
	return BTNode.Status.RUNNING

# --- Input / Process ---

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_N:
		_enemy.alert_pos = get_viewport().get_mouse_position()
		_noise_pulse = 0.0

func _process(delta: float) -> void:
	# Player movement
	var move := Vector2.ZERO
	if Input.is_key_pressed(KEY_W): move.y -= 1
	if Input.is_key_pressed(KEY_S): move.y += 1
	if Input.is_key_pressed(KEY_A): move.x -= 1
	if Input.is_key_pressed(KEY_D): move.x += 1
	if move.length() > 0:
		move = move.normalized()
	_player_pos += move * PLAYER_SPEED * delta
	_player_pos = _player_pos.clamp(Vector2(10, 10), Vector2(630, 470))

	# Reset vel each frame so tree decides movement
	_enemy.vel = Vector2.ZERO

	# Tick the behavior tree
	_last_statuses = {}
	_update_composite_labels()
	_bt_root.tick({})

	# Apply velocity
	_enemy.pos += _enemy.vel * delta
	_enemy.pos.x = clamp(_enemy.pos.x, 10, 400)
	_enemy.pos.y = clamp(_enemy.pos.y, 10, 470)

	# Timers
	if _attack_flash > 0:
		_attack_flash -= delta
	_noise_pulse += delta * 3.0

	queue_redraw()

func _update_composite_labels() -> void:
	# Pre-clear composite statuses (leaves set their own)
	for entry in _node_layout:
		if not _last_statuses.has(entry.label):
			_last_statuses[entry.label] = -1  # unticked

# --- Draw ---

func _draw() -> void:
	# Background
	draw_rect(Rect2(0, 0, 640, 480), Color(0.08, 0.08, 0.15))

	# Floor line
	draw_line(Vector2(0, 420), Vector2(410, 420), Color(0.3, 0.3, 0.4), 2)

	# Obstacles
	draw_rect(Rect2(100, 370, 40, 50), Color(0.25, 0.2, 0.15))
	draw_rect(Rect2(300, 350, 50, 70), Color(0.25, 0.2, 0.15))

	# Sight range indicator (faint)
	draw_arc(_enemy.pos, SIGHT_RANGE, 0, TAU, 48, Color(1, 0.5, 0, 0.08), 1)

	# Noise marker
	if _enemy.alert_pos != null:
		var pulse_r := 10.0 + sin(_noise_pulse) * 5.0
		draw_arc(_enemy.alert_pos, pulse_r, 0, TAU, 24, Color(1, 1, 0, 0.8), 2)
		draw_circle(_enemy.alert_pos, 4, Color(1, 1, 0, 0.9))

	# Enemy
	var enemy_color := Color(1.0, 0.4, 0.0)
	if _enemy.state == "attack" and _attack_flash > 0:
		enemy_color = Color(1, 0.1, 0.1)
	elif _enemy.state == "investigate":
		enemy_color = Color(1, 1, 0)
	draw_circle(_enemy.pos, 16, enemy_color)
	draw_arc(_enemy.pos, 16, 0, TAU, 24, Color(1, 1, 1, 0.5), 1)

	# Player
	draw_circle(_player_pos, 14, Color(0.2, 0.5, 1.0))
	draw_arc(_player_pos, 14, 0, TAU, 24, Color(1, 1, 1, 0.6), 1)

	# BT Visualization panel
	draw_rect(Rect2(418, 40, 215, 360), Color(0.05, 0.05, 0.12, 0.95))
	draw_rect(Rect2(418, 40, 215, 360), Color(0.3, 0.3, 0.5), false, 1)

	# Draw connection lines
	for i in range(_node_layout.size()):
		var entry = _node_layout[i]
		if entry.parent_idx >= 0:
			var parent = _node_layout[entry.parent_idx]
			draw_line(Vector2(parent.x, parent.y + 10), Vector2(entry.x, entry.y - 10),
				Color(0.4, 0.4, 0.6), 1)

	# Draw nodes
	for entry in _node_layout:
		var status = _last_statuses.get(entry.label, -1)
		var node_color: Color
		match status:
			BTNode.Status.SUCCESS:
				node_color = Color(0.1, 0.8, 0.2)
			BTNode.Status.FAILURE:
				node_color = Color(0.8, 0.1, 0.1)
			BTNode.Status.RUNNING:
				node_color = Color(0.9, 0.8, 0.0)
			_:
				node_color = Color(0.25, 0.25, 0.35)

		var box := Rect2(entry.x - 42, entry.y - 10, 84, 20)
		draw_rect(box, node_color)
		draw_rect(box, Color(0.8, 0.8, 0.9), false, 1)

	# Panel title
	draw_string(ThemeDB.fallback_font, Vector2(424, 32), "Behavior Tree", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.8, 0.8, 1.0))

	# Hints
	draw_string(ThemeDB.fallback_font, Vector2(8, 466), "WASD: move player   N: make noise at mouse", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.6, 0.6, 0.8))

	# Enemy state label
	draw_string(ThemeDB.fallback_font, Vector2(_enemy.pos.x - 20, _enemy.pos.y - 22), _enemy.state, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, 0.8))
