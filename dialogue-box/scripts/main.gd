extends Node2D

const LINES : Array[String] = [
	"Hello, brave adventurer! I've been waiting for you.",
	"The ancient temple lies to the east, past the dark forest.",
	"Many have tried to reach it... few have returned.",
	"Take this map. May fortune favor you on your journey.",
]
const SPEAKERS : Array[String] = ["Elder", "Elder", "Elder", "Elder"]

@onready var dialogue_box : Control = $CanvasLayer/DialogueBox
@onready var talk_btn     : Button  = $TalkBtn

func _ready() -> void:
	talk_btn.pressed.connect(func():
		talk_btn.disabled = true
		dialogue_box.start(LINES, SPEAKERS))
	dialogue_box.finished.connect(func():
		talk_btn.disabled = false)

func _draw() -> void:
	# NPC elder
	draw_rect(Rect2(182, 240, 36, 52), Color.SANDY_BROWN)
	draw_circle(Vector2(200, 234), 18, Color(0.8, 0.62, 0.44))
	draw_line(Vector2(218, 252), Vector2(232, 194), Color.SADDLE_BROWN, 4)
	draw_circle(Vector2(232, 190), 7, Color.GOLD)
	# Talk button label visual hint
