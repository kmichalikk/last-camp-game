extends AnimatableBody3D

class_name Player

func _input_event(_camera: Camera3D, any_input_event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if any_input_event is InputEventMouseButton and any_input_event.is_pressed():
		if GameState.target_player != self:
			GameState.target_player = self
			print("Player selected")
		else:
			GameState.target_player = null
			print("Player deselected")
