extends Node

# Drives the real NetworkManager from scripts/network.gd. A real ENet server is
# started on a loopback port, so this covers actual peer creation and teardown
# rather than a mock — but it stays single-process, so the client-side paths that
# need a second peer are asserted through the roster and RPC configuration
# instead of a live handshake.

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_starts_offline()
	test_host_creates_a_server()
	test_host_registers_itself_as_peer_one()
	test_leave_tears_down()
	test_host_twice_after_leaving()
	test_port_in_use_is_reported()
	test_offline_say_still_reports_locally()
	test_chat_rpc_calls_local()
	test_roster_sync_is_server_authoritative()
	test_peer_disconnect_updates_roster()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

# Well above the demo's default so a running demo never collides with the tests.
const TEST_PORT := 28910

func _make() -> NetworkManager:
	var net := NetworkManager.new()
	add_child(net)
	return net

func test_starts_offline() -> void:
	print("a fresh manager is offline")
	var net := _make()
	expect(not net.is_online(), "is_online() is false before host/join")
	expect(not net.is_server(), "is_server() is false while offline")
	expect(net.local_id() == 0, "local_id() is 0 while offline")
	expect(net.players.is_empty(), "the roster starts empty")
	net.leave()

func test_host_creates_a_server() -> void:
	print("host() brings up an ENet server")
	var net := _make()
	var statuses: Array[String] = []
	net.status_changed.connect(func(t: String) -> void: statuses.append(t))
	expect(net.host(TEST_PORT) == OK, "host() returns OK")
	expect(net.is_online(), "is_online() is true after hosting")
	expect(net.is_server(), "the host is the server")
	expect(statuses.size() == 1 and statuses[0].contains(str(TEST_PORT)),
		"status_changed reports the port it is listening on")
	net.leave()

func test_host_registers_itself_as_peer_one() -> void:
	print("the server registers itself as peer 1")
	var net := _make()
	var joins: Array = []
	net.player_joined.connect(func(id: int, is_local: bool) -> void: joins.append([id, is_local]))
	net.host(TEST_PORT + 1)
	# Godot never emits peer_connected for the server itself, so host() has to
	# add the entry — otherwise the host is missing from its own roster.
	expect(net.local_id() == 1, "the server is peer 1")
	expect(net.players.has(1), "the host appears in its own roster")
	expect(joins == [[1, true]], "player_joined fires once, flagged as local")
	net.leave()

func test_leave_tears_down() -> void:
	print("leave() releases the peer and the roster")
	var net := _make()
	net.host(TEST_PORT + 2)
	net.leave()
	expect(not net.is_online(), "is_online() is false after leaving")
	expect(net.players.is_empty(), "the roster is cleared")
	expect(net.local_id() == 0, "local_id() is 0 again")

func test_host_twice_after_leaving() -> void:
	print("the same port can be reused after leaving")
	var net := _make()
	expect(net.host(TEST_PORT + 3) == OK, "first host succeeds")
	net.leave()
	expect(net.host(TEST_PORT + 3) == OK, "hosting the same port again succeeds once released")
	net.leave()

func test_port_in_use_is_reported() -> void:
	print("a busy port is reported rather than silently ignored")
	var first := _make()
	first.host(TEST_PORT + 4)
	var second := _make()
	var statuses: Array[String] = []
	second.status_changed.connect(func(t: String) -> void: statuses.append(t))
	var err := second.host(TEST_PORT + 4)
	expect(err != OK, "the second host() on a busy port returns an error")
	expect(not second.is_online(), "the failed manager stays offline")
	expect(statuses.size() == 1 and statuses[0].contains("Could not host"),
		"the failure is surfaced through status_changed")
	first.leave()
	second.leave()

func test_offline_say_still_reports_locally() -> void:
	print("say() offline echoes locally")
	var net := _make()
	var seen: Array = []
	net.message_received.connect(func(id: int, text: String) -> void: seen.append([id, text]))
	net.say("hello")
	expect(seen == [[0, "hello"]], "an offline message is echoed with sender id 0")
	seen.clear()
	net.say("   ")
	expect(seen.is_empty(), "whitespace-only messages are dropped")

func test_chat_rpc_calls_local() -> void:
	print("the chat RPC runs on the sender too")
	var net := _make()
	net.host(TEST_PORT + 6)
	var seen: Array = []
	net.message_received.connect(func(id: int, text: String) -> void: seen.append([id, text]))
	net.say("hello")
	# This is what `call_local` buys: the sender sees its own message through the
	# same path as everyone else, so nothing has to special-case "me". Without it
	# the RPC would run only on remote peers and this list would stay empty.
	expect(seen.size() == 1, "the sender receives its own message")
	expect(seen[0][0] == 1, "it arrives attributed to the sending peer (the host is 1)")
	expect(seen[0][1] == "hello", "with the text intact")
	net.leave()

func test_roster_sync_is_server_authoritative() -> void:
	print("only the server rewrites the roster")
	var net := _make()
	net.host(TEST_PORT + 7)
	var joins: Array[int] = []
	net.player_joined.connect(func(id: int, _local: bool) -> void: joins.append(id))
	# _sync_roster is annotated "authority" + "call_remote": the server sends it
	# and never runs it on itself, so the host's own roster is the source of
	# truth rather than something it can overwrite from the wire.
	net._on_peer_connected(2)
	expect(net.players.has(2), "the server adds the joining peer")
	expect(joins == [2], "player_joined fires for the remote peer")
	expect(net.players.has(1), "and the host's own entry survives the sync")
	net.leave()

func test_peer_disconnect_updates_roster() -> void:
	print("a disconnect drops the peer from the roster")
	var net := _make()
	net.host(TEST_PORT + 5)
	# Stand in for a client that connected and then dropped.
	net.players[2] = "Player 2"
	var left: Array[int] = []
	net.player_left.connect(func(id: int) -> void: left.append(id))
	net._on_peer_disconnected(2)
	expect(left == [2], "player_left carries the departing id")
	expect(not net.players.has(2), "the peer is removed from the roster")
	expect(net.players.has(1), "the host is still listed")
	net.leave()

func _report() -> void:
	var summary := "[multiplayer-rpc] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)
