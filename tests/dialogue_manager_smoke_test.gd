extends Node


func _ready() -> void:
	var dialogues: Array[Dictionary] = [
		{"text": "Dialogue 01", "unlock_key": ""},
		{"text": "Dialogue 02", "unlock_key": "basic_info"},
		{"text": "Dialogue 03", "unlock_key": "final_info"},
	]
	var npc_a_progress := NPCProgress.new(&"npc_a")
	var manager := DialogueManager.new()
	assert(manager.setup(dialogues, npc_a_progress))

	assert(npc_a_progress.current_dialogue_index == 0)
	assert(manager.get_current_dialogue() == dialogues[0])
	assert(manager.get_current_text() == "Dialogue 01")
	assert(manager.get_current_unlock_key().is_empty())
	assert(manager.has_next())

	var result := manager.advance()
	assert(result["accepted"])
	assert(result["moved_to_next"])
	assert(result["unlock_key"] == "")
	assert(not result["dialogue_completed"])
	assert(npc_a_progress.current_dialogue_index == 1)
	assert(manager.get_current_text() == "Dialogue 02")

	result = manager.advance()
	assert(result["accepted"])
	assert(result["moved_to_next"])
	assert(result["unlock_key"] == "basic_info")
	assert(npc_a_progress.current_dialogue_index == 2)
	assert(npc_a_progress.unlocked_keys.is_empty())

	# 最后一条带 key：返回 key、完成对话，并让索引停留在最后一条。
	result = manager.advance()
	assert(result["accepted"])
	assert(not result["moved_to_next"])
	assert(result["unlock_key"] == "final_info")
	assert(result["dialogue_completed"])
	assert(npc_a_progress.dialogue_completed)
	assert(npc_a_progress.current_dialogue_index == dialogues.size() - 1)
	assert(npc_a_progress.unlocked_keys.is_empty())

	# 完成后重复调用必须安全，不能重复返回最后一条 key。
	result = manager.advance()
	assert(not result["accepted"])
	assert(not result["moved_to_next"])
	assert(result["unlock_key"] == "")
	assert(result["dialogue_completed"])
	assert(npc_a_progress.current_dialogue_index == dialogues.size() - 1)

	# 使用同一 NPCProgress 重建 Manager，仍恢复到同一条 Dialogue。
	var restored_manager := DialogueManager.new()
	assert(restored_manager.setup(dialogues, npc_a_progress))
	assert(restored_manager.get_current_text() == "Dialogue 03")
	assert(restored_manager.get_current_unlock_key() == "final_info")
	assert(not restored_manager.has_next())

	# 不同 NPCProgress 互不影响。
	var npc_b_progress := NPCProgress.new(&"npc_b")
	var npc_b_manager := DialogueManager.new()
	assert(npc_b_manager.setup(dialogues, npc_b_progress))
	assert(npc_b_manager.get_current_text() == "Dialogue 01")
	assert(npc_b_progress.current_dialogue_index == 0)
	assert(npc_a_progress.current_dialogue_index == 2)
	assert(npc_a_progress.dialogue_completed)
	assert(not npc_b_progress.dialogue_completed)

	# 空 dialogues setup 失败，但所有读取和推进接口仍安全。
	var empty_dialogues: Array[Dictionary] = []
	var empty_progress := NPCProgress.new(&"empty_test")
	var empty_manager := DialogueManager.new()
	assert(not empty_manager.setup(empty_dialogues, empty_progress))
	assert(empty_manager.get_current_dialogue().is_empty())
	assert(empty_manager.get_current_text().is_empty())
	assert(empty_manager.get_current_unlock_key().is_empty())
	assert(not empty_manager.has_next())
	result = empty_manager.advance()
	assert(not result["accepted"])
	assert(not result["moved_to_next"])
	assert(result["unlock_key"] == "")
	assert(not result["dialogue_completed"])
	assert(empty_progress.current_dialogue_index == 0)
	assert(not empty_progress.dialogue_completed)

	print("DIALOGUE_MANAGER_SMOKE_TEST: PASS")
	get_tree().quit(0)
