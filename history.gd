extends Node

signal action_performed

const PHYSICS_SETTLED_AFTER_ACTION_THRESHOLD = 0.5

var _state_history = []
var _should_undo_current_state_first = true

func _ready() -> void:
	connect("action_performed", snapshot)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("undo"):
		if (_should_undo_current_state_first):
			undo_one()
			_should_undo_current_state_first = false
		undo_one()

func snapshot():
	await get_tree().create_timer(PHYSICS_SETTLED_AFTER_ACTION_THRESHOLD).timeout
	var data = {}
	for node in get_tree().get_nodes_in_group("history"):
		data[node.get_path()] = node.snapshot()
	_state_history.push_back(data)
	_should_undo_current_state_first = true
	
func undo_one():
	var last_entry = _state_history.pop_back()
	for path in last_entry:
		get_node(path).restore_from_snapshot(last_entry[path])
	if (_state_history.size() == 0):
		_state_history.push_back(last_entry)
