@tool
## The plugin entry point. Godot instantiates this once when the plugin is
## enabled in Project Settings → Plugins, and frees it when it is disabled.
##
## The rule that catches everyone: whatever you add in `_enter_tree()` you must
## remove in `_exit_tree()`. Godot does not clean up docks, custom types, or
## menu items for you, so a plugin that forgets leaves duplicates behind every
## time it is reloaded — and plugins reload constantly while you develop them.
extends EditorPlugin

const DOCK_SCENE := preload("res://addons/ring_tools/ring_dock.tscn")
const SPAWNER_SCRIPT := preload("res://addons/ring_tools/ring_spawner.gd")
const SPAWNER_ICON := preload("res://icon.svg")

var _dock: Control

func _enter_tree() -> void:
	_dock = DOCK_SCENE.instantiate()
	add_control_to_dock(DOCK_SLOT_LEFT_UR, _dock)

	# Registers a node type that appears in the Add Node dialog like a built-in.
	add_custom_type("RingSpawner", "Node2D", SPAWNER_SCRIPT, SPAWNER_ICON)

func _exit_tree() -> void:
	# Symmetric teardown. Skipping either of these leaves a stale dock or a
	# phantom node type behind after the plugin is disabled.
	remove_custom_type("RingSpawner")
	if is_instance_valid(_dock):
		remove_control_from_docks(_dock)
		_dock.queue_free()
	_dock = null

func _get_plugin_name() -> String:
	return "Ring Tools"
