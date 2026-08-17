extends Node

# Drives the real settings panel from scenes/main.tscn — see docs/TEST_INTEGRITY.md.
#
# It writes and reads the real user:// config, so each test clears it first —
# a leftover file from an earlier run would decide what the panel opens with.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_it_opens_on_the_defaults()
	_test_the_controls_show_the_saved_values()
	_test_dragging_the_slider_updates_its_readout()
	_test_editing_without_applying_changes_nothing_saved()
	_test_apply_saves_the_controls()
	_test_saved_settings_survive_a_restart()
	_test_apply_sets_the_audio_bus()
	_test_cancel_puts_the_controls_back()
	_test_reset_returns_to_the_defaults()
	_test_reset_is_not_saved_until_applied()
	_test_a_config_missing_a_key_falls_back_to_its_default()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[settings-menu] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

var _scene: Control

func _forget_saved_settings() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://settings.cfg"))

## A panel with nothing saved behind it.
func _make() -> Control:
	_forget_saved_settings()
	return _open()

## A panel that loads whatever is on disk, as a restart would.
func _open() -> Control:
	if is_instance_valid(_scene):
		remove_child(_scene)
		_scene.free()
	_scene = load("res://scenes/main.tscn").instantiate()
	add_child(_scene)
	return _scene

func _button(m: Control, name: String) -> Button:
	return m.get_node("Panel/VBox/ButtonRow/" + name)

func _status(m: Control) -> String:
	return (m.get_node("Panel/VBox/StatusLabel") as Label).text

func _test_it_opens_on_the_defaults() -> void:
	print("first run")
	var m := _make()
	expect(is_equal_approx(m._saved_vol, 1.0), "volume starts at full")
	expect(not m._saved_fs, "windowed")
	expect(m._saved_speed == 200, "and at the default speed")

func _test_the_controls_show_the_saved_values() -> void:
	print("the controls")
	var m := _make()
	expect(is_equal_approx(m._vol_slider.value, m._saved_vol), "the slider shows the saved volume")
	expect(m._fs_check.button_pressed == m._saved_fs, "the checkbox the saved mode")
	expect(int(m._speed_spin.value) == m._saved_speed, "and the spinner the saved speed")
	expect(m._vol_label.text.contains("100"), "with the volume written out as a percentage")

func _test_dragging_the_slider_updates_its_readout() -> void:
	print("the slider")
	var m := _make()
	m._vol_slider.value = 0.5
	expect(m._vol_label.text.contains("50"), "moving the slider updates the number beside it")
	expect(is_equal_approx(m._saved_vol, 1.0), "without saving anything yet")

func _test_editing_without_applying_changes_nothing_saved() -> void:
	print("unapplied edits")
	var m := _make()
	m._vol_slider.value = 0.25
	m._fs_check.button_pressed = true
	m._speed_spin.value = 400
	expect(is_equal_approx(m._saved_vol, 1.0), "the saved volume is untouched")
	expect(not m._saved_fs, "and the saved mode")
	expect(m._saved_speed == 200, "and the saved speed")
	expect(not FileAccess.file_exists(m.CONFIG_PATH), "nothing has been written to disk")

func _test_apply_saves_the_controls() -> void:
	print("apply")
	var m := _make()
	m._vol_slider.value = 0.4
	m._fs_check.button_pressed = true
	m._speed_spin.value = 350
	_button(m, "ApplyButton").pressed.emit()
	expect(is_equal_approx(m._saved_vol, 0.4), "apply takes the volume from the slider")
	expect(m._saved_fs, "the mode from the checkbox")
	expect(m._saved_speed == 350, "and the speed from the spinner")
	expect(_status(m).contains("saved"), "and says so")
	expect(FileAccess.file_exists(m.CONFIG_PATH), "with a config file on disk")

	# Windowed again, so a fullscreen flag cannot follow the suite around.
	m._fs_check.button_pressed = false
	_button(m, "ApplyButton").pressed.emit()

func _test_saved_settings_survive_a_restart() -> void:
	print("persistence")
	var m := _make()
	m._vol_slider.value = 0.3
	# On the spinner's step grid, or it rounds and the comparison is about
	# arithmetic rather than about persistence.
	m._speed_spin.value = 280
	_button(m, "ApplyButton").pressed.emit()

	var restarted := _open()
	expect(is_equal_approx(restarted._saved_vol, 0.3), "the volume comes back")
	expect(restarted._saved_speed == 280, "and the speed")
	expect(is_equal_approx(restarted._vol_slider.value, 0.3), "with the controls showing them")

func _test_apply_sets_the_audio_bus() -> void:
	print("taking effect")
	var m := _make()
	m._vol_slider.value = 0.5
	_button(m, "ApplyButton").pressed.emit()
	# Saved but never applied to the audio bus, the setting would be a number
	# in a file that changes nothing.
	expect(is_equal_approx(AudioServer.get_bus_volume_db(0), linear_to_db(0.5)),
		"applying sets the master bus to the chosen volume")

	m._vol_slider.value = 1.0
	_button(m, "ApplyButton").pressed.emit()

func _test_cancel_puts_the_controls_back() -> void:
	print("cancel")
	var m := _make()
	m._vol_slider.value = 0.2
	m._fs_check.button_pressed = true
	m._speed_spin.value = 500
	_button(m, "CancelButton").pressed.emit()
	expect(is_equal_approx(m._vol_slider.value, m._saved_vol), "cancel puts the slider back")
	expect(m._fs_check.button_pressed == m._saved_fs, "the checkbox back")
	expect(int(m._speed_spin.value) == m._saved_speed, "and the spinner back")
	expect(_status(m).contains("revert"), "and says the changes were dropped")

func _test_reset_returns_to_the_defaults() -> void:
	print("reset")
	var m := _make()
	m._vol_slider.value = 0.1
	m._speed_spin.value = 500
	_button(m, "ApplyButton").pressed.emit()
	_button(m, "ResetButton").pressed.emit()
	expect(is_equal_approx(m._saved_vol, 1.0), "reset returns the volume to full")
	expect(m._saved_speed == 200, "and the speed to its default")
	expect(not m._saved_fs, "and the window back to windowed")
	expect(not m._fs_check.button_pressed, "with the checkbox cleared")
	expect(is_equal_approx(m._vol_slider.value, 1.0), "with the controls following")
	expect(_status(m).contains("default"), "and says so")

func _test_reset_is_not_saved_until_applied() -> void:
	print("reset then restart")
	var m := _make()
	m._vol_slider.value = 0.6
	_button(m, "ApplyButton").pressed.emit()
	_button(m, "ResetButton").pressed.emit()

	# Reset changes the panel, not the file: a restart before applying should
	# still find the settings that were last saved.
	var restarted := _open()
	expect(is_equal_approx(restarted._saved_vol, 0.6),
		"an unapplied reset leaves the saved settings alone")

func _test_a_config_missing_a_key_falls_back_to_its_default() -> void:
	print("an incomplete config")
	_forget_saved_settings()
	# A config written by an older version of the game will be missing whatever
	# was added since. Each setting needs a sane fallback, not whatever the
	# missing value reads as.
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "volume", 0.7)
	cfg.save("user://settings.cfg")

	var m := _open()
	expect(is_equal_approx(m._saved_vol, 0.7), "the setting that is there is loaded")
	expect(not m._saved_fs, "and a missing fullscreen flag defaults to windowed")
	expect(m._saved_speed == 200, "with a missing speed defaulting too")
