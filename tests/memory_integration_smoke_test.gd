extends Node


class MemoryIntegrationProbe:
	extends Node

	const NPC_BASE_SCENE_PATH := "res://scenes/npc/npc_base.tscn"
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

		var point_names: Array = test_case["points"]
		await _validate_zhang_yuan_marker_and_dialogue_flow(memory_scene, point_names[0])
		for point_index in range(1, point_names.size()):
			await _complete_observation(memory_scene, point_names[point_index])

		assert(bool(memory_scene.get("completion_status")))
		var complete_button := memory_scene.get_node("%CompleteButton") as Button
		assert(complete_button.visible)
		assert(not complete_button.disabled)
		complete_button.pressed.emit()
		await _wait_for_navigation()

		assert(get_tree().current_scene.scene_file_path == NPC_BASE_SCENE_PATH)
		assert(str(get_tree().current_scene.get("npc_data_path")) == test_case["data_path"])
		var contract_book := get_tree().current_scene.get_node(
			"DossierPanel/TimeLoanContractButton"
		) as TextureButton
		assert(contract_book != null and contract_book.visible)
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
		if bool(npc_base.get("_awaiting_intro_reveal")):
			npc_base.call("_reveal_first_conversation")
			await _wait_for_dialogue_input(npc_base)
		var safety_count := 0
		while not bool(npc_base.get("dialogue_completed")):
			var detail_popup := npc_base.get_node("%NoteDetailPopup") as Control
			if detail_popup.visible:
				detail_popup.get_node("%CloseHitArea").pressed.emit()
				await get_tree().create_timer(0.35).timeout
				safety_count += 1
				assert(safety_count < 100)
				continue
			await _wait_for_dialogue_input(npc_base)
			assert(not continue_button.disabled)
			continue_button.pressed.emit()
			await get_tree().process_frame
			safety_count += 1
			assert(safety_count < 100)


	func _wait_for_dialogue_input(npc_base: Node) -> void:
		for _frame in 180:
			if not bool(npc_base.call("_is_dialogue_advance_blocked")):
				return
			await get_tree().process_frame
		assert(false, "NPCBase dialogue input did not unblock in time.")

	func _complete_observation(memory_scene: Node, point_name: StringName) -> void:
		var point := memory_scene.get_node("%%%s" % point_name)
		var observation_data = point.get("observation_data")
		var info_panel := memory_scene.get_node("%MemoryInfoPanel") as MemoryInfoPanel
		var completed_ids: Array[StringName] = []
		var record_completed := func(observation_id) -> void:
			completed_ids.append(StringName(observation_id))
		info_panel.observation_completed.connect(record_completed, CONNECT_ONE_SHOT)
		await _click_observation_point(point)

		assert(info_panel.visible)
		var object_panel := info_panel.get_node("Panel") as Control
		var dialogue_box := info_panel.get_node("DialogueBox") as Control
		var object_continue_button := object_panel.get_node("ContinueButton") as Button
		var dialogue_continue_button := dialogue_box.get_node("DialogueContinueButton") as Button
		var dialogue_content_label := dialogue_box.get_node("DialogueContentLabel") as Label
		assert(object_panel.visible)
		assert(not dialogue_box.visible)
		assert(info_panel.get_node("Panel/ContentLabel").text == observation_data.info)

		await _click_gui_button(object_continue_button)
		if not observation_data.dialogue.is_empty():
			assert(info_panel.visible)
			assert(not object_panel.visible)
			assert(dialogue_box.visible)
			var dialogue_index := 0
			while info_panel.visible:
				assert(dialogue_content_label.text == observation_data.dialogue[dialogue_index])
				await _click_gui_button(dialogue_continue_button)
				dialogue_index += 1
				assert(dialogue_index <= observation_data.dialogue.size())

		assert(not info_panel.visible)
		assert(completed_ids == [StringName(observation_data.observation_id)])
		assert(bool(memory_scene.call("is_observed", observation_data.observation_id)))


	func _validate_zhang_yuan_marker_and_dialogue_flow(
		memory_scene: Node,
		point_name: StringName
	) -> void:
		var point := memory_scene.get_node("%%%s" % point_name) as MemoryObservationPoint
		var observation_data = point.observation_data
		var marker := point.get_node("UnexploredMarker") as CanvasItem
		var info_panel := memory_scene.get_node("%MemoryInfoPanel") as MemoryInfoPanel
		var cancelled_count := [0]
		var record_cancelled := func() -> void:
			cancelled_count[0] += 1
		info_panel.observation_cancelled.connect(record_cancelled)

		# 未完成点打开后进入 DialogueBox，再使用真实 CloseButton 取消，Marker 必须恢复。
		assert(marker.visible)
		await _click_observation_point(point)
		assert(info_panel.visible)
		assert(info_panel.get_node("Panel").visible)
		assert(not info_panel.get_node("DialogueBox").visible)
		await _click_gui_button(info_panel.get_node("Panel/ContinueButton") as Button)
		var dialogue_box := info_panel.get_node("DialogueBox") as Control
		assert(dialogue_box.visible)
		var dialogue_label := dialogue_box.get_node("DialogueContentLabel") as Label
		assert(dialogue_label.text == observation_data.dialogue[0])
		if observation_data.dialogue.size() > 1:
			await _click_gui_button(
				dialogue_box.get_node("DialogueContinueButton") as Button
			)
			assert(dialogue_label.text == observation_data.dialogue[1])
		await _click_gui_button(dialogue_box.get_node("DialogueCloseButton") as Button)
		assert(not info_panel.visible)
		assert(cancelled_count[0] == 1)
		assert(not memory_scene.is_observed(observation_data.observation_id))
		assert(marker.visible)

		# 正常完成后 Marker 消失，observation_completed 由真实 DialogueContinueButton 触发。
		await _complete_observation(memory_scene, point_name)
		assert(memory_scene.is_observed(observation_data.observation_id))
		assert(not marker.visible)

		# 已完成点重新打开后使用 DialogueCloseButton，Marker 仍必须保持隐藏。
		await _click_observation_point(point)
		await _click_gui_button(info_panel.get_node("Panel/ContinueButton") as Button)
		assert(dialogue_box.visible)
		await _click_gui_button(dialogue_box.get_node("DialogueCloseButton") as Button)
		assert(not info_panel.visible)
		assert(cancelled_count[0] == 2)
		assert(not marker.visible)

		# 已完成点再次打开后使用 ESC，仍不能恢复“未探索”标记。
		await _click_observation_point(point)
		assert(info_panel.visible)
		await _press_escape()
		assert(not info_panel.visible)
		assert(cancelled_count[0] == 3)
		assert(not marker.visible)
		info_panel.observation_cancelled.disconnect(record_cancelled)


	func _click_gui_button(button: Button) -> void:
		assert(button != null)
		assert(button.is_visible_in_tree())
		assert(not button.disabled)
		var click_position := button.get_global_rect().get_center()
		button.set_meta(&"memory_smoke_button_down", false)
		button.button_down.connect(
			func() -> void: button.set_meta(&"memory_smoke_button_down", true),
			CONNECT_ONE_SHOT
		)

		var motion := InputEventMouseMotion.new()
		motion.position = click_position
		motion.global_position = click_position
		get_viewport().push_input(motion, true)
		await get_tree().process_frame

		var press := InputEventMouseButton.new()
		press.button_index = MOUSE_BUTTON_LEFT
		press.button_mask = MOUSE_BUTTON_MASK_LEFT
		press.pressed = true
		press.position = click_position
		press.global_position = click_position
		get_viewport().push_input(press, true)
		await get_tree().process_frame
		assert(button.get_meta(&"memory_smoke_button_down", false))

		var release := InputEventMouseButton.new()
		release.button_index = MOUSE_BUTTON_LEFT
		release.button_mask = 0
		release.pressed = false
		release.position = click_position
		release.global_position = click_position
		get_viewport().push_input(release, true)
		await get_tree().process_frame


	func _click_observation_point(point: MemoryObservationPoint) -> void:
		assert(point != null)
		assert(point.is_visible_in_tree())
		var click_position := point.global_position
		point.set_meta(&"memory_smoke_point_opened", false)
		point.observation_requested.connect(
			func(_data) -> void: point.set_meta(&"memory_smoke_point_opened", true),
			CONNECT_ONE_SHOT
		)

		var motion := InputEventMouseMotion.new()
		motion.position = click_position
		motion.global_position = click_position
		get_viewport().push_input(motion, true)
		await get_tree().physics_frame

		var press := InputEventMouseButton.new()
		press.button_index = MOUSE_BUTTON_LEFT
		press.button_mask = MOUSE_BUTTON_MASK_LEFT
		press.pressed = true
		press.position = click_position
		press.global_position = click_position
		get_viewport().push_input(press, true)
		await get_tree().physics_frame
		await get_tree().process_frame
		assert(point.get_meta(&"memory_smoke_point_opened", false))

		var release := InputEventMouseButton.new()
		release.button_index = MOUSE_BUTTON_LEFT
		release.button_mask = 0
		release.pressed = false
		release.position = click_position
		release.global_position = click_position
		get_viewport().push_input(release, true)
		await get_tree().physics_frame
		await get_tree().process_frame


	func _press_escape() -> void:
		var escape_press := InputEventAction.new()
		escape_press.action = &"ui_cancel"
		escape_press.pressed = true
		escape_press.strength = 1.0
		get_viewport().push_input(escape_press, true)
		await get_tree().process_frame

		var escape_release := InputEventAction.new()
		escape_release.action = &"ui_cancel"
		escape_release.pressed = false
		get_viewport().push_input(escape_release, true)
		await get_tree().process_frame


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
