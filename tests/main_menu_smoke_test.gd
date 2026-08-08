extends Node

## Main Menu 模块、倒计时与目标场景冒烟测试。

const NPC_DATA_PATH := "res://data/npc/npc_a.json"


class StartNavigationProbe:
	extends Node

	var expected_data_path := ""


	func _ready() -> void:
		call_deferred("_verify_navigation")


	func _verify_navigation() -> void:
		await get_tree().process_frame
		await get_tree().process_frame
		var npc_base := get_tree().current_scene
		assert(npc_base is NPCBase)
		assert(npc_base.npc_data_path == expected_data_path)
		assert(npc_base.npc_data.source_path == expected_data_path)
		assert(npc_base.npc_data.npc_id == &"npc_a")
		assert(npc_base.npc_name.text == "NPC_A")
		print("MAIN_MENU_SMOKE_TEST: PASS")
		get_tree().quit(0)


func _ready() -> void:
	assert(ResourceLoader.exists(SceneRouter.ROUTES[&"lobby"]))
	assert(SceneRouter.ROUTES[&"npc_base"] == "res://scenes/npc/npc_base.tscn")
	var lobby_scene: PackedScene = load(SceneRouter.ROUTES[&"lobby"])
	var lobby := lobby_scene.instantiate()
	assert(lobby is Control)
	assert(lobby.get_child_count() == 1)
	assert(lobby.get_child(0) is Label)
	assert(lobby.get_child(0).text == "Lobby Test")
	lobby.free()

	var menu_scene: PackedScene = load("res://scenes/main/main_menu.tscn")
	var menu := menu_scene.instantiate()
	add_child(menu)
	await get_tree().process_frame
	assert(menu is Control)
	var direct_child_names := PackedStringArray()
	for child in menu.get_children():
		direct_child_names.append(child.name)
	assert(direct_child_names == PackedStringArray([
		"BackgroundPlaceholder",
		"RuleButton",
		"TimeDisplay",
		"StartButton",
		"RulePanel",
	]))

	var countdown: TimeDisplay = menu.get_node("%TimeDisplay")
	assert(countdown is Control)
	var time_child_names := PackedStringArray()
	for child in countdown.get_children():
		time_child_names.append(child.name)
	assert(time_child_names == PackedStringArray(["Background", "TimeTitle", "TimeValue"]))
	assert(countdown.get_child(0) is TextureRect)
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

	var start_button: Button = menu.get_node("%StartButton")
	assert(start_button.pressed.get_connections().size() == 1)
	assert(menu.has_method("_start_game"))
	assert(menu.INITIAL_NPC_DATA_PATH == NPC_DATA_PATH)

	# 真实执行 START，确认 payload 让公共 NPCBase 加载 npc_a.json。
	var navigation_probe := StartNavigationProbe.new()
	navigation_probe.expected_data_path = NPC_DATA_PATH
	get_tree().root.add_child(navigation_probe)
	start_button.pressed.emit()
