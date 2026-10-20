extends Control

@onready var video_stream_player: VideoStreamPlayer = $VideoStreamPlayer
@onready var v_box_container: VBoxContainer = $VBoxContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	v_box_container.visible = false
	await get_tree().create_timer(1.5).timeout
	v_box_container.visible = true


func _on_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Menu/Menu.tscn")


func _on_again_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Gameplay/Gameplay.tscn")
