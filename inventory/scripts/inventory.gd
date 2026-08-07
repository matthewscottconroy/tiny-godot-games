## A fixed-size slot inventory. Each slot holds an item (any Variant — this demo
## uses dictionaries) or null. Handles place / take / swap by index and emits
## `changed` so a UI can refresh. It knows nothing about buttons or drawing.
class_name Inventory
extends RefCounted

signal changed

var slots: Array = []   # each element is an item, or null for empty

func _init(slot_count: int = 0) -> void:
	slots.resize(slot_count)   # resize fills new entries with null

func size() -> int:
	return slots.size()

func get_item(index: int) -> Variant:
	return slots[index]

func is_empty(index: int) -> bool:
	return slots[index] == null

## Place `item` into an empty slot. Returns false if the slot is occupied.
func place(index: int, item) -> bool:
	if slots[index] != null:
		return false
	slots[index] = item
	changed.emit()
	return true

## Remove and return the item in `index` (or null if empty).
func take(index: int) -> Variant:
	var item = slots[index]
	slots[index] = null
	if item != null:
		changed.emit()
	return item

## Put `item` into `index` and return whatever was there (a swap).
func swap(index: int, item) -> Variant:
	var prev = slots[index]
	slots[index] = item
	changed.emit()
	return prev
