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
				_history.clear()
				return combo["name"]
	return ""
