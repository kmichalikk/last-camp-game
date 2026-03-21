extends StaticBody3D

class_name RockBase

@export var can_stand: bool = false
@export var can_grab_north: bool = false
@export var can_grab_south: bool = false
@export var can_grab_west: bool = false
@export var can_grab_east: bool = false 

var tile_stand_highlight: MeshInstance3D = null
var tile_grab_north_highlight: MeshInstance3D = null
var tile_grab_south_highlight: MeshInstance3D = null
var tile_grab_west_highlight: MeshInstance3D = null
var tile_grab_east_highlight: MeshInstance3D = null

var top_occupancy_zone: Area3D = null
var material: StandardMaterial3D = null

func _ready() -> void:
	GameState.selection_changed.connect(_on_selection_changed)
	material = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(1, 1, 1, 0.5)
	add_child(_create_helper_collision_shape(Vector3(1, 1, 1), Vector3.ZERO))
	if can_stand:
		_setup_stand_colliders()
	if can_grab_north:
		_setup_grab_action(Vector3(0.004, 1, 1), Vector3(0.502, 0, 0), &"tile_grab_north_highlight", Vector3(1, 0, 0))
	if can_grab_south:
		_setup_grab_action(Vector3(0.004, 1, 1), Vector3(-0.502, 0, 0), &"tile_grab_south_highlight", Vector3(-1, 0, 0))
	if can_grab_east:
		_setup_grab_action(Vector3(1, 1, 0.004), Vector3(0, 0, 0.502), &"tile_grab_east_highlight", Vector3(0, 0, 1))
	if can_grab_west:
		_setup_grab_action(Vector3(1, 1, 0.004), Vector3(0, 0, -0.502), &"tile_grab_west_highlight", Vector3(0, 0, -1))
		
#region Stand action

func _setup_stand_colliders():
	tile_stand_highlight = _create_helper_mesh_instance(Vector3(1, 0.004, 1), Vector3(0, 0.502, 0))
	var tile_stand_area = Area3D.new()
	tile_stand_area.add_child(tile_stand_highlight)
	tile_stand_area.add_child(_create_helper_collision_shape(Vector3(1, 0.004, 1), Vector3(0, 0.502, 0)))
	tile_stand_area.mouse_entered.connect(Callable(self, &"_stand_mouse_enter"))
	tile_stand_area.mouse_exited.connect(Callable(self, &"_stand_mouse_exit"))
	tile_stand_area.input_event.connect(Callable(self, &"_stand_input_event"))
	add_child(tile_stand_area)
	
	top_occupancy_zone = Area3D.new()
	top_occupancy_zone.collision_mask = 2
	top_occupancy_zone.input_ray_pickable = false
	top_occupancy_zone.add_child(_create_helper_mesh_instance(Vector3(0.9, 0.9, 0.9), Vector3(0, 1, 0)))
	top_occupancy_zone.add_child(_create_helper_collision_shape(Vector3(0.9, 0.9, 0.9), Vector3(0, 1, 0)))
	add_child(top_occupancy_zone)

func _stand_input_event(_camera: Camera3D, any_input_event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if any_input_event is InputEventMouse:
		if any_input_event is InputEventMouseButton and any_input_event.is_pressed() and GameState.target_player and GameState.can_player_move_to_tile(GameState.target_player, self):
			GameState.target_player.stand_on(self)
			if get_viewport():
				get_viewport().set_input_as_handled()

func _stand_mouse_enter() -> void:
	if GameState.target_player != null and GameState.can_player_move_to_tile(GameState.target_player, self):
		tile_stand_highlight.visible = true

func _stand_mouse_exit() -> void:
	tile_stand_highlight.visible = false
	
#endregion

#region Grab action

func _setup_grab_action(position: Vector3, size: Vector3, target_mesh_var: StringName, normal: Vector3):
	self[target_mesh_var] = _create_helper_mesh_instance(position, size)
	var tile_grab_area = Area3D.new()
	tile_grab_area.add_child(self[target_mesh_var])
	tile_grab_area.add_child(_create_helper_collision_shape(position, size))
	tile_grab_area.mouse_entered.connect(_make_grab_mouse_enter(target_mesh_var, self.global_transform.basis * normal))
	tile_grab_area.mouse_exited.connect(_make_grab_mouse_exit(target_mesh_var))
	tile_grab_area.input_event.connect(Callable(self, &"_grab_input_event"))
	add_child(tile_grab_area)

func _grab_input_event(_camera: Camera3D, any_input_event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if any_input_event is InputEventMouse:
		if any_input_event is InputEventMouseButton and any_input_event.is_pressed() and GameState.target_player and GameState.can_player_grab_tile(GameState.target_player, self, _normal):
			GameState.target_player.grab(self, _normal)
			if get_viewport():
				get_viewport().set_input_as_handled()

func _make_grab_mouse_enter(target_mesh_var: StringName, normal: Vector3) -> Callable:
	return func():
		if GameState.target_player != null and GameState.can_player_grab_tile(GameState.target_player, self, normal):
			self[target_mesh_var].visible = true

func _make_grab_mouse_exit(target_mesh_var: StringName) -> Callable:
	return func():
		self[target_mesh_var].visible = false
	
#endregion

func _create_helper_mesh_instance(size: Vector3, position: Vector3) -> MeshInstance3D:
	var instance = MeshInstance3D.new()
	instance.mesh = BoxMesh.new()
	instance.mesh.size = size
	instance.position = position
	instance.mesh.material = self.material
	instance.visible = false
	return instance
	
func _create_helper_collision_shape(size: Vector3, position: Vector3) -> CollisionShape3D:
	var collision_shape = CollisionShape3D.new()
	collision_shape.shape = BoxShape3D.new()
	collision_shape.shape.size = size
	collision_shape.position = position
	return collision_shape
		
func has_standing_player() -> bool:
	return can_stand and top_occupancy_zone.has_overlapping_bodies()
	
func _on_selection_changed(new_player: Player):
	if new_player != null:
		var target_color = GameState.target_player.player_color
		self.material.albedo_color = Color(target_color.r, target_color.g, target_color.b, material.albedo_color.a)
