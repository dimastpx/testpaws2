extends Control

@onready var timer_text: Label = $TimerText

var first_text: String = "6:00 АМ"
var second_text: String = "6 00 АМ"
var is_first: bool = true

func _ready() -> void:
	$MenuButton.visible = false
	timer_text.text = first_text

	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.timeout.connect(_on_timer_timeout)
	timer.autostart = true
	add_child(timer)
	await get_tree().create_timer(1.5).timeout
	$MenuButton.visible = true

func _on_timer_timeout() -> void:
	is_first = not is_first

	if is_first:
		timer_text.text = first_text
	else:
		timer_text.text = second_text


func _on_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Menu/Menu.tscn")
