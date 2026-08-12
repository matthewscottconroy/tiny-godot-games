## Wraps Godot's high-level multiplayer into three calls: host(), join(), and
## leave(). It owns the peer and the roster of connected players, and reports
## everything else through signals so the game never has to poll
## `multiplayer.multiplayer_peer` or care whether it is the server or a client.
##
## The server is authoritative over the roster: clients learn about each other
## because the server tells them, not because they discover each other.
class_name NetworkManager
extends Node

## Someone joined. `is_local` is true for this peer's own arrival.
signal player_joined(id: int, is_local: bool)
## Someone left, by id.
signal player_left(id: int)
## Connection state changed — for a status label.
signal status_changed(text: String)
## A chat line arrived from `id`.
signal message_received(id: int, text: String)

const DEFAULT_PORT := 8910
const MAX_CLIENTS := 8

## Peer id -> display name. The server owns this; clients mirror it.
var players: Dictionary = {}

## Whether host()/join() has put us on a real peer.
##
## Testing `multiplayer.multiplayer_peer != null` does NOT work: Godot installs
## an OfflineMultiplayerPeer by default, so that check is true before you have
## networked anything. `has_multiplayer_peer()` returns true for it as well.
## Tracking the state explicitly is both correct and easier to read.
var _active := false

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

## Start listening. Returns OK, or the error from create_server().
func host(port: int = DEFAULT_PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_CLIENTS)
	if err != OK:
		status_changed.emit("Could not host on port %d (error %d)" % [port, err])
		return err
	multiplayer.multiplayer_peer = peer
	_active = true
	# The server is peer 1 by definition and never gets a peer_connected for
	# itself, so it registers its own entry directly.
	players[1] = "Host"
	status_changed.emit("Hosting on port %d" % port)
	player_joined.emit(1, true)
	return OK

## Connect to a host. Returns OK, or the error from create_client().
func join(address: String = "127.0.0.1", port: int = DEFAULT_PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address, port)
	if err != OK:
		status_changed.emit("Could not reach %s:%d (error %d)" % [address, port, err])
		return err
	multiplayer.multiplayer_peer = peer
	_active = true
	status_changed.emit("Connecting to %s:%d…" % [address, port])
	return OK

## Drop the connection and clear the roster.
func leave() -> void:
	if _active and multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	_active = false
	players.clear()
	status_changed.emit("Offline")

func is_online() -> bool:
	return _active

func is_server() -> bool:
	return _active and multiplayer.is_server()

func local_id() -> int:
	return multiplayer.get_unique_id() if _active else 0

## Send a chat line to everyone, including ourselves.
func say(text: String) -> void:
	if text.strip_edges().is_empty():
		return
	if not is_online():
		# Offline, the message still shows locally so the UI behaves the same.
		message_received.emit(0, text)
		return
	_receive_message.rpc(text)

# --- RPCs ---------------------------------------------------------------
#
# "any_peer"    — clients may call this on others, not just the server.
# "call_local"  — the sender runs it too, so nobody special-cases themselves.
# "reliable"    — chat must not be dropped; use "unreliable" for per-frame state.

@rpc("any_peer", "call_local", "reliable")
func _receive_message(text: String) -> void:
	message_received.emit(multiplayer.get_remote_sender_id(), text)

## Server -> client: here is the whole roster. Sent to each client as it joins.
@rpc("authority", "call_remote", "reliable")
func _sync_roster(roster: Dictionary) -> void:
	players = roster.duplicate()
	for id in players:
		player_joined.emit(int(id), int(id) == local_id())

# --- Multiplayer signal handlers ----------------------------------------

func _on_peer_connected(id: int) -> void:
	# Only the server maintains the roster; it then pushes it to everyone.
	if not is_server():
		return
	players[id] = "Player %d" % id
	player_joined.emit(id, false)
	_sync_roster.rpc(players)
	status_changed.emit("Player %d joined (%d online)" % [id, players.size()])

func _on_peer_disconnected(id: int) -> void:
	players.erase(id)
	player_left.emit(id)
	if is_server():
		_sync_roster.rpc(players)
	status_changed.emit("Player %d left (%d online)" % [id, players.size()])

func _on_connected_to_server() -> void:
	status_changed.emit("Connected as peer %d" % local_id())
	player_joined.emit(local_id(), true)

func _on_connection_failed() -> void:
	multiplayer.multiplayer_peer = null
	_active = false
	status_changed.emit("Connection failed")

func _on_server_disconnected() -> void:
	multiplayer.multiplayer_peer = null
	_active = false
	players.clear()
	status_changed.emit("Host disconnected")
