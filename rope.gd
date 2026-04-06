extends Node3D

class_name Rope

signal rope_broken()

@export var player_a_ref: RigidBody3D
@export var player_b_ref: RigidBody3D

@export var num_segments: int = 10

var segment_distance: Vector3

var material: StandardMaterial3D
var strain_points: Array[Node3D]

var joint_positions: Array[Vector3]

# rope breaking logic
var expected_total_length: float
var time_under_strain: float = 0
var central_joint: Generic6DOFJoint3D
var broken: bool = false

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
	var joints = []
	
	for i in range(1, joint_positions.size()):
		segments_positions.push_back((joint_positions[i-1] + joint_positions[i]) / 2)
		segments_directions.push_back((joint_positions[i] - joint_positions[i-1]).normalized())
	
	var segments = []
	for i in range(segments_positions.size()):
		var segment = _make_rope_segment(segments_positions[i])
		segments.push_back(segment)
		segment.transform.basis = _make_alignment_basis(segments_directions[i])
		if (i > 0):
			segment.add_collision_exception_with(segments.back())
		add_child(segment)
	
	for i in range(segments.size()):
		_append_strain_points(segments[i], joint_positions[i], joint_positions[i+1])
	
	for i in range(joint_positions.size()):
		var joint = _make_6dof_joint()
		joint.position = joint_positions[i]
		if (i == 0):
			joint.node_a = first_end_ref.get_path()
			joint.node_b = segments[i].get_path()
		elif (i == joint_positions.size()-1):
			joint.node_a = segments[i-1].get_path()
			joint.node_b = second_end_ref.get_path()
		else:
			joint.node_a = segments[i-1].get_path()
			joint.node_b = segments[i].get_path()
		if (i == joint_positions.size() / 2):
			central_joint = joint
		add_child(joint)

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
	segment.mass = 0.5 / num_segments
	segment.position = position
	segment.collision_layer = 8
	segment.collision_mask = 4
	var mesh = CapsuleMesh.new()
	mesh.material = material
	mesh.radius = 0.05
	mesh.height = segment_distance.length() + 0.1
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	segment.add_child(mesh_instance)
	var collider = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = 0.08
	shape.height = segment_distance.length()
	collider.shape = shape
	segment.add_child(collider)
	return segment

func _make_6dof_joint() -> Generic6DOFJoint3D:
	var joint = Generic6DOFJoint3D.new()
	joint.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, false)
	joint.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, false)
	joint.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, false)
	return joint

func _append_strain_points(target: RigidBody3D, position1: Vector3, position2: Vector3) -> void:
	var sp1 = Node3D.new()
	target.add_child(sp1)
	sp1.global_position = position1
	strain_points.push_back(sp1)
	var sp2 = Node3D.new()
	target.add_child(sp2)
	sp2.global_position = position2
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

func _break_rope() -> void:
	if (!broken):
		GameState.rope_broken(self)
		central_joint.queue_free()
		broken = true

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

func snapshot() -> Variant:
	return {
		"joint_positions": get_joint_points(),
	}

func restore_from_snapshot(data: Variant):
	joint_positions = data.joint_positions
	broken = false
	time_under_strain = 0
	strain_points.clear()
	for child in get_children():
		child.free()
	_make_rope(player_a_ref, player_b_ref, joint_positions)
