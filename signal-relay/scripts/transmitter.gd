extends Button

signal message_sent(text: String)

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	message_sent.emit("Signal received at %d ms!" % Time.get_ticks_msec())
