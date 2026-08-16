class_name NPC2LiLeiMemory
extends "res://scripts/memory/memory_base.gd"

## 李磊 Memory 只声明人物专属调查点，公共流程由 MemoryBase 负责。

@onready var mother_message: Area2D = %MotherMessage
@onready var living_expense_record: Area2D = %LivingExpenseRecord
@onready var unfinished_personal_plan: Area2D = %UnfinishedPersonalPlan

var _active_unexplored_marker: CanvasItem


func _ready() -> void:
	super._ready()
	register_observation_points([
		mother_message,
		living_expense_record,
		unfinished_personal_plan,
	])
	mother_message.observation_requested.connect(_on_observation_opened.bind(mother_message))
	living_expense_record.observation_requested.connect(_on_observation_opened.bind(living_expense_record))
	unfinished_personal_plan.observation_requested.connect(_on_observation_opened.bind(unfinished_personal_plan))
	%MemoryInfoPanel.observation_cancelled.connect(_on_observation_cancelled_restore_marker)
	%MemoryInfoPanel.observation_completed.connect(_on_observation_completed_keep_hidden)


func _on_observation_opened(_data, point: Area2D) -> void:
	_active_unexplored_marker = point.get_node_or_null("UnexploredMarker") as CanvasItem
	if _active_unexplored_marker != null:
		_active_unexplored_marker.hide()


func _on_observation_cancelled_restore_marker() -> void:
	if _active_unexplored_marker != null:
		_active_unexplored_marker.show()
	_active_unexplored_marker = null


func _on_observation_completed_keep_hidden(_observation_id) -> void:
	_active_unexplored_marker = null
