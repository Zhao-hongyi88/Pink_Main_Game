extends Node

const START_BUTTON_SCENE: PackedScene = preload("res://scenes/ui/start_button.tscn")
const MAIN_MENU_SCENE: PackedScene = preload("res://scenes/main/main_menu.tscn")


func _ready() -> void:
	await _verify_standalone_hover_rotation()
	await _verify_main_menu_interface()
	print("START_BUTTON_SMOKE_TEST: PASS")
	get_tree().quit(0)


func _verify_standalone_hover_rotation() -> void:
	var start_button: Variant = START_BUTTON_SCENE.instantiate()
	assert(start_button is Button)
	add_child(start_button)
	await get_tree().process_frame
	assert(start_button.name == "StartButton")
	assert(start_button.is_unique_name_in_owner())
	assert(start_button.pressed.get_connections().is_empty())
	assert(start_button.get_node("Gear_Back") is TextureRect)
	assert(start_button.get_node("Gear_Front") is TextureRect)
	var gear_back: TextureRect = start_button.get_node("Gear_Back")
	var gear_front: TextureRect = start_button.get_node("Gear_Front")
	assert(gear_back.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert(gear_front.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert(gear_back.texture != null)
	assert(gear_front.texture != null)
	start_button.gear_speed = 20.0

	var script_source := FileAccess.get_file_as_string("res://scripts/ui/start_button.gd")
	var scene_source := FileAccess.get_file_as_string("res://scenes/ui/start_button.tscn")
	assert(script_source.find("AnimationPlayer") == -1)
	assert(script_source.find("SceneRouter") == -1)
	assert(script_source.find("GameState") == -1)
	assert(script_source.find("Archive") == -1)
	assert(script_source.find("res://") == -1)
	assert(script_source.find("as_relative()") != -1)
	assert(script_source.find("Tween.TRANS_LINEAR") != -1)
	assert(script_source.find("set_loops()") != -1)
	assert(script_source.find("set_parallel(true)") != -1)
	assert(scene_source.find("AnimationPlayer") == -1)

	var initial_back_rotation := gear_back.rotation
	var initial_front_rotation := gear_front.rotation
	var rotation_duration: float = TAU / start_button.gear_speed
	start_button.mouse_entered.emit()
	assert(start_button.is_gear_rotation_active())
	await get_tree().create_timer(rotation_duration * 1.25).timeout
	assert(start_button.is_gear_rotation_active())
	assert(gear_back.rotation > initial_back_rotation + TAU)
	assert(gear_front.rotation < initial_front_rotation - TAU)

	var first_cycle_back_rotation := gear_back.rotation
	var first_cycle_front_rotation := gear_front.rotation
	await get_tree().create_timer(rotation_duration * 1.25).timeout
	assert(start_button.is_gear_rotation_active())
	assert(gear_back.rotation > first_cycle_back_rotation)
	assert(gear_front.rotation < first_cycle_front_rotation)

	start_button.mouse_exited.emit()
	assert(not start_button.is_gear_rotation_active())
	var held_back_rotation := gear_back.rotation
	var held_front_rotation := gear_front.rotation
	await get_tree().create_timer(0.12).timeout
	assert(is_equal_approx(gear_back.rotation, held_back_rotation))
	assert(is_equal_approx(gear_front.rotation, held_front_rotation))
	assert(not is_zero_approx(held_back_rotation))
	assert(not is_zero_approx(held_front_rotation))

	start_button.mouse_entered.emit()
	await get_tree().create_timer(rotation_duration * 0.5).timeout
	assert(gear_back.rotation > held_back_rotation)
	assert(gear_front.rotation < held_front_rotation)
	start_button.mouse_exited.emit()
	assert(not start_button.is_gear_rotation_active())

	remove_child(start_button)
	start_button.free()


func _verify_main_menu_interface() -> void:
	GameState.clear_runtime_state()
	var menu := MAIN_MENU_SCENE.instantiate() as Control
	assert(menu != null)
	add_child(menu)
	await get_tree().process_frame
	var start_button := menu.get_node("%StartButton") as Button
	assert(start_button != null)
	assert(start_button.name == "StartButton")
	assert(start_button.is_unique_name_in_owner())
	assert(start_button.pressed.get_connections().size() == 1)
	assert(menu.has_method("_start_game"))
	assert(start_button.get_node("Gear_Back") is TextureRect)
	assert(start_button.get_node("Gear_Front") is TextureRect)
	assert(menu.get_node("%ArchivePanel") != null)
	assert(menu.get_node("%RulePanel") != null)

	remove_child(menu)
	menu.free()
