extends Control

@onready var complete_memory_button: Button = %CompleteMemoryButton
@onready var back_button: Button = %BackButton

var return_npc_data_path := ""
var current_npc_id: StringName = &""


func _ready() -> void:
	var payload := SceneRouter.take_payload()
	return_npc_data_path = str(payload.get("return_npc_data_path", "")).strip_edges()
	current_npc_id = StringName(str(payload.get("npc_id", "")).strip_edges())
	complete_memory_button.pressed.connect(_on_complete_memory_pressed)
	back_button.pressed.connect(_on_back_pressed)

	var has_return_context := not return_npc_data_path.is_empty() and not current_npc_id.is_empty()
	back_button.disabled = not has_return_context
	complete_memory_button.disabled = current_npc_id.is_empty()
	var progress := GameState.get_npc_progress(current_npc_id)
	if progress != null and progress.memory_completed:
		_show_memory_completed()


func _on_complete_memory_pressed() -> void:
	if current_npc_id.is_empty():
		return
	if GameState.mark_memory_completed(current_npc_id):
		_show_memory_completed()


func _show_memory_completed() -> void:
	complete_memory_button.text = "Memory Completed"
	complete_memory_button.disabled = true


func _on_back_pressed() -> void:
	if return_npc_data_path.is_empty() or current_npc_id.is_empty():
		push_error("MemoryTest: 缺少返回上下文，无法返回 NPCBase。")
		return
	SceneRouter.go_to(&"npc_base", {
		"npc_data_path": return_npc_data_path,
	})
