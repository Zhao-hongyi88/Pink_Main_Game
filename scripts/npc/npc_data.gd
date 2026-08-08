class_name NPCData
extends RefCounted

## NPC 的只读数据模型。仅负责 JSON 读取、字段校验与规范化数据提供。

var npc_id: StringName = &""
var display_name := ""
var portrait := ""
var name_unlock_key: StringName = &""
var dialogues: Array[Dictionary] = []
var notes: Array[Dictionary] = []
var memory_scene := ""
var source_path := ""
var validation_errors: PackedStringArray = []


static func load_from_json(path: String) -> NPCData:
	var result := NPCData.new()
	result.source_path = path
	result._read_and_validate()
	return result


func is_valid() -> bool:
	return validation_errors.is_empty()


func get_error_message() -> String:
	return "; ".join(validation_errors)


func _read_and_validate() -> void:
	if source_path.is_empty():
		validation_errors.append("NPCData: 数据路径为空。")
		return
	if not FileAccess.file_exists(source_path):
		validation_errors.append("NPCData: 找不到数据文件：%s" % source_path)
		return

	var file := FileAccess.open(source_path, FileAccess.READ)
	if file == null:
		validation_errors.append("NPCData: 无法读取数据文件：%s" % source_path)
		return

	var json := JSON.new()
	var parse_result := json.parse(file.get_as_text())
	file.close()
	if parse_result != OK:
		validation_errors.append(
			"NPCData: JSON 解析失败（第 %d 行）：%s" % [json.get_error_line(), json.get_error_message()]
		)
		return
	if typeof(json.data) != TYPE_DICTIONARY:
		validation_errors.append("NPCData: JSON 根节点必须是 Dictionary。")
		return

	var raw: Dictionary = json.data
	npc_id = StringName(_read_required_string(raw, "npc_id"))
	display_name = _read_required_string(raw, "display_name")
	portrait = _read_required_string(raw, "portrait", true)
	name_unlock_key = StringName(_read_required_string(raw, "name_unlock_key", true))
	memory_scene = _read_required_string(raw, "memory_scene")
	_read_dialogues(raw)
	_read_notes(raw)
	_validate_resource_paths()
	_validate_unlock_references()


func _read_required_string(raw: Dictionary, field: String, allow_empty := false) -> String:
	if not raw.has(field):
		validation_errors.append("NPCData: 缺少字段 '%s'。" % field)
		return ""
	if typeof(raw[field]) != TYPE_STRING:
		validation_errors.append("NPCData: 字段 '%s' 必须是 String。" % field)
		return ""
	var value := str(raw[field]).strip_edges()
	if value.is_empty() and not allow_empty:
		validation_errors.append("NPCData: 字段 '%s' 不能为空。" % field)
	return value


func _read_dialogues(raw: Dictionary) -> void:
	if not raw.has("dialogues") or typeof(raw["dialogues"]) != TYPE_ARRAY:
		validation_errors.append("NPCData: 字段 'dialogues' 必须是 Array。")
		return

	var raw_dialogues: Array = raw["dialogues"]
	if raw_dialogues.is_empty():
		validation_errors.append("NPCData: 'dialogues' 至少需要一条对话。")
		return

	for index in raw_dialogues.size():
		var entry: Variant = raw_dialogues[index]
		if typeof(entry) != TYPE_DICTIONARY:
			validation_errors.append("NPCData: dialogues[%d] 必须是 Dictionary。" % index)
			continue
		var dialogue: Dictionary = entry
		if not dialogue.has("text") or typeof(dialogue["text"]) != TYPE_STRING:
			validation_errors.append("NPCData: dialogues[%d].text 必须是 String。" % index)
			continue
		if not dialogue.has("unlock_key") or typeof(dialogue["unlock_key"]) != TYPE_STRING:
			validation_errors.append("NPCData: dialogues[%d].unlock_key 必须是 String。" % index)
			continue
		var text := str(dialogue["text"]).strip_edges()
		if text.is_empty():
			validation_errors.append("NPCData: dialogues[%d].text 不能为空。" % index)
			continue
		dialogues.append({
			"text": text,
			"unlock_key": str(dialogue["unlock_key"]).strip_edges(),
		})


func _read_notes(raw: Dictionary) -> void:
	if not raw.has("notes") or typeof(raw["notes"]) != TYPE_ARRAY:
		validation_errors.append("NPCData: 字段 'notes' 必须是 Array。")
		return

	var known_keys: Dictionary = {}
	var raw_notes: Array = raw["notes"]
	for index in raw_notes.size():
		var entry: Variant = raw_notes[index]
		if typeof(entry) != TYPE_DICTIONARY:
			validation_errors.append("NPCData: notes[%d] 必须是 Dictionary。" % index)
			continue
		var note: Dictionary = entry
		var normalized_note := _normalize_note(note, index)
		if normalized_note.is_empty():
			continue
		var note_key: String = normalized_note["key"]
		if known_keys.has(note_key):
			validation_errors.append("NPCData: Note key 重复：%s" % note_key)
			continue
		known_keys[note_key] = true
		notes.append(normalized_note)


func _normalize_note(note: Dictionary, index: int) -> Dictionary:
	for field in ["key", "header", "content"]:
		if not note.has(field) or typeof(note[field]) != TYPE_STRING:
			validation_errors.append("NPCData: notes[%d].%s 必须是 String。" % [index, field])
			return {}
	var note_key := str(note["key"]).strip_edges()
	if note_key.is_empty():
		validation_errors.append("NPCData: notes[%d].key 不能为空。" % index)
		return {}
	return {
		"key": note_key,
		"header": str(note["header"]),
		"content": str(note["content"]),
	}


func _validate_resource_paths() -> void:
	if not portrait.is_empty() and not ResourceLoader.exists(portrait, "Texture2D"):
		validation_errors.append("NPCData: portrait 不是有效的 Texture2D 路径：%s" % portrait)
	if not memory_scene.is_empty() and not ResourceLoader.exists(memory_scene, "PackedScene"):
		validation_errors.append("NPCData: memory_scene 不是有效的场景路径：%s" % memory_scene)


func _validate_unlock_references() -> void:
	var note_keys: Dictionary = {}
	for note in notes:
		note_keys[note["key"]] = true
	if not name_unlock_key.is_empty() and not note_keys.has(String(name_unlock_key)):
		validation_errors.append("NPCData: name_unlock_key 没有对应的 Note：%s" % name_unlock_key)
	for index in dialogues.size():
		var unlock_key: String = dialogues[index]["unlock_key"]
		if not unlock_key.is_empty() and not note_keys.has(unlock_key):
			validation_errors.append(
				"NPCData: dialogues[%d].unlock_key 没有对应的 Note：%s" % [index, unlock_key]
			)
