class_name NPCAMemory
extends "res://scripts/memory/memory_base.gd"

## NPC_A's first formal vertical Memory slice.
## Maintains only this memory's investigation data and UI bindings without duplicating base flow.

const OBSERVATION_DATA: Dictionary = {
	"recruitment_notice": {
		"title": "Recruitment Notice",
		"dialogue": [
			"2026 Fall Campus Recruitment.",
			"Positions: Design / Programming / Art.",
			"Note: Complete project experience preferred.",
		],
	},
	"job_search_record": {
		"title": "Job Search Record",
		"dialogue": [
			"Applications submitted: 17.",
			"Responses received: 3.",
			"Interviews reached: 1.",
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
