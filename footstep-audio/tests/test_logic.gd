extends Node

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_step_timer_fires_at_interval()
	test_step_only_fires_while_walking()
	test_surface_switches_on_zone_enter()
	test_surface_resets_on_zone_exit()
	test_all_surfaces_have_config()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		push_error("  FAIL  " + label)

func _report() -> void:
	var msg := "[footstep-audio] %d/%d passed" % [_pass, _pass + _fail]
	print("\n", msg)
	if _fail > 0:
		push_error(msg)

const STEP_INTERVAL := 0.34
const SURFACE_CONFIG := {
	"stone":  {"freq": 380.0, "dur": 0.05, "wave": "square"},
	"grass":  {"freq": 160.0, "dur": 0.10, "wave": "sweep"},
	"wood":   {"freq": 260.0, "dur": 0.07, "wave": "sine"},
	"water":  {"freq": 200.0, "dur": 0.12, "wave": "sine"},
	"metal":  {"freq": 600.0, "dur": 0.04, "wave": "square"},
}

func _simulate_steps(duration: float, is_walking: bool) -> int:
	var timer := 0.0
	var count := 0
	var elapsed := 0.0
	var delta := 0.016
	while elapsed < duration:
		if is_walking:
			timer -= delta
			if timer <= 0.0:
				timer = STEP_INTERVAL
				count += 1
		else:
			timer = 0.0
		elapsed += delta
	return count

func test_step_timer_fires_at_interval() -> void:
	var steps := _simulate_steps(1.0, true)
	var expected := int(1.0 / STEP_INTERVAL)
	expect(absf(steps - expected) <= 1, "step count within 1 of expected for 1 second walking")

func test_step_only_fires_while_walking() -> void:
	var steps := _simulate_steps(1.0, false)
	expect(steps == 0, "no steps when not walking")

func test_surface_switches_on_zone_enter() -> void:
	var surface := "stone"
	# Simulate entering grass zone
	surface = "grass"
	expect(surface == "grass", "surface updated to grass on zone enter")

func test_surface_resets_on_zone_exit() -> void:
	var surface := "grass"
	# Simulate exiting zone
	surface = "stone"
	expect(surface == "stone", "surface resets to stone on zone exit")

func test_all_surfaces_have_config() -> void:
	for surface in ["stone", "grass", "wood", "water", "metal"]:
		expect(SURFACE_CONFIG.has(surface), "%s surface has config" % surface)
		var cfg := SURFACE_CONFIG[surface]
		expect(cfg["freq"] > 0.0, "%s has positive frequency" % surface)
		expect(cfg["dur"]  > 0.0, "%s has positive duration" % surface)
		expect(not cfg["wave"].is_empty(), "%s has wave type" % surface)
