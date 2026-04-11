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
