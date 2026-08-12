extends Node

const HOME_WORLD_SCENE: PackedScene = preload("res://scenes/home/home_world.tscn")
const MAIN_MENU_SCENE: PackedScene = preload("res://scenes/main/main_menu.tscn")

var expected_outer_outline := PackedVector2Array([
	Vector2(260, 365), Vector2(325, 345), Vector2(405, 325), Vector2(500, 298),
	Vector2(595, 270), Vector2(690, 242), Vector2(785, 215), Vector2(855, 215),
	Vector2(910, 240), Vector2(945, 280), Vector2(952, 325), Vector2(932, 365),
	Vector2(895, 400), Vector2(850, 430), Vector2(805, 455), Vector2(755, 480),
	Vector2(710, 510), Vector2(660, 545), Vector2(595, 575), Vector2(520, 596),
	Vector2(435, 605), Vector2(355, 598), Vector2(300, 575), Vector2(270, 535),
	Vector2(260, 490), Vector2(260, 430),
])
var expected_merged_obstacle := PackedVector2Array([
	Vector2(475, 330), Vector2(545, 305), Vector2(625, 288), Vector2(710, 288),
	Vector2(790, 305), Vector2(845, 335), Vector2(870, 375), Vector2(860, 415),
	Vector2(825, 448), Vector2(765, 470), Vector2(690, 480), Vector2(610, 470),
	Vector2(595, 535), Vector2(545, 535), Vector2(540, 445), Vector2(495, 410),
	Vector2(475, 370),
])


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
	assert(navigation_region.navigation_polygon.get_polygon_count() == 17)
	var navigation_vertices := navigation_region.navigation_polygon.vertices
	for expected_point: Vector2 in expected_outer_outline:
		assert(_vertices_contain_point(navigation_vertices, expected_point))
	for expected_point: Vector2 in expected_merged_obstacle:
		assert(_vertices_contain_point(navigation_vertices, expected_point))
	assert(avatar != null)
	assert(avatar.position.is_equal_approx(Vector2(360.0, 430.0)))
	var visual := avatar.get_node("AvatarVisual") as AnimatedSprite2D
	assert(visual != null)
	assert(visual.sprite_frames != null)
	assert(visual.sprite_frames.has_animation(&"idle"))
	assert(visual.sprite_frames.has_animation(&"walk"))
	assert(visual.sprite_frames.get_frame_count(&"idle") > 0)
	assert(visual.sprite_frames.get_frame_count(&"walk") > 0)
	var navigation_agent := avatar.get_node("NavigationAgent2D") as NavigationAgent2D
	assert(navigation_agent != null)
	assert(navigation_agent.get_navigation_map().is_valid())

	var source := FileAccess.get_file_as_string("res://scripts/home/home_avatar.gd")
	assert(source.find("func _unhandled_input") != -1)
	assert(source.find("@export_range") != -1)
	assert(source.find(".png") == -1)
	assert(source.find("global_position = Vector2(") == -1)
	assert(source.find("AnimationPlayer") == -1)
	assert(source.find("AnimatedSprite2D") != -1)
	assert(source.find("idle_breath") == -1)
	assert(source.find("IDLE_BREATH") == -1)

	# Idle remains a SpriteFrames animation; no scale-based breathing effect remains.
	assert(visual.animation == &"idle")
	assert(visual.is_playing())
	assert(avatar.scale.is_equal_approx(Vector2.ONE))
	assert(visual.scale.is_equal_approx(Vector2.ONE))
	await get_tree().create_timer(0.25).timeout
	assert(visual.scale.is_equal_approx(Vector2.ONE))
	assert(avatar.scale.is_equal_approx(Vector2.ONE))

	await get_tree().physics_frame
	await get_tree().physics_frame
	var navigation_map := navigation_agent.get_navigation_map()
	var obstacle_center := Vector2(680.0, 370.0)
	var counter_point := Vector2(500.0, 250.0)
	var furniture_point := Vector2(900.0, 550.0)
	for blocked_point: Vector2 in [obstacle_center, counter_point, furniture_point]:
		var closest_walkable := NavigationServer2D.map_get_closest_point(navigation_map, blocked_point)
		assert(closest_walkable.distance_to(blocked_point) > 1.0)

	# Reaching the right side from the initial left floor requires a real detour around the railing hole.
	var detour_target := Vector2(900.0, 350.0)
	var detour_path := NavigationServer2D.map_get_path(
		navigation_map,
		avatar.global_position,
		detour_target,
		true
	)
	assert(detour_path.size() >= 3)
	assert(_path_length(detour_path) > avatar.global_position.distance_to(detour_target) + 10.0)

	assert(is_equal_approx(avatar.move_speed, 180.0))
	avatar.stopping_distance = 6.0
	var initial_position: Vector2 = avatar.global_position
	var target_position := detour_target
	var click_event := InputEventMouseButton.new()
	click_event.button_index = MOUSE_BUTTON_LEFT
	click_event.pressed = true
	click_event.position = target_position
	avatar._unhandled_input(click_event)
	assert(avatar.get_movement_target().is_equal_approx(target_position))
	assert(avatar.is_moving())
	assert(visual.animation == &"walk")
	assert(visual.is_playing())
	assert(visual.scale.is_equal_approx(Vector2.ONE))

	# Rapid retargeting keeps the walk animation and does not change visual scale.
	avatar.set_movement_target(Vector2(820.0, 260.0))
	avatar.set_movement_target(target_position)
	assert(avatar.get_movement_target().is_equal_approx(target_position))
	assert(visual.animation == &"walk")
	assert(visual.scale.is_equal_approx(Vector2.ONE))
	await get_tree().physics_frame
	assert(navigation_agent.target_position.is_equal_approx(target_position))

	var movement_observed := false
	var configured_speed_observed := false
	for _frame in 600:
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
	assert(visual.animation == &"idle")
	assert(visual.is_playing())
	await get_tree().create_timer(0.25).timeout
	assert(visual.scale.is_equal_approx(Vector2.ONE))
	assert(avatar.scale.is_equal_approx(Vector2.ONE))

	# Repeated stop while already idle remains stable.
	avatar.stop_movement()
	avatar.stop_movement()
	assert(visual.animation == &"idle")
	assert(visual.scale.is_equal_approx(Vector2.ONE))

	# A new leftward move preserves facing logic; external stop restores idle.
	var left_target := Vector2(300.0, 500.0)
	avatar.set_movement_target(left_target)
	assert(visual.animation == &"walk")
	assert(visual.scale.is_equal_approx(Vector2.ONE))
	var left_facing_observed := false
	for _frame in 60:
		await get_tree().physics_frame
		if avatar.velocity.x < 0.0:
			left_facing_observed = true
			assert(visual.flip_h)
			break
	assert(left_facing_observed)
	avatar.stop_movement()
	assert(not avatar.is_moving())
	assert(avatar.velocity.is_zero_approx())
	assert(visual.animation == &"idle")
	assert(visual.scale.is_equal_approx(Vector2.ONE))
	avatar.stop_movement()
	assert(visual.animation == &"idle")
	assert(visual.scale.is_equal_approx(Vector2.ONE))

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

	var lobby_target := Vector2(350.0, 500.0)
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
	assert(avatar.get_node("AvatarVisual").scale.is_equal_approx(Vector2.ONE))

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


func _vertices_contain_point(vertices: PackedVector2Array, expected_point: Vector2) -> bool:
	for vertex: Vector2 in vertices:
		if vertex.is_equal_approx(expected_point):
			return true
	return false


func _path_length(path: PackedVector2Array) -> float:
	var result := 0.0
	for index in range(1, path.size()):
		result += path[index - 1].distance_to(path[index])
	return result
