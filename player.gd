extends AnimatableBody3D

class_name Player

@export var player_color: Color = "498eff"

@onready var material: StandardMaterial3D = $PlayerCSG.material_override

func _ready() -> void:
	material.albedo_color = player_color
	material.emission = player_color
	material.emission_enabled = false
	
	GameState.selection_changed.connect(_on_selection_changed)

func _input_event(_camera: Camera3D, any_input_event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if any_input_event is InputEventMouseButton and any_input_event.is_pressed():
		GameState.toggle_selection(self)

func _on_selection_changed(new_player: Player):
	material.emission_enabled = new_player == self
