extends Node


class MemoryIntegrationProbe:
	extends Node

	const NPC_BASE_SCENE_PATH := "res://scenes/npc/npc_base.tscn"
	const HOME_SCENE_PATH := "res://scenes/main/main_menu.tscn"
	const CASES: Array[Dictionary] = [
		{
			"npc_id": &"npc_zhang_yuan",
			"data_path": "res://data/npc/npc_a.json",
			"memory_scene": "res://scenes/memory/npc1_zhang_yuan_memory.tscn",
			"points": [&"StudyRecord", &"DegreeCertificate", &"InterviewResult"],
		},
		{
			"npc_id": &"npc_li_lei",
			"data_path": "res://data/npc/npc_b.json",
			"memory_scene": "res://scenes/memory/npc2_li_lei_memory.tscn",
			"points": [&"AttendanceRecord", &"ComputerIdleTime", &"RentalContract"],
		},
		{
			"npc_id": &"npc_liu_guilan",
			"data_path": "res://data/npc/npc_c.json",
			"memory_scene": "res://scenes/memory/npc3_liu_guilan_memory.tscn",
			"points": [&"MedicalRecord", &"TreatmentBill", &"TreatmentBed"],
		},
		{
			"npc_id": &"npc_su_qing",
			"data_path": "res://data/npc/npc_d.json",
			"memory_scene": "res://scenes/memory/npc4_su_qing_memory.tscn",
			"points": [&"MeetingRecord", &"WorkDocuments", &"DaughterChatRecord"],
		},
		{
			"npc_id": &"npc_wang_jianguo",
			"data_path": "res://data/npc/npc_e.json",
			"memory_scene": "res://scenes/memory/npc5_wang_jianguo_memory.tscn",
			"points": [&"CommunitySupplies", &"DonationCertificates", &"CharityForumRecord"],
		},
	]


	func run() -> void:
		GameState.clear_runtime_state()
		var transition_layer = SceneRouter.get_node_or_null("TransitionLayer")
		assert(transition_layer != null)
		transition_layer.fade_duration = 0.05

		_validate_all_memory_scenes()
		await _validate_completed_memory_flow(CASES[0])
		await _validate_unfinished_back_flow(CASES[1])

		print("MEMORY_INTEGRATION_SMOKE_TEST: PASS")
		get_tree().quit(0)


	func _validate_all_memory_scenes() -> void:
		for test_case: Dictionary in CASES:
			var memory_scene_path := str(test_case["memory_scene"])
			assert(ResourceLoader.exists(memory_scene_path, "PackedScene"))
			var packed_scene := load(memory_scene_path) as PackedScene
			assert(packed_scene != null)
			var memory_scene := packed_scene.instantiate()
			assert(memory_scene != null)
			assert(memory_scene.get_node_or_null("%MemoryInfoPanel") != null)
			assert(memory_scene.get_node_or_null("%ProgressLabel") != null)
			assert(memory_scene.get_node_or_null("%CompleteButton") != null)
			assert(memory_scene.get_node_or_null("%BackButton") != null)
			for point_name: StringName in test_case["points"]:
				var point := memory_scene.get_node_or_null("%%%s" % point_name)
				assert(point != null)
				assert(point.get("observation_data") != null)
			memory_scene.free()


	func _validate_completed_memory_flow(test_case: Dictionary) -> void:
		await _enter_npc_base(test_case)
		var npc_base := get_tree().current_scene
		assert(npc_base.scene_file_path == NPC_BASE_SCENE_PATH)
		await _complete_npc_dialogue(npc_base)

		var memory_button := npc_base.get_node("%MemoryButton") as Button
		assert(memory_button.visible)
		assert(not memory_button.disabled)
		memory_button.pressed.emit()
		await _wait_for_navigation()

		var memory_scene := get_tree().current_scene
		assert(memory_scene.scene_file_path == test_case["memory_scene"])
		assert(StringName(memory_scene.get("npc_id")) == test_case["npc_id"])
		assert(str(memory_scene.get("return_npc_data_path")) == test_case["data_path"])
		assert(memory_scene.get("observed_points").size() == 3)

		for point_name: StringName in test_case["points"]:
			await _complete_observation(memory_scene, point_name)

		assert(bool(memory_scene.get("completion_status")))
		var complete_button := memory_scene.get_node("%CompleteButton") as Button
		assert(complete_button.visible)
		assert(not complete_button.disabled)
		complete_button.pressed.emit()
		await _wait_for_navigation()

		assert(get_tree().current_scene.scene_file_path == HOME_SCENE_PATH)
		var progress := GameState.get_npc_progress(test_case["npc_id"])
		assert(progress != null)
		assert(progress.memory_completed)


	func _validate_unfinished_back_flow(test_case: Dictionary) -> void:
		await _enter_npc_base(test_case)
		var npc_base := get_tree().current_scene
		await _complete_npc_dialogue(npc_base)
		var memory_button := npc_base.get_node("%MemoryButton") as Button
		memory_button.pressed.emit()
		await _wait_for_navigation()

		var memory_scene := get_tree().current_scene
		assert(memory_scene.scene_file_path == test_case["memory_scene"])
		var back_button := memory_scene.get_node("%BackButton") as Button
		assert(not back_button.disabled)
		back_button.pressed.emit()
		await _wait_for_navigation()

		var returned_npc_base := get_tree().current_scene
		assert(returned_npc_base.scene_file_path == NPC_BASE_SCENE_PATH)
		assert(str(returned_npc_base.get("npc_data_path")) == test_case["data_path"])
		var progress := GameState.get_npc_progress(test_case["npc_id"])
		assert(progress != null)
		assert(not progress.memory_completed)


	func _enter_npc_base(test_case: Dictionary) -> void:
		assert(SceneRouter.go_to(&"npc_base", {
			"npc_data_path": test_case["data_path"],
		}))
		await _wait_for_navigation()


	func _complete_npc_dialogue(npc_base: Node) -> void:
		var continue_button := npc_base.get_node("%ContinueButton") as Button
		var safety_count := 0
		while not continue_button.disabled:
			continue_button.pressed.emit()
			await get_tree().process_frame
			safety_count += 1
			assert(safety_count < 100)


	func _complete_observation(memory_scene: Node, point_name: StringName) -> void:
		var point := memory_scene.get_node("%%%s" % point_name)
		var observation_data = point.get("observation_data")
		point.emit_signal("observation_requested", observation_data)
		await get_tree().process_frame

		var info_panel := memory_scene.get_node("%MemoryInfoPanel") as Control
		assert(info_panel.visible)
		var continue_button := info_panel.get_node("Panel/ContinueButton") as Button
		var safety_count := 0
		while info_panel.visible:
			continue_button.pressed.emit()
			await get_tree().process_frame
			safety_count += 1
			assert(safety_count < 100)
		assert(bool(memory_scene.call("is_observed", observation_data.observation_id)))


	func _wait_for_navigation() -> void:
		for _frame in 300:
			if not SceneRouter.is_transitioning():
				await get_tree().process_frame
				return
			await get_tree().process_frame
		assert(false, "SceneRouter navigation timed out.")


func _ready() -> void:
	call_deferred("_start_probe")


func _start_probe() -> void:
	var probe := MemoryIntegrationProbe.new()
	get_tree().root.add_child(probe)
	probe.run()

