class_name NPCProgress
extends RefCounted

## 单个 NPC 的运行时进度。只保存内存状态，不负责 UI、导航、静态数据或磁盘存档。

var npc_id: StringName = &""
var current_dialogue_index := 0
var dialogue_completed := false
var unlocked_keys: Dictionary = {}
var revealed_note_keys: Array[String] = []
var memory_ready := false
var memory_completed := false
var contract_stamped := false
var contract_reviewed := false
var final_dialogue_index := 0
var final_dialogue_completed := false


func _init(progress_npc_id: StringName = &"") -> void:
	npc_id = progress_npc_id
