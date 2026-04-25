extends Node2D

@onready var particles  : CPUParticles2D = $Particles
@onready var mode_label : Label          = $ModeLabel

func _ready() -> void:
	$Buttons/FireBtn.pressed.connect(_set_fire)
	$Buttons/SmokeBtn.pressed.connect(_set_smoke)
	$Buttons/SparkleBtn.pressed.connect(_set_sparkle)
	$Buttons/ExplosionBtn.pressed.connect(_burst)
	$Buttons/StopBtn.pressed.connect(func():
		particles.emitting = false
		mode_label.text = "Stopped")
	_set_fire()

func _set_fire() -> void:
	mode_label.text = "Mode: Fire (looping)"
	particles.one_shot            = false
	particles.amount              = 40
	particles.lifetime            = 0.9
	particles.direction           = Vector2(0, -1)
	particles.spread              = 22.0
	particles.gravity             = Vector2(0, -30)
	particles.initial_velocity_min = 60.0
	particles.initial_velocity_max = 120.0
	particles.scale_amount_min    = 4.0
	particles.scale_amount_max    = 8.0
	particles.color               = Color.ORANGE_RED
	particles.emitting            = true

func _set_smoke() -> void:
	mode_label.text = "Mode: Smoke (looping)"
	particles.one_shot            = false
	particles.amount              = 20
	particles.lifetime            = 2.5
	particles.direction           = Vector2(0, -1)
	particles.spread              = 40.0
	particles.gravity             = Vector2(5, -15)
	particles.initial_velocity_min = 15.0
	particles.initial_velocity_max = 40.0
	particles.scale_amount_min    = 8.0
	particles.scale_amount_max    = 16.0
	particles.color               = Color(0.55, 0.55, 0.55, 0.55)
	particles.emitting            = true

func _set_sparkle() -> void:
	mode_label.text = "Mode: Sparkle (looping)"
	particles.one_shot            = false
	particles.amount              = 60
	particles.lifetime            = 1.4
	particles.direction           = Vector2(0, -1)
	particles.spread              = 180.0
	particles.gravity             = Vector2(0, 80)
	particles.initial_velocity_min = 80.0
	particles.initial_velocity_max = 180.0
	particles.scale_amount_min    = 2.0
	particles.scale_amount_max    = 5.0
	particles.color               = Color.GOLD
	particles.emitting            = true

func _burst() -> void:
	mode_label.text = "Mode: Explosion (one-shot)"
	particles.one_shot            = true
	particles.amount              = 80
	particles.lifetime            = 0.7
	particles.direction           = Vector2(0, -1)
	particles.spread              = 180.0
	particles.gravity             = Vector2(0, 140)
	particles.initial_velocity_min = 160.0
	particles.initial_velocity_max = 320.0
	particles.scale_amount_min    = 3.0
	particles.scale_amount_max    = 8.0
	particles.color               = Color.ORANGE_RED
	particles.restart()
	particles.emitting            = true
