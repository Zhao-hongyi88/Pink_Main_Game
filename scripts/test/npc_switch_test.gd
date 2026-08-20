extends Control

const NPC_DATA_PATHS: Dictionary = {
	"NPC_A": "res://data/npc/npc_a.json",
	"NPC_B": "res://data/npc/npc_b.json",
	"NPC_C": "res://data/npc/npc_c.json",
	"NPC_D": "res://data/npc/npc_d.json",
	"NPC_E": "res://data/npc/npc_e.json",
}

@onready var npc_button_container: VBoxContainer = %NPCButtonContainer


func _ready() -> void:
	for child in npc_button_container.get_children():
		var button := child as Button
		if button == null:
			continue
		button.pressed.connect(_on_npc_button_pressed.bind(button.text))


func _on_npc_button_pressed(npc_label: String) -> void:
	var selected_data_path := str(NPC_DATA_PATHS.get(npc_label, ""))
	if selected_data_path.is_empty():
		push_error("NPCSwitchTest: No NPCData path is mapped for %s." % npc_label)
		return
	SceneRouter.go_to(&"npc_base", {
		"npc_data_path": selected_data_path,
	})
