extends Node

const NPC_BASE_SCENE_PATH := "res://scenes/npc/npc_base.tscn"
const NPC_SWITCH_TEST_SCENE_PATH := "res://scenes/test/npc_switch_test.tscn"
const NPC_BASE_SCENE: PackedScene = preload(NPC_BASE_SCENE_PATH)

const NPC_CASES: Array[Dictionary] = [
	{
		"path": "res://data/npc/npc_a.json",
		"npc_id": "npc_zhang_yuan",
		"display_name": "Ryan Miller",
		"dialogue_name": "Ryan",
		"profile_photo": "res://TextureAsset/NPC/Profile/ryan_profile.png",
		"first_speaker_name": "Me",
		"dialogue_count": 11,
		"note_count": 5,
		"dialogue_complete_on_end": true,
		"dialogue_speaker_known_from_start": false,
	},
	{
		"path": "res://data/npc/npc_b.json",
		"npc_id": "npc_li_lei",
		"display_name": "Mike Carter",
		"dialogue_name": "Mike",
		"profile_photo": "res://TextureAsset/NPC/Profile/mike_profile.png",
		"first_speaker_name": "Me",
		"dialogue_count": 10,
		"note_count": 2,
		"dialogue_complete_on_end": true,
		"dialogue_speaker_known_from_start": false,
	},
	{
		"path": "res://data/npc/npc_c.json",
		"npc_id": "npc_liu_guilan",
		"display_name": "Mary Carter",
		"dialogue_name": "Mary",
		"profile_photo": "res://TextureAsset/NPC/Profile/mary_profile.png",
		"first_speaker_name": "Me",
		"dialogue_count": 13,
		"note_count": 3,
		"dialogue_complete_on_end": true,
		"dialogue_speaker_known_from_start": false,
	},
	{
		"path": "res://data/npc/npc_d.json",
		"npc_id": "npc_su_qing",
		"display_name": "Lisa Wilson",
		"dialogue_name": "Lisa",
		"profile_photo": "res://TextureAsset/NPC/Profile/lisa_profile.png",
		"first_speaker_name": "???",
		"dialogue_count": 9,
		"note_count": 2,
		"dialogue_complete_on_end": true,
		"dialogue_speaker_known_from_start": false,
	},
	{
		"path": "res://data/npc/npc_e.json",
		"npc_id": "npc_wang_jianguo",
		"display_name": "Tom Brown",
		"dialogue_name": "Tom",
		"profile_photo": "res://TextureAsset/NPC/Profile/tom_profile.png",
		"first_speaker_name": "Tom",
		"dialogue_count": 11,
		"note_count": 3,
		"dialogue_complete_on_end": true,
		"dialogue_speaker_known_from_start": true,
	},
]


func _ready() -> void:
	SceneRouter.take_payload()
	_assert_development_entry_is_isolated()
	_assert_no_npc_specific_pages()

	GameState.clear_runtime_state()
	await _verify_all_npcs_use_shared_ui()
	await _verify_profile_photo_switching()

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


func _get_expected_speaker_display(
	dialogue: Dictionary,
	npc_data: NPCData,
	progress: NPCProgress
) -> String:
	if str(dialogue.get("speaker_role", "npc")) == "player":
		return str(dialogue.get("speaker_name", "Me"))
	if (
		npc_data.dialogue_speaker_known_from_start
		or progress.unlocked_keys.get(String(npc_data.name_unlock_key), false)
	):
		return npc_data.dialogue_name
	return "???"


func _contains_cjk(text: String) -> bool:
	for character_index in text.length():
		var codepoint := text.unicode_at(character_index)
		if codepoint >= 0x3400 and codepoint <= 0x9FFF:
			return true
	return false


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
		assert(
			npc_data.dialogue_speaker_known_from_start
			== test_case["dialogue_speaker_known_from_start"]
		)
		observed_dialogue_counts[npc_data.dialogues.size()] = true
		observed_note_counts[npc_data.notes.size()] = true

		var npc_base := await _instantiate_npc(data_path)
		assert(npc_base.scene_file_path == NPC_BASE_SCENE_PATH)
		assert(npc_base.npc_data.source_path == data_path)
		assert(String(npc_base.npc_id) == test_case["npc_id"])
		assert(npc_base.get_node("%NPCName").text == test_case["first_speaker_name"])
		assert(npc_base.get_node("%SpeakerName").text == test_case["first_speaker_name"])
		assert(not npc_base.get_node("%NPCName").visible)
		assert(npc_base.get_node_or_null("CharacterLayer") == null)
		assert(npc_base.get_node_or_null("%CharacterPortrait") == null)
		var profile_photo := npc_base.get_node("%ProfilePhoto") as TextureRect
		assert(profile_photo != null)
		assert(profile_photo.texture != null)
		assert(profile_photo.texture.resource_path == test_case["profile_photo"])
		assert(profile_photo.position == Vector2(28.0, 32.0))
		assert(profile_photo.size.is_equal_approx(Vector2(109.0, 132.0)))
		assert(profile_photo.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
		assert(profile_photo.mouse_filter == Control.MOUSE_FILTER_IGNORE)
		assert(npc_base.find_children("ProfileBoard", "Control", true, false).size() == 1)
		assert(npc_base.find_children("ProfilePhoto", "TextureRect", true, false).size() == 1)
		var dialogue_label := npc_base.get_node("%DialogueText") as Label
		var speaker_label := npc_base.get_node("%SpeakerName") as Label
		assert(dialogue_label.text == npc_data.dialogues[0]["text"])
		assert(dialogue_label.get_theme_font_size(&"font_size") == 20)
		assert(dialogue_label.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART)
		assert(speaker_label.get_theme_font_size(&"font_size") == 22)
		assert(not _contains_cjk(dialogue_label.text))
		assert(not _contains_cjk(speaker_label.text))
		assert(npc_base.dialogue_manager._dialogues.size() == npc_data.dialogues.size())
		var note_board_area := npc_base.get_node("%RelatedDataArea") as Control
		assert(note_board_area != null)
		assert(npc_base.get_node_or_null("%NoteContainer") == null)
		assert(npc_base.get_node_or_null("DossierPanel/NoteScroll") == null)
		assert(note_board_area.get_child_count() == 6 + npc_data.notes.size())
		assert(npc_base._note_items_by_key.size() == npc_data.notes.size())
		assert(not npc_base.get_node("%DialoguePanel").visible)
		assert(not npc_base.get_node("%NamePlate").visible)
		assert(not npc_base.get_node("%DossierPanel").visible)
		assert(not npc_base.get_node("%MemoryButton").visible)
		assert(npc_base.npc_progress.npc_id == npc_data.npc_id)
		progress_by_id[npc_data.npc_id] = npc_base.npc_progress
		var intro_index := npc_base.current_dialogue_index
		npc_base._reveal_first_conversation()
		assert(npc_base.get_node("%DialoguePanel").visible)
		assert(npc_base.get_node("%NamePlate").visible)
		assert(npc_base.get_node("%NPCName").visible)
		assert(npc_base.current_dialogue_index == intro_index)
		await get_tree().create_timer(
			npc_base.dialogue_reveal_delay + npc_base.dialogue_reveal_duration + 0.08
		).timeout

		var expected_revealed_keys: Array[String] = []
		var continue_button: Button = npc_base.get_node("%ContinueButton")
		for dialogue_index in npc_data.dialogues.size():
			var dialogue: Dictionary = npc_data.dialogues[dialogue_index]
			assert(npc_base.current_dialogue_index == dialogue_index)
			assert(npc_base.get_node("%DialogueText").text == dialogue["text"])
			assert(not _contains_cjk(String(npc_base.get_node("%DialogueText").text)))
			var expected_speaker := _get_expected_speaker_display(
				dialogue,
				npc_data,
				npc_base.npc_progress
			)
			assert(npc_base.get_node("%NPCName").text == expected_speaker)
			assert(npc_base.get_node("%SpeakerName").text == expected_speaker)
			assert(not _contains_cjk(String(expected_speaker)))
			var unlock_key := str(dialogue["unlock_key"])
			var open_note_key := str(dialogue.get("open_note_key", ""))
			var newly_revealed_key := ""
			if not open_note_key.is_empty():
				assert(bool(npc_base.npc_progress.unlocked_keys.get(open_note_key, false)))
				assert(npc_base.note_detail_popup.visible)
				assert(npc_base._auto_note_interaction_locked)
				var locked_index := npc_base.current_dialogue_index
				continue_button.pressed.emit()
				assert(npc_base.current_dialogue_index == locked_index)
				npc_base.note_detail_popup.get_node("%CloseHitArea").pressed.emit()
				await get_tree().create_timer(0.35).timeout
				assert(not npc_base.note_detail_popup.visible)
				assert(not npc_base._auto_note_interaction_locked)
				if not expected_revealed_keys.has(open_note_key):
					expected_revealed_keys.append(open_note_key)
					newly_revealed_key = open_note_key
			else:
				continue_button.pressed.emit()
				if not unlock_key.is_empty() and not expected_revealed_keys.has(unlock_key):
					expected_revealed_keys.append(unlock_key)
					newly_revealed_key = unlock_key

			if not newly_revealed_key.is_empty():
				assert(bool(npc_base.npc_progress.unlocked_keys.get(newly_revealed_key, false)))
				var note_item: NoteItem = npc_base._note_items_by_key[newly_revealed_key]
				assert(note_item.visible)
				assert(not note_item.get_node("Divider").visible)
				assert(not note_item.get_node("%NoteHeader").visible)
				assert(not note_item.get_node("%NoteContent").visible)
				assert(note_item.get_node("%NoteHeader").text.is_empty())
				assert(note_item.get_node("%NoteContent").text.is_empty())
				assert(note_item.tooltip_text.is_empty())
				var anchor_name := "%%RelatedSlot0%d" % expected_revealed_keys.size()
				assert(note_item.get_parent() == npc_base.get_node(anchor_name))
				if npc_base._note_entry_tweens.has(newly_revealed_key):
					assert(note_item.disabled)
				await get_tree().create_timer(npc_base.note_entry_duration + 0.08).timeout
				assert(not npc_base._note_entry_tweens.has(newly_revealed_key))
				assert(note_item.position == Vector2.ZERO)
				assert(note_item.scale == Vector2.ONE)
				assert(is_equal_approx(note_item.rotation, 0.0))
				assert(is_equal_approx(note_item.modulate.a, 1.0))
				assert(not note_item.disabled)
				var note_data: Dictionary = npc_data.notes.filter(
					func(note: Dictionary) -> bool: return note["key"] == newly_revealed_key
				)[0]
				note_item.pressed.emit()
				var detail_popup := npc_base.get_node("%NoteDetailPopup") as Control
				assert(detail_popup.visible)
				assert(detail_popup.get_node("%TitleLabel").text == note_data["header"])
				assert(detail_popup.get_node("%ContentLabel").text == note_data["content"])
				if newly_revealed_key == "basic_info":
					var title_label := detail_popup.get_node("%TitleLabel") as Label
					var content_label := detail_popup.get_node("%ContentLabel") as Label
					var paper_background := detail_popup.get_node("%PaperBackground") as Control
					assert(title_label.text == "Basic Information")
					assert(not _contains_cjk(title_label.text))
					assert(not _contains_cjk(content_label.text))
					assert(paper_background.get_global_rect().encloses(title_label.get_global_rect()))
					assert(paper_background.get_global_rect().encloses(content_label.get_global_rect()))
					assert(content_label.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART)
					await get_tree().process_frame
					assert(content_label.get_visible_line_count() == content_label.get_line_count())
					assert(detail_popup.get_node("%CloseHitArea").tooltip_text == "Close")
				detail_popup.get_node("%CloseHitArea").pressed.emit()
				assert(detail_popup.visible)
				await get_tree().create_timer(0.35).timeout
				assert(not detail_popup.visible)
			if StringName(newly_revealed_key) == npc_data.name_unlock_key:
				assert(npc_base.get_node("%NPCName").visible)
				assert(npc_base.get_node("%NamePlate").visible)
				assert(npc_base.get_node("%DossierPanel").visible)
			if (
				npc_base.current_dialogue_index == dialogue_index
				and dialogue_index < npc_data.dialogues.size() - 1
			):
				continue_button.pressed.emit()

		assert(npc_base.current_dialogue_index == npc_data.dialogues.size() - 1)
		var final_dialogue: Dictionary = npc_data.dialogues[-1]
		if (
			bool(test_case["dialogue_complete_on_end"])
			and not npc_base.dialogue_completed
			and not bool(final_dialogue.get("complete_on_note_close", true))
		):
			continue_button.pressed.emit()
		assert(npc_base.npc_progress.revealed_note_keys == expected_revealed_keys)
		var visible_note_count := 0
		for note_item: NoteItem in npc_base._note_items:
			if note_item.visible:
				visible_note_count += 1
		assert(visible_note_count == expected_revealed_keys.size())
		assert(npc_base.get_node("%NPCName").visible)
		assert(npc_base.get_node("%DossierPanel").visible)
		assert(continue_button.disabled)
		if bool(test_case["dialogue_complete_on_end"]):
			assert(npc_base.dialogue_completed)
			assert(npc_base.memory_ready)
			assert(npc_base.get_node("%MemoryButton").visible)
			assert(not npc_base.get_node("%MemoryButton").disabled)
		else:
			assert(not npc_base.dialogue_completed)
			assert(not npc_base.memory_ready)
			assert(not npc_base.get_node("%MemoryButton").visible)
			assert(not npc_base.memory_completed)
		_dispose_npc(npc_base)

	assert(progress_by_id.size() == NPC_CASES.size())
	assert(observed_dialogue_counts.size() > 1)
	assert(observed_note_counts.size() > 1)
	for left_index in NPC_CASES.size():
		for right_index in range(left_index + 1, NPC_CASES.size()):
			var left_id: StringName = StringName(NPC_CASES[left_index]["npc_id"])
			var right_id: StringName = StringName(NPC_CASES[right_index]["npc_id"])
			assert(progress_by_id[left_id] != progress_by_id[right_id])


func _verify_profile_photo_switching() -> void:
	var npc_base := await _instantiate_npc(NPC_CASES[0]["path"])
	var shared_profile_photo := npc_base.get_node("%ProfilePhoto") as TextureRect
	assert(shared_profile_photo != null)
	for test_case: Dictionary in NPC_CASES:
		assert(npc_base._load_npc_data(test_case["path"]))
		assert(npc_base.get_node("%ProfilePhoto") == shared_profile_photo)
		assert(shared_profile_photo.texture != null)
		assert(shared_profile_photo.texture.resource_path == test_case["profile_photo"])
	assert(npc_base._load_npc_data("res://tests/data/npc_background_test.json"))
	assert(shared_profile_photo.texture == null)
	_dispose_npc(npc_base)


func _verify_npc_progress_isolation() -> void:
	var npc_b_data := NPCData.load_from_json("res://data/npc/npc_b.json")
	var npc_c_data := NPCData.load_from_json("res://data/npc/npc_c.json")
	assert(npc_b_data.is_valid())
	assert(npc_c_data.is_valid())

	# Mike reaches the document interaction, unlocks basic_info, but remains incomplete.
	var npc_b := await _instantiate_npc(npc_b_data.source_path)
	npc_b._reveal_first_conversation()
	await get_tree().create_timer(
		npc_b.dialogue_reveal_delay + npc_b.dialogue_reveal_duration + 0.08
	).timeout
	var npc_b_continue: Button = npc_b.get_node("%ContinueButton")
	for _dialogue_index in range(1, 9):
		npc_b_continue.pressed.emit()
	assert(npc_b.note_detail_popup.visible)
	assert(npc_b._auto_note_interaction_locked)
	npc_b.note_detail_popup.get_node("%CloseHitArea").pressed.emit()
	await get_tree().create_timer(0.45).timeout
	var npc_b_progress: NPCProgress = npc_b.npc_progress
	var npc_b_index := npc_b.current_dialogue_index
	var npc_b_text: String = str(npc_b.get_node("%DialogueText").text)
	var npc_b_unlocked: Dictionary = npc_b_progress.unlocked_keys.duplicate(true)
	var npc_b_revealed: Array[String] = npc_b_progress.revealed_note_keys.duplicate()
	assert(npc_b_index == 8)
	assert(not npc_b_progress.dialogue_completed)
	assert(npc_b_unlocked.get("basic_info", false))
	assert(npc_b_revealed == ["basic_info"])
	assert(npc_b.get_node("%NPCName").visible)
	assert(npc_b.get_node("%DossierPanel").visible)
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
	assert(not npc_c.get_node("%DossierPanel").visible)
	assert(not npc_c.get_node("%MemoryButton").visible)
	npc_c._reveal_first_conversation()
	await get_tree().create_timer(
		npc_c.dialogue_reveal_delay + npc_c.dialogue_reveal_duration + 0.08
	).timeout
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
	assert(npc_b_reloaded.get_node("%DialoguePanel").visible)
	assert(npc_b_reloaded.get_node("%NamePlate").visible)
	assert(npc_b_reloaded.get_node("%DossierPanel").visible)
	assert(npc_b_reloaded._note_items_by_key["basic_info"].visible)
	assert(npc_b_reloaded._note_items_by_key["basic_info"].get_parent() == npc_b_reloaded.get_node("%RelatedSlot01"))
	assert(npc_b_reloaded._note_entry_tweens.is_empty())
	assert(npc_b_reloaded._note_items_by_key["basic_info"].position == Vector2.ZERO)
	assert(npc_b_reloaded._note_items_by_key["basic_info"].scale == Vector2.ONE)
	assert(is_equal_approx(npc_b_reloaded._note_items_by_key["basic_info"].modulate.a, 1.0))
	assert(not npc_b_reloaded._note_items_by_key["basic_info"].disabled)

	# Completing 李磊 and its memory flag must not mutate any 刘桂兰 field.
	var npc_b_reloaded_continue: Button = npc_b_reloaded.get_node("%ContinueButton")
	npc_b_reloaded_continue.pressed.emit()
	assert(npc_b_reloaded.current_dialogue_index == 9)
	assert(not npc_b_reloaded.dialogue_completed)
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
	assert(npc_c_reloaded.get_node("%NPCName").visible)
	assert(npc_c_reloaded.get_node("%NamePlate").visible)
	assert(npc_c_reloaded.get_node("%NPCName").text == "???")
	assert(npc_c_reloaded.get_node("%DialoguePanel").visible)
	assert(not npc_c_reloaded.get_node("%DossierPanel").visible)
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
