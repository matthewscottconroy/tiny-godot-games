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
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _make_scene() -> Node2D:
	var scene: Node2D = load("res://scenes/main.tscn").instantiate()
	add_child(scene)
	return scene

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

func _report() -> void:
	var summary := "[footstep-audio] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
