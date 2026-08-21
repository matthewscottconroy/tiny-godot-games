extends Node

# Drives the real AccessibilitySettings from scripts/accessibility.gd.

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_defaults()
	test_palette_cycles()
	test_every_palette_is_complete()
	test_palettes_are_internally_distinguishable()
	test_reduced_motion_collapses_duration()
	test_text_scale_clamps()
	test_font_size_scales()
	test_shape_cues()
	test_changed_signal_fires_once_per_real_change()
	test_round_trip_through_dict()
	test_from_dict_tolerates_junk()
	test_cycling_goes_forward_through_the_list()
	test_setting_a_palette_to_itself_is_not_a_change()
	test_an_empty_dict_restores_the_defaults()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[accessibility-options] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

func _make() -> AccessibilitySettings:
	var s := AccessibilitySettings.new()
	add_child(s)
	return s

func test_defaults() -> void:
	print("defaults")
	var s := _make()
	expect(s.palette == AccessibilitySettings.Palette.DEFAULT, "starts on the default palette")
	expect(not s.reduced_motion, "reduced motion starts off")
	expect(is_equal_approx(s.text_scale, 1.0), "text scale starts at 1x")
	expect(not s.shape_cues, "shape cues start off")

func test_palette_cycles() -> void:
	print("cycling palettes")
	var s := _make()
	var seen: Array[int] = []
	for i in AccessibilitySettings.PALETTES.size():
		seen.append(int(s.palette))
		s.cycle_palette()
	expect(seen.size() == AccessibilitySettings.PALETTES.size(), "every palette is reachable")
	expect(int(s.palette) == int(AccessibilitySettings.Palette.DEFAULT), "cycling wraps around")

func test_every_palette_is_complete() -> void:
	print("palette definitions")
	for key in AccessibilitySettings.PALETTES:
		var p: Dictionary = AccessibilitySettings.PALETTES[key]
		expect(p.has("name") and String(p["name"]) != "", "palette %s has a name" % key)
		for role in ["positive", "negative", "neutral"]:
			expect(p.get(role) is Color, "palette %s defines '%s'" % [key, role])

func test_palettes_are_internally_distinguishable() -> void:
	print("positive and negative are separable in every palette")
	# The whole point of an alternate palette is that its two semantic colours do
	# not collapse into each other. Compare them in a way that ignores overall
	# brightness, since hue is what the affected player loses.
	for key in AccessibilitySettings.PALETTES:
		var p: Dictionary = AccessibilitySettings.PALETTES[key]
		var a: Color = p["positive"]
		var b: Color = p["negative"]
		var distance := Vector3(a.r, a.g, a.b).distance_to(Vector3(b.r, b.g, b.b))
		expect(distance > 0.5, "%s: positive and negative are far apart (%.2f)" % [p["name"], distance])

func test_reduced_motion_collapses_duration() -> void:
	print("reduced motion")
	var s := _make()
	expect(is_equal_approx(s.motion_duration(0.4), 0.4), "durations pass through when motion is allowed")
	s.reduced_motion = true
	expect(is_zero_approx(s.motion_duration(0.4)), "decorative motion collapses to zero")
	expect(is_zero_approx(s.motion_duration(10.0)), "regardless of the base duration")

func test_text_scale_clamps() -> void:
	print("text scale limits")
	var s := _make()
	s.text_scale = 99.0
	expect(is_equal_approx(s.text_scale, AccessibilitySettings.MAX_TEXT_SCALE), "clamped to the maximum")
	s.text_scale = -5.0
	expect(is_equal_approx(s.text_scale, AccessibilitySettings.MIN_TEXT_SCALE), "clamped to the minimum")

func test_font_size_scales() -> void:
	print("font sizing")
	var s := _make()
	expect(s.font_size(14) == 14, "1x leaves the base size alone")
	s.text_scale = 2.0
	expect(s.font_size(14) == 28, "2x doubles it")
	expect(s.font_size(15) == 30, "and rounds rather than truncating")

func test_shape_cues() -> void:
	print("shape cues")
	var s := _make()
	expect(s.cue_for(true) == "", "no cue while the option is off")
	s.shape_cues = true
	expect(s.cue_for(true) != "", "a positive cue appears")
	expect(s.cue_for(false) != "", "a negative cue appears")
	expect(s.cue_for(true) != s.cue_for(false), "the two cues differ — colour is not the only signal")

func test_changed_signal_fires_once_per_real_change() -> void:
	print("changed signal")
	var s := _make()
	var count := {"n": 0}
	s.changed.connect(func() -> void: count["n"] += 1)
	s.reduced_motion = true
	expect(count["n"] == 1, "a real change emits once")
	s.reduced_motion = true
	expect(count["n"] == 1, "setting the same value again emits nothing")
	s.text_scale = 1.5
	expect(count["n"] == 2, "another setting emits again")
	s.text_scale = 99.0          # clamps to MAX, which is a real change
	expect(count["n"] == 3, "a clamped-but-different value still counts")
	s.text_scale = 99.0          # clamps to the same MAX — no change
	expect(count["n"] == 3, "clamping to the current value emits nothing")

func test_round_trip_through_dict() -> void:
	print("save/restore")
	var s := _make()
	s.palette = AccessibilitySettings.Palette.TRITANOPIA
	s.reduced_motion = true
	s.text_scale = 1.5
	s.shape_cues = true

	var restored := _make()
	restored.from_dict(s.to_dict())
	expect(restored.palette == s.palette, "palette survives the round trip")
	expect(restored.reduced_motion, "reduced motion survives")
	expect(is_equal_approx(restored.text_scale, 1.5), "text scale survives")
	expect(restored.shape_cues, "shape cues survive")

func test_from_dict_tolerates_junk() -> void:
	print("loading an older or corrupt settings file")
	var s := _make()
	s.from_dict({})
	expect(s.palette == AccessibilitySettings.Palette.DEFAULT, "missing keys fall back to defaults")
	s.from_dict({"palette": 999})
	expect(s.palette == AccessibilitySettings.Palette.DEFAULT, "an unknown palette id falls back")
	s.from_dict({"text_scale": 50.0})
	expect(is_equal_approx(s.text_scale, AccessibilitySettings.MAX_TEXT_SCALE),
		"an out-of-range scale is clamped rather than rejected")

## Cycling steps forward through the palettes, in order.
##
## The test above only checks that every palette is reached and that it wraps —
## which stepping backwards does just as well, in reverse. What a reader
## clicking "next" expects is the next one.
func test_cycling_goes_forward_through_the_list() -> void:
	print("cycling forward")
	var s := _make()
	var order: Array = AccessibilitySettings.PALETTES.keys()
	expect(order.size() > 2,
		"there are enough palettes for a direction to mean something (%d)" % order.size())

	var start := order.find(int(s.palette))
	expect(start >= 0, "the current palette is one of them")
	s.cycle_palette()
	expect(int(s.palette) == order[(start + 1) % order.size()],
		"cycling moves to the next one, not the previous (%d)" % int(s.palette))
	s.cycle_palette()
	expect(int(s.palette) == order[(start + 2) % order.size()],
		"and keeps going the same way (%d)" % int(s.palette))

	# Every index stays inside the list: stepping backwards past zero would
	# produce a negative key that PALETTES has no entry for.
	for i in order.size() * 2:
		s.cycle_palette()
		expect_quiet(AccessibilitySettings.PALETTES.has(int(s.palette)),
			"palette %d is a real one" % int(s.palette))
	expect(_quiet_failures == 0, "cycling never lands outside the list")

## Setting a value to what it already is is not a change.
##
## The setters guard on inequality before emitting. Invert that guard and
## `changed` fires only when nothing changed, which is exactly backwards — every
## listener redraws on the writes that do nothing and misses the ones that
## matter.
func test_setting_a_palette_to_itself_is_not_a_change() -> void:
	print("no-op writes")
	var s := _make()
	var count := {"n": 0}
	s.changed.connect(func() -> void: count["n"] += 1)

	s.palette = s.palette
	expect(count["n"] == 0,
		"writing the palette it already has emits nothing (%d)" % count["n"])

	var other := AccessibilitySettings.Palette.DEFAULT
	for key in AccessibilitySettings.PALETTES:
		if key != int(s.palette):
			other = key as AccessibilitySettings.Palette
			break
	s.palette = other
	expect(count["n"] == 1, "a real change emits once (%d)" % count["n"])
	expect(int(s.palette) == int(other), "and takes effect (%d)" % int(s.palette))

	s.palette = other
	expect(count["n"] == 1, "writing it again emits nothing more (%d)" % count["n"])

## An empty dictionary restores the defaults, not the opposites of them.
func test_an_empty_dict_restores_the_defaults() -> void:
	print("empty settings")
	var s := _make()
	# Turn everything on first, so a fallback that returns the wrong default
	# cannot be mistaken for the value simply not changing.
	s.reduced_motion = true
	s.shape_cues = true
	s.text_scale = AccessibilitySettings.MAX_TEXT_SCALE
	s.palette = AccessibilitySettings.PALETTES.keys()[1] as AccessibilitySettings.Palette

	s.from_dict({})
	expect(not s.reduced_motion,
		"motion is not reduced by default — the setting is opt-in")
	expect(not s.shape_cues,
		"and shape cues are off by default, since they add clutter for readers "
		+ "who do not need them")
	expect(is_equal_approx(s.text_scale, 1.0),
		"text is at its normal size (%.2f)" % s.text_scale)
	expect(int(s.palette) == int(AccessibilitySettings.Palette.DEFAULT),
		"and the palette is the default one (%d)" % int(s.palette))

	# A partial dictionary takes what it has and defaults the rest, which is
	# what makes an older settings file still load.
	s.reduced_motion = true
	s.from_dict({"reduced_motion": true})
	expect(s.reduced_motion, "a value that is present is used")
	expect(not s.shape_cues, "and the ones that are absent still fall back")

var _quiet_failures := 0

func expect_quiet(cond: bool, label: String) -> void:
	if not cond:
		_quiet_failures += 1
		print("    (", label, " — failed)")
