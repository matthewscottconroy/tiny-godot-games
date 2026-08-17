# Memory

Two separate things live here: leaks inside the demos, and the memory the test
tooling itself consumes. They caused different problems and have different fixes.

## Leaks in the demos

Godot reports unfreed objects when it shuts down. Those messages arrive after
everything has finished and nothing fails, so they are easy to never notice.
`tools/leakcheck.sh` surfaces them deliberately:

```bash
tools/leakcheck.sh                    # every demo
VERBOSE=1 tools/leakcheck.sh <demo>   # show clean results too
```

**Current state: 165 clean, 0 leaking.** The two engine-side reports are
allowlisted with evidence; the race is filtered by confirm-on-retry.

The first full scan found five reports. Investigating each turned up
**two real leaks, two engine-side reports, and one race** — a distinction worth
making, because "fixing" the last three would have meant adding code that does
nothing.

### Real: `undo-redo`

```
without the fix: 8/8 runs leak      with the fix: 0/8
```

`UndoRedo` extends `Object`, not `RefCounted`. Nothing reference-counts it, so
`UndoRedo.new()` held in a variable is never collected — it has to be freed by
hand. This is the general trap with Godot's `Object`-derived helper types, and
it is invisible until you go looking.

```gdscript
func _exit_tree() -> void:
	if is_instance_valid(_undo_redo):
		_undo_redo.free()
```

### Real: `state-machine-hfsm`

Found and fixed earlier, during the Godot 4.7 compatibility work. `HFSMState`
is `RefCounted` and held a strong `parent` reference while the parent held its
children, so the whole state tree formed a cycle and never freed. `RefCounted`
is reference-counted, not garbage-collected: a cycle is permanent.

The fix is a `WeakRef` for the upward link, with a property getter so callers
still write `state.parent`.

### Partial: `procedural-sfx`

```
without the fix: 5/8 runs leak      with the fix: 2/8
```

An `AudioStreamGeneratorPlayback` stays referenced while its player is playing,
so stopping the player on the way out releases the demo's share. It does not
eliminate the report, because the remainder is the engine race described below.
The change is kept because the reduction is real and the practice — release
audio before freeing the node — is correct in any game.

### Engine-side: `audio-positional`, `dynamic-music`

These report leaks that the demo cannot fix. Both were confirmed by reproducing
the identical report in a minimal scene containing none of the demo's code:

```gdscript
# 12 lines, leaks 2 ObjectDB instances at exit
func _ready() -> void:
    var wav := AudioStreamWAV.new()
    ...
    var p := AudioStreamPlayer2D.new()
    add_child(p); p.stream = wav; p.play()
```

Stopping the player, clearing `stream`, and running longer all made no
difference (3 leaked instances in every configuration). `tools/leakcheck.sh`
carries these two on a short allowlist with that evidence attached, so the scan
does not cry wolf on them forever.

### Race: `music-sequencer`

Reports a leak in roughly **one run in six** and nothing the other five times.
Rather than allowlist it, the checker confirms every hit by running a second
time and only reports if it reproduces. That is more robust than a growing list
of exceptions and catches future flakiness for free.

## What actually caused the OOM crashes

Worth recording, because the first two guesses were both wrong. The kernel log
named the victims:

```
Out of memory: Killed process (bash) anon-rss:41926808kB   # 40.4 GB
Out of memory: Killed process (bash) anon-rss:41926808kB   # 40.0 GB
```

**Two bash processes at 40GB each.** Not Godot, which measures ~107MB. The cause
is that `out="$(cmd)"` buffers everything the child writes into a shell
variable — and `run-tests.sh` captured a whole demo run that way with no cap. A
demo that errors once per frame, or any run that does not terminate when
expected, grows the *shell* without limit. `subprocess.run(capture_output=True)`
in Python has exactly the same property.

The fix is `mem_capture`, which applies both a time limit and a size limit to
every capture, and announces truncation in the captured text so nothing silently
analyses a partial log. `tools/mutate.py` streams and truncates for the same
reason. Verified against `yes` as an infinite producer.

Two earlier theories that the evidence did not support:

- *"Too many parallel Godot processes."* 24 jobs is ~2.6GB on a 55GB machine.
  Capping concurrency is still right, but it was never the cause.
- *"A leaking demo."* The full scan finds 165 clean; the leaks that did exist
  were a few objects at shutdown, not gigabytes.

## Safeguards in the tooling

`tools/memguard.sh` is sourced by every Godot-spawning tool. Six protections,
because any one alone leaves a hole:

| Guard | What it does | Override |
|-------|--------------|----------|
| Pre-flight | Refuses to start below 2GB available | `MEM_MIN_START_MB` |
| Bounded jobs | Concurrency from free memory, not just cores; halved again if another Godot is already running; hard cap 8 | `JOBS`, `MEM_MAX_JOBS` |
| Live floor | Aborts mid-run below 1GB, checked between chunks | `MEM_FLOOR_MB` |
| Reaping | Kills our own children on exit or interrupt | — |
| **Bounded capture** | **Caps captured output at 2MB — the guard that addresses the actual cause** | `MEM_MAX_CAPTURE_KB` |
| Run timeout | Kills a single Godot invocation that will not exit | `MEM_RUN_TIMEOUT` |

Every Godot spawn also runs under an address-space `ulimit` (`MEM_ULIMIT_MB`,
4GB) so a runaway child is killed alone rather than taking the machine with it.
The cap was checked against normal operation before being relied on.

`run-tests.sh` processes demos in chunks so the floor is re-checked as it goes
and reports a partial result rather than dying. `tools/mutate.py` checks between
demos and, crucially, **refuses to write or check the mutation baseline after an
aborted run** — a partial sweep is not comparable, and recording it would
silently lower the floor.

## Memory used by the test tooling

`run-tests.sh` runs demos in parallel. Each job is a full Godot process holding
a rendering server and an imported project — **measured at ~107MB peak RSS**,
not the ~400MB first assumed.

Concurrency defaults are bounded by both cores and available memory:

```
half the core count, capped at 8, and further capped at roughly 1 job per GB of
MemAvailable
```

On a 24-core machine that is 8 jobs (~0.9GB) rather than 24 (~2.6GB). Override
with `JOBS=`:

```bash
JOBS=4 ./run-tests.sh        # tighter
JOBS=16 ./run-tests.sh       # a big machine with nothing else running
```

`tools/mutate.py` and `tools/leakcheck.sh` are deliberately serial: they are
diagnostics rather than something to finish quickly, and one process at a time
keeps their footprint at a single Godot instance.

If you are running several things at once and hit memory pressure, `JOBS=2` or
`JOBS=1` makes the suite entirely sequential at the cost of wall-clock time.
