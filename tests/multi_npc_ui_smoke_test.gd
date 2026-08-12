extends Node

const NPC_BASE_SCENE_PATH := "res://scenes/npc/npc_base.tscn"
const NPC_SWITCH_TEST_SCENE_PATH := "res://scenes/test/npc_switch_test.tscn"
const NPC_BASE_SCENE: PackedScene = preload(NPC_BASE_SCENE_PATH)

const NPC_CASES: Array[Dictionary] = [
	{
		"path": "res://data/npc/npc_a.json",
		"npc_id": "npc_zhang_yuan",
		"display_name": "张远",
		"dialogue_count": 5,
		"note_count": 5,
	},
	{
		"path": "res://data/npc/npc_b.json",
		"npc_id": "npc_li_lei",
		"display_name": "李磊",
		"dialogue_count": 3,
		"note_count": 2,
	},
	{
		"path": "res://data/npc/npc_c.json",
		"npc_id": "npc_liu_guilan",
		"display_name": "刘桂兰",
		"dialogue_count": 4,
		"note_count": 3,
	},
	{
		"path": "res://data/npc/npc_d.json",
		"npc_id": "npc_su_qing",
		"display_name": "苏晴",
		"dialogue_count": 5,
		"note_count": 2,
	},
	{
		"path": "res://data/npc/npc_e.json",
		"npc_id": "npc_wang_jianguo",
		"display_name": "王建国",
		"dialogue_count": 4,
		"note_count": 3,
	},
]


func _ready() -> void:
	SceneRouter.take_payload()
	_assert_development_entry_is_isolated()
	_assert_no_npc_specific_pages()

	GameState.clear_runtime_state()
	await _verify_all_npcs_use_shared_ui()

	GameState.clear_runtime_state()
	await _verify_npc_progress_isolation()

	print("MULTI_NPC_UI_SMOKE_TEST: PASS")
	get_tree().quit(0)


func _assert_development_entry_is_isolated() -> void:
	assert(ResourceLoader.exists(NPC_SWITCH_TEST_SCENE_PATH, "PackedScene"))
	var project_settings := FileAccess.get_file_as_string("res://project.godot")
	var main_menu_source := FileAccess.get_file_as_string("res://scripts/main/main_menu.gd")
	var scene_router_source := FileAccess.get_file_as_string("res://core/navigation/scene_router.gd")
	assert(project_settings.find(NPC_SWITCH_TEST_SCENE_PATH) == -1)
	assert(main_menu_source.find("npc_switch_test") == -1)
	assert(scene_router_source.find("npc_switch_test") == -1)


func _assert_no_npc_specific_pages() -> void:
	for test_case: Dictionary in NPC_CASES:
		var npc_id: String = test_case["npc_id"]
		assert(not ResourceLoader.exists("res://scenes/npc/%s.tscn" % npc_id))
		assert(not FileAccess.file_exists("res://scripts/npc/%s.gd" % npc_id))


func _verify_all_npcs_use_shared_ui() -> void:
	var progress_by_id: Dictionary = {}
	var observed_dialogue_counts: Dictionary = {}
	var observed_note_counts: Dictionary = {}

	for test_case: Dictionary in NPC_CASES:
		var data_path: String = test_case["path"]
		var npc_data := NPCData.load_from_json(data_path)
		assert(npc_data.is_valid(), "%s: %s" % [data_path, npc_data.get_error_message()])
		assert(npc_data.dialogues.size() == test_case["dialogue_count"])
		assert(npc_data.notes.size() == test_case["note_count"])
		observed_dialogue_counts[npc_data.dialogues.size()] = true
		observed_note_counts[npc_data.notes.size()] = true

		var npc_base := await _instantiate_npc(data_path)
		assert(npc_base.scene_file_path == NPC_BASE_SCENE_PATH)
		assert(npc_base.npc_data.source_path == data_path)
		assert(String(npc_base.npc_id) == test_case["npc_id"])
		assert(npc_base.get_node("%NPCName").text == test_case["display_name"])
		assert(not npc_base.get_node("%NPCName").visible)
		assert(npc_base.get_node("%CharacterArea").texture != null)
		assert(npc_base.get_node("%DialogueText").text == npc_data.dialogues[0]["text"])
		assert(npc_base.dialogue_manager._dialogues.size() == npc_data.dialogues.size())
		var note_board_area := npc_base.get_node("%NoteBoardArea") as Control
		assert(note_board_area != null)
		assert(npc_base.get_node_or_null("%NoteContainer") == null)
		assert(npc_base.get_node_or_null("NotePanel/NoteScroll") == null)
		assert(note_board_area.get_child_count() == 6 + npc_data.notes.size())
		assert(npc_base._note_items_by_key.size() == npc_data.notes.size())
		assert(not npc_base.get_node("%NotePanel").visible)
		assert(not npc_base.get_node("%MemoryButton").visible)
		assert(npc_base.npc_progress.npc_id == npc_data.npc_id)
		progress_by_id[npc_data.npc_id] = npc_base.npc_progress

		var expected_revealed_keys: Array[String] = []
		var continue_button: Button = npc_base.get_node("%ContinueButton")
		for dialogue_index in npc_data.dialogues.size():
			assert(npc_base.current_dialogue_index == dialogue_index)
			assert(npc_base.get_node("%DialogueText").text == npc_data.dialogues[dialogue_index]["text"])
			var unlock_key := str(npc_data.dialogues[dialogue_index]["unlock_key"])
			continue_button.pressed.emit()
			if not unlock_key.is_empty() and not expected_revealed_keys.has(unlock_key):
				expected_revealed_keys.append(unlock_key)
				assert(bool(npc_base.npc_progress.unlocked_keys.get(unlock_key, false)))
				var note_item: NoteItem = npc_base._note_items_by_key[unlock_key]
				assert(note_item.visible)
				var anchor_name := "%%NoteAnchor_0%d" % expected_revealed_keys.size()
				assert(note_item.get_parent() == npc_base.get_node(anchor_name))
				assert(npc_base._note_entry_tweens.has(unlock_key))
				assert(note_item.disabled)
				await get_tree().create_timer(npc_base.note_entry_duration + 0.08).timeout
				assert(not npc_base._note_entry_tweens.has(unlock_key))
				assert(note_item.position == Vector2.ZERO)
				assert(note_item.scale == Vector2.ONE)
				assert(is_equal_approx(note_item.rotation, 0.0))
				assert(is_equal_approx(note_item.modulate.a, 1.0))
				assert(not note_item.disabled)
				var note_data: Dictionary = npc_data.notes.filter(
					func(note: Dictionary) -> bool: return note["key"] == unlock_key
				)[0]
				note_item.pressed.emit()
				var detail_popup := npc_base.get_node("%NoteDetailPopup") as Control
				assert(detail_popup.visible)
				assert(detail_popup.get_node("%TitleLabel").text == note_data["header"])
				assert(detail_popup.get_node("%ContentLabel").text == note_data["content"])
				detail_popup.get_node("%CloseButton").pressed.emit()
				assert(not detail_popup.visible)
			if StringName(unlock_key) == npc_data.name_unlock_key:
				assert(npc_base.get_node("%NPCName").visible)

		assert(npc_base.dialogue_completed)
		assert(npc_base.current_dialogue_index == npc_data.dialogues.size() - 1)
		assert(npc_base.npc_progress.revealed_note_keys == expected_revealed_keys)
		var visible_note_count := 0
		for note_item: NoteItem in npc_base._note_items:
			if note_item.visible:
				visible_note_count += 1
		assert(visible_note_count == expected_revealed_keys.size())
		assert(npc_base.get_node("%NPCName").visible)
		assert(npc_base.get_node("%NotePanel").visible)
		assert(npc_base.memory_ready)
		assert(npc_base.get_node("%MemoryButton").visible)
		assert(not npc_base.get_node("%MemoryButton").disabled)
		assert(continue_button.disabled)
		_dispose_npc(npc_base)

	assert(progress_by_id.size() == NPC_CASES.size())
	assert(observed_dialogue_counts.size() > 1)
	assert(observed_note_counts.size() > 1)
	for left_index in NPC_CASES.size():
		for right_index in range(left_index + 1, NPC_CASES.size()):
			var left_id: StringName = StringName(NPC_CASES[left_index]["npc_id"])
			var right_id: StringName = StringName(NPC_CASES[right_index]["npc_id"])
			assert(progress_by_id[left_id] != progress_by_id[right_id])


func _verify_npc_progress_isolation() -> void:
	var npc_b_data := NPCData.load_from_json("res://data/npc/npc_b.json")
	var npc_c_data := NPCData.load_from_json("res://data/npc/npc_c.json")
	assert(npc_b_data.is_valid())
	assert(npc_c_data.is_valid())

	# 李磊 advances far enough to unlock basic_info, but remains incomplete.
	var npc_b := await _instantiate_npc(npc_b_data.source_path)
	var npc_b_continue: Button = npc_b.get_node("%ContinueButton")
	npc_b_continue.pressed.emit()
	npc_b_continue.pressed.emit()
	var npc_b_progress: NPCProgress = npc_b.npc_progress
	var npc_b_index := npc_b.current_dialogue_index
	var npc_b_text: String = str(npc_b.get_node("%DialogueText").text)
	var npc_b_unlocked: Dictionary = npc_b_progress.unlocked_keys.duplicate(true)
	var npc_b_revealed: Array[String] = npc_b_progress.revealed_note_keys.duplicate()
	assert(npc_b_index == 2)
	assert(not npc_b_progress.dialogue_completed)
	assert(npc_b_unlocked.get("basic_info", false))
	assert(npc_b_revealed == ["basic_info"])
	assert(npc_b.get_node("%NPCName").visible)
	assert(npc_b.get_node("%NotePanel").visible)
	_dispose_npc(npc_b)

	# 刘桂兰 starts from its own untouched progress.
	var npc_c := await _instantiate_npc(npc_c_data.source_path)
	var npc_c_progress: NPCProgress = npc_c.npc_progress
	assert(npc_c_progress != npc_b_progress)
	assert(npc_c.current_dialogue_index == 0)
	assert(npc_c.get_node("%DialogueText").text == npc_c_data.dialogues[0]["text"])
	assert(not npc_c.dialogue_completed)
	assert(npc_c.unlocked_keys.is_empty())
	assert(npc_c_progress.revealed_note_keys.is_empty())
	assert(not npc_c.memory_ready)
	assert(not npc_c.memory_completed)
	assert(not npc_c.get_node("%NPCName").visible)
	assert(not npc_c.get_node("%NotePanel").visible)
	assert(not npc_c.get_node("%MemoryButton").visible)
	var npc_c_continue: Button = npc_c.get_node("%ContinueButton")
	npc_c_continue.pressed.emit()
	assert(npc_c.current_dialogue_index == 1)
	_dispose_npc(npc_c)

	# Reloading 李磊 restores exactly the state it had before 刘桂兰 was opened.
	var npc_b_reloaded := await _instantiate_npc(npc_b_data.source_path)
	assert(npc_b_reloaded.npc_progress == npc_b_progress)
	assert(npc_b_reloaded.current_dialogue_index == npc_b_index)
	assert(npc_b_reloaded.get_node("%DialogueText").text == npc_b_text)
	assert(npc_b_reloaded.npc_progress.unlocked_keys == npc_b_unlocked)
	assert(npc_b_reloaded.npc_progress.revealed_note_keys == npc_b_revealed)
	assert(not npc_b_reloaded.dialogue_completed)
	assert(not npc_b_reloaded.memory_ready)
	assert(not npc_b_reloaded.memory_completed)
	assert(npc_b_reloaded.get_node("%NPCName").visible)
	assert(npc_b_reloaded.get_node("%NotePanel").visible)
	assert(npc_b_reloaded._note_items_by_key["basic_info"].visible)
	assert(npc_b_reloaded._note_items_by_key["basic_info"].get_parent() == npc_b_reloaded.get_node("%NoteAnchor_01"))
	assert(npc_b_reloaded._note_entry_tweens.is_empty())
	assert(npc_b_reloaded._note_items_by_key["basic_info"].position == Vector2.ZERO)
	assert(npc_b_reloaded._note_items_by_key["basic_info"].scale == Vector2.ONE)
	assert(is_equal_approx(npc_b_reloaded._note_items_by_key["basic_info"].modulate.a, 1.0))
	assert(not npc_b_reloaded._note_items_by_key["basic_info"].disabled)

	# Completing 李磊 and its memory flag must not mutate any 刘桂兰 field.
	var npc_b_reloaded_continue: Button = npc_b_reloaded.get_node("%ContinueButton")
	npc_b_reloaded_continue.pressed.emit()
	assert(npc_b_reloaded.dialogue_completed)
	assert(npc_b_reloaded.memory_ready)
	assert(npc_b_reloaded.get_node("%MemoryButton").visible)
	assert(GameState.mark_memory_completed(&"npc_li_lei"))
	assert(npc_b_reloaded.memory_completed)
	assert(npc_c_progress.current_dialogue_index == 1)
	assert(not npc_c_progress.dialogue_completed)
	assert(npc_c_progress.unlocked_keys.is_empty())
	assert(npc_c_progress.revealed_note_keys.is_empty())
	assert(not npc_c_progress.memory_ready)
	assert(not npc_c_progress.memory_completed)
	_dispose_npc(npc_b_reloaded)

	# Reloading 刘桂兰 restores its own state, not 李磊's completed state.
	var npc_c_reloaded := await _instantiate_npc(npc_c_data.source_path)
	assert(npc_c_reloaded.npc_progress == npc_c_progress)
	assert(npc_c_reloaded.current_dialogue_index == 1)
	assert(npc_c_reloaded.get_node("%DialogueText").text == npc_c_data.dialogues[1]["text"])
	assert(not npc_c_reloaded.dialogue_completed)
	assert(npc_c_reloaded.unlocked_keys.is_empty())
	assert(npc_c_reloaded.npc_progress.revealed_note_keys.is_empty())
	assert(not npc_c_reloaded.memory_ready)
	assert(not npc_c_reloaded.memory_completed)
	assert(not npc_c_reloaded.get_node("%NPCName").visible)
	assert(not npc_c_reloaded.get_node("%NotePanel").visible)
	assert(not npc_c_reloaded.get_node("%MemoryButton").visible)
	_dispose_npc(npc_c_reloaded)


func _instantiate_npc(data_path: String) -> NPCBase:
	var npc_base := NPC_BASE_SCENE.instantiate() as NPCBase
	assert(npc_base != null)
	npc_base.npc_data_path = data_path
	add_child(npc_base)
	await get_tree().process_frame
	assert(npc_base.npc_data != null)
	assert(npc_base.npc_progress != null)
	return npc_base


func _dispose_npc(npc_base: NPCBase) -> void:
	remove_child(npc_base)
	npc_base.free()
