class_name MainUi
extends Control

signal btn_turn_left
signal btn_turn_right
signal btn_use
signal btn_pause

@onready var llabel: Label = $LButton/Label
@onready var rlabel: Label = $RButton/Label
@onready var mlabel: Label = $MidButton/Label
@onready var power_progress_bar: ProgressBar = $PowerInfo/Power/ProgressBar
@onready var consumption: Label = $PowerInfo/Consumption

var is_powerdown: bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update()

func update() -> void:
	if not MainManager.isControlsUiEnabled:
		llabel.visible = false
		rlabel.visible = false
		mlabel.visible = false
	else:
		llabel.visible = true
		rlabel.visible = true
		mlabel.visible = true


func _on_l_button_pressed() -> void:
	btn_turn_left.emit()


func _on_l_button_mouse_entered() -> void:
	llabel.add_theme_color_override("font_color", Color.DARK_GRAY)


func _on_l_button_mouse_exited() -> void:
	llabel.add_theme_color_override("font_color", Color.WHITE)
	


func _on_r_button_pressed() -> void:
	btn_turn_right.emit()
	


func _on_r_button_mouse_entered() -> void:
	rlabel.add_theme_color_override("font_color", Color.DARK_GRAY)


func _on_r_button_mouse_exited() -> void:
	rlabel.add_theme_color_override("font_color", Color.WHITE)




func _on_mid_button_pressed() -> void:
	btn_use.emit()


func _on_mid_button_mouse_entered() -> void:
	mlabel.add_theme_color_override("font_color", Color.DARK_GRAY)


func _on_mid_button_mouse_exited() -> void:
	mlabel.add_theme_color_override("font_color", Color.WHITE)



func lbutton_visible(on: bool) -> void:
	if MainManager.isControlsUiEnabled:
		$LButton.visible = on
	
func rbutton_visible(on: bool) -> void:
	if MainManager.isControlsUiEnabled:
		$RButton.visible = on
	
func midbutton_visible(on: bool) -> void:
	if MainManager.isControlsUiEnabled:
		$MidButton.visible = on
	


func _on_pause_ui_game_resumed() -> void:
	update()



func _on_game_manager_update_power(value: float) -> void:
	if power_progress_bar:
		power_progress_bar.value = clamp(value, 0, 100)


func _on_camera_3d_main_ui_tablet_visible(on: bool) -> void:
	if MainManager.isControlsUiEnabled:
		$MidButton.visible = on
		$PowerInfo.visible = on


func _on_game_manager_update_consumption(value: float) -> void:
	if consumption and not is_powerdown:
		var str_value = "0.5" if value == 0.5 else str(int(value))
		consumption.text = "Потребление: " + str_value


func _on_game_manager_powerdown() -> void:
	is_powerdown = true
	consumption.text = "Потребление: 0"


func _on_pause_button_pressed() -> void:
	btn_pause.emit()


func _on_game_manager_time_updated(hour: int) -> void:
		$Time.text = str(hour) + " AM"
