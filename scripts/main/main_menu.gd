extends Control

const INITIAL_NPC_DATA_PATH := "res://data/npc/npc_a.json"

@onready var start_button: Button = %StartButton
@onready var rule_button: Button = %RuleButton
@onready var rule_panel: Control = %RulePanel


func _ready() -> void:
	start_button.pressed.connect(_on_start_button_pressed)
	rule_button.pressed.connect(_on_rule_button_pressed)
	rule_panel.get_node("%CloseButton").pressed.connect(_on_rule_panel_close_pressed)


func _on_start_button_pressed() -> void:
	_start_game()


func _start_game() -> void:
	SceneRouter.go_to(&"npc_base", {
		"npc_data_path": INITIAL_NPC_DATA_PATH,
	})


func _on_rule_button_pressed() -> void:
	rule_panel.show()


func _on_rule_panel_close_pressed() -> void:
	rule_panel.hide()
