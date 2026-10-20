class_name GameManager
extends Node

enum Where {
	LCORRIDOR, RCORRIDOR, DRUMS, SCENE, LDOOR, RDOOR, NONE, DONATION_ZONE
}

class Enemy:
	var name: String
	var initial_location: Where
	var location: Where
	var route: Array
	var current_step: int = -1
	var is_waiting_at_door: bool = false

	func _init(p_name: String, p_location: Where, p_route: Array) -> void:
		name = p_name
		initial_location = p_location
		location = p_location
		route = p_route

signal enemy_moved(enemy: Enemy)
signal warning(enemy: Enemy)
signal jumpscare(enemy: Enemy)
signal enemy_repelled(enemy: Enemy)
signal update_power(value: float)
signal powerdown()
signal update_money(value: int)
signal update_consumption(value: float)

# --- НОВЫЕ СИГНАЛЫ ДЛЯ ВРЕМЕНИ ---
signal time_updated(hour: int)
signal win()

# Инициализация врагов
# Рыси убрали маршрут, так как теперь она зависит только от денег
var lynx: Enemy = Enemy.new("Рысь", Where.NONE, []) 
var bars: Enemy = Enemy.new("Барс", Where.DRUMS, [Where.SCENE, Where.LCORRIDOR, Where.LDOOR])
var cool: Enemy = Enemy.new("Кулдог", Where.SCENE, [Where.SCENE, Where.RCORRIDOR, Where.RDOOR])
var tofy: Enemy = Enemy.new("Тофи", Where.SCENE, [Where.SCENE, Where.RCORRIDOR, Where.RDOOR])

@export_category("Настройки ресурсов")
@export_range(0.1, 10.0, 0.1) var money_drain_interval: float = 2.0
@export var money_button: int = 50 
var _money_timer: float = 0.0

var active_consumers: Array[String] = []
var current_power_drain: float = 0.0

@export_category("Ожидание врагов")
@export var door_reaction_time: float = 4.0

@export_category("Диапазон значений для рандома и траты энергии")
@export_group("Easy", "easy_")
@export var easy_min_value: float = 20.0
@export var easy_max_value: float = 40.0
@export var easy_power_multiplier: float = 0.5

@export_group("Normal", "normal_")
@export var normal_min_value: float = 15.0
@export var normal_max_value: float = 30.0
@export var normal_power_multiplier: float = 1.0

@export_group("Hard", "hard_")
@export var hard_min_value: float = 15.0
@export var hard_max_value: float = 25.0
@export var hard_power_multiplier: float = 1.5

@export_group("Hardcore", "hardcore_")
@export var hardcore_min_value: float = 10.0
@export var hardcore_max_value: float = 15.0
@export var hardcore_power_multiplier: float = 2.5

var min_value: float
var max_value: float

# --- ПЕРЕМЕННЫЕ ДЛЯ РЫСИ ---
var lynx_attack_timer: float = 5.0
var is_lynx_attacking: bool = false
var lynx_triggered: bool = false

# --- ПЕРЕМЕННЫЕ ДЛЯ ВРЕМЕНИ ---
const TOTAL_GAME_TIME: float = 180.0 # 3 минуты (180 секунд)
const HOURS_IN_GAME: int = 6 # 6 игровых часов (с 12 до 6)
var in_game_time: float = 0.0
var current_hour: int = 12
var is_game_active: bool = true


func get_time_range_by_difficulty() -> Array:
	match MainManager.difficulty:
		MainManager.Difficulty.EASY:     return [easy_min_value, easy_max_value]
		MainManager.Difficulty.NORMAL:   return [normal_min_value, normal_max_value]
		MainManager.Difficulty.HARD:     return [hard_min_value, hard_max_value]
		MainManager.Difficulty.HARDCORE: return [hardcore_min_value, hardcore_max_value]
		_:                               return [normal_min_value, normal_max_value]

func get_power_drain_rate() -> float:
	match MainManager.difficulty:
		MainManager.Difficulty.EASY:     return easy_power_multiplier
		MainManager.Difficulty.NORMAL:   return normal_power_multiplier
		MainManager.Difficulty.HARD:     return hard_power_multiplier
		MainManager.Difficulty.HARDCORE: return hardcore_power_multiplier
		_:                               return normal_power_multiplier


func add_consumer(consumer_name: String) -> void:
	if not active_consumers.has(consumer_name):
		active_consumers.append(consumer_name)
		_recalculate_consumption()

func remove_consumer(consumer_name: String) -> void:
	if active_consumers.has(consumer_name):
		active_consumers.erase(consumer_name)
		_recalculate_consumption()

func _recalculate_consumption() -> void:
	var count: int = active_consumers.size()
	var base_drain: float = 0.5
	if count > 0:
		base_drain = 1.0 + float(count)
	current_power_drain = base_drain * get_power_drain_rate()
	update_consumption.emit(base_drain)


func _process(delta: float) -> void:
	# Если игра завершена победой, останавливаем все таймеры
	if not is_game_active:
		return
		
	# --- СИСТЕМА ВРЕМЕНИ ---
	in_game_time += delta
	var hour_duration = TOTAL_GAME_TIME / HOURS_IN_GAME # 180 / 6 = 30 секунд на один час
	var hours_passed = int(in_game_time / hour_duration)
	
	var new_hour = 12
	if hours_passed > 0:
		new_hour = hours_passed # 1, 2, 3, 4, 5, 6
		
	if new_hour != current_hour:
		if hours_passed >= HOURS_IN_GAME:
			# Наступило 6 AM - ПОБЕДА
			is_game_active = false
			current_hour = 6
			time_updated.emit(current_hour)
			win.emit()
			print("[ИГРА] 6 AM! ПОБЕДА!")
			get_tree().change_scene_to_file("res://Gameplay/win_ui.tscn")
			return
		else:
			current_hour = new_hour
			time_updated.emit(current_hour)
			print("[ВРЕМЯ] Новый час: ", current_hour, " AM")

	# --- ЭНЕРГИЯ ---
	if MainManager.power > 0:
		MainManager.power -= current_power_drain * delta
		update_power.emit(MainManager.power)
		if MainManager.power <= 0:
			MainManager.power = 0
			powerdown.emit()
	
	# --- ДЕНЬГИ ---
	if MainManager.money > 0:
		_money_timer += delta
		if _money_timer >= money_drain_interval:
			MainManager.money -= 1
			update_money.emit(MainManager.money)
			_money_timer = 0.0
			
	# --- НОВАЯ СИСТЕМА РЫСИ ---
	if MainManager.money <= 0:
		if not is_lynx_attacking:
			is_lynx_attacking = true
			lynx.location = Where.DONATION_ZONE
			_sync_location(lynx)
			warning.emit(lynx) # Предупреждаем игрока
			print("[ВНИМАНИЕ] Деньги кончились! Рысь нападет через 5 секунд!")
		
		lynx_attack_timer -= delta
		
		if lynx_attack_timer <= 0.0 and not lynx_triggered:
			lynx_triggered = true
			jumpscare.emit(lynx)
			print("[РЕЗУЛЬТАТ] ЗАЩИТА ПРОБИТА! Рысь совершает нападение!")
	else:
		if is_lynx_attacking:
			# Если игрок успел заработать деньги, Рысь уходит
			is_lynx_attacking = false
			lynx.location = Where.NONE
			_sync_location(lynx)
			enemy_repelled.emit(lynx)
			print("[РЕЗУЛЬТАТ] Баланс пополнен! Рысь ушла.")
		lynx_attack_timer = 5.0 # Сбрасываем таймер обратно до 5 секунд


func _sync_location(enemy: Enemy) -> void:
	match enemy.name:
		"Рысь": MainManager.where_lynx = enemy.location
		"Барс": MainManager.where_bars = enemy.location
		"Кулдог": MainManager.where_cool = enemy.location
		"Тофи": MainManager.where_tofy = enemy.location

func _run_enemy_loop(enemy: Enemy) -> void:
	print("[АИ] Запущен цикл для: ", enemy.name)
	while is_inside_tree() and is_game_active: # Проверяем, активна ли еще игра
		var wait_time: float
		if enemy.is_waiting_at_door:
			wait_time = door_reaction_time
		else:
			wait_time = randf_range(min_value, max_value)
		
		await get_tree().create_timer(wait_time).timeout
		if not is_inside_tree() or not is_game_active: return
		
		_process_step(enemy)

func _process_step(enemy: Enemy) -> void:
	if enemy.is_waiting_at_door:
		_check_defense(enemy)
		return

	if enemy.current_step < enemy.route.size() - 1:
		enemy.current_step += 1
		enemy.location = enemy.route[enemy.current_step]
		
		_sync_location(enemy)
		enemy_moved.emit(enemy)
		
		if enemy.location in [Where.LDOOR, Where.RDOOR, Where.DONATION_ZONE]:
			enemy.is_waiting_at_door = true
			warning.emit(enemy)

func _check_defense(enemy: Enemy) -> void:
	var is_safe: bool = false
	
	match enemy.location:
		Where.LDOOR:
			is_safe = MainManager.ldoor_closed
		Where.RDOOR:
			is_safe = MainManager.rdoor_closed
			
	# Из проверки убрана DONATION_ZONE, так как Рысь обрабатывается отдельно

	if is_safe:
		enemy.is_waiting_at_door = false
		enemy.current_step = -1
		enemy.location = enemy.initial_location
		
		_sync_location(enemy)
		enemy_repelled.emit(enemy)
		enemy_moved.emit(enemy)
	else:
		jumpscare.emit(enemy)


func _ready() -> void:
	print("[МЕНЕДЖЕР] Инициализация ночи...")
	var values = get_time_range_by_difficulty()
	min_value = values[0]
	max_value = values[1]
	
	_recalculate_consumption()
	
	# Отправляем в UI начальное время
	time_updated.emit(current_hour) 
	
	# ВАЖНО: Рысь больше не запускается в стандартном цикле
	for enemy in [bars, cool, tofy]:
		_sync_location(enemy)
		_run_enemy_loop(enemy)


# --- Сигналы интерфейса (оставлены без изменений) ---
func _on_camera_3d_tablet_change(open: bool) -> void:
	if open: add_consumer("camera")
	else: remove_consumer("camera")

func _on_l_door_light_l_door(on: bool) -> void:
	if on: add_consumer("light_l")
	else: remove_consumer("light_l")

func _on_r_door_light_door(on: bool) -> void:
	if on: add_consumer("light_r")
	else: remove_consumer("light_r")

func _on_l_door_change_door(close: bool) -> void:
	if close: add_consumer("door_l")
	else: remove_consumer("door_l")

func _on_r_door_change_door(close: bool) -> void:
	if close: add_consumer("door_r")
	else: remove_consumer("door_r")

func _on_tablet_ui_money_plus() -> void:
	MainManager.money += money_button
