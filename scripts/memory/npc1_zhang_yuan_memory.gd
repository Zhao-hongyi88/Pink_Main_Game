class_name NPC1ZhangYuanMemory
extends MemoryBase

## 张远当前 Memory 只绑定“学习记录”这一件调查物。

@onready var study_record: MemoryObservationPoint = $ObservationPoints/StudyRecord
@onready var degree_certificate: MemoryObservationPoint = $ObservationPoints/DegreeCertificate
@onready var interview_result: MemoryObservationPoint = $ObservationPoints/InterviewResult
@onready var memory_info_panel: MemoryInfoPanel = $MemoryInfoPanel
@onready var progress_label: Label = $ProgressLabel


func _ready() -> void:
	if study_record.observation_data != null:
		register_observation(study_record.observation_data.observation_id)
	if degree_certificate.observation_data != null:
		register_observation(degree_certificate.observation_data.observation_id)
	if interview_result.observation_data != null:
		register_observation(interview_result.observation_data.observation_id)

	study_record.observation_requested.connect(_on_observation_requested)
	degree_certificate.observation_requested.connect(_on_observation_requested)
	interview_result.observation_requested.connect(_on_observation_requested)
	memory_info_panel.observation_completed.connect(_on_observation_completed)
	memory_info_panel.observation_cancelled.connect(_on_observation_cancelled)
	observation_progress_changed.connect(_on_observation_progress_changed)
	progress_label.text = get_progress_text()


func _on_observation_requested(data: MemoryObservationData) -> void:
	if inspect_observation(data.observation_id):
		memory_info_panel.show_observation(data)


func _on_observation_completed(_observation_id) -> void:
	complete_current_observation()


func _on_observation_cancelled() -> void:
	cancel_current_observation()


func _on_observation_progress_changed(_completed_count, _total_count) -> void:
	progress_label.text = get_progress_text()
