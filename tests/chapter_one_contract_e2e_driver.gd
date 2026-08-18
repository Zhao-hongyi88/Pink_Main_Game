extends Node

## TEMP-run autoload driver. It is registered only in an isolated project copy,
## so the production project settings and scenes remain untouched.

const RYAN_ID: StringName = &"npc_zhang_yuan"
const RYAN_DATA_PATH := "res://data/npc/npc_a.json"
const RYAN_FINAL_BACKGROUND := (
	"res://TextureAsset/Level1/Ryan/ryan_loan_04_after_submit.png"
)
const FINAL_SPEAKERS := [
	"Me", "Ryan", "Ryan", "Me", "Ryan", "Ryan", "Me", "Ryan",
]
const FINAL_TEXTS := [
	"After reviewing your documents, we've approved your loan application.",
	"Really... it was approved? Thank you.",
	"I hope I can finally find a job this time.",
	"I wish you the best.",
	"By the way...\nA friend of mine has been thinking about applying for a time loan too.",
	"His situation is a little more complicated than mine. But I think the people here... at least take the time to properly review every application.",
	"Thank you for your trust. If he meets the requirements, he's welcome to apply.",
	"He should be coming by in the next couple of days. Thank you.",
]
const TIMEOUT_MS := 15000

var _stamp_impact_seen := false
var _stamp_finished_seen := false
var _failed := false


func _ready() -> void:
	if not OS.get_cmdline_user_args().has("--chapter-one-contract-e2e"):
		queue_free()
		return
	GameState.debug_unlock_all_npcs = false
	GameState.clear_runtime_state()
	call_deferred("_run_e2e")


func _run_e2e() -> void:
	print("CHAPTER_ONE_E2E: PROJECT_STARTED")
	var main_menu := await _wait_for_scene(&"MainMenu") as Control
	if not _check(main_menu != null, "Main Menu did not load."):
		return
	print("CHAPTER_ONE_E2E: MAIN_MENU_READY")
	await _capture("01_main_menu.png")
	if _failed:
		return

	var archive_panel := main_menu.get_node("%ArchivePanel") as Control
	var archive_button := archive_panel.get_node("%ArchiveButton") as Button
	var archive_selection := archive_panel.get_node("%SelectionPanel") as Control
	var archive_close := archive_panel.get_node("%CloseButton") as Button
	if not _check(
		archive_button != null and archive_close != null and archive_selection != null,
		"Archive controls are unavailable."
	):
		return
	archive_button.pressed.emit()
	await get_tree().process_frame
	if not _check(archive_selection.visible, "Archive did not open."):
		return
	archive_close.pressed.emit()
	if not await _wait_for_control_hidden(archive_selection):
		return
	print("CHAPTER_ONE_E2E: ARCHIVE_OK")

	var start_button := main_menu.get_node("%StartButton") as Button
	if not _check(start_button != null and not start_button.disabled, "START is unavailable."):
		return
	start_button.pressed.emit()
	if not await _wait_for_start_loading():
		return
	print("CHAPTER_ONE_E2E: LOADING_VISIBLE")
	await _capture("02_loading.png")
	if _failed:
		return

	var npc := await _wait_for_scene(&"NPCBase") as NPCBase
	if not _check(npc != null and npc.npc_data_path == RYAN_DATA_PATH, "Ryan page did not load."):
		return
	print("CHAPTER_ONE_E2E: RYAN_PAGE_READY")
	await _capture("03_ryan_arrival.png")
	await _send_left_click(Vector2(570.0, 250.0))
	if not await _wait_for_control_visible(npc.get_node("%DialoguePanel") as Control):
		return
	if not await _wait_for_intro_finished(npc):
		return
	var continue_button := npc.get_node("%ContinueButton") as Button
	if not _check(
		npc.current_dialogue_index == 0
		and npc.get_node("%DialogueText").text
		== "Hello. What can I help you with today?",
		"Ryan's original dialogue did not start."
	):
		return

	for expected_index in range(1, 11):
		continue_button.pressed.emit()
		await get_tree().process_frame
		if not _check(
			npc.current_dialogue_index == expected_index,
			"Original dialogue stopped before line %d." % expected_index
		):
			return
	if not _check(npc.note_detail_popup.visible, "Ryan Basic Information note did not open."):
		return
	npc.note_detail_popup.get_node("%CloseHitArea").pressed.emit()
	if not await _wait_for_control_hidden(npc.note_detail_popup):
		return
	if not _check(
		npc.dialogue_completed
		and npc.memory_ready
		and npc.background.texture == load(RYAN_FINAL_BACKGROUND),
		"Original Ryan dialogue did not complete with its existing final background."
	):
		return
	print("CHAPTER_ONE_E2E: ORIGINAL_DIALOGUE_COMPLETE")
	await _capture("04_ryan_ready_for_memory.png")

	var memory_button := npc.get_node("%MemoryButton") as Button
	if not _check(memory_button.visible and not memory_button.disabled, "Enter Memory is unavailable."):
		return
	memory_button.pressed.emit()
	var memory_scene := await _wait_for_scene(&"ZhangYuanMemory")
	if not _check(memory_scene != null, "Ryan Memory did not load."):
		return
	print("CHAPTER_ONE_E2E: MEMORY_READY")
	await _capture("05_ryan_memory.png")

	for point_path in [
		"ObservationPoints/StudyRecord",
		"ObservationPoints/DegreeCertificate",
		"ObservationPoints/InterviewResult",
	]:
		if not await _complete_observation(memory_scene, point_path):
			return
	var complete_button := memory_scene.get_node("%CompleteButton") as Button
	if not _check(
		complete_button.visible and not complete_button.disabled,
		"Memory completion button did not unlock."
	):
		return
	print("CHAPTER_ONE_E2E: MEMORY_OBSERVATIONS_COMPLETE")
	complete_button.pressed.emit()

	var returned_npc := await _wait_for_scene(&"NPCBase") as NPCBase
	if not _check(returned_npc != null, "Memory did not return to Ryan."):
		return
	var progress := GameState.get_npc_progress(RYAN_ID)
	if not _check(
		progress != null
		and progress.memory_completed
		and returned_npc.background.texture == load(RYAN_FINAL_BACKGROUND),
		"Memory completion state or Ryan background was not restored."
	):
		return
	var contract_book := returned_npc.get_node(
		"DossierPanel/TimeLoanContractButton"
	) as TextureButton
	if not _check(
		contract_book != null and contract_book.visible and not contract_book.disabled,
		"Time Loan Contract book did not appear."
	):
		return
	print("CHAPTER_ONE_E2E: MEMORY_RETURN_AND_CONTRACT_BOOK_OK")
	await _capture("06_contract_book.png")

	var overlay := returned_npc.get_node("LoanContractOverlay") as LoanContractOverlay
	if not _check(overlay != null, "Contract Overlay was not mounted."):
		return
	overlay.stamp_impact.connect(_on_stamp_impact)
	overlay.stamp_animation_finished.connect(_on_stamp_finished)
	contract_book.pressed.emit()
	if not await _wait_for_stamp(overlay, progress):
		return
	if not _check(
		overlay.visible
		and overlay.was_stamp_animation_played()
		and overlay.was_shake_played()
		and _stamp_impact_seen
		and _stamp_finished_seen,
		"Stamp drop or impact shake did not complete."
	):
		return
	print("CHAPTER_ONE_E2E: CONTRACT_OVERLAY_STAMP_SHAKE_OK")
	await _capture("07_contract_stamped.png")

	overlay.close_button.pressed.emit()
	await get_tree().process_frame
	if not _check(
		not overlay.visible
		and progress.contract_reviewed
		and returned_npc._final_dialogue_active,
		"Closing the contract did not start Final Dialogue."
	):
		return
	print("CHAPTER_ONE_E2E: FINAL_DIALOGUE_STARTED")
	if not _check_final_line(returned_npc, 0):
		return
	await _capture("08_final_dialogue_first.png")
	var final_continue := returned_npc.get_node("%ContinueButton") as Button
	for final_index in range(1, FINAL_TEXTS.size()):
		final_continue.pressed.emit()
		await get_tree().process_frame
		if not _check_final_line(returned_npc, final_index):
			return
	await _capture("09_final_dialogue_last.png")
	final_continue.pressed.emit()

	var returned_menu := await _wait_for_scene(&"MainMenu") as Control
	if not _check(
		returned_menu != null and progress.final_dialogue_completed,
		"Chapter end did not return to Main Menu."
	):
		return
	await _capture("10_chapter_complete_main_menu.png")
	if _failed:
		return
	print("CHAPTER_ONE_E2E: FINAL_DIALOGUE_ME_RYAN_OK")
	print("CHAPTER_ONE_E2E: CHAPTER_END_MAIN_MENU_OK")
	print("CHAPTER_ONE_CONTRACT_E2E: PASS")
	get_tree().quit(0)


func _complete_observation(memory_scene: Node, point_path: String) -> bool:
	var point := memory_scene.get_node(point_path) as MemoryObservationPoint
	var info_panel := memory_scene.get_node("%MemoryInfoPanel") as MemoryInfoPanel
	if not _check(point != null and point.observation_data != null, "Missing Memory point: " + point_path):
		return false
	var click_event := InputEventMouseButton.new()
	click_event.button_index = MOUSE_BUTTON_LEFT
	click_event.pressed = true
	point._on_input_event(get_viewport(), click_event, 0)
	await get_tree().process_frame
	if not _check(info_panel.visible, "Memory point did not open: " + point_path):
		return false

	var step_count := 0
	while info_panel.visible and step_count < 20:
		var next_button := (
			info_panel.dialogue_continue_button
			if info_panel.dialogue_box.visible
			else info_panel.continue_button
		)
		next_button.pressed.emit()
		step_count += 1
		await get_tree().process_frame
	if not _check(not info_panel.visible, "Memory point did not complete: " + point_path):
		return false
	if not _check(
		bool(memory_scene.get("observed_points").get(
			str(point.observation_data.observation_id),
			false
		)),
		"Memory point was not recorded: " + point_path
	):
		return false
	return true


func _check_final_line(npc: NPCBase, index: int) -> bool:
	return _check(
		npc.npc_progress.final_dialogue_index == index
		and npc.get_node("%NPCName").text == FINAL_SPEAKERS[index]
		and npc.get_node("%DialogueText").text == FINAL_TEXTS[index],
		"Final Dialogue mismatch at line %d." % index
	)


func _wait_for_scene(expected_name: StringName) -> Node:
	var timeout_at := Time.get_ticks_msec() + TIMEOUT_MS
	while Time.get_ticks_msec() < timeout_at:
		var current_scene := get_tree().current_scene
		if (
			current_scene != null
			and current_scene.name == expected_name
			and not SceneRouter.is_transitioning()
		):
			return current_scene
		await get_tree().process_frame
	_fail("Timed out waiting for scene: %s" % expected_name)
	return null


func _wait_for_start_loading() -> bool:
	var transition_layer := SceneRouter.get_start_transition_layer() as CanvasLayer
	var timeout_at := Time.get_ticks_msec() + TIMEOUT_MS
	while Time.get_ticks_msec() < timeout_at:
		if (
			transition_layer != null
			and bool(transition_layer.get("last_transition_started"))
			and transition_layer.get_node("%LoadingLabel").visible
		):
			return true
		await get_tree().process_frame
	_fail("START transition did not show Loading.")
	return false


func _wait_for_control_visible(control: Control) -> bool:
	var timeout_at := Time.get_ticks_msec() + TIMEOUT_MS
	while Time.get_ticks_msec() < timeout_at:
		if control != null and control.visible:
			return true
		await get_tree().process_frame
	_fail("Expected Control did not become visible.")
	return false


func _wait_for_control_hidden(control: Control) -> bool:
	var timeout_at := Time.get_ticks_msec() + TIMEOUT_MS
	while Time.get_ticks_msec() < timeout_at:
		if control != null and not control.visible:
			return true
		await get_tree().process_frame
	_fail("Expected Control did not become hidden.")
	return false


func _wait_for_intro_finished(npc: NPCBase) -> bool:
	var timeout_at := Time.get_ticks_msec() + TIMEOUT_MS
	while Time.get_ticks_msec() < timeout_at:
		if not npc._intro_animation_playing:
			return true
		await get_tree().process_frame
	_fail("Ryan's first dialogue reveal animation did not finish.")
	return false


func _wait_for_stamp(overlay: LoanContractOverlay, progress: NPCProgress) -> bool:
	var timeout_at := Time.get_ticks_msec() + TIMEOUT_MS
	while Time.get_ticks_msec() < timeout_at:
		if progress.contract_stamped and _stamp_finished_seen:
			return true
		if not overlay.visible:
			break
		await get_tree().process_frame
	_fail("Contract stamp animation did not finish.")
	return false


func _send_left_click(position: Vector2) -> void:
	var press_event := InputEventMouseButton.new()
	press_event.button_index = MOUSE_BUTTON_LEFT
	press_event.pressed = true
	press_event.position = position
	press_event.global_position = position
	Input.parse_input_event(press_event)
	await get_tree().process_frame
	var release_event := press_event.duplicate() as InputEventMouseButton
	release_event.pressed = false
	Input.parse_input_event(release_event)
	await get_tree().process_frame


func _capture(file_name: String) -> void:
	if DisplayServer.get_name() == "headless":
		_fail("E2E capture requires a non-headless display.")
		return
	var artifact_dir := ProjectSettings.globalize_path("res://e2e_artifacts")
	var dir_error := DirAccess.make_dir_recursive_absolute(artifact_dir)
	if dir_error != OK and dir_error != ERR_ALREADY_EXISTS:
		_fail("Could not create E2E artifact directory.")
		return
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	if not _check(image != null and not image.is_empty(), "Viewport capture was empty."):
		return
	if not _check(
		image.save_png(artifact_dir.path_join(file_name)) == OK,
		"Could not save E2E screenshot: " + file_name
	):
		return


func _on_stamp_impact() -> void:
	_stamp_impact_seen = true


func _on_stamp_finished() -> void:
	_stamp_finished_seen = true


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error("CHAPTER_ONE_CONTRACT_E2E: FAIL - " + message)
	print("CHAPTER_ONE_CONTRACT_E2E: FAIL - " + message)
	get_tree().quit(1)
