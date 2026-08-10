class_name NPC4SuQingMemory
extends MemoryBase

## 苏晴的 Memory：只绑定 NPC4 的三个调查物。

const NPC_ID := "npc4_su_qing"
const MEMORY_ID := "npc4_memory_01"

@onready var meeting_record: MemoryObservationPoint = $ObservationPoints/MeetingRecord
@onready var work_documents: MemoryObservationPoint = $ObservationPoints/WorkDocuments
@onready var daughter_chat_record: MemoryObservationPoint = $ObservationPoints/DaughterChatRecord
@onready var memory_info_panel: MemoryInfoPanel = $MemoryInfoPanel
@onready var progress_label: Label = $ProgressLabel


func _ready() -> void:
	_register_observation_point(meeting_record)
	_register_observation_point(work_documents)
	_register_observation_point(daughter_chat_record)

	memory_info_panel.observation_completed.connect(_on_observation_completed)
	memory_info_panel.observation_cancelled.connect(_on_observation_cancelled)
	observation_progress_changed.connect(_on_observation_progress_changed)
	progress_label.text = get_progress_text()


func _register_observation_point(point: MemoryObservationPoint) -> void:
	if point.observation_data != null:
		register_observation(point.observation_data.observation_id)
	point.observation_requested.connect(_on_observation_requested)


func _on_observation_requested(data: MemoryObservationData) -> void:
	if inspect_observation(data.observation_id):
		memory_info_panel.show_observation(data)


func _on_observation_completed(_observation_id) -> void:
	complete_current_observation()


func _on_observation_cancelled() -> void:
	cancel_current_observation()


func _on_observation_progress_changed(_completed_count, _total_count) -> void:
	progress_label.text = get_progress_text()
