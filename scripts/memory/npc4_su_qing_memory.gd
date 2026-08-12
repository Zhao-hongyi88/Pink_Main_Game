class_name NPC4SuQingMemory
extends "res://scripts/memory/memory_base.gd"

## 苏晴 Memory 只声明人物专属调查点，公共流程由 MemoryBase 负责。

@onready var meeting_record: Area2D = %MeetingRecord
@onready var work_documents: Area2D = %WorkDocuments
@onready var daughter_chat_record: Area2D = %DaughterChatRecord


func _ready() -> void:
	super._ready()
	register_observation_points([
		meeting_record,
		work_documents,
		daughter_chat_record,
	])
