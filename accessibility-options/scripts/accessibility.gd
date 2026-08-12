## Holds the accessibility settings a game exposes, and tells everything else
## when they change.
##
## The point of routing these through one object is that accessibility settings
## are cross-cutting: colour choice affects every drawn thing, reduced motion
## affects every tween and shake, text scale affects every label. If each system
## reads a global directly you get no signal when a setting changes; if each one
## stores its own copy they drift. One node, one `changed` signal.
class_name AccessibilitySettings
extends Node

signal changed

## Palettes chosen so that the semantic pairs stay distinguishable under the
## common forms of colour vision deficiency. "Default" is the red/green pairing
## most games ship and the one that fails for roughly 1 in 12 men.
enum Palette { DEFAULT, DEUTERANOPIA, TRITANOPIA, HIGH_CONTRAST }

const PALETTES := {
	Palette.DEFAULT: {
		"name": "Default",
		"positive": Color(0.20, 0.75, 0.30),
		"negative": Color(0.85, 0.20, 0.20),
		"neutral": Color(0.55, 0.57, 0.62),
	},
	Palette.DEUTERANOPIA: {
		# Red/green become indistinguishable, so split on blue/orange instead.
		"name": "Deuteranopia",
		"positive": Color(0.20, 0.50, 0.95),
		"negative": Color(0.95, 0.55, 0.10),
		"neutral": Color(0.55, 0.57, 0.62),
	},
	Palette.TRITANOPIA: {
		# Blue/yellow confusion; magenta and teal stay separable.
		"name": "Tritanopia",
		"positive": Color(0.10, 0.70, 0.70),
		"negative": Color(0.85, 0.20, 0.60),
		"neutral": Color(0.55, 0.57, 0.62),
	},
	Palette.HIGH_CONTRAST: {
		"name": "High contrast",
		"positive": Color(1.00, 1.00, 1.00),
		"negative": Color(0.10, 0.10, 0.10),
		"neutral": Color(0.50, 0.50, 0.50),
	},
}

const MIN_TEXT_SCALE := 1.0
const MAX_TEXT_SCALE := 2.0

var palette: Palette = Palette.DEFAULT:
	set(value):
		if palette != value:
			palette = value
			changed.emit()

## When true, systems should skip decorative motion — screen shake, camera
## kicks, parallax drift. It must not remove information, only movement.
var reduced_motion := false:
	set(value):
		if reduced_motion != value:
			reduced_motion = value
			changed.emit()

## Multiplier applied to font sizes.
var text_scale := 1.0:
	set(value):
		var clamped := clampf(value, MIN_TEXT_SCALE, MAX_TEXT_SCALE)
		if not is_equal_approx(text_scale, clamped):
			text_scale = clamped
			changed.emit()

## True when the player has asked for a marker as well as a colour. Colour alone
## is never enough — it is the single most common accessibility failure in games.
var shape_cues := false:
	set(value):
		if shape_cues != value:
			shape_cues = value
			changed.emit()

func colors() -> Dictionary:
	return PALETTES[palette]

func palette_name() -> String:
	return PALETTES[palette]["name"]

## Scale a base font size for the current text setting.
func font_size(base: int) -> int:
	return int(round(base * text_scale))

## How long an animation should take. Reduced motion collapses decorative
## animation to zero so the end state appears immediately.
func motion_duration(base_seconds: float) -> float:
	return 0.0 if reduced_motion else base_seconds

## The symbol to pair with a colour, or "" when shape cues are off.
func cue_for(is_positive: bool) -> String:
	if not shape_cues:
		return ""
	return "▲" if is_positive else "▼"

func cycle_palette() -> void:
	palette = ((palette + 1) % PALETTES.size()) as Palette

## Everything as a plain dictionary, ready for ConfigFile or JSON.
func to_dict() -> Dictionary:
	return {
		"palette": int(palette),
		"reduced_motion": reduced_motion,
		"text_scale": text_scale,
		"shape_cues": shape_cues,
	}

## Restore from to_dict(). Unknown or out-of-range values fall back to defaults
## rather than raising, so a settings file from an older build still loads.
func from_dict(data: Dictionary) -> void:
	var p := int(data.get("palette", Palette.DEFAULT))
	palette = (p if PALETTES.has(p) else Palette.DEFAULT) as Palette
	reduced_motion = bool(data.get("reduced_motion", false))
	text_scale = float(data.get("text_scale", 1.0))
	shape_cues = bool(data.get("shape_cues", false))
