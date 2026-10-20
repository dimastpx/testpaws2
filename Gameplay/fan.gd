extends Node3D

@onready var rotator: MeshInstance3D = $Rotator

@export var rotation_speed: float = 32 # радиан в секунду
@export var rotation_axis: Vector3 = Vector3.FORWARD


func _process(delta: float) -> void:
	if MainManager.power > 0.0:
		rotator.rotate(rotation_axis.normalized(), rotation_speed * delta)
