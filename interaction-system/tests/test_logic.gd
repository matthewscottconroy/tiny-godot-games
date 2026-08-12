extends Node

# Drives the real Interactable nodes from scripts/interactable.gd via the demo
# scene, plus the real player from scripts/player.gd.

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_prompt_text_format()
	test_nearby_set_on_enter()
	test_nearby_cleared_on_exit()
	test_interact_increments_count()
	test_interact_shows_the_response()
	test_non_player_body_is_ignored()
	test_each_interactable_has_its_own_text()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _make_scene() -> Node:
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	add_child(scene)
	return scene

func test_prompt_text_format() -> void:
	print("prompt text format")
	var scene := _make_scene()
	var chest: Interactable = scene.get_node("Chest")
	expect(chest._prompt.text == "[E] " + chest.label_text, "prompt reads '[E] <label_text>'")
	expect(not chest._prompt.visible, "the prompt starts hidden")

func test_nearby_set_on_enter() -> void:
	print("entering the area registers the interactable")
	var scene := _make_scene()
	var chest: Interactable = scene.get_node("Chest")
	var player := scene.get_node("Player")
	chest._on_enter(player)
	expect(player._nearby == chest, "the player knows which interactable it is near")
	expect(chest._prompt.visible, "the prompt becomes visible")

func test_nearby_cleared_on_exit() -> void:
	print("leaving the area clears it")
	var scene := _make_scene()
	var chest: Interactable = scene.get_node("Chest")
	var player := scene.get_node("Player")
	chest._on_enter(player)
	chest._on_exit(player)
	expect(player._nearby == null, "the player is no longer near anything")
	expect(not chest._prompt.visible, "the prompt hides again")

func test_interact_increments_count() -> void:
	print("interact counts uses")
	var scene := _make_scene()
	var chest: Interactable = scene.get_node("Chest")
	chest.interact()
	expect(chest._times_used == 1, "first use counted")
	chest.interact()
	expect(chest._times_used == 2, "interact count increments each call")

func test_interact_shows_the_response() -> void:
	print("interact shows the response text")
	var scene := _make_scene()
	var chest: Interactable = scene.get_node("Chest")
	chest.interact()
	expect(chest._resp_label.visible, "the response label becomes visible")
	expect(chest._resp_label.text == chest.response, "the first use shows the plain response")
	chest.interact()
	expect(chest._resp_label.text.ends_with("(×2)"), "repeat uses append a counter")

func test_non_player_body_is_ignored() -> void:
	print("non-player bodies are ignored")
	var scene := _make_scene()
	var chest: Interactable = scene.get_node("Chest")
	var debris := Node2D.new()
	add_child(debris)
	chest._on_enter(debris)
	expect(not chest._prompt.visible, "a body outside the player group shows no prompt")

func test_each_interactable_has_its_own_text() -> void:
	print("each interactable is configured separately")
	var scene := _make_scene()
	var labels: Array[String] = []
	for name in ["Chest", "Sign", "Door"]:
		var node: Interactable = scene.get_node(name)
		labels.append(node.label_text)
		expect(node.response != "", "%s has a response configured" % name)
	var unique := {}
	for l in labels:
		unique[l] = true
	expect(unique.size() == 3, "the three interactables have distinct prompts")

func _report() -> void:
	var summary := "[interaction-system] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
