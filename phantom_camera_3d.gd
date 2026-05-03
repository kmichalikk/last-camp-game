@tool
extends PhantomCamera3D

@export var is_frozen: bool = false:
	set(value):
		if is_frozen == value:
			return
		is_frozen = value
		_handle_freeze_logic()

@export var rotation_duration: float = 0.4
var _is_rotating: bool = false
var _absolute_rotation_y: float = 0.0
var _target_rotation_y: float = 0.0
var _rotation_tween: Tween

func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint():
		return

	_absolute_rotation_y = rotation.y
	_target_rotation_y = rotation.y
	add_to_group("history")
	GameState.game_over.connect(_on_game_over)

func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint() or is_frozen:
		return

	if event.is_action_pressed("camera_rotate_left"):
		_rotate_camera(PI / 2.0)
	elif event.is_action_pressed("camera_rotate_right"):
		_rotate_camera(-PI / 2.0)

func _rotate_camera(angle_rad: float) -> void:
	_target_rotation_y += angle_rad

	if _rotation_tween and _rotation_tween.is_valid():
		_rotation_tween.kill()

	_is_rotating = true
	follow_damping = false

	_rotation_tween = create_tween()
	_rotation_tween.set_trans(Tween.TRANS_QUART)
	_rotation_tween.set_ease(Tween.EASE_OUT)
	_rotation_tween.tween_method(_apply_rotation, _absolute_rotation_y, _target_rotation_y, rotation_duration)
	_rotation_tween.finished.connect(_on_tween_finish)

func _apply_rotation(value: float) -> void:
	_absolute_rotation_y = value
	rotation.y = value

func _on_tween_finish() -> void:
	_is_rotating = false
	follow_damping = true

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
