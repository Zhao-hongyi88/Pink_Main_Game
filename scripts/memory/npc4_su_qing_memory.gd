class_name NPC4SuQingMemory
extends "res://scripts/memory/memory_base.gd"

## 苏晴 Memory 只声明人物专属调查点，公共流程由 MemoryBase 负责。

@onready var table_phone: Area2D = %TablePhone
@onready var hospital_boxed_meal: Area2D = %HospitalBoxedMeal
@onready var hospital_care_record: Area2D = %HospitalCareRecord

var _active_unexplored_marker: CanvasItem
var _active_observation_id := ""


func _ready() -> void:
	super._ready()
	register_observation_points([
		table_phone,
		hospital_boxed_meal,
		hospital_care_record,
	])
	table_phone.observation_requested.connect(_on_observation_opened.bind(table_phone))
	hospital_boxed_meal.observation_requested.connect(_on_observation_opened.bind(hospital_boxed_meal))
	hospital_care_record.observation_requested.connect(_on_observation_opened.bind(hospital_care_record))
	%MemoryInfoPanel.observation_cancelled.connect(_on_observation_cancelled_restore_marker)
	%MemoryInfoPanel.observation_completed.connect(_on_observation_completed_keep_hidden)


func _on_observation_opened(data, point: Area2D) -> void:
	_active_observation_id = str(data.observation_id)
	_active_unexplored_marker = point.get_node_or_null("UnexploredMarker") as CanvasItem
	if _active_unexplored_marker != null:
		_active_unexplored_marker.hide()


func _on_observation_cancelled_restore_marker() -> void:
	if _active_unexplored_marker != null and not is_observed(_active_observation_id):
		_active_unexplored_marker.show()
	_active_unexplored_marker = null
	_active_observation_id = ""


func _on_observation_completed_keep_hidden(_observation_id) -> void:
	_active_unexplored_marker = null
	_active_observation_id = ""
