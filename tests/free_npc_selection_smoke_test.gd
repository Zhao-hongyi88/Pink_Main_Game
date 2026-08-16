extends Node

const ROSTER_PATH := "res://data/npc/npc_roster.json"
const ROSTER_SCRIPT = preload("res://scripts/npc/npc_roster.gd")
const MAIN_MENU_SCENE: PackedScene = preload("res://scenes/main/main_menu.tscn")

var roster: RefCounted
var ordered_npc_ids: Array[StringName] = []


func _ready() -> void:
	GameState.debug_unlock_all_npcs = true
	GameState.clear_runtime_state()
	roster = ROSTER_SCRIPT.new()
	assert(roster.load_from_json(ROSTER_PATH), roster.get_error_message())
	ordered_npc_ids = roster.get_ordered_npc_ids()
	assert(ordered_npc_ids.size() == 5)

	var menu := await _create_main_menu_as_current()
	var archive: Variant = menu.get_node("%ArchivePanel")
	assert(GameState.unlocked_npc_ids.size() == 1)
	assert(bool(GameState.unlocked_npc_ids.get(ordered_npc_ids[0], false)))
	for npc_id: StringName in ordered_npc_ids:
		assert(GameState.is_npc_unlocked(npc_id))
		assert(not archive.get_npc_button(npc_id).disabled)
		assert(archive.get_npc_button(npc_id).text == "???")
	archive.get_node("%ArchiveButton").pressed.emit()
	await get_tree().create_timer(0.35).timeout
	assert(archive.get_node("%SelectionPanel").visible)
	await _capture_viewport("free_npc_archive_all_enabled.png")
	archive.get_node("%CloseButton").pressed.emit()
	await get_tree().create_timer(0.3).timeout

	var selection_order: Array[StringName] = ordered_npc_ids.duplicate()
	for npc_id: StringName in selection_order:
		menu = get_tree().current_scene as Control
		archive = menu.get_node("%ArchivePanel")
		archive.get_npc_button(npc_id).pressed.emit()
		assert(GameState.selected_npc_id == npc_id)
		assert(archive.get_node("%SelectedNPCLabel").text == "???")
		menu.get_node("%StartButton").pressed.emit()
		await _wait_for_scene(&"NPCBase")
		var npc := get_tree().current_scene as NPCBase
		assert(npc != null)
		assert(npc.npc_id == npc_id)
		assert(npc.npc_data_path == roster.get_data_path(npc_id))
		await _capture_viewport("free_npc_%s.png" % String(npc_id))
		npc.get_node("%ExitButton").pressed.emit()
		await _wait_for_scene(&"MainMenu")

	_assert_independent_progress()
	assert(GameState.unlocked_npc_ids.size() == 1)
	assert(bool(GameState.unlocked_npc_ids.get(ordered_npc_ids[0], false)))
	GameState.debug_unlock_all_npcs = true
	print("FREE_NPC_SELECTION_SMOKE_TEST: PASS")
	get_tree().quit(0)


func _assert_independent_progress() -> void:
	var progress_by_id: Dictionary = {}
	for index in ordered_npc_ids.size():
		var npc_id: StringName = ordered_npc_ids[index]
		var progress := GameState.get_or_create_npc_progress(npc_id)
		assert(progress != null)
		progress.current_dialogue_index = index
		progress.unlocked_keys["debug_progress_%d" % index] = true
		progress.revealed_note_keys = ["debug_note_%d" % index]
		progress_by_id[npc_id] = progress

	for index in ordered_npc_ids.size():
		var npc_id: StringName = ordered_npc_ids[index]
		assert(GameState.select_npc(npc_id))
		var progress := GameState.get_npc_progress(npc_id)
		assert(progress == progress_by_id[npc_id])
		assert(progress.current_dialogue_index == index)
		assert(bool(progress.unlocked_keys.get("debug_progress_%d" % index, false)))
		assert(progress.revealed_note_keys == ["debug_note_%d" % index])
		for other_index in ordered_npc_ids.size():
			if other_index == index:
				continue
			var other_id: StringName = ordered_npc_ids[other_index]
			var other_progress := GameState.get_npc_progress(other_id)
			assert(other_progress == progress_by_id[other_id])
			assert(other_progress.current_dialogue_index == other_index)


func _create_main_menu_as_current() -> Control:
	var menu := MAIN_MENU_SCENE.instantiate() as Control
	assert(menu != null)
	get_tree().root.add_child.call_deferred(menu)
	await get_tree().process_frame
	get_tree().current_scene = menu
	await get_tree().process_frame
	return menu


func _capture_viewport(file_name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	assert(image != null and not image.is_empty())
	var capture_dir := OS.get_environment("FREE_NPC_CAPTURE_DIR").strip_edges()
	var output_path := "user://%s" % file_name
	if not capture_dir.is_empty():
		output_path = capture_dir.path_join(file_name)
	assert(image.save_png(output_path) == OK)
	print("FREE_NPC_CAPTURE: %s" % output_path)


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
