class_name HFSMState

var name: String
var parent: HFSMState = null
var children: Array[HFSMState] = []
var active_child: HFSMState = null
var _on_enter: Callable = func(): pass
var _on_exit: Callable = func(): pass
var _on_tick: Callable = func(_delta: float): pass

func _init(n: String) -> void:
	name = n

func add_child(child: HFSMState) -> HFSMState:
	child.parent = self
	children.append(child)
	return child

func enter() -> void:
	_on_enter.call()
	if children.size() > 0 and active_child == null:
		transition_to(children[0])

func exit() -> void:
	if active_child:
		active_child.exit()
		active_child = null
	_on_exit.call()

func tick(delta: float) -> void:
	_on_tick.call(delta)
	if active_child:
		active_child.tick(delta)

func transition_to(target: HFSMState) -> void:
	if active_child:
		active_child.exit()
	active_child = target
	active_child.enter()

func is_active() -> bool:
	if parent == null:
		return true
	return parent.active_child == self and parent.is_active()

func get_active_path() -> Array[String]:
	var path: Array[String] = [name]
	if active_child:
		path.append_array(active_child.get_active_path())
	return path
