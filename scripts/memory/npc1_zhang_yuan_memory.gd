class_name NPC1ZhangYuanMemory
extends "res://scripts/memory/memory_base.gd"

## 张远 Memory 只声明人物专属调查点，公共流程由 MemoryBase 负责。

@onready var study_record: Area2D = %StudyRecord
@onready var degree_certificate: Area2D = %DegreeCertificate
@onready var interview_result: Area2D = %InterviewResult


func _ready() -> void:
	super._ready()
	register_observation_points([
		study_record,
		degree_certificate,
		interview_result,
	])
