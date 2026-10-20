extends SpotLight3D # Замените на PointLight2D, если делаете 2D-игру

@export_group("Настройки мерцания")
@export var base_energy: float = 1.0       # Базовая яркость света
@export var flicker_intensity_low: float = 0.4 # Размах колебаний (+/- от базовой)
@export var flicker_intensity_medium: float = 0.6
@export var flicker_intensity_high: float = 1.0
@export var flicker_speed: float = 15.0   # Скорость мерцания
@export var is_menu: bool = false

var noise := FastNoiseLite.new()
var time: float = 0.0

func _ready() -> void:
	noise.seed = randi()
	noise.frequency = 0.5
	noise.noise_type = FastNoiseLite.TYPE_PERLIN

func _process(delta: float) -> void:
	if MainManager.isFlickerEnabled and (MainManager.power > 0 or is_menu):
		time += delta * flicker_speed
		# Получаем значение шума в диапазоне от -1.0 до 1.0
		var noise_val: float = noise.get_noise_1d(time)
		var flicker_intensity: float
		match MainManager.flicker_type:
			MainManager.FlickerType.LOW:
				flicker_intensity = flicker_intensity_low
			MainManager.FlickerType.MEDIUM:
				flicker_intensity = flicker_intensity_medium
			MainManager.FlickerType.HIGH:
				flicker_intensity = flicker_intensity_high
		
		# Меняем свойство energy (или texture_scale, если хотите менять радиус)
		light_energy = max(0.0, base_energy + (noise_val * flicker_intensity))


func _on_game_manager_powerdown() -> void:
	light_energy = 0
	
	
