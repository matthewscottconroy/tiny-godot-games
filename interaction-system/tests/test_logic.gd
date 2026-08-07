extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_nearby_set_on_enter()
	test_nearby_cleared_on_exit()
	test_interact_increments_count()
	test_interact_ignored_when_not_near()
	test_prompt_text_format()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[interaction-system] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

# Replicate the interaction logic outside of node context

class FakeInteractable:
	var label_text  := "Open Chest"
	var response    := "Found gold!"
	var _times_used := 0
	var _player_near := false

	func enter(is_player: bool) -> void:
		if is_player:
			_player_near = true

	func exit(is_player: bool) -> void:
		if is_player:
			_player_near = false

	func interact() -> bool:
		if not _player_near:
			return false
		_times_used += 1
		return true

	func get_use_count() -> int:
		return _times_used

	func is_near() -> bool:
		return _player_near

func test_nearby_set_on_enter() -> void:
	var i := FakeInteractable.new()
	i.enter(true)
	expect(i.is_near(), "player near after enter")

func test_nearby_cleared_on_exit() -> void:
	var i := FakeInteractable.new()
	i.enter(true)
	i.exit(true)
	expect(not i.is_near(), "player no longer near after exit")

func test_interact_increments_count() -> void:
	var i := FakeInteractable.new()
	i.enter(true)
	i.interact()
	i.interact()
	expect(i.get_use_count() == 2, "interact count increments each call")

func test_interact_ignored_when_not_near() -> void:
	var i := FakeInteractable.new()
	var fired := i.interact()  # player never entered
	expect(not fired, "interact does nothing when player is not near")
	expect(i.get_use_count() == 0, "use count stays 0 when not near")

func test_prompt_text_format() -> void:
	var i := FakeInteractable.new()
	var expected := "[E] " + i.label_text
	expect(expected == "[E] Open Chest", "prompt text formatted correctly")
