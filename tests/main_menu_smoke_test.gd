extends Node

const ROSTER_SCRIPT = preload("res://scripts/npc/npc_roster.gd")


class StartNavigationProbe:
	extends Node

	var expected_data_path := ""
	var expected_npc_id: StringName = &""


	func _ready() -> void:
		call_deferred("_verify_navigation")


	func _verify_navigation() -> void:
		for _frame in 300:
			if not SceneRouter.is_transitioning() and get_tree().current_scene is NPCBase:
				break
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
	assert(not menu.has_node("BackgroundMotion"))
	assert(not menu.has_node("BackgroundPlaceholder"))
	assert(background.get_index() == 0)
	assert(background.get_index() < menu.get_node("HomeWorld").get_index())
	assert(is_zero_approx(background.anchor_left))
	assert(is_zero_approx(background.anchor_top))
	assert(is_equal_approx(background.anchor_right, 1.0))
	assert(is_equal_approx(background.anchor_bottom, 1.0))
	assert(background.grow_horizontal == Control.GROW_DIRECTION_BOTH)
	assert(background.grow_vertical == Control.GROW_DIRECTION_BOTH)
	assert(background.expand_mode == TextureRect.EXPAND_IGNORE_SIZE)
	assert(background.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED)
	assert(background.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert(background.texture != null)
	assert(not FileAccess.file_exists("res://scenes/ui/background_motion.tscn"))
	assert(not FileAccess.file_exists("res://scripts/ui/background_motion.gd"))
	var initial_background_position := background.position
	var initial_background_scale := background.scale
	await get_tree().create_timer(0.2).timeout
	assert(background.position.is_equal_approx(initial_background_position))
	assert(background.scale.is_equal_approx(initial_background_scale))

	# Both visual layers ignore mouse input, so an uncovered lobby click still reaches HomeAvatar.
	var home_avatar := menu.get_node("HomeWorld/HomeAvatar") as HomeAvatar
	assert(home_avatar != null)
	var lobby_click := InputEventMouseButton.new()
	lobby_click.button_index = MOUSE_BUTTON_LEFT
	lobby_click.pressed = true
	lobby_click.position = Vector2(350.0, 500.0)
	get_viewport().push_input(lobby_click)
	await get_tree().process_frame
	assert(home_avatar.is_moving())
	home_avatar.stop_movement()

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

	# The three authored UI groups match the 1152x648 reference layout exactly.
	var archive_texture := intro_archive_panel.get_node("%ArchiveButton/ArchiveTexture") as TextureRect
	var magnifier_texture := intro_archive_panel.get_node("%ArchiveButton/MagnifierTexture") as TextureRect
	var clock_texture := countdown.get_node("ClockTexture") as TextureRect
	var time_frame_texture := countdown.get_node("TimeFrameTexture") as TextureRect
	var gear_back := intro_start_button.get_node("Gear_Back") as TextureRect
	var gear_front := intro_start_button.get_node("Gear_Front") as TextureRect
	var start_image := intro_start_button.get_node("StartImage") as TextureRect
	assert(archive_texture.get_global_rect().position.is_equal_approx(Vector2(48.0, 408.0)))
	assert(archive_texture.size.is_equal_approx(Vector2(178.0, 215.0)))
	assert(magnifier_texture.get_global_rect().position.is_equal_approx(Vector2(168.0, 516.0)))
	assert(magnifier_texture.size.is_equal_approx(Vector2(82.0, 105.0)))
	assert(clock_texture.get_global_rect().position.is_equal_approx(Vector2(835.0, 21.0)))
	assert(clock_texture.size.is_equal_approx(Vector2(132.0, 120.0)))
	assert(time_frame_texture.get_global_rect().position.is_equal_approx(Vector2(925.0, 40.0)))
	assert(time_frame_texture.size.is_equal_approx(Vector2(188.0, 78.0)))
	assert(gear_back.get_global_rect().position.is_equal_approx(Vector2(934.0, 400.0)))
	assert(gear_back.size.is_equal_approx(Vector2(98.0, 98.0)))
	assert(gear_front.get_global_rect().position.is_equal_approx(Vector2(951.0, 434.0)))
	assert(gear_front.size.is_equal_approx(Vector2(197.0, 197.0)))
	assert(start_image.get_global_rect().position.is_equal_approx(Vector2(1000.0, 509.0)))
	assert(start_image.size.is_equal_approx(Vector2(100.0, 48.0)))
	for texture_rect: TextureRect in [
		archive_texture,
		magnifier_texture,
		clock_texture,
		time_frame_texture,
		gear_back,
		gear_front,
		start_image,
	]:
		assert(texture_rect.expand_mode == TextureRect.EXPAND_IGNORE_SIZE)
		assert(texture_rect.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
		assert(texture_rect.mouse_filter == Control.MOUSE_FILTER_IGNORE)
		assert(texture_rect.texture != null)
	assert(gear_back.pivot_offset.is_equal_approx(gear_back.size / 2.0))
	assert(gear_front.pivot_offset.is_equal_approx(gear_front.size / 2.0))

	# The shared hover component animates RuleButton without changing its click contract.
	assert(intro_rule_button.get_script().resource_path == "res://scripts/ui/button_hover_effect.gd")
	assert(intro_start_button.get_script().resource_path != "res://scripts/ui/button_hover_effect.gd")
	var rule_default_modulate := intro_rule_button.modulate
	intro_rule_button.mouse_entered.emit()
	assert(intro_rule_button.is_hover_tween_running())
	await get_tree().create_timer(0.08).timeout
	assert(intro_rule_button.scale.x > 1.0 and intro_rule_button.scale.x <= 1.051)
	assert(intro_rule_button.modulate.r > rule_default_modulate.r)
	intro_rule_button.mouse_exited.emit()
	await get_tree().create_timer(0.2).timeout
	assert(intro_rule_button.scale.is_equal_approx(Vector2.ONE))
	assert(intro_rule_button.modulate.is_equal_approx(rule_default_modulate))
	assert(intro_rule_button.pivot_offset.is_equal_approx(intro_rule_button.size / 2.0))

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
		"ClockTexture",
		"TimeFrameTexture",
		"TimeTitle",
		"TimeValue",
	]))
	var time_title := countdown.get_node("TimeTitle") as Label
	var time_value := countdown.get_node("%TimeValue") as Label
	assert(clock_texture != null)
	assert(time_frame_texture != null)
	assert(time_title != null)
	assert(time_value != null)
	assert(time_title.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert(time_value.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert(clock_texture.z_index > time_frame_texture.z_index)
	assert(time_title.text == "TIME LEFT")
	var time_display_source := FileAccess.get_file_as_string("res://scripts/ui/time_display.gd")
	assert(time_display_source.find("time_title") == -1)

	# Second-level changes do not animate until the visible hour/minute text changes.
	countdown.set_running(false)
	countdown.set_remaining_seconds(125)
	await get_tree().create_timer(0.22).timeout
	assert(not countdown.is_value_feedback_running())
	assert(time_value.scale.is_equal_approx(Vector2.ONE))
	var unchanged_display_tween: Tween = countdown._value_feedback_tween
	countdown.set_remaining_seconds(124)
	assert(countdown.get_display_text() == "0H 02Min")
	assert(countdown._value_feedback_tween == unchanged_display_tween)
	assert(not countdown.is_value_feedback_running())

	# Crossing a minute boundary changes the text and plays one feedback Tween.
	countdown.set_remaining_seconds(120)
	countdown.set_running(true)
	countdown._process(1.0)
	assert(countdown.get_remaining_seconds() == 119)
	assert(countdown.get_display_text() == "0H 01Min")
	assert(countdown.is_value_feedback_running())
	assert(countdown._value_feedback_tween != unchanged_display_tween)
	await get_tree().create_timer(0.06).timeout
	assert(time_value.scale.x > 1.0 and time_value.scale.x <= 1.041)
	await get_tree().create_timer(0.16).timeout
	assert(time_value.scale.is_equal_approx(Vector2.ONE))

	# Crossing an hour boundary uses the same display-change feedback.
	countdown.initialize(3600)
	await get_tree().create_timer(0.22).timeout
	var before_hour_boundary_tween: Tween = countdown._value_feedback_tween
	countdown.set_running(true)
	countdown._process(1.0)
	assert(countdown.get_remaining_seconds() == 3599)
	assert(countdown.get_display_text() == "0H 59Min")
	assert(countdown.is_value_feedback_running())
	assert(countdown._value_feedback_tween != before_hour_boundary_tween)
	await get_tree().create_timer(0.22).timeout
	assert(time_value.scale.is_equal_approx(Vector2.ONE))

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
	assert(archive.get_node("%SelectedNPCLabel").text == "???")
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
	assert(archive.get_node("%SelectedNPCLabel").text == "???")

	var main_menu_source := FileAccess.get_file_as_string("res://scripts/main/main_menu.gd")
	assert(main_menu_source.find("INITIAL_NPC_DATA_PATH") == -1)
	assert(main_menu_source.find("npc_a.json") == -1)
	assert(main_menu_source.find("\"npc_zhang_yuan\"") == -1)
	assert(main_menu_source.find("&\"npc_zhang_yuan\"") == -1)
	var start_button: Button = menu.get_node("%StartButton")
	assert(start_button.pressed.get_connections().size() == 1)
	assert(menu.has_method("_start_game"))

	var navigation_probe := StartNavigationProbe.new()
	navigation_probe.expected_npc_id = ordered_npc_ids[1]
	navigation_probe.expected_data_path = roster.get_data_path(ordered_npc_ids[1])
	get_tree().root.add_child(navigation_probe)
	start_button.pressed.emit()
