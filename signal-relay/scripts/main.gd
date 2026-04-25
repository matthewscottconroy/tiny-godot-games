extends Control

func _ready() -> void:
	# Connect transmitter's custom signal to receiver's method.
	# Neither node knows about the other — main.gd owns the relationship.
	$Transmitter.message_sent.connect($Receiver.receive)
