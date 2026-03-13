extends StaticBody3D

@onready var tile_geom: CSGBox3D = $TileGeom
@onready var tile_stand_highlight: CSGBox3D = $TileStandHighlight

@export var player_can_stand_on: bool = true


func _mouse_enter() -> void:
	if GameState.target_player != null and player_can_stand_on:
		tile_stand_highlight.visible = true


func _mouse_exit() -> void:
	tile_stand_highlight.visible = false
		
		
func _input_event(_camera: Camera3D, any_input_event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if any_input_event is InputEventMouse:
		if any_input_event is InputEventMouseButton and GameState.target_player:
			GameState.target_player.position = self.global_position + Vector3(0, 1, 0)
