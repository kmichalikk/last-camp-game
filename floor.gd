extends AnimatableBody3D

@onready var mouse_marker: CSGBox3D = %MouseMarker


func calculate_grid_position(mouse_position: Vector3):
	return floor(mouse_position) + Vector3(0, 0.5, 0)


func _input_event(_camera: Camera3D, any_input_event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if any_input_event is InputEventMouse:
		mouse_marker.position = calculate_grid_position(_position)
		if any_input_event is InputEventMouseButton and mouse_marker.target_player:
			mouse_marker.target_player.position = mouse_marker.position + Vector3(0, 0.5, 0)
		
		
func _mouse_exit() -> void:
	mouse_marker.position = Vector3(-999, -999, -999)
