class_name MainCamera
extends Camera3D

@export_range(0.05, 1.5, 0.05) var tilt_duration: float = 0.35
@export var tablet_ui: Control # Ссылка на UI-ноду (можно назначить в инспекторе)

@onready var head: Node3D = $Head

signal main_ui_tablet_visible(on: bool)
signal tablet_change(open: bool)

var _tween: Tween

func tablet_open(open: bool) -> void:
	tablet_change.emit(open)
	if not open:
		# Если закрываем — сразу прячем UI
		if tablet_ui:
			tablet_ui.visible = false
			main_ui_tablet_visible.emit(true)
		_rotate_head_to(Vector3(deg_to_rad(-45.0), 0.0, 0.0))
		return

	# Запускаем поворот и ждем его окончания
	_rotate_head_to(Vector3.ZERO)
	main_ui_tablet_visible.emit(false)
	await _tween.finished
	
	# Показываем UI только после завершения поворота
	if tablet_ui:
		tablet_ui.visible = true
		# Либо tablet_ui.show()

func _rotate_head_to(target_rotation_rad: Vector3) -> void:
	if _tween and _tween.is_running():
		_tween.kill()

	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(head, "rotation", target_rotation_rad, tilt_duration)
