class_name DropTable
extends RefCounted

var _entries: Array[Dictionary] = []

func add(item: String, weight: float) -> DropTable:
	_entries.append({"item": item, "weight": weight})
	return self

func roll() -> String:
	if _entries.is_empty():
		return ""
	var total := 0.0
	for e in _entries:
		total += e["weight"]
	var r := randf() * total
	var acc := 0.0
	for e in _entries:
		acc += e["weight"]
		if r <= acc:
			return e["item"]
	return _entries[-1]["item"]

func get_chances() -> Dictionary:
	var total := 0.0
	for e in _entries:
		total += e["weight"]
	var out := {}
	for e in _entries:
		out[e["item"]] = e["weight"] / total
	return out
