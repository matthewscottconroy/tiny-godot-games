class_name EventBus

## A simple typed publish/subscribe event bus.
## Events are identified by string keys and carry data as Dictionaries.
## Multiple subscribers can listen to the same event type independently.

var _listeners: Dictionary = {}


## Subscribe callback to an event type.
func on(event_type: String, callback: Callable) -> void:
	if not _listeners.has(event_type):
		_listeners[event_type] = []
	_listeners[event_type].append(callback)


## Unsubscribe a specific callback from an event type.
func off(event_type: String, callback: Callable) -> void:
	if _listeners.has(event_type):
		_listeners[event_type].erase(callback)


## Emit an event, invoking all subscribers with the provided data dictionary.
func emit(event_type: String, data: Dictionary = {}) -> void:
	if _listeners.has(event_type):
		for cb: Callable in _listeners[event_type]:
			cb.call(data)
