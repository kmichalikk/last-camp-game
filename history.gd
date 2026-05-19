extends Node

signal action_performed

const PHYSICS_SETTLED_AFTER_ACTION_THRESHOLD = 0.5

var _state_history = []
var _should_undo_current_state_first = true
var _snapshot_timer: Timer

func _ready() -> void:
	connect("action_performed", _on_action_performed)

	_snapshot_timer = Timer.new()
	_snapshot_timer.wait_time = PHYSICS_SETTLED_AFTER_ACTION_THRESHOLD
	_snapshot_timer.one_shot = true
	_snapshot_timer.timeout.connect(_take_snapshot)
	add_child(_snapshot_timer)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("undo"):
		_snapshot_timer.stop() # Cancel any pending snapshot
		if (_should_undo_current_state_first):
			undo_one()
			_should_undo_current_state_first = false
		undo_one()

func _on_action_performed():
	if _snapshot_timer.time_left > 0:
		_take_snapshot()

	_should_undo_current_state_first = false
	_snapshot_timer.start()

func _take_snapshot():
	var data = {}
	for node in get_tree().get_nodes_in_group("history"):
		data[node.get_path()] = node.snapshot()
	_state_history.push_back(data)
	_should_undo_current_state_first = true

func undo_one():
	if _state_history.is_empty():
		return

	var last_entry = _state_history.pop_back()
	for path in last_entry:
		var node = get_node_or_null(path)
		if node:
			node.restore_from_snapshot(last_entry[path])

	if (_state_history.size() == 0):
		_state_history.push_back(last_entry)
