# Multiplayer RPC

A minimal Godot 4 demo of the high-level multiplayer API: host or join over ENet, keep a shared player roster, and send messages between peers with `@rpc`.

## Purpose

Networking in Godot is usually taught as a wall of API surface, but the shape of it is small: one `MultiplayerPeer`, five signals, and functions marked `@rpc` that run on other machines. What makes multiplayer code confusing is not the transport — it is that every function now has to answer "who is running this, and who is allowed to?" That is exactly what the `@rpc` annotation encodes.

This demo keeps the game trivial (a chat line and a player list) so the networking is the only thing on screen. It shows the server as the authority over shared state, the difference between an `any_peer` call and an `authority` one, and why `call_local` is what lets you write a single code path instead of branching on "am I the sender".

## Running it

You need two instances. In the editor, enable **Debug → Run Multiple Instances → 2**, then press F5. From a terminal:

```bash
godot --path multiplayer-rpc &
godot --path multiplayer-rpc &
```

Press `H` in one window and `J` in the other. Both rosters should show two peers.

## Controls

| Key | Action |
|-----|--------|
| H | Host a server on port 8910 |
| J | Join `127.0.0.1:8910` |
| L | Leave and go back offline |
| 1-4 | Send a canned message to every peer |

## How It Works

**One peer, set once.** `ENetMultiplayerPeer.create_server()` or `create_client()` produces a peer; assigning it to `multiplayer.multiplayer_peer` is what puts the whole `SceneTree` on the network. The server is always peer id `1`; clients get ids assigned on connection.

**Five signals cover the lifecycle.** `peer_connected` / `peer_disconnected` fire on everyone when the roster changes. `connected_to_server`, `connection_failed`, and `server_disconnected` fire on clients only. The demo funnels all of them into its own `status_changed` signal so the UI never inspects network state directly.

**The server owns shared state.** When a client connects, only the server updates `players` — then it pushes the whole roster with `_sync_roster.rpc()`. Clients never build the roster themselves; they receive it. That is the cheapest form of server authority, and it is why `_sync_roster` is annotated `authority`: a client calling it would be rejected.

**`@rpc` annotations are the contract.**

```gdscript
@rpc("any_peer", "call_local", "reliable")
func _receive_message(text: String) -> void:
    message_received.emit(multiplayer.get_remote_sender_id(), text)
```

- `any_peer` — any client may invoke it. The default (`authority`) means only the server can, which is what you want for anything that changes shared state.
- `call_local` — the caller runs it too. Without this the sender would have to emit its own message separately, and you would have two code paths for one action.
- `reliable` — retransmit until it lands. Correct for chat and state changes; use `unreliable` for per-frame data like positions, where a newer packet makes an older one irrelevant.

`multiplayer.get_remote_sender_id()` inside the body tells you who called it — and returns your own id on a `call_local` invocation.

**Detecting "am I networked?" is not obvious.** Godot installs an `OfflineMultiplayerPeer` by default, so `multiplayer.multiplayer_peer != null` is true before you have connected to anything, and `has_multiplayer_peer()` returns true for it as well. `NetworkManager` tracks an explicit `_active` flag instead.

## Key Godot APIs

| API | Purpose |
|-----|---------|
| `ENetMultiplayerPeer.create_server(port, max)` | Start listening |
| `ENetMultiplayerPeer.create_client(host, port)` | Connect out |
| `multiplayer.multiplayer_peer` | Assigning it puts the tree on the network |
| `@rpc("any_peer", "call_local", "reliable")` | Who may call it, whether the sender runs it, and delivery guarantee |
| `Callable.rpc(args)` | Invoke on every peer; `rpc_id(id, …)` targets one |
| `multiplayer.get_remote_sender_id()` | Who called the RPC currently executing |
| `multiplayer.is_server()` / `get_unique_id()` | Role and identity |
| `multiplayer.peer_connected` / `peer_disconnected` | Roster changes, on every peer |
| `multiplayer.connection_failed` / `server_disconnected` | Client-side failure paths |

## Key Constants

| Constant | Value | Meaning |
|----------|-------|---------|
| `DEFAULT_PORT` | 8910 | Port used by both host and join |
| `MAX_CLIENTS` | 8 | Connection slots on the server |
| `MAX_LOG_LINES` | 8 | Lines kept in the on-screen log |

## Files

| File | What it holds |
|------|---------------|
| `scripts/network.gd` | The `NetworkManager` component: peer lifecycle, roster, RPCs |
| `scripts/main.gd` | Demo driver: key handling, HUD, and the connection diagram |
| `scenes/main.tscn` | The runnable scene |
| `tests/test_logic.gd` | Headless test suite — starts real ENet servers on loopback |

## Use as a building block

**Copy:** `scripts/network.gd` — the `NetworkManager` type. `scripts/main.gd` is the demo driver and is not needed.

**Public API**
- `host(port := 8910) -> Error` / `join(address := "127.0.0.1", port := 8910) -> Error` — both return the engine error rather than raising, so the caller can show it.
- `leave()` — closes the peer and clears the roster.
- `is_online()`, `is_server()`, `local_id()` — state without touching `multiplayer` directly.
- `say(text)` — broadcast a chat line; echoes locally when offline so the UI does not need a special case.
- `players: Dictionary` — peer id to display name.
- signals `player_joined(id, is_local)`, `player_left(id)`, `status_changed(text)`, `message_received(id, text)`.

**Integrate**
1. Add a `NetworkManager` node to your main scene and connect its signals to your UI.
2. Call `host()` or `join()` from a lobby screen; both are non-blocking, so wait for `status_changed` / `player_joined` rather than the return value alone.
3. Add your own `@rpc` functions for game actions. Anything that changes shared state should stay `authority` and be validated on the server; only inputs and chat belong on `any_peer`.

**Notes**
- `class_name NetworkManager` is global to the project — rename it if you already define that type.
- Godot matches RPCs by **node path**, so the node holding an `@rpc` function must exist at the same path on every peer. Registering `NetworkManager` as an autoload is the simplest way to guarantee that.
- The roster sync sends the whole dictionary on every change, which is fine for a lobby but not for per-frame state. For that, look at `MultiplayerSynchronizer` or send deltas as `unreliable`.
- No project settings or input actions are required; the demo reads raw keys so it does not depend on the `ui_*` map.

## Related demos

- [multiplayer-prediction](../multiplayer-prediction) — Applying input locally, then reconciling when the authoritative server disagrees.
- [split-screen](../split-screen) — Two-player split-screen, each with independent world, physics, and camera.

<sub>Generated by `tools/build_index.py` from shared APIs and [learning path](../docs/LEARNING_PATHS.md) adjacency.</sub>

