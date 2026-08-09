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
	var avatar := home_world.get_node("HomeAvatar") as CharacterBody2D
	assert(navigation_region != null)
	assert(navigation_region.navigation_polygon != null)
	assert(navigation_region.navigation_polygon.get_polygon_count() > 1)
	assert(avatar != null)
	assert(avatar.get_node("VisualPlaceholder") is Sprite2D)
	assert(avatar.get_node("VisualPlaceholder").texture != null)
	var navigation_agent := avatar.get_node("NavigationAgent2D") as NavigationAgent2D
	assert(navigation_agent != null)
	assert(navigation_agent.get_navigation_map().is_valid())

	var source := FileAccess.get_file_as_string("res://scripts/home/home_avatar.gd")
	assert(source.find("func _unhandled_input") != -1)
	assert(source.find("@export_range") != -1)
	assert(source.find(".png") == -1)
	assert(source.find("global_position = Vector2(") == -1)

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
	await get_tree().physics_frame
	assert(navigation_agent.target_position.is_equal_approx(target_position))

	var movement_observed := false
	var configured_speed_observed := false
	for _frame in 300:
		await get_tree().physics_frame
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

	remove_child(home_world)
	home_world.free()


func _verify_main_menu_input_boundaries() -> void:
	GameState.clear_runtime_state()
	var menu := MAIN_MENU_SCENE.instantiate() as Control
	assert(menu != null)
	add_child(menu)
	await get_tree().process_frame
	var avatar := menu.get_node("HomeWorld/HomeAvatar") as CharacterBody2D
	assert(avatar != null)
	assert(menu.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert(menu.get_node("%StartButton").mouse_filter == Control.MOUSE_FILTER_STOP)
	assert(menu.get_node("%RuleButton").mouse_filter == Control.MOUSE_FILTER_STOP)
	assert(menu.get_node("%ArchivePanel").mouse_filter == Control.MOUSE_FILTER_STOP)

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
