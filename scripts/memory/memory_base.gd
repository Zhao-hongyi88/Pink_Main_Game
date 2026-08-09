class_name MemoryBase
extends Control

## Memory 通用回忆基类。
## 基类只处理调查、对话、完成和退出流程；各 NPC Memory 只提供数据与节点绑定。

signal memory_completed(p_npc_id: String, p_memory_id: String)
signal exit_requested()

@export var npc_id: String = ""
@export var memory_id: String = ""

var completion_status := false
var observed_points: Dictionary = {}

var _current_dialogue: Array = []
var _current_dialogue_index := 0

@onready var info_panel: Control = $MemoryUI/InfoPanel
@onready var title_label: Label = $MemoryUI/InfoPanel/TitleLabel
@onready var content_label: Label = $MemoryUI/InfoPanel/ContentLabel
@onready var action_button: Button = $MemoryUI/InfoPanel/ActionButton
@onready var exit_button: Button = $MemoryUI/ExitButton
@onready var complete_button: Button = $MemoryUI/CompleteButton
@onready var progress_label: Label = $MemoryUI/ProgressLabel


func _ready() -> void:
	info_panel.hide()
	action_button.pressed.connect(_on_action_button_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	complete_button.pressed.connect(_on_complete_pressed)
	_update_memory_ui()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return

	if info_panel.visible:
		_close_info_panel()
	else:
		_on_exit_pressed()
	get_viewport().set_input_as_handled()


## 由子类在 super._ready() 前注册自己的调查点。
func register_observations(observation_ids: Array) -> void:
	observed_points.clear()
	for observation_id in observation_ids:
		observed_points[str(observation_id)] = false
	completion_status = false


## 通用接口：显示某个调查点的对话数据。
func inspect_observation(observation_id: String, observation_data: Dictionary) -> void:
	if info_panel.visible:
		return

	if not observation_data.has(observation_id):
		push_warning("MemoryBase: 找不到调查点数据 -> " + observation_id)
		return

	var data: Dictionary = observation_data[observation_id]
	var dialogue_lines: Array = []
	if data.get("dialogue") is Array:
		dialogue_lines = data["dialogue"]
	set_observed(observation_id)
	show_memory_info(
		str(data.get("title", "调查点")),
		dialogue_lines,
	)


func is_observed(observation_id: String) -> bool:
	return observed_points.get(observation_id, false)


func set_observed(observation_id: String) -> void:
	if not observed_points.has(observation_id):
		push_warning("MemoryBase: 未注册的调查点 -> " + observation_id)
		return

	observed_points[observation_id] = true
	check_completion_condition()
	_update_memory_ui()


func check_completion_condition() -> void:
	if observed_points.is_empty():
		completion_status = false
		return

	for is_done in observed_points.values():
		if not is_done:
			completion_status = false
			return
	completion_status = true


func show_memory_info(title: String, dialogue_lines: Array) -> void:
	_current_dialogue = dialogue_lines.duplicate()
	_current_dialogue_index = 0
	title_label.text = title

	if _current_dialogue.is_empty():
		_current_dialogue.append("这里暂时没有更多记录。")

	_show_current_line()
	info_panel.show()
	action_button.grab_focus()


func _show_current_line() -> void:
	content_label.text = str(_current_dialogue[_current_dialogue_index])
	if _current_dialogue_index == _current_dialogue.size() - 1:
		action_button.text = "关闭"
	else:
		action_button.text = "下一条"


func _on_action_button_pressed() -> void:
	_current_dialogue_index += 1
	if _current_dialogue_index < _current_dialogue.size():
		_show_current_line()
	else:
		_close_info_panel()


func _close_info_panel() -> void:
	info_panel.hide()


func _update_memory_ui() -> void:
	var observed_count := 0
	for is_done in observed_points.values():
		if is_done:
			observed_count += 1

	progress_label.text = "调查进度：%d / %d" % [observed_count, observed_points.size()]
	complete_button.visible = completion_status
	complete_button.disabled = not completion_status


func _on_complete_pressed() -> void:
	if not completion_status:
		return
	memory_completed.emit(npc_id, memory_id)
	_return_to_npc_page()


func _on_exit_pressed() -> void:
	exit_requested.emit()
	_return_to_npc_page()


func _return_to_npc_page() -> void:
	print("[MemoryBase] 离开回忆 -> NPC: %s, Memory: %s, Done: %s" % [npc_id, memory_id, completion_status])
	# 接入主轴时，由 SceneRouter 或父节点监听 memory_completed / exit_requested 完成跳转。
