extends Node2D

const ITEM_COLORS := {
	"Nothing":    Color(0.5, 0.5, 0.5),
	"Coin":       Color(1.0, 0.85, 0.1),
	"Health Orb": Color(0.2, 0.85, 0.3),
	"Arrow":      Color(0.5, 0.7, 1.0),
	"Bomb":       Color(0.9, 0.3, 0.3),
	"Rare Gem":   Color(0.6, 0.1, 0.9),
}

var _tables: Array[DropTable] = []
var _counts: Array[Dictionary] = []
var _rolls:  Array[int]        = []

@onready var _stats_label: Label = $StatsLabel

func _ready() -> void:
	var goblin := DropTable.new()
	goblin.add("Nothing",    40).add("Coin",       35).add("Arrow",  15).add("Health Orb", 10)
	var orc := DropTable.new()
	orc.add("Nothing",    25).add("Coin",       30).add("Bomb",   20).add("Health Orb", 15).add("Rare Gem", 10)
	var boss := DropTable.new()
	boss.add("Coin",       30).add("Health Orb", 25).add("Bomb",  20).add("Rare Gem",   25)

	_tables = [goblin, orc, boss]
	for i in 3:
		_counts.append({})
		_rolls.append(0)

func _draw() -> void:
	var names := ["Goblin", "Orc", "Boss"]
	var x_pos := [110.0, 320.0, 530.0]

	for i in 3:
		var x: float = x_pos[i]
		var table := _tables[i]

		# Enemy body
		var col: Color = [Color.SEA_GREEN, Color.TOMATO, Color.FIREBRICK][i]
		draw_circle(Vector2(x, 220), 34, col)
		draw_arc(Vector2(x, 220), 34, 0, TAU, 32, col.lightened(0.4), 2.0)

		# Enemy eyes
		draw_circle(Vector2(x - 10, 210), 7, Color.WHITE)
		draw_circle(Vector2(x + 10, 210), 7, Color.WHITE)
		draw_circle(Vector2(x - 10, 210), 4, Color.BLACK)
		draw_circle(Vector2(x + 10, 210), 4, Color.BLACK)

		# Name label drawn above (Label nodes handle text)
		# Chance bars below
		var chances := table.get_chances()
		var bar_y := 280.0
		for item in chances:
			var pct: float = chances[item]
			var ic: Color = ITEM_COLORS.get(item, Color.WHITE)
			draw_rect(Rect2(x - 50, bar_y, 100, 8), Color(0.2, 0.2, 0.2))
			draw_rect(Rect2(x - 50, bar_y, 100.0 * pct, 8), ic)
			bar_y += 12.0

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_left"):
		_kill(0)
	if Input.is_action_just_pressed("ui_up"):
		_kill(1)
	if Input.is_action_just_pressed("ui_right"):
		_kill(2)

func _kill(idx: int) -> void:
	var drop := _tables[idx].roll()
	_rolls[idx] += 1
	_counts[idx][drop] = _counts[idx].get(drop, 0) + 1
	_spawn_drop(idx, drop)
	_update_stats()
	queue_redraw()

func _spawn_drop(enemy_idx: int, item: String) -> void:
	if item == "Nothing":
		return
	var x_pos := [110.0, 320.0, 530.0]
	var x: float = x_pos[enemy_idx]
	var col: Color = ITEM_COLORS.get(item, Color.WHITE)

	# Spawn a visual circle that floats up and fades
	var dot := ColorRect.new()
	dot.size = Vector2(16, 16)
	dot.color = col
	dot.position = Vector2(x - 8, 200)
	dot.z_index  = 5
	add_child(dot)

	var tw := dot.create_tween()
	tw.set_parallel(true)
	tw.tween_property(dot, "position:y", 100.0, 0.7).set_ease(Tween.EASE_OUT)
	tw.tween_property(dot, "modulate:a", 0.0, 0.7).set_delay(0.2)
	tw.chain().tween_callback(dot.queue_free)

func _update_stats() -> void:
	var names := ["Goblin", "Orc", "Boss"]
	var lines: Array[String] = []
	for i in 3:
		if _rolls[i] == 0:
			continue
		lines.append("%s (%d kills):" % [names[i], _rolls[i]])
		for item in _counts[i]:
			var pct: float = 100.0 * _counts[i][item] / _rolls[i]
			lines.append("  %-12s %d  (%.0f%%)" % [item, _counts[i][item], pct])
	_stats_label.text = "\n".join(lines)
