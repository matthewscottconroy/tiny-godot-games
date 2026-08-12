class_name BTNode

enum Status { SUCCESS, FAILURE, RUNNING }

func tick(_ctx: Dictionary) -> Status:
	return Status.FAILURE


class Sequence extends BTNode:
	var children: Array[BTNode] = []
	func tick(ctx: Dictionary) -> Status:
		for child in children:
			var s := child.tick(ctx)
			if s != Status.SUCCESS:
				return s
		return Status.SUCCESS


class Selector extends BTNode:
	var children: Array[BTNode] = []
	func tick(ctx: Dictionary) -> Status:
		for child in children:
			var s := child.tick(ctx)
			if s != Status.FAILURE:
				return s
		return Status.FAILURE


class Leaf extends BTNode:
	var label: String = ""
	var _fn: Callable
	func _init(lbl: String, fn: Callable) -> void:
		label = lbl
		_fn = fn
	func tick(ctx: Dictionary) -> Status:
		return _fn.call(ctx)
