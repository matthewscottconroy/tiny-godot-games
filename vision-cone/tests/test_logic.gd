extends Node

# ── Mirrored constants ──────────────────────────────────────────────────────
const CONE_ANGLE := PI / 3.0
const CONE_RANGE := 180.0

# ── Helpers ─────────────────────────────────────────────────────────────────
var _pass := 0
var _fail := 0

func expect(condition: bool, label: String) -> void:
	if condition:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	print("")
	print("Results: %d passed, %d failed" % [_pass, _fail])

# ── Mirrored detection logic ─────────────────────────────────────────────────

func _in_cone(enemy_pos: Vector2, enemy_dir: float, player_pos: Vector2) -> bool:
	if enemy_pos.distance_to(player_pos) > CONE_RANGE:
		return false
	var angle_to_player := (player_pos - enemy_pos).angle()
	var diff := angle_difference(angle_to_player, enemy_dir)
	if absf(diff) > CONE_ANGLE:
		return false
	return true


func _segment_intersects_rect(p1: Vector2, p2: Vector2, r: Rect2) -> bool:
	var d := p2 - p1
	var t_min := 0.0
	var t_max := 1.0

	var tests := [
		[d.x, r.position.x - p1.x, r.position.x + r.size.x - p1.x],
		[d.y, r.position.y - p1.y, r.position.y + r.size.y - p1.y],
	]

	for t in tests:
		var dv: float = t[0]
		var lo: float = t[1]
		var hi: float = t[2]
		if absf(dv) < 1e-6:
			if lo > 0.0 or hi < 0.0:
				return false
		else:
			var t1 := lo / dv
			var t2 := hi / dv
			if t1 > t2:
				var tmp := t1; t1 = t2; t2 = tmp
			t_min = maxf(t_min, t1)
			t_max = minf(t_max, t2)
			if t_min > t_max:
				return false

	return true


func _wall_blocks(a: Vector2, b: Vector2, walls: Array) -> bool:
	for w in walls:
		if _segment_intersects_rect(a, b, w):
			return true
	return false


# ── Tests ────────────────────────────────────────────────────────────────────

func _test_angle_in_cone() -> void:
	# Player directly in front of enemy (angle_diff = 0) → should be in cone
	var enemy_pos := Vector2(100, 100)
	var enemy_dir := 0.0  # facing right
	var player_pos := Vector2(200, 100)  # directly to the right, well within range
	expect(_in_cone(enemy_pos, enemy_dir, player_pos), "angle_in_cone: player directly ahead → detected")


func _test_angle_outside_cone() -> void:
	# Player directly behind enemy (angle_diff = PI) → outside cone
	var enemy_pos := Vector2(100, 100)
	var enemy_dir := 0.0  # facing right
	var player_pos := Vector2(50, 100)  # to the left (behind)
	expect(not _in_cone(enemy_pos, enemy_dir, player_pos), "angle_outside_cone: player behind → not detected")


func _test_range_too_far() -> void:
	# Player within cone angle but beyond CONE_RANGE
	var enemy_pos := Vector2(100, 100)
	var enemy_dir := 0.0
	var player_pos := Vector2(100 + CONE_RANGE + 10, 100)
	expect(not _in_cone(enemy_pos, enemy_dir, player_pos), "range_too_far: beyond CONE_RANGE → not detected")


func _test_range_within() -> void:
	# Player within range and directly in front → detected (no walls)
	var enemy_pos := Vector2(100, 100)
	var enemy_dir := 0.0
	var player_pos := Vector2(100 + CONE_RANGE - 10, 100)
	expect(_in_cone(enemy_pos, enemy_dir, player_pos), "range_within: close and frontal → detected")


func _test_wall_blocks() -> void:
	# Wall fully covers the enemy→player path
	var enemy_pos := Vector2(100, 100)
	var player_pos := Vector2(300, 100)
	# Wall stretches from x=150 to x=260, covering y=80..120 — blocks the horizontal segment
	var walls: Array = [Rect2(150, 80, 110, 40)]
	expect(_wall_blocks(enemy_pos, player_pos, walls), "wall_blocks: wall on path → line of sight blocked")


func _test_wall_does_not_block() -> void:
	# Wall placed below the enemy→player line — should not block
	var enemy_pos := Vector2(100, 100)
	var player_pos := Vector2(300, 100)
	var walls: Array = [Rect2(150, 200, 110, 40)]
	expect(not _wall_blocks(enemy_pos, player_pos, walls), "wall_does_not_block: wall off path → not blocked")


# ── Entry point ──────────────────────────────────────────────────────────────

func _ready() -> void:
	print("=== Vision Cone Tests ===")
	_test_angle_in_cone()
	_test_angle_outside_cone()
	_test_range_too_far()
	_test_range_within()
	_test_wall_blocks()
	_test_wall_does_not_block()
	_report()
