class_name HoverEffect
extends Node

@export_range(1.0, 1.2, 0.01) var hover_scale := 1.05
@export_range(1.0, 1.5, 0.01) var hover_brightness := 1.12
@export var hover_offset := Vector2(0.0, -3.0)
@export_range(0.05, 0.5, 0.01) var hover_duration := 0.18
@export_range(0.8, 1.0, 0.01) var pressed_scale := 0.97
@export_range(1.0, 1.1, 0.01) var pressed_rebound_scale := 1.02
@export_range(0.06, 0.3, 0.01) var pressed_duration := 0.12

var _target: Control
var _effect_tween: Tween
var _base_position := Vector2.ZERO
var _base_scale := Vector2.ONE
var _base_modulate := Color.WHITE


func _ready() -> void:
	_target = get_parent() as Control
	if _target == null:
		push_warning("HoverEffect: parent must be a Control.")
		return
	_base_position = _target.position
	_base_scale = _target.scale
	_base_modulate = _target.modulate
	_target.mouse_entered.connect(_on_mouse_entered)
	_target.mouse_exited.connect(_on_mouse_exited)
	_target.gui_input.connect(_on_gui_input)


func is_effect_running() -> bool:
	return _effect_tween != null and _effect_tween.is_valid() and _effect_tween.is_running()


func _on_mouse_entered() -> void:
	_capture_current_base_if_idle()
	_animate_to(_base_scale * hover_scale, _base_position + hover_offset, _brightened_modulate())


func _on_mouse_exited() -> void:
	_animate_to(_base_scale, _base_position, _base_modulate)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_capture_current_base_if_idle()
			_play_pressed_feedback()


func _capture_current_base_if_idle() -> void:
	if is_effect_running():
		return
	_base_position = _target.position
	_base_scale = _target.scale
	_base_modulate = _target.modulate


func _animate_to(target_scale: Vector2, target_position: Vector2, target_modulate: Color) -> void:
	_kill_effect_tween()
	_effect_tween = create_tween().set_parallel(true)
	_effect_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_effect_tween.tween_property(_target, "scale", target_scale, hover_duration)
	_effect_tween.tween_property(_target, "position", target_position, hover_duration)
	_effect_tween.tween_property(_target, "modulate", target_modulate, hover_duration)


func _play_pressed_feedback() -> void:
	_kill_effect_tween()
	var stage_duration := pressed_duration / 3.0
	_effect_tween = create_tween()
	_effect_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_effect_tween.tween_property(_target, "scale", _base_scale * pressed_scale, stage_duration)
	_effect_tween.tween_property(_target, "scale", _base_scale * pressed_rebound_scale, stage_duration)
	_effect_tween.tween_property(_target, "scale", _base_scale, stage_duration)
	_effect_tween.parallel().tween_property(_target, "position", _base_position, stage_duration)
	_effect_tween.parallel().tween_property(_target, "modulate", _base_modulate, stage_duration)


func _brightened_modulate() -> Color:
	return Color(
		_base_modulate.r * hover_brightness,
		_base_modulate.g * hover_brightness,
		_base_modulate.b * hover_brightness,
		_base_modulate.a
	)


func _kill_effect_tween() -> void:
	if _effect_tween != null and _effect_tween.is_valid():
		_effect_tween.kill()
	_effect_tween = null
