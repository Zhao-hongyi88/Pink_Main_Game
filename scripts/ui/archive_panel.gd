class_name ArchivePanel
extends Control

@onready var archive_button: Button = %ArchiveButton
@onready var selected_npc_label: Label = %SelectedNPCLabel
@onready var selection_panel: PanelContainer = %SelectionPanel
@onready var npc_button_container: VBoxContainer = %NPCButtonContainer
@onready var close_button: Button = %CloseButton

var roster: RefCounted
var _buttons_by_id: Dictionary = {}


func _ready() -> void:
	archive_button.pressed.connect(_on_archive_button_pressed)
	close_button.pressed.connect(_on_close_button_pressed)
	selection_panel.hide()


func setup(roster_data: RefCounted) -> bool:
	if roster_data == null or not roster_data.is_valid():
		return false
	roster = roster_data
	_build_npc_buttons()
	refresh()
	return true


func refresh() -> void:
	if roster == null:
		selected_npc_label.text = "SELECTED: NONE"
		return

	var selected_name: String = roster.get_display_name(GameState.selected_npc_id)
	selected_npc_label.text = "SELECTED: %s" % (selected_name if not selected_name.is_empty() else "NONE")
	for entry: Dictionary in roster.get_entries():
		var npc_id: StringName = entry["npc_id"]
		var button: Button = _buttons_by_id[npc_id]
		var unlocked := GameState.is_npc_unlocked(npc_id)
		button.disabled = not unlocked
		button.text = str(entry["display_name"]) if unlocked else "%s - Locked" % entry["display_name"]


func get_npc_button(npc_id: StringName) -> Button:
	if not _buttons_by_id.has(npc_id):
		return null
	return _buttons_by_id[npc_id]


func get_npc_button_count() -> int:
	return _buttons_by_id.size()


func _build_npc_buttons() -> void:
	for child in npc_button_container.get_children():
		npc_button_container.remove_child(child)
		child.free()
	_buttons_by_id.clear()

	for entry: Dictionary in roster.get_entries():
		var npc_id: StringName = entry["npc_id"]
		var button := Button.new()
		button.name = "NPCOption_%s" % String(npc_id)
		button.custom_minimum_size = Vector2(0, 42)
		button.pressed.connect(_on_npc_button_pressed.bind(npc_id))
		npc_button_container.add_child(button)
		_buttons_by_id[npc_id] = button


func _on_archive_button_pressed() -> void:
	refresh()
	selection_panel.show()


func _on_close_button_pressed() -> void:
	selection_panel.hide()


func _on_npc_button_pressed(npc_id: StringName) -> void:
	if not GameState.select_npc(npc_id):
		return
	refresh()
	selection_panel.hide()
