class_name StartButton
extends Button

@export_range(0.1, 20.0, 0.1, "or_greater") var gear_speed := 2.0

@onready var gear_back: TextureRect = %Gear_Back
@onready var gear_front: TextureRect = %Gear_Front

var _gear_tween: Tween


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func is_gear_rotation_active() -> bool:
	return (
		_gear_tween != null
		and _gear_tween.is_valid()
		and _gear_tween.is_running()
	)


func _on_mouse_entered() -> void:
	_start_gear_rotation()


func _on_mouse_exited() -> void:
	_stop_gear_rotation()


func _start_gear_rotation() -> void:
	if is_gear_rotation_active():
		return
	var rotation_duration := TAU / maxf(gear_speed, 0.001)
	_gear_tween = create_tween()
	_gear_tween.set_loops()
	_gear_tween.set_parallel(true)
	_gear_tween.tween_property(
		gear_back,
		"rotation",
		gear_back.rotation + TAU,
		rotation_duration
	)
	_gear_tween.tween_property(
		gear_front,
		"rotation",
		gear_front.rotation - TAU,
		rotation_duration
	)


func _stop_gear_rotation() -> void:
	if _gear_tween != null and _gear_tween.is_valid():
		_gear_tween.kill()
	_gear_tween = null
