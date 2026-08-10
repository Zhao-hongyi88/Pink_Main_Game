class_name MemoryBase
extends Control

## Memory 只管理调查状态；展示和输入分别由专用模块处理。

signal observation_marked_observed(observation_id)
signal observation_progress_changed(completed_count, total_count)
signal memory_completed()

var observed_points = {}
var _current_observation_id = ""
var completion_status = false
var _memory_completed_emitted = false


func _ready() -> void:
	pass


func register_observation(observation_id) -> void:
	var id = str(observation_id)
	if id == "":
		push_warning("MemoryBase: 不能注册空 observation_id。")
		return
	if not observed_points.has(id):
		observed_points[id] = false
		completion_status = false
		_memory_completed_emitted = false


func register_observations(observation_ids) -> void:
	for observation_id in observation_ids:
		register_observation(observation_id)


func is_observed(observation_id) -> bool:
	return observed_points.get(str(observation_id), false)


func get_progress_text() -> String:
	return "调查进度：%d / %d" % [_get_observed_count(), observed_points.size()]


## 打开调查时只记录当前对象，绝不在此处标记完成。
func inspect_observation(observation_id, _legacy_observation_data = null) -> bool:
	var id = str(observation_id)
	if id == "" or not observed_points.has(id):
		push_warning("MemoryBase: 未注册的调查点 -> " + id)
		return false

	_current_observation_id = id
	return true


## 仅由 MemoryInfoPanel 的“完成并关闭”信号触发。
func complete_current_observation() -> void:
	if _current_observation_id == "":
		return

	set_observed(_current_observation_id)
	_current_observation_id = ""


## ESC 或普通关闭时调用；只清理当前调查状态。
func cancel_current_observation() -> void:
	_current_observation_id = ""

	_current_dialogue_index += 1

func set_observed(observation_id) -> void:
	var id = str(observation_id)
	if not observed_points.has(id):
		push_warning("MemoryBase: 未注册的调查点 -> " + id)
		return
	if observed_points[id]:
		return

	observed_points[id] = true
	emit_signal("observation_marked_observed", id)
	_update_completion_status()


func _get_observed_count() -> int:
	var observed_count = 0
	for is_done in observed_points.values():
		if is_done:
			observed_count += 1
	return observed_count


func _update_completion_status() -> void:
	var total_count = observed_points.size()
	var completed_count = _get_observed_count()
	completion_status = total_count > 0 and completed_count == total_count
	emit_signal("observation_progress_changed", completed_count, total_count)

	if completion_status and not _memory_completed_emitted:
		_memory_completed_emitted = true
		emit_signal("memory_completed")
