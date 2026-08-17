extends Node2D

# size-exempt: the rollout plan keeps this as one file deliberately: the lesson is a hierarchical FSM read top to bottom

var _hfsm: HFSMState  # root

var _alive: HFSMState
var _idle: HFSMState
var _walk: HFSMState
var _run: HFSMState
var _combat: HFSMState
var _attack: HFSMState
var _block: HFSMState
var _dodge: HFSMState
var _dead: HFSMState

var _log: Array[String] = []
var _health: int = 100

func _log_push(msg: String) -> void:
	_log.append(msg)
	if _log.size() > 8:
		_log.pop_front()

func _ready() -> void:
	# Build HFSM tree
	_hfsm = HFSMState.new("Root")

	_alive  = HFSMState.new("Alive")
	_idle   = HFSMState.new("Idle")
	_walk   = HFSMState.new("Walk")
	_run    = HFSMState.new("Run")
	_combat = HFSMState.new("Combat")
	_attack = HFSMState.new("Attack")
	_block  = HFSMState.new("Block")
	_dodge  = HFSMState.new("Dodge")
	_dead   = HFSMState.new("Dead")

	# Wire up hierarchy
	_hfsm.add_child(_alive)
	_hfsm.add_child(_dead)
	_alive.add_child(_idle)
	_alive.add_child(_walk)
	_alive.add_child(_run)
	_alive.add_child(_combat)
	_combat.add_child(_attack)
	_combat.add_child(_block)
	_combat.add_child(_dodge)

	# Enter/exit callables
	_idle._on_enter   = func(): _log_push("→ Idle: standing still")
	_idle._on_exit    = func(): _log_push("← Idle: leaving idle")
	_walk._on_enter   = func(): _log_push("→ Walk: moving at walk speed")
	_walk._on_exit    = func(): _log_push("← Walk: stopping walk")
	_run._on_enter    = func(): _log_push("→ Run: sprinting!")
	_run._on_exit     = func(): _log_push("← Run: slowing down")
	_combat._on_enter = func(): _log_push("→ Combat: entering combat stance")
	_combat._on_exit  = func(): _log_push("← Combat: leaving combat")
	_attack._on_enter = func(): _log_push("  → Attack: striking!")
	_attack._on_exit  = func(): _log_push("  ← Attack: recovering")
	_block._on_enter  = func(): _log_push("  → Block: raising shield")
	_block._on_exit   = func(): _log_push("  ← Block: lowering shield")
	_dodge._on_enter  = func(): _log_push("  → Dodge: rolling away!")
	_dodge._on_exit   = func(): _log_push("  ← Dodge: landed")
	_alive._on_enter  = func(): _log_push("→ Alive: character alive")
	_alive._on_exit   = func(): _log_push("← Alive: character dying")
	_dead._on_enter   = func(): _log_push("→ Dead: character has died")
	_dead._on_exit    = func(): _log_push("← Dead: resurrecting")

	# Start the machine: Root → Alive → Idle
	_hfsm.enter()

func _in_alive() -> bool:
	return _alive.is_active()

func _in_combat() -> bool:
	return _combat.is_active()

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var kb := event as InputEventKey
		if kb.pressed and not kb.echo:
			match kb.keycode:
				KEY_W:
					if kb.shift_pressed:
						# Shift+W → Run (only if walking or alive)
						if _in_alive():
							_alive.transition_to(_run)
					else:
						if _in_alive():
							_alive.transition_to(_walk)
				KEY_I:
					if _in_alive():
						_alive.transition_to(_idle)
				KEY_C:
					if _in_alive():
						_alive.transition_to(_combat)
				KEY_1:
					if _in_combat():
						_combat.transition_to(_attack)
				KEY_2:
					if _in_combat():
						_combat.transition_to(_block)
				KEY_3:
					if _in_combat():
						_combat.transition_to(_dodge)
				KEY_D:
					_health = 0
					_hfsm.transition_to(_dead)
				KEY_R:
					_health = 100
					_hfsm.transition_to(_alive)
			queue_redraw()

func _process(delta: float) -> void:
	_hfsm.tick(delta)
	queue_redraw()

func _draw() -> void:
	# ── Background ──
	draw_rect(Rect2(0, 0, 640, 480), Color(0.06, 0.06, 0.10))

	# ── Character figure (left panel, x 20..300) ──
	_draw_character()

	# ── HFSM tree (right panel, x 320..635) ──
	_draw_tree()

	# ── Active path label ──
	var path_arr := _hfsm.get_active_path()
	var path_str := " > ".join(path_arr)
	draw_rect(Rect2(4, 440, 632, 22), Color(0, 0, 0, 0.65))
	draw_string(ThemeDB.fallback_font, Vector2(8, 456), "Path: %s" % path_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.9, 0.3))

	# ── Transition log ──
	_draw_log()

	# ── Hint bar ──
	draw_rect(Rect2(0, 462, 640, 18), Color(0, 0, 0, 0.55))
	var hint := "W: walk  Shift+W: run  I: idle  C: combat  1/2/3: attack/block/dodge  D: die  R: revive"
	draw_string(ThemeDB.fallback_font, Vector2(4, 476), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.55, 0.55, 0.55))

func _draw_character() -> void:
	var cx := 155.0
	var cy := 200.0

	# Ground
	draw_line(Vector2(60, 310), Vector2(260, 310), Color(0.3, 0.3, 0.4), 2.0)

	if not _alive.is_active() and _dead.is_active():
		# Dead: character lying down
		draw_circle(Vector2(cx, 310), 16, Color(0.5, 0.1, 0.1))
		draw_line(Vector2(cx - 40, 310), Vector2(cx + 40, 310), Color(0.6, 0.2, 0.2), 6.0)
		draw_string(ThemeDB.fallback_font, Vector2(cx - 25, 340), "DEAD", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 0.2, 0.2))
		# Health bar
		draw_rect(Rect2(80, 360, 150, 12), Color(0.2, 0.0, 0.0))
		return

	# Body color based on sub-state
	var body_col := Color(0.4, 0.6, 1.0)
	if _combat.is_active():
		body_col = Color(1.0, 0.4, 0.2)
	elif _run.is_active():
		body_col = Color(0.3, 1.0, 0.4)
	elif _walk.is_active():
		body_col = Color(0.4, 0.9, 0.5)

	# Head
	draw_circle(Vector2(cx, cy - 60), 18, body_col)

	# Body
	draw_line(Vector2(cx, cy - 42), Vector2(cx, cy + 30), body_col, 5.0)

	# Arms and legs depend on state
	if _idle.is_active():
		# Arms down
		draw_line(Vector2(cx, cy - 20), Vector2(cx - 22, cy + 10), body_col, 4.0)
		draw_line(Vector2(cx, cy - 20), Vector2(cx + 22, cy + 10), body_col, 4.0)
		# Legs straight
		draw_line(Vector2(cx, cy + 30), Vector2(cx - 15, cy + 80), body_col, 4.0)
		draw_line(Vector2(cx, cy + 30), Vector2(cx + 15, cy + 80), body_col, 4.0)

	elif _walk.is_active():
		# Arms swinging
		draw_line(Vector2(cx, cy - 20), Vector2(cx - 28, cy), body_col, 4.0)
		draw_line(Vector2(cx, cy - 20), Vector2(cx + 14, cy + 20), body_col, 4.0)
		# Legs stepping
		draw_line(Vector2(cx, cy + 30), Vector2(cx - 22, cy + 75), body_col, 4.0)
		draw_line(Vector2(cx, cy + 30), Vector2(cx + 22, cy + 75), body_col, 4.0)

	elif _run.is_active():
		# Arms pumping
		draw_line(Vector2(cx, cy - 20), Vector2(cx - 30, cy - 10), body_col, 4.0)
		draw_line(Vector2(cx, cy - 20), Vector2(cx + 20, cy + 25), body_col, 4.0)
		# Legs wide
		draw_line(Vector2(cx, cy + 30), Vector2(cx - 30, cy + 70), body_col, 4.0)
		draw_line(Vector2(cx, cy + 30), Vector2(cx + 30, cy + 70), body_col, 4.0)
		# Speed lines
		for i in range(3):
			var ly := cy - 10.0 + i * 15.0
			draw_line(Vector2(cx - 55, ly), Vector2(cx - 35, ly), Color(1, 1, 0.5, 0.5), 2.0)

	elif _combat.is_active():
		if _attack.is_active():
			# Punching arm extended
			draw_line(Vector2(cx, cy - 20), Vector2(cx + 50, cy - 25), body_col, 4.0)
			draw_line(Vector2(cx, cy - 20), Vector2(cx - 18, cy + 15), body_col, 4.0)
		elif _block.is_active():
			# Arms raised, shield position
			draw_line(Vector2(cx, cy - 20), Vector2(cx - 30, cy - 30), body_col, 4.0)
			draw_line(Vector2(cx, cy - 20), Vector2(cx + 20, cy - 15), body_col, 4.0)
			# Shield
			draw_rect(Rect2(cx - 52, cy - 45, 22, 35), Color(0.7, 0.7, 0.3), false, 3.0)
		elif _dodge.is_active():
			# Leaning sideways
			draw_line(Vector2(cx, cy - 20), Vector2(cx - 15, cy + 15), body_col, 4.0)
			draw_line(Vector2(cx, cy - 20), Vector2(cx + 35, cy), body_col, 4.0)
		# Combat legs (wide stance)
		draw_line(Vector2(cx, cy + 30), Vector2(cx - 28, cy + 78), body_col, 4.0)
		draw_line(Vector2(cx, cy + 30), Vector2(cx + 28, cy + 78), body_col, 4.0)

	# Health bar
	draw_rect(Rect2(80, 360, 150, 12), Color(0.2, 0.0, 0.0))
	var hp_w := int(150.0 * _health / 100.0)
	var hp_col := Color(0.2, 0.9, 0.2)
	if _health < 50:
		hp_col = Color(1.0, 0.6, 0.1)
	if _health <= 0:
		hp_col = Color(0.5, 0.0, 0.0)
	draw_rect(Rect2(80, 360, hp_w, 12), hp_col)
	draw_rect(Rect2(80, 360, 150, 12), Color(0.5, 0.5, 0.5), false, 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(80, 388), "HP: %d" % _health, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.9, 0.9, 0.9))

	# State label under character
	var state_label: String = _alive.active_child.name if _alive.active_child else "Alive"
	if _combat.is_active() and _combat.active_child:
		state_label = "Combat / %s" % _combat.active_child.name
	draw_string(ThemeDB.fallback_font, Vector2(cx - 50, 410), state_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, body_col)

func _draw_tree() -> void:
	# Panel
	draw_rect(Rect2(316, 0, 324, 435), Color(0.0, 0.0, 0.05, 0.8))
	draw_line(Vector2(316, 0), Vector2(316, 435), Color(0.3, 0.3, 0.4), 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(322, 16), "HFSM Tree", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1))

	# Layout positions for each state
	var positions: Dictionary = {
		"Root":   Vector2(468, 36),
		"Alive":  Vector2(420, 80),
		"Dead":   Vector2(545, 80),
		"Idle":   Vector2(340, 132),
		"Walk":   Vector2(395, 132),
		"Run":    Vector2(450, 132),
		"Combat": Vector2(515, 132),
		"Attack": Vector2(475, 190),
		"Block":  Vector2(518, 190),
		"Dodge":  Vector2(561, 190),
	}

	# Parent→child edges
	var edges: Array = [
		["Root", "Alive"], ["Root", "Dead"],
		["Alive", "Idle"], ["Alive", "Walk"], ["Alive", "Run"], ["Alive", "Combat"],
		["Combat", "Attack"], ["Combat", "Block"], ["Combat", "Dodge"],
	]

	for edge in edges:
		var a: Vector2 = positions[edge[0]]
		var b: Vector2 = positions[edge[1]]
		draw_line(a + Vector2(0, 10), b - Vector2(0, 8), Color(0.4, 0.4, 0.5), 1.0)

	# Get active path for highlight
	var active_path := _hfsm.get_active_path()
	var active_set: Dictionary = {}
	for s in active_path:
		active_set[s] = true

	# Draw state boxes
	var all_states := [
		_hfsm, _alive, _dead, _idle, _walk, _run, _combat, _attack, _block, _dodge
	]
	for state in all_states:
		var pos: Vector2 = positions.get(state.name, Vector2.ZERO)
		var is_act: bool = active_set.has(state.name)

		var box_w := 40.0
		var box_h := 18.0
		var rect := Rect2(pos - Vector2(box_w * 0.5, box_h * 0.5), Vector2(box_w, box_h))

		var bg_col: Color
		var txt_col: Color
		if is_act:
			bg_col = Color(0.2, 0.6, 1.0)
			txt_col = Color(1, 1, 1)
		else:
			bg_col = Color(0.15, 0.15, 0.2)
			txt_col = Color(0.5, 0.5, 0.6)

		draw_rect(rect, bg_col)
		draw_rect(rect, Color(0.6, 0.6, 0.7) if is_act else Color(0.25, 0.25, 0.3), false, 1.0)
		var label_x := pos.x - box_w * 0.5 + 2.0
		draw_string(ThemeDB.fallback_font, Vector2(label_x, pos.y + 5), state.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, txt_col)

func _draw_log() -> void:
	draw_rect(Rect2(0, 395, 308, 45), Color(0, 0, 0, 0.65))
	draw_string(ThemeDB.fallback_font, Vector2(6, 408), "Transition Log:", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.7, 0.7, 0.7))
	var start_idx := maxi(0, _log.size() - 2)
	for i in range(start_idx, _log.size()):
		var y: float = 420.0 + (i - start_idx) * 14.0
		draw_string(ThemeDB.fallback_font, Vector2(6, y), _log[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.85, 0.85, 0.6))
