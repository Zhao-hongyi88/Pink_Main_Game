extends Node

const ROSTER_PATH := "res://data/npc/npc_roster.json"
const ROSTER_SCRIPT = preload("res://scripts/npc/npc_roster.gd")
const MAIN_MENU_SCENE: PackedScene = preload("res://scenes/main/main_menu.tscn")

var roster: RefCounted
var ordered_npc_ids: Array[StringName] = []


func _ready() -> void:
	GameState.clear_runtime_state()
	_load_and_verify_roster()
	await _verify_archive_and_sequence_progression()
	print("ARCHIVE_SYSTEM_SMOKE_TEST: PASS")
	get_tree().quit(0)


func _load_and_verify_roster() -> void:
	roster = ROSTER_SCRIPT.new()
	assert(roster.load_from_json(ROSTER_PATH), roster.get_error_message())
	assert(roster.is_valid())
	ordered_npc_ids = roster.get_ordered_npc_ids()
	assert(ordered_npc_ids == [
		&"npc_zhang_yuan",
		&"npc_li_lei",
		&"npc_liu_guilan",
		&"npc_su_qing",
		&"npc_wang_jianguo",
	])
	assert(roster.get_first_npc_id() == ordered_npc_ids[0])
	assert(roster.get_next_npc_id(ordered_npc_ids[0]) == ordered_npc_ids[1])
	assert(roster.get_next_npc_id(ordered_npc_ids[-1]).is_empty())
	assert(roster.get_data_path(&"missing_npc").is_empty())

	var known_ids: Dictionary = {}
	for entry: Dictionary in roster.get_entries():
		var npc_id: StringName = entry["npc_id"]
		assert(not known_ids.has(npc_id))
		known_ids[npc_id] = true
		var npc_data := NPCData.load_from_json(entry["data_path"])
		assert(npc_data.is_valid(), npc_data.get_error_message())
		assert(npc_data.npc_id == npc_id)
		assert(entry["display_name"] == npc_data.display_name)
	assert(known_ids.size() == ordered_npc_ids.size())

	var project_settings := FileAccess.get_file_as_string("res://project.godot")
	var main_menu_source := FileAccess.get_file_as_string("res://scripts/main/main_menu.gd")
	var archive_scene_source := FileAccess.get_file_as_string("res://scenes/ui/archive_panel.tscn")
	assert(project_settings.find("npc_roster.gd") == -1)
	assert(main_menu_source.find("npc_a.json") == -1)
	assert(main_menu_source.find("\"npc_zhang_yuan\"") == -1)
	assert(main_menu_source.find("&\"npc_zhang_yuan\"") == -1)
	for npc_id: StringName in ordered_npc_ids:
		assert(archive_scene_source.find(roster.get_display_name(npc_id)) == -1)


func _verify_archive_and_sequence_progression() -> void:
	# First entry only: the first roster NPC is unlocked and selected without hardcoding in MainMenu.
	var menu := await _create_main_menu()
	var archive: Variant = menu.get_node("%ArchivePanel")
	_assert_archive_visual_contract(archive)
	await _verify_archive_button_hover(archive)
	assert(GameState.selected_npc_id == ordered_npc_ids[0])
	assert(GameState.unlocked_npc_ids.size() == 1)
	assert(GameState.is_npc_unlocked(ordered_npc_ids[0]))
	assert(not GameState.select_npc(ordered_npc_ids[1]))
	_assert_archive_ui(archive, 1, ordered_npc_ids[0])

	archive.get_node("%ArchiveButton").pressed.emit()
	var selection_panel := archive.get_node("%SelectionPanel") as PanelContainer
	assert(selection_panel.visible)
	assert(selection_panel.modulate.a < 1.0)
	assert(selection_panel.scale.is_equal_approx(Vector2(0.96, 0.96)))
	await get_tree().create_timer(0.35).timeout
	assert(selection_panel.visible)
	assert(is_equal_approx(selection_panel.modulate.a, 1.0))
	assert(selection_panel.scale.is_equal_approx(Vector2.ONE))
	assert(selection_panel.pivot_offset.is_equal_approx(selection_panel.size / 2.0))

	archive.get_node("%CloseButton").pressed.emit()
	assert(selection_panel.visible)
	await get_tree().create_timer(0.3).timeout
	assert(not selection_panel.visible)

	await _verify_archive_animation_interruptions(archive, selection_panel)

	# Preserve concrete NPC_A progress while Archive selection changes later.
	var first_progress := GameState.get_or_create_npc_progress(ordered_npc_ids[0])
	first_progress.current_dialogue_index = 2
	first_progress.unlocked_keys["archive_test_key"] = true
	first_progress.revealed_note_keys.append("archive_test_key")
	assert(GameState.mark_memory_completed(ordered_npc_ids[0]))
	_dispose_main_menu(menu)

	# Completing the first NPC newly unlocks and automatically selects the second.
	menu = await _create_main_menu()
	archive = menu.get_node("%ArchivePanel")
	assert(GameState.unlocked_npc_ids.size() == 2)
	assert(GameState.selected_npc_id == ordered_npc_ids[1])
	_assert_archive_ui(archive, 2, ordered_npc_ids[1])

	# Manual selection back to the first NPC survives another MainMenu entry.
	archive.get_node("%ArchiveButton").pressed.emit()
	await get_tree().create_timer(0.35).timeout
	assert(archive.get_node("%SelectionPanel").visible)
	archive.get_npc_button(ordered_npc_ids[0]).pressed.emit()
	assert(GameState.selected_npc_id == ordered_npc_ids[0])
	assert(archive.get_node("%SelectedNPCLabel").text == "SELECTED: %s" % roster.get_display_name(ordered_npc_ids[0]))
	assert(archive.get_node("%SelectionPanel").visible)
	await get_tree().create_timer(0.3).timeout
	assert(not archive.get_node("%SelectionPanel").visible)
	_dispose_main_menu(menu)
	menu = await _create_main_menu()
	archive = menu.get_node("%ArchivePanel")
	assert(GameState.selected_npc_id == ordered_npc_ids[0])
	assert(GameState.unlocked_npc_ids.size() == 2)
	assert(GameState.get_npc_progress(ordered_npc_ids[0]) == first_progress)
	assert(first_progress.current_dialogue_index == 2)
	assert(first_progress.unlocked_keys.get("archive_test_key", false))
	assert(first_progress.revealed_note_keys == ["archive_test_key"])
	_dispose_main_menu(menu)

	# Each newly completed roster entry unlocks and selects exactly the next entry.
	for completed_index in range(1, ordered_npc_ids.size() - 1):
		var completed_npc_id := ordered_npc_ids[completed_index]
		var expected_next_npc_id := ordered_npc_ids[completed_index + 1]
		assert(GameState.mark_memory_completed(completed_npc_id))
		menu = await _create_main_menu()
		archive = menu.get_node("%ArchivePanel")
		assert(GameState.is_npc_unlocked(expected_next_npc_id))
		assert(GameState.selected_npc_id == expected_next_npc_id)
		assert(GameState.unlocked_npc_ids.size() == completed_index + 2)
		_assert_archive_ui(archive, completed_index + 2, expected_next_npc_id)
		_dispose_main_menu(menu)

	# Completing the final entry has no next NPC and leaves the final selection intact.
	var final_npc_id := ordered_npc_ids[-1]
	assert(GameState.selected_npc_id == final_npc_id)
	assert(GameState.mark_memory_completed(final_npc_id))
	menu = await _create_main_menu()
	archive = menu.get_node("%ArchivePanel")
	assert(GameState.get_npc_progress(final_npc_id).memory_completed)
	assert(GameState.selected_npc_id == final_npc_id)
	assert(GameState.unlocked_npc_ids.size() == ordered_npc_ids.size())
	assert(GameState.advance_from_completed_progress(roster).is_empty())
	_assert_archive_ui(archive, ordered_npc_ids.size(), final_npc_id)

	# With no new unlock, a manual selection remains selected even after all NPCs are complete.
	archive.get_npc_button(ordered_npc_ids[0]).pressed.emit()
	assert(GameState.selected_npc_id == ordered_npc_ids[0])
	_dispose_main_menu(menu)
	menu = await _create_main_menu()
	assert(GameState.selected_npc_id == ordered_npc_ids[0])
	assert(GameState.unlocked_npc_ids.size() == ordered_npc_ids.size())
	_dispose_main_menu(menu)


func _verify_archive_button_hover(archive: Variant) -> void:
	var archive_button := archive.get_node("%ArchiveButton") as Button
	assert(archive_button != null)
	assert(archive_button.get_script().resource_path == "res://scripts/ui/button_hover_effect.gd")
	# Let MainMenu's parent-level intro finish before isolating the button effect.
	await get_tree().create_timer(0.5).timeout
	var default_modulate := archive_button.modulate

	assert(archive_button.mouse_entered.get_connections().size() == 1)
	archive_button.mouse_entered.emit()
	assert(archive_button.is_hover_tween_running())
	await get_tree().create_timer(0.08).timeout
	assert(
		archive_button.scale.x > 1.0 and archive_button.scale.x <= 1.051,
		"Archive hover scale was %s" % archive_button.scale
	)
	assert(archive_button.modulate.r > default_modulate.r)

	# A rapid direction reversal replaces the old Tween and returns to authored values.
	var enter_tween: Tween = archive_button._hover_tween
	archive_button.mouse_exited.emit()
	assert(not enter_tween.is_valid())
	await get_tree().create_timer(0.2).timeout
	assert(archive_button.scale.is_equal_approx(Vector2.ONE))
	assert(archive_button.modulate.is_equal_approx(default_modulate))
	assert(archive_button.pivot_offset.is_equal_approx(archive_button.size / 2.0))

	# Hover does not replace or consume Archive's existing pressed connection.
	assert(archive_button.pressed.get_connections().size() == 1)


func _verify_archive_animation_interruptions(archive: Variant, selection_panel: PanelContainer) -> void:
	var archive_button := archive.get_node("%ArchiveButton") as Button
	var close_button := archive.get_node("%CloseButton") as Button

	# Closing during opening must finish closed without stale animation state.
	archive_button.pressed.emit()
	await get_tree().create_timer(0.08).timeout
	close_button.pressed.emit()
	await get_tree().create_timer(0.3).timeout
	assert(not selection_panel.visible)

	# Reopening during closing must stay visible after the old close would have completed.
	archive_button.pressed.emit()
	await get_tree().create_timer(0.08).timeout
	close_button.pressed.emit()
	await get_tree().create_timer(0.08).timeout
	archive_button.pressed.emit()
	await get_tree().create_timer(0.35).timeout
	assert(selection_panel.visible)
	assert(is_equal_approx(selection_panel.modulate.a, 1.0))
	assert(selection_panel.scale.is_equal_approx(Vector2.ONE))

	# Repeated open requests must converge on one stable open state.
	archive_button.pressed.emit()
	archive_button.pressed.emit()
	archive_button.pressed.emit()
	await get_tree().create_timer(0.35).timeout
	assert(selection_panel.visible)
	assert(is_equal_approx(selection_panel.modulate.a, 1.0))
	assert(selection_panel.scale.is_equal_approx(Vector2.ONE))
	close_button.pressed.emit()
	await get_tree().create_timer(0.3).timeout
	assert(not selection_panel.visible)


func _assert_archive_ui(archive: Variant, unlocked_count: int, selected_npc_id: StringName) -> void:
	assert(archive.get_npc_button_count() == ordered_npc_ids.size())
	assert(archive.get_node("%NPCButtonContainer").get_child_count() == ordered_npc_ids.size())
	assert(archive.get_node("%SelectedNPCLabel").text == "SELECTED: %s" % roster.get_display_name(selected_npc_id))
	for index in ordered_npc_ids.size():
		var npc_id: StringName = ordered_npc_ids[index]
		var button: Button = archive.get_npc_button(npc_id)
		assert(button != null)
		assert(button.disabled == (index >= unlocked_count))
		assert(button.text.contains("Locked") == (index >= unlocked_count))


func _assert_archive_visual_contract(archive: Variant) -> void:
	assert(archive is Control)
	assert(archive.get_node("%ArchiveButton") is Button)
	assert(archive.get_node("%SelectedNPCLabel") is Label)
	assert(archive.get_node("%SelectionPanel") is PanelContainer)
	assert(archive.get_node("%NPCButtonContainer") is VBoxContainer)
	assert(archive.get_node("%CloseButton") is Button)

	var paper_background := archive.get_node("%SelectionPanel/PaperBackground") as TextureRect
	assert(paper_background != null)
	assert(paper_background.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert(paper_background.texture != null)
	assert(paper_background.get_index() < archive.get_node("%SelectionPanel/MarginContainer").get_index())

	assert(archive.theme != null)
	for style_name: StringName in [&"normal", &"hover", &"pressed", &"disabled"]:
		assert(archive.theme.has_stylebox(style_name, &"Button"))

	var archive_button := archive.get_node("%ArchiveButton") as Button
	var close_button := archive.get_node("%CloseButton") as Button
	var dynamic_button: Button = archive.get_npc_button(ordered_npc_ids[0])
	for button: Button in [archive_button, close_button, dynamic_button]:
		assert(button != null)
		assert(button.get_theme_stylebox(&"normal") != null)
		assert(button.get_theme_stylebox(&"hover") != null)
		assert(button.get_theme_stylebox(&"pressed") != null)
		assert(button.get_theme_stylebox(&"disabled") != null)


func _create_main_menu() -> Control:
	var menu := MAIN_MENU_SCENE.instantiate() as Control
	assert(menu != null)
	add_child(menu)
	await get_tree().process_frame
	assert(menu.get("npc_roster") != null)
	return menu


func _dispose_main_menu(menu: Control) -> void:
	remove_child(menu)
	menu.free()
