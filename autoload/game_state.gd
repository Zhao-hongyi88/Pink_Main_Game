extends Node

## 当前游戏运行期间的公共状态。关闭游戏后自然清空，不接入 SaveService。

var npc_progress: Dictionary = {}
var selected_npc_id: StringName = &""
var unlocked_npc_ids: Dictionary = {}


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


func initialize_npc_access(roster: RefCounted) -> bool:
	if roster == null or not roster.is_valid():
		return false
	var ordered_npc_ids: Array[StringName] = roster.get_ordered_npc_ids()
	if ordered_npc_ids.is_empty():
		return false

	if unlocked_npc_ids.is_empty():
		var first_npc_id: StringName = roster.get_first_npc_id()
		if not unlock_npc(first_npc_id):
			return false
		selected_npc_id = first_npc_id
		return true

	if not selected_npc_id.is_empty() and is_npc_unlocked(selected_npc_id) and ordered_npc_ids.has(selected_npc_id):
		return true
	for npc_id: StringName in ordered_npc_ids:
		if is_npc_unlocked(npc_id):
			selected_npc_id = npc_id
			return true
	return false


func is_npc_unlocked(npc_id: StringName) -> bool:
	return not npc_id.is_empty() and bool(unlocked_npc_ids.get(npc_id, false))


func unlock_npc(npc_id: StringName) -> bool:
	if npc_id.is_empty() or is_npc_unlocked(npc_id):
		return false
	unlocked_npc_ids[npc_id] = true
	return true


func select_npc(npc_id: StringName) -> bool:
	if not is_npc_unlocked(npc_id):
		return false
	selected_npc_id = npc_id
	return true


func advance_from_completed_progress(roster: RefCounted) -> StringName:
	if roster == null or not roster.is_valid():
		return &""
	var latest_new_unlock: StringName = &""
	for npc_id: StringName in roster.get_ordered_npc_ids():
		var progress := get_npc_progress(npc_id)
		if progress == null or not progress.memory_completed:
			continue
		var next_npc_id: StringName = roster.get_next_npc_id(npc_id)
		if next_npc_id.is_empty():
			continue
		if unlock_npc(next_npc_id):
			selected_npc_id = next_npc_id
			latest_new_unlock = next_npc_id
	return latest_new_unlock


func clear_runtime_state() -> void:
	npc_progress.clear()
	selected_npc_id = &""
	unlocked_npc_ids.clear()
