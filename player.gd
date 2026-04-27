extends RigidBody3D

class_name Player

@onready var material: StandardMaterial3D = $PlayerCSG.material_override

@onready var stack_highlight: Area3D = $PlayerStackHighlight
@onready var stack_hightlight_csg: CSGCylinder3D = $PlayerStackHighlight/PlayerStackHighlightCSG
@onready var stack_highlight_material: StandardMaterial3D = $PlayerStackHighlight/PlayerStackHighlightCSG.material_override
@onready var grab_indicator: Sprite3D = $GrabIndicator
@onready var snap_to_floor_detector: Area3D = $SnapToFloorDetector
@onready var player_has_space_detector: ShapeCast3D = $PlayerHasSpaceDetector

@export var player_color: Color = "498eff"
@export var attached_ropes: Array[Rope]

var player_above: Player = null
var player_below: Player = null

var is_grabbing: bool = false
var is_fixed: bool = false

var _move_tween: Tween
var target_position: Vector3 = Vector3.ZERO

func _ready() -> void:
	add_to_group("history")
	
	material.albedo_color = player_color
	material.emission = player_color
	material.emission_enabled = false

	snap_to_floor_detector.connect("body_entered", _snap_to_floor_triggered)

	GameState.game_over.connect(_on_game_over)
	GameState.selection_changed.connect(_on_selection_changed)
	stack_highlight.mouse_entered.connect(_on_player_stack_highlight_mouse_entered)
	stack_highlight.mouse_exited.connect(_on_player_stack_highlight_mouse_exited)
	stack_highlight.input_event.connect(_on_player_stack_highlight_input_event)

func _process(delta: float) -> void:
	grab_indicator.position = self.global_position

func _physics_process(delta: float) -> void:
	# reset rotation so the player is always upright
	transform.basis = Basis()

func _snap_to_floor_triggered(body: Node3D) -> void:
	if is_fixed or body == self or GameState.is_game_over:
		return

	_snap_to_floor_if_possible(body)

func _snap_to_floor_if_possible(body: Node3D) -> bool:
	if ((body is RockBase and body.can_stand) or (body is Player and body.is_fixed)) \
	and body.global_position.distance_squared_to(self.global_position) < GameState.PLAYER_SNAP_TO_FLOOR_DISTANCE:
		stand_on(body)
		return true
	return false

func stand_on(target: Node3D):
	if is_grabbing:
		return
	if (target is Player):
		target.player_above = self
		player_below = target
		target_position = target.target_position + Vector3.UP
		_move_to_position_smoothly(target_position)
	else:
		if player_below:
			player_below.player_above = null
			player_below = null
		target_position = target.global_position + Vector3.UP
		_move_to_position_smoothly(target_position)
	
	if (player_above != null):
		if (!player_above.is_grabbing and GameState.can_player_stack_onto_player(player_above, self)):
			player_above.stand_on(self)
		else:
			detach_player_above()
	is_fixed = true
	History.action_performed.emit()

func detach_player_above():
	if (player_above == null):
		return
	if (!player_above.is_grabbing):
		player_above.freeze = false
		player_above.is_fixed = false
		player_above.detach_player_above()
	player_above.player_below = null
	player_above = null

func grab(block: Node3D, normal: Vector3) -> void:
	if is_grabbing:
		grab_indicator.visible = false
		is_grabbing = false
		is_fixed = false
		freeze = false
		for body in snap_to_floor_detector.get_overlapping_bodies():
			if _snap_to_floor_if_possible(body):
				return
	else:
		print(block, normal)
		grab_indicator.visible = true
		
		_move_to_position_smoothly(block.global_position + normal)
		
		is_grabbing = true
		is_fixed = true

func ragdoll() -> void:
	is_fixed = false
	is_grabbing = false
	grab_indicator.visible = false
	freeze = false
	if player_below:
		player_below.detach_player_above()
	else:
		detach_player_above()

func jump_off(tile: Node3D, normal: Vector3) -> void:
	if is_grabbing or !is_fixed or player_below != null:
		return
		
	_move_to_position_smoothly(tile.global_position + normal + 0.5 * Vector3.UP)
	await _move_tween.finished
	
	detach_player_above()
	is_fixed = false
	freeze = false

func _move_to_position_smoothly(target_pos: Vector3, duration: float = 0.2) -> void:
	if _move_tween and _move_tween.is_valid():
		_move_tween.kill()

	freeze = true 
	
	_move_tween = create_tween()
	_move_tween.tween_property(self, "global_position", target_pos, duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

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

func _on_game_over():
	is_grabbing = false
	grab_indicator.visible = false
	is_fixed = false
	freeze = false

func snapshot() -> Variant:
	return {
		"player_above": player_above,
		"player_below": player_below,
		"is_grabbing": is_grabbing,
		"is_fixed": is_fixed,
		"global_transform": global_transform
	}

func restore_from_snapshot(data: Variant):
	player_above = data.player_above
	player_below = data.player_below
	is_grabbing = data.is_grabbing
	grab_indicator.visible = is_grabbing
	is_fixed = data.is_fixed
	freeze = is_fixed
	global_transform = data.global_transform
