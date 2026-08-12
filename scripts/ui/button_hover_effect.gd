class_name ButtonHoverEffect
extends Button

@export_range(1.0, 1.2, 0.01) var hover_scale := 1.05
@export_range(1.0, 1.5, 0.01) var hover_brightness := 1.08
@export_range(0.05, 0.5, 0.01) var transition_duration := 0.14

var _hover_tween: Tween
var _base_scale := Vector2.ONE
var _base_modulate := Color.WHITE


func _ready() -> void:
	_base_scale = scale
	_base_modulate = modulate
	pivot_offset = size / 2.0
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		pivot_offset = size / 2.0


func is_hover_tween_running() -> bool:
	return _hover_tween != null and _hover_tween.is_valid() and _hover_tween.is_running()


func _on_mouse_entered() -> void:
	var highlighted_modulate := Color(
		_base_modulate.r * hover_brightness,
		_base_modulate.g * hover_brightness,
		_base_modulate.b * hover_brightness,
		_base_modulate.a
	)
	_animate_to(_base_scale * hover_scale, highlighted_modulate)


func _on_mouse_exited() -> void:
	_animate_to(_base_scale, _base_modulate)


func _animate_to(target_scale: Vector2, target_modulate: Color) -> void:
	if _hover_tween != null and _hover_tween.is_valid():
		_hover_tween.kill()

	_hover_tween = create_tween().set_parallel(true)
	_hover_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_hover_tween.tween_property(self, "scale", target_scale, transition_duration)
	_hover_tween.tween_property(self, "modulate", target_modulate, transition_duration)
