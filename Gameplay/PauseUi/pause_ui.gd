extends Control

@onready var flicker_check: CheckButton = $Settings/VBoxContainer/FlickerCheck
@onready var controls_ui_check: CheckButton = $Settings/VBoxContainer/ControlsUiCheck
@export var main_ui: MainUi
@export var tablet_ui: Control

var main_ui_return: bool = false
var tablet_ui_return: bool = false

signal game_resumed
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _resume_game() -> void:
	get_tree().paused = false
	visible = false
	main_ui.visible = main_ui_return
	tablet_ui.visible = tablet_ui_return
	game_resumed.emit()

func _set_pause() -> void:
	get_tree().paused = true
	visible = true
	flicker_check.button_pressed = MainManager.isFlickerEnabled
	controls_ui_check.button_pressed = MainManager.isControlsUiEnabled
	main_ui_return = main_ui.visible
	tablet_ui_return = tablet_ui.visible
	main_ui.visible = false
	tablet_ui.visible = false
	

func _on_resume_button_pressed() -> void:
	_resume_game()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("back"):
		if get_tree().paused:
			_resume_game()
		else:
			_set_pause()
		


func _on_flicker_check_toggled(toggled_on: bool) -> void:
	MainManager.isFlickerEnabled = toggled_on
	MainManager.savegame()


func _on_controls_ui_check_toggled(toggled_on: bool) -> void:
	MainManager.isControlsUiEnabled = toggled_on
	MainManager.savegame()


func _on_button_pressed() -> void:
	_resume_game()
	get_tree().change_scene_to_file("res://Menu/Menu.tscn")


func _on_main_ui_btn_pause() -> void:
	_set_pause()
