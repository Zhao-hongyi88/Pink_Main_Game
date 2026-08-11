class_name ArchivePanel
extends Control

@onready var archive_button: Button = %ArchiveButton
@onready var selected_npc_label: Label = %SelectedNPCLabel
@onready var selection_panel: PanelContainer = %SelectionPanel
@onready var npc_button_container: VBoxContainer = %NPCButtonContainer
@onready var close_button: Button = %CloseButton

var roster: RefCounted
var _buttons_by_id: Dictionary = {}
var _selection_tween: Tween
var _selection_should_be_open := false
var _selection_animation_id := 0

const SELECTION_OPEN_SCALE := Vector2(0.96, 0.96)
const SELECTION_OPEN_DURATION := 0.3
const SELECTION_CLOSE_DURATION := 0.25
const UNKNOWN_NPC_NAME := "???"

var _name_unlock_keys_by_id: Dictionary = {}


func _ready() -> void:
	archive_button.pressed.connect(_on_archive_button_pressed)
	close_button.pressed.connect(_on_close_button_pressed)
	selection_panel.hide()


func setup(roster_data: RefCounted) -> bool:
	if roster_data == null or not roster_data.is_valid():
		return false
	roster = roster_data
	if not _cache_name_unlock_keys():
		return false
	_build_npc_buttons()
	refresh()
	return true


func refresh() -> void:
	if roster == null:
		selected_npc_label.text = UNKNOWN_NPC_NAME
		return

	selected_npc_label.text = _get_visible_npc_name(GameState.selected_npc_id)
	for entry: Dictionary in roster.get_entries():
		var npc_id: StringName = entry["npc_id"]
		var button: Button = _buttons_by_id[npc_id]
		var unlocked := GameState.is_npc_unlocked(npc_id)
		button.disabled = not unlocked
		button.text = (
			_get_visible_npc_name(npc_id)
			if unlocked
			else "%s - Locked" % UNKNOWN_NPC_NAME
		)


func _cache_name_unlock_keys() -> bool:
	_name_unlock_keys_by_id.clear()
	for entry: Dictionary in roster.get_entries():
		var npc_id: StringName = entry["npc_id"]
		var npc_data := NPCData.load_from_json(str(entry["data_path"]))
		if not npc_data.is_valid() or npc_data.npc_id != npc_id:
			push_error("ArchivePanel: invalid NPCData for %s." % npc_id)
			_name_unlock_keys_by_id.clear()
			return false
		_name_unlock_keys_by_id[npc_id] = npc_data.name_unlock_key
	return true


func _get_visible_npc_name(npc_id: StringName) -> String:
	if roster == null or npc_id.is_empty():
		return UNKNOWN_NPC_NAME
	var name_unlock_key := StringName(_name_unlock_keys_by_id.get(npc_id, &""))
	if name_unlock_key.is_empty():
		return UNKNOWN_NPC_NAME
	var progress := GameState.get_npc_progress(npc_id)
	if progress == null or not bool(progress.unlocked_keys.get(String(name_unlock_key), false)):
		return UNKNOWN_NPC_NAME
	var display_name: String = roster.get_display_name(npc_id)
	return display_name if not display_name.is_empty() else UNKNOWN_NPC_NAME


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
	_open_selection_panel()


func _on_close_button_pressed() -> void:
	_close_selection_panel()


func _on_npc_button_pressed(npc_id: StringName) -> void:
	if not GameState.select_npc(npc_id):
		return
	refresh()
	_close_selection_panel()


func _open_selection_panel() -> void:
	_selection_should_be_open = true
	_selection_animation_id += 1
	_kill_selection_tween()
	selection_panel.pivot_offset = selection_panel.size / 2.0

	if not selection_panel.visible:
		selection_panel.modulate.a = 0.0
		selection_panel.scale = SELECTION_OPEN_SCALE
		selection_panel.show()

	_selection_tween = create_tween().set_parallel(true)
	_selection_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_selection_tween.tween_property(selection_panel, "modulate:a", 1.0, SELECTION_OPEN_DURATION)
	_selection_tween.tween_property(selection_panel, "scale", Vector2.ONE, SELECTION_OPEN_DURATION)


func _close_selection_panel() -> void:
	if not selection_panel.visible:
		_selection_should_be_open = false
		return

	_selection_should_be_open = false
	_selection_animation_id += 1
	var animation_id := _selection_animation_id
	_kill_selection_tween()
	selection_panel.pivot_offset = selection_panel.size / 2.0

	_selection_tween = create_tween().set_parallel(true)
	_selection_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_selection_tween.tween_property(selection_panel, "modulate:a", 0.0, SELECTION_CLOSE_DURATION)
	_selection_tween.tween_property(selection_panel, "scale", SELECTION_OPEN_SCALE, SELECTION_CLOSE_DURATION)
	_selection_tween.chain().tween_callback(_finish_selection_close.bind(animation_id))


func _finish_selection_close(animation_id: int) -> void:
	if animation_id != _selection_animation_id or _selection_should_be_open:
		return
	selection_panel.hide()
	_selection_tween = null


func _kill_selection_tween() -> void:
	if _selection_tween != null and _selection_tween.is_valid():
		_selection_tween.kill()
	_selection_tween = null
