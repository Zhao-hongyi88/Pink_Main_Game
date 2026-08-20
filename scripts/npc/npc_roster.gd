class_name NPCRoster
extends RefCounted

## Read-only NPC order and data-path configuration. Runtime player state belongs to GameState.
var entries: Array[Dictionary] = []
var source_path := ""
var validation_errors: PackedStringArray = []

var _entries_by_id: Dictionary = {}


func load_from_json(path: String) -> bool:
	entries.clear()
	_entries_by_id.clear()
	validation_errors.clear()
	source_path = path
	_read_and_validate()
	return is_valid()


func is_valid() -> bool:
	return validation_errors.is_empty()


func get_error_message() -> String:
	return "; ".join(validation_errors)


func get_entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: Dictionary in entries:
		result.append(entry.duplicate(true))
	return result


func get_ordered_npc_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for entry: Dictionary in entries:
		result.append(entry["npc_id"])
	return result


func get_first_npc_id() -> StringName:
	if entries.is_empty():
		return &""
	return entries[0]["npc_id"]


func has_npc(npc_id: StringName) -> bool:
	return not npc_id.is_empty() and _entries_by_id.has(npc_id)


func get_data_path(npc_id: StringName) -> String:
	if not has_npc(npc_id):
		return ""
	return str(_entries_by_id[npc_id]["data_path"])


func get_display_name(npc_id: StringName) -> String:
	if not has_npc(npc_id):
		return ""
	return str(_entries_by_id[npc_id]["display_name"])


func get_next_npc_id(npc_id: StringName) -> StringName:
	for index in entries.size():
		if entries[index]["npc_id"] != npc_id:
			continue
		if index + 1 >= entries.size():
			return &""
		return entries[index + 1]["npc_id"]
	return &""


func _read_and_validate() -> void:
	if source_path.is_empty():
		validation_errors.append("NPCRoster: source path is empty.")
		return
	if not FileAccess.file_exists(source_path):
		validation_errors.append("NPCRoster: data file not found: %s" % source_path)
		return

	var file := FileAccess.open(source_path, FileAccess.READ)
	if file == null:
		validation_errors.append("NPCRoster: cannot read data file: %s" % source_path)
		return

	var json := JSON.new()
	var parse_result := json.parse(file.get_as_text())
	file.close()
	if parse_result != OK:
		validation_errors.append(
			"NPCRoster: JSON parse failed at line %d: %s" % [
				json.get_error_line(),
				json.get_error_message(),
			]
		)
		return
	if typeof(json.data) != TYPE_DICTIONARY:
		validation_errors.append("NPCRoster: JSON root must be a Dictionary.")
		return

	var raw: Dictionary = json.data
	if not raw.has("npcs") or typeof(raw["npcs"]) != TYPE_ARRAY:
		validation_errors.append("NPCRoster: 'npcs' must be an Array.")
		return
	var raw_entries: Array = raw["npcs"]
	if raw_entries.is_empty():
		validation_errors.append("NPCRoster: at least one NPC entry is required.")
		return

	for index in raw_entries.size():
		var raw_entry: Variant = raw_entries[index]
		if typeof(raw_entry) != TYPE_DICTIONARY:
			validation_errors.append("NPCRoster: npcs[%d] must be a Dictionary." % index)
			continue
		_normalize_entry(raw_entry, index)


func _normalize_entry(raw_entry: Dictionary, index: int) -> void:
	for field in ["npc_id", "data_path"]:
		if not raw_entry.has(field) or typeof(raw_entry[field]) != TYPE_STRING:
			validation_errors.append("NPCRoster: npcs[%d].%s must be a String." % [index, field])
			return

	var npc_id_text := str(raw_entry["npc_id"]).strip_edges()
	var data_path := str(raw_entry["data_path"]).strip_edges()
	if npc_id_text.is_empty() or data_path.is_empty():
		validation_errors.append("NPCRoster: npcs[%d] contains an empty required field." % index)
		return

	var npc_id := StringName(npc_id_text)
	if _entries_by_id.has(npc_id):
		validation_errors.append("NPCRoster: duplicate npc_id: %s" % npc_id_text)
		return
	if not FileAccess.file_exists(data_path):
		validation_errors.append("NPCRoster: NPCData file not found: %s" % data_path)
		return

	var npc_data := NPCData.load_from_json(data_path)
	if not npc_data.is_valid():
		validation_errors.append("NPCRoster: invalid NPCData at %s: %s" % [data_path, npc_data.get_error_message()])
		return
	if npc_data.npc_id != npc_id:
		validation_errors.append(
			"NPCRoster: npc_id mismatch for %s (NPCData contains %s)." % [npc_id_text, npc_data.npc_id]
		)
		return

	var entry := {
		"npc_id": npc_id,
		"data_path": data_path,
		"display_name": npc_data.display_name,
	}
	entries.append(entry)
	_entries_by_id[npc_id] = entry
