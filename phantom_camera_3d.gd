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

func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint():
		return

	add_to_group("history")
	GameState.game_over.connect(_on_game_over)

func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint() or is_frozen or _is_rotating:
		return

	if event.is_action_pressed("camera_rotate_left"):
		_rotate_camera(90)
	elif event.is_action_pressed("camera_rotate_right"):
		_rotate_camera(-90)

func _rotate_camera(angle_degrees: float) -> void:
	_is_rotating = true

	follow_damping = false

	var target_rotation_y = rotation.y + deg_to_rad(angle_degrees)

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUART)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation:y", target_rotation_y, rotation_duration)

	tween.finished.connect(_on_tween_finish)

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
