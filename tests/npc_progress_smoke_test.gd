extends Node

const NPC_DATA_PATH := "res://data/npc/npc_a.json"


func _ready() -> void:
	GameState.clear_runtime_state()
	var original_json := FileAccess.get_file_as_string(NPC_DATA_PATH)

	assert(not GameState.has_npc_progress(&"npc_a"))
	assert(not GameState.has_npc_progress(&"npc_b"))

	var npc_a_progress := GameState.get_or_create_npc_progress(&"npc_a")
	assert(npc_a_progress is NPCProgress)
	assert(npc_a_progress.npc_id == &"npc_a")
	assert(npc_a_progress.current_dialogue_index == 0)
	assert(not npc_a_progress.dialogue_completed)
	assert(npc_a_progress.unlocked_keys.is_empty())
	assert(npc_a_progress.revealed_note_keys.is_empty())
	assert(not npc_a_progress.memory_ready)
	assert(not npc_a_progress.memory_completed)

	npc_a_progress.current_dialogue_index = 2
	npc_a_progress.unlocked_keys["basic_info"] = true
	npc_a_progress.revealed_note_keys.append("basic_info")
	assert(GameState.get_or_create_npc_progress(&"npc_a") == npc_a_progress)

	var npc_b_progress := GameState.get_or_create_npc_progress(&"npc_b")
	assert(npc_b_progress is NPCProgress)
	assert(npc_b_progress != npc_a_progress)
	assert(npc_b_progress.current_dialogue_index == 0)
	assert(npc_b_progress.unlocked_keys.is_empty())
	assert(npc_b_progress.revealed_note_keys.is_empty())

	npc_b_progress.current_dialogue_index = 4
	npc_b_progress.unlocked_keys["npc_b_test"] = true
	npc_b_progress.revealed_note_keys.append("npc_b_test")
	assert(npc_a_progress.current_dialogue_index == 2)
	assert(npc_a_progress.unlocked_keys.has("basic_info"))
	assert(not npc_a_progress.unlocked_keys.has("npc_b_test"))
	assert(npc_a_progress.revealed_note_keys == ["basic_info"])

	assert(GameState.mark_memory_completed(&"npc_a"))
	assert(npc_a_progress.memory_completed)
	assert(not npc_b_progress.memory_completed)

	var progress_source := FileAccess.get_file_as_string("res://scripts/npc/npc_progress.gd")
	var game_state_source := FileAccess.get_file_as_string("res://autoload/game_state.gd")
	assert(progress_source.find("revealed_note_count") == -1)
	assert(game_state_source.find("SaveService.") == -1)
	assert(game_state_source.find("FileAccess") == -1)
	assert(FileAccess.get_file_as_string(NPC_DATA_PATH) == original_json)

	print("NPC_PROGRESS_SMOKE_TEST: PASS")
	get_tree().quit(0)
