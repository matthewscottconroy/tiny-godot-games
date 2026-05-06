extends Control

@onready var _vol_slider:    HSlider       = $Panel/VBox/VolumeRow/VolumeSlider
@onready var _vol_label:     Label         = $Panel/VBox/VolumeRow/VolumeValueLabel
@onready var _fs_check:      CheckButton   = $Panel/VBox/FullscreenRow/FSCheck
@onready var _speed_spin:    SpinBox       = $Panel/VBox/SpeedRow/SpeedSpin
@onready var _status:        Label         = $Panel/VBox/StatusLabel

const CONFIG_PATH := "user://settings.cfg"

var _saved_vol:   float = 1.0
var _saved_fs:    bool  = false
var _saved_speed: int   = 200

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_load_config()
	_apply_to_ui()
	# Connect signals
	_vol_slider.value_changed.connect(_on_vol_changed)
	$Panel/VBox/ButtonRow/ApplyButton.pressed.connect(_on_apply)
	$Panel/VBox/ButtonRow/CancelButton.pressed.connect(_on_cancel)
	$Panel/VBox/ButtonRow/ResetButton.pressed.connect(_on_reset)

func _load_config() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) == OK:
		_saved_vol   = cfg.get_value("audio",    "volume",     1.0)
		_saved_fs    = cfg.get_value("display",  "fullscreen", false)
		_saved_speed = cfg.get_value("gameplay", "speed",      200)

func _apply_to_ui() -> void:
	_vol_slider.value        = _saved_vol
	_vol_label.text          = "%.0f%%" % (100.0 * _saved_vol)
	_fs_check.button_pressed = _saved_fs
	_speed_spin.value        = _saved_speed

func _on_vol_changed(v: float) -> void:
	_vol_label.text = "%.0f%%" % (100.0 * v)

func _on_apply() -> void:
	_saved_vol   = _vol_slider.value
	_saved_fs    = _fs_check.button_pressed
	_saved_speed = int(_speed_spin.value)

	var cfg := ConfigFile.new()
	cfg.set_value("audio",    "volume",     _saved_vol)
	cfg.set_value("display",  "fullscreen", _saved_fs)
	cfg.set_value("gameplay", "speed",      _saved_speed)
	cfg.save(CONFIG_PATH)

	AudioServer.set_bus_volume_db(0, linear_to_db(_saved_vol))

	if _saved_fs:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	_status.text = "Settings saved!"

func _on_cancel() -> void:
	_apply_to_ui()
	_status.text = "Changes reverted."

func _on_reset() -> void:
	_saved_vol   = 1.0
	_saved_fs    = false
	_saved_speed = 200
	_apply_to_ui()
	_status.text = "Reset to defaults."
