## Upgrades save data written by older versions of your game.
##
## Every save carries a `version` field. Register one small step per version
## bump — each step only has to know how to get from N to N+1 — and `migrate()`
## chains them. That keeps the migration for any single release readable, and
## means a save from three versions ago is upgraded by running three steps in
## order rather than by one function full of special cases.
##
## Nothing here knows what your save contains; the steps do.
class_name SaveMigrator
extends RefCounted

## The version a freshly written save gets.
var current_version: int = 1

## from_version -> Callable(Dictionary) -> Dictionary
var _steps: Dictionary = {}

func _init(latest_version: int = 1) -> void:
	current_version = latest_version

## Register the step that upgrades a save from `from_version` to the next one.
## Returns self so registrations can chain.
func add_step(from_version: int, step: Callable) -> SaveMigrator:
	_steps[from_version] = step
	return self

## Read the version out of a save, treating a missing field as version 0 —
## saves written before anyone thought to add one.
func version_of(data: Dictionary) -> int:
	return int(data.get("version", 0))

## True if `data` is older than `current_version` and can be upgraded.
func needs_migration(data: Dictionary) -> bool:
	return version_of(data) < current_version

## Run every step between the save's version and the current one.
##
## Returns {"ok": bool, "data": Dictionary, "from": int, "to": int,
## "steps": PackedStringArray, "error": String}. `ok` is false when a version in
## the chain has no registered step, or the save is newer than this build knows
## about — both are cases where guessing would corrupt the player's data, so the
## caller is told rather than handed something plausible.
func migrate(data: Dictionary) -> Dictionary:
	var from := version_of(data)
	var result := {
		"ok": true,
		"data": data.duplicate(true),
		"from": from,
		"to": from,
		"steps": PackedStringArray(),
		"error": "",
	}

	if from > current_version:
		result["ok"] = false
		result["error"] = ("save is version %d but this build only understands %d — "
			+ "it was probably written by a newer version of the game") % [from, current_version]
		return result

	var working: Dictionary = result["data"]
	var v := from
	while v < current_version:
		if not _steps.has(v):
			result["ok"] = false
			result["error"] = "no migration step registered for version %d" % v
			result["data"] = working
			result["to"] = v
			return result
		working = (_steps[v] as Callable).call(working)
		v += 1
		working["version"] = v
		result["steps"].append("%d→%d" % [v - 1, v])

	result["data"] = working
	result["to"] = v
	return result
