extends Node

signal score_changed(new_score: int)

var score: int = 0:
	set(value):
		score = value
		score_changed.emit(score)

func add(amount: int = 10) -> void:
	score += amount

func reset() -> void:
	score = 0
