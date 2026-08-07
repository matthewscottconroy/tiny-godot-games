## A type registry that decouples entity creation from calling code: register a
## builder `Callable` under a name, then `create(name)` without the caller
## knowing how each type is constructed. Add new types without touching spawners.
class_name EntityFactory
extends RefCounted

var _registry: Dictionary = {}

func register(type_name: StringName, builder: Callable) -> void:
	_registry[type_name] = builder

func create(type_name: StringName, params: Dictionary = {}) -> Dictionary:
	if not _registry.has(type_name):
		push_warning("EntityFactory: unknown type '%s'" % type_name)
		return {}
	return _registry[type_name].call(params)

func has_type(type_name: StringName) -> bool:
	return _registry.has(type_name)

func registered_types() -> Array:
	return _registry.keys()
