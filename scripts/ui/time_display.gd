class_name TimeDisplay
extends Control

## 独立的测试倒计时组件。
## 后续全局时间系统可以调用 initialize、set_remaining_seconds、start 和 stop 接管状态。

signal time_changed(remaining_seconds: int)
signal time_finished

@export var auto_start := true

@onready var time_value: Label = %TimeValue

var _remaining_seconds := 282180
var _value_feedback_tween: Tween

const VALUE_FEEDBACK_SCALE := Vector2(1.04, 1.04)
const VALUE_FEEDBACK_HALF_DURATION := 0.09

@export_range(0, 31536000, 1) var remaining_seconds: int = 282180:
	get:
		return _remaining_seconds
	set(value):
		_remaining_seconds = maxi(0, value)
		if is_node_ready():
			_apply_remaining_seconds(_remaining_seconds, true)

var _second_accumulator := 0.0
var _is_running := false
var _finish_emitted := false


func _ready() -> void:
	_finish_emitted = false
	_apply_remaining_seconds(remaining_seconds, true)
	_is_running = auto_start and remaining_seconds > 0


func _process(delta: float) -> void:
	if not _is_running or remaining_seconds <= 0:
		return

	_second_accumulator += delta
	var elapsed_seconds := int(floor(_second_accumulator))
	if elapsed_seconds < 1:
		return

	_second_accumulator -= float(elapsed_seconds)
	_apply_remaining_seconds(remaining_seconds - elapsed_seconds, false)


func initialize(seconds: int) -> void:
	_finish_emitted = false
	_apply_remaining_seconds(seconds, true)
	_is_running = auto_start and remaining_seconds > 0


func set_remaining_seconds(seconds: int) -> void:
	_apply_remaining_seconds(seconds, true)


func start() -> void:
	if remaining_seconds > 0:
		_is_running = true


func stop() -> void:
	_is_running = false


func set_running(value: bool) -> void:
	if value:
		start()
	else:
		stop()


func is_running() -> bool:
	return _is_running


func get_remaining_seconds() -> int:
	return remaining_seconds


func is_value_feedback_running() -> bool:
	return (
		_value_feedback_tween != null
		and _value_feedback_tween.is_valid()
		and _value_feedback_tween.is_running()
	)


func get_display_text() -> String:
	var parts := get_time_parts()
	return "%dH %02dMin" % [parts["hours"], parts["minutes"]]


func get_time_parts() -> Dictionary:
	return {
		"hours": int(remaining_seconds / 3600),
		"minutes": int((remaining_seconds % 3600) / 60),
		"seconds": remaining_seconds % 60,
	}


func _apply_remaining_seconds(seconds: int, reset_accumulator: bool) -> void:
	_remaining_seconds = maxi(0, seconds)
	if reset_accumulator:
		_second_accumulator = 0.0
	if remaining_seconds > 0:
		_finish_emitted = false
	if is_node_ready():
		_update_display()
	time_changed.emit(remaining_seconds)
	if remaining_seconds == 0:
		_finish_countdown()


func _finish_countdown() -> void:
	_is_running = false
	_second_accumulator = 0.0
	if _finish_emitted:
		return
	_finish_emitted = true
	time_finished.emit()


func _update_display() -> void:
	var new_display_text := get_display_text()
	if time_value.text == new_display_text:
		return
	time_value.text = new_display_text
	_play_value_feedback()


func _play_value_feedback() -> void:
	if _value_feedback_tween != null and _value_feedback_tween.is_valid():
		_value_feedback_tween.kill()

	time_value.pivot_offset = time_value.size / 2.0
	_value_feedback_tween = create_tween()
	_value_feedback_tween.tween_property(
		time_value,
		"scale",
		VALUE_FEEDBACK_SCALE,
		VALUE_FEEDBACK_HALF_DURATION
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_value_feedback_tween.tween_property(
		time_value,
		"scale",
		Vector2.ONE,
		VALUE_FEEDBACK_HALF_DURATION
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
