extends Node

# Drives the real threaded loading from scenes/main.tscn — see
# docs/TEST_INTEGRITY.md.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_the_demo_writes_the_resources_it_will_load()
	_test_the_written_resources_are_usable()
	_test_it_starts_idle()
	_test_pressing_load_queues_every_resource()
	_test_the_button_is_locked_while_loading()
	await _test_the_loads_complete()
	await _test_every_resource_comes_back_intact()
	await _test_the_progress_bar_fills()
	await _test_a_result_row_per_resource()
	await _test_reset_clears_up()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[thread-loading] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

var _scene: Control

func _make() -> Control:
	if is_instance_valid(_scene):
		remove_child(_scene)
		_scene.free()
	_scene = load("res://scenes/main.tscn").instantiate()
	add_child(_scene)
	return _scene

func _button(m: Control, name: String) -> Button:
	return m.get_node("VBox/Buttons/" + name)

## Run the demo's own loop until it reports it has finished, or we run out of
## patience. Threaded loading takes as many frames as it takes.
func _load_and_wait(m: Control) -> void:
	_button(m, "LoadButton").pressed.emit()
	for i in 300:
		await get_tree().process_frame
		m._process(0.0)
		if not m._loading:
			return

func _test_the_demo_writes_the_resources_it_will_load() -> void:
	print("the resources")
	var m := _make()
	begin_quiet()
	# The demo makes its own files so it has something real to load — without
	# them every load would fail and the demo would show only errors.
	for i in m.RESOURCE_COUNT:
		var path: String = m.SAVE_DIR + "resource_%02d.tres" % i
		expect_quiet(FileAccess.file_exists(path), "resource %d was not written" % i)
	expect(_quiet_failures == 0, "there is a resource on disk for every one it will load")

## Delete the demo's saved resources, so _setup_resources writes them fresh.
## Otherwise a run only ever sees the files an earlier run left behind.
func _forget_resources() -> void:
	var dir := DirAccess.open("user://thread_loading_demo/")
	if dir == null:
		return
	for file in dir.get_files():
		dir.remove(file)

func _test_the_written_resources_are_usable() -> void:
	print("what it wrote")
	_forget_resources()
	var m := _make()
	begin_quiet()
	var colours := {}
	for i in m.RESOURCE_COUNT:
		var path: String = m.SAVE_DIR + "resource_%02d.tres" % i
		var res: Variant = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		expect_quiet(res is StyleBoxFlat, "resource %d did not load back" % i)
		if res is StyleBoxFlat:
			var style := res as StyleBoxFlat
			colours[style.bg_color] = true
			# A channel outside 0..1 is not a colour anything can display.
			expect_quiet(style.bg_color.r >= 0.0 and style.bg_color.r <= 1.0,
				"resource %d has a red channel of %.2f" % [i, style.bg_color.r])
			expect_quiet(style.bg_color.b >= 0.0 and style.bg_color.b <= 1.0,
				"resource %d has a blue channel of %.2f" % [i, style.bg_color.b])
			expect_quiet(style.resource_name != "", "resource %d has no name" % i)
	expect(_quiet_failures == 0, "every written resource is a usable style box")
	expect(colours.size() == m.RESOURCE_COUNT, "each written in its own colour")

func _test_it_starts_idle() -> void:
	print("before loading")
	var m := _make()
	expect(not m._loading, "nothing is loading yet")
	expect(m._loaded.is_empty(), "and nothing has been loaded")
	expect(not _button(m, "LoadButton").disabled, "the load button is available")
	expect(is_zero_approx(m._progress_bar.value), "with the progress bar empty")

func _test_pressing_load_queues_every_resource() -> void:
	print("starting a load")
	var m := _make()
	_button(m, "LoadButton").pressed.emit()
	expect(m._loading, "pressing load starts a load")
	expect(m._pending_paths.size() == m.RESOURCE_COUNT, "with every resource queued")
	expect(m._status_label.text.contains("Loading"), "and says so")

func _test_the_button_is_locked_while_loading() -> void:
	print("during a load")
	var m := _make()
	_button(m, "LoadButton").pressed.emit()
	# Pressing load twice would queue the same paths again on top of the
	# requests already in flight.
	expect(_button(m, "LoadButton").disabled, "the load button is locked while loading")

func _test_the_loads_complete() -> void:
	print("finishing")
	var m := _make()
	await _load_and_wait(m)
	expect(not m._loading, "the loads finish")
	expect(m._loaded.size() == m.RESOURCE_COUNT, "with every resource accounted for")
	expect(not _button(m, "LoadButton").disabled, "and the button is available again")
	expect(m._status_label.text.contains("Done"), "with the readout saying so")

func _test_every_resource_comes_back_intact() -> void:
	print("what came back")
	var m := _make()
	await _load_and_wait(m)
	begin_quiet()
	for path in m._loaded:
		var res: Variant = m._loaded[path]
		expect_quiet(res != null, "%s came back as null" % path)
		expect_quiet(res is StyleBoxFlat, "%s came back as the wrong type" % path)
	expect(_quiet_failures == 0, "every resource loaded, and as the type it was saved as")

	# And they are distinct resources, not the same one handed back repeatedly.
	var names := {}
	for path in m._loaded:
		names[(m._loaded[path] as Resource).resource_name] = true
	expect(names.size() == m.RESOURCE_COUNT, "each one is its own resource")

func _test_the_progress_bar_fills() -> void:
	print("progress")
	var m := _make()
	await _load_and_wait(m)
	expect(is_equal_approx(m._progress_bar.value, 100.0),
		"the bar reads full once everything has loaded")

func _test_a_result_row_per_resource() -> void:
	print("the results list")
	var m := _make()
	await _load_and_wait(m)
	expect(m._result_list.get_child_count() == m.RESOURCE_COUNT,
		"there is a row per resource loaded")

	# And each row says what came back, not just that something did.
	begin_quiet()
	for row in m._result_list.get_children():
		var text := ""
		for label in row.get_children():
			text += (label as Label).text
		expect_quiet(text.contains("StyleBoxFlat"), "a row does not name the type it loaded")
		expect_quiet(text.contains("DemoStyle"), "a row does not name the resource it loaded")
		expect_quiet(not text.contains("FAILED"), "a row reports a failure")
	expect(_quiet_failures == 0, "every row names the resource and the type that came back")

func _test_reset_clears_up() -> void:
	print("reset")
	var m := _make()
	await _load_and_wait(m)
	_button(m, "ResetButton").pressed.emit()
	await get_tree().process_frame
	expect(m._loaded.is_empty(), "reset forgets what was loaded")
	expect(m._pending_paths.is_empty(), "and what was queued")
	expect(is_zero_approx(m._progress_bar.value), "empties the progress bar")
	expect(m._result_list.get_child_count() == 0, "clears the list")
	expect(not _button(m, "LoadButton").disabled, "and leaves the button ready to go again")

var _quiet_failures := 0

## Zero the tally, so one test's failures cannot cascade into the next.
func begin_quiet() -> void:
	_quiet_failures = 0

func expect_quiet(cond: bool, label: String) -> void:
	if not cond:
		_quiet_failures += 1
		print("  (", label, " — failed)")
