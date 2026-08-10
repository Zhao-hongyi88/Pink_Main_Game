class_name NPC5WangJianGuoMemory
extends MemoryBase

## 王建国的 Memory：只绑定 NPC5 的三个调查物。

const NPC_ID := "npc5_wang_jianguo"
const MEMORY_ID := "npc5_memory_01"

@onready var community_supplies: MemoryObservationPoint = $ObservationPoints/CommunitySupplies
@onready var donation_certificates: MemoryObservationPoint = $ObservationPoints/DonationCertificates
@onready var charity_forum_record: MemoryObservationPoint = $ObservationPoints/CharityForumRecord
@onready var memory_info_panel: MemoryInfoPanel = $MemoryInfoPanel
@onready var progress_label: Label = $ProgressLabel


func _ready() -> void:
	_register_observation_point(community_supplies)
	_register_observation_point(donation_certificates)
	_register_observation_point(charity_forum_record)

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
