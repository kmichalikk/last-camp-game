extends AnimatableBody3D

class_name Player

@onready var material: StandardMaterial3D = $PlayerCSG.material_override

@onready var stack_highlight: Area3D = $PlayerStackHighlight
@onready var stack_hightlight_csg: CSGCylinder3D = $PlayerStackHighlight/PlayerStackHighlightCSG
@onready var stack_highlight_material: StandardMaterial3D = $PlayerStackHighlight/PlayerStackHighlightCSG.material_override
@onready var ground_ray: RayCast3D = $GroundRay

@export var player_color: Color = "498eff"

func _ready() -> void:
	material.albedo_color = player_color
	material.emission = player_color
	material.emission_enabled = false
	
	GameState.selection_changed.connect(_on_selection_changed)
	stack_highlight.mouse_entered.connect(_on_player_stack_highlight_mouse_entered)
	stack_highlight.mouse_exited.connect(_on_player_stack_highlight_mouse_exited)
	stack_highlight.input_event.connect(_on_player_stack_highlight_input_event)
	
	call_deferred("_do_initial_placement")

func _do_initial_placement() -> void:
	# Epic trick to attach player to the tile based on position in editor
	if get_parent() == get_tree().current_scene:
		ground_ray.force_raycast_update()
		if ground_ray.is_colliding():
			stand_on(ground_ray.get_collider())

func stand_on(new_parent: Node3D):
	if get_parent() != new_parent:
		var blocked_player = _find_lowest_blocked_player_in_stack(new_parent)
		
		if blocked_player != null:
			blocked_player._drop_in_place()
			
		reparent(new_parent, false)
		position = Vector3.UP

func _find_lowest_blocked_player_in_stack(new_parent: Node3D) -> Player:
	var target_global_pos = new_parent.global_position + Vector3.UP
	var step_offset = target_global_pos - self.global_position
	
	var space_state = get_world_3d().direct_space_state
	var current_child = _get_child_player()
	
	while current_child != null:
		var child_target_pos = current_child.global_position + step_offset
		
		var query = PhysicsShapeQueryParameters3D.new()
		var shape = SphereShape3D.new()
		shape.radius = 0.4
		query.shape = shape
		query.transform = Transform3D(Basis(), child_target_pos)
		query.collision_mask = 4
		
		var results = space_state.intersect_shape(query)
		if not results.is_empty():
			return current_child
			
		current_child = current_child._get_child_player()
		
	return null

func _drop_in_place():
	var space_state = get_world_3d().direct_space_state
	# Cast from slightly above to ensure we don't catch inside the current floor
	var query = PhysicsRayQueryParameters3D.create(global_position + (Vector3.UP * 0.1), global_position + (Vector3.DOWN * 50.0), 6)
	
	var excludes = []
	
	# Exclude self and all children from the ray
	var p = self
	while p != null:
		excludes.append(p.get_rid())
		p = p._get_child_player()
		
	# Exclude all moving ancestors beneath us because they are about to leave, we want to hit the Tile they are standing on.
	var ancestor = get_parent()
	while ancestor != null and ancestor is Player:
		excludes.append(ancestor.get_rid())
		ancestor = ancestor.get_parent()
		
	query.exclude = excludes
	
	var result = space_state.intersect_ray(query)
	if result and result.collider is Node3D:
		reparent(result.collider, false)
		position = Vector3.UP

func _get_child_player() -> Player:
	for child in get_children():
		if child is Player:
			return child
	return null

func _input_event(_camera: Camera3D, any_input_event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if any_input_event is InputEventMouseButton and any_input_event.is_pressed():
		GameState.toggle_selection(self)

func _on_selection_changed(new_player: Player):
	material.emission_enabled = new_player == self
	if new_player != null:
		var target_color = new_player.player_color
		stack_highlight_material.albedo_color = Color(target_color.r, target_color.g, target_color.b, stack_highlight_material.albedo_color.a)

func _on_player_stack_highlight_mouse_entered() -> void:
	if GameState.target_player != null and GameState.can_player_stack_onto_player(GameState.target_player, self):
		stack_hightlight_csg.visible = true

func _on_player_stack_highlight_mouse_exited() -> void:
	stack_hightlight_csg.visible = false

func _on_player_stack_highlight_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and GameState.target_player != null:
		var stacking_player = GameState.target_player
		if stacking_player != null and GameState.can_player_stack_onto_player(stacking_player, self):
			stacking_player.stand_on(self)
			if get_viewport():
				get_viewport().set_input_as_handled()
			return
	
	# Fallback to regular input event
	_input_event(camera, event, event_position, normal, 0)
