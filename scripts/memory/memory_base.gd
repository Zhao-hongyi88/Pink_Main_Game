class_name MemoryBase
extends Control

## 所有 Memory 场景共用的调查、导航与运行时状态入口。
## 人物专属脚本只注册调查点；NPC 身份始终来自 SceneRouter payload。

signal observation_marked_observed(observation_id: String)
signal observation_progress_changed(completed_count: int, total_count: int)
signal memory_completed()

var npc_id: StringName = &""
var return_npc_data_path := ""
var observed_points: Dictionary = {}
var completion_status := false

var _current_observation_id := ""
var _memory_completed_emitted := false
var _has_navigation_context := false

@onready var _memory_info_panel: Control = %MemoryInfoPanel
@onready var _progress_label: Label = %ProgressLabel
@onready var _complete_button: Button = %CompleteButton
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_consume_navigation_payload()
	_memory_info_panel.observation_completed.connect(_on_observation_completed)
	_memory_info_panel.observation_cancelled.connect(_on_observation_cancelled)
	observation_progress_changed.connect(_on_observation_progress_changed)
	memory_completed.connect(_on_all_observations_completed)
	_complete_button.pressed.connect(_on_complete_pressed)
	_back_button.pressed.connect(_on_back_pressed)

	_complete_button.hide()
	_complete_button.disabled = true
	_back_button.disabled = not _has_navigation_context
	_refresh_progress_label()


func register_observation(observation_id) -> void:
	var id := str(observation_id).strip_edges()
	if id.is_empty():
		push_warning("MemoryBase: 不能注册空 observation_id。")
		return
	if not observed_points.has(id):
		observed_points[id] = false
		completion_status = false
		_memory_completed_emitted = false
		_complete_button.hide()
		_complete_button.disabled = true


func register_observations(observation_ids) -> void:
	for observation_id in observation_ids:
		register_observation(observation_id)
	_refresh_progress_label()


func register_observation_point(point) -> void:
	if point == null:
		push_warning("MemoryBase: 不能注册空的调查点。")
		return
	if point.observation_data == null:
		push_warning("MemoryBase: 调查点缺少 observation_data：%s" % point.name)
		return

	register_observation(point.observation_data.observation_id)
	if not point.observation_requested.is_connected(_on_observation_requested):
		point.observation_requested.connect(_on_observation_requested)
	_refresh_progress_label()


func register_observation_points(points: Array) -> void:
	for point in points:
		register_observation_point(point)
	_refresh_progress_label()


func is_observed(observation_id) -> bool:
	return bool(observed_points.get(str(observation_id).strip_edges(), false))


func get_progress_text() -> String:
	return "调查进度：%d / %d" % [_get_observed_count(), observed_points.size()]


## 打开调查时只记录当前对象，绝不在此处标记完成。
func inspect_observation(observation_id, _legacy_observation_data = null) -> bool:
	var id := str(observation_id).strip_edges()
	if id.is_empty() or not observed_points.has(id):
		push_warning("MemoryBase: 未注册的调查点 -> " + id)
		return false

	_current_observation_id = id
	return true


## 仅由 MemoryInfoPanel 的“完成并关闭”信号触发。
func complete_current_observation() -> void:
	if _current_observation_id.is_empty():
		return

	set_observed(_current_observation_id)
	_current_observation_id = ""


## ESC 或普通关闭时调用；只清理当前调查状态。
func cancel_current_observation() -> void:
	_current_observation_id = ""


func set_observed(observation_id) -> void:
	var id := str(observation_id).strip_edges()
	if not observed_points.has(id):
		push_warning("MemoryBase: 未注册的调查点 -> " + id)
		return
	if bool(observed_points[id]):
		return

	observed_points[id] = true
	observation_marked_observed.emit(id)
	_update_completion_status()


func _consume_navigation_payload() -> void:
	var payload := SceneRouter.take_payload()
	npc_id = StringName(str(payload.get("npc_id", "")).strip_edges())
	return_npc_data_path = str(payload.get("return_npc_data_path", "")).strip_edges()
	_has_navigation_context = not npc_id.is_empty() and not return_npc_data_path.is_empty()
	if not _has_navigation_context:
		push_warning("MemoryBase: 缺少 npc_id 或 return_npc_data_path 导航上下文。")


func _on_observation_requested(data) -> void:
	if data == null:
		return
	if inspect_observation(data.observation_id):
		_memory_info_panel.show_observation(data)


func _on_observation_completed(_observation_id) -> void:
	complete_current_observation()


func _on_observation_cancelled() -> void:
	cancel_current_observation()


func _on_observation_progress_changed(_completed_count: int, _total_count: int) -> void:
	_refresh_progress_label()


func _on_all_observations_completed() -> void:
	_complete_button.show()
	_complete_button.disabled = not _has_navigation_context


func _on_complete_pressed() -> void:
	if not completion_status or not _has_navigation_context:
		return
	if GameState.mark_memory_completed(npc_id):
		_complete_button.disabled = true
		SceneRouter.go_to(&"home")


func _on_back_pressed() -> void:
	if not _has_navigation_context:
		push_error("MemoryBase: 缺少返回上下文，无法返回 NPCBase。")
		return
	var progress := GameState.get_npc_progress(npc_id)
	if progress != null and progress.memory_completed:
		SceneRouter.go_to(&"home")
		return
	SceneRouter.go_to(&"npc_base", {
		"npc_data_path": return_npc_data_path,
	})


func _get_observed_count() -> int:
	var observed_count := 0
	for is_done in observed_points.values():
		if bool(is_done):
			observed_count += 1
	return observed_count


func _update_completion_status() -> void:
	var total_count := observed_points.size()
	var completed_count := _get_observed_count()
	completion_status = total_count > 0 and completed_count == total_count
	observation_progress_changed.emit(completed_count, total_count)

	if completion_status and not _memory_completed_emitted:
		_memory_completed_emitted = true
		memory_completed.emit()


func _refresh_progress_label() -> void:
	if is_instance_valid(_progress_label):
		_progress_label.text = get_progress_text()
