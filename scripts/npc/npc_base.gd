class_name NPCBase
extends Control

## 公共 NPC 页面。静态内容来自 NPCData，运行时状态来自 GameState 中的 NPCProgress。

const NOTE_ITEM_SCENE: PackedScene = preload("res://scenes/ui/npc/note_card.tscn")

@export_file("*.json") var npc_data_path := ""
@export_group("Note Entry Animation")
@export_range(0.1, 1.0, 0.01) var note_entry_duration := 0.36
@export var note_entry_offset := Vector2(18.0, -14.0)
@export var note_entry_start_scale := Vector2(0.88, 0.88)
@export_range(0.0, 20.0, 0.5) var note_entry_rotation_degrees := 4.0

@onready var character_area: TextureRect = %CharacterArea
@onready var npc_name: Label = %NPCName
@onready var identity_label: Label = %IdentityLabel
@onready var dialogue_panel: Control = %DialoguePanel
@onready var speaker_name: Label = %SpeakerName
@onready var dialogue_text: Label = %DialogueText
@onready var continue_button: Button = %ContinueButton
@onready var note_panel: Control = %NotePanel
@onready var note_board_area: Control = %NoteBoardArea
@onready var note_detail_popup: Control = %NoteDetailPopup
@onready var memory_button: Button = %MemoryButton
@onready var _note_anchors: Array[Control] = [
	%NoteAnchor_01,
	%NoteAnchor_02,
	%NoteAnchor_03,
	%NoteAnchor_04,
	%NoteAnchor_05,
	%NoteAnchor_06,
]

var npc_data: NPCData
var npc_progress: NPCProgress
var dialogue_manager: DialogueManager
var unlock_system: UnlockSystem
var npc_id: StringName = &""
var memory_scene_path := ""

# 兼容页面现有公开状态名，但唯一数据源是 NPCProgress。
var current_dialogue_index: int:
	get:
		return npc_progress.current_dialogue_index if npc_progress != null else 0

var dialogue_completed: bool:
	get:
		return npc_progress.dialogue_completed if npc_progress != null else false

var unlocked_keys: Dictionary:
	get:
		return npc_progress.unlocked_keys if npc_progress != null else {}

var revealed_note_count: int:
	get:
		return npc_progress.revealed_note_keys.size() if npc_progress != null else 0

var memory_ready: bool:
	get:
		return npc_progress.memory_ready if npc_progress != null else false

var memory_completed: bool:
	get:
		return npc_progress.memory_completed if npc_progress != null else false

var _name_unlock_key: StringName = &""
var _note_data: Array[Dictionary] = []
var _valid_unlock_keys: Array[String] = []
var _note_items: Array[NoteItem] = []
var _note_items_by_key: Dictionary = {}
var _note_entry_tweens: Dictionary = {}


func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)
	memory_button.pressed.connect(_on_memory_pressed)
	_consume_navigation_payload()
	if not _load_npc_data(npc_data_path):
		_show_load_error()
		return
	_extract_valid_unlock_keys()
	_build_note_items()
	if not _bind_npc_progress():
		_show_load_error()
		return
	if not _setup_unlock_system():
		_show_load_error()
		return
	if not _setup_dialogue_manager():
		_show_load_error()
		return
	_restore_page_state()


func _consume_navigation_payload() -> void:
	var payload := SceneRouter.take_payload()
	var payload_data_path := str(payload.get("npc_data_path", "")).strip_edges()
	if not payload_data_path.is_empty():
		npc_data_path = payload_data_path


func _load_npc_data(path: String) -> bool:
	if path.is_empty():
		push_error("NPCBase: 没有传入 npc_data_path。")
		return false

	var loaded_data := NPCData.load_from_json(path)
	if not loaded_data.is_valid():
		push_error("NPCBase: %s" % loaded_data.get_error_message())
		return false

	npc_data = loaded_data
	npc_id = npc_data.npc_id
	npc_name.text = npc_data.display_name
	_name_unlock_key = npc_data.name_unlock_key
	memory_scene_path = npc_data.memory_scene
	_note_data = npc_data.notes.duplicate(true)
	identity_label.text = _get_identity_display_text()
	speaker_name.text = "UNKNOWN"
	return _apply_portrait(npc_data.portrait)


func _get_identity_display_text() -> String:
	for note: Dictionary in _note_data:
		if StringName(str(note.get("key", "")).strip_edges()) != _name_unlock_key:
			continue
		var header := str(note.get("header", "")).strip_edges()
		var content := str(note.get("content", "")).strip_edges()
		if header.is_empty():
			return content
		if content.is_empty():
			return header
		return "%s · %s" % [header, content]
	return npc_data.display_name


func _apply_portrait(portrait_path: String) -> bool:
	if portrait_path.is_empty():
		return true
	var portrait_resource := load(portrait_path)
	if not portrait_resource is Texture2D:
		push_error("NPCBase: portrait 无法作为 Texture2D 加载：%s" % portrait_path)
		return false
	character_area.texture = portrait_resource
	return true


func _bind_npc_progress() -> bool:
	npc_progress = GameState.get_or_create_npc_progress(npc_data.npc_id)
	return npc_progress != null


func _setup_unlock_system() -> bool:
	unlock_system = UnlockSystem.new()
	return unlock_system.setup(_valid_unlock_keys, npc_progress)


func _setup_dialogue_manager() -> bool:
	dialogue_manager = DialogueManager.new()
	return dialogue_manager.setup(npc_data.dialogues, npc_progress)


func _extract_valid_unlock_keys() -> void:
	_valid_unlock_keys.clear()
	for note: Dictionary in _note_data:
		var note_key := str(note.get("key", "")).strip_edges()
		if note_key.is_empty() or _valid_unlock_keys.has(note_key):
			continue
		_valid_unlock_keys.append(note_key)


func _build_note_items() -> void:
	_note_items.clear()
	_note_items_by_key.clear()
	for note: Dictionary in _note_data:
		var note_key := str(note.get("key", "")).strip_edges()
		if note_key.is_empty():
			push_warning("NPCBase: 忽略没有 key 的 Note。")
			continue
		if _note_items_by_key.has(note_key):
			push_warning("NPCBase: 忽略重复的 Note key：%s" % note_key)
			continue
		var note_item: NoteItem = NOTE_ITEM_SCENE.instantiate()
		note_item.setup(
			str(note.get("header", "")),
			str(note.get("content", "")),
			note_key
		)
		note_item.note_selected.connect(_on_note_selected)
		note_item.hide()
		note_board_area.add_child(note_item)
		_note_items.append(note_item)
		_note_items_by_key[note_key] = note_item


func _restore_page_state() -> void:
	character_area.show()
	dialogue_panel.show()
	npc_name.hide()
	identity_label.hide()
	speaker_name.text = "UNKNOWN"
	note_panel.hide()
	note_detail_popup.hide()
	for note_item in _note_items:
		_cancel_note_entry_tween(note_item.note_key)
		_set_note_final_visual(note_item)
		note_item.hide()

	_restore_revealed_notes()
	_refresh_dialogue_ui()


func _restore_revealed_notes() -> void:
	var displayed_keys: Dictionary = {}
	var displayed_count := 0
	for note_key in npc_progress.revealed_note_keys:
		var normalized_key := note_key.strip_edges()
		if normalized_key.is_empty():
			push_warning("NPCBase: 跳过空的历史 revealed_note_key。")
			continue
		if displayed_keys.has(normalized_key):
			push_warning("NPCBase: 跳过重复的历史 revealed_note_key：%s" % normalized_key)
			continue
		if not bool(npc_progress.unlocked_keys.get(normalized_key, false)):
			push_warning("NPCBase: 历史资料 key 未处于解锁状态，跳过 UI：%s" % normalized_key)
			continue
		if not _note_items_by_key.has(normalized_key):
			push_warning("NPCBase: 合法历史 key 没有对应 NoteItem，跳过 UI：%s" % normalized_key)
			continue
		_show_note_item(normalized_key, displayed_count)
		displayed_count += 1
		displayed_keys[normalized_key] = true

	if displayed_count > 0:
		note_panel.show()
	if not _name_unlock_key.is_empty() and bool(
		npc_progress.unlocked_keys.get(String(_name_unlock_key), false)
	):
		_show_identity_info()


func _show_identity_info() -> void:
	npc_name.show()
	identity_label.show()
	speaker_name.text = npc_data.display_name


func _show_note_item(note_key: String, order_index: int, animate_entry := false) -> void:
	var note_item: NoteItem = _note_items_by_key[note_key]
	if order_index < 0 or order_index >= _note_anchors.size():
		_cancel_note_entry_tween(note_key)
		note_item.hide()
		push_warning("NPCBase: 资料板锚点不足，暂不显示资料：%s" % note_key)
		return
	var target_anchor := _note_anchors[order_index]
	if note_item.get_parent() != target_anchor:
		note_item.reparent(target_anchor, false)
	note_item.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	note_item.show()
	note_item.pivot_offset = note_item.size * 0.5
	if animate_entry:
		_play_note_entry_animation(note_key, note_item)
	else:
		_cancel_note_entry_tween(note_key)
		_set_note_final_visual(note_item)


func _play_note_entry_animation(note_key: String, note_item: NoteItem) -> void:
	_cancel_note_entry_tween(note_key)
	var final_position := Vector2.ZERO
	var final_rotation := 0.0
	note_item.position = final_position + note_entry_offset
	note_item.scale = note_entry_start_scale
	note_item.rotation = final_rotation - deg_to_rad(note_entry_rotation_degrees)
	note_item.modulate.a = 0.0
	note_item.disabled = true

	var entry_tween := create_tween()
	entry_tween.set_parallel(true)
	entry_tween.set_trans(Tween.TRANS_SINE)
	entry_tween.set_ease(Tween.EASE_OUT)
	entry_tween.tween_property(note_item, "position", final_position, note_entry_duration)
	entry_tween.tween_property(note_item, "scale", Vector2.ONE, note_entry_duration)
	entry_tween.tween_property(note_item, "rotation", final_rotation, note_entry_duration)
	entry_tween.tween_property(note_item, "modulate:a", 1.0, note_entry_duration)
	_note_entry_tweens[note_key] = entry_tween
	entry_tween.finished.connect(
		_on_note_entry_animation_finished.bind(note_key, note_item, entry_tween)
	)


func _on_note_entry_animation_finished(
	note_key: String,
	note_item: NoteItem,
	entry_tween: Tween
) -> void:
	if _note_entry_tweens.get(note_key) != entry_tween:
		return
	_note_entry_tweens.erase(note_key)
	if is_instance_valid(note_item):
		_set_note_final_visual(note_item)


func _cancel_note_entry_tween(note_key: String) -> void:
	var entry_tween: Tween = _note_entry_tweens.get(note_key)
	if entry_tween != null and entry_tween.is_valid():
		entry_tween.kill()
	_note_entry_tweens.erase(note_key)


func _set_note_final_visual(note_item: NoteItem) -> void:
	note_item.position = Vector2.ZERO
	note_item.scale = Vector2.ONE
	note_item.rotation = 0.0
	note_item.modulate.a = 1.0
	note_item.disabled = false


func _on_note_selected(note_key: String, header: String, content: String) -> void:
	if npc_progress == null or not bool(npc_progress.unlocked_keys.get(note_key, false)):
		return
	note_detail_popup.call("open_note", note_key, header, content)


func _on_continue_pressed() -> void:
	var result := dialogue_manager.advance()
	if not bool(result.get("accepted", false)):
		_refresh_dialogue_ui()
		return
	var unlock_key := str(result.get("unlock_key", ""))
	if not unlock_key.is_empty():
		unlock_info(unlock_key)
	_refresh_dialogue_ui(bool(result.get("dialogue_completed", false)))


func unlock_info(unlock_key: String) -> bool:
	var result := unlock_system.request_unlock(unlock_key)
	if not bool(result.get("newly_unlocked", false)):
		return false

	var unlocked_key := str(result.get("key", ""))
	if _note_items_by_key.has(unlocked_key):
		_show_note_item(unlocked_key, _get_note_ui_order_index(unlocked_key), true)
		note_panel.show()
	else:
		push_warning("NPCBase: 合法 key 没有对应 NoteItem，跳过 UI：%s" % unlocked_key)
	if StringName(unlocked_key) == _name_unlock_key:
		_show_identity_info()
	return true


func _get_note_ui_order_index(target_key: String) -> int:
	var order_index := 0
	for note_key in npc_progress.revealed_note_keys:
		if note_key == target_key:
			break
		if bool(npc_progress.unlocked_keys.get(note_key, false)) and _note_items_by_key.has(note_key):
			order_index += 1
	return order_index


func _refresh_dialogue_ui(grab_memory_focus := false) -> void:
	# 当前阶段 memory_ready 与 dialogue_completed 保持严格同步。
	npc_progress.memory_ready = npc_progress.dialogue_completed
	dialogue_text.text = dialogue_manager.get_current_text()
	continue_button.disabled = npc_progress.dialogue_completed
	memory_button.hide()
	memory_button.disabled = true
	if npc_progress.memory_ready:
		memory_button.show()
		memory_button.disabled = false
		if grab_memory_focus:
			memory_button.grab_focus()


func _on_memory_pressed() -> void:
	if not memory_ready:
		return
	SceneRouter.go_to_scene(memory_scene_path, {
		"return_npc_data_path": npc_data_path,
		"npc_id": String(npc_data.npc_id),
	})


func _show_load_error() -> void:
	npc_name.text = "NPC DATA ERROR"
	npc_name.hide()
	identity_label.hide()
	speaker_name.text = "UNKNOWN"
	dialogue_text.text = "无法读取 NPC 数据。"
	continue_button.disabled = true
	note_panel.hide()
	note_detail_popup.hide()
	memory_button.hide()
	memory_button.disabled = true
