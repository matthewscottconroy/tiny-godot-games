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
	await test_the_response_clears_itself()
	test_walking_away_takes_the_response_with_it()
	test_the_counter_reads_as_a_suffix()
	await test_the_player_stays_put_untouched()
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

## The response appears, holds, and takes itself away.
##
## Every assertion above is on the frame `interact()` is called, where the label
## has just been made visible — so nothing held the tween that hides it again,
## and a response that stayed on screen forever would pass.
func test_the_response_clears_itself() -> void:
	print("the response clears")
	var scene := _make_scene()
	var chest: Interactable = scene.get_node("Chest")
	await get_tree().process_frame

	expect(not chest._resp_label.visible, "no response is showing to begin with")
	chest.interact()
	expect(chest._resp_label.visible, "using it shows one")
	expect(chest._prompt.modulate != Color.WHITE,
		"and the prompt lights up to acknowledge the press (%s)" % chest._prompt.modulate)

	# Still up a moment later: it has to be readable, not a single-frame flash.
	var elapsed := 0.0
	while elapsed < 0.6:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	expect(chest._resp_label.visible,
		"it is still readable half a second later")

	# And gone by the end of the interval.
	while elapsed < 3.0 and chest._resp_label.visible:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	expect(not chest._resp_label.visible,
		"but hides itself once the interval passes (after %.1fs)" % elapsed)
	expect(chest._prompt.modulate == Color.WHITE,
		"and the prompt goes back to normal (%s)" % chest._prompt.modulate)

## Leaving the area clears the response as well as the prompt.
func test_walking_away_takes_the_response_with_it() -> void:
	print("walking away")
	var scene := _make_scene()
	var chest: Interactable = scene.get_node("Chest")
	var player := scene.get_node("Player")

	chest._on_enter(player)
	chest.interact()
	expect(chest._resp_label.visible, "the response is up while standing there")

	chest._on_exit(player)
	expect(not chest._prompt.visible, "walking away hides the prompt")
	expect(not chest._resp_label.visible,
		"and the response with it — an answer left hanging over an empty chest")

## The repeat counter is added to the response, not substituted for it.
func test_the_counter_reads_as_a_suffix() -> void:
	print("the counter")
	var scene := _make_scene()
	var chest: Interactable = scene.get_node("Chest")

	chest.interact()
	expect(chest._resp_label.text == chest.response,
		"the first use is the response alone (%s)" % chest._resp_label.text)
	chest.interact()
	expect(chest._resp_label.text.begins_with(chest.response),
		"the second still starts with it (%s)" % chest._resp_label.text)
	expect(chest._resp_label.text.length() > chest.response.length(),
		"with the count added on the end rather than replacing it")
	chest.interact()
	expect(chest._resp_label.text.ends_with("(×3)"),
		"and the count keeps up (%s)" % chest._resp_label.text)

## Nothing pressed, nothing happens — the grounded half of the jump.
func test_the_player_stays_put_untouched() -> void:
	print("the player")
	var scene := _make_scene()
	var player: CharacterBody2D = scene.get_node("Player")
	for _i in 60:
		await get_tree().physics_frame
	expect(player.is_on_floor(), "the player settles on the ground")
	var resting: float = player.global_position.y
	var highest := resting
	for _i in 40:
		await get_tree().physics_frame
		highest = minf(highest, player.global_position.y)
	expect(resting - highest < 4.0,
		"and stays there with no key pressed (rose %.1f px)" % (resting - highest))

func _report() -> void:
	var summary := "[interaction-system] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
