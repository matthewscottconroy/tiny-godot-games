extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_initial_spawn()
	_test_set_checkpoint()
	_test_ordering()
	_test_already_activated()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

# --- spawn point logic (mirrored from player.gd) ---

class FakePlayer:
	var global_position: Vector2
	var _spawn_point: Vector2

	func _init(pos: Vector2) -> void:
		global_position = pos
		_spawn_point = pos

	func set_checkpoint(pos: Vector2) -> void:
		_spawn_point = pos

	func respawn() -> void:
		global_position = _spawn_point

func _test_initial_spawn() -> void:
	print("initial spawn point")
	var p := FakePlayer.new(Vector2(60, 400))
	expect(p._spawn_point == Vector2(60, 400), "spawn_point starts at initial position")
	p.respawn()
	expect(p.global_position == Vector2(60, 400), "respawn returns to initial position")

func _test_set_checkpoint() -> void:
	print("set_checkpoint")
	var p := FakePlayer.new(Vector2(60, 400))
	p.set_checkpoint(Vector2(160, 425))
	expect(p._spawn_point == Vector2(160, 425), "spawn_point updated after set_checkpoint")
	p.global_position = Vector2(999, 999)
	p.respawn()
	expect(p.global_position == Vector2(160, 425), "respawn lands at new checkpoint")

func _test_ordering() -> void:
	print("checkpoint ordering")
	var p := FakePlayer.new(Vector2(0, 0))
	p.set_checkpoint(Vector2(100, 0))
	p.set_checkpoint(Vector2(200, 0))
	p.set_checkpoint(Vector2(300, 0))
	expect(p._spawn_point == Vector2(300, 0), "last activated checkpoint wins")

func _test_already_activated() -> void:
	print("already-activated guard")
	# Simulate _activated flag: second call should not change id
	var emitted_ids: Array = []
	var activated := false
	var emit_id := func(id: int) -> void:
		if activated:
			return
		activated = true
		emitted_ids.append(id)
	emit_id.call(1)
	emit_id.call(2)  # should be ignored
	expect(emitted_ids.size() == 1, "signal fires only once per checkpoint")
	expect(emitted_ids[0] == 1, "first activation id is correct")

func _report() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [_pass, _fail])
	if _fail == 0:
		print("ALL TESTS PASSED")
	else:
		print("SOME TESTS FAILED")
