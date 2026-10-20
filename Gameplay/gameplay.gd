extends Node3D

enum CameraDirection { LEFT, MIDDLE, RIGHT }

@export var camera: MainCamera

@export_range(5.0, 90.0, 1.0) var turn_angle_deg: float = 45.0
@export_range(0.05, 1.0, 0.05) var turn_duration: float = 0.3

@onready var main_ui: MainUi = $MainUi


var current_direction: CameraDirection = CameraDirection.MIDDLE
var _tween: Tween
var is_tablet_opened: bool



func _ready() -> void:
	MainManager.reset()
	# Если ссылка не задана в инспекторе, ищем дочернюю камеру автоматически
	if not camera:
		camera = $Camera3D
	
	# Начальная позиция — середина (0 градусов)
	camera.rotation.y = 0.0

func turn_camera_left() -> void:
	# Если мы уже в крайнем левом положении, прерываем функцию.
	# Это предотвратит ложные срабатывания закрытия планшета и сброс интерфейса.
	if current_direction == CameraDirection.LEFT:
		return 
		
	camera.tablet_open(false)
	is_tablet_opened = false
	
	match current_direction:
		CameraDirection.RIGHT:
			_set_camera_state(CameraDirection.MIDDLE)
		CameraDirection.MIDDLE:
			_set_camera_state(CameraDirection.LEFT)


func turn_camera_right() -> void:
	# То же самое для правого положения
	if current_direction == CameraDirection.RIGHT:
		return 
		
	camera.tablet_open(false)
	is_tablet_opened = false
	
	match current_direction:
		CameraDirection.LEFT:
			_set_camera_state(CameraDirection.MIDDLE)
		CameraDirection.MIDDLE:
			_set_camera_state(CameraDirection.RIGHT)
			

func _set_camera_state(new_direction: CameraDirection) -> void:
	current_direction = new_direction
	
	# Определяем точный целевой угол в радианах для каждого состояния
	var target_angle_rad: float = 0.0
	match current_direction:
		CameraDirection.LEFT:
			target_angle_rad = deg_to_rad(turn_angle_deg)
			main_ui.lbutton_visible(false)
			main_ui.midbutton_visible(false)
		CameraDirection.MIDDLE:
			target_angle_rad = 0.0
			main_ui.lbutton_visible(true)
			main_ui.rbutton_visible(true)
			main_ui.midbutton_visible(true)
		CameraDirection.RIGHT:
			target_angle_rad = deg_to_rad(-turn_angle_deg)
			main_ui.rbutton_visible(false)
			main_ui.midbutton_visible(false)
			
	_animate_camera(target_angle_rad)

func _animate_camera(target_rotation_y: float) -> void:
	if _tween and _tween.is_running():
		_tween.kill()
		
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(camera, "rotation:y", target_rotation_y, turn_duration)


func _on_main_ui_btn_turn_left() -> void:
	turn_camera_left()


func _on_main_ui_btn_turn_right() -> void:
	turn_camera_right()
	

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("left"):
		turn_camera_left()
	elif event.is_action_pressed("right"):
		turn_camera_right()
	elif event.is_action_pressed("act"):
		match current_direction:
			CameraDirection.LEFT:
				pass
			CameraDirection.MIDDLE:
				if MainManager.power > 0:
					camera.tablet_open(not is_tablet_opened)
					is_tablet_opened = not is_tablet_opened
			CameraDirection.RIGHT:
				pass
				


func _on_main_ui_btn_use() -> void:
	# Дополнительная защита: планшет по кнопке может открыться 
	# ТОЛЬКО если мы смотрим прямо (MIDDLE)
	if current_direction == CameraDirection.MIDDLE and MainManager.power > 0:
		camera.tablet_open(not is_tablet_opened)
		is_tablet_opened = not is_tablet_opened


func _on_tablet_ui_close_tablet() -> void:
	camera.tablet_open(false)
	is_tablet_opened = false


func _on_game_manager_powerdown() -> void:
	camera.tablet_open(false)
	is_tablet_opened = false


func _on_main_ui_btn_pause() -> void:
	pass # Replace with function body.
