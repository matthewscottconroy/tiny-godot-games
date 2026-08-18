extends Node

# Drives the real emitter from scenes/main.tscn — see docs/TEST_INTEGRITY.md.
#
# The particles are the engine's; what this checks is that each preset
# configures the emitter into a state that produces the effect it names, and
# that switching presets leaves nothing behind from the last one.

var _pass := 0
var _fail := 0

func _ready() -> void:
	_test_it_starts_on_fire()
	_test_every_preset_emits()
	_test_every_preset_is_a_complete_setup()
	_test_the_looping_presets_loop()
	_test_the_explosion_is_a_one_shot()
	_test_switching_back_clears_the_one_shot()
	_test_fire_rises_and_smoke_drifts()
	_test_sparkle_goes_everywhere()
	_test_stop_stops()
	_test_the_readout_names_the_mode()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[particle-effects] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

var _scene: Node2D

func _make() -> Node2D:
	if is_instance_valid(_scene):
		remove_child(_scene)
		_scene.free()
	_scene = load("res://scenes/main.tscn").instantiate()
	add_child(_scene)
	return _scene

func _press(m: Node2D, name: String) -> void:
	(m.get_node("Buttons/" + name) as Button).pressed.emit()

func _particles(m: Node2D) -> CPUParticles2D:
	return m.get_node("Particles")

const PRESETS := ["FireBtn", "SmokeBtn", "SparkleBtn", "ExplosionBtn"]

func _test_it_starts_on_fire() -> void:
	print("on open")
	var m := _make()
	expect(_particles(m).emitting, "the demo is already emitting when it opens")
	expect((m.get_node("ModeLabel") as Label).text.contains("Fire"), "on the fire preset")

func _test_every_preset_emits() -> void:
	print("the presets")
	begin_quiet()
	for name in PRESETS:
		var m := _make()
		_press(m, name)
		expect_quiet(_particles(m).emitting, "%s does not start the emitter" % name)
	expect(_quiet_failures == 0, "every preset starts the emitter")

func _test_every_preset_is_a_complete_setup() -> void:
	print("complete setups")
	# Each preset sets every property rather than relying on what the last one
	# left — otherwise the effect you get depends on the button you pressed
	# before it.
	begin_quiet()
	for name in PRESETS:
		var m := _make()
		_press(m, name)
		var p := _particles(m)
		expect_quiet(p.amount > 0, "%s emits no particles" % name)
		expect_quiet(p.lifetime > 0.0, "%s gives them no lifetime" % name)
		expect_quiet(p.initial_velocity_max >= p.initial_velocity_min,
			"%s has its velocity range the wrong way round" % name)
		expect_quiet(p.scale_amount_max >= p.scale_amount_min,
			"%s has its scale range the wrong way round" % name)
		expect_quiet(p.scale_amount_min > 0.0, "%s emits particles of no size" % name)
	expect(_quiet_failures == 0, "every preset leaves the emitter fully configured")

func _test_the_looping_presets_loop() -> void:
	print("looping")
	begin_quiet()
	for name in ["FireBtn", "SmokeBtn", "SparkleBtn"]:
		var m := _make()
		_press(m, name)
		expect_quiet(not _particles(m).one_shot, "%s should keep going, not fire once" % name)
	expect(_quiet_failures == 0, "the three continuous effects loop")

func _test_the_explosion_is_a_one_shot() -> void:
	print("the explosion")
	var m := _make()
	_press(m, "ExplosionBtn")
	var p := _particles(m)
	expect(p.one_shot, "an explosion fires once rather than looping")
	expect(p.spread > 90.0, "throwing particles in every direction")
	expect(p.gravity.y > 0.0, "and letting them fall afterwards")

func _test_switching_back_clears_the_one_shot() -> void:
	print("after an explosion")
	var m := _make()
	_press(m, "ExplosionBtn")
	_press(m, "FireBtn")
	# A looping preset left in one-shot mode emits a single puff and stops.
	expect(not _particles(m).one_shot, "going back to a looping preset clears the one-shot flag")
	expect(_particles(m).emitting, "and starts it emitting again")

func _test_fire_rises_and_smoke_drifts() -> void:
	print("fire and smoke")
	var fire := _make()
	_press(fire, "FireBtn")
	var fire_p := _particles(fire)
	expect(fire_p.gravity.y < 0.0, "fire is pulled upwards")
	expect(fire_p.color.r > fire_p.color.b, "and is warm-coloured")

	var smoke := _make()
	_press(smoke, "SmokeBtn")
	var smoke_p := _particles(smoke)
	expect(smoke_p.lifetime > fire_p.lifetime, "smoke lingers longer than flame")
	expect(smoke_p.scale_amount_max > fire_p.scale_amount_max, "in bigger, softer puffs")
	expect(smoke_p.color.a < 1.0, "and is see-through")

func _test_sparkle_goes_everywhere() -> void:
	print("sparkle")
	var m := _make()
	_press(m, "SparkleBtn")
	var p := _particles(m)
	expect(p.spread > 90.0, "sparkles fly in every direction")
	expect(p.gravity.y > 0.0, "and fall back down")

func _test_stop_stops() -> void:
	print("stopping")
	var m := _make()
	_press(m, "StopBtn")
	expect(not _particles(m).emitting, "stop stops the emitter")
	expect((m.get_node("ModeLabel") as Label).text.contains("Stopped"), "and says so")

	_press(m, "FireBtn")
	expect(_particles(m).emitting, "and a preset starts it again")

func _test_the_readout_names_the_mode() -> void:
	print("the readout")
	var names := {}
	for name in PRESETS:
		var m := _make()
		_press(m, name)
		names[(m.get_node("ModeLabel") as Label).text] = true
	expect(names.size() == PRESETS.size(), "each preset names itself on screen")

var _quiet_failures := 0

## Zero the tally, so one test's failures cannot cascade into the next.
func begin_quiet() -> void:
	_quiet_failures = 0

func expect_quiet(cond: bool, label: String) -> void:
	if not cond:
		_quiet_failures += 1
		print("  (", label, " — failed)")
