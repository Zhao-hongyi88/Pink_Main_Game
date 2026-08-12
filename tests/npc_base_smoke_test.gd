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
		assert(returned_npc.get_node("%DossierPanel").visible)
		assert(returned_npc.npc_progress.revealed_note_keys == ["basic_info", "work_info"])
		var restored_basic_note: NoteItem = returned_npc._note_items_by_key["basic_info"]
		var restored_work_note: NoteItem = returned_npc._note_items_by_key["work_info"]
		assert(restored_basic_note.get_parent() == returned_npc.get_node("%RelatedSlot01"))
		assert(restored_work_note.get_parent() == returned_npc.get_node("%RelatedSlot02"))
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
		assert(main_menu.get_node("%ArchivePanel").get_node("%SelectedNPCLabel").text == "???")
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
	var note_panel: Control = npc_base.get_node("%DossierPanel")
	var note_board_area: Control = npc_base.get_node("%RelatedDataArea")
	var note_detail_popup: Control = npc_base.get_node("%NoteDetailPopup")
	var memory_button: Button = npc_base.get_node("%MemoryButton")
	var profile_hover: Node = npc_base.get_node("%DossierPanel/ProfileBoard/HoverEffect")
	var memory_hover: Node = memory_button.get_node("HoverEffect")
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
	assert(not npc_base.get_node("%CharacterLayer").visible)
	assert(not npc_base.get_node("%DialoguePanel").visible)
	assert(not npc_base.get_node("%NamePlate").visible)
	assert(not continue_button.disabled)
	assert(not memory_button.visible)
	assert(memory_button.disabled)
	assert(profile_hover != null)
	assert(profile_hover.get("hover_scale") == 1.05)
	assert(profile_hover.get("hover_offset") == Vector2(0.0, -4.0))
	assert(memory_hover != null)
	assert(memory_hover.get("hover_scale") == 1.08)
	assert(memory_hover.get("hover_brightness") == 1.15)
	assert(npc_base._note_items.size() == expected_notes.size())
	assert(not note_detail_popup.visible)
	assert(note_detail_popup.get_node("%DimBackground") is ColorRect)
	assert(note_detail_popup.get_node("%DocumentRoot") is Control)
	assert(note_detail_popup.get_node("%PaperPlaceholder") is ColorRect)
	assert(note_detail_popup.get_node("%PaperBackground") is TextureRect)
	assert(note_detail_popup.get_node("%PreviewImage") is TextureRect)
	assert(note_detail_popup.get_node("%DimBackground").position == Vector2.ZERO)
	assert(is_equal_approx(note_detail_popup.get_node("%DimBackground").anchor_right, 1.0))
	assert(is_equal_approx(note_detail_popup.get_node("%DimBackground").anchor_bottom, 1.0))
	assert(note_detail_popup.get_node("%DimBackground").color == Color(0, 0, 0, 0.75))
	assert(note_detail_popup.get_node("%DocumentRoot").position == Vector2(120.0, 120.0))
	assert(note_detail_popup.get_node("%DocumentRoot").size.is_equal_approx(Vector2(920.0, 480.0)))
	assert(note_detail_popup.get_node("%DocumentRoot").pivot_offset == Vector2(460.0, 240.0))
	assert(note_detail_popup.get_node("%PaperPlaceholder").position == Vector2.ZERO)
	assert(note_detail_popup.get_node("%PaperPlaceholder").size.is_equal_approx(Vector2(920.0, 480.0)))
	assert(note_detail_popup.get_node("%PaperBackground").position == Vector2.ZERO)
	assert(note_detail_popup.get_node("%PaperBackground").size.is_equal_approx(Vector2(920.0, 480.0)))
	assert(note_detail_popup.get_node("%PaperBackground").texture == null)
	assert(note_detail_popup.get_node("%PaperBackground").stretch_mode == TextureRect.STRETCH_SCALE)
	assert(note_detail_popup.get_node("%PreviewImage").position == Vector2(-100.0, -80.0))
	assert(note_detail_popup.get_node("%PreviewImage").size.is_equal_approx(Vector2(190.0, 190.0)))
	assert(note_detail_popup.get_node("%TitleLabel").position == Vector2(120.0, 70.0))
	assert(note_detail_popup.get_node("%TitleLabel").size.is_equal_approx(Vector2(650.0, 50.0)))
	assert(note_detail_popup.get_node("%TitleLabel").get_theme_font_size(&"font_size") == 30)
	assert(note_detail_popup.get_node("%ContentLabel").position == Vector2(190.0, 150.0))
	assert(note_detail_popup.get_node("%ContentLabel").size.is_equal_approx(Vector2(650.0, 260.0)))
	assert(note_detail_popup.get_node("%ContentLabel").get_theme_font_size(&"font_size") == 22)
	assert(note_detail_popup.get_node_or_null("%ContentScroll") == null)
	assert(note_detail_popup.get_node("%CloseHitArea") is TextureButton)
	assert(note_detail_popup.get_node("%CloseHitArea").position == Vector2(850.0, 20.0))
	assert(note_detail_popup.get_node("%CloseHitArea").size.is_equal_approx(Vector2(50.0, 50.0)))
	assert(note_detail_popup.get_node("%CloseHitArea").texture_normal == null)
	assert(npc_base.get_node("%CharacterPortrait").texture != null)
	assert(npc_base.get_node("%ProfilePhoto").texture != null)
	assert(npc_base.get_node("%CharacterPortrait").get_parent().name == "CharacterSlot")
	assert(npc_base.get_node("%DialogueText").get_parent().name == "DialoguePanel")
	assert(npc_base.get_node("%SpeakerName").get_parent().name == "DialoguePanel")
	assert(npc_base.get_node_or_null("%NoteContainer") == null)
	assert(npc_base.get_node_or_null("DossierPanel/NoteScroll") == null)
	assert(note_board_area.get_child_count() == 6 + expected_notes.size())
	for anchor_index in 6:
		assert(npc_base.get_node_or_null("%%RelatedSlot0%d" % (anchor_index + 1)) != null)
	var first_dialogue_index: int = npc_base.current_dialogue_index
	var first_dialogue_text: String = dialogue_text.text
	var reveal_click := InputEventMouseButton.new()
	reveal_click.button_index = MOUSE_BUTTON_LEFT
	reveal_click.pressed = true
	npc_base._unhandled_input(reveal_click)
	assert(npc_base.get_node("%CharacterLayer").visible)
	assert(npc_base.get_node("%DialoguePanel").visible)
	assert(npc_base.current_dialogue_index == first_dialogue_index)
	assert(dialogue_text.text == first_dialogue_text)
	await get_tree().create_timer(npc_base.character_reveal_duration + 0.08).timeout
	assert(npc_base.get_node("%CharacterLayer").position == npc_base._character_final_position)
	assert(npc_base.get_node("%DialoguePanel").position == npc_base._dialogue_final_position)
	assert(npc_base.get_node("%DialoguePanel").mouse_filter == Control.MOUSE_FILTER_PASS)
	assert(npc_base.get_node("%SpeakerName").mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert(npc_base.get_node("%DialogueText").mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert(npc_base.get_node("%DossierPanel").mouse_filter == Control.MOUSE_FILTER_STOP)
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
		var note_hover: Node = note_item.get_node("HoverEffect")
		assert(not note_item.visible)
		assert(note_hover != null)
		assert(note_hover.get("hover_scale") == 1.05)
		assert(note_hover.get("hover_offset") == Vector2(0.0, -3.0))
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
	final_unlock_npc._reveal_first_conversation()
	await get_tree().create_timer(final_unlock_npc.character_reveal_duration + 0.08).timeout
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
	assert(final_unlock_npc.get_node("%NamePlate").visible)
	assert(final_unlock_npc.get_node("%DossierPanel").visible)
	assert(final_unlock_npc.memory_ready)
	assert(final_continue_button.disabled)
	var original_entry_tween: Tween = final_unlock_npc._note_entry_tweens["basic_info"]
	final_unlock_npc._on_continue_pressed()
	assert(final_unlock_progress.revealed_note_keys == ["basic_info"])
	assert(final_unlock_progress.current_dialogue_index == 0)
	assert(final_unlock_npc._note_entry_tweens.size() == 1)
	assert(final_unlock_npc._note_entry_tweens["basic_info"] == original_entry_tween)
	final_unlock_npc.queue_free()

	# ContinueButton 与 DialoguePanel 共用同一推进函数；文字、左侧和空白位置均由整个 Panel 接收。
	var interaction_npc := npc_scene.instantiate() as NPCBase
	interaction_npc.npc_data_path = NPC_DATA_PATH
	add_child(interaction_npc)
	await get_tree().process_frame
	var interaction_progress := NPCProgress.new(&"dialogue_panel_interaction_test")
	var interaction_dialogues: Array[Dictionary] = [
		{"text": "Panel 01", "unlock_key": ""},
		{"text": "Panel 02", "unlock_key": ""},
		{"text": "Panel 03", "unlock_key": ""},
		{"text": "Panel 04", "unlock_key": ""},
	]
	interaction_npc.npc_progress = interaction_progress
	assert(interaction_npc.unlock_system.setup(interaction_npc._valid_unlock_keys, interaction_progress))
	assert(interaction_npc.dialogue_manager.setup(interaction_dialogues, interaction_progress))
	interaction_npc._restore_page_state()
	interaction_npc._reveal_first_conversation()
	var panel_click := InputEventMouseButton.new()
	panel_click.button_index = MOUSE_BUTTON_LEFT
	panel_click.pressed = true
	interaction_npc.get_node("%DialoguePanel").gui_input.emit(panel_click)
	assert(interaction_progress.current_dialogue_index == 0)
	await get_tree().create_timer(interaction_npc.character_reveal_duration + 0.08).timeout
	interaction_npc.get_node("%ContinueButton").pressed.emit()
	assert(interaction_progress.current_dialogue_index == 1)
	for click_position: Vector2 in [Vector2(12, 80), Vector2(120, 70), Vector2(730, 30)]:
		panel_click.position = click_position
		interaction_npc.get_node("%DialoguePanel").gui_input.emit(panel_click)
	assert(interaction_progress.dialogue_completed)
	assert(interaction_progress.current_dialogue_index == 3)
	var completed_index := interaction_progress.current_dialogue_index
	interaction_npc.get_node("%DialoguePanel").gui_input.emit(panel_click)
	assert(interaction_progress.current_dialogue_index == completed_index)
	interaction_npc.note_detail_popup.show()
	interaction_progress.dialogue_completed = false
	interaction_npc.get_node("%DialoguePanel").gui_input.emit(panel_click)
	assert(interaction_progress.current_dialogue_index == completed_index)
	interaction_npc.note_detail_popup.hide()
	interaction_npc.queue_free()

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
	assert(npc_base.get_node("%NamePlate").visible)
	assert(npc_base.get_node("%DossierPanel").visible)
	var basic_note_item: NoteItem = npc_base._note_items_by_key["basic_info"]
	assert(basic_note_item.get_parent() == npc_base.get_node("%RelatedSlot01"))
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
	assert(
		note_detail_popup.get_node("%TitleLabel").text == expected_identity_note["header"],
		"Unexpected detail title: %s" % note_detail_popup.get_node("%TitleLabel").text
	)
	assert(note_detail_popup.get_node("%ContentLabel").text == expected_identity_note["content"])
	assert(note_detail_popup.get_node("%PreviewImage").texture != null)
	assert(note_detail_popup.get_node("%PreviewImage").texture is not GradientTexture1D)
	assert(note_detail_popup.get_node("%PreviewImage").texture is not GradientTexture2D)
	assert(note_detail_popup.get_node("%DocumentRoot").scale == Vector2(0.96, 0.96))
	await get_tree().create_timer(0.35).timeout
	assert(note_detail_popup.get_node("%DocumentRoot").scale.is_equal_approx(Vector2.ONE))
	assert(is_equal_approx(note_detail_popup.get_node("%DimBackground").modulate.a, 1.0))
	note_detail_popup.get_node("%CloseHitArea").pressed.emit()
	assert(note_detail_popup.visible)
	await get_tree().create_timer(0.35).timeout
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
	await get_tree().create_timer(npc_base.note_entry_duration + 0.08).timeout
	var work_note_data: Dictionary = expected_notes.filter(
		func(note: Dictionary) -> bool: return note["key"] == "work_info"
	)[0]
	var work_note_item: NoteItem = npc_base._note_items_by_key["work_info"]
	work_note_item.pressed.emit()
	assert(note_detail_popup.get_node("%TitleLabel").text == work_note_data["header"])
	assert(note_detail_popup.get_node("%ContentLabel").text == work_note_data["content"])
	assert(note_detail_popup.get_node("%TitleLabel").text != expected_identity_note["header"])
	note_detail_popup.get_node("%CloseHitArea").pressed.emit()
	await get_tree().create_timer(0.35).timeout
	assert(not note_detail_popup.visible)

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
	note_board_area = npc_base.get_node("%RelatedDataArea")
	assert(npc_base.current_dialogue_index == 4)
	assert(dialogue_text.text == displayed_before_rebuild)
	assert(not npc_base.dialogue_completed)
	assert(not continue_button.disabled)
	assert(npc_base.get_node("%NPCName").visible)
	assert(npc_base.get_node("%IdentityLabel").visible)
	assert(npc_base.get_node("%SpeakerName").text == formal_data.display_name)
	assert(npc_base.get_node("%NamePlate").visible)
	assert(npc_base.get_node("%DossierPanel").visible)
	assert(not npc_base.get_node("%MemoryButton").visible)
	assert(npc_base.npc_progress.unlocked_keys == unlocked_before_restore)
	assert(npc_base.npc_progress.revealed_note_keys == order_before_restore)
	var restored_basic_note: NoteItem = npc_base._note_items_by_key["basic_info"]
	var restored_work_note: NoteItem = npc_base._note_items_by_key["work_info"]
	assert(restored_basic_note.get_parent() == npc_base.get_node("%RelatedSlot01"))
	assert(restored_work_note.get_parent() == npc_base.get_node("%RelatedSlot02"))
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
