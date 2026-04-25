extends Node2D

const WORLD_W := 1200
const WORLD_H := 900
const PLAYER_SPEED := 200.0
const MINIMAP_W := 160
const MINIMAP_H := 114  # matches display offset_bottom - offset_top

var _player_pos := Vector2(WORLD_W / 2.0, WORLD_H / 2.0)
var _main_cam: Camera2D
var _minimap_cam: Camera2D
var _minimap_vp: SubViewport
var _objects: Array  # {pos, color, size, shape}

func _ready() -> void:
	_main_cam = $MainCamera
	_minimap_vp = $MinimapViewport
	_minimap_cam = $MinimapViewport/MinimapCamera

	# Share the main viewport's World2D so MinimapCamera sees the same scene
	_minimap_vp.world_2d = get_viewport().world_2d

	# Zoom the minimap camera out to see the whole world at once
	var zoom_x := float(MINIMAP_W) / float(WORLD_W)
	var zoom_y := float(MINIMAP_H) / float(WORLD_H)
	var zoom := minf(zoom_x, zoom_y)
	_minimap_cam.zoom = Vector2(zoom, zoom)
	_minimap_cam.position = Vector2(WORLD_W / 2.0, WORLD_H / 2.0)

	# Connect SubViewport output to the HUD display
	$HUD/MinimapDisplay.texture = _minimap_vp.get_texture()

	# Generate scattered world objects with a fixed seed
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	for i in 35:
		var sz := rng.randf_range(24, 80)
		_objects.append({
			"pos": Vector2(rng.randf_range(sz, WORLD_W - sz), rng.randf_range(sz, WORLD_H - sz)),
			"color": Color(rng.randf_range(0.3, 1.0), rng.randf_range(0.3, 1.0), rng.randf_range(0.3, 1.0)),
			"size": sz,
			"shape": rng.randi() % 2,  # 0=rect, 1=circle
		})

func _process(delta: float) -> void:
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	_player_pos += dir * PLAYER_SPEED * delta
	_player_pos.x = clampf(_player_pos.x, 16, WORLD_W - 16)
	_player_pos.y = clampf(_player_pos.y, 16, WORLD_H - 16)

	# Main camera follows player
	_main_cam.position = _player_pos

	# Update player indicator in minimap (tiny dot overlay)
	var minimap_origin := Vector2(470, 360)
	var px := minimap_origin.x + (_player_pos.x / WORLD_W) * MINIMAP_W
	var py := minimap_origin.y + (_player_pos.y / WORLD_H) * MINIMAP_H
	$HUD/PlayerDot.visible = true
	$HUD/PlayerDot.offset_left = px - 3
	$HUD/PlayerDot.offset_top = py - 3
	$HUD/PlayerDot.offset_right = px + 3
	$HUD/PlayerDot.offset_bottom = py + 3
	$HUD/PlayerDot.color = Color(1, 1, 0, 0.9)

	queue_redraw()

func _draw() -> void:
	# World background with subtle grid
	draw_rect(Rect2(0, 0, WORLD_W, WORLD_H), Color(0.10, 0.12, 0.18))
	for gx in range(0, WORLD_W + 1, 120):
		draw_line(Vector2(gx, 0), Vector2(gx, WORLD_H), Color(0.18, 0.20, 0.28), 1)
	for gy in range(0, WORLD_H + 1, 90):
		draw_line(Vector2(0, gy), Vector2(WORLD_W, gy), Color(0.18, 0.20, 0.28), 1)

	# World border
	draw_rect(Rect2(0, 0, WORLD_W, WORLD_H), Color(0.3, 0.4, 0.6), false, 3)

	# Scattered world objects
	for obj in _objects:
		var c: Color = obj["color"]
		var s: float = obj["size"]
		var p: Vector2 = obj["pos"]
		if obj["shape"] == 0:
			draw_rect(Rect2(p - Vector2(s, s) * 0.5, Vector2(s, s)), c)
			draw_rect(Rect2(p - Vector2(s, s) * 0.5, Vector2(s, s)), c.lightened(0.3), false, 1.5)
		else:
			draw_circle(p, s * 0.5, c)
			draw_arc(p, s * 0.5, 0, TAU, 24, c.lightened(0.3), 1.5)

	# Player (bright yellow, visible in both views)
	draw_circle(_player_pos, 16, Color(1.0, 0.85, 0.0))
	draw_circle(_player_pos, 12, Color(1.0, 1.0, 0.4))
	draw_circle(_player_pos, 5, Color.WHITE)

	# Main camera viewport frame (shows what the main view is seeing)
	var half_w := 320.0
	var half_h := 240.0
	var frame := Rect2(_player_pos - Vector2(half_w, half_h), Vector2(640, 480))
	draw_rect(frame, Color(0.5, 0.8, 1.0, 0.25))
	draw_rect(frame, Color(0.5, 0.8, 1.0, 0.6), false, 1.5)
