extends Node2D

const PLAYER_SPEED := 120.0
const ATTACK_RANGE := 30.0
const COIN_RANGE := 15.0
const BEACON_RANGE := 30.0
const ENEMY_RESPAWN_COUNT := 5

# Quest tracking lives in the reusable QuestSystem (scripts/quest_system.gd).
# `_quests` aliases `_quests_sys.quests` (same array) so the drawing code can
# keep reading it directly.
var _quests_sys: QuestSystem
var _quests: Array = []
var _enemies: Array = []
var _coins: Array = []
var _beacon_pos: Vector2 = Vector2(560, 80)
var _player_pos: Vector2 = Vector2(60, 380)
var _all_complete: bool = false
var _beacon_pulse: float = 0.0
var _kill_flash: float = 0.0

func _ready() -> void:
	_setup_quests()
	_setup_enemies()
	_setup_coins()

func _setup_quests() -> void:
	_quests = [
		{
			"id": "kill",
			"title": "Slay the Beasts",
			"description": "Defeat 5 enemies",
			"type": "kill",
			"target_count": 5,
			"current_count": 0,
			"completed": false,
			"reward_xp": 100
		},
		{
			"id": "collect",
			"title": "Gather the Coins",
			"description": "Collect 3 coins",
			"type": "collect",
			"target_count": 3,
			"current_count": 0,
			"completed": false,
			"reward_xp": 75
		},
		{
			"id": "reach",
			"title": "Reach the Beacon",
			"description": "Travel to the beacon",
			"type": "reach",
			"target_count": 1,
			"current_count": 0,
			"completed": false,
			"reward_xp": 50
		}
	]
	_quests_sys = QuestSystem.new(_quests)   # shares the same array

func _setup_enemies() -> void:
	_enemies = [
		{"pos": Vector2(160, 360), "alive": true},
		{"pos": Vector2(260, 340), "alive": true},
		{"pos": Vector2(330, 370), "alive": true},
		{"pos": Vector2(200, 300), "alive": true},
		{"pos": Vector2(290, 290), "alive": true},
	]

func _setup_coins() -> void:
	_coins = [
		{"pos": Vector2(120, 200), "collected": false},
		{"pos": Vector2(350, 150), "collected": false},
		{"pos": Vector2(480, 320), "collected": false},
	]

func _respawn_enemies() -> void:
	_enemies = [
		{"pos": Vector2(160, 360), "alive": true},
		{"pos": Vector2(260, 340), "alive": true},
		{"pos": Vector2(330, 370), "alive": true},
		{"pos": Vector2(200, 300), "alive": true},
		{"pos": Vector2(290, 290), "alive": true},
	]

func _input(event: InputEvent) -> void:
	if _all_complete:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos := get_viewport().get_mouse_position()
		for enemy in _enemies:
			if enemy.alive and mouse_pos.distance_to(enemy.pos) <= ATTACK_RANGE:
				enemy.alive = false
				_kill_flash = 0.2
				break

func _process(delta: float) -> void:
	if _all_complete:
		queue_redraw()
		return

	# Player movement
	var move := Vector2.ZERO
	if Input.is_key_pressed(KEY_W): move.y -= 1
	if Input.is_key_pressed(KEY_S): move.y += 1
	if Input.is_key_pressed(KEY_A): move.x -= 1
	if Input.is_key_pressed(KEY_D): move.x += 1
	if move.length() > 0:
		move = move.normalized()
	_player_pos += move * PLAYER_SPEED * delta
	_player_pos = _player_pos.clamp(Vector2(10, 10), Vector2(410, 470))

	# Coin collection
	for coin in _coins:
		if not coin.collected and _player_pos.distance_to(coin.pos) <= COIN_RANGE:
			coin.collected = true

	# Update quests
	_update_quest_progress()
	_all_complete = _quests_sys.is_all_completed()

	# Respawn enemies if all dead and kill quest not done
	var kill_quest = _quests_sys.get_quest("kill")
	if not kill_quest.completed:
		var all_dead := true
		for e in _enemies:
			if e.alive:
				all_dead = false
				break
		if all_dead:
			_respawn_enemies()

	_beacon_pulse += delta * 2.5
	if _kill_flash > 0:
		_kill_flash -= delta

	queue_redraw()

func _update_quest_progress() -> void:
	# Translate game state into quest progress; QuestSystem handles clamping,
	# completion, and the "all done" signal.
	var dead_count := 0
	for e in _enemies:
		if not e.alive:
			dead_count += 1
	_quests_sys.set_progress("kill", dead_count)

	var collected_count := 0
	for c in _coins:
		if c.collected:
			collected_count += 1
	_quests_sys.set_progress("collect", collected_count)

	if _player_pos.distance_to(_beacon_pos) <= BEACON_RANGE:
		_quests_sys.set_progress("reach", 1)

func _draw() -> void:
	# Background
	draw_rect(Rect2(0, 0, 640, 480), Color(0.07, 0.07, 0.12))

	# Floor
	draw_line(Vector2(0, 420), Vector2(415, 420), Color(0.3, 0.3, 0.4), 2)
	draw_rect(Rect2(0, 420, 415, 60), Color(0.1, 0.09, 0.08))

	# Beacon (pulsing)
	var pulse_r := 16.0 + sin(_beacon_pulse) * 6.0
	var beacon_color := Color(1.0, 0.9, 0.2) if not _quests[2].completed else Color(0.3, 1.0, 0.3)
	draw_circle(_beacon_pos, pulse_r, Color(beacon_color.r, beacon_color.g, beacon_color.b, 0.25))
	draw_circle(_beacon_pos, 12, beacon_color)
	# Star shape (simplified as lines)
	for i in range(8):
		var angle := i * PI / 4.0
		var inner := 6.0 if i % 2 == 0 else 12.0
		var outer := 12.0 if i % 2 == 0 else 20.0
		draw_line(
			_beacon_pos + Vector2(cos(angle) * inner, sin(angle) * inner),
			_beacon_pos + Vector2(cos(angle) * outer, sin(angle) * outer),
			Color(1, 1, 0.5), 2)

	# Coins
	for coin in _coins:
		if not coin.collected:
			draw_circle(coin.pos, 10, Color(1.0, 0.85, 0.1))
			draw_arc(coin.pos, 10, 0, TAU, 12, Color(1, 1, 0.5), 1)

	# Enemies
	for enemy in _enemies:
		if enemy.alive:
			var ecol := Color(0.9, 0.15, 0.15)
			if _kill_flash > 0:
				ecol = Color(1.0, 0.5, 0.5)
			draw_circle(enemy.pos, 14, ecol)
			draw_arc(enemy.pos, 14, 0, TAU, 16, Color(1, 0.5, 0.5), 1)
		else:
			draw_circle(enemy.pos, 14, Color(0.35, 0.35, 0.35, 0.5))

	# Player
	draw_circle(_player_pos, 14, Color(0.2, 0.5, 1.0))
	draw_arc(_player_pos, 14, 0, TAU, 24, Color(0.8, 0.9, 1.0), 1)

	# Quest panel (right side)
	draw_rect(Rect2(418, 20, 215, 380), Color(0.04, 0.04, 0.11, 0.97))
	draw_rect(Rect2(418, 20, 215, 380), Color(0.35, 0.35, 0.55), false, 1)
	draw_string(ThemeDB.fallback_font, Vector2(424, 38), "QUESTS", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 0.9, 0.5))

	var card_y := 48
	for quest in _quests:
		_draw_quest_card(quest, card_y)
		card_y += 120

	# All complete overlay
	if _all_complete:
		draw_rect(Rect2(0, 0, 640, 480), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(120, 160, 400, 120), Color(0.05, 0.15, 0.05, 0.95))
		draw_rect(Rect2(120, 160, 400, 120), Color(0.3, 0.9, 0.3), false, 2)
		draw_string(ThemeDB.fallback_font, Vector2(145, 205), "ALL QUESTS COMPLETE!",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.3, 1.0, 0.3))
		draw_string(ThemeDB.fallback_font, Vector2(175, 235), "Congratulations, Hero!",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.8, 1.0, 0.8))

	# Hints
	if not _all_complete:
		draw_string(ThemeDB.fallback_font, Vector2(6, 472),
			"WASD move   Click enemies to kill   Walk over coins   Reach beacon",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.5, 0.5, 0.7))

func _draw_quest_card(quest: Dictionary, y: int) -> void:
	var card := Rect2(424, y, 204, 112)
	var bg_color := Color(0.07, 0.12, 0.07) if quest.completed else Color(0.07, 0.07, 0.12)
	draw_rect(card, bg_color)
	var border_color := Color(0.3, 0.9, 0.3) if quest.completed else Color(0.3, 0.3, 0.55)
	draw_rect(card, border_color, false, 1)

	# Title
	draw_string(ThemeDB.fallback_font, Vector2(430, y + 16), quest.title,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1.0, 0.85, 0.4))

	# Description
	draw_string(ThemeDB.fallback_font, Vector2(430, y + 32), quest.description,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.7, 0.7, 0.85))

	# Progress text
	var prog_text := "%d / %d" % [quest.current_count, quest.target_count]
	draw_string(ThemeDB.fallback_font, Vector2(430, y + 50), prog_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.8, 0.9, 1.0))

	# Progress bar background
	var bar_rect := Rect2(430, y + 58, 192, 10)
	draw_rect(bar_rect, Color(0.15, 0.15, 0.2))
	# Progress bar fill
	var fill := float(quest.current_count) / float(quest.target_count)
	fill = clamp(fill, 0.0, 1.0)
	var fill_color := Color(0.3, 0.9, 0.3) if quest.completed else Color(0.2, 0.6, 1.0)
	draw_rect(Rect2(430, y + 58, int(192 * fill), 10), fill_color)
	draw_rect(bar_rect, Color(0.4, 0.4, 0.6), false, 1)

	# Checkmark if complete
	if quest.completed:
		draw_string(ThemeDB.fallback_font, Vector2(430, y + 90), "[COMPLETE] +%d XP" % quest.reward_xp,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.4, 1.0, 0.4))
