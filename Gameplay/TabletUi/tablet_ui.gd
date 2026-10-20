extends Control

signal close_tablet
signal money_plus

@onready var money_text: Label = $MoneyText
@onready var too_late: Label = $TooLate

@onready var l_cor_button: Button = $GridContainer/LCorButton
@onready var r_cor_button: Button = $GridContainer/RCorButton
@onready var scene_button: Button = $GridContainer/SceneButton
@onready var drums_button: Button = $GridContainer/DrumsButton

@onready var camera: TextureRect = $Camera

var dont_have_money = false

# ============================================================
#  КАМЕРЫ
# ============================================================
const STATIC_DURATION: float = 0.5
const STATIC_FRAME_TIME: float = 0.05
const STATIC_FRAMES_COUNT: int = 6
const NOISE_SIZE := Vector2i(160, 90)

@export_group("Помехи (необязательно)")
@export var static_frames: Array[Texture2D] = []

@export_group("Камеры: фон без врагов")
@export var cam_lcor_bg: Texture2D
@export var cam_rcor_bg: Texture2D
@export var cam_scene_bg: Texture2D
@export var cam_drums_bg: Texture2D

var _current_cam: int = GameManager.Where.NONE
var _static_left: float = 0.0
var _static_frame_timer: float = 0.0
var _static_index: int = 0
var _noise_textures: Array[Texture2D] = []
var _saved_filter: int = CanvasItem.TEXTURE_FILTER_PARENT_NODE

var _backgrounds: Dictionary = {}

# Узлы-спрайты врагов: перетаскивай узлы из дерева сцены в слоты инспектора.
# Пустые слоты просто пропускаются.
@export_group("Барс на камерах")
@export var bars_on_lcor: CanvasItem
@export var bars_on_rcor: CanvasItem
@export var bars_on_scene: CanvasItem
@export var bars_on_drums: CanvasItem

@export_group("Кулдог на камерах")
@export var cool_on_lcor: CanvasItem
@export var cool_on_rcor: CanvasItem
@export var cool_on_scene: CanvasItem
@export var cool_on_drums: CanvasItem

@export_group("Тофи на камерах")
@export var tofy_on_lcor: CanvasItem
@export var tofy_on_rcor: CanvasItem
@export var tofy_on_scene: CanvasItem
@export var tofy_on_drums: CanvasItem

@export_group("Рысь на камерах")
@export var lynx_on_lcor: CanvasItem
@export var lynx_on_rcor: CanvasItem
@export var lynx_on_scene: CanvasItem
@export var lynx_on_drums: CanvasItem

# список вида [{"node": CanvasItem, "cam": int, "enemy": String}]
var _sprites: Array = []


func _ready() -> void:
	self.visible = false
	too_late.visible = false

	var w = GameManager.Where
	_backgrounds = {
		w.LCORRIDOR: cam_lcor_bg,
		w.RCORRIDOR: cam_rcor_bg,
		w.SCENE: cam_scene_bg,
		w.DRUMS: cam_drums_bg,
	}

	_collect_sprites()
	_hide_enemies()
	_prepare_static()

	l_cor_button.pressed.connect(_switch_camera.bind(w.LCORRIDOR))
	r_cor_button.pressed.connect(_switch_camera.bind(w.RCORRIDOR))
	scene_button.pressed.connect(_switch_camera.bind(w.SCENE))
	drums_button.pressed.connect(_switch_camera.bind(w.DRUMS))


func _process(delta: float) -> void:
	if _current_cam == GameManager.Where.NONE:
		return

	if _static_left > 0.0:
		_static_left -= delta
		_static_frame_timer -= delta
		if _static_frame_timer <= 0.0:
			_static_frame_timer = STATIC_FRAME_TIME
			_show_next_static_frame()
		if _static_left <= 0.0:
			_finish_static()
	else:
		_refresh_enemies()


# ---------------- Переключение камер ----------------

func _switch_camera(cam: int) -> void:
	_current_cam = cam
	_static_left = STATIC_DURATION
	_static_frame_timer = 0.0
	_hide_enemies()

	if _saved_filter == CanvasItem.TEXTURE_FILTER_PARENT_NODE:
		_saved_filter = camera.texture_filter
	camera.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_show_next_static_frame()


func _finish_static() -> void:
	_static_left = 0.0
	camera.texture_filter = _saved_filter as CanvasItem.TextureFilter
	_saved_filter = CanvasItem.TEXTURE_FILTER_PARENT_NODE
	camera.texture = _backgrounds.get(_current_cam)
	_refresh_enemies()


# ---------------- Помехи ----------------

func _prepare_static() -> void:
	if not static_frames.is_empty():
		_noise_textures = static_frames.duplicate()
		return
	for i in STATIC_FRAMES_COUNT:
		var data := PackedByteArray()
		data.resize(NOISE_SIZE.x * NOISE_SIZE.y)
		for p in data.size():
			data[p] = randi() % 256
		var img := Image.create_from_data(NOISE_SIZE.x, NOISE_SIZE.y, false, Image.FORMAT_L8, data)
		_noise_textures.append(ImageTexture.create_from_image(img))


func _show_next_static_frame() -> void:
	if _noise_textures.is_empty():
		return
	_static_index = (_static_index + 1 + randi() % maxi(_noise_textures.size() - 1, 1)) % _noise_textures.size()
	camera.texture = _noise_textures[_static_index]


# ---------------- Спрайты врагов (узлы в сцене) ----------------

func _collect_sprites() -> void:
	var w = GameManager.Where
	var table := [
		["bars", w.LCORRIDOR, bars_on_lcor], ["bars", w.RCORRIDOR, bars_on_rcor],
		["bars", w.SCENE, bars_on_scene], ["bars", w.DRUMS, bars_on_drums],
		["cool", w.LCORRIDOR, cool_on_lcor], ["cool", w.RCORRIDOR, cool_on_rcor],
		["cool", w.SCENE, cool_on_scene], ["cool", w.DRUMS, cool_on_drums],
		["tofy", w.LCORRIDOR, tofy_on_lcor], ["tofy", w.RCORRIDOR, tofy_on_rcor],
		["tofy", w.SCENE, tofy_on_scene], ["tofy", w.DRUMS, tofy_on_drums],
		["lynx", w.LCORRIDOR, lynx_on_lcor], ["lynx", w.RCORRIDOR, lynx_on_rcor],
		["lynx", w.SCENE, lynx_on_scene], ["lynx", w.DRUMS, lynx_on_drums],
	]
	for row in table:
		if row[2] != null:
			_sprites.append({"node": row[2], "cam": row[1], "enemy": row[0]})


func _get_enemy_location(enemy_name: String) -> int:
	match enemy_name:
		"bars": return MainManager.where_bars
		"cool": return MainManager.where_cool
		"tofy": return MainManager.where_tofy
		"lynx": return MainManager.where_lynx
	return GameManager.Where.NONE


func _refresh_enemies() -> void:
	for s in _sprites:
		s["node"].visible = (s["cam"] == _current_cam) and (_get_enemy_location(s["enemy"]) == s["cam"])


func _hide_enemies() -> void:
	for s in _sprites:
		s["node"].visible = false


# ============================================================
#  Остальное (без изменений)
# ============================================================

func _on_close_button_pressed() -> void:
	close_tablet.emit()


func _on_game_manager_update_money(value: int) -> void:
	if value == 0:
		dont_have_money = true
	money_text.text = "Донаты рыси: " + str(value)


func _on_game_manager_update_consumption(value: float) -> void:
	$Consumption.text = "Потребление: " + str(int(value))


func _on_donate_pressed() -> void:
	if dont_have_money:
		too_late.visible = true
	else:
		money_plus.emit()
