extends CSGBox3D

var target_player: AnimatableBody3D = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	position = Vector3(-999, -999, -999)
