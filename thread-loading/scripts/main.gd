extends Control

# Number of resources to create and load as a demonstration
const RESOURCE_COUNT := 8
const SAVE_DIR := "user://thread_loading_demo/"

var _pending_paths: Array[String] = []
var _loaded: Dictionary = {}
var _loading := false
var _load_button: Button
var _reset_button: Button
var _progress_bar: ProgressBar
var _status_label: Label
var _result_list: VBoxContainer

func _ready() -> void:
	_load_button = $VBox/Buttons/LoadButton
	_reset_button = $VBox/Buttons/ResetButton
	_progress_bar = $VBox/ProgressBar
	_status_label = $VBox/StatusLabel
	_result_list = $VBox/ResultList

	_load_button.pressed.connect(_on_load_pressed)
	_reset_button.pressed.connect(_on_reset_pressed)

	_setup_resources()

func _setup_resources() -> void:
	# Create test resources on disk so we have something to load
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	for i in RESOURCE_COUNT:
		var path := SAVE_DIR + "resource_%02d.tres" % i
		if not FileAccess.file_exists(path):
			var sb := StyleBoxFlat.new()
			sb.resource_name = "DemoStyle_%d" % i
			sb.bg_color = Color(float(i) / RESOURCE_COUNT, 0.5, 1.0 - float(i) / RESOURCE_COUNT)
			sb.corner_radius_top_left = i * 4
			sb.corner_radius_top_right = i * 4
			sb.corner_radius_bottom_left = i * 4
			sb.corner_radius_bottom_right = i * 4
			ResourceSaver.save(sb, path)

func _on_load_pressed() -> void:
	_clear_results()
	_pending_paths.clear()
	_loaded.clear()
	_loading = true
	_load_button.disabled = true
	_progress_bar.value = 0

	for i in RESOURCE_COUNT:
		var path := SAVE_DIR + "resource_%02d.tres" % i
		# CACHE_MODE_IGNORE forces a fresh disk read each time
		var err := ResourceLoader.load_threaded_request(
			path, "", false, ResourceLoader.CACHE_MODE_IGNORE
		)
		if err == OK:
			_pending_paths.append(path)
		else:
			_status_label.text = "Error starting load for: " + path.get_file()

	_status_label.text = "Loading %d resources..." % _pending_paths.size()

func _on_reset_pressed() -> void:
	_clear_results()
	_loading = false
	_pending_paths.clear()
	_loaded.clear()
	_progress_bar.value = 0
	_status_label.text = "Press 'Start Loading' to begin"
	_load_button.disabled = false

func _process(_delta: float) -> void:
	if not _loading:
		return

	var total := _pending_paths.size()
	if total == 0:
		return

	var done_count := 0
	var in_progress := false

	for path in _pending_paths:
		if _loaded.has(path):
			done_count += 1
			continue

		var progress_arr: Array = []
		var status := ResourceLoader.load_threaded_get_status(path, progress_arr)

		match status:
			ResourceLoader.THREAD_LOAD_LOADED:
				var res := ResourceLoader.load_threaded_get(path)
				_loaded[path] = res
				done_count += 1
				_add_result(path, res)

			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				in_progress = true

			ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				_loaded[path] = null
				done_count += 1
				_add_result(path, null)

	# Overall progress: fraction of completed loads
	_progress_bar.value = float(done_count) / total * 100.0

	if not in_progress and done_count == total:
		_loading = false
		_load_button.disabled = false
		_status_label.text = "Done — loaded %d resources" % done_count

func _add_result(path: String, res: Resource) -> void:
	var row := HBoxContainer.new()

	var name_label := Label.new()
	name_label.text = path.get_file()
	name_label.custom_minimum_size.x = 200
	name_label.add_theme_font_size_override("font_size", 12)
	row.add_child(name_label)

	var type_label := Label.new()
	if res:
		type_label.text = "→  " + res.get_class()
		if res.resource_name != "":
			type_label.text += " (%s)" % res.resource_name
		type_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
	else:
		type_label.text = "→  FAILED"
		type_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	type_label.add_theme_font_size_override("font_size", 12)
	row.add_child(type_label)

	_result_list.add_child(row)

func _clear_results() -> void:
	for child in _result_list.get_children():
		child.queue_free()
