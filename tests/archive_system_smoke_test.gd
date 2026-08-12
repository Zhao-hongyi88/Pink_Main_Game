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
	assert(GameState.get_npc_progress(ordered_npc_ids[0]) == null)
	_assert_archive_ui(archive, 1, ordered_npc_ids[0])
	assert(archive.get_node("%SelectedNPCLabel").text == "???")
	assert(archive.get_npc_button(ordered_npc_ids[0]).text == "???")
	assert(archive.get_npc_button(ordered_npc_ids[1]).text == "??? - Locked")

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

	# The real DialogueManager -> UnlockSystem flow reveals the name before dialogue or memory completion.
	var first_progress := _trigger_name_unlock_through_dialogue(ordered_npc_ids[0])
	var first_data := NPCData.load_from_json(roster.get_data_path(ordered_npc_ids[0]))
	assert(first_progress.unlocked_keys.get(String(first_data.name_unlock_key), false))
	assert(not first_progress.dialogue_completed)
	assert(not first_progress.memory_completed)
	archive.refresh()
	assert(archive.get_node("%SelectedNPCLabel").text == first_data.display_name)
	assert(archive.get_npc_button(ordered_npc_ids[0]).text == first_data.display_name)

	# Re-instantiating MainMenu restores the known name from NPCProgress without a transient signal.
	_dispose_main_menu(menu)
	menu = await _create_main_menu()
	archive = menu.get_node("%ArchivePanel")
	assert(GameState.selected_npc_id == ordered_npc_ids[0])
	assert(archive.get_node("%SelectedNPCLabel").text == first_data.display_name)
	assert(not first_progress.dialogue_completed)
	assert(not first_progress.memory_completed)

	assert(GameState.mark_memory_completed(ordered_npc_ids[0]))
	_dispose_main_menu(menu)

	# Completing the first NPC newly unlocks and automatically selects the second.
	menu = await _create_main_menu()
	archive = menu.get_node("%ArchivePanel")
	assert(GameState.unlocked_npc_ids.size() == 2)
	assert(GameState.selected_npc_id == ordered_npc_ids[1])
	_assert_archive_ui(archive, 2, ordered_npc_ids[1])
	assert(archive.get_node("%SelectedNPCLabel").text == "???")
	assert(archive.get_npc_button(ordered_npc_ids[0]).text == first_data.display_name)
	assert(archive.get_npc_button(ordered_npc_ids[1]).text == "???")

	# A second NPC has independent name knowledge and remains unknown until its own key is unlocked.
	var second_progress := _trigger_name_unlock_through_dialogue(ordered_npc_ids[1])
	var second_data := NPCData.load_from_json(roster.get_data_path(ordered_npc_ids[1]))
	assert(second_progress.unlocked_keys.get(String(second_data.name_unlock_key), false))
	assert(not second_progress.dialogue_completed)
	assert(not second_progress.memory_completed)
	archive.refresh()
	assert(archive.get_node("%SelectedNPCLabel").text == second_data.display_name)
	assert(archive.get_npc_button(ordered_npc_ids[0]).text == first_data.display_name)
	assert(archive.get_npc_button(ordered_npc_ids[1]).text == second_data.display_name)

	# Manual selection back to the first NPC survives another MainMenu entry.
	archive.get_node("%ArchiveButton").pressed.emit()
	await get_tree().create_timer(0.35).timeout
	assert(archive.get_node("%SelectionPanel").visible)
	archive.get_npc_button(ordered_npc_ids[0]).pressed.emit()
	assert(GameState.selected_npc_id == ordered_npc_ids[0])
	assert(archive.get_node("%SelectedNPCLabel").text == roster.get_display_name(ordered_npc_ids[0]))
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
	assert(first_progress.unlocked_keys.get(String(first_data.name_unlock_key), false))
	assert(first_progress.revealed_note_keys == [String(first_data.name_unlock_key)])
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
	var archive_texture := archive_button.get_node("ArchiveTexture") as TextureRect
	var magnifier_texture := archive_button.get_node("MagnifierTexture") as TextureRect
	var selected_npc_label := archive.get_node("%SelectedNPCLabel") as Label
	assert(archive_button != null)
	assert(archive_texture != null)
	assert(magnifier_texture != null)
	assert(selected_npc_label != null)
	assert(selected_npc_label.get_parent() == archive_button)
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
	var hovered_scale := archive_button.scale.x
	assert(is_equal_approx(archive_texture.get_global_transform().get_scale().x, hovered_scale))
	assert(is_equal_approx(magnifier_texture.get_global_transform().get_scale().x, hovered_scale))
	assert(is_equal_approx(selected_npc_label.get_global_transform().get_scale().x, hovered_scale))

	# A rapid direction reversal replaces the old Tween and returns to authored values.
	var enter_tween: Tween = archive_button._hover_tween
	archive_button.mouse_exited.emit()
	assert(not enter_tween.is_valid())
	await get_tree().create_timer(0.2).timeout
	assert(archive_button.scale.is_equal_approx(Vector2.ONE))
	assert(archive_button.modulate.is_equal_approx(default_modulate))
	assert(archive_button.pivot_offset.is_equal_approx(archive_button.size / 2.0))
	assert(archive_texture.get_global_transform().get_scale().is_equal_approx(Vector2.ONE))
	assert(magnifier_texture.get_global_transform().get_scale().is_equal_approx(Vector2.ONE))
	assert(selected_npc_label.get_global_transform().get_scale().is_equal_approx(Vector2.ONE))

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
	assert(archive.get_node("%SelectedNPCLabel").text == _get_expected_visible_name(selected_npc_id))
	for index in ordered_npc_ids.size():
		var npc_id: StringName = ordered_npc_ids[index]
		var button: Button = archive.get_npc_button(npc_id)
		assert(button != null)
		assert(button.disabled == (index >= unlocked_count))
		assert(button.text.contains("Locked") == (index >= unlocked_count))
		assert(button.text == (
			"??? - Locked"
			if index >= unlocked_count
			else _get_expected_visible_name(npc_id)
		))


func _trigger_name_unlock_through_dialogue(npc_id: StringName) -> NPCProgress:
	var npc_data := NPCData.load_from_json(roster.get_data_path(npc_id))
	assert(npc_data.is_valid(), npc_data.get_error_message())
	var progress := GameState.get_or_create_npc_progress(npc_id)
	var dialogue_manager := DialogueManager.new()
	assert(dialogue_manager.setup(npc_data.dialogues, progress))
	var valid_keys: Array[String] = []
	for note: Dictionary in npc_data.notes:
		valid_keys.append(str(note["key"]))
	var unlock_system := UnlockSystem.new()
	assert(unlock_system.setup(valid_keys, progress))

	var name_unlock_observed := false
	for _dialogue_index in npc_data.dialogues.size():
		var dialogue_result := dialogue_manager.advance()
		assert(dialogue_result["accepted"])
		var unlock_key := str(dialogue_result["unlock_key"])
		if not unlock_key.is_empty():
			var unlock_result := unlock_system.request_unlock(unlock_key)
			assert(unlock_result["accepted"])
		if unlock_key == String(npc_data.name_unlock_key):
			name_unlock_observed = true
			break
	assert(name_unlock_observed)
	assert(progress.unlocked_keys.get(String(npc_data.name_unlock_key), false))
	return progress


func _get_expected_visible_name(npc_id: StringName) -> String:
	var npc_data := NPCData.load_from_json(roster.get_data_path(npc_id))
	assert(npc_data.is_valid(), npc_data.get_error_message())
	var progress := GameState.get_npc_progress(npc_id)
	if progress == null:
		return "???"
	if not bool(progress.unlocked_keys.get(String(npc_data.name_unlock_key), false)):
		return "???"
	return npc_data.display_name


func _assert_archive_visual_contract(archive: Variant) -> void:
	assert(archive is Control)
	assert(archive.get_node("%ArchiveButton") is Button)
	assert(archive.get_node("%SelectedNPCLabel") is Label)
	var selected_npc_label := archive.get_node("%SelectedNPCLabel") as Label
	assert(selected_npc_label.text.find("SELECTED:") == -1)
	assert(selected_npc_label.get_theme_font_size(&"font_size") == 28)
	var archive_name_font := selected_npc_label.get_theme_font(&"font") as SystemFont
	assert(archive_name_font != null)
	assert(archive_name_font.font_weight == 700)
	assert(selected_npc_label.get_theme_color(&"font_color").is_equal_approx(
		Color(0.290196, 0.203922, 0.160784, 0.86)
	))
	assert(selected_npc_label.get_parent() == archive.get_node("%ArchiveButton"))
	assert(selected_npc_label.position.is_equal_approx(Vector2(12.0, 38.0)))
	assert(selected_npc_label.size.is_equal_approx(Vector2(154.0, 58.0)))
	assert(selected_npc_label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER)
	assert(selected_npc_label.vertical_alignment == VERTICAL_ALIGNMENT_CENTER)
	assert(selected_npc_label.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert(archive.get_node("%SelectionPanel") is PanelContainer)
	assert(archive.get_node("%NPCButtonContainer") is VBoxContainer)
	assert(archive.get_node("%CloseButton") is Button)
	var archive_button := archive.get_node("%ArchiveButton") as Button
	var archive_texture := archive_button.get_node("ArchiveTexture") as TextureRect
	var magnifier_texture := archive_button.get_node("MagnifierTexture") as TextureRect
	assert(archive_texture != null)
	assert(magnifier_texture != null)
	assert(archive_texture.position.is_equal_approx(Vector2.ZERO))
	assert(archive_texture.size.is_equal_approx(Vector2(178.0, 215.0)))
	assert(magnifier_texture.position.is_equal_approx(Vector2(120.0, 108.0)))
	assert(magnifier_texture.size.is_equal_approx(Vector2(82.0, 105.0)))
	assert(magnifier_texture.get_index() > archive_texture.get_index())
	assert(archive_button.size.is_equal_approx(Vector2(202.0, 215.0)))
	for texture_rect: TextureRect in [archive_texture, magnifier_texture]:
		assert(texture_rect.texture != null)
		assert(texture_rect.mouse_filter == Control.MOUSE_FILTER_IGNORE)
		assert(texture_rect.expand_mode == TextureRect.EXPAND_IGNORE_SIZE)
		assert(texture_rect.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED)

	var paper_background := archive.get_node("%SelectionPanel/PaperBackground") as TextureRect
	assert(paper_background != null)
	assert(paper_background.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert(paper_background.texture != null)
	assert(paper_background.get_index() < archive.get_node("%SelectionPanel/MarginContainer").get_index())

	assert(archive.theme != null)
	for style_name: StringName in [&"normal", &"hover", &"pressed", &"disabled"]:
		assert(archive.theme.has_stylebox(style_name, &"Button"))

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
