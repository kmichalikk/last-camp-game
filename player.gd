extends AnimatableBody3D

@onready var mouse_marker: CSGBox3D = %MouseMarker

func _input_event(_camera: Camera3D, any_input_event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if any_input_event is InputEventMouseButton and any_input_event.is_pressed():
		if mouse_marker.target_player != self:
			mouse_marker.target_player = self
			print("Player selected")
		else:
			mouse_marker.target_player = null
			print("Player deselected")
