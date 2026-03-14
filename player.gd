extends AnimatableBody3D

class_name Player

@export var player_color: Color = "498eff"

@onready var geometry: GeometryInstance3D = $PlayerCSG

func _ready() -> void:
	var material = StandardMaterial3D.new()
	material.albedo_color = player_color
	geometry.material_override = material
	

func _input_event(_camera: Camera3D, any_input_event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if any_input_event is InputEventMouseButton and any_input_event.is_pressed():
		if GameState.target_player != self:
			GameState.target_player = self
			print("Player selected")
		else:
			GameState.target_player = null
			print("Player deselected")
