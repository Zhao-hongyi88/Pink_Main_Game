extends Node


func _ready() -> void:
	var valid_keys: Array[String] = ["basic_info", "work_info"]
	var npc_a_progress := NPCProgress.new(&"npc_a")
	npc_a_progress.current_dialogue_index = 2
	var system := UnlockSystem.new()
	assert(system.setup(valid_keys, npc_a_progress))

	# setup 只能保存引用与合法 key，不得改动任何已有运行时状态。
	assert(npc_a_progress.current_dialogue_index == 2)
	assert(not npc_a_progress.dialogue_completed)
	assert(npc_a_progress.unlocked_keys.is_empty())
	assert(npc_a_progress.revealed_note_keys.is_empty())

	var result := system.request_unlock("")
	assert(not result["accepted"])
	assert(not result["newly_unlocked"])
	assert(result["key"] == "")
	result = system.request_unlock("missing_key")
	assert(not result["accepted"])
	assert(not result["newly_unlocked"])
	assert(result["key"] == "missing_key")
	assert(npc_a_progress.unlocked_keys.is_empty())
	assert(npc_a_progress.revealed_note_keys.is_empty())

	# 按真实触发顺序 work_info → basic_info 写入状态。
	result = system.request_unlock(" work_info ")
	assert(result["accepted"])
	assert(result["newly_unlocked"])
	assert(result["key"] == "work_info")
	assert(npc_a_progress.unlocked_keys.get("work_info", false))
	assert(npc_a_progress.revealed_note_keys == ["work_info"])
	result = system.request_unlock("basic_info")
	assert(result["accepted"])
	assert(result["newly_unlocked"])
	assert(npc_a_progress.unlocked_keys.get("basic_info", false))
	assert(npc_a_progress.revealed_note_keys == ["work_info", "basic_info"])

	# 有效但重复的 key 被识别，不能重复追加。
	result = system.request_unlock("work_info")
	assert(result["accepted"])
	assert(not result["newly_unlocked"])
	assert(npc_a_progress.revealed_note_keys == ["work_info", "basic_info"])
	assert(npc_a_progress.unlocked_keys.size() == 2)

	# UnlockSystem 不得修改 Dialogue 或 Memory 状态。
	assert(npc_a_progress.current_dialogue_index == 2)
	assert(not npc_a_progress.dialogue_completed)
	assert(not npc_a_progress.memory_ready)
	assert(not npc_a_progress.memory_completed)

	# 使用已有 NPCProgress 重新 setup，不清空、不补充、不重排状态。
	var unlocked_before: Dictionary = npc_a_progress.unlocked_keys.duplicate(true)
	var order_before: Array[String] = npc_a_progress.revealed_note_keys.duplicate()
	var restored_system := UnlockSystem.new()
	assert(restored_system.setup(valid_keys, npc_a_progress))
	assert(npc_a_progress.unlocked_keys == unlocked_before)
	assert(npc_a_progress.revealed_note_keys == order_before)

	# NPC_A 与 NPC_B 使用不同 NPCProgress，互不影响。
	var npc_b_progress := NPCProgress.new(&"npc_b")
	var npc_b_system := UnlockSystem.new()
	assert(npc_b_system.setup(valid_keys, npc_b_progress))
	result = npc_b_system.request_unlock("basic_info")
	assert(result["newly_unlocked"])
	assert(npc_b_progress.revealed_note_keys == ["basic_info"])
	assert(npc_a_progress.revealed_note_keys == ["work_info", "basic_info"])
	assert(npc_a_progress != npc_b_progress)

	# 空合法集合仍可安全工作，只会拒绝所有 key。
	var empty_keys: Array[String] = []
	var empty_system := UnlockSystem.new()
	assert(empty_system.setup(empty_keys, NPCProgress.new(&"empty")))
	result = empty_system.request_unlock("basic_info")
	assert(not result["accepted"])
	assert(not result["newly_unlocked"])

	var source := FileAccess.get_file_as_string("res://scripts/unlock/unlock_system.gd")
	for forbidden_name in ["NoteItem", "NotePanel", "NPCName", "Label", "Button", "Texture"]:
		assert(source.find(forbidden_name) == -1)

	print("UNLOCK_SYSTEM_SMOKE_TEST: PASS")
	get_tree().quit(0)
