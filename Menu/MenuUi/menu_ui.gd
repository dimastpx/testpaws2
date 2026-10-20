extends Control

@onready var difficulty_selector: OptionButton = $ColorRect/VBoxContainer/DifficultySelector
@onready var flicker_check: CheckButton = $ColorRect/VBoxContainer/FlickerCheck
@onready var controls_ui_check: CheckButton = $ColorRect/VBoxContainer/ControlsUiCheck
@onready var flicker_selector: OptionButton = $ColorRect/VBoxContainer/FlickerSelector


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	difficulty_selector.select(MainManager.difficulty)
	flicker_check.button_pressed = MainManager.isFlickerEnabled
	controls_ui_check.button_pressed = MainManager.isControlsUiEnabled
	flicker_selector.select(MainManager.flicker_type)
	flicker_selector.visible = MainManager.isFlickerEnabled


func _on_difficulty_selector_item_selected(index: int) -> void:
	MainManager.difficulty = index
	MainManager.savegame()


func _on_flicker_check_toggled(toggled_on: bool) -> void:
	MainManager.isFlickerEnabled = toggled_on
	flicker_selector.visible = toggled_on
	MainManager.savegame()


func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Gameplay/Gameplay.tscn")


func _on_controls_ui_check_toggled(toggled_on: bool) -> void:
	MainManager.isControlsUiEnabled = toggled_on
	MainManager.savegame()


func _on_flicker_selector_item_selected(index: int) -> void:
	MainManager.flicker_type = index
	MainManager.savegame()
