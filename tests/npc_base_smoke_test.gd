extends Node

const NPC_DATA_PATH := "res://data/npc/npc_a.json"
const NPC_SCENE_PATH := "res://scenes/npc/npc_base.tscn"
const MEMORY_SCENE_PATH := "res://scenes/memory/npc1_zhang_yuan_memory.tscn"


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
		await _wait_for_transition()
		var memory_scene := get_tree().current_scene
		assert(memory_scene is Control)
		assert(memory_scene.name == "ZhangYuanMemory")
		assert(memory_scene.return_npc_data_path == expected_data_path)
		assert(memory_scene.npc_id == expected_npc_id)
		assert(memory_scene.observed_points.size() == 3)

		# An incomplete Memory Back returns to the same NPCData and preserves all page state.
		var back_button: Button = memory_scene.get_node("%BackButton")
		assert(not back_button.disabled)
		back_button.pressed.emit()

		await _wait_for_transition()
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
		var restored_basic_note: NoteItem = returned_npc._note_items_by_key["basic_info"]
		var restored_work_note: NoteItem = returned_npc._note_items_by_key["work_info"]
		assert(restored_basic_note.get_parent() == returned_npc.get_node("%NoteAnchor_01"))
		assert(restored_work_note.get_parent() == returned_npc.get_node("%NoteAnchor_02"))
		assert(returned_npc._note_entry_tweens.is_empty())
		for restored_note: NoteItem in [restored_basic_note, restored_work_note]:
			assert(restored_note.position == Vector2.ZERO)
			assert(restored_note.scale == Vector2.ONE)
			assert(is_equal_approx(restored_note.rotation, 0.0))
			assert(is_equal_approx(restored_note.modulate.a, 1.0))
			assert(not restored_note.disabled)
		assert(FileAccess.get_file_as_string(expected_data_path) == original_json)

		# Completing Memory marks only the current NPC, then returns home for roster progression.
		returned_npc.get_node("%MemoryButton").pressed.emit()
		await _wait_for_transition()
		memory_scene = get_tree().current_scene
		assert(memory_scene.name == "ZhangYuanMemory")
		for observation_id in memory_scene.observed_points.keys():
			memory_scene.set_observed(observation_id)
		var complete_button: Button = memory_scene.get_node("%CompleteButton")
		assert(complete_button.visible)
		assert(not complete_button.disabled)
		complete_button.pressed.emit()
		assert(GameState.get_npc_progress(expected_npc_id).memory_completed)

		await _wait_for_transition()
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


	func _wait_for_transition() -> void:
		for _frame in 300:
			if not SceneRouter.is_transitioning():
				return
			await get_tree().process_frame
		assert(false, "Scene transition did not finish within the smoke-test timeout.")


func _ready() -> void:
	GameState.clear_runtime_state()
	var original_json := FileAccess.get_file_as_string(NPC_DATA_PATH)
	var expected_data := _read_json(NPC_DATA_PATH)
	assert(not expected_data.is_empty())
	assert(expected_data["npc_id"] == "npc_zhang_yuan")
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
	var note_board_area: Control = npc_base.get_node("%NoteBoardArea")
	var note_detail_popup: Control = npc_base.get_node("%NoteDetailPopup")
	var memory_button: Button = npc_base.get_node("%MemoryButton")
	var expected_dialogues: Array = expected_data["dialogues"]
	var expected_notes: Array = expected_data["notes"]

	# 首次进入创建默认进度，索引 0 表示当前显示第 1 条 Dialogue。
	assert(GameState.has_npc_progress(&"npc_zhang_yuan"))
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
	assert(npc_base._note_items.size() == expected_notes.size())
	assert(not note_detail_popup.visible)
	assert(npc_base.get_node("%CharacterArea").texture != null)
	var portrait_frame := npc_base.get_node("CharacterDisplay/PortraitFrame") as TextureRect
	assert(portrait_frame != null)
	assert(portrait_frame.texture != null)
	assert(portrait_frame.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert(npc_base.get_node("%CharacterArea").get_parent().name == "CharacterDisplay")
	assert(npc_base.get_node("%DialogueText").get_parent().name == "DialogueBox")
	assert(npc_base.get_node("%SpeakerName").get_parent().name == "DialogueBox")
	assert(npc_base.get_node_or_null("%NoteContainer") == null)
	assert(npc_base.get_node_or_null("NotePanel/NoteScroll") == null)
	assert(note_board_area.get_child_count() == 6 + expected_notes.size())
	for anchor_index in 6:
		assert(npc_base.get_node_or_null("%%NoteAnchor_0%d" % (anchor_index + 1)) != null)
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
		assert(note_item is Button)
		assert(note_item.get_node("NoteBackground") is TextureRect)
		assert(note_item.get_node("%NoteHeader").text == note_data["header"])
		assert(note_item.full_content == note_data["content"])
		assert(note_item.note_key == note_data["key"])
		assert(note_item.position == Vector2.ZERO)
		assert(note_item.scale == Vector2.ONE)
		assert(is_equal_approx(note_item.modulate.a, 1.0))
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
	assert(final_unlock_npc._note_entry_tweens.has("basic_info"))
	assert(final_unlock_npc.get_node("%NPCName").visible)
	assert(final_unlock_npc.get_node("%IdentityLabel").visible)
	assert(final_unlock_npc.get_node("%SpeakerName").text == formal_data.display_name)
	assert(final_unlock_npc.get_node("%NotePanel").visible)
	assert(final_unlock_npc.memory_ready)
	assert(final_continue_button.disabled)
	var original_entry_tween: Tween = final_unlock_npc._note_entry_tweens["basic_info"]
	final_unlock_npc._on_continue_pressed()
	assert(final_unlock_progress.revealed_note_keys == ["basic_info"])
	assert(final_unlock_progress.current_dialogue_index == 0)
	assert(final_unlock_npc._note_entry_tweens.size() == 1)
	assert(final_unlock_npc._note_entry_tweens["basic_info"] == original_entry_tween)
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
	note_detail_popup = npc_base.get_node("%NoteDetailPopup")
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
	var basic_note_item: NoteItem = npc_base._note_items_by_key["basic_info"]
	assert(basic_note_item.get_parent() == npc_base.get_node("%NoteAnchor_01"))
	assert(npc_base._note_entry_tweens.has("basic_info"))
	assert(basic_note_item.disabled)
	assert(basic_note_item.position == npc_base.note_entry_offset)
	assert(basic_note_item.scale == npc_base.note_entry_start_scale)
	assert(is_equal_approx(basic_note_item.rotation, -deg_to_rad(npc_base.note_entry_rotation_degrees)))
	assert(is_zero_approx(basic_note_item.modulate.a))
	await get_tree().create_timer(npc_base.note_entry_duration + 0.08).timeout
	assert(not npc_base._note_entry_tweens.has("basic_info"))
	assert(basic_note_item.position == Vector2.ZERO)
	assert(basic_note_item.scale == Vector2.ONE)
	assert(is_equal_approx(basic_note_item.rotation, 0.0))
	assert(is_equal_approx(basic_note_item.modulate.a, 1.0))
	assert(not basic_note_item.disabled)
	basic_note_item.pressed.emit()
	assert(note_detail_popup.visible)
	assert(note_detail_popup.get_node("%TitleLabel").text == expected_identity_note["header"])
	assert(note_detail_popup.get_node("%ContentLabel").text == expected_identity_note["content"])
	note_detail_popup.get_node("%CloseButton").pressed.emit()
	assert(not note_detail_popup.visible)
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
	note_board_area = npc_base.get_node("%NoteBoardArea")
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
	var restored_basic_note: NoteItem = npc_base._note_items_by_key["basic_info"]
	var restored_work_note: NoteItem = npc_base._note_items_by_key["work_info"]
	assert(restored_basic_note.get_parent() == npc_base.get_node("%NoteAnchor_01"))
	assert(restored_work_note.get_parent() == npc_base.get_node("%NoteAnchor_02"))
	assert(npc_base._note_entry_tweens.is_empty())
	for restored_note: NoteItem in [restored_basic_note, restored_work_note]:
		assert(restored_note.position == Vector2.ZERO)
		assert(restored_note.scale == Vector2.ONE)
		assert(is_equal_approx(restored_note.rotation, 0.0))
		assert(is_equal_approx(restored_note.modulate.a, 1.0))
		assert(not restored_note.disabled)

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

	# 张远与李磊使用不同 NPCProgress，互不影响。
	var npc_a_progress := GameState.get_npc_progress(&"npc_zhang_yuan")
	var npc_b_progress := GameState.get_or_create_npc_progress(&"npc_li_lei")
	npc_b_progress.current_dialogue_index = 3
	npc_b_progress.unlocked_keys["li_lei_test"] = true
	npc_b_progress.revealed_note_keys.append("li_lei_test")
	assert(npc_a_progress.current_dialogue_index == 4)
	assert(not npc_a_progress.unlocked_keys.has("li_lei_test"))
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
