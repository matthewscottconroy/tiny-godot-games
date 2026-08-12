extends Node2D

# Demo driver. Runs two instances of this project (Debug > Run Multiple
# Instances in the editor, or two `godot --path multiplayer-rpc` processes):
# press H in one, J in the other, then 1-4 to send messages between them.

@onready var _net: NetworkManager = $Network
@onready var _status_label: Label = $HUD/StatusLabel
@onready var _roster_label: Label = $HUD/RosterLabel
@onready var _log_label: Label = $HUD/LogLabel

const CANNED_MESSAGES := ["Hello!", "Ready when you are.", "Nice shot.", "Rematch?"]
const MAX_LOG_LINES := 8

var _log: Array[String] = []

func _ready() -> void:
	_net.status_changed.connect(_on_status)
	_net.player_joined.connect(_on_joined)
	_net.player_left.connect(_on_left)
	_net.message_received.connect(_on_message)
	_on_status("Offline — press H to host, J to join 127.0.0.1")
	_refresh_roster()

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_H: _net.host()
		KEY_J: _net.join()
		KEY_L: _net.leave()
		KEY_1, KEY_2, KEY_3, KEY_4:
			_net.say(CANNED_MESSAGES[key.keycode - KEY_1])

func _on_status(text: String) -> void:
	var role := ""
	if _net.is_online():
		role = "  [%s, peer %d]" % ["server" if _net.is_server() else "client", _net.local_id()]
	_status_label.text = text + role
	_refresh_roster()

func _on_joined(id: int, is_local: bool) -> void:
	_append("→ peer %d joined%s" % [id, " (you)" if is_local else ""])
	_refresh_roster()

func _on_left(id: int) -> void:
	_append("← peer %d left" % id)
	_refresh_roster()

func _on_message(id: int, text: String) -> void:
	var who := "you" if id == _net.local_id() or id == 0 else "peer %d" % id
	_append("%s: %s" % [who, text])

func _append(line: String) -> void:
	_log.append(line)
	while _log.size() > MAX_LOG_LINES:
		_log.pop_front()
	_log_label.text = "\n".join(_log)

func _refresh_roster() -> void:
	if not _net.is_online():
		_roster_label.text = "Players: —"
		return
	var ids := _net.players.keys()
	ids.sort()
	var names := ids.map(func(i: int) -> String:
		return "%d%s" % [i, "*" if i == _net.local_id() else ""])
	_roster_label.text = "Players (%d): %s      * = you" % [ids.size(), ", ".join(names)]

func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 480), Color(0.09, 0.10, 0.14))
	# Two "machines" with a link between them, tinted by connection state.
	var linked := _net.is_online() and _net.players.size() > 1
	var link_col := Color(0.3, 0.85, 0.45) if linked else Color(0.35, 0.35, 0.42)
	draw_line(Vector2(190, 150), Vector2(450, 150), link_col, 4.0)
	for i in 2:
		var centre := Vector2(150.0 + i * 340.0, 150.0)
		var online := _net.is_online() and (i == 0 or linked)
		var body := Color(0.22, 0.45, 0.75) if online else Color(0.24, 0.24, 0.30)
		draw_rect(Rect2(centre - Vector2(40, 30), Vector2(80, 60)), body)
		draw_rect(Rect2(centre - Vector2(40, 30), Vector2(80, 60)), body.lightened(0.4), false, 2.0)
		draw_circle(centre + Vector2(0, 44), 6.0, link_col if online else Color(0.4, 0.2, 0.2))
