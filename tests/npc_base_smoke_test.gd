extends Node

const NPC_DATA_PATH := "res://data/npc/npc_a.json"
const NPC_SCENE_PATH := "res://scenes/npc/npc_base.tscn"
const MEMORY_SCENE_PATH := "res://scenes/memory/memory_test.tscn"


class MemoryRoundTripProbe:
	extends Node

	var expected_data_path := ""
	var expected_npc_id: StringName = &""
	var expected_dialogue_index := 0
	var expected_dialogue_text := ""
	var original_json := ""


	func _ready() -> void:
		call_deferred("_verify_round_trip")


	func _verify_round_trip() -> void:
		await get_tree().process_frame
		await get_tree().process_frame
		var memory_test := get_tree().current_scene
		assert(memory_test is Control)
		assert(memory_test.name == "MemoryTest")
		assert(memory_test.return_npc_data_path == expected_data_path)
		assert(memory_test.current_npc_id == expected_npc_id)
		assert(memory_test.get_node("Label").text == "Memory Test")

		# An incomplete Memory Back returns to the same NPCData and preserves all page state.
		var back_button: Button = memory_test.get_node("%BackButton")
		assert(not back_button.disabled)
		back_button.pressed.emit()

		await get_tree().process_frame
		await get_tree().process_frame
		var returned_npc := get_tree().current_scene
		assert(returned_npc is NPCBase)
		assert(returned_npc.npc_data_path == expected_data_path)
		assert(returned_npc.npc_id == expected_npc_id)
		assert(returned_npc.current_dialogue_index == expected_dialogue_index)
		assert(returned_npc.get_node("%DialogueText").text == expected_dialogue_text)
		assert(returned_npc.dialogue_completed)
		assert(returned_npc.get_node("%ContinueButton").disabled)
		assert(returned_npc.memory_ready)
		assert(not returned_npc.memory_completed)
		assert(returned_npc.get_node("%MemoryButton").visible)
		assert(not returned_npc.get_node("%MemoryButton").disabled)
		assert(returned_npc.get_node("%NPCName").visible)
		assert(returned_npc.get_node("%IdentityLabel").visible)
		assert(returned_npc.get_node("%SpeakerName").text == returned_npc.npc_data.display_name)
		assert(returned_npc.get_node("%NotePanel").visible)
		assert(returned_npc.npc_progress.revealed_note_keys == ["basic_info", "work_info"])
		var note_container: VBoxContainer = returned_npc.get_node("%NoteContainer")
		assert(note_container.get_child(0) == returned_npc._note_items_by_key["basic_info"])
		assert(note_container.get_child(1) == returned_npc._note_items_by_key["work_info"])
		assert(FileAccess.get_file_as_string(expected_data_path) == original_json)

		# Completing Memory marks only the current NPC, then returns home for roster progression.
		returned_npc.get_node("%MemoryButton").pressed.emit()
		await get_tree().process_frame
		await get_tree().process_frame
		memory_test = get_tree().current_scene
		assert(memory_test.name == "MemoryTest")
		var complete_button: Button = memory_test.get_node("%CompleteMemoryButton")
		assert(not complete_button.disabled)
		complete_button.pressed.emit()
		assert(GameState.get_npc_progress(expected_npc_id).memory_completed)

		await get_tree().process_frame
		await get_tree().process_frame
		var main_menu := get_tree().current_scene
		assert(main_menu is Control)
		assert(main_menu.name == "MainMenu")
		var roster: RefCounted = main_menu.get("npc_roster")
		assert(roster != null)
		var next_npc_id: StringName = roster.get_next_npc_id(expected_npc_id)
		assert(not next_npc_id.is_empty())
		assert(GameState.is_npc_unlocked(expected_npc_id))
		assert(GameState.is_npc_unlocked(next_npc_id))
		assert(GameState.selected_npc_id == next_npc_id)
		assert(main_menu.get_node("%ArchivePanel").get_node("%SelectedNPCLabel").text == "SELECTED: %s" % roster.get_display_name(next_npc_id))
		assert(FileAccess.get_file_as_string(expected_data_path) == original_json)

		print("NPC_BASE_SMOKE_TEST: PASS")
		get_tree().quit(0)


func _ready() -> void:
	GameState.clear_runtime_state()
	var original_json := FileAccess.get_file_as_string(NPC_DATA_PATH)
	var expected_data := _read_json(NPC_DATA_PATH)
	assert(not expected_data.is_empty())
	assert(expected_data["npc_id"] == "npc_a")
	assert(expected_data["portrait"] == "")
	assert(expected_data["name_unlock_key"] == "basic_info")
	assert(expected_data["memory_scene"] == MEMORY_SCENE_PATH)
	assert(ResourceLoader.exists(NPC_SCENE_PATH))
	assert(ResourceLoader.exists(MEMORY_SCENE_PATH))

	var formal_data := NPCData.load_from_json(NPC_DATA_PATH)
	assert(formal_data.is_valid(), formal_data.get_error_message())
	assert(formal_data.npc_id == StringName(expected_data["npc_id"]))
	assert(formal_data.display_name == expected_data["display_name"])
	assert(formal_data.portrait.is_empty())
	assert(formal_data.memory_scene == expected_data["memory_scene"])

	var npc_base_source := FileAccess.get_file_as_string("res://scripts/npc/npc_base.gd")
	assert(npc_base_source.find("npc_a.json") == -1)
	assert(npc_base_source.find("NPC_A") == -1)
	assert(npc_base_source.find("res://scenes/ui/npc/note_card.tscn") != -1)

	var npc_scene: PackedScene = load(NPC_SCENE_PATH)
	var npc_base := npc_scene.instantiate()
	npc_base.npc_data_path = NPC_DATA_PATH
	add_child(npc_base)
	await get_tree().process_frame

	var npc_name: Label = npc_base.get_node("%NPCName")
	var identity_label: Label = npc_base.get_node("%IdentityLabel")
	var speaker_name: Label = npc_base.get_node("%SpeakerName")
	var dialogue_text: Label = npc_base.get_node("%DialogueText")
	var continue_button: Button = npc_base.get_node("%ContinueButton")
	var note_panel: Control = npc_base.get_node("%NotePanel")
	var note_container: VBoxContainer = npc_base.get_node("%NoteContainer")
	var memory_button: Button = npc_base.get_node("%MemoryButton")
	var expected_dialogues: Array = expected_data["dialogues"]
	var expected_notes: Array = expected_data["notes"]

	# 首次进入创建默认进度，索引 0 表示当前显示第 1 条 Dialogue。
	assert(GameState.has_npc_progress(&"npc_a"))
	assert(npc_base.dialogue_manager is DialogueManager)
	assert(npc_base.unlock_system is UnlockSystem)
	assert(npc_base.current_dialogue_index == 0)
	assert(dialogue_text.text == expected_dialogues[0]["text"])
	assert(not npc_base.dialogue_completed)
	assert(not npc_base.memory_ready)
	assert(not npc_base.memory_completed)
	assert(npc_base.revealed_note_count == 0)
	assert(npc_base.npc_progress.revealed_note_keys.is_empty())
	assert(not npc_name.visible)
	assert(not identity_label.visible)
	assert(speaker_name.text == "UNKNOWN")
	assert(not note_panel.visible)
	assert(not continue_button.disabled)
	assert(not memory_button.visible)
	assert(memory_button.disabled)
	assert(note_container.get_child_count() == expected_notes.size())
	assert(npc_base.get_node("%CharacterArea").texture != null)
	var portrait_frame := npc_base.get_node("CharacterDisplay/PortraitFrame") as TextureRect
	assert(portrait_frame != null)
	assert(portrait_frame.texture != null)
	assert(portrait_frame.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert(npc_base.get_node("%CharacterArea").get_parent().name == "CharacterDisplay")
	assert(npc_base.get_node("%DialogueText").get_parent().name == "DialogueBox")
	assert(npc_base.get_node("%SpeakerName").get_parent().name == "DialogueBox")
	assert(npc_base.get_node("%NoteContainer").get_parent() is ScrollContainer)
	var expected_identity_note: Dictionary = expected_notes.filter(
		func(note: Dictionary) -> bool: return note["key"] == expected_data["name_unlock_key"]
	)[0]
	assert(identity_label.text.contains(expected_identity_note["header"]))
	assert(identity_label.text.contains(expected_identity_note["content"]))
	for style_name: StringName in [&"normal", &"hover", &"pressed", &"disabled"]:
		assert(memory_button.get_theme_stylebox(style_name) != null)

	var expected_note_keys: Array[String] = []
	for note_data: Dictionary in expected_notes:
		expected_note_keys.append(note_data["key"])
		var note_item: NoteItem = npc_base._note_items_by_key[note_data["key"]]
		assert(not note_item.visible)
		assert(note_item.get_node("NoteBackground") is TextureRect)
		assert(note_item.get_node("%NoteHeader").text == note_data["header"])
		assert(note_item.get_node("%NoteContent").text == note_data["content"])
	assert(npc_base._valid_unlock_keys == expected_note_keys)

	# NPCBase 集成：最后一条自身带 key 时，完成对话的同时仍正常解锁。
	var final_unlock_npc := npc_scene.instantiate()
	final_unlock_npc.npc_data_path = NPC_DATA_PATH
	add_child(final_unlock_npc)
	await get_tree().process_frame
	var final_unlock_progress := NPCProgress.new(&"final_unlock_test")
	var final_unlock_dialogues: Array[Dictionary] = [
		{"text": "Final Unlock Dialogue", "unlock_key": "basic_info"},
	]
	final_unlock_npc.npc_progress = final_unlock_progress
	assert(final_unlock_npc.unlock_system.setup(
		final_unlock_npc._valid_unlock_keys,
		final_unlock_progress
	))
	assert(final_unlock_npc.dialogue_manager.setup(final_unlock_dialogues, final_unlock_progress))
	final_unlock_npc._restore_page_state()
	var final_continue_button: Button = final_unlock_npc.get_node("%ContinueButton")
	final_continue_button.pressed.emit()
	assert(final_unlock_progress.dialogue_completed)
	assert(final_unlock_progress.current_dialogue_index == 0)
	assert(final_unlock_progress.unlocked_keys.get("basic_info", false))
	assert(final_unlock_progress.revealed_note_keys == ["basic_info"])
	assert(final_unlock_npc._note_items_by_key["basic_info"].visible)
	assert(final_unlock_npc.get_node("%NPCName").visible)
	assert(final_unlock_npc.get_node("%IdentityLabel").visible)
	assert(final_unlock_npc.get_node("%SpeakerName").text == formal_data.display_name)
	assert(final_unlock_npc.get_node("%NotePanel").visible)
	assert(final_unlock_npc.memory_ready)
	assert(final_continue_button.disabled)
	final_unlock_npc._on_continue_pressed()
	assert(final_unlock_progress.revealed_note_keys == ["basic_info"])
	assert(final_unlock_progress.current_dialogue_index == 0)
	final_unlock_npc.queue_free()

	# 空 key、未知 key 和第 1 条无 key 对话都不产生资料。
	assert(not npc_base.unlock_info(""))
	assert(not npc_base.unlock_info("missing_key"))
	continue_button.pressed.emit()
	assert(npc_base.current_dialogue_index == 1)
	assert(dialogue_text.text == expected_dialogues[1]["text"])
	assert(npc_base.npc_progress.current_dialogue_index == 1)
	assert(npc_base.revealed_note_count == 0)

	# 重建页面后仍显示离开前同一条 Dialogue，不重复推进也不自动跳转。
	var displayed_before_rebuild := dialogue_text.text
	remove_child(npc_base)
	npc_base.free()
	npc_base = npc_scene.instantiate()
	npc_base.npc_data_path = NPC_DATA_PATH
	add_child(npc_base)
	await get_tree().process_frame
	dialogue_text = npc_base.get_node("%DialogueText")
	continue_button = npc_base.get_node("%ContinueButton")
	assert(npc_base.current_dialogue_index == 1)
	assert(dialogue_text.text == displayed_before_rebuild)
	assert(dialogue_text.text == expected_dialogues[1]["text"])
	assert(not continue_button.disabled)

	# 推进第 2 条后解锁 basic_info；后续按实际触发顺序解锁 work_info。
	continue_button.pressed.emit()
	assert(npc_base.current_dialogue_index == 2)
	assert(npc_base.unlocked_keys.get("basic_info", false))
	assert(npc_base.npc_progress.revealed_note_keys == ["basic_info"])
	assert(npc_base.revealed_note_count == 1)
	assert(npc_base.get_node("%NPCName").visible)
	assert(npc_base.get_node("%IdentityLabel").visible)
	assert(npc_base.get_node("%SpeakerName").text == formal_data.display_name)
	assert(npc_base.get_node("%NotePanel").visible)
	assert(not npc_base.unlock_info("basic_info"))
	continue_button.pressed.emit()
	assert(npc_base.current_dialogue_index == 3)
	continue_button.pressed.emit()
	assert(npc_base.current_dialogue_index == 4)
	assert(dialogue_text.text == expected_dialogues[4]["text"])
	assert(npc_base.unlocked_keys.get("work_info", false))
	assert(npc_base.npc_progress.revealed_note_keys == ["basic_info", "work_info"])
	assert(npc_base.revealed_note_count == 2)

	# 未完成状态再次重建：完整恢复文本、便利贴顺序、姓名与资料区。
	displayed_before_rebuild = dialogue_text.text
	var unlocked_before_restore: Dictionary = npc_base.npc_progress.unlocked_keys.duplicate(true)
	var order_before_restore: Array[String] = npc_base.npc_progress.revealed_note_keys.duplicate()
	remove_child(npc_base)
	npc_base.free()
	npc_base = npc_scene.instantiate()
	npc_base.npc_data_path = NPC_DATA_PATH
	add_child(npc_base)
	await get_tree().process_frame
	dialogue_text = npc_base.get_node("%DialogueText")
	continue_button = npc_base.get_node("%ContinueButton")
	note_container = npc_base.get_node("%NoteContainer")
	assert(npc_base.current_dialogue_index == 4)
	assert(dialogue_text.text == displayed_before_rebuild)
	assert(not npc_base.dialogue_completed)
	assert(not continue_button.disabled)
	assert(npc_base.get_node("%NPCName").visible)
	assert(npc_base.get_node("%IdentityLabel").visible)
	assert(npc_base.get_node("%SpeakerName").text == formal_data.display_name)
	assert(npc_base.get_node("%NotePanel").visible)
	assert(not npc_base.get_node("%MemoryButton").visible)
	assert(npc_base.npc_progress.unlocked_keys == unlocked_before_restore)
	assert(npc_base.npc_progress.revealed_note_keys == order_before_restore)
	assert(note_container.get_child(0) == npc_base._note_items_by_key["basic_info"])
	assert(note_container.get_child(1) == npc_base._note_items_by_key["work_info"])

	# 第 5 条完成后索引仍指向正在显示的最后一条，而不是数组长度。
	continue_button.pressed.emit()
	assert(npc_base.current_dialogue_index == expected_dialogues.size() - 1)
	assert(dialogue_text.text == expected_dialogues[4]["text"])
	assert(npc_base.dialogue_completed)
	assert(npc_base.memory_ready)
	assert(continue_button.disabled)
	assert(npc_base.get_node("%MemoryButton").visible)
	assert(not npc_base.get_node("%MemoryButton").disabled)
	var revealed_before_repeat: Array[String] = npc_base.npc_progress.revealed_note_keys.duplicate()
	npc_base._on_continue_pressed()
	assert(npc_base.current_dialogue_index == expected_dialogues.size() - 1)
	assert(npc_base.npc_progress.revealed_note_keys == revealed_before_repeat)

	# 完成状态重建后 Continue 与 MemoryButton 状态必须完整恢复。
	remove_child(npc_base)
	npc_base.free()
	npc_base = npc_scene.instantiate()
	npc_base.npc_data_path = NPC_DATA_PATH
	add_child(npc_base)
	await get_tree().process_frame
	continue_button = npc_base.get_node("%ContinueButton")
	memory_button = npc_base.get_node("%MemoryButton")
	assert(npc_base.current_dialogue_index == expected_dialogues.size() - 1)
	assert(npc_base.get_node("%DialogueText").text == expected_dialogues[4]["text"])
	assert(npc_base.dialogue_completed)
	assert(npc_base.memory_ready)
	assert(continue_button.disabled)
	assert(memory_button.visible)
	assert(not memory_button.disabled)

	# NPC_A 与 NPC_B 使用不同 NPCProgress，互不影响。
	var npc_a_progress := GameState.get_npc_progress(&"npc_a")
	var npc_b_progress := GameState.get_or_create_npc_progress(&"npc_b")
	npc_b_progress.current_dialogue_index = 3
	npc_b_progress.unlocked_keys["npc_b_test"] = true
	npc_b_progress.revealed_note_keys.append("npc_b_test")
	assert(npc_a_progress.current_dialogue_index == 4)
	assert(not npc_a_progress.unlocked_keys.has("npc_b_test"))
	assert(npc_a_progress.revealed_note_keys == ["basic_info", "work_info"])
	assert(not npc_b_progress.memory_ready)

	# 真实执行 Memory 完成与返回，Probe 在切换场景后继续检查完整 UI。
	var round_trip_probe := MemoryRoundTripProbe.new()
	round_trip_probe.expected_data_path = NPC_DATA_PATH
	round_trip_probe.expected_npc_id = formal_data.npc_id
	round_trip_probe.expected_dialogue_index = expected_dialogues.size() - 1
	round_trip_probe.expected_dialogue_text = expected_dialogues[4]["text"]
	round_trip_probe.original_json = original_json
	get_tree().root.add_child(round_trip_probe)
	memory_button.pressed.emit()


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed
