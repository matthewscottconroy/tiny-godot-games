extends CharacterBody2D

# Collision layer assignments (bitmask):
#   Layer 1 (value 1): World/walls
#   Layer 2 (value 2): Character bodies
#   Layer 3 (value 4): Hitboxes
#   Layer 4 (value 8): Hurtboxes

const SPEED := 160.0

var health := 3
var attack_cooldown := 0.0

@onready var hitbox: Area2D = $Hitbox
@onready var health_label: Label = $HealthLabel

func _ready() -> void:
	$Hurtbox.add_to_group("hurtbox")
	hitbox.monitoring = false
	hitbox.area_entered.connect(_on_hitbox_area_entered)
	$Hurtbox.area_entered.connect(_on_hurtbox_area_entered)

func _draw() -> void:
	draw_rect(Rect2(-14, -24, 28, 48), Color.CORNFLOWER_BLUE)
	draw_rect(Rect2(-7, -20, 5, 5), Color.WHITE)
	draw_rect(Rect2(2, -20, 5, 5), Color.WHITE)
	# Show attack range when hitbox active
	if hitbox.monitoring:
		draw_rect(Rect2(14, -16, 28, 32), Color(1, 1, 0, 0.35))

func _physics_process(delta: float) -> void:
	velocity = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") * SPEED
	move_and_slide()
	attack_cooldown = max(0.0, attack_cooldown - delta)
	if Input.is_action_just_pressed("ui_accept") and attack_cooldown == 0.0:
		_attack()
	queue_redraw()

func _attack() -> void:
	hitbox.monitoring = true
	attack_cooldown = 0.6
	get_tree().create_timer(0.15).timeout.connect(func(): hitbox.monitoring = false; queue_redraw())

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("hurtbox"):
		area.get_parent().take_damage(1)

func _on_hurtbox_area_entered(_area: Area2D) -> void:
	take_damage(1)

func take_damage(amount: int) -> void:
	health -= amount
	health_label.text = "❤ %d" % max(health, 0)
	modulate = Color.RED
	get_tree().create_timer(0.15).timeout.connect(func(): modulate = Color.WHITE)
	if health <= 0:
		health_label.text = "Player KO!"
