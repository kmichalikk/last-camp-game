extends Node3D

const SPRITE_NUM = 20
const SPRITE_MAX_LIFE = 2.5
const SPRITE_PEAK_SIZE_TIME = 1.5

var sprites: Array[Sprite3D] = []
var sprite_life: Array[float] = []
var sprite_grow_time: float

func _init() -> void:
	sprite_grow_time = SPRITE_MAX_LIFE - SPRITE_PEAK_SIZE_TIME
	for i in range(SPRITE_NUM):
		var sprite = Sprite3D.new()
		sprite.billboard = true
		sprite.centered = true
		sprite.pixel_size = 0.4
		sprite.texture = load("res://assets/fire.png")
		sprites.push_back(sprite)
		self.add_child(sprite)
		sprite_life.push_back(randf() * SPRITE_MAX_LIFE)


func _process(delta: float) -> void:
	var growing: float
	var shrinking: float
	for i in range(len(sprites)):
		sprite_life[i] -= delta
		if sprite_life[i] < 0:
			sprites[i].position = Vector3(randf() - 0.5, 0.5 + randf(), randf() - 0.5) * 2
			sprites[i].scale = Vector3.ZERO
			sprite_life[i] = SPRITE_MAX_LIFE
		sprites[i].position.y += delta * 2
		growing = 1.0 - max(0, sprite_life[i] - SPRITE_PEAK_SIZE_TIME) / sprite_grow_time
		shrinking = 1.0 - max(0, SPRITE_PEAK_SIZE_TIME - sprite_life[i]) / SPRITE_PEAK_SIZE_TIME
		sprites[i].scale = Vector3.ONE * (growing + shrinking) * 0.1

		
