class_name NPCAMemory
extends MemoryBase

## NPC_A 的第一个正式 Memory 纵向样板。
## 只维护本回忆的调查数据和 UI 节点绑定，不复制基类流程。

const OBSERVATION_DATA: Dictionary = {
	"recruitment_notice": {
		"title": "招聘公告",
		"dialogue": [
			"2026 秋季校园招聘。",
			"岗位：策划 / 程序 / 美术。",
			"备注：有完整项目经验者优先。",
		],
	},
	"job_search_record": {
		"title": "求职记录",
		"dialogue": [
			"投递次数：17。",
			"收到回复：3。",
			"进入面试：1。",
		],
	},
}

@onready var recruitment_notice_button: Button = $ObservationPoints/RecruitmentNotice
@onready var job_search_record_button: Button = $ObservationPoints/JobSearchRecord


func _ready() -> void:
	register_observations(OBSERVATION_DATA.keys())
	super._ready()
	_bind_observation_button(recruitment_notice_button, "recruitment_notice")
	_bind_observation_button(job_search_record_button, "job_search_record")


func _bind_observation_button(button: Button, observation_id: String) -> void:
	button.pressed.connect(_on_observation_selected.bind(observation_id))


func _on_observation_selected(observation_id: String) -> void:
	inspect_observation(observation_id, OBSERVATION_DATA)
