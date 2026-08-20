extends TextureButton

const HOVER_SCALE := Vector2(1.05, 1.05)
const HOVER_MODULATE := Color(1.2, 1.15, 1.05, 1.0)
const HOVER_DURATION := 0.12

var _hover_tween: Tween


func _ready() -> void:
	pivot_offset = size * 0.5
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		pivot_offset = size * 0.5


func _on_mouse_entered() -> void:
	_animate_hover(HOVER_SCALE, HOVER_MODULATE)


func _on_mouse_exited() -> void:
	_animate_hover(Vector2.ONE, Color.WHITE)


func _animate_hover(target_scale: Vector2, target_modulate: Color) -> void:
	if _hover_tween:
		_hover_tween.kill()
	_hover_tween = create_tween().set_parallel(true)
	_hover_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_hover_tween.tween_property(self, "scale", target_scale, HOVER_DURATION)
	_hover_tween.tween_property(self, "self_modulate", target_modulate, HOVER_DURATION)
