class_name BackgroundMotion
extends Control

@export var background_path: NodePath
@export_range(0.0, 0.1, 0.001) var scale_amount := 0.03
@export_range(0.0, 50.0, 0.5) var horizontal_drift := 6.0
@export_range(2.5, 5.0, 0.1) var half_cycle_duration := 4.0

var _background: TextureRect
var _motion_tween: Tween
var _base_position := Vector2.ZERO
var _base_scale := Vector2.ONE


func _ready() -> void:
	call_deferred("_start_motion")


func is_motion_running() -> bool:
	return _motion_tween != null and _motion_tween.is_valid() and _motion_tween.is_running()


func get_background() -> TextureRect:
	return _background


func get_base_position() -> Vector2:
	return _base_position


func get_base_scale() -> Vector2:
	return _base_scale


func _start_motion() -> void:
	_background = get_node_or_null(background_path) as TextureRect
	if _background == null:
		push_warning("BackgroundMotion requires a valid TextureRect background_path.")
		return

	_stop_motion()
	_base_position = _background.position
	_base_scale = _background.scale
	_background.pivot_offset = _background.size / 2.0

	var expanded_scale := _base_scale * (1.0 + scale_amount)
	var right_position := _base_position + Vector2(horizontal_drift, 0.0)
	var left_position := _base_position - Vector2(horizontal_drift, 0.0)

	_motion_tween = create_tween().set_loops()
	_motion_tween.tween_property(
		_background,
		"scale",
		expanded_scale,
		half_cycle_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_motion_tween.parallel().tween_property(
		_background,
		"position",
		right_position,
		half_cycle_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_motion_tween.tween_property(
		_background,
		"scale",
		_base_scale,
		half_cycle_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_motion_tween.parallel().tween_property(
		_background,
		"position",
		left_position,
		half_cycle_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _stop_motion() -> void:
	if _motion_tween != null and _motion_tween.is_valid():
		_motion_tween.kill()
	_motion_tween = null
