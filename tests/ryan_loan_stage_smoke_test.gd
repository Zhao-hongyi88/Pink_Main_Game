extends Node

const NPC_DATA_PATH := "res://data/npc/npc_a.json"
const NPC_SCENE_PATH := "res://scenes/npc/npc_base.tscn"
const BACKGROUND_01 := "res://TextureAsset/Level1/Ryan/ryan_loan_01_arrival.png"
const BACKGROUND_02 := "res://TextureAsset/Level1/Ryan/ryan_loan_02_counter.png"
const BACKGROUND_03 := "res://TextureAsset/Level1/Ryan/ryan_loan_03_submit_documents.png"
const BACKGROUND_04 := "res://TextureAsset/Level1/Ryan/ryan_loan_04_after_submit.png"

const EXPECTED_SPEAKERS := [
	"Me", "Ryan", "Me", "Ryan", "Me", "Ryan",
	"Me", "Ryan", "Ryan", "Me", "Ryan",
]
const EXPECTED_SPEAKER_DISPLAY := [
	"Me", "???", "Me", "???", "Me", "???",
	"Me", "???", "???", "Me", "Ryan",
]
const EXPECTED_TEXTS := [
	"Hello. What can I help you with today?",
	"I'd like to apply for a small loan.",
	"Of course. What will the loan be used for?",
	"Training.\nA course offered by a professional certification institute.\nThey said completing it could improve my time-value rating.",
	"Just a reminder: a training loan must be repaid with your future labor time. If the training falls short of expectations, repayment may become more difficult.",
	"(After a brief silence) I understand.",
	"Why did you choose this training provider?",
	"Because they promised to help raise my time-value rating.",
	"I just want my time...\nto have at least one chance to be needed.",
	"Your loan application has been submitted. Please hand over your application documents.\nPlease wait for the review result.",
	"(Hands over the documents) Of course. Here are my documents.",
]
const EXPECTED_FINAL_SPEAKERS := [
	"Me", "Ryan", "Ryan", "Me", "Ryan", "Ryan", "Me", "Ryan",
]
const EXPECTED_FINAL_TEXTS := [
	"After reviewing your documents, we've approved your loan application.",
	"Really... it was approved? Thank you.",
	"I hope I can finally find a job this time.",
	"I wish you the best.",
	"By the way...\nA friend of mine has been thinking about applying for a time loan too.",
	"His situation is a little more complicated than mine. But I think the people here... at least take the time to properly review every application.",
	"Thank you for your trust. If he meets the requirements, he's welcome to apply.",
	"He should be coming by in the next couple of days. Thank you.",
]


class RyanExitRoundTripProbe:
	extends Node

	func _ready() -> void:
		call_deferred("_verify_round_trip")


	func _verify_round_trip() -> void:
		await _wait_for_scene(&"MainMenu")
		var progress := GameState.get_npc_progress(&"npc_zhang_yuan")
		assert(progress != null)
		assert(progress.current_dialogue_index == 10)
		assert(progress.unlocked_keys.get("basic_info", false))
		assert(progress.revealed_note_keys == ["basic_info"])
		assert(progress.dialogue_completed)
		assert(progress.memory_ready)
		assert(not progress.memory_completed)
		assert(not GameState.is_npc_unlocked(&"npc_li_lei"))

		var main_menu := get_tree().current_scene as Control
		assert(main_menu != null)
		var start_button := main_menu.get_node("%StartButton") as Button
		assert(start_button != null and not start_button.disabled)
		start_button.pressed.emit()
		await _wait_for_scene(&"NPCBase")
		var returned_npc := get_tree().current_scene as NPCBase
		assert(returned_npc != null)
		assert(returned_npc.current_dialogue_index == 10)
		assert(returned_npc.background.texture == load(BACKGROUND_04))
		assert(returned_npc.get_node("%DialogueText").text == EXPECTED_TEXTS[10])
		assert(returned_npc.get_node("%NPCName").text == "Ryan")
		assert(returned_npc.get_node("%SpeakerName").text == "Ryan")
		assert(returned_npc._note_items_by_key["basic_info"].visible)
		assert(not returned_npc.note_detail_popup.visible)
		assert(returned_npc.dialogue_completed)
		assert(returned_npc.memory_ready)
		assert(returned_npc.get_node("%MemoryButton").visible)
		assert(not returned_npc.get_node("%MemoryButton").disabled)
		assert(returned_npc.get_node("%ContinueButton").disabled)

		returned_npc._note_items_by_key["basic_info"].pressed.emit()
		assert(returned_npc.note_detail_popup.visible)
		returned_npc.note_detail_popup.get_node("%CloseHitArea").pressed.emit()
		await get_tree().create_timer(0.35).timeout
		assert(not returned_npc.note_detail_popup.visible)
		assert(returned_npc.background.texture == load(BACKGROUND_04))
		await _capture_viewport("user://ryan_loan_stage_04_restored.png")

		returned_npc.get_node("%MemoryButton").pressed.emit()
		await _wait_for_scene(&"ZhangYuanMemory")
		var memory_scene := get_tree().current_scene
		assert(memory_scene.scene_file_path == "res://scenes/memory/npc1_zhang_yuan_memory.tscn")
		assert(StringName(memory_scene.get("npc_id")) == &"npc_zhang_yuan")
		assert(str(memory_scene.get("return_npc_data_path")) == NPC_DATA_PATH)
		await _capture_viewport("user://ryan_loan_memory.png")
		var observed_points: Dictionary = memory_scene.get("observed_points")
		for observation_id_value: Variant in observed_points.keys():
			var observation_id := str(observation_id_value)
			memory_scene.call("set_observed", observation_id)
		await get_tree().process_frame
		assert(bool(memory_scene.get("completion_status")))
		var complete_button := memory_scene.get_node("%CompleteButton") as Button
		assert(complete_button.visible and not complete_button.disabled)
		complete_button.pressed.emit()
		await _wait_for_scene(&"NPCBase")
		assert(progress.memory_completed)
		var contract_npc := get_tree().current_scene as NPCBase
		assert(contract_npc != null)
		assert(contract_npc.background.texture == load(BACKGROUND_04))
		var contract_book := contract_npc.get_node(
			"DossierPanel/TimeLoanContractButton"
		) as TextureButton
		assert(contract_book != null and contract_book.visible and not contract_book.disabled)
		assert(contract_book.texture_normal == load(
			"res://TextureAsset/Contract/time_loan_contract_book.png"
		))
		assert(not contract_npc.get_node("%MemoryButton").visible)
		await _capture_viewport("user://ryan_contract_book.png")

		contract_book.pressed.emit()
		var overlay := contract_npc.get_node("LoanContractOverlay") as LoanContractOverlay
		assert(overlay != null and overlay.visible)
		assert(overlay.contract_texture.texture == load(
			"res://TextureAsset/Contract/ryan_miller_contract.png"
		))
		assert(overlay.approval_stamp.texture == load(
			"res://TextureAsset/Contract/lifetime_repository_approved_stamp.png"
		))
		await _wait_for_contract_stamp(progress)
		assert(overlay.was_stamp_animation_played())
		assert(overlay.was_shake_played())
		assert(overlay.approval_stamp.visible)
		await _capture_viewport("user://ryan_contract_stamped.png")

		overlay.close_button.pressed.emit()
		assert(not overlay.visible)
		assert(progress.contract_reviewed)
		assert(contract_npc._final_dialogue_active)
		assert(contract_npc.get_node("%NPCName").text == EXPECTED_FINAL_SPEAKERS[0])
		assert(contract_npc.get_node("%DialogueText").text == EXPECTED_FINAL_TEXTS[0])
		var final_continue := contract_npc.get_node("%ContinueButton") as Button
		for final_index in range(1, EXPECTED_FINAL_TEXTS.size()):
			final_continue.pressed.emit()
			assert(progress.final_dialogue_index == final_index)
			assert(
				contract_npc.get_node("%NPCName").text
				== EXPECTED_FINAL_SPEAKERS[final_index]
			)
			assert(
				contract_npc.get_node("%DialogueText").text
				== EXPECTED_FINAL_TEXTS[final_index]
			)
		await _capture_viewport("user://ryan_final_dialogue_last.png")
		final_continue.pressed.emit()
		await _wait_for_scene(&"MainMenu")
		assert(progress.final_dialogue_completed)
		assert(GameState.is_npc_unlocked(&"npc_li_lei"))

		GameState.debug_unlock_all_npcs = true
		print("RYAN_LOAN_STAGE_SMOKE_TEST: PASS")
		get_tree().quit(0)


	func _wait_for_contract_stamp(progress: NPCProgress) -> void:
		var timeout_at := Time.get_ticks_msec() + 3000
		while Time.get_ticks_msec() < timeout_at:
			if progress.contract_stamped:
				return
			await get_tree().process_frame
		assert(false, "Contract stamp animation did not finish.")


	func _wait_for_scene(expected_scene_name: StringName) -> void:
		var timeout_at := Time.get_ticks_msec() + 10000
		while Time.get_ticks_msec() < timeout_at:
			var current_scene := get_tree().current_scene
			if (
				current_scene != null
				and current_scene.name == expected_scene_name
				and not SceneRouter.is_transitioning()
			):
				return
			await get_tree().process_frame
		assert(false, "Expected scene did not become active: %s" % expected_scene_name)


	func _capture_viewport(path: String) -> void:
		if DisplayServer.get_name() == "headless":
			return
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		assert(image != null and not image.is_empty())
		assert(image.save_png(path) == OK)


func _ready() -> void:
	GameState.debug_unlock_all_npcs = false
	GameState.clear_runtime_state()
	var raw_json := FileAccess.get_file_as_string(NPC_DATA_PATH)
	for forbidden_text in [
		"拒信", "很抱歉你未通过", "恭喜", "批准了你的贷款申请",
		"多久能到账", "李磊", "利率贷款",
	]:
		assert(raw_json.find(forbidden_text) == -1)

	var data := NPCData.load_from_json(NPC_DATA_PATH)
	assert(data.is_valid(), data.get_error_message())
	assert(data.npc_id == &"npc_zhang_yuan")
	assert(data.display_name == "Ryan Miller")
	assert(data.dialogue_name == "Ryan")
	assert(data.initial_background == BACKGROUND_01)
	assert(data.dialogue_complete_on_end)
	assert(data.dialogues.size() == 11)
	assert(data.dialogues[0]["background"] == BACKGROUND_02)
	assert(data.dialogues[10]["background"] == BACKGROUND_03)
	assert(data.dialogues[10]["unlock_key"] == "basic_info")
	assert(data.dialogues[10]["open_note_key"] == "basic_info")
	assert(data.dialogues[10]["after_note_background"] == BACKGROUND_04)
	for index in data.dialogues.size():
		assert(data.dialogues[index]["speaker_name"] == EXPECTED_SPEAKERS[index])
		assert(data.dialogues[index]["text"] == EXPECTED_TEXTS[index])
		if EXPECTED_SPEAKERS[index] == "Me":
			assert(data.dialogues[index]["speaker_role"] == "player")
		else:
			assert(str(data.dialogues[index].get("speaker_role", "npc")) == "npc")
	for background_path in [BACKGROUND_01, BACKGROUND_02, BACKGROUND_03, BACKGROUND_04]:
		assert(ResourceLoader.exists(background_path, "Texture2D"))

	var main_menu_scene := load("res://scenes/main/main_menu.tscn") as PackedScene
	var main_menu := main_menu_scene.instantiate() as Control
	assert(main_menu != null)
	get_tree().root.add_child.call_deferred(main_menu)
	await get_tree().process_frame
	assert(main_menu.get_parent() == get_tree().root)
	get_tree().current_scene = main_menu
	await get_tree().process_frame
	var start_button := main_menu.get_node("%StartButton") as Button
	assert(start_button != null and not start_button.disabled)
	start_button.pressed.emit()
	await _wait_for_scene(&"NPCBase")
	var npc := get_tree().current_scene as NPCBase
	assert(npc != null)
	assert(npc.scene_file_path == NPC_SCENE_PATH)
	assert(npc.npc_data_path == NPC_DATA_PATH)
	assert(npc.background.texture == load(BACKGROUND_01))
	assert(not npc.get_node("%DialoguePanel").visible)
	assert(not npc.get_node("%NamePlate").visible)
	assert(npc.get_node("%DialogueText").get_theme_font_size(&"font_size") == 20)
	assert(npc.get_node("%NPCName").get_theme_font_size(&"font_size") == 22)
	assert(npc.get_node("%DialogueText").autowrap_mode == TextServer.AUTOWRAP_WORD_SMART)
	assert(npc.get_node_or_null("CharacterLayer") == null)
	assert(npc.get_node_or_null("%CharacterPortrait") == null)
	await _capture_viewport("user://ryan_loan_stage_01.png")

	npc._reveal_first_conversation()
	await get_tree().create_timer(
		npc.dialogue_reveal_delay + npc.dialogue_reveal_duration + 0.08
	).timeout
	assert(npc.background.texture == load(BACKGROUND_02))
	assert(npc.get_node("%NamePlate").visible)
	assert(npc.get_node("%NPCName").visible)
	assert(npc.get_node("%NPCName").text == EXPECTED_SPEAKER_DISPLAY[0])
	assert(npc.get_node("%SpeakerName").text == EXPECTED_SPEAKER_DISPLAY[0])
	assert(npc.get_node("%DialogueText").text == EXPECTED_TEXTS[0])
	await _capture_viewport("user://ryan_loan_stage_02.png")

	var continue_button := npc.get_node("%ContinueButton") as Button
	for dialogue_index in range(1, 10):
		continue_button.pressed.emit()
		assert(npc.current_dialogue_index == dialogue_index)
		assert(npc.background.texture == load(BACKGROUND_02))
		assert(npc.get_node("%NPCName").text == EXPECTED_SPEAKER_DISPLAY[dialogue_index])
		assert(npc.get_node("%SpeakerName").text == EXPECTED_SPEAKER_DISPLAY[dialogue_index])
		assert(npc.get_node("%DialogueText").text == EXPECTED_TEXTS[dialogue_index])
		assert(not npc.get_node("%MemoryButton").visible)
		if dialogue_index == 1:
			await _capture_viewport("user://ryan_loan_speaker_unknown.png")

	continue_button.pressed.emit()
	assert(npc.current_dialogue_index == 10)
	assert(npc.background.texture == load(BACKGROUND_03))
	assert(npc.get_node("%NPCName").text == "Ryan")
	assert(npc.get_node("%SpeakerName").text == "Ryan")
	assert(npc.get_node("%DialogueText").text == EXPECTED_TEXTS[10])
	assert(npc.npc_progress.unlocked_keys.get("basic_info", false))
	assert(npc.npc_progress.revealed_note_keys == ["basic_info"])
	assert(npc._note_items_by_key["basic_info"].visible)
	assert(npc.note_detail_popup.visible)
	assert(npc._auto_note_interaction_locked)
	assert(continue_button.disabled)
	assert(not npc.dialogue_completed)
	assert(not npc.memory_ready)
	assert(not npc.get_node("%MemoryButton").visible)
	await _capture_viewport("user://ryan_loan_stage_03_popup.png")

	npc.advance_dialogue()
	assert(npc.current_dialogue_index == 10)
	npc.note_detail_popup.get_node("%CloseHitArea").pressed.emit()
	assert(npc.note_detail_popup.visible)
	assert(npc.background.texture == load(BACKGROUND_03))
	await get_tree().create_timer(0.35).timeout
	assert(not npc.note_detail_popup.visible)
	assert(not npc._auto_note_interaction_locked)
	assert(npc.background.texture == load(BACKGROUND_04))
	assert(npc.dialogue_completed)
	assert(npc.memory_ready)
	assert(not npc.memory_completed)
	assert(continue_button.disabled)
	assert(npc.get_node("%MemoryButton").visible)
	assert(not npc.get_node("%MemoryButton").disabled)
	await _capture_viewport("user://ryan_loan_stage_04.png")

	var probe := RyanExitRoundTripProbe.new()
	get_tree().root.add_child(probe)
	npc.get_node("%ExitButton").pressed.emit()


func _capture_viewport(path: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	assert(image != null and not image.is_empty())
	assert(image.save_png(path) == OK)


func _wait_for_scene(expected_scene_name: StringName) -> void:
	var timeout_at := Time.get_ticks_msec() + 10000
	while Time.get_ticks_msec() < timeout_at:
		var current_scene := get_tree().current_scene
		if (
			current_scene != null
			and current_scene.name == expected_scene_name
			and not SceneRouter.is_transitioning()
		):
			return
		await get_tree().process_frame
	assert(false, "Expected scene did not become active: %s" % expected_scene_name)
