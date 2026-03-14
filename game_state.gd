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

func can_player_move_to_tile(player: Player, tile: RockTile):
	if not tile.player_can_stand_on:
		return false

	if tile.has_standing_player():
		return false
		
	# Additional constraints in the future will go here.
	
	return true
	
func can_player_stack_onto_player(stacked_player: Player, base_player: Player):
	return stacked_player != base_player
