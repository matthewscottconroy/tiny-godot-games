extends Node

# Drives the real tilemap from scenes/main.tscn — see docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_tileset_is_built_in_code()
	_test_the_map_data_is_laid_out()
	_test_empty_cells_stay_empty()
	_test_solid_tiles_have_collision()
	_test_water_does_not()
	_test_the_number_keys_pick_a_tile()
	_test_clicking_paints_the_selected_tile()
	_test_right_click_erases()
	_test_the_eraser_selection_erases_on_a_left_click()
	_test_clicks_map_to_the_cell_under_them()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[tilemap] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

var _scene: Node2D

func _make() -> Node2D:
	if is_instance_valid(_scene):
		remove_child(_scene)
		_scene.free()
	_scene = load("res://scenes/main.tscn").instantiate()
	add_child(_scene)
	return _scene

func _layer(m: Node2D) -> TileMapLayer:
	return m.get_node("TileMapLayer")

func _press(m: Node2D, code: Key) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.pressed = true
	m._unhandled_input(e)

func _click(m: Node2D, cell: Vector2i, button: int) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = button
	e.pressed = true
	e.position = _layer(m).to_global(_layer(m).map_to_local(cell))
	m._unhandled_input(e)

## An empty cell well away from the drawn map.
func _blank_cell(m: Node2D) -> Vector2i:
	return Vector2i(3, 2)

func _test_the_tileset_is_built_in_code() -> void:
	print("the tileset")
	var m := _make()
	var tileset := _layer(m).tile_set
	expect(tileset != null, "the layer has a tileset")
	expect(tileset.tile_size == Vector2i(m.TILE_SIZE, m.TILE_SIZE), "with the demo's tile size")
	var source := tileset.get_source(0) as TileSetAtlasSource
	expect(source != null, "built from an atlas source")
	expect(source.get_tiles_count() == 3, "holding the three tile types the map uses")
	expect(source.texture != null, "with a texture generated in code")

func _test_the_map_data_is_laid_out() -> void:
	print("the map")
	var m := _make()
	var layer := _layer(m)
	begin_quiet()
	for row in m.MAP_DATA.size():
		for col in (m.MAP_DATA[row] as Array).size():
			var wanted: int = m.MAP_DATA[row][col]
			if wanted == 0:
				continue
			var atlas := layer.get_cell_atlas_coords(Vector2i(col, row))
			# The map stores 1-based ids and the atlas is 0-based; an off-by-one
			# here paints the whole level as the wrong material.
			expect_quiet(atlas == Vector2i(wanted - 1, 0),
				"cell %d,%d holds %s, expected tile %d" % [col, row, atlas, wanted - 1])
	expect(_quiet_failures == 0, "every cell in the map data was placed as the tile it names")

func _test_empty_cells_stay_empty() -> void:
	print("empty cells")
	var m := _make()
	var layer := _layer(m)
	begin_quiet()
	for row in m.MAP_DATA.size():
		for col in (m.MAP_DATA[row] as Array).size():
			if m.MAP_DATA[row][col] == 0:
				expect_quiet(layer.get_cell_source_id(Vector2i(col, row)) == -1,
					"cell %d,%d should be empty" % [col, row])
	expect(_quiet_failures == 0, "a zero in the map data leaves the cell empty")

func _test_solid_tiles_have_collision() -> void:
	print("collision")
	var m := _make()
	var source := _layer(m).tile_set.get_source(0) as TileSetAtlasSource
	begin_quiet()
	for atlas_x in [0, 1]:
		var data := source.get_tile_data(Vector2i(atlas_x, 0), 0)
		expect_quiet(data.get_collision_polygons_count(0) > 0,
			"tile %d has no collision, so the player falls through it" % atlas_x)
	expect(_quiet_failures == 0, "the ground tiles are solid")

func _test_water_does_not() -> void:
	print("water")
	var m := _make()
	var source := _layer(m).tile_set.get_source(0) as TileSetAtlasSource
	var water := source.get_tile_data(Vector2i(2, 0), 0)
	# Water is scenery: collision on it would make the pool a wall.
	expect(water.get_collision_polygons_count(0) == 0, "water is walked through, not stood on")

func _test_the_number_keys_pick_a_tile() -> void:
	print("the palette keys")
	var m := _make()
	for pair in [[KEY_1, 1], [KEY_2, 2], [KEY_3, 3], [KEY_4, 0]]:
		_press(m, pair[0])
		expect(m._paint_tile == pair[1], "a number key selects its tile")

func _test_clicking_paints_the_selected_tile() -> void:
	print("painting")
	var m := _make()
	var cell := _blank_cell(m)
	expect(_layer(m).get_cell_source_id(cell) == -1, "the cell starts empty")
	_press(m, KEY_2)
	_click(m, cell, MOUSE_BUTTON_LEFT)
	expect(_layer(m).get_cell_atlas_coords(cell) == Vector2i(1, 0),
		"clicking paints the selected tile there")

func _test_right_click_erases() -> void:
	print("erasing")
	var m := _make()
	var cell := _blank_cell(m)
	_press(m, KEY_1)
	_click(m, cell, MOUSE_BUTTON_LEFT)
	expect(_layer(m).get_cell_source_id(cell) != -1, "painted")
	_click(m, cell, MOUSE_BUTTON_RIGHT)
	expect(_layer(m).get_cell_source_id(cell) == -1, "right-click clears the cell")

func _test_the_eraser_selection_erases_on_a_left_click() -> void:
	print("the eraser")
	var m := _make()
	var cell := _blank_cell(m)
	_press(m, KEY_1)
	_click(m, cell, MOUSE_BUTTON_LEFT)
	_press(m, KEY_4)
	_click(m, cell, MOUSE_BUTTON_LEFT)
	# Selecting the eraser makes the left button erase too, rather than
	# painting a tile that does not exist.
	expect(_layer(m).get_cell_source_id(cell) == -1, "with the eraser chosen, a left click clears")

func _test_clicks_map_to_the_cell_under_them() -> void:
	print("hit testing")
	var m := _make()
	var layer := _layer(m)
	begin_quiet()
	for cell in [Vector2i(1, 1), Vector2i(7, 3), Vector2i(15, 2)]:
		var fresh := _make()
		_press(fresh, KEY_3)
		_click(fresh, cell, MOUSE_BUTTON_LEFT)
		expect_quiet(_layer(fresh).get_cell_atlas_coords(cell) == Vector2i(2, 0),
			"a click over %s painted somewhere else" % cell)
	expect(_quiet_failures == 0, "a click paints the cell it lands on")

var _quiet_failures := 0

## Zero the tally, so one test's failures cannot cascade into the next.
func begin_quiet() -> void:
	_quiet_failures = 0

func expect_quiet(cond: bool, label: String) -> void:
	if not cond:
		_quiet_failures += 1
		print("  (", label, " — failed)")
