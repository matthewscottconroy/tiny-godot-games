extends Node2D

const PRESETS := [
	{
		"name": "Fractal Tree",
		"axiom": "X",
		"rules": {"X": "F+[[X]-X]-F[-FX]+X", "F": "FF"},
		"angle": 25.0,
		"iters": 5,
		"length": 3.0,
		"start": Vector2(320.0, 465.0),
		"start_angle": -90.0,
	},
	{
		"name": "Fern",
		"axiom": "X",
		"rules": {"X": "+F-[[X]-X]-F[-FX]+X", "F": "FF"},
		"angle": 22.5,
		"iters": 6,
		"length": 2.5,
		"start": Vector2(320.0, 468.0),
		"start_angle": -90.0,
	},
	{
		"name": "Koch Snowflake",
		"axiom": "F--F--F",
		"rules": {"F": "F+F--F+F"},
		"angle": 60.0,
		"iters": 4,
		"length": 5.0,
		"start": Vector2(80.0, 310.0),
		"start_angle": 0.0,
	},
]

var _current  := 0
var _lines    := PackedVector2Array()
var _name_str := ""

func _ready() -> void:
	_generate()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			_current = (_current + 1) % PRESETS.size()
			_generate()

func _generate() -> void:
	var p: Dictionary = PRESETS[_current]
	_name_str  = p["name"]
	var s     := _expand(p["axiom"], p["rules"], p["iters"])
	_lines     = _turtle(s, p["start"], p["start_angle"], p["angle"], p["length"])
	queue_redraw()

func _expand(axiom: String, rules: Dictionary, iters: int) -> String:
	var s := axiom
	for _i in iters:
		var next := ""
		for c in s:
			next += rules.get(c, c)
		s = next
	return s

func _turtle(s: String, start: Vector2, start_angle: float,
		turn: float, seg_len: float) -> PackedVector2Array:
	var pts   := PackedVector2Array()
	var pos   := start
	var angle := deg_to_rad(start_angle)
	var stack: Array = []
	for c in s:
		match c:
			"F":
				var npos := pos + Vector2(cos(angle), sin(angle)) * seg_len
				pts.append(pos)
				pts.append(npos)
				pos = npos
			"f":
				pos += Vector2(cos(angle), sin(angle)) * seg_len
			"+":
				angle -= deg_to_rad(turn)
			"-":
				angle += deg_to_rad(turn)
			"[":
				stack.push_back([pos, angle])
			"]":
				if not stack.is_empty():
					var state: Array = stack.pop_back()
					pos   = state[0]
					angle = state[1]
	return pts

func _draw() -> void:
	for i in range(0, _lines.size() - 1, 2):
		var t := float(i) / float(maxf(_lines.size(), 1))
		var col := Color(0.2 + t * 0.3, 0.5 + t * 0.2, 0.2)
		draw_line(_lines[i], _lines[i + 1], col, 1.0)
