extends Node

## 主轴运行时状态。页面仅调用这里的公开接口，不直接修改进度。

signal run_started(step: MainAxisStep)
signal current_step_changed(step: MainAxisStep)
signal progress_changed(completed_count: int, total_count: int)
signal run_completed

const SAVE_SECTION := &"main_axis"
const DEFAULT_DEFINITION: MainAxisDefinition = preload("res://data/main_axis/default_main_axis.tres")

var definition: MainAxisDefinition = DEFAULT_DEFINITION
var current_step_id: StringName = &""
var completed_step_ids: Array[StringName] = []
var has_active_run := false
var is_run_completed := false


func _ready() -> void:
	SaveService.register_section(SAVE_SECTION, _build_save_data, _apply_save_data)
	var definition_errors := definition.validate_definition()
	for message in definition_errors:
		push_error("MainAxisService: %s" % message)


func start_new_run() -> bool:
	if definition.get_step(definition.initial_step_id) == null:
		push_error("MainAxisService: 无法开始，起始节点无效。")
		return false
	completed_step_ids.clear()
	current_step_id = definition.initial_step_id
	has_active_run = true
	is_run_completed = false
	SaveService.save_game()
	var step := get_current_step()
	run_started.emit(step)
	_emit_progress()
	return true


func resume_run() -> bool:
	if not SaveService.load_game():
		return false
	if is_run_completed:
		return true
	if not has_active_run or get_current_step() == null:
		push_error("MainAxisService: 存档中没有有效的主线进度。")
		return false
	current_step_changed.emit(get_current_step())
	_emit_progress()
	return true


func get_current_step() -> MainAxisStep:
	return definition.get_step(current_step_id)


func advance_current_step() -> bool:
	if not has_active_run:
		return false
	var current_step := get_current_step()
	if current_step == null:
		return false
	if not completed_step_ids.has(current_step.id):
		completed_step_ids.append(current_step.id)

	if current_step.next_step_id.is_empty():
		current_step_id = &""
		has_active_run = false
		is_run_completed = true
		SaveService.save_game()
		_emit_progress()
		run_completed.emit()
		return true

	var next_step := definition.get_step(current_step.next_step_id)
	if next_step == null:
		push_error("MainAxisService: 后续节点不存在：%s" % current_step.next_step_id)
		return false
	current_step_id = next_step.id
	SaveService.save_game()
	current_step_changed.emit(next_step)
	_emit_progress()
	return true


func get_progress_text() -> String:
	if is_run_completed:
		return "主线占位流程已完成"
	if not has_active_run:
		return "尚未开始"
	var index := definition.get_step_index(current_step_id)
	return "节点 %d / %d" % [index + 1, definition.steps.size()]


func _build_save_data() -> Dictionary:
	var completed: Array[String] = []
	for step_id in completed_step_ids:
		completed.append(String(step_id))
	return {
		"current_step_id": String(current_step_id),
		"completed_step_ids": completed,
		"has_active_run": has_active_run,
		"is_run_completed": is_run_completed,
	}


func _apply_save_data(data: Variant) -> void:
	if typeof(data) != TYPE_DICTIONARY:
		return
	var saved: Dictionary = data
	current_step_id = StringName(saved.get("current_step_id", ""))
	completed_step_ids.clear()
	var saved_completed: Array = saved.get("completed_step_ids", [])
	for step_id: Variant in saved_completed:
		completed_step_ids.append(StringName(str(step_id)))
	has_active_run = bool(saved.get("has_active_run", false))
	is_run_completed = bool(saved.get("is_run_completed", false))


func _emit_progress() -> void:
	progress_changed.emit(completed_step_ids.size(), definition.steps.size())
