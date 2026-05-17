extends Node3D

@export var skip_intro_animation: bool = false
@export var intro_duration: float = 10.0

@onready var intro_path_follow: PathFollow3D = $IntroCameraPath/IntroCameraPathFollow
@onready var intro_camera: Node3D = $IntroCameraPath/IntroCameraPathFollow/IntroPhantomCamera

@onready var ui = $UI

func _ready() -> void:
	ui.play_pressed.connect(_start_intro)

func _start_intro() -> void:
	if skip_intro_animation or intro_path_follow == null or intro_camera == null:
		_end_intro()
		return

	intro_path_follow.progress_ratio = 0.0
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(intro_path_follow, "progress_ratio", 1.0, intro_duration)
	tween.finished.connect(_end_intro)

func _end_intro() -> void:
	if intro_camera:
		intro_camera.set("priority", 0)
	History.action_performed.emit()


func _on_win_area_body_entered(body: Node3D) -> void:
	if body is Player:
		ui.show_win()
