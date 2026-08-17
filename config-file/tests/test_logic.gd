extends Node

# Drives the real settings screen from scripts/main.gd — see docs/TEST_INTEGRITY.md.
#
# Persistence is the point of this demo, so the suite writes and reads the real
# user:// config file rather than a stand-in dictionary. Each test starts by
# clearing it, so a leftover file from a previous run cannot change the result.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_it_opens_on_the_defaults()
	_test_saving_writes_a_file()
	_test_settings_come_back_after_a_restart()
	_test_the_file_is_grouped_into_sections()
	_test_a_slider_follows_the_mouse()
	_test_a_slider_cannot_be_dragged_past_its_ends()
	_test_each_slider_has_its_own_range()
	_test_a_toggle_flips()
	_test_letting_go_of_a_slider_saves()
	_test_the_save_button_saves()
	_test_a_corrupt_value_is_clamped_on_load()
	_test_hit_testing_names_the_control_under_the_mouse()
	_test_the_controls_sit_inside_the_panel()
	_test_both_toggles_mark_the_settings_unsaved()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[config-file] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

var _script: GDScript = load("res://scripts/main.gd")

func _forget_saved_settings() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://settings.cfg"))

## A fresh settings screen with no saved file behind it.
func _make() -> Control:
	_forget_saved_settings()
	return _open()

## A settings screen that loads whatever is on disk, as a restart would.
func _open() -> Control:
	var m: Control = _script.new()
	add_child(m)
	return m

func _click(m: Control, at: Vector2, pressed: bool = true) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.position = at
	m._input(e)

func _move(m: Control, to: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = to
	m._input(e)

func _test_it_opens_on_the_defaults() -> void:
	print("first run")
	var m := _make()
	for key in m.DEFAULTS:
		expect(m._settings[key] == m.DEFAULTS[key], "%s starts at its default" % key)
	expect(not m._dirty, "with nothing unsaved")

func _test_saving_writes_a_file() -> void:
	print("saving")
	var m := _make()
	m._settings["master_volume"] = 42
	m._save_settings()
	expect(FileAccess.file_exists(m.CONFIG_PATH), "saving writes the config file")
	expect(not m._dirty, "and clears the unsaved marker")
	expect(m._saved_flash > 0.0, "flashing a confirmation on screen")

func _test_settings_come_back_after_a_restart() -> void:
	print("persistence")
	var m := _make()
	m._settings["master_volume"] = 42
	m._settings["fullscreen"] = true
	m._settings["player_speed"] = 275
	m._save_settings()

	var restarted := _open()
	expect(restarted._settings["master_volume"] == 42, "a saved number comes back")
	expect(restarted._settings["fullscreen"] == true, "and a saved toggle")
	expect(restarted._settings["player_speed"] == 275, "and a saved speed")

func _test_the_file_is_grouped_into_sections() -> void:
	print("the file itself")
	var m := _make()
	m._save_settings()
	var cfg := ConfigFile.new()
	expect(cfg.load(m.CONFIG_PATH) == OK, "the file it wrote is a valid ConfigFile")
	# Sections are what make a settings file readable by hand.
	expect(cfg.has_section_key("audio", "master_volume"), "volumes are filed under audio")
	expect(cfg.has_section_key("display", "fullscreen"), "display options under display")
	expect(cfg.has_section_key("gameplay", "player_speed"), "and gameplay under gameplay")

func _test_a_slider_follows_the_mouse() -> void:
	print("dragging a slider")
	var m := _make()
	var rect: Rect2 = m._get_slider_rect(0)
	_click(m, rect.position + rect.size * 0.5)
	expect(m._dragging == "master_volume", "pressing on the track picks up the slider")
	expect(m._settings["master_volume"] == 50, "the middle of the track is halfway along the range")
	expect(m._dirty, "and the change is marked unsaved")

	_move(m, rect.position + Vector2(rect.size.x * 0.25, rect.size.y * 0.5))
	expect(m._settings["master_volume"] == 25, "the value tracks the mouse while held")

func _test_a_slider_cannot_be_dragged_past_its_ends() -> void:
	print("slider limits")
	var m := _make()
	var rect: Rect2 = m._get_slider_rect(0)
	_click(m, rect.position + rect.size * 0.5)
	_move(m, rect.position + Vector2(-500.0, rect.size.y * 0.5))
	expect(m._settings["master_volume"] == 0, "dragging off the left end stops at the minimum")
	_move(m, rect.position + Vector2(rect.size.x + 500.0, rect.size.y * 0.5))
	expect(m._settings["master_volume"] == 100, "and off the right end at the maximum")

func _test_each_slider_has_its_own_range() -> void:
	print("ranges")
	var m := _make()
	var rect: Rect2 = m._get_slider_rect(3)
	_click(m, rect.position + Vector2(0.0, rect.size.y * 0.5))
	expect(m._settings["player_speed"] == 50, "player speed bottoms out at 50, not 0")
	_move(m, rect.position + Vector2(rect.size.x, rect.size.y * 0.5))
	expect(m._settings["player_speed"] == 300, "and tops out at 300")

func _test_a_toggle_flips() -> void:
	print("toggles")
	var m := _make()
	var rect: Rect2 = m._get_toggle_rect(2)
	var before: bool = m._settings["fullscreen"]
	_click(m, rect.position + rect.size * 0.5)
	expect(m._settings["fullscreen"] != before, "clicking a toggle flips it")
	expect(m._dirty, "and marks the settings unsaved")
	_click(m, rect.position + rect.size * 0.5)
	expect(m._settings["fullscreen"] == before, "and clicking again flips it back")
	expect(m._dragging == "", "a toggle is not something you drag")

func _test_letting_go_of_a_slider_saves() -> void:
	print("save on release")
	var m := _make()
	var rect: Rect2 = m._get_slider_rect(1)
	_click(m, rect.position + Vector2(rect.size.x * 0.25, rect.size.y * 0.5))
	_click(m, rect.position + Vector2(rect.size.x * 0.25, rect.size.y * 0.5), false)
	expect(m._dragging == "", "releasing drops the slider")
	expect(not m._dirty, "and writes the change out")

	var restarted := _open()
	expect(restarted._settings["sfx_volume"] == 25, "so the new value survives a restart")

func _test_the_save_button_saves() -> void:
	print("the save button")
	var m := _make()
	m._settings["master_volume"] = 7
	m._dirty = true
	_click(m, m.SAVE_RECT.position + m.SAVE_RECT.size * 0.5)
	expect(not m._dirty, "the button saves")
	expect(m._dragging == "", "without grabbing anything")
	var restarted := _open()
	expect(restarted._settings["master_volume"] == 7, "and the value is on disk")

func _test_a_corrupt_value_is_clamped_on_load() -> void:
	print("a bad file")
	_forget_saved_settings()
	# Hand-edited config files are a fact of life; a volume of 900 must not make
	# it into the running settings.
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master_volume", 900)
	cfg.set_value("gameplay", "player_speed", -40)
	cfg.save("user://settings.cfg")

	var m := _open()
	expect(m._settings["master_volume"] == 100, "an out-of-range volume is clamped to the maximum")
	expect(m._settings["player_speed"] == 50, "and a negative speed to the minimum")

func _test_hit_testing_names_the_control_under_the_mouse() -> void:
	print("hover")
	var m := _make()
	_move(m, m._get_slider_rect(0).position + Vector2(4.0, 8.0))
	expect(m._hovered_control == "master_volume", "the mouse over a slider names that slider")
	_move(m, m._get_toggle_rect(4).position + Vector2(4.0, 8.0))
	expect(m._hovered_control == "show_fps", "over a toggle, that toggle")
	_move(m, m.SAVE_RECT.position + Vector2(4.0, 8.0))
	expect(m._hovered_control == "save", "and over the button, the button")
	_move(m, Vector2(5.0, 470.0))
	expect(m._hovered_control == "", "away from everything it names nothing")

func _test_the_controls_sit_inside_the_panel() -> void:
	print("layout")
	var m := _make()
	# Clicks in the other tests are derived from these same rects, so they would
	# happily follow a control that had wandered off the panel. This is the test
	# that says where the panel is.
	var panel := Rect2(m.PANEL_X, m.PANEL_Y, m.PANEL_W, m.PANEL_H)
	var rects := {
		"master volume": m._get_slider_rect(0),
		"sfx volume": m._get_slider_rect(1),
		"fullscreen": m._get_toggle_rect(2),
		"player speed": m._get_slider_rect(3),
		"show fps": m._get_toggle_rect(4),
		"save button": m.SAVE_RECT,
	}
	for name in rects:
		var r: Rect2 = rects[name]
		expect(panel.encloses(r), "the %s control is inside the panel" % name)
		expect(r.position.x > m.PANEL_X + m.LABEL_X, "and clear of the label column")

	var save_centre: float = m.SAVE_RECT.position.x + m.SAVE_RECT.size.x * 0.5
	expect(is_equal_approx(save_centre, m.PANEL_X + m.PANEL_W * 0.5),
		"the save button is centred under the panel")

	var first: Rect2 = m._get_slider_rect(0)
	var second: Rect2 = m._get_slider_rect(1)
	expect(not first.intersects(second), "consecutive rows do not overlap")
	expect(second.position.y > first.position.y, "and run down the panel in order")

func _test_both_toggles_mark_the_settings_unsaved() -> void:
	print("unsaved changes")
	var m := _make()
	var rect: Rect2 = m._get_toggle_rect(4)
	var before: bool = m._settings["show_fps"]
	_click(m, rect.position + rect.size * 0.5)
	expect(m._settings["show_fps"] != before, "the second toggle flips too")
	expect(m._dirty, "and marks the settings unsaved, like the first")
