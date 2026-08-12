extends Node2D

enum Mode { TERRAIN, CAVES, ISLAND, MOISTURE }

const MAP_W := 78
const MAP_H := 52
const CELL  := 8

var _noise     := FastNoiseLite.new()
var _map       : Array[float] = []
var _mode      := Mode.TERRAIN
var _seed      := 0

@onready var mode_label : Label = $ModeLabel

func _ready() -> void:
	$Buttons/TerrainBtn.pressed.connect(func():   _set_mode(Mode.TERRAIN))
	$Buttons/CaveBtn.pressed.connect(func():      _set_mode(Mode.CAVES))
	$Buttons/IslandBtn.pressed.connect(func():    _set_mode(Mode.ISLAND))
	$Buttons/MoistureBtn.pressed.connect(func():  _set_mode(Mode.MOISTURE))
	$Buttons/RegenerateBtn.pressed.connect(_regenerate)
	_noise.noise_type   = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_noise.fractal_octaves = 5
	_noise.frequency    = 0.035
	_regenerate()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		_regenerate()

func _set_mode(m: Mode) -> void:
	_mode = m
	var names := ["Terrain", "Caves", "Island", "Moisture"]
	mode_label.text = "Mode: " + names[m]
	queue_redraw()

func _regenerate() -> void:
	_seed = randi()
	_noise.seed = _seed
	_map.clear()
	for y in MAP_H:
		for x in MAP_W:
			_map.append(_noise.get_noise_2d(x, y))
	queue_redraw()

func _noise_at(x: int, y: int) -> float:
	return _map[y * MAP_W + x]

func _draw() -> void:
	for y in MAP_H:
		for x in MAP_W:
			var n := _noise_at(x, y)
			var col := _sample_color(x, y, n)
			draw_rect(Rect2(x * CELL + 1, y * CELL + 65, CELL - 1, CELL - 1), col)

func _sample_color(x: int, y: int, n: float) -> Color:
	match _mode:
		Mode.TERRAIN:
			if n < -0.35: return Color(0.1, 0.2, 0.7)   # deep water
			if n < -0.1:  return Color(0.2, 0.4, 0.85)  # shallow water
			if n < 0.0:   return Color(0.75, 0.7, 0.4)  # sand
			if n < 0.25:  return Color(0.2, 0.55, 0.2)  # grass
			if n < 0.5:   return Color(0.3, 0.45, 0.2)  # forest
			if n < 0.7:   return Color(0.5, 0.45, 0.35) # mountain
			return Color(0.9, 0.9, 0.9)                  # snow
		Mode.CAVES:
			return Color.BLACK if n > 0.05 else Color(0.7, 0.65, 0.55)
		Mode.ISLAND:
			# Use distance from center to create island falloff
			var cx := float(x) / MAP_W - 0.5
			var cy := float(y) / MAP_H - 0.5
			var d   := Vector2(cx, cy).length() * 2.2
			var v   := n - d
			if v < -0.3: return Color(0.1, 0.2, 0.7)
			if v < 0.0:  return Color(0.75, 0.7, 0.4)
			if v < 0.3:  return Color(0.2, 0.55, 0.2)
			return Color(0.4, 0.35, 0.25)
		Mode.MOISTURE:
			var t := (n + 1.0) * 0.5  # remap −1…1 to 0…1
			return Color(0.1 + t * 0.1, 0.3 + t * 0.5, 0.8 - t * 0.6)
	return Color.MAGENTA
