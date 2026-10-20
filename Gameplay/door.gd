extends Node3D

signal change_door(close: bool)
signal light_door(on: bool)

var light_on: bool = false
var is_powerdown: bool = false

@export var is_left: bool
@export var cool_object: MeshInstance3D
@export var bars_object: MeshInstance3D
@export var tofy_object: MeshInstance3D

# --- Настройки заслонки (DoorFlap) ---
const flap_open_y: float = -3.788  # Позиция Y открытой двери (настройте в инспекторе)
const flap_closed_y: float = -0.31 # Позиция Y закрытой двери (настройте в инспекторе)
const flap_speed: float = 0.25   # Время закрытия/открытия в секундах

@onready var spot_light_3d: SpotLight3D = $SpotLight3D
@onready var light_button: MeshInstance3D = $Buttons/LightButton
@onready var door_button: MeshInstance3D = $Buttons/DoorButton

@onready var light_area: Area3D = $Buttons/LightButton/Area3D
@onready var door_area: Area3D = $Buttons/DoorButton/Area3D
@onready var door_flap: Node3D = $DoorFlap 

# Корневая нода Gameplay (скрипт gameplay.gd) — в ней хранится current_direction
@onready var camera_rig: Node = get_parent()

# Значения совпадают с enum CameraDirection в gameplay.gd
const CAM_LEFT: int = 0
const CAM_RIGHT: int = 2


func _ready() -> void:
	spot_light_3d.visible = false
	door_flap.position.y = flap_open_y
	
	light_area.input_event.connect(_on_light_event)
	door_area.input_event.connect(_on_door_event)
	
	# Безусловно прячем все объекты при старте сцены, чтобы никто не висел в воздухе
	if bars_object: bars_object.visible = false
	if cool_object: cool_object.visible = false
	if tofy_object: tofy_object.visible = false
	if has_node("MeshInstance3D"): $MeshInstance3D.visible = false


func _process(_delta: float) -> void:
	_update_enemy_visibility()


# --- Железобетонная логика отображения врагов ---
func _update_enemy_visibility() -> void:
	# 1. Если свет выключен или нет энергии — ГАРАНТИРОВАННО прячем вообще всё
	if not light_on or is_powerdown:
		if bars_object: bars_object.visible = false
		if cool_object: cool_object.visible = false
		if tofy_object: tofy_object.visible = false
		
		# Если у тебя в сцене осталась тестовая заглушка, её тоже убираем
		if has_node("MeshInstance3D"):
			$MeshInstance3D.visible = false
		return
		
	# 2. Если свет горит, показываем только тех врагов, которые стоят у этой двери
	if is_left:
		# Проверяем, стоит ли Барс у левой двери
		var is_bars_here = (MainManager.where_bars == GameManager.Where.LDOOR)
		
		if bars_object: bars_object.visible = is_bars_here
		# Тестовая модель тоже покажет, что враг здесь
		if has_node("MeshInstance3D"): $MeshInstance3D.visible = is_bars_here
	else:
		# Проверяем Кулдога и Тофи у правой двери
		var is_cool_here = (MainManager.where_cool == GameManager.Where.RDOOR)
		var is_tofy_here = (MainManager.where_tofy == GameManager.Where.RDOOR)
		
		if cool_object: cool_object.visible = is_cool_here
		if tofy_object: tofy_object.visible = is_tofy_here


# --- Ввод с клавиатуры/геймпада (Area3D.input_event реагирует только на мышь) ---
func _unhandled_input(event: InputEvent) -> void:
	if not _is_player_looking_at_me():
		return
	if event.is_action_pressed("flashlight"):
		_toggle_light()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("door"):
		_toggle_door()
		get_viewport().set_input_as_handled()


# Левая дверь реагирует, только когда камера повёрнута влево, правая — вправо
func _is_player_looking_at_me() -> bool:
	if camera_rig == null or not "current_direction" in camera_rig:
		return false
	var dir: int = camera_rig.current_direction
	return dir == (CAM_LEFT if is_left else CAM_RIGHT)


# --- Ввод мышью по кубикам ---
func _on_light_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_toggle_light()


func _on_door_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_toggle_door()


# --- Общая логика (вызывается и мышью, и клавишами) ---
func _toggle_light() -> void:
	if is_powerdown:
		return
	var side_name = "Левая" if is_left else "Правая"
	print("[КНОПКА]: %s дверь (свет)" % side_name)
	
	light_on = not light_on
	light_door.emit(light_on)
	
	var energy = 1.0 if light_on else 0.0
	_set_button_emission(light_button, energy)
	spot_light_3d.visible = light_on
	
	# Обновляем видимость немедленно
	_update_enemy_visibility()


func _toggle_door() -> void:
	if is_powerdown:
		return
	var side_name = "Левая" if is_left else "Правая"
	print("[КНОПКА]: %s дверь (дверь)" % side_name)
	
	var is_closed: bool
	
	if is_left:
		MainManager.ldoor_closed = not MainManager.ldoor_closed
		is_closed = MainManager.ldoor_closed
	else:
		MainManager.rdoor_closed = not MainManager.rdoor_closed
		is_closed = MainManager.rdoor_closed
		
	change_door.emit(is_closed)
	
	var energy = 1.0 if is_closed else 0.0
	_set_button_emission(door_button, energy)
	
	_animate_door_flap(is_closed)


func _on_game_manager_powerdown() -> void:
	is_powerdown = true
	light_on = false
	spot_light_3d.visible = false
	_set_button_emission(light_button, 0.0)
	
	_set_button_emission(door_button, 0.0)
	if is_left:
		MainManager.ldoor_closed = false
	else:
		MainManager.rdoor_closed = false
	
	_animate_door_flap(false)
	# Обязательно обновляем видимость при обесточивании
	_update_enemy_visibility()


func _animate_door_flap(is_closed: bool) -> void:
	var target_y = flap_closed_y if is_closed else flap_open_y
	
	var tween = create_tween()
	tween.tween_property(door_flap, "position:y", target_y, flap_speed)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)


func _set_button_emission(button: MeshInstance3D, energy: float) -> void:
	var mat = button.get_active_material(0)
	if mat:
		mat.emission_energy_multiplier = energy
