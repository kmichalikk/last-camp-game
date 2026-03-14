extends StaticBody3D

class_name RockTile

@onready var tile_geom: CSGBox3D = $TileGeom
@onready var tile_stand_highlight: CSGBox3D = $TileStandHighlight
@onready var material: StandardMaterial3D = $TileStandHighlight.material
@onready var topOccupancyZone: Area3D = $TopOccupancyZone

@export var player_can_stand_on: bool = true

func _ready() -> void:
	GameState.selection_changed.connect(_on_selection_changed)

func has_standing_player() -> bool:
	return topOccupancyZone.has_overlapping_bodies()

func _mouse_enter() -> void:
	if GameState.target_player != null and GameState.can_player_move_to_tile(GameState.target_player, self):
		tile_stand_highlight.visible = true


func _mouse_exit() -> void:
	tile_stand_highlight.visible = false
		
		
func _input_event(_camera: Camera3D, any_input_event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if any_input_event is InputEventMouse:
		if any_input_event is InputEventMouseButton and GameState.target_player and GameState.can_player_move_to_tile(GameState.target_player, self):
			GameState.target_player.position = self.global_position + Vector3(0, 1, 0)
			
func _on_selection_changed(new_player: Player):
	if new_player != null:
		var target_color = GameState.target_player.player_color
		material.albedo_color = Color(target_color.r, target_color.g, target_color.b, material.albedo_color.a)
