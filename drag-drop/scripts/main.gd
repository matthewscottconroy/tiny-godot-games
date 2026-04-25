extends Node2D

var filled := 0

@onready var status_label : Label = $StatusLabel

func _ready() -> void:
	var colors := [Color.TOMATO, Color.CORNFLOWER_BLUE, Color.GOLD]
	var items := $Items.get_children()
	for i in items.size():
		items[i].item_color = colors[i % colors.size()]

func on_drop() -> void:
	filled += 1
	status_label.text = "Filled: %d / %d" % [filled, $Zones.get_child_count()]
	if filled == $Zones.get_child_count():
		status_label.text += "  — All slots filled!"
