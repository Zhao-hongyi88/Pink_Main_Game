extends Node


class StartTransitionProbe:
	extends Node

	const HOME_SCENE_PATH := "res://scenes/main/main_menu.tscn"
	const NPC_BASE_SCENE_PATH := "res://scenes/npc/npc_base.tscn"
	const LOBBY_SCENE_PATH := "res://scenes/main/lobby.tscn"


	func run() -> void:
		GameState.clear_runtime_state()
		SceneRouter.clear_next_transition_mode()
		var normal_layer = SceneRouter.get_node("TransitionLayer")
		var start_layer = SceneRouter.get_start_transition_layer()
		assert(start_layer != null)
		assert(start_layer.name == "StartTransitionLayer")
		assert(start_layer.layer > normal_layer.layer)
		assert(is_equal_approx(start_layer.move_duration, 0.6))
		assert(is_equal_approx(start_layer.fade_duration, 0.6))
		assert(is_equal_approx(start_layer.loading_fade_delay, 0.2))
		assert(is_equal_approx(start_layer.loading_fade_duration, 0.28))
		assert(is_equal_approx(start_layer.grow_duration, 0.48))
		assert(is_equal_approx(start_layer.center_hold_duration, 0.52))
		assert(is_equal_approx(start_layer.reveal_duration, 0.9))
		assert(is_equal_approx(
			start_layer.move_duration
			+ start_layer.grow_duration
			+ start_layer.center_hold_duration
			+ start_layer.reveal_duration,
			2.5
		))
		normal_layer.fade_duration = 0.05
		start_layer.move_duration = 0.12
		start_layer.fade_duration = 0.12
		start_layer.loading_fade_delay = 0.02
		start_layer.loading_fade_duration = 0.05
		start_layer.grow_duration = 0.1
		start_layer.center_hold_duration = 0.08
		start_layer.reveal_duration = 0.15
		start_layer.gear_rotation_speed = 20.0

		_assert_layer_structure(start_layer)
		assert(SceneRouter.go_to(&"home"))
		await _wait_for_navigation()
		var main_menu := get_tree().current_scene
		assert(main_menu.scene_file_path == HOME_SCENE_PATH)
		var start_button := main_menu.get_node("%StartButton") as Button
		var source_back := start_button.get_node("Gear_Back") as TextureRect
		var source_front := start_button.get_node("Gear_Front") as TextureRect
		var roster: RefCounted = main_menu.get("npc_roster")
		var expected_npc_id: StringName = GameState.selected_npc_id
		var expected_data_path: String = roster.get_data_path(expected_npc_id)
		assert(not expected_data_path.is_empty())
		assert(SceneRouter.get_next_transition_mode().is_empty())

		start_button.pressed.emit()
		assert(SceneRouter.is_transitioning())
		assert(SceneRouter.get_active_transition_mode() == SceneRouter.START_TRANSITION_MODE)
		assert(SceneRouter.get_next_transition_mode().is_empty())
		assert(start_layer.last_transition_started)
		assert(start_layer.is_active())
		assert(start_layer.is_input_locked())
		assert(start_layer.gear_back.texture == source_back.texture)
		assert(start_layer.gear_front.texture == source_front.texture)
		assert(not source_back.visible)
		assert(not source_front.visible)

		# Programmatic duplicate input cannot enqueue a second navigation or mode.
		start_button.pressed.emit()
		assert(not SceneRouter.set_next_transition_mode(SceneRouter.START_TRANSITION_MODE))
		assert(not SceneRouter.go_to(&"lobby"))
		assert(SceneRouter.get_active_transition_mode() == SceneRouter.START_TRANSITION_MODE)

		await _wait_for_center(start_layer)
		assert(start_layer.current_phase == &"center_spin")
		assert(is_equal_approx(start_layer.dim_overlay.modulate.a, 1.0))
		assert(start_layer.loading_label.visible)
		assert(start_layer.loading_label.text == "Loading......")
		assert(is_equal_approx(start_layer.loading_label.modulate.a, 1.0))
		var screen_center: Vector2 = start_layer.get_screen_center()
		var back_center: Vector2 = start_layer.gear_back.position + start_layer.gear_back.size * 0.5
		var front_center: Vector2 = start_layer.gear_front.position + start_layer.gear_front.size * 0.5
		assert(back_center.is_equal_approx(
			screen_center + start_layer.BACK_GEAR_CENTER_OFFSET
		))
		assert(front_center.is_equal_approx(
			screen_center + start_layer.FRONT_GEAR_CENTER_OFFSET
		))
		assert(start_layer.gear_back.pivot_offset.is_equal_approx(
			start_layer.gear_back.size * 0.5
		))
		assert(start_layer.gear_front.pivot_offset.is_equal_approx(
			start_layer.gear_front.size * 0.5
		))
		var back_rotation: float = start_layer.gear_back.rotation
		var front_rotation: float = start_layer.gear_front.rotation
		await get_tree().create_timer(0.04).timeout
		assert(start_layer.gear_back.rotation > back_rotation)
		assert(start_layer.gear_front.rotation < front_rotation)

		var reveal_observed := false
		for _frame in 300:
			if start_layer.current_phase == &"reveal":
				reveal_observed = true
				break
			await get_tree().process_frame
		assert(reveal_observed)
		assert(start_layer.reveal_overlay.visible)
		assert(start_layer.is_input_locked())

		await _wait_for_navigation()
		var npc_base := get_tree().current_scene
		assert(npc_base.scene_file_path == NPC_BASE_SCENE_PATH)
		assert(npc_base.npc_data_path == expected_data_path)
		assert(npc_base.npc_data.npc_id == expected_npc_id)
		assert(start_layer.last_reveal_completed)
		assert(not start_layer.is_active())
		assert(not start_layer.is_input_locked())
		assert(start_layer.current_phase == &"idle")
		assert(not start_layer.loading_label.visible)
		var reveal_material := start_layer.reveal_overlay.material as ShaderMaterial
		assert(is_equal_approx(
			float(reveal_material.get_shader_parameter("radius")),
			start_layer.reveal_max_radius
		))
		assert(SceneRouter.get_next_transition_mode().is_empty())
		assert(SceneRouter.get_active_transition_mode().is_empty())

		# The following navigation uses the unchanged ordinary fade transition.
		assert(SceneRouter.go_to(&"lobby"))
		assert(SceneRouter.get_active_transition_mode().is_empty())
		assert(not start_layer.is_active())
		await _wait_for_navigation()
		assert(get_tree().current_scene.scene_file_path == LOBBY_SCENE_PATH)
		assert(not start_layer.is_active())
		assert(SceneRouter.get_next_transition_mode().is_empty())

		print("START_TRANSITION_SMOKE_TEST: PASS")
		get_tree().quit(0)


	func _assert_layer_structure(start_layer) -> void:
		assert(start_layer.get_node("%TransitionRoot") is Control)
		assert(start_layer.get_node("%DimOverlay") is ColorRect)
		assert(start_layer.get_node("%GearBack") is TextureRect)
		assert(start_layer.get_node("%GearFront") is TextureRect)
		assert(start_layer.get_node("%LoadingLabel") is Label)
		var reveal_overlay := start_layer.get_node("%RevealOverlay") as ColorRect
		assert(reveal_overlay != null)
		assert(reveal_overlay.material is ShaderMaterial)
		assert((reveal_overlay.material as ShaderMaterial).shader.code.contains("radius"))
		assert(start_layer.get_node("%TransitionRoot").mouse_filter == Control.MOUSE_FILTER_IGNORE)


	func _wait_for_center(start_layer) -> void:
		for _frame in 300:
			if start_layer.last_center_reached:
				return
			await get_tree().process_frame
		assert(false, "Start gears did not reach the screen center.")


	func _wait_for_navigation() -> void:
		for _frame in 600:
			if not SceneRouter.is_transitioning():
				await get_tree().process_frame
				return
			await get_tree().process_frame
		assert(false, "SceneRouter navigation timed out.")


func _ready() -> void:
	call_deferred("_start_probe")


func _start_probe() -> void:
	var probe := StartTransitionProbe.new()
	get_tree().root.add_child(probe)
	probe.run()
