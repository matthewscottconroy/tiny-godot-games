extends Node2D

@onready var _player: CharacterBody2D = $Player

func _ready() -> void:
	for zone_name in ["PoisonZone", "BurnZone", "FreezeZone"]:
		var zone: Area2D = get_node(zone_name)
		var effect_name: String = zone.get_meta("effect")
		zone.body_entered.connect(_on_zone_entered.bind(effect_name))

func _on_zone_entered(body: Node2D, effect_name: String) -> void:
	if body.has_method("apply_effect"):
		body.apply_effect(effect_name)

func _draw() -> void:
	draw_rect(Rect2(0, 455, 640, 25), Color(0.30, 0.30, 0.35))
	draw_rect(Rect2(160, 395, 130, 65), Color(0.15, 0.70, 0.15, 0.30))
	draw_rect(Rect2(305, 395, 130, 65), Color(0.85, 0.25, 0.10, 0.30))
	draw_rect(Rect2(450, 395, 130, 65), Color(0.20, 0.55, 1.00, 0.30))
	draw_string(ThemeDB.fallback_font, Vector2(200, 392), "POISON", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.4, 1.0, 0.4))
	draw_string(ThemeDB.fallback_font, Vector2(342, 392), "BURN", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.5, 0.2))
	draw_string(ThemeDB.fallback_font, Vector2(494, 392), "FREEZE", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.4, 0.8, 1.0))
