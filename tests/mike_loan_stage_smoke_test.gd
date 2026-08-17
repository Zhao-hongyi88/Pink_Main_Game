extends Node

const NPC_DATA_PATH := "res://data/npc/npc_b.json"
const NPC_SCENE_PATH := "res://scenes/npc/npc_base.tscn"
const MEMORY_SCENE_PATH := "res://scenes/memory/npc2_li_lei_memory.tscn"
const PROFILE_PHOTO_PATH := "res://TextureAsset/NPC/Profile/mike_profile.png"
const BACKGROUND_01 := "res://TextureAsset/Level1/Mike/mike_loan_01_arrival.png"
const BACKGROUND_02 := "res://TextureAsset/Level1/Mike/mike_loan_02_counter.png"
const BACKGROUND_03 := "res://TextureAsset/Level1/Mike/mike_loan_03_submit_documents.png"
const BACKGROUND_04 := "res://TextureAsset/Level1/Mike/mike_loan_04_after_submit.png"

const EXPECTED_SPEAKERS := [
	"Me", "Mike", "Me", "Mike", "Me",
	"Mike", "Me", "Mike", "Mike", "Me",
]
const EXPECTED_SPEAKER_DISPLAY := [
	"Me", "???", "Me", "???", "Me",
	"???", "Me", "???", "Mike", "Me",
]
const EXPECTED_TEXTS := [
	"Hello. What can I help you with today?",
	"Hello. I'd like to apply for an eighteen-month family medical time loan.",
	"Of course.\nIs the loan for your own medical care, or for a family member?",
	"It's for my mother, Mary.",
	"Eighteen months of time credit.\nIs it intended to support long-term treatment?",
	"Yes.\nShe has a chronic illness and needs continued support to sustain her time.",
	"Understood.\nPlease confirm that the time credit will be repaid through your future labor time.",
	"I understand. I reviewed the time-repayment rules before coming here to apply.",
	"(Hands over the documents) Here are my application documents.",
	"All right.\nYour documents have been registered.\nPlease wait for the review.",
]

const EXPECTED_BASIC_INFO := "Name: Mike\nAge: 24\nAddress: Pendulum Falls, Westland State\nEmail: Mike@email.com\nTime Credit Rating: B\n\nLoan History:\n• Medical Time Loan (Ongoing)\n• Current Application: Family Medical Time Loan (12 Months)"


func _ready() -> void:
	GameState.clear_runtime_state()
	_verify_data_contract()
	assert(GameState.mark_memory_completed(&"npc_zhang_yuan"))

	var main_menu := await _create_main_menu_as_current()
	_assert_mike_selected(main_menu, "???")
	var npc := await _start_mike_from_current_menu()
	_assert_initial_state(npc)
	await _capture_viewport("mike_loan_stage_01.png")

	npc._reveal_first_conversation()
	await get_tree().create_timer(
		npc.dialogue_reveal_delay + npc.dialogue_reveal_duration + 0.08
	).timeout
	_assert_dialogue_state(npc, 0, BACKGROUND_02)
	await _capture_viewport("mike_loan_stage_02.png")

	var continue_button := npc.get_node("%ContinueButton") as Button
	for dialogue_index in range(1, 5):
		continue_button.pressed.emit()
		_assert_dialogue_state(npc, dialogue_index, BACKGROUND_02)
		assert(not npc.get_node("%MemoryButton").visible)
		if dialogue_index == 1:
			await _capture_viewport("mike_loan_speaker_unknown.png")

	# Scenario A: ordinary dialogue progress restores the most recent background (stage 02).
	npc.get_node("%ExitButton").pressed.emit()
	await _wait_for_scene(&"MainMenu")
	main_menu = get_tree().current_scene as Control
	_assert_mike_selected(main_menu, "???")
	npc = await _start_mike_from_current_menu()
	_assert_dialogue_state(npc, 4, BACKGROUND_02)
	assert(not npc.note_detail_popup.visible)
	assert(not npc.get_node("%DossierPanel").visible)
	continue_button = npc.get_node("%ContinueButton") as Button

	for dialogue_index in range(5, 9):
		continue_button.pressed.emit()
		_assert_dialogue_state(
			npc,
			dialogue_index,
			BACKGROUND_03 if dialogue_index == 8 else BACKGROUND_02
		)
		assert(not npc.get_node("%MemoryButton").visible)

	assert(npc.npc_progress.unlocked_keys.get("basic_info", false))
	assert(npc.npc_progress.revealed_note_keys == ["basic_info"])
	assert(npc._note_items_by_key["basic_info"].visible)
	assert(npc._note_items_by_key["basic_info"].get_node("Divider").visible == false)
	assert(npc._note_items_by_key["basic_info"].get_node("%NoteHeader").text.is_empty())
	assert(npc._note_items_by_key["basic_info"].get_node("%NoteContent").text.is_empty())
	assert(npc.note_detail_popup.visible)
	assert(npc._auto_note_interaction_locked)
	assert(continue_button.disabled)
	assert(not npc.dialogue_completed)
	assert(not npc.memory_ready)
	assert(npc.get_node("%DossierPanel").visible)
	assert(npc.get_node("%ProfilePhoto").texture.resource_path == PROFILE_PHOTO_PATH)
	await _capture_viewport("mike_loan_stage_03_popup.png")

	# Every dialogue entry point remains locked while the automatic popup is open.
	npc.advance_dialogue()
	continue_button.pressed.emit()
	var blocked_click := InputEventMouseButton.new()
	blocked_click.button_index = MOUSE_BUTTON_LEFT
	blocked_click.pressed = true
	npc.dialogue_panel.gui_input.emit(blocked_click)
	assert(npc.current_dialogue_index == 8)
	assert(npc.background.texture == load(BACKGROUND_03))

	npc.note_detail_popup.get_node("%CloseHitArea").pressed.emit()
	assert(npc.note_detail_popup.visible)
	assert(npc.background.texture == load(BACKGROUND_03))
	continue_button.pressed.emit()
	assert(npc.current_dialogue_index == 8)
	await get_tree().create_timer(0.45).timeout
	assert(not npc.note_detail_popup.visible)
	assert(not npc._auto_note_interaction_locked)
	assert(npc.background.texture == load(BACKGROUND_04))
	assert(npc.current_dialogue_index == 8)
	assert(not npc.dialogue_completed)
	assert(not npc.memory_ready)
	assert(not npc.get_node("%MemoryButton").visible)
	await _capture_viewport("mike_loan_stage_04.png")

	# Scenario B: completed note interaction restores stage 04 without reopening the popup.
	npc.get_node("%ExitButton").pressed.emit()
	await _wait_for_scene(&"MainMenu")
	main_menu = get_tree().current_scene as Control
	_assert_mike_selected(main_menu, "Mike Carter")
	npc = await _start_mike_from_current_menu()
	_assert_dialogue_state(npc, 8, BACKGROUND_04)
	assert(not npc.note_detail_popup.visible)
	assert(npc._note_items_by_key["basic_info"].visible)
	assert(npc.get_node("%DossierPanel").visible)

	npc._note_items_by_key["basic_info"].pressed.emit()
	assert(npc.note_detail_popup.visible)
	assert(npc.note_detail_popup.get_node("%ContentLabel").text == EXPECTED_BASIC_INFO)
	npc.note_detail_popup.get_node("%CloseHitArea").pressed.emit()
	await get_tree().create_timer(0.35).timeout
	assert(not npc.note_detail_popup.visible)
	assert(npc.background.texture == load(BACKGROUND_04))

	continue_button = npc.get_node("%ContinueButton") as Button
	continue_button.pressed.emit()
	_assert_dialogue_state(npc, 9, BACKGROUND_04)
	assert(not npc.dialogue_completed)
	assert(not npc.memory_ready)
	assert(not npc.get_node("%MemoryButton").visible)
	await _capture_viewport("mike_loan_final_dialogue.png")

	continue_button.pressed.emit()
	assert(npc.current_dialogue_index == 9)
	assert(npc.dialogue_completed)
	assert(npc.memory_ready)
	assert(not npc.memory_completed)
	assert(npc.background.texture == load(BACKGROUND_04))
	assert(npc.get_node("%MemoryButton").visible)
	assert(not npc.get_node("%MemoryButton").disabled)
	assert(continue_button.disabled)
	await _capture_viewport("mike_loan_memory_ready.png")

	# Scenario C: completed dialogue restores stage 04 and the Memory button.
	npc.get_node("%ExitButton").pressed.emit()
	await _wait_for_scene(&"MainMenu")
	main_menu = get_tree().current_scene as Control
	_assert_mike_selected(main_menu, "Mike Carter")
	npc = await _start_mike_from_current_menu()
	_assert_dialogue_state(npc, 9, BACKGROUND_04)
	assert(npc.dialogue_completed)
	assert(npc.memory_ready)
	assert(not npc.memory_completed)
	assert(not npc.note_detail_popup.visible)
	assert(npc.get_node("%MemoryButton").visible)
	assert(not npc.get_node("%MemoryButton").disabled)

	npc.get_node("%MemoryButton").pressed.emit()
	await _wait_for_scene(&"LiLeiMemory")
	var memory_scene := get_tree().current_scene
	assert(memory_scene.scene_file_path == MEMORY_SCENE_PATH)
	assert(StringName(memory_scene.get("npc_id")) == &"npc_li_lei")
	assert(str(memory_scene.get("return_npc_data_path")) == NPC_DATA_PATH)
	assert(not bool(memory_scene.get("completion_status")))
	assert(not GameState.get_npc_progress(&"npc_li_lei").memory_completed)
	await _capture_viewport("mike_loan_memory.png")

	print("MIKE_LOAN_STAGE_SMOKE_TEST: PASS")
	get_tree().quit(0)


func _verify_data_contract() -> void:
	var raw_json := FileAccess.get_file_as_string(NPC_DATA_PATH)
	for forbidden_text in [
		"Placeholder dialogue", "张远", "审核通过", "拒绝", "贷款到账", "利率",
	]:
		assert(raw_json.find(forbidden_text) == -1)

	var data := NPCData.load_from_json(NPC_DATA_PATH)
	assert(data.is_valid(), data.get_error_message())
	assert(data.npc_id == &"npc_li_lei")
	assert(data.display_name == "Mike Carter")
	assert(data.dialogue_name == "Mike")
	assert(data.profile_photo == PROFILE_PHOTO_PATH)
	assert(data.initial_background == BACKGROUND_01)
	assert(data.dialogue_complete_on_end)
	assert(data.name_unlock_key == &"basic_info")
	assert(data.memory_scene == MEMORY_SCENE_PATH)
	assert(data.dialogues.size() == 10)
	assert(data.notes.size() == 2)
	assert(data.notes[0]["key"] == "basic_info")
	assert(data.notes[0]["content"] == EXPECTED_BASIC_INFO)
	assert(data.notes[1]["key"] == "b_extra_info")
	assert(data.dialogues[0]["background"] == BACKGROUND_02)
	assert(data.dialogues[8]["background"] == BACKGROUND_03)
	assert(data.dialogues[8]["unlock_key"] == "basic_info")
	assert(data.dialogues[8]["open_note_key"] == "basic_info")
	assert(data.dialogues[8]["after_note_background"] == BACKGROUND_04)
	for index in data.dialogues.size():
		assert(data.dialogues[index]["speaker_name"] == EXPECTED_SPEAKERS[index])
		assert(data.dialogues[index]["text"] == EXPECTED_TEXTS[index])
		if EXPECTED_SPEAKERS[index] == "Me":
			assert(data.dialogues[index]["speaker_role"] == "player")
		else:
			assert(str(data.dialogues[index].get("speaker_role", "npc")) == "npc")
		if index not in [0, 8]:
			assert(not data.dialogues[index].has("background"))
	for background_path in [BACKGROUND_01, BACKGROUND_02, BACKGROUND_03, BACKGROUND_04]:
		assert(ResourceLoader.exists(background_path, "Texture2D"))
		assert(load(background_path) is Texture2D)
	for data_path in [
		"res://data/npc/npc_c.json",
		"res://data/npc/npc_d.json",
		"res://data/npc/npc_e.json",
	]:
		assert(NPCData.load_from_json(data_path).is_valid())


func _assert_initial_state(npc: NPCBase) -> void:
	assert(npc != null)
	assert(npc.scene_file_path == NPC_SCENE_PATH)
	assert(npc.npc_data_path == NPC_DATA_PATH)
	assert(npc.background.texture == load(BACKGROUND_01))
	assert(not npc.get_node("%DialoguePanel").visible)
	assert(not npc.get_node("%NamePlate").visible)
	assert(not npc.get_node("%DossierPanel").visible)
	assert(not npc.get_node("%MemoryButton").visible)
	assert(npc.get_node("%ProfilePhoto").texture.resource_path == PROFILE_PHOTO_PATH)
	assert(npc.get_node("%DialogueText").get_theme_font_size(&"font_size") == 20)
	assert(npc.get_node("%NPCName").get_theme_font_size(&"font_size") == 22)
	assert(npc.get_node("%DialogueText").autowrap_mode == TextServer.AUTOWRAP_WORD_SMART)
	assert(npc.get_node_or_null("CharacterLayer") == null)
	assert(npc.get_node_or_null("%CharacterPortrait") == null)


func _assert_dialogue_state(npc: NPCBase, dialogue_index: int, background_path: String) -> void:
	assert(npc.current_dialogue_index == dialogue_index)
	assert(npc.background.texture == load(background_path))
	assert(npc.get_node("%DialogueText").text == EXPECTED_TEXTS[dialogue_index])
	assert(npc.get_node("%NPCName").text == EXPECTED_SPEAKER_DISPLAY[dialogue_index])
	assert(npc.get_node("%SpeakerName").text == EXPECTED_SPEAKER_DISPLAY[dialogue_index])
	assert(npc.get_node("%NamePlate").visible)
	if dialogue_index < 8:
		assert(not npc.npc_progress.unlocked_keys.get("basic_info", false))
	else:
		assert(npc.npc_progress.unlocked_keys.get("basic_info", false))


func _create_main_menu_as_current() -> Control:
	var main_menu_scene := load("res://scenes/main/main_menu.tscn") as PackedScene
	var main_menu := main_menu_scene.instantiate() as Control
	assert(main_menu != null)
	get_tree().root.add_child.call_deferred(main_menu)
	await get_tree().process_frame
	assert(main_menu.get_parent() == get_tree().root)
	get_tree().current_scene = main_menu
	await get_tree().process_frame
	return main_menu


func _assert_mike_selected(main_menu: Control, expected_visible_name: String) -> void:
	assert(main_menu != null)
	assert(main_menu.name == "MainMenu")
	assert(GameState.selected_npc_id == &"npc_li_lei")
	assert(GameState.is_npc_unlocked(&"npc_li_lei"))
	assert(
		main_menu.get_node("%ArchivePanel").get_node("%SelectedNPCLabel").text
		== expected_visible_name
	)


func _start_mike_from_current_menu() -> NPCBase:
	var main_menu := get_tree().current_scene as Control
	assert(main_menu != null and main_menu.name == "MainMenu")
	var start_button := main_menu.get_node("%StartButton") as Button
	assert(start_button != null and not start_button.disabled)
	start_button.pressed.emit()
	await _wait_for_scene(&"NPCBase")
	var npc := get_tree().current_scene as NPCBase
	assert(npc != null and npc.npc_id == &"npc_li_lei")
	return npc


func _capture_viewport(file_name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	assert(image != null and not image.is_empty())
	assert(image.get_width() == 1152 and image.get_height() == 648)
	var capture_dir := OS.get_environment("MIKE_CAPTURE_DIR").strip_edges()
	var output_path := "user://%s" % file_name
	if not capture_dir.is_empty():
		output_path = capture_dir.path_join(file_name)
	assert(image.save_png(output_path) == OK)
	print("MIKE_CAPTURE: %s" % output_path)


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
