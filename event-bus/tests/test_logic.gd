extends Node

# Drives the real bus and listeners from scenes/main.tscn — see docs/TEST_INTEGRITY.md.
#
# The point of an event bus is that emitters and listeners never reference each
# other, so the suite emits on the autoload and reads the listener's output.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_bus_carries_the_four_events()
	_test_the_log_starts_empty()
	_test_an_event_reaches_the_listener()
	_test_each_event_is_reported_differently()
	_test_the_payload_is_carried_through()
	_test_the_newest_line_is_at_the_top()
	_test_the_log_is_trimmed()
	_test_a_coin_reports_itself_through_the_bus()
	_test_the_player_emits_without_knowing_the_listener()
	_test_a_key_release_emits_nothing()
	await _test_the_coins_are_watching_for_the_player()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[event-bus] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

var _scene: Node2D

# One scene at a time: the listener is connected to a global bus, so a stale
# copy would keep logging alongside the live one.
func _make() -> Node2D:
	if is_instance_valid(_scene):
		remove_child(_scene)
		_scene.free()
	_scene = load("res://scenes/main.tscn").instantiate()
	add_child(_scene)
	return _scene

func _log_text(m: Node2D) -> String:
	return (m.get_node("LogLabel") as Label).text

func _test_the_bus_carries_the_four_events() -> void:
	print("the bus")
	_make()
	for signal_name in ["item_collected", "player_hurt", "player_healed", "enemy_died"]:
		expect(EventBus.has_signal(signal_name), "the bus declares %s" % signal_name)

func _test_the_log_starts_empty() -> void:
	print("before anything happens")
	var m := _make()
	expect(m.log_lines.is_empty(), "nothing has happened yet")

func _test_an_event_reaches_the_listener() -> void:
	print("carrying an event")
	var m := _make()
	EventBus.item_collected.emit("Gold Coin")
	expect(m.log_lines.size() == 1, "the listener hears an event it never subscribed to directly")
	expect(_log_text(m).contains("Gold Coin"), "and puts it on screen")

func _test_each_event_is_reported_differently() -> void:
	print("four events")
	var m := _make()
	EventBus.item_collected.emit("Sword")
	EventBus.player_hurt.emit(10)
	EventBus.player_healed.emit(5)
	EventBus.enemy_died.emit("Slime")
	expect(m.log_lines.size() == 4, "all four are logged")
	var text := _log_text(m)
	expect(text.contains("item_collected") and text.contains("player_hurt"), "each named by its event")
	expect(text.contains("player_healed") and text.contains("enemy_died"), "including the other two")

func _test_the_payload_is_carried_through() -> void:
	print("payloads")
	var m := _make()
	EventBus.player_hurt.emit(37)
	expect(_log_text(m).contains("37"), "the damage figure travels with the event")
	EventBus.enemy_died.emit("Goblin King")
	expect(_log_text(m).contains("Goblin King"), "and so does a name")

func _test_the_newest_line_is_at_the_top() -> void:
	print("order")
	var m := _make()
	EventBus.enemy_died.emit("First")
	EventBus.enemy_died.emit("Second")
	expect(m.log_lines[0].contains("Second"), "the most recent event is at the top of the log")
	expect(m.log_lines[1].contains("First"), "with the older one beneath it")

func _test_the_log_is_trimmed() -> void:
	print("trimming")
	var m := _make()
	for i in 20:
		EventBus.enemy_died.emit("Slime %d" % i)
	expect(m.log_lines.size() <= 9, "the log stops growing at nine lines")
	expect(m.log_lines[0].contains("Slime 19"), "keeping the newest")
	expect(not _log_text(m).contains("Slime 0 "), "and dropping the oldest")

func _test_a_coin_reports_itself_through_the_bus() -> void:
	print("the coins")
	var m := _make()
	var coins: Node2D = m.get_node("Coins")
	expect(coins.get_child_count() == m.COIN_POSITIONS.size(), "a coin per listed position")

	var coin: Area2D = coins.get_child(0)
	coin.body_entered.emit(m.get_node("Player"))
	expect(_log_text(m).contains("Coin"), "walking into a coin is announced on the bus")
	expect(coin.is_queued_for_deletion(), "and the coin takes itself away")

func _test_the_player_emits_without_knowing_the_listener() -> void:
	print("the player")
	var m := _make()
	var player: CharacterBody2D = m.get_node("Player")
	var key := InputEventKey.new()
	key.keycode = KEY_SHIFT
	key.pressed = true
	player._unhandled_input(key)
	expect(_log_text(m).contains("player_healed"), "the player's heal reaches the log through the bus")

	var hurt := InputEventAction.new()
	hurt.action = "ui_accept"
	hurt.pressed = true
	player._unhandled_input(hurt)
	expect(_log_text(m).contains("player_hurt"), "and so does the damage key")
	expect(player.get_script().source_code.find("LogLabel") == -1,
		"and the player's own code never mentions the label it ends up writing to")

func _test_a_key_release_emits_nothing() -> void:
	print("key releases")
	var m := _make()
	var player: CharacterBody2D = m.get_node("Player")
	var release := InputEventKey.new()
	release.keycode = KEY_SHIFT
	release.pressed = false
	player._unhandled_input(release)
	expect(m.log_lines.is_empty(), "letting go of the heal key heals nobody")

func _test_the_coins_are_watching_for_the_player() -> void:
	print("coin monitoring")
	var m := _make()
	# monitoring is set deferred, so it lands at the end of the frame. Without
	# it a coin never notices the player and the demo has nothing to announce.
	await get_tree().process_frame
	var watching := true
	for coin in m.get_node("Coins").get_children():
		if not (coin as Area2D).monitoring:
			watching = false
	expect(watching, "every coin is watching for the player by the next frame")
