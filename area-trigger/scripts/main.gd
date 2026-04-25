extends Node2D

@onready var status_label: Label = $StatusLabel

func _ready() -> void:
	$Zones/SafeZone.body_entered.connect(func(_b): _set_status("SAFE ZONE", Color.SEA_GREEN))
	$Zones/SafeZone.body_exited.connect(func(_b): _set_status("—", Color.WHITE))
	$Zones/DangerZone.body_entered.connect(func(_b): _set_status("DANGER ZONE!", Color.TOMATO))
	$Zones/DangerZone.body_exited.connect(func(_b): _set_status("—", Color.WHITE))
	$Zones/WinZone.body_entered.connect(func(_b): _set_status("WIN ZONE!", Color.GOLD))
	$Zones/WinZone.body_exited.connect(func(_b): _set_status("—", Color.WHITE))
	_set_status("—", Color.WHITE)

func _set_status(text: String, color: Color) -> void:
	status_label.text = "Zone: " + text
	status_label.modulate = color

func _draw() -> void:
	draw_rect(Rect2(30, 250, 160, 190), Color(0.2, 0.75, 0.3, 0.25))
	draw_rect(Rect2(30, 250, 160, 190), Color.SEA_GREEN, false, 2)
	draw_rect(Rect2(450, 250, 160, 190), Color(0.85, 0.2, 0.2, 0.25))
	draw_rect(Rect2(450, 250, 160, 190), Color.TOMATO, false, 2)
	draw_rect(Rect2(220, 60, 200, 150), Color(0.9, 0.75, 0.1, 0.25))
	draw_rect(Rect2(220, 60, 200, 150), Color.GOLD, false, 2)
