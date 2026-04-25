extends CharacterBody2D

var health := 5
var attack_timer := 0.0
const ATTACK_INTERVAL := 2.2

@onready var hitbox: Area2D = $Hitbox
@onready var health_label: Label = $HealthLabel

func _ready() -> void:
	$Hurtbox.add_to_group("hurtbox")
	hitbox.monitoring = false
	hitbox.area_entered.connect(_on_hitbox_area_entered)
	$Hurtbox.area_entered.connect(_on_hurtbox_area_entered)

func _draw() -> void:
	draw_rect(Rect2(-16, -24, 32, 48), Color.TOMATO)
	draw_rect(Rect2(-8, -20, 6, 6), Color.WHITE)
	draw_rect(Rect2(2, -20, 6, 6), Color.WHITE)
	if hitbox.monitoring:
		draw_rect(Rect2(-44, -16, 28, 32), Color(1, 0.5, 0, 0.4))

func _process(delta: float) -> void:
	attack_timer += delta
	if attack_timer >= ATTACK_INTERVAL:
		attack_timer = 0.0
		_swing()
	queue_redraw()

func _swing() -> void:
	hitbox.monitoring = true
	get_tree().create_timer(0.2).timeout.connect(func(): hitbox.monitoring = false; queue_redraw())

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("hurtbox"):
		area.get_parent().take_damage(1)

func _on_hurtbox_area_entered(_area: Area2D) -> void:
	take_damage(1)

func take_damage(amount: int) -> void:
	health -= amount
	health_label.text = "❤ %d" % max(health, 0)
	modulate = Color.RED
	get_tree().create_timer(0.1).timeout.connect(func(): modulate = Color.WHITE)
	if health <= 0:
		health_label.text = "Enemy KO!"
