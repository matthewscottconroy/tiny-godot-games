## A caption queue for speech and important sounds.
##
## Games caption two different things and usually conflate them: dialogue (who
## said it, and what) and non-speech audio cues (a door behind you, a reload).
## Both need to be queued rather than shown instantly, because two lines that
## overlap in time must not overlap on screen — the second waits.
##
## Timing is derived from the text length so a caption stays up long enough to
## read, with a floor for very short lines.
class_name SubtitleQueue
extends Node

## A caption became visible.
signal caption_shown(entry: Dictionary)
## A caption's time ran out and it was removed.
signal caption_hidden(entry: Dictionary)
## The queue drained completely.
signal queue_empty

## Reading speed used to size a caption's duration.
@export var chars_per_second := 14.0
## No caption is shown for less than this, however short.
@export var min_duration := 1.2
## Longest a single caption stays up before being cut off.
@export var max_duration := 8.0
## Show non-speech cues like [door opens] as well as speech.
@export var sound_cues := true

var _queue: Array[Dictionary] = []
var _current: Dictionary = {}
var _remaining := 0.0

## How long a caption should stay up for `text`.
func duration_for(text: String) -> float:
	return clampf(text.length() / chars_per_second, min_duration, max_duration)

## Queue a spoken line. `speaker` may be empty for a narrator.
func say(text: String, speaker: String = "") -> void:
	_enqueue({"text": text, "speaker": speaker, "is_cue": false})

## Queue a non-speech cue, e.g. cue("door opens behind you"). Dropped entirely
## when the player has sound cues switched off.
func cue(text: String) -> void:
	if not sound_cues:
		return
	_enqueue({"text": text, "speaker": "", "is_cue": true})

func _enqueue(entry: Dictionary) -> void:
	if String(entry["text"]).strip_edges().is_empty():
		return
	entry["duration"] = duration_for(String(entry["text"]))
	_queue.append(entry)
	if _current.is_empty():
		_advance()

## Age the visible caption. Call once per frame.
func update(delta: float) -> void:
	if _current.is_empty():
		return
	_remaining -= delta
	if _remaining <= 0.0:
		var finished := _current
		_current = {}
		caption_hidden.emit(finished)
		_advance()

## The caption on screen right now, or {} when nothing is showing.
func current() -> Dictionary:
	return _current

## Formatted for display: cues are bracketed, speech is prefixed with a speaker.
func current_text() -> String:
	if _current.is_empty():
		return ""
	var text := String(_current["text"])
	if bool(_current["is_cue"]):
		return "[%s]" % text
	var speaker := String(_current["speaker"])
	return "%s: %s" % [speaker, text] if speaker != "" else text

func pending() -> int:
	return _queue.size()

func is_showing() -> bool:
	return not _current.is_empty()

## Drop everything, on screen and queued — for a scene change or a skip.
func clear() -> void:
	var was_showing := not _current.is_empty()
	var finished := _current
	_queue.clear()
	_current = {}
	_remaining = 0.0
	if was_showing:
		caption_hidden.emit(finished)
	queue_empty.emit()

## Cut the visible caption short and move on.
func skip() -> void:
	if _current.is_empty():
		return
	_remaining = 0.0
	update(0.0)

func _advance() -> void:
	if _queue.is_empty():
		queue_empty.emit()
		return
	_current = _queue.pop_front()
	_remaining = float(_current["duration"])
	caption_shown.emit(_current)
