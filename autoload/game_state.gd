extends Node

## 当前游戏运行期间的公共状态。关闭游戏后自然清空，不接入 SaveService。

var npc_progress: Dictionary = {}


func has_npc_progress(npc_id: StringName) -> bool:
	return not npc_id.is_empty() and npc_progress.has(npc_id)


func get_npc_progress(npc_id: StringName) -> NPCProgress:
	if not has_npc_progress(npc_id):
		return null
	return npc_progress[npc_id]


func get_or_create_npc_progress(npc_id: StringName) -> NPCProgress:
	if npc_id.is_empty():
		push_error("GameState: npc_id 不能为空。")
		return null
	if not npc_progress.has(npc_id):
		npc_progress[npc_id] = NPCProgress.new(npc_id)
	return npc_progress[npc_id]


func mark_memory_completed(npc_id: StringName) -> bool:
	var progress := get_or_create_npc_progress(npc_id)
	if progress == null:
		return false
	progress.memory_completed = true
	return true


func clear_runtime_state() -> void:
	npc_progress.clear()
