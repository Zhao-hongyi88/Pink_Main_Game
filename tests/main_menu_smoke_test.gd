extends Node

const ROSTER_SCRIPT = preload("res://scripts/npc/npc_roster.gd")


class StartNavigationProbe:
	extends Node

	var expected_data_path := ""
	var expected_npc_id: StringName = &""


	func _ready() -> void:
		call_deferred("_verify_navigation")


	func _verify_navigation() -> void:
		await get_tree().process_frame
		await get_tree().process_frame
		var npc_base := get_tree().current_scene
		assert(npc_base is NPCBase)
		assert(npc_base.npc_data_path == expected_data_path)
		assert(npc_base.npc_data.source_path == expected_data_path)
		assert(npc_base.npc_data.npc_id == expected_npc_id)
		print("MAIN_MENU_SMOKE_TEST: PASS")
		get_tree().quit(0)


func _ready() -> void:
	GameState.clear_runtime_state()
	assert(ResourceLoader.exists(SceneRouter.ROUTES[&"lobby"]))
	assert(SceneRouter.ROUTES[&"npc_base"] == "res://scenes/npc/npc_base.tscn")
	var lobby_scene: PackedScene = load(SceneRouter.ROUTES[&"lobby"])
	var lobby := lobby_scene.instantiate()
	assert(lobby is Control)
	assert(lobby.get_child_count() == 1)
	assert(lobby.get_child(0) is Label)
	assert(lobby.get_child(0).text == "Lobby Test")
	lobby.free()

	var roster: RefCounted = ROSTER_SCRIPT.new()
	assert(roster.load_from_json("res://data/npc/npc_roster.json"), roster.get_error_message())
	var ordered_npc_ids: Array[StringName] = roster.get_ordered_npc_ids()
	assert(ordered_npc_ids.size() >= 2)

	var menu_scene: PackedScene = load("res://scenes/main/main_menu.tscn")
	var menu := menu_scene.instantiate()
	add_child(menu)
	await get_tree().process_frame
	assert(menu is Control)
	var direct_child_names := PackedStringArray()
	for child in menu.get_children():
		direct_child_names.append(child.name)
	assert(direct_child_names == PackedStringArray([
		"Background",
		"HomeWorld",
		"RuleButton",
		"TimeDisplay",
		"ArchivePanel",
		"StartButton",
		"RulePanel",
	]))
	var background := menu.get_node("Background") as TextureRect
	assert(background != null)
	assert(not menu.has_node("BackgroundPlaceholder"))
	assert(background.get_index() == 0)
	assert(background.get_index() < menu.get_node("HomeWorld").get_index())
	assert(is_zero_approx(background.anchor_left))
	assert(is_zero_approx(background.anchor_top))
	assert(is_equal_approx(background.anchor_right, 1.0))
	assert(is_equal_approx(background.anchor_bottom, 1.0))
	assert(is_zero_approx(background.offset_left))
	assert(is_zero_approx(background.offset_top))
	assert(is_zero_approx(background.offset_right))
	assert(is_zero_approx(background.offset_bottom))
	assert(background.grow_horizontal == Control.GROW_DIRECTION_BOTH)
	assert(background.grow_vertical == Control.GROW_DIRECTION_BOTH)
	assert(background.expand_mode == TextureRect.EXPAND_IGNORE_SIZE)
	assert(background.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED)
	assert(background.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert(background.texture != null)

	var countdown: TimeDisplay = menu.get_node("%TimeDisplay")
	assert(countdown is Control)
	var intro_archive_panel := menu.get_node("%ArchivePanel") as Control
	var intro_start_button := menu.get_node("%StartButton") as StartButton
	var intro_rule_button := menu.get_node("%RuleButton") as Button
	assert(intro_archive_panel != null)
	assert(intro_start_button != null)
	assert(intro_rule_button != null)

	# Deferred intro finishes at the authored scene layout and can be safely replayed.
	await get_tree().create_timer(0.65).timeout
	var final_time_position := countdown.position
	var final_archive_position := intro_archive_panel.position
	var final_start_position := intro_start_button.position
	assert(is_equal_approx(countdown.modulate.a, 1.0))
	assert(is_equal_approx(intro_archive_panel.modulate.a, 1.0))
	assert(intro_start_button.scale.is_equal_approx(Vector2.ONE))
	assert(is_equal_approx(intro_start_button.modulate.a, 1.0))
	assert(is_equal_approx(intro_rule_button.modulate.a, 1.0))

	menu._play_intro_animation()
	var first_intro_tween: Tween = menu._intro_tween
	assert(first_intro_tween != null and first_intro_tween.is_running())
	assert(countdown.position.is_equal_approx(final_time_position + Vector2(0.0, -20.0)))
	assert(is_zero_approx(countdown.modulate.a))
	assert(intro_archive_panel.position.is_equal_approx(final_archive_position + Vector2(-30.0, 0.0)))
	assert(is_zero_approx(intro_archive_panel.modulate.a))
	assert(intro_start_button.position.is_equal_approx(final_start_position))
	assert(intro_start_button.scale.is_equal_approx(Vector2(0.85, 0.85)))
	assert(is_zero_approx(intro_start_button.modulate.a))
	assert(intro_start_button.pivot_offset.is_equal_approx(intro_start_button.size * 0.5))
	assert(is_zero_approx(intro_rule_button.modulate.a))

	# Intro does not disable input, and replay kills only the previous intro tween.
	assert(not intro_start_button.disabled)
	assert(intro_start_button.pressed.get_connections().size() == 1)
	intro_rule_button.pressed.emit()
	assert(menu.get_node("%RulePanel").visible)
	menu.get_node("%RulePanel/%CloseButton").pressed.emit()
	intro_archive_panel.get_node("%ArchiveButton").pressed.emit()
	assert(intro_archive_panel.get_node("%SelectionPanel").visible)
	intro_archive_panel.get_node("%CloseButton").pressed.emit()
	intro_start_button.mouse_entered.emit()
	assert(intro_start_button.is_gear_rotation_active())
	menu._play_intro_animation()
	assert(not first_intro_tween.is_valid())
	assert(intro_start_button.is_gear_rotation_active())
	intro_start_button.mouse_exited.emit()

	await get_tree().create_timer(0.65).timeout
	assert(countdown.position.is_equal_approx(final_time_position))
	assert(intro_archive_panel.position.is_equal_approx(final_archive_position))
	assert(intro_start_button.position.is_equal_approx(final_start_position))
	assert(intro_start_button.scale.is_equal_approx(Vector2.ONE))
	assert(is_equal_approx(countdown.modulate.a, 1.0))
	assert(is_equal_approx(intro_archive_panel.modulate.a, 1.0))
	assert(is_equal_approx(intro_start_button.modulate.a, 1.0))
	assert(is_equal_approx(intro_rule_button.modulate.a, 1.0))

	var time_child_names := PackedStringArray()
	for child in countdown.get_children():
		time_child_names.append(child.name)
	assert(time_child_names == PackedStringArray([
		"Background",
		"ClockIcon",
		"TimeTitle",
		"TimeValueFrame",
		"TimeValue",
	]))
	var time_background := countdown.get_node("Background") as TextureRect
	var clock_icon := countdown.get_node("ClockIcon") as TextureRect
	var time_title := countdown.get_node("TimeTitle") as Label
	var time_value_frame := countdown.get_node("TimeValueFrame") as TextureRect
	var time_value := countdown.get_node("%TimeValue") as Label
	assert(time_background != null)
	assert(clock_icon != null)
	assert(time_title != null)
	assert(time_value_frame != null)
	assert(time_value != null)
	assert(time_background.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert(clock_icon.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert(time_value_frame.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert(time_background.texture != null)
	assert(clock_icon.texture != null)
	assert(time_value_frame.texture != null)
	assert(time_title.text == "TIME LEFT")
	var time_display_source := FileAccess.get_file_as_string("res://scripts/ui/time_display.gd")
	assert(time_display_source.find("time_title") == -1)
	countdown.set_running(false)
	countdown.remaining_seconds = 62
	assert(countdown.get_remaining_seconds() == 62)
	assert(countdown.get_display_text() == "0H 01Min")
	countdown.initialize(3660)
	assert(countdown.get_remaining_seconds() == 3660)
	assert(countdown.get_display_text() == "1H 01Min")
	assert(countdown.get_time_parts()["seconds"] == 0)
	countdown.set_running(true)
	countdown._process(1.0)
	assert(countdown.get_remaining_seconds() == 3659)
	assert(countdown.get_display_text() == "1H 00Min")
	assert(countdown.get_time_parts()["seconds"] == 59)
	countdown.initialize(1)
	countdown.start()
	countdown._process(1.0)
	assert(countdown.get_remaining_seconds() == 0)
	assert(not countdown.is_running())
	assert(countdown.get_display_text() == "0H 00Min")

	var rules_panel: Control = menu.get_node("%RulePanel")
	assert(not rules_panel.visible)
	var rule_child_names := PackedStringArray()
	for child in rules_panel.get_children():
		rule_child_names.append(child.name)
	assert(rule_child_names == PackedStringArray([
		"PanelBackground",
		"TitleLabel",
		"RuleText",
		"CloseButton",
	]))
	menu.get_node("%RuleButton").pressed.emit()
	assert(rules_panel.visible)
	rules_panel.get_node("%CloseButton").pressed.emit()
	assert(not rules_panel.visible)

	# Archive is data-driven: only the first roster entry starts unlocked and selected.
	var archive: Variant = menu.get_node("%ArchivePanel")
	assert(archive.get_npc_button_count() == ordered_npc_ids.size())
	assert(archive.get_node("%NPCButtonContainer").get_child_count() == ordered_npc_ids.size())
	assert(GameState.selected_npc_id == ordered_npc_ids[0])
	assert(GameState.unlocked_npc_ids.size() == 1)
	assert(GameState.is_npc_unlocked(ordered_npc_ids[0]))
	assert(not archive.get_npc_button(ordered_npc_ids[0]).disabled)
	assert(archive.get_npc_button(ordered_npc_ids[1]).disabled)
	assert(archive.get_npc_button(ordered_npc_ids[1]).text.contains("Locked"))
	assert(archive.get_node("%SelectedNPCLabel").text == "SELECTED: %s" % roster.get_display_name(ordered_npc_ids[0]))
	archive.get_node("%ArchiveButton").pressed.emit()
	assert(archive.get_node("%SelectionPanel").visible)
	archive.get_node("%CloseButton").pressed.emit()
	assert(archive.get_node("%SelectionPanel").visible)
	await get_tree().create_timer(0.3).timeout
	assert(not archive.get_node("%SelectionPanel").visible)
	assert(not GameState.select_npc(ordered_npc_ids[1]))

	# A newly unlocked roster entry can be selected and START resolves its data path dynamically.
	assert(GameState.unlock_npc(ordered_npc_ids[1]))
	archive.refresh()
	archive.get_npc_button(ordered_npc_ids[1]).pressed.emit()
	assert(GameState.selected_npc_id == ordered_npc_ids[1])
	assert(archive.get_node("%SelectedNPCLabel").text == "SELECTED: %s" % roster.get_display_name(ordered_npc_ids[1]))

	var main_menu_source := FileAccess.get_file_as_string("res://scripts/main/main_menu.gd")
	assert(main_menu_source.find("INITIAL_NPC_DATA_PATH") == -1)
	assert(main_menu_source.find("npc_a.json") == -1)
	assert(main_menu_source.find("\"npc_a\"") == -1)
	assert(main_menu_source.find("&\"npc_a\"") == -1)
	var start_button: Button = menu.get_node("%StartButton")
	assert(start_button.pressed.get_connections().size() == 1)
	assert(menu.has_method("_start_game"))

	var navigation_probe := StartNavigationProbe.new()
	navigation_probe.expected_npc_id = ordered_npc_ids[1]
	navigation_probe.expected_data_path = roster.get_data_path(ordered_npc_ids[1])
	get_tree().root.add_child(navigation_probe)
	start_button.pressed.emit()
