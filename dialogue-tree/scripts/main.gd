extends Node2D

# size-exempt: most of the bulk is the branching-graph visualisation, which is what makes the traversal legible

const PLAYER_SPEED := 100.0
const INTERACT_RANGE := 100.0

var _game_state: Dictionary = {
	"has_sword": false,
	"gold": 10,
	"talked_before": false
}

# Each node: { speaker, text, choices: [{text, condition, target, effect}] }
# condition: "" means always available; otherwise the game decides in _is_condition_met().
# effect: optional string applied to _game_state when the choice is selected.
# Graph navigation lives in DialogueTree (scripts/dialogue_tree.gd); this file
# owns _game_state, effects, movement, and drawing.
var _tree: DialogueTree

var _active: bool = false
var _npc_pos: Vector2 = Vector2(320, 300)
var _player_pos: Vector2 = Vector2(200, 380)

func _ready() -> void:
	_build_dialogue()

func _build_dialogue() -> void:
	var nodes := {
		"start": {
			"speaker": "Old Merchant",
			"text": "Ah, a traveler! Welcome, welcome. I haven't seen you around here before. What brings you to my humble stall?",
			"choices": [
				{"text": "Tell me about the sword you mentioned.", "condition": "", "target": "sword_intro"},
				{"text": "I'm looking for adventure.", "condition": "", "target": "adventure"},
				{"text": "Goodbye.", "condition": "", "target": "goodbye_cold"},
			]
		},
		"start_again": {
			"speaker": "Old Merchant",
			"text": "Back again, eh? I knew you'd return. So, what can I do for you this time?",
			"choices": [
				{"text": "Tell me about the legendary sword.", "condition": "", "target": "sword_intro"},
				{"text": "I've found the sword!", "condition": "has_sword", "target": "show_sword"},
				{"text": "Can I buy information about the sword?", "condition": "", "target": "buy_info"},
				{"text": "Nothing, goodbye.", "condition": "", "target": "goodbye_warm"},
			]
		},
		"sword_intro": {
			"speaker": "Old Merchant",
			"text": "Ah, the Blade of Embers! A legendary weapon, lost for a century. Rumor has it the blade rests in the old ruins east of here. But getting the location costs gold.",
			"choices": [
				{"text": "I'll pay 5 gold for the information.", "condition": "gold_gte_5", "target": "buy_info"},
				{"text": "I don't have enough gold.", "condition": "", "target": "no_gold"},
				{"text": "I'll find it myself. Goodbye.", "condition": "", "target": "goodbye_cold"},
			]
		},
		"adventure": {
			"speaker": "Old Merchant",
			"text": "Adventure! Ha! This whole region is crawling with it. Bandits, ancient ruins, mysterious beasts. A wise soul would arm themselves first.",
			"choices": [
				{"text": "Arm myself? With what?", "condition": "", "target": "sword_intro"},
				{"text": "I'll keep that in mind. Goodbye.", "condition": "", "target": "goodbye_cold"},
			]
		},
		"buy_info": {
			"speaker": "Old Merchant",
			"text": "Five gold it is. The ruins are half a day east, past the twin oaks. The blade is in the third chamber. Watch out for the guardian — it doesn't like visitors.",
			"choices": [
				{"text": "Thank you! I'll head there now.", "condition": "", "target": "after_buy",
					"effect": "spend_gold"},
				{"text": "On second thought, maybe later.", "condition": "", "target": "goodbye_warm"},
			]
		},
		"after_buy": {
			"speaker": "Old Merchant",
			"text": "Be careful out there. And remember: if you find the blade, come back and show me. I'd love to see it one last time before I die.",
			"choices": [
				{"text": "I will. Farewell.", "condition": "", "target": "end_after_buy",
					"effect": "set_talked"},
			]
		},
		"no_gold": {
			"speaker": "Old Merchant",
			"text": "No gold, no secrets. That's just business, friend. Come back when your pockets are heavier.",
			"choices": [
				{"text": "Understood. Goodbye.", "condition": "", "target": "goodbye_cold"},
			]
		},
		"show_sword": {
			"speaker": "Old Merchant",
			"text": "By the stars... you actually found it! The Blade of Embers, in the flesh. You're either very brave or very lucky. Probably both. Keep it safe, hero.",
			"choices": [
				{"text": "Thank you, old friend. Farewell.", "condition": "", "target": "end_hero"},
			]
		},
		"goodbye_cold": {
			"speaker": "Old Merchant",
			"text": "Safe travels then, stranger. The roads aren't kind to the unprepared.",
			"choices": [
				{"text": "[Close]", "condition": "", "target": "_close", "effect": "set_talked"},
			]
		},
		"goodbye_warm": {
			"speaker": "Old Merchant",
			"text": "Come back anytime, friend. My door is always open.",
			"choices": [
				{"text": "[Close]", "condition": "", "target": "_close"},
			]
		},
		"end_after_buy": {
			"speaker": "Old Merchant",
			"text": "Good luck!",
			"choices": []
		},
		"end_hero": {
			"speaker": "Old Merchant",
			"text": "A true legend walks among us. Farewell, hero.",
			"choices": []
		},
	}
	_tree = DialogueTree.new(nodes, "start")

func _get_available_choices() -> Array:
	return _tree.available_choices(_is_condition_met)

## Game-specific condition check. DialogueTree calls this for any non-empty
## condition string on a choice.
func _is_condition_met(cond: String) -> bool:
	if cond == "gold_gte_5":
		return _game_state.get("gold", 0) >= 5
	return _game_state.get(cond, false)

func _apply_effect(effect_name: String) -> void:
	match effect_name:
		"spend_gold":
			_game_state.gold = max(0, _game_state.gold - 5)
		"set_talked":
			_game_state.talked_before = true
		"give_sword":
			_game_state.has_sword = true

func _open_dialogue() -> void:
	_active = true
	_tree.current = "start_again" if _game_state.get("talked_before", false) else "start"

func _input(event: InputEvent) -> void:
	if not _active:
		if event is InputEventKey and event.pressed and event.keycode == KEY_E:
			if _player_pos.distance_to(_npc_pos) <= INTERACT_RANGE:
				_open_dialogue()
		return

	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				_game_state.talked_before = true
				_active = false
				queue_redraw()
				return
			KEY_SPACE, KEY_ENTER:
				var choices := _get_available_choices()
				if choices.is_empty():
					_game_state.talked_before = true
					_active = false
					queue_redraw()
				return

		var num_key: int = event.keycode - KEY_1
		if num_key >= 0 and num_key <= 3:
			var choices := _get_available_choices()
			if num_key < choices.size():
				var chosen = choices[num_key]
				var effect: String = chosen.get("effect", "")
				if effect != "":
					_apply_effect(effect)
				var target: String = chosen.get("target", "_close")
				if target == "_close":
					_active = false
				else:
					_tree.goto(target)
				queue_redraw()

func _process(delta: float) -> void:
	if not _active:
		var move := Vector2.ZERO
		if Input.is_key_pressed(KEY_W): move.y -= 1
		if Input.is_key_pressed(KEY_S): move.y += 1
		if Input.is_key_pressed(KEY_A): move.x -= 1
		if Input.is_key_pressed(KEY_D): move.x += 1
		if move.length() > 0:
			move = move.normalized()
		_player_pos += move * PLAYER_SPEED * delta
		_player_pos = _player_pos.clamp(Vector2(10, 10), Vector2(630, 470))
	queue_redraw()

func _draw() -> void:
	# Background
	draw_rect(Rect2(0, 0, 640, 480), Color(0.07, 0.07, 0.13))

	# Floor
	draw_line(Vector2(0, 420), Vector2(640, 420), Color(0.3, 0.3, 0.4), 2)
	draw_rect(Rect2(0, 420, 640, 60), Color(0.1, 0.09, 0.08))

	# NPC
	draw_circle(_npc_pos, 18, Color(0.6, 0.4, 0.2))
	draw_arc(_npc_pos, 18, 0, TAU, 24, Color(1, 0.8, 0.5), 2)

	# Speech bubble above NPC
	var near_player := _player_pos.distance_to(_npc_pos) <= INTERACT_RANGE
	var bubble_text := "!" if not _active else "..."
	var bubble_color := Color(1, 1, 0) if not _active else Color(0.5, 1, 0.5)
	draw_circle(_npc_pos + Vector2(0, -35), 12, Color(0.1, 0.1, 0.15))
	draw_arc(_npc_pos + Vector2(0, -35), 12, 0, TAU, 16, bubble_color, 2)
	draw_string(ThemeDB.fallback_font, _npc_pos + Vector2(-4, -30), bubble_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, bubble_color)

	# Player
	draw_circle(_player_pos, 14, Color(0.2, 0.5, 1.0))
	draw_arc(_player_pos, 14, 0, TAU, 24, Color(0.8, 0.9, 1.0), 1)

	# Interact hint
	if not _active and near_player:
		draw_string(ThemeDB.fallback_font, _npc_pos + Vector2(-30, -55), "Press E",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 0.6, 0.9))

	# Dialogue panel
	if _active:
		_draw_dialogue_panel()

	# Game state display (top-left HUD)
	draw_rect(Rect2(4, 4, 160, 50), Color(0.05, 0.05, 0.1, 0.85))
	draw_string(ThemeDB.fallback_font, Vector2(8, 18), "Gold: %d" % _game_state.gold,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 0.9, 0.3))
	draw_string(ThemeDB.fallback_font, Vector2(8, 33), "Has Sword: %s" % str(_game_state.has_sword),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.8, 0.8, 1.0))
	draw_string(ThemeDB.fallback_font, Vector2(8, 48), "Talked Before: %s" % str(_game_state.talked_before),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.7, 0.7, 0.9))

	# Controls hint
	if not _active:
		draw_string(ThemeDB.fallback_font, Vector2(8, 470), "WASD: move   E: talk to NPC   ESC: close dialogue",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.5, 0.5, 0.7))

func _draw_dialogue_panel() -> void:
	var panel := Rect2(20, 230, 600, 240)
	draw_rect(panel, Color(0.04, 0.04, 0.12, 0.97))
	draw_rect(panel, Color(0.5, 0.5, 0.8), false, 2)

	var node_data = _tree.node()
	var speaker: String = node_data.get("speaker", "???")
	var text: String = node_data.get("text", "")
	var choices := _get_available_choices()
	var all_choices: Array = node_data.get("choices", [])

	# Speaker name
	draw_string(ThemeDB.fallback_font, Vector2(28, 252), speaker,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1.0, 0.85, 0.4))

	# Dialogue text (manual wrap at ~72 chars)
	var lines := _wrap_text(text, 72)
	for i in range(lines.size()):
		draw_string(ThemeDB.fallback_font, Vector2(28, 270 + i * 16), lines[i],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.9, 0.9, 0.95))

	var choice_y := 340
	if choices.is_empty() and all_choices.is_empty():
		draw_string(ThemeDB.fallback_font, Vector2(28, choice_y), "[Space/Enter to close]",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.6, 0.6, 0.8))
	else:
		# `choices` is already filtered by DialogueTree — just number them.
		for i in choices.size():
			draw_string(ThemeDB.fallback_font, Vector2(28, choice_y + i * 18),
				"%d. %s" % [i + 1, choices[i].get("text", "")],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.8, 1.0, 0.8))

func _wrap_text(text: String, max_chars: int) -> Array:
	var words := text.split(" ")
	var lines: Array = []
	var current := ""
	for word in words:
		if current.length() + word.length() + 1 > max_chars:
			lines.append(current.strip_edges())
			current = word + " "
		else:
			current += word + " "
	if current.strip_edges() != "":
		lines.append(current.strip_edges())
	return lines
