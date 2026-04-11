extends Node3D
class_name VisualRope

const VISUAL_ROPE_RADIUS = 0.05
const VISUAL_ROPE_SIDES = 12

# There must be exactly 2 parts
var visual_parts: Array[VisualHalf] = []

class VisualHalf:
	var path: Path3D
	var poly: CSGPolygon3D
	var curve: Curve3D

	func _init(parent: Node, mat: Material, poly_shape: PackedVector2Array):
		path = Path3D.new()
		curve = Curve3D.new()
		path.curve = curve
		parent.add_child(path)
		
		poly = CSGPolygon3D.new()
		parent.add_child(poly)
		
		poly.mode = CSGPolygon3D.MODE_PATH
		poly.path_node = poly.get_path_to(path)
		poly.path_interval = 0.1
		poly.path_rotation = CSGPolygon3D.PATH_ROTATION_POLYGON
		poly.polygon = poly_shape
		poly.material = mat

	func update_points(points: Array[Node3D], origin: Node3D):
		curve.clear_points()
		for p in points:
			curve.add_point(origin.to_local(p.global_position))


func setup(material: Material):
	var shape = _generate_circle_polygon(VISUAL_ROPE_RADIUS, VISUAL_ROPE_SIDES)
	for i in range(2):
		visual_parts.append(VisualHalf.new(self, material, shape))

func update_rope(points: Array[Node3D], broken: bool):
	if points.size() < 4: 
		return
	
	var mid = points.size() / 2

	visual_parts[0].update_points(points.slice(0, mid if broken else mid + 1), self)
	visual_parts[1].update_points(points.slice(mid), self)

func _generate_circle_polygon(radius: float, sides: int) -> PackedVector2Array:
	var points = PackedVector2Array()
	for i in range(sides):
		var angle = i * TAU / sides
		points.push_back(Vector2(cos(angle), sin(angle)) * radius)
	return points
