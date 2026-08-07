## A fixed-size pool of reusable node instances.
##
## Pre-instantiates `size` copies of `scene` at startup, then hands out
## inactive ones on demand instead of allocating (and later freeing) at runtime.
## Pooling avoids per-spawn allocation spikes and garbage collection stalls —
## essential for anything spawned frequently: bullets, particles, enemies.
##
## Contract: an instance is "available" while hidden (`visible == false`).
## `acquire()` returns a hidden instance; make it visible to use it, and hide
## it again to return it to the pool.
class_name ObjectPool
extends Node2D

## Scene pre-instantiated `size` times to fill the pool.
@export var scene: PackedScene
## Number of instances allocated up front.
@export var size := 20

## A pooled instance was just handed out by acquire().
signal acquired(instance: Node)
## acquire() was called while every instance was already active.
signal exhausted

var reuse_count := 0
var miss_count := 0

func _ready() -> void:
	assert(scene != null, "ObjectPool: `scene` is not set")
	for i in size:
		var instance := scene.instantiate()
		instance.visible = false
		add_child(instance)

## Returns a hidden instance, or null if all `size` instances are active.
func acquire() -> Node:
	for child in get_children():
		if not child.visible:
			reuse_count += 1
			acquired.emit(child)
			return child
	# Pool exhausted — in a real game you'd either grow the pool or skip the spawn.
	miss_count += 1
	exhausted.emit()
	return null

## How many instances are currently active (visible).
func active_count() -> int:
	return get_children().filter(func(c): return c.visible).size()
