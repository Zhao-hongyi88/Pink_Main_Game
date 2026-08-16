class_name NPCData
extends RefCounted

## NPC 的只读数据模型。仅负责 JSON 读取、字段校验与规范化数据提供。

var npc_id: StringName = &""
var display_name := ""
var dialogue_name := ""
var profile_photo := ""
var initial_background := ""
var dialogue_complete_on_end := true
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
	dialogue_name = _read_optional_string(raw, "dialogue_name", display_name)
	profile_photo = _read_optional_string(raw, "profile_photo", "")
	initial_background = _read_optional_string(raw, "initial_background", "")
	dialogue_complete_on_end = _read_optional_bool(raw, "dialogue_complete_on_end", true)
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


func _read_optional_string(raw: Dictionary, field: String, fallback: String) -> String:
	if not raw.has(field):
		return fallback
	if typeof(raw[field]) != TYPE_STRING:
		validation_errors.append("NPCData: 字段 '%s' 必须是 String。" % field)
		return fallback
	var value := str(raw[field]).strip_edges()
	return value if not value.is_empty() else fallback


func _read_optional_bool(raw: Dictionary, field: String, fallback: bool) -> bool:
	if not raw.has(field):
		return fallback
	if typeof(raw[field]) != TYPE_BOOL:
		validation_errors.append("NPCData: 字段 '%s' 必须是 bool。" % field)
		return fallback
	return bool(raw[field])


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
		var optional_string_fields := [
			"background",
			"speaker_name",
			"speaker_role",
			"open_note_key",
			"after_note_background",
		]
		var optional_fields_valid := true
		for field: String in optional_string_fields:
			if dialogue.has(field) and typeof(dialogue[field]) != TYPE_STRING:
				validation_errors.append(
					"NPCData: dialogues[%d].%s 必须是 String。" % [index, field]
				)
				optional_fields_valid = false
		if (
			dialogue.has("complete_on_note_close")
			and typeof(dialogue["complete_on_note_close"]) != TYPE_BOOL
		):
			validation_errors.append(
				"NPCData: dialogues[%d].complete_on_note_close 必须是 bool。" % index
			)
			optional_fields_valid = false
		if not optional_fields_valid:
			continue
		var text := str(dialogue["text"]).strip_edges()
		if text.is_empty():
			validation_errors.append("NPCData: dialogues[%d].text 不能为空。" % index)
			continue
		var normalized_dialogue := {
			"text": text,
			"unlock_key": str(dialogue["unlock_key"]).strip_edges(),
		}
		var background_path := str(dialogue.get("background", "")).strip_edges()
		if not background_path.is_empty():
			normalized_dialogue["background"] = background_path
		var dialogue_speaker_name := str(dialogue.get("speaker_name", "")).strip_edges()
		if not dialogue_speaker_name.is_empty():
			normalized_dialogue["speaker_name"] = dialogue_speaker_name
		var speaker_role := str(dialogue.get("speaker_role", "")).strip_edges().to_lower()
		if not speaker_role.is_empty():
			if speaker_role not in ["player", "npc"]:
				validation_errors.append(
					"NPCData: dialogues[%d].speaker_role 必须是 'player' 或 'npc'。" % index
				)
				continue
			if speaker_role == "player" and dialogue_speaker_name.is_empty():
				validation_errors.append(
					"NPCData: dialogues[%d] 的 player speaker_role 需要 speaker_name。" % index
				)
				continue
			normalized_dialogue["speaker_role"] = speaker_role
		var open_note_key := str(dialogue.get("open_note_key", "")).strip_edges()
		if not open_note_key.is_empty():
			normalized_dialogue["open_note_key"] = open_note_key
		var after_note_background := str(
			dialogue.get("after_note_background", "")
		).strip_edges()
		if not after_note_background.is_empty():
			normalized_dialogue["after_note_background"] = after_note_background
		if dialogue.has("complete_on_note_close"):
			normalized_dialogue["complete_on_note_close"] = bool(
				dialogue["complete_on_note_close"]
			)
		dialogues.append(normalized_dialogue)


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
	if not profile_photo.is_empty() and not ResourceLoader.exists(profile_photo, "Texture2D"):
		validation_errors.append(
			"NPCData: profile_photo 不是有效的图片路径：%s" % profile_photo
		)
	if (
		not initial_background.is_empty()
		and not ResourceLoader.exists(initial_background, "Texture2D")
	):
		validation_errors.append(
			"NPCData: initial_background 不是有效的图片路径：%s" % initial_background
		)
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
		var open_note_key := str(dialogues[index].get("open_note_key", ""))
		if not open_note_key.is_empty() and not note_keys.has(open_note_key):
			validation_errors.append(
				"NPCData: dialogues[%d].open_note_key 没有对应的 Note：%s" % [
					index,
					open_note_key,
				]
			)
		if (
			dialogues[index].has("after_note_background")
			and open_note_key.is_empty()
		):
			validation_errors.append(
				"NPCData: dialogues[%d].after_note_background 需要 open_note_key。" % index
			)
		if (
			dialogues[index].has("complete_on_note_close")
			and open_note_key.is_empty()
		):
			validation_errors.append(
				"NPCData: dialogues[%d].complete_on_note_close 需要 open_note_key。" % index
			)
