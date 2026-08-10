class_name TransitionLayer
extends CanvasLayer

@export_range(0.05, 2.0, 0.05) var fade_duration := 0.25

@onready var fade_overlay: ColorRect = %FadeOverlay

var _fade_tween: Tween


func _ready() -> void:
	fade_overlay.modulate.a = 0.0
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE


func fade_out() -> void:
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	await _fade_to(1.0)


func fade_in() -> void:
	await _fade_to(0.0)
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE


func is_fading() -> bool:
	return _fade_tween != null and _fade_tween.is_valid() and _fade_tween.is_running()


func _fade_to(target_alpha: float) -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()

	_fade_tween = create_tween()
	_fade_tween.tween_property(
		fade_overlay,
		"modulate:a",
		target_alpha,
		fade_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await _fade_tween.finished
	fade_overlay.modulate.a = target_alpha
