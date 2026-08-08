class_name MemoryBase
extends Control

## Memory 通用回忆基类
## 遵循“MemoryBase 管行为，NPC Memory 管数据”原则

signal memory_completed(p_npc_id: String, p_memory_id: String)
signal exit_requested()

@export var npc_id: String = ""
@export var memory_id: String = ""

var completion_status: bool = false
var observed_points: Dictionary = {}

# 当前正在弹窗显示的对话数据
var _current_dialogue: Array = []
var _current_dialogue_index: int = 0

# UI 节点引用
@onready var info_panel: Control = $MemoryUI/InfoPanel
@onready var title_label: Label = $MemoryUI/InfoPanel/TitleLabel
@onready var content_label: Label = $MemoryUI/InfoPanel/ContentLabel
@onready var action_button: Button = $MemoryUI/InfoPanel/ActionButton
@onready var exit_button: Button = $MemoryUI/ExitButton
@onready var complete_button: Button = $MemoryUI/CompleteButton

func _ready() -> void:
	if info_panel:
		info_panel.hide()
	
	if action_button and not action_button.pressed.is_connected(_on_action_button_pressed):
		action_button.pressed.connect(_on_action_button_pressed)
		
	if exit_button and not exit_button.pressed.is_connected(_on_exit_pressed):
		exit_button.pressed.connect(_on_exit_pressed)
		
	if complete_button and not complete_button.pressed.is_connected(_on_complete_pressed):
		complete_button.pressed.connect(_on_complete_pressed)
		
	_update_complete_button_ui()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		if info_panel and info_panel.visible:
			_close_info_panel()
			get_viewport().set_input_as_handled()
		else:
			_on_exit_pressed()
			get_viewport().set_input_as_handled()

## 通用接口：查看某个调查点
func inspect_observation(observation_id: String, observation_data: Dictionary) -> void:
	if info_panel and info_panel.visible:
		return
		
	if not observation_data.has(observation_id):
		push_warning("MemoryBase: 找不到调查点数据 -> " + observation_id)
		return
		
	var data: Dictionary = observation_data[observation_id]
	var title: String = data.get("title", "调查点")
	var dialogue: Array = data.get("dialogue", [])
	
	set_observed(observation_id)
	show_memory_info(title, dialogue)

## 检查指定调查点是否已被调查
func is_observed(observation_id: String) -> bool:
	return observed_points.get(observation_id, false)

## 标记调查点为已调查
func set_observed(observation_id: String) -> void:
	observed_points[observation_id] = true
	check_completion_condition()

## 检查回忆完成条件（默认全部调查点已查看即完成）
func check_completion_condition() -> void:
	if observed_points.is_empty():
		return
		
	var all_done: bool = true
	for key in observed_points:
		if not observed_points[key]:
			all_done = false
			break
			
	if all_done:
		completion_status = true
		_update_complete_button_ui()

## 弹出通用信息/对话弹窗
func show_memory_info(title: String, dialogue_lines: Array) -> void:
	if not info_panel:
		return
		
	_current_dialogue = dialogue_lines
	_current_dialogue_index = 0
	
	if title_label:
		title_label.text = title
		
	_show_current_line()
	info_panel.show()

func _show_current_line() -> void:
	if _current_dialogue_index < _current_dialogue.size():
		if content_label:
			content_label.text = str(_current_dialogue[_current_dialogue_index])
			
		if action_button:
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
	if info_panel:
		info_panel.hide()

func _update_complete_button_ui() -> void:
	if complete_button:
		complete_button.visible = completion_status
		complete_button.disabled = not completion_status

func _on_complete_pressed() -> void:
	if completion_status:
		memory_completed.emit(npc_id, memory_id)
		_return_to_npc_page()

func _on_exit_pressed() -> void:
	exit_requested.emit()
	_return_to_npc_page()

func _return_to_npc_page() -> void:
	print("[MemoryBase] 离开回忆 -> NPC: %s, Memory: %s, Done: %s" % [npc_id, memory_id, completion_status])
	# 可通过 SceneRouter 或场景释放进行返回，此处预留平滑退出逻辑
