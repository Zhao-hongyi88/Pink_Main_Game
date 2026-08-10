class_name NPC3LiuGuiLanMemory
extends MemoryBase

## 刘桂兰的 Memory：只绑定 NPC3 的三个调查物。

const NPC_ID := "npc3_liu_guilan"
const MEMORY_ID := "npc3_memory_01"

@onready var medical_record: MemoryObservationPoint = $ObservationPoints/MedicalRecord
@onready var treatment_bill: MemoryObservationPoint = $ObservationPoints/TreatmentBill
@onready var treatment_bed: MemoryObservationPoint = $ObservationPoints/TreatmentBed
@onready var memory_info_panel: MemoryInfoPanel = $MemoryInfoPanel
@onready var progress_label: Label = $ProgressLabel


func _ready() -> void:
	_register_observation_point(medical_record)
	_register_observation_point(treatment_bill)
	_register_observation_point(treatment_bed)

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
