extends Node2D

const TILE_SIZE := 32

@onready var tilemap : TileMap         = $TileMap
@onready var player  : CharacterBody2D = $Player

const MAP_DATA := [
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
	[0,0,0,0,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0],
	[0,0,0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0],
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
	[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
	[2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2],
	[2,2,2,2,2,3,3,3,3,3,2,2,2,2,2,2,2,2,2,2],
	[2,2,2,2,2,3,3,3,3,3,2,2,2,2,2,2,2,2,2,2],
	[2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2],
]

var _paint_tile := 1

func _ready() -> void:
	_build_tileset()
	_load_map()
	_setup_player()
	player.draw.connect(func():
		player.draw_rect(Rect2(-11, -22, 22, 44), Color.CORNFLOWER_BLUE)
		player.draw_rect(Rect2(-6, -18, 5, 5), Color.WHITE)
		player.draw_rect(Rect2(1,  -18, 5, 5), Color.WHITE))

func _build_tileset() -> void:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)

	var source := TileSetAtlasSource.new()
	var colors := [Color(0.2, 0.65, 0.25), Color(0.45, 0.40, 0.35), Color(0.2, 0.4, 0.85)]
	var img    := Image.create(TILE_SIZE * 3, TILE_SIZE, false, Image.FORMAT_RGB8)
	for ti in 3:
		var col := colors[ti]
		for y in TILE_SIZE:
			for x in TILE_SIZE:
				var border := x == 0 or y == 0 or x == TILE_SIZE-1 or y == TILE_SIZE-1
				img.set_pixel(ti * TILE_SIZE + x, y, col.darkened(0.2) if border else col)
	source.texture             = ImageTexture.create_from_image(img)
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	for ax in 3:
		source.create_tile(Vector2i(ax, 0))
	tileset.add_source(source, 0)
	tileset.add_physics_layer(0)
	var sq := PackedVector2Array([Vector2(-16,-16),Vector2(16,-16),Vector2(16,16),Vector2(-16,16)])
	for ax in [0, 1]:
		var td := source.get_tile_data(Vector2i(ax, 0), 0)
		td.add_collision_polygon(0)
		td.set_collision_polygon_points(0, 0, sq)
	tilemap.tile_set = tileset

func _load_map() -> void:
	for row in MAP_DATA.size():
		for col in MAP_DATA[row].size():
			var t := MAP_DATA[row][col]
			if t > 0:
				tilemap.set_cell(0, Vector2i(col, row), 0, Vector2i(t - 1, 0))

func _setup_player() -> void:
	var shape    := CapsuleShape2D.new()
	shape.radius  = 10
	shape.height  = 24
	$Player/CollisionShape2D.shape = shape

func _physics_process(delta: float) -> void:
	if not player.is_on_floor():
		player.velocity.y += 900.0 * delta
	if player.is_on_floor() and Input.is_action_just_pressed("ui_up"):
		player.velocity.y = -420.0
	player.velocity.x = Input.get_axis("ui_left", "ui_right") * 180.0
	player.move_and_slide()
	player.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: _paint_tile = 1
			KEY_2: _paint_tile = 2
			KEY_3: _paint_tile = 3
			KEY_4: _paint_tile = 0
	if event is InputEventMouseButton and event.pressed:
		var cell := tilemap.local_to_map(tilemap.to_local(event.position))
		if event.button_index == MOUSE_BUTTON_LEFT:
			if _paint_tile > 0:
				tilemap.set_cell(0, cell, 0, Vector2i(_paint_tile - 1, 0))
			else:
				tilemap.erase_cell(0, cell)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			tilemap.erase_cell(0, cell)

func _draw() -> void:
	var names := ["Erase (4)", "Grass (1)", "Stone (2)", "Water (3)"]
	draw_string(ThemeDB.fallback_font, Vector2(4, 445),
		"Paint: %s  |  1-4 select  LMB=paint  RMB=erase" % names[_paint_tile],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
