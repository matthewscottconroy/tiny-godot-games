class_name ComboSystem
extends RefCounted

const WINDOW := 0.6  # seconds before inputs expire

# Longest patterns first so they match before shorter subsets
const COMBOS: Array[Dictionary] = [
	{"pattern": ["L", "L", "L"], "name": "Triple Slash"},
	{"pattern": ["L", "H", "L"], "name": "Spin Attack"},
	{"pattern": ["H", "H", "H"], "name": "Ground Slam"},
	{"pattern": ["L", "L"],      "name": "Double Cut"},
	{"pattern": ["L", "H"],      "name": "Launcher"},
	{"pattern": ["H", "L"],      "name": "Counter"},
	{"pattern": ["H", "H"],      "name": "Overhead Slam"},
]

var _history: Array[Dictionary] = []  # [{input, time}]

func add_input(inp: String) -> String:
	_purge_old()
	_history.append({"input": inp, "time": Time.get_ticks_msec() / 1000.0})
	return _check()

func get_history_string() -> String:
	_purge_old()
	return " → ".join(_history.map(func(h: Dictionary) -> String: return h["input"]))

func _purge_old() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var keep: Array[Dictionary] = []
	for h in _history:
		if now - h["time"] < WINDOW:
			keep.append(h)
	_history = keep

func _check() -> String:
	var recent: Array[String] = []
	for h in _history:
		recent.append(h["input"])
	for combo in COMBOS:
		var pat: Array = combo["pattern"]
		if recent.size() >= pat.size():
			var tail := recent.slice(recent.size() - pat.size())
			if tail == pat:
				# Only forget the inputs if nothing longer could still grow out
				# of them. Clearing unconditionally meant "L" "L" fired Double
				# Cut and threw the history away, so the third "L" started from
				# nothing and Triple Slash — along with Spin Attack and Ground
				# Slam — could never be performed at all.
				if not _can_extend(pat):
					_history.clear()
				return combo["name"]
	return ""

## Is `pat` the opening of some longer combo?
static func _can_extend(pat: Array) -> bool:
	for combo in COMBOS:
		var other: Array = combo["pattern"]
		if other.size() > pat.size() and other.slice(0, pat.size()) == pat:
			return true
	return false
