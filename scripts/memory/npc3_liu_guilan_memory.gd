class_name NPC3LiuGuiLanMemory
extends "res://scripts/memory/memory_base.gd"

@onready var employee_overtime_statistics: MemoryObservationPoint = %EmployeeOvertimeStatistics
@onready var li_lei_employee_file: MemoryObservationPoint = %LiLeiEmployeeFile
@onready var project_leader_list: MemoryObservationPoint = %ProjectLeaderList

var _active_unexplored_marker: CanvasItem
var _active_observation_id: StringName = &""


func _ready() -> void:
	super._ready()
	register_observation_points([
		employee_overtime_statistics,
		li_lei_employee_file,
		project_leader_list,
	])
	employee_overtime_statistics.observation_requested.connect(
		_on_observation_opened.bind(employee_overtime_statistics)
	)
	li_lei_employee_file.observation_requested.connect(
		_on_observation_opened.bind(li_lei_employee_file)
	)
	project_leader_list.observation_requested.connect(
		_on_observation_opened.bind(project_leader_list)
	)
	%MemoryInfoPanel.observation_cancelled.connect(_on_observation_cancelled_restore_marker)
	%MemoryInfoPanel.observation_completed.connect(_on_observation_completed_keep_hidden)


func _on_observation_opened(data, point: MemoryObservationPoint) -> void:
	_active_observation_id = data.observation_id if data != null else &""
	_active_unexplored_marker = point.get_node_or_null("UnexploredMarker") as CanvasItem
	if _active_unexplored_marker != null:
		_active_unexplored_marker.hide()


func _on_observation_cancelled_restore_marker() -> void:
	if _active_unexplored_marker != null and not is_observed(_active_observation_id):
		_active_unexplored_marker.show()
	_clear_active_observation_marker()


func _on_observation_completed_keep_hidden(_observation_id) -> void:
	_clear_active_observation_marker()


func _clear_active_observation_marker() -> void:
	_active_unexplored_marker = null
	_active_observation_id = &""
