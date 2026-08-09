class_name NPCBase
extends Control

## 公共 NPC 页面。静态内容来自 NPCData，运行时状态来自 GameState 中的 NPCProgress。

const NOTE_ITEM_SCENE: PackedScene = preload("res://scenes/ui/npc/note_card.tscn")

@export_file("*.json") var npc_data_path := ""

@onready var character_area: TextureRect = %CharacterArea
@onready var npc_name: Label = %NPCName
@onready var identity_label: Label = %IdentityLabel
@onready var dialogue_panel: Control = %DialoguePanel
@onready var speaker_name: Label = %SpeakerName
@onready var dialogue_text: Label = %DialogueText
@onready var continue_button: Button = %ContinueButton
@onready var note_panel: Control = %NotePanel
@onready var note_container: VBoxContainer = %NoteContainer
@onready var memory_button: Button = %MemoryButton

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
		note_item.setup(str(note.get("header", "")), str(note.get("content", "")))
		note_item.hide()
		note_container.add_child(note_item)
		_note_items.append(note_item)
		_note_items_by_key[note_key] = note_item


func _restore_page_state() -> void:
	character_area.show()
	dialogue_panel.show()
	npc_name.hide()
	identity_label.hide()
	speaker_name.text = "UNKNOWN"
	note_panel.hide()
	for note_item in _note_items:
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


func _show_note_item(note_key: String, order_index: int) -> void:
	var note_item: NoteItem = _note_items_by_key[note_key]
	note_container.move_child(note_item, order_index)
	note_item.show()


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
		_show_note_item(unlocked_key, _get_note_ui_order_index(unlocked_key))
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
	memory_button.hide()
	memory_button.disabled = true
