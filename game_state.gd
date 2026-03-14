extends Node

signal selection_changed(new_player: Player)

var target_player: Player = null

func toggle_selection(player: Player):
	if target_player == player:
		_deselect_player()
	else:
		_select_player(player)

func _select_player(player: Player):
	if target_player == player: return
	
	target_player = player
	selection_changed.emit(target_player)

func _deselect_player():
	if target_player == null: return
	
	target_player = null
	selection_changed.emit(null)


func _target_is_reachable(player: Player, target: Node3D):
	"""
	checks if the target tile is reachable by the player;
	player should be able to move 1 block in any direction on flat surface, but not descend/climb diagonally
	"""
	var distance_to_target = round(player.global_position - target.global_position - Vector3(0, 1, 0))
	var abs_distance_to_target = abs(distance_to_target)
	if abs_distance_to_target.y > 1:
		return false
		
	if abs_distance_to_target.y == 1 and abs_distance_to_target.x + abs_distance_to_target.z > 1:
		return false
		
	if abs_distance_to_target.x == 1 and abs_distance_to_target.z == 1:
		# if the diagonal direction is blocked by a corner tile, we should disallow it
		# we're testing that with two rays projected perpendicularily
		var ray_direction_one = Vector3(-distance_to_target.x, 0, 0)
		var ray_direction_two = Vector3(0, 0, -distance_to_target.z)
		var intersections_one = player.get_world_3d().direct_space_state.intersect_ray(
			PhysicsRayQueryParameters3D.create(player.global_position, player.global_position + ray_direction_one)
		)
		var intersections_two = player.get_world_3d().direct_space_state.intersect_ray(
			PhysicsRayQueryParameters3D.create(player.global_position, player.global_position + ray_direction_two)
		)
		return intersections_one.is_empty() and intersections_two.is_empty()
		
	return abs_distance_to_target.x <= 1 and abs_distance_to_target.z <= 1


func can_player_move_to_tile(player: Player, tile: RockTile):
	if not tile.player_can_stand_on:
		return false

	if tile.has_standing_player():
		return false
		
	if not _target_is_reachable(player, tile):
		return false
	
	return true
	
func can_player_stack_onto_player(stacking_player: Player, base_player: Player):
	return stacking_player != base_player and _target_is_reachable(stacking_player, base_player)
