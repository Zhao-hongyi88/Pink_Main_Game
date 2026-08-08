class_name NPCAMemory
extends MemoryBase

## NPC_A 专属回忆 Demo
## 场景：秋招 / 招聘现场
## 继承 MemoryBase，只负责 NPC_A 的专属数据与节点绑定

var observation_data: Dictionary = {
	"recruitment_notice": {
		"title": "招聘公告",
		"dialogue": [
			"2026 秋季校园招聘",
			"招聘岗位：策划 / 程序 / 美术",
			"要求：相关项目经验优先。"
		]
	},
	"job_search_record": {
		"title": "求职记录",
		"dialogue": [
			"投递次数：17",
			"收到回复：3",
			"进入面试：1"
		]
	}
}

@onready var recruitment_notice_area: Area2D = $ObservationPoints/RecruitmentNotice/Area2D
@onready var job_search_record_area: Area2D = $ObservationPoints/JobSearchRecord/Area2D

func _init() -> void:
	npc_id = "npc_a"
	memory_id = "npc_a_memory_01"

func _ready() -> void:
	# 初始化观察状态记录
	observed_points = {
		"recruitment_notice": false,
		"job_search_record": false
	}
	
	super._ready()
	_setup_observation_hitbox(recruitment_notice_area, "recruitment_notice")
	_setup_observation_hitbox(job_search_record_area, "job_search_record")

## 绑定透明 Hitbox 的 Hover 与点击事件
func _setup_observation_hitbox(area: Area2D, obs_id: String) -> void:
	if not area:
		return
		
	area.mouse_entered.connect(func():
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	)
	
	area.mouse_exited.connect(func():
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	)
	
	area.input_event.connect(func(_viewport: Node, event: InputEvent, _shape_idx: int):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_on_observation_clicked(obs_id)
	)

func _on_observation_clicked(obs_id: String) -> void:
	inspect_observation(obs_id, observation_data)
