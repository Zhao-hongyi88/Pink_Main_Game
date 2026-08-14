class_name NPC2LiLeiMemory
extends "res://scripts/memory/memory_base.gd"

## 李磊 Memory 只声明人物专属调查点，公共流程由 MemoryBase 负责。

@onready var attendance_record: Area2D = %AttendanceRecord
@onready var computer_idle_time: Area2D = %ComputerIdleTime
@onready var rental_contract: Area2D = %RentalContract

var _active_unexplored_marker: CanvasItem


func _ready() -> void:
	super._ready()
	register_observation_points([
		attendance_record,
		computer_idle_time,
		rental_contract,
	])
	attendance_record.observation_requested.connect(_on_observation_opened.bind(attendance_record))
	computer_idle_time.observation_requested.connect(_on_observation_opened.bind(computer_idle_time))
	rental_contract.observation_requested.connect(_on_observation_opened.bind(rental_contract))
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
