class_name NPC1ZhangYuanMemory
extends "res://scripts/memory/memory_base.gd"

## 张远 Memory 只声明人物专属调查点，公共流程由 MemoryBase 负责。

@onready var study_record: MemoryObservationPoint = %StudyRecord
@onready var degree_certificate: MemoryObservationPoint = %DegreeCertificate
@onready var interview_result: MemoryObservationPoint = %InterviewResult

var _active_unexplored_marker: CanvasItem
var _active_observation_id: StringName = &""


func _ready() -> void:
	super._ready()
	register_observation_points([
		study_record,
		degree_certificate,
		interview_result,
	])
	study_record.observation_requested.connect(_on_observation_opened.bind(study_record))
	degree_certificate.observation_requested.connect(_on_observation_opened.bind(degree_certificate))
	interview_result.observation_requested.connect(_on_observation_opened.bind(interview_result))
	%MemoryInfoPanel.observation_cancelled.connect(_on_observation_cancelled_restore_marker)
	%MemoryInfoPanel.observation_completed.connect(_on_observation_completed_keep_hidden)


func _on_observation_opened(data, point: MemoryObservationPoint) -> void:
	_active_observation_id = data.observation_id if data != null else &""
	_active_unexplored_marker = point.get_node_or_null("UnexploredMarker") as CanvasItem
	if _active_unexplored_marker != null:
		_active_unexplored_marker.hide()


func _on_observation_cancelled_restore_marker() -> void:
	if (
		_active_unexplored_marker != null
		and not is_observed(_active_observation_id)
	):
		_active_unexplored_marker.show()
	_clear_active_observation_marker()


func _on_observation_completed_keep_hidden(_observation_id) -> void:
	_clear_active_observation_marker()


func _clear_active_observation_marker() -> void:
	_active_unexplored_marker = null
	_active_observation_id = &""
