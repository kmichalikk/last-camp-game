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
	
func _physics_process(delta: float) -> void:
	# Epic trick to attach player to the tile based on position in editor
	if get_parent() == get_tree().current_scene and ground_ray.is_colliding():
		stand_on(ground_ray.get_collider())

func stand_on(new_parent: Node3D):
	if get_parent() != new_parent:
		reparent(new_parent, false)
		position = Vector3.UP

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
			
