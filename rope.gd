extends Node3D

class_name Rope

signal rope_broken()

@export var player_a_ref: RigidBody3D
@export var player_b_ref: RigidBody3D

@export var num_segments: int = 10

@export var show_debug_joints: bool = false:
	set(value):
		show_debug_joints = value
		_update_visibility()

var segment_distance: Vector3

var material: StandardMaterial3D
var strain_points: Array[Node3D]
var segments: Array[RigidBody3D] = []

var joint_positions: Array[Vector3]
var joint_rids: Array[RID]

# rope breaking logic
var expected_total_length: float
var time_under_strain: float = 0
var broken: bool = false

var visual_rope: VisualRope

func _init(joint_position: Array[Vector3] = [], segment_distance: Vector3 = Vector3.ZERO) -> void:
	add_to_group("history")
	self.joint_positions = joint_positions
	self.segment_distance = segment_distance

func _ready() -> void:
	material = StandardMaterial3D.new()
	material.albedo_color = Color('orange')
	strain_points = []

	if (joint_positions.size() == 0):
		var players_distance = player_b_ref.global_position - player_a_ref.global_position
		segment_distance = players_distance / num_segments
		for i in range(num_segments+1):
			joint_positions.push_back(player_a_ref.global_position + i * segment_distance)
		expected_total_length = players_distance.length()

	_make_rope.call_deferred(player_a_ref, player_b_ref, joint_positions)

func _make_rope(first_end_ref: RigidBody3D, second_end_ref: RigidBody3D, joint_positions: Array[Vector3]):
	global_position = Vector3.ZERO

	var segments_positions = []
	var segments_directions = []
	
	for i in range(1, joint_positions.size()):
		segments_positions.push_back((joint_positions[i-1] + joint_positions[i]) / 2)
		segments_directions.push_back((joint_positions[i] - joint_positions[i-1]).normalized())

	segments = []
	for i in range(segments_positions.size()):
		var segment = _make_rope_segment(segments_positions[i])
		segments.push_back(segment)
		segment.transform.basis = _make_alignment_basis(segments_directions[i])
		if (i > 0):
			segment.add_collision_exception_with(segments.back())
		add_child(segment)

	for i in range(segments.size()):
		_append_strain_points(segments[i])
	
	var anchor_offset_from_node_center = segment_distance.length() / 2
	for i in range(joint_positions.size()):
		var node_a: Node3D;
		var node_a_anchor = Vector3.ZERO;
		var node_b: Node3D;
		var node_b_anchor = Vector3.ZERO;
		if (i == 0):
			node_a = first_end_ref
			node_b = segments[i]
			node_b_anchor = Vector3.DOWN * anchor_offset_from_node_center
		elif (i == joint_positions.size()-1):
			node_a = segments[i-1]
			node_a_anchor = Vector3.UP * anchor_offset_from_node_center
			node_b = second_end_ref
		else:
			node_a = segments[i-1]
			node_a_anchor = Vector3.UP * anchor_offset_from_node_center
			node_b = segments[i]
			node_b_anchor = Vector3.DOWN * anchor_offset_from_node_center
		var joint_rid = PhysicsServer3D.joint_create();
		PhysicsServer3D.joint_make_generic_6dof(
			joint_rid,
			node_a.get_rid(),
			Transform3D(Basis.IDENTITY, node_a_anchor),
			node_b.get_rid(),
			Transform3D(Basis.IDENTITY, node_b_anchor)
		);
		_configure_6dof_joint(joint_rid)
		joint_rids.push_back(joint_rid)
	
	visual_rope = VisualRope.new()
	add_child(visual_rope)
	visual_rope.setup.call_deferred(material)
	_update_visibility.call_deferred()

func _make_alignment_basis(direction: Vector3) -> Basis:
	var rope_align_basis_y = direction
	var rope_align_basis_x = Vector3.UP.cross(rope_align_basis_y).normalized()
	var rope_align_basis_z = rope_align_basis_y.cross(rope_align_basis_x)
	return Basis(
		rope_align_basis_x,
		rope_align_basis_y,
		rope_align_basis_z
	)

func _make_rope_segment(position: Vector3) -> RigidBody3D:
	var segment = RigidBody3D.new()
	segment.continuous_cd = true
	segment.can_sleep = false
	
	var physics_mat = PhysicsMaterial.new()
	physics_mat.friction = 0.1
	segment.physics_material_override = physics_mat
	
	segment.mass = 1.0 / num_segments
	segment.position = position
	segment.collision_layer = 0
	segment.collision_mask = 4
	var mesh = CapsuleMesh.new()
	mesh.material = material
	mesh.radius = 0.05
	mesh.height = segment_distance.length() + 0.1
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.visible = false
	segment.add_child(mesh_instance)
	var collider = CollisionShape3D.new()
	var shape = CapsuleShape3D.new()
	shape.radius = segment_distance.length() / 2
	shape.height = segment_distance.length() + 0.2
	collider.shape = shape
	segment.add_child(collider)
	return segment

func _configure_6dof_joint(joint: RID):
	for axis in range(3):
		PhysicsServer3D.generic_6dof_joint_set_flag(joint, axis, PhysicsServer3D.G6DOF_JOINT_FLAG_ENABLE_LINEAR_LIMIT, true)
		PhysicsServer3D.generic_6dof_joint_set_param(joint, axis, PhysicsServer3D.G6DOF_JOINT_LINEAR_LOWER_LIMIT, 0.0)
		PhysicsServer3D.generic_6dof_joint_set_param(joint, axis, PhysicsServer3D.G6DOF_JOINT_LINEAR_UPPER_LIMIT, 0.0)


func _append_strain_points(target: RigidBody3D) -> void:
	var offset_from_center = segment_distance.length() / 2
	var sp1 = Node3D.new()
	target.add_child(sp1)
	sp1.position = Vector3.DOWN * offset_from_center
	strain_points.push_back(sp1)
	var sp2 = Node3D.new()
	target.add_child(sp2)
	sp2.position = Vector3.UP * offset_from_center
	strain_points.push_back(sp2)

func _process(delta: float) -> void:
	var length = real_length()
	if (length > expected_total_length + GameState.ROPE_ALLOWED_STRETCH):
		material.albedo_color = Color('red')
		time_under_strain += delta
		if (time_under_strain > 2):
			_break_rope()
	else:
		time_under_strain = 0
		material.albedo_color = Color('orange')

	visual_rope.update_rope(get_visual_rope_known_positions(), broken)

func _break_rope() -> void:
	if (!broken):
		GameState.rope_broken(self)
		var center = int(joint_rids.size() / 2)
		PhysicsServer3D.joint_clear(joint_rids[center])
		joint_rids.remove_at(center)
		broken = true

func _update_visibility() -> void:
	if visual_rope:
		visual_rope.visible = !show_debug_joints

	for segment in segments:
		for child in segment.get_children():
			child.visible = show_debug_joints

func real_length() -> float:
	var total = 0.0
	var prev_node = strain_points[0]
	for i in range(1, strain_points.size()):
		total += strain_points[i].global_position.distance_to(prev_node.global_position)
		prev_node = strain_points[i]
	return total

func get_joint_points() -> Array[Vector3]:
	var joint_points: Array[Vector3] = []
	joint_points.push_back(strain_points[0].global_position)
	for i in range(2, strain_points.size()-1, 2):
		joint_points.push_back((strain_points[i-1].global_position + strain_points[i].global_position) / 2)
	joint_points.push_back(strain_points[-1].global_position)
	return joint_points

func get_visual_rope_known_positions() -> Array[Vector3]:
	var points: Array[Vector3] = []
	for sp in strain_points:
		points.push_back(sp.global_position)
	return points

func snapshot() -> Variant:
	return {
		"joint_positions": get_joint_points(),
	}

func restore_from_snapshot(data: Variant):
	joint_positions = data.joint_positions
	for rid in joint_rids:
		PhysicsServer3D.free_rid(rid)
	joint_rids.clear()
	broken = false
	time_under_strain = 0
	strain_points.clear()
	visual_rope = null
	for child in get_children():
		child.free()
	_make_rope(player_a_ref, player_b_ref, joint_positions)
