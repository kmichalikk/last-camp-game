extends RockBase

class_name BreakableRock

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

@export var break_duration: float = 0.5
@export var break_drop_distance: float = 2.0

var is_broken: bool = false
var _break_tween: Tween
var _interacting_players: Array[Player] = []

func _ready() -> void:
	super._ready()
	add_to_group("history")
	# Ensure the mesh has its own unique material so we can fade it
	var material = mesh_instance.get_active_material(0)
	if material:
		mesh_instance.set_surface_override_material(0, material.duplicate())

func on_player_stand_started(player: Player) -> void:
	if not _interacting_players.has(player):
		_interacting_players.append(player)

func on_player_stand_ended(player: Player) -> void:
	_interacting_players.erase(player)
	break_now()

func on_player_grab_started(player: Player, _normal: Vector3) -> void:
	if not _interacting_players.has(player):
		_interacting_players.append(player)

func on_player_grab_ended(player: Player, _normal: Vector3) -> void:
	_interacting_players.erase(player)
	break_now()

func break_now() -> void:
	if is_broken:
		return

	is_broken = true

	# Force all remaining players using this rock to detach and fall
	var players_to_detach = _interacting_players.duplicate()
	_interacting_players.clear()
	for player in players_to_detach:
		player.force_detach(self)

	# Disable gameplay collision immediately
	collision_layer = 0
	set_actions_enabled(false)

	if _break_tween and _break_tween.is_valid():
		_break_tween.kill()

	_break_tween = create_tween()
	_break_tween.set_parallel(true)

	# Animate mesh downward
	_break_tween.tween_property(mesh_instance, "position:y", -break_drop_distance, break_duration)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_IN)

	# Fade out
	var material = mesh_instance.get_surface_override_material(0) as StandardMaterial3D
	if material:
		_break_tween.tween_property(material, "albedo_color:a", 0.0, break_duration)

	_break_tween.set_parallel(false)
	_break_tween.tween_callback(func(): mesh_instance.visible = false)

func snapshot() -> Variant:
	var material = mesh_instance.get_surface_override_material(0) as StandardMaterial3D
	var player_paths = []
	for player in _interacting_players:
		if is_instance_valid(player):
			player_paths.append(player.get_path())

	return {
		"is_broken": is_broken,
		"actions_enabled": actions_enabled,
		"collision_layer": collision_layer,
		"mesh_position": mesh_instance.position,
		"mesh_visible": mesh_instance.visible,
		"material_alpha": material.albedo_color.a if material else 1.0,
		"interacting_players": player_paths
	}

func restore_from_snapshot(data: Variant):
	if _break_tween and _break_tween.is_valid():
		_break_tween.kill()

	is_broken = data.is_broken
	set_actions_enabled(data.actions_enabled)
	collision_layer = data.collision_layer
	mesh_instance.position = data.mesh_position
	mesh_instance.visible = data.mesh_visible

	_interacting_players.clear()
	for path in data.get("interacting_players", []):
		var node = get_node_or_null(path)
		if node is Player:
			_interacting_players.append(node)

	var material = mesh_instance.get_surface_override_material(0) as StandardMaterial3D
	if material:
		material.albedo_color.a = data.material_alpha
