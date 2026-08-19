extends CanvasLayer
# Global autoload that handles scene changes with a fade.

var _transitioning := false

## How the scene actually changes. Replaceable so a test can drive a whole
## transition — the guard, the fade out, the fade back in and the flag being
## released — without the scene it is running in being swapped out from under
## it. In the demo this is exactly `get_tree().change_scene_to_file`.
var change_scene: Callable = func(path: String) -> void:
	get_tree().change_scene_to_file(path)

@onready var rect : ColorRect = $FadeRect

func _ready() -> void:
	rect.color      = Color(0, 0, 0, 0)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer           = 128   # on top of everything

func fade_to(path: String) -> void:
	if _transitioning:
		return
	_transitioning = true
	rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.tween_property(rect, "color:a", 1.0, 0.4)
	await tw.finished
	change_scene.call(path)
	# Fade back in after scene loads (next frame)
	await get_tree().process_frame
	await get_tree().process_frame
	var tw2 := create_tween()
	tw2.tween_property(rect, "color:a", 0.0, 0.4)
	await tw2.finished
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transitioning = false
