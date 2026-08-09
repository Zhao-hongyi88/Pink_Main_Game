extends Control

const NPC_ROSTER_PATH := "res://data/npc/npc_roster.json"
const NPC_ROSTER_SCRIPT = preload("res://scripts/npc/npc_roster.gd")

@onready var start_button: Button = %StartButton
@onready var rule_button: Button = %RuleButton
@onready var rule_panel: Control = %RulePanel
@onready var archive_panel: Control = %ArchivePanel

var npc_roster: RefCounted


func _ready() -> void:
	start_button.pressed.connect(_on_start_button_pressed)
	rule_button.pressed.connect(_on_rule_button_pressed)
	rule_panel.get_node("%CloseButton").pressed.connect(_on_rule_panel_close_pressed)
	_setup_archive()


func _on_start_button_pressed() -> void:
	_start_game()


func _start_game() -> void:
	if npc_roster == null or not GameState.is_npc_unlocked(GameState.selected_npc_id):
		push_error("MainMenu: no unlocked NPC is selected.")
		return
	var selected_data_path: String = npc_roster.get_data_path(GameState.selected_npc_id)
	if selected_data_path.is_empty():
		push_error("MainMenu: selected NPC has no NPCData path.")
		return
	SceneRouter.go_to(&"npc_base", {
		"npc_data_path": selected_data_path,
	})


func _setup_archive() -> void:
	npc_roster = NPC_ROSTER_SCRIPT.new()
	if not npc_roster.load_from_json(NPC_ROSTER_PATH):
		push_error("MainMenu: %s" % npc_roster.get_error_message())
		start_button.disabled = true
		return
	if not GameState.initialize_npc_access(npc_roster):
		push_error("MainMenu: failed to initialize NPC access state.")
		start_button.disabled = true
		return
	GameState.advance_from_completed_progress(npc_roster)
	if not archive_panel.setup(npc_roster):
		push_error("MainMenu: failed to initialize ArchivePanel.")
		start_button.disabled = true


func _on_rule_button_pressed() -> void:
	rule_panel.show()


func _on_rule_panel_close_pressed() -> void:
	rule_panel.hide()
