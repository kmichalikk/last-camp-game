@tool
extends PhantomCamera3D

@export var is_frozen: bool = false:
	set(value):
		if is_frozen == value:
			return
		is_frozen = value
		_handle_freeze_logic()

func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint():
		return
	
	add_to_group("history")
	GameState.game_over.connect(_on_game_over)

func _on_game_over() -> void:
	is_frozen = true

func _handle_freeze_logic() -> void:
	if Engine.is_editor_hint():
		return
		
	if is_frozen:
		follow_mode = FollowMode.NONE
	else:
		follow_mode = FollowMode.GROUP

func snapshot() -> Variant:
	return {
		"is_frozen": is_frozen
	}

func restore_from_snapshot(data: Variant):
	is_frozen = data.is_frozen
