extends Control

# --- НАСТРОЙКИ СКРИМЕРА ---
const TARGET_SCALE: Vector2 = Vector2(2, 2) 
const ANIMATION_DURATION: float = .3

@export_category("Картинки скримеров")
@export var lynx_texture: Texture2D
@export var tofy_texture: Texture2D
@export var cool_texture: Texture2D
@export var bars_texture: Texture2D

@onready var texture_rect: TextureRect = $TextureRect
@onready var audio_stream_player_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D


func _ready() -> void:
	texture_rect.visible = false
	#await get_tree().create_timer(2).timeout
	#screamer("Тофи")


func screamer(enemy_name: String) -> void:
	audio_stream_player_3d.play()
	var current_texture: Texture2D = null
	
	match enemy_name:
		"Рысь": current_texture = lynx_texture
		"Тофи": current_texture = tofy_texture
		"Кулдог": current_texture = cool_texture
		"Барс": current_texture = bars_texture
		_:
			push_warning("Неизвестное имя врага для скримера: ", enemy_name)
			return
			
	if current_texture == null:
		push_error("В инспекторе не назначена текстура скримера для: ", enemy_name)
		return
		
	texture_rect.texture = current_texture
	
	texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Принудительно задаем размер узла равным размеру окна игры
	texture_rect.size = get_viewport_rect().size 
	texture_rect.force_update_transform() 
	
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	texture_rect.pivot_offset = texture_rect.size / 2.0
	
	# СТАРТ С НУЛЯ: масштаб 0, непрозрачность 100%
	texture_rect.scale = Vector2.ZERO 
	texture_rect.modulate.a = 1.0 
	texture_rect.visible = true
	
	var tween = create_tween()
	
	tween.tween_property(texture_rect, "scale", TARGET_SCALE, ANIMATION_DURATION) \
		.set_trans(Tween.TRANS_LINEAR)
	
	tween.tween_callback(_on_screamer_finished)


func _on_screamer_finished() -> void:
	get_tree().change_scene_to_file("res://LoseUi.tscn")


func _on_game_manager_jumpscare(enemy: RefCounted) -> void:
	screamer(enemy.name)
