extends Node

const HOME_WORLD_SCENE: PackedScene = preload("res://scenes/home/home_world.tscn")
const MAIN_MENU_SCENE: PackedScene = preload("res://scenes/main/main_menu.tscn")


func _ready() -> void:
	await _verify_navigation_and_movement()
	await _verify_main_menu_input_boundaries()
	print("HOME_AVATAR_SMOKE_TEST: PASS")
	get_tree().quit(0)


func _verify_navigation_and_movement() -> void:
	var home_world := HOME_WORLD_SCENE.instantiate() as Node2D
	assert(home_world != null)
	add_child(home_world)
	var navigation_region := home_world.get_node("NavigationRegion2D") as NavigationRegion2D
	var avatar := home_world.get_node("HomeAvatar") as HomeAvatar
	assert(navigation_region != null)
	assert(navigation_region.navigation_polygon != null)
	assert(navigation_region.navigation_polygon.get_polygon_count() > 1)
	assert(avatar != null)
	var visual := avatar.get_node("VisualPlaceholder") as Sprite2D
	assert(visual != null)
	assert(visual.texture != null)
	var navigation_agent := avatar.get_node("NavigationAgent2D") as NavigationAgent2D
	assert(navigation_agent != null)
	assert(navigation_agent.get_navigation_map().is_valid())

	var source := FileAccess.get_file_as_string("res://scripts/home/home_avatar.gd")
	assert(source.find("func _unhandled_input") != -1)
	assert(source.find("@export_range") != -1)
	assert(source.find(".png") == -1)
	assert(source.find("global_position = Vector2(") == -1)
	assert(source.find("AnimationPlayer") == -1)
	assert(source.find("AnimatedSprite2D") == -1)

	# Idle breathing starts immediately and affects only the visual child.
	assert(avatar.is_idle_breathing())
	assert(avatar.scale.is_equal_approx(Vector2.ONE))
	var initial_idle_tween: Tween = avatar._idle_breath_tween
	await get_tree().create_timer(0.25).timeout
	assert(avatar.is_idle_breathing())
	assert(visual.scale.x > 1.0 and visual.scale.x <= 1.016)
	assert(visual.scale.y > 1.0 and visual.scale.y <= 1.016)
	assert(avatar.scale.is_equal_approx(Vector2.ONE))

	await get_tree().physics_frame
	await get_tree().physics_frame
	avatar.move_speed = 420.0
	avatar.stopping_distance = 6.0
	var initial_position: Vector2 = avatar.global_position
	var target_position := Vector2(780.0, 210.0)
	var click_event := InputEventMouseButton.new()
	click_event.button_index = MOUSE_BUTTON_LEFT
	click_event.pressed = true
	click_event.position = target_position
	avatar._unhandled_input(click_event)
	assert(avatar.get_movement_target().is_equal_approx(target_position))
	assert(avatar.is_moving())
	assert(not avatar.is_idle_breathing())
	assert(visual.scale.is_equal_approx(Vector2.ONE))
	assert(not initial_idle_tween.is_valid())

	# Rapid retargeting while moving never creates an idle tween.
	avatar.set_movement_target(Vector2(740.0, 230.0))
	avatar.set_movement_target(target_position)
	assert(avatar.get_movement_target().is_equal_approx(target_position))
	assert(not avatar.is_idle_breathing())
	assert(avatar._idle_breath_tween == null)
	await get_tree().physics_frame
	assert(navigation_agent.target_position.is_equal_approx(target_position))

	var movement_observed := false
	var configured_speed_observed := false
	for _frame in 300:
		await get_tree().physics_frame
		if avatar.is_moving():
			assert(not avatar.is_idle_breathing())
		if avatar.global_position.distance_to(initial_position) > 1.0:
			movement_observed = true
		if is_equal_approx(avatar.velocity.length(), avatar.move_speed):
			configured_speed_observed = true
		if not avatar.is_moving():
			break
	assert(movement_observed)
	assert(configured_speed_observed)
	assert(not avatar.is_moving())
	assert(avatar.velocity.is_zero_approx())
	assert(avatar.global_position.distance_to(target_position) <= avatar.stopping_distance + 2.0)
	assert(avatar.is_idle_breathing())
	var arrived_idle_tween: Tween = avatar._idle_breath_tween
	await get_tree().create_timer(0.25).timeout
	assert(not visual.scale.is_equal_approx(Vector2.ONE))
	assert(avatar.scale.is_equal_approx(Vector2.ONE))

	# Repeated stop while already idle preserves the single existing loop.
	avatar.stop_movement()
	avatar.stop_movement()
	assert(avatar._idle_breath_tween == arrived_idle_tween)
	assert(avatar.is_idle_breathing())

	# A new leftward move stops breathing, preserves facing logic, and external stop resumes it.
	var left_target := Vector2(300.0, 210.0)
	avatar.set_movement_target(left_target)
	assert(not arrived_idle_tween.is_valid())
	assert(not avatar.is_idle_breathing())
	assert(visual.scale.is_equal_approx(Vector2.ONE))
	var left_facing_observed := false
	for _frame in 60:
		await get_tree().physics_frame
		assert(not avatar.is_idle_breathing())
		if avatar.velocity.x < 0.0:
			left_facing_observed = true
			assert(visual.flip_h)
			break
	assert(left_facing_observed)
	avatar.stop_movement()
	assert(not avatar.is_moving())
	assert(avatar.velocity.is_zero_approx())
	assert(avatar.is_idle_breathing())
	assert(visual.scale.is_equal_approx(Vector2.ONE))
	var external_stop_tween: Tween = avatar._idle_breath_tween
	avatar.stop_movement()
	assert(avatar._idle_breath_tween == external_stop_tween)

	remove_child(home_world)
	home_world.free()


func _verify_main_menu_input_boundaries() -> void:
	GameState.clear_runtime_state()
	var menu := MAIN_MENU_SCENE.instantiate() as Control
	assert(menu != null)
	add_child(menu)
	await get_tree().process_frame
	var avatar := menu.get_node("HomeWorld/HomeAvatar") as HomeAvatar
	var background := menu.get_node("Background") as TextureRect
	assert(avatar != null)
	assert(background != null)
	assert(background.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert(menu.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert(menu.get_node("%StartButton").mouse_filter == Control.MOUSE_FILTER_STOP)
	assert(menu.get_node("%RuleButton").mouse_filter == Control.MOUSE_FILTER_STOP)
	assert(menu.get_node("%ArchivePanel").mouse_filter == Control.MOUSE_FILTER_STOP)

	var lobby_target := Vector2(780.0, 210.0)
	var lobby_click := InputEventMouseButton.new()
	lobby_click.button_index = MOUSE_BUTTON_LEFT
	lobby_click.pressed = true
	lobby_click.position = lobby_target
	var previous_movement_target: Vector2 = avatar.get_movement_target()
	get_viewport().push_input(lobby_click)
	await get_tree().process_frame
	assert(avatar.is_moving())
	assert(not avatar.get_movement_target().is_equal_approx(previous_movement_target))
	avatar.stop_movement()
	assert(not avatar.is_moving())
	assert(avatar.is_idle_breathing())

	menu.get_node("%RuleButton").pressed.emit()
	assert(menu.get_node("%RulePanel").visible)
	assert(not avatar.is_moving())
	menu.get_node("%RulePanel/%CloseButton").pressed.emit()
	assert(not menu.get_node("%RulePanel").visible)
	menu.get_node("%ArchivePanel/%ArchiveButton").pressed.emit()
	assert(menu.get_node("%ArchivePanel/%SelectionPanel").visible)
	assert(not avatar.is_moving())
	assert(menu.get_node("%StartButton").pressed.get_connections().size() == 1)

	remove_child(menu)
	menu.free()
