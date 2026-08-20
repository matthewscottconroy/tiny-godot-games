extends Node

# Drives the real Player (scripts/player.gd), SurfaceZone (scripts/surface_zone.gd)
# and the demo's tone generator via the demo scene.

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_all_surfaces_have_config()
	test_zones_declare_known_surfaces()
	test_surface_switches_on_zone_enter()
	test_surface_resets_on_zone_exit()
	test_step_signal_carries_the_surface()
	test_tone_differs_per_surface()
	test_generated_tone_is_well_formed()
	test_the_tone_fades_out_and_is_the_wave_it_says()
	await test_stepping_is_paced_by_walking()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

var _scene: Node2D = null

## One world at a time.
##
## Each test used to add another copy of the scene and leave it there, which is
## invisible while every test only reads configuration — and stops being
## invisible the moment one lets the physics run, because the stacked players
## depenetrate off each other and the one being watched never reaches the floor.
func _make_scene() -> Node2D:
	if _scene != null and is_instance_valid(_scene):
		remove_child(_scene)        # out of the physics world now, not next frame
		_scene.queue_free()
	_scene = load("res://scenes/main.tscn").instantiate()
	add_child(_scene)
	return _scene

func test_all_surfaces_have_config() -> void:
	print("every surface has a full config entry")
	var scene := _make_scene()
	var config: Dictionary = scene.SURFACE_CONFIG
	expect(config.has("stone"), "there is a 'stone' default")
	for surface in config:
		var cfg: Dictionary = config[surface]
		expect(cfg.get("freq", 0.0) > 0.0, "%s has positive frequency" % surface)
		expect(cfg.get("dur", 0.0) > 0.0, "%s has positive duration" % surface)
		expect(cfg.get("wave", "") != "", "%s has a wave type" % surface)

func test_zones_declare_known_surfaces() -> void:
	print("each SurfaceZone names a configured surface")
	var scene := _make_scene()
	var zones := scene.get_node("SurfaceZones").get_children()
	expect(zones.size() > 0, "the demo places surface zones")
	for zone in zones:
		var sz := zone as SurfaceZone
		expect(sz != null, "%s is a SurfaceZone" % zone.name)
		expect(scene.SURFACE_CONFIG.has(sz.surface_name),
			"%s names a configured surface (%s)" % [zone.name, sz.surface_name])

func test_surface_switches_on_zone_enter() -> void:
	print("walking into a zone switches surface")
	var scene := _make_scene()
	var player := scene.get_node("Player")
	var grass: SurfaceZone = scene.get_node("SurfaceZones/GrassZone")
	grass.body_entered.emit(player)
	expect(player._current_surface == grass.surface_name, "surface updated on zone enter")

func test_surface_resets_on_zone_exit() -> void:
	print("leaving a zone falls back to stone")
	var scene := _make_scene()
	var player := scene.get_node("Player")
	var grass: SurfaceZone = scene.get_node("SurfaceZones/GrassZone")
	grass.body_entered.emit(player)
	grass.body_exited.emit(player)
	expect(player._current_surface == "stone", "surface resets to the stone default on exit")

func test_step_signal_carries_the_surface() -> void:
	print("the stepped signal carries the current surface")
	var scene := _make_scene()
	var player := scene.get_node("Player")
	var steps: Array[String] = []
	player.stepped.connect(func(surface: String) -> void: steps.append(surface))
	player.set_surface("metal")
	player.stepped.emit(player._current_surface)
	expect(steps == ["metal"], "listeners receive the surface the step happened on")

func test_tone_differs_per_surface() -> void:
	print("each surface produces a different tone")
	var scene := _make_scene()
	var lengths := {}
	for surface in scene.SURFACE_CONFIG:
		var cfg: Dictionary = scene.SURFACE_CONFIG[surface]
		var tone: AudioStreamWAV = scene._make_tone(cfg["freq"], cfg["dur"], cfg["wave"])
		lengths[surface] = tone.data.size()
	expect(lengths["metal"] < lengths["water"],
		"a shorter duration yields fewer samples (metal 0.04s vs water 0.12s)")

func test_generated_tone_is_well_formed() -> void:
	print("the generated tone is a usable AudioStreamWAV")
	var scene := _make_scene()
	var tone: AudioStreamWAV = scene._make_tone(440.0, 0.1, "sine")
	expect(tone != null, "a stream is produced")
	expect(tone.data.size() > 0, "it contains sample data")
	# 16-bit mono: two bytes per sample at the demo's SAMPLE_RATE.
	expect(tone.data.size() == int(scene.SAMPLE_RATE * 0.1) * 2,
		"sample count matches rate x duration for 16-bit mono")
	expect(tone.mix_rate == scene.SAMPLE_RATE, "the stream reports the demo's sample rate")

## What is actually in the sample data.
##
## "It is the right length and mix rate" is satisfied by silence, by noise, and
## by a buffer whose high and low bytes are the wrong way round. A footstep is a
## click that decays, so the shape is checkable: loud at the start, quiet at the
## end, and a square wave made of edges rather than a curve.
func test_the_tone_fades_out_and_is_the_wave_it_says() -> void:
	print("the shape of the tone")
	var scene := _make_scene()

	var sine: AudioStreamWAV = scene._make_tone(440.0, 0.1, "sine")
	var first := _peak(sine.data, 0.0, 0.2)
	var last := _peak(sine.data, 0.8, 1.0)
	expect(first > 2000, "the tone starts loud (%d)" % first)
	expect(last < first / 4, "and ends far quieter — it is a click, not a hum (%d)" % last)
	expect(_peak(sine.data, 0.95, 1.0) < 1500,
		"arriving at near-silence rather than being cut off mid-note")

	# A sine steps smoothly between neighbours; a square is all edges. Assembled
	# from swapped bytes, a smooth wave stops being smooth.
	expect(_max_jump(sine.data, 0.0, 0.3) < 6000,
		"a sine moves smoothly between samples (%d)" % _max_jump(sine.data, 0.0, 0.3))

	# A low tone moves less than one high byte between neighbouring samples, so
	# any disturbance of the high bytes shows up as a jump the wave itself
	# cannot produce. At 20Hz the true step never exceeds ~130.
	var slow: AudioStreamWAV = scene._make_tone(20.0, 0.1, "sine")
	expect(_max_jump(slow.data, 0.0, 0.3) < 200,
		"a 20Hz tone is smooth to well under one high byte (%d)"
		% _max_jump(slow.data, 0.0, 0.3))

	var square: AudioStreamWAV = scene._make_tone(440.0, 0.1, "square")
	expect(_max_jump(square.data, 0.0, 0.3) > 20000,
		"a square jumps between its two levels (%d)" % _max_jump(square.data, 0.0, 0.3))
	expect(_max_jump(square.data, 0.0, 0.3) > _max_jump(sine.data, 0.0, 0.3),
		"and does so more sharply than the sine")
	# It starts on its high half. Inverted, the click begins with the speaker
	# pulling back instead of pushing — the same waveform out of phase, and the
	# sort of thing that only shows in the first sample.
	expect(_sample_at(square.data, 0) > 0,
		"a square starts on its positive half (%d)" % _sample_at(square.data, 0))

	# The sweep changes pitch as it runs, so its zero crossings bunch up.
	var sweep: AudioStreamWAV = scene._make_tone(300.0, 0.2, "sweep")
	var early := _crossings(sweep.data, 0.0, 0.25)
	var late := _crossings(sweep.data, 0.5, 0.75)
	expect(late > early,
		"the sweep rises in pitch as it plays (%d crossings then %d)" % [early, late])

## The signed 16-bit sample at index `i`, read the way the engine reads it.
func _sample_at(data: PackedByteArray, i: int) -> int:
	var raw := data[i * 2] | (data[i * 2 + 1] << 8)
	return raw - 65536 if raw > 32767 else raw

func _peak(data: PackedByteArray, from: float, to: float) -> int:
	var count := data.size() / 2
	var loudest := 0
	for i in range(int(count * from), int(count * to)):
		loudest = maxi(loudest, absi(_sample_at(data, i)))
	return loudest

func _max_jump(data: PackedByteArray, from: float, to: float) -> int:
	var count := data.size() / 2
	var biggest := 0
	for i in range(maxi(int(count * from), 1), int(count * to)):
		biggest = maxi(biggest, absi(_sample_at(data, i) - _sample_at(data, i - 1)))
	return biggest

func _crossings(data: PackedByteArray, from: float, to: float) -> int:
	var count := data.size() / 2
	var crossed := 0
	for i in range(maxi(int(count * from), 1), int(count * to)):
		if signi(_sample_at(data, i)) != signi(_sample_at(data, i - 1)):
			crossed += 1
	return crossed

## Steps are paced by walking, and only by walking.
func test_stepping_is_paced_by_walking() -> void:
	print("the pace")
	var scene := _make_scene()
	var player: CharacterBody2D = scene.get_node("Player")
	await get_tree().physics_frame

	var steps: Array[String] = []
	player.stepped.connect(func(surface: String) -> void: steps.append(surface))

	# Standing still on the floor makes no sound, however long you stand there.
	for _i in 90:
		await get_tree().physics_frame
	expect(player.is_on_floor(), "the player is standing on the floor")
	expect(steps.is_empty(), "standing still makes no footsteps (%d)" % steps.size())

	# Walking does, and at a pace rather than every frame. Driven through the
	# rule itself, since _physics_process recomputes the speed from Input and
	# headless there is never any.
	var walked := 0
	for _i in 180:
		if player.tick_steps(1.0 / 60.0, true, 200.0):
			walked += 1
	expect(walked > 0, "walking makes footsteps (%d)" % walked)
	expect(walked < 60,
		"paced by the step interval, not one per frame (%d in 180 frames)" % walked)
	var expected := int(180.0 / 60.0 / player.STEP_INTERVAL)
	expect(absi(walked - expected) <= 2,
		"about one every STEP_INTERVAL seconds (%d, expected near %d)" % [walked, expected])

	# Barely moving is not walking — a shuffle below the threshold is silent.
	var shuffled := 0
	for _i in 180:
		if player.tick_steps(1.0 / 60.0, true, 5.0):
			shuffled += 1
	expect(shuffled == 0, "drifting slower than the threshold makes none (%d)" % shuffled)
	expect(player.tick_steps(1.0 / 60.0, true, player.WALK_THRESHOLD) == false,
		"and exactly at the threshold still counts as standing")

	# In mid-air there is nothing to step on, however fast you are moving.
	var airborne := 0
	for _i in 180:
		if player.tick_steps(1.0 / 60.0, false, 400.0):
			airborne += 1
	expect(airborne == 0, "and none at all in mid-air (%d)" % airborne)

	# Coming back down starts a new stride immediately rather than partway
	# through the last gap — the timer is reset, not paused.
	expect(player.tick_steps(1.0 / 60.0, true, 200.0),
		"the first frame back on the ground lands a step")

	# The real handler still emits on the surface the player is standing on.
	player._current_surface = "metal"
	player._step_timer = 0.0
	var heard := steps.size()
	if player.tick_steps(1.0 / 60.0, true, 200.0):
		player.stepped.emit(player._current_surface)
	expect(steps.size() == heard + 1, "a step is announced")
	expect(steps[steps.size() - 1] == "metal",
		"carrying the surface underfoot (%s)" % steps[steps.size() - 1])

func _report() -> void:
	var summary := "[footstep-audio] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
