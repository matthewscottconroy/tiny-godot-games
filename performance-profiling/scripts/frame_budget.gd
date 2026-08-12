## Measures where a frame's time goes, and against what budget.
##
## "The game is slow" is not actionable. A budget is: at 60 fps you have 16.67ms
## per frame, and the useful question is which section spent it. This wraps
## Godot's monotonic clock into named sections, keeps a rolling window so one
## unlucky frame does not dominate, and reports the share each section took.
##
## Sampling is not free — it is a timer read per section per frame — so in a real
## game you gate it behind a debug flag rather than shipping it hot.
class_name FrameBudget
extends RefCounted

## Target frame time in milliseconds. 60 fps is 16.67ms.
var budget_ms := 1000.0 / 60.0

## How many frames the rolling average covers.
var window := 60

var _open: Dictionary = {}        # section -> start microseconds
var _current: Dictionary = {}     # section -> accumulated ms this frame
var _history: Array[Dictionary] = []
var _order: PackedStringArray = PackedStringArray()

func _init(target_fps: float = 60.0, sample_window: int = 60) -> void:
	budget_ms = 1000.0 / maxf(target_fps, 1.0)
	window = maxi(sample_window, 1)

## Begin timing a section. Sections may be started and stopped in any order but
## must not nest under the same name.
func begin(section: String) -> void:
	if not _order.has(section):
		_order.append(section)
	_open[section] = Time.get_ticks_usec()

## Stop timing a section and add it to this frame's total.
func end(section: String) -> void:
	if not _open.has(section):
		return
	var elapsed_ms := (Time.get_ticks_usec() - int(_open[section])) / 1000.0
	_current[section] = float(_current.get(section, 0.0)) + elapsed_ms
	_open.erase(section)

## Close the frame and roll it into the history. Call once per frame.
func end_frame() -> void:
	_history.append(_current.duplicate())
	while _history.size() > window:
		_history.pop_front()
	_current = {}
	_open.clear()

## Rolling average milliseconds per section.
func averages() -> Dictionary:
	var totals: Dictionary = {}
	for frame in _history:
		for section in frame:
			totals[section] = float(totals.get(section, 0.0)) + float(frame[section])
	var out: Dictionary = {}
	var frames := maxi(_history.size(), 1)
	for section in totals:
		out[section] = float(totals[section]) / frames
	return out

## Average total frame time across all sections.
func total_ms() -> float:
	var sum := 0.0
	for value in averages().values():
		sum += float(value)
	return sum

## Fraction of the budget consumed. Above 1.0 means missing the target rate.
func budget_used() -> float:
	return total_ms() / budget_ms

func over_budget() -> bool:
	return total_ms() > budget_ms

## Sections ordered by cost, worst first — the list you actually want to read.
func worst_first() -> Array:
	var avg := averages()
	var rows: Array = []
	for section in avg:
		rows.append({
			"section": section,
			"ms": float(avg[section]),
			"share": (float(avg[section]) / total_ms()) if total_ms() > 0.0 else 0.0,
		})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["ms"] > b["ms"])
	return rows

## The order sections were first seen, for a stable display.
func sections() -> PackedStringArray:
	return _order

func samples() -> int:
	return _history.size()

func reset() -> void:
	_open.clear()
	_current = {}
	_history.clear()
	_order = PackedStringArray()
