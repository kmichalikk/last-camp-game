extends AnimatableBody3D

class_name Player

@export var player_color: Color = "498eff"

@onready var geometry: GeometryInstance3D = $PlayerCSG

@onready var material: StandardMaterial3D = geometry.material_override

func _ready() -> void:
	material.albedo_color = player_color
	material.emission = player_color
	material.emission_enabled = false

func _input_event(_camera: Camera3D, any_input_event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if any_input_event is InputEventMouseButton and any_input_event.is_pressed():
		if GameState.target_player != self:
			if GameState.target_player != null:
				GameState.target_player.material.emission_enabled = false
			GameState.target_player = self
			material.emission_enabled = true
			print("Player selected")
		else:
			GameState.target_player = null
			material.emission_enabled = false
			print("Player deselected")
