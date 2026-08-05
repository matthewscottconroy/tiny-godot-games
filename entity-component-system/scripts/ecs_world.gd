class_name ECSWorld

var _next_id  := 0
var _components: Dictionary = {}  # type -> {entity_id -> data}

func create_entity() -> int:
	var id := _next_id
	_next_id += 1
	return id

func add_component(entity: int, type: StringName, data: Dictionary) -> void:
	if not _components.has(type):
		_components[type] = {}
	_components[type][entity] = data

func get_component(entity: int, type: StringName) -> Dictionary:
	if _components.has(type) and _components[type].has(entity):
		return _components[type][entity]
	return {}

func has_component(entity: int, type: StringName) -> bool:
	return _components.has(type) and _components[type].has(entity)

func remove_component(entity: int, type: StringName) -> void:
	if _components.has(type):
		_components[type].erase(entity)

func query(types: Array) -> Array:
	if types.is_empty():
		return []
	var first: StringName = types[0]
	if not _components.has(first):
		return []
	var result: Array = []
	for entity in _components[first].keys():
		var has_all := true
		for t in types:
			if not has_component(entity, t):
				has_all = false
				break
		if has_all:
			result.append(entity)
	return result
