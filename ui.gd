extends CanvasLayer

signal play_pressed

@onready var blur_rect = $Blur
@onready var main_menu = $MainMenu
@onready var win_screen = $WinScreen

func _ready():
	win_screen.hide()
	win_screen.modulate.a = 0
	blur_rect.material.set_shader_parameter("blur_amount", 3.0)

func _on_play_button_pressed():
	play_pressed.emit()
	
	var tween = create_tween().set_parallel(true)
	
	tween.tween_property(blur_rect.material, "shader_parameter/blur_amount", 0.0, 1.0)
	tween.tween_property(main_menu, "modulate:a", 0.0, 1.0)
	
	tween.chain().tween_callback(main_menu.hide)
	tween.chain().tween_callback(blur_rect.hide)

func show_win():
	win_screen.show()
	blur_rect.show()
	
	var tween = create_tween().set_parallel(true)
	
	tween.tween_property(blur_rect.material, "shader_parameter/blur_amount", 3.0, 1.5)
	tween.tween_property(win_screen, "modulate:a", 1.0, 1.5)
