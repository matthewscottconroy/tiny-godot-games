extends Node2D

var hp       := 100
var frozen   := false
var vel      := Vector2.ZERO
var hp_label : Label

func _ready() -> void:
	add_to_group("enemies")
	vel = Vector2(randf_range(-70, 70), randf_range(-50, 50))
	hp_label = Label.new()
	hp_label.text = "HP: 100"
	hp_label.position = Vector2(-22, 20)
	hp_label.add_theme_font_size_override("font_size", 11)
	add_child(hp_label)

func flash() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE * 4, 0.05)
	tween.tween_property(self, "modulate", Color.WHITE, 0.25)

func freeze_toggle() -> void:
	frozen = !frozen
	modulate = Color(0.5, 0.85, 1.0) if frozen else Color.WHITE

func take_damage(amount: int) -> void:
	hp = max(0, hp - amount)
	if hp_label:
		hp_label.text = "HP: %d" % hp
	if hp <= 0:
		queue_free()

func _process(delta: float) -> void:
	if frozen:
		return
	position += vel * delta
	if position.x < 60 or position.x > 580:
		vel.x = -vel.x
		position.x = clamp(position.x, 60, 580)
	if position.y < 80 or position.y > 390:
		vel.y = -vel.y
		position.y = clamp(position.y, 80, 390)
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 18, Color.CORAL)
	draw_circle(Vector2(-6, -5), 4, Color.WHITE)
	draw_circle(Vector2( 6, -5), 4, Color.WHITE)
