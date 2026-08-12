@tool
## The dock's UI. A dock is just a Control that the plugin parks in one of the
## editor's slots, so everything you know about building UI still applies.
##
## It talks to the editor through EditorInterface rather than reaching into the
## scene tree directly — that is what makes "add a node to whatever scene is
## open" work, and what makes the action land in the editor's undo history.
extends VBoxContainer

@onready var _points_label: Label = $PointsLabel
@onready var _skip_label: Label = $SkipLabel
@onready var _points_slider: HSlider = $PointsSlider
@onready var _skip_slider: HSlider = $SkipSlider
@onready var _spawn_button: Button = $SpawnButton

func _ready() -> void:
	_points_slider.value_changed.connect(func(_v: float) -> void: _refresh())
	_skip_slider.value_changed.connect(func(_v: float) -> void: _refresh())
	_spawn_button.pressed.connect(_spawn)
	_refresh()

func _refresh() -> void:
	_points_label.text = "Points: %d" % int(_points_slider.value)
	_skip_label.text = "Skip: %d" % int(_skip_slider.value)

func _spawn() -> void:
	# Only meaningful inside the editor; guard so a runtime instance is inert.
	if not Engine.is_editor_hint():
		return
	var root := EditorInterface.get_edited_scene_root()
	if root == null:
		push_warning("Ring Tools: no scene is open")
		return

	var spawner := Node2D.new()
	spawner.set_script(load("res://addons/ring_tools/ring_spawner.gd"))
	spawner.name = "RingSpawner"
	spawner.points = int(_points_slider.value)
	spawner.skip = int(_skip_slider.value)
	root.add_child(spawner)
	# Without setting the owner the node is invisible in the Scene dock and is
	# not saved with the scene — the single most common custom-tooling mistake.
	spawner.owner = root
