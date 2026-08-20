extends Node

## 通用存档协调器。
## 各业务系统通过 register_section 注册自己的序列化逻辑，避免存档模块依赖具体系统。

signal save_completed(path: String)
signal load_completed(path: String)
signal save_failed(message: String)
signal load_failed(message: String)

const SAVE_VERSION := 1
const SAVE_PATH := "user://pink_main_game_save.json"

var _sections: Dictionary = {}


func register_section(
	section_id: StringName,
	save_callback: Callable,
	load_callback: Callable
) -> void:
	if section_id.is_empty():
		push_error("SaveService: section_id 不能为空。")
		return
	if not save_callback.is_valid() or not load_callback.is_valid():
		push_error("SaveService: 存档回调无效：%s" % section_id)
		return
	_sections[section_id] = {
		"save": save_callback,
		"load": load_callback,
	}


func unregister_section(section_id: StringName) -> void:
	_sections.erase(section_id)


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> bool:
	var section_data: Dictionary = {}
	for section_id: StringName in _sections:
		var provider: Dictionary = _sections[section_id]
		section_data[String(section_id)] = provider["save"].call()

	var payload := {
		"version": SAVE_VERSION,
		"saved_at_unix": int(Time.get_unix_time_from_system()),
		"sections": section_data,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		var message := "无法写入存档：%s" % error_string(FileAccess.get_open_error())
		push_error(message)
		save_failed.emit(message)
		return false

	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	save_completed.emit(SAVE_PATH)
	return true


func load_game() -> bool:
	if not has_save():
		var no_save_message := "没有可读取的存档。"
		load_failed.emit(no_save_message)
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		var open_message := "无法读取存档：%s" % error_string(FileAccess.get_open_error())
		push_error(open_message)
		load_failed.emit(open_message)
		return false

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		var format_message := "存档格式无效。"
		push_error(format_message)
		load_failed.emit(format_message)
		return false

	var payload: Dictionary = parsed
	if int(payload.get("version", -1)) > SAVE_VERSION:
		var version_message := "存档版本高于当前程序版本。"
		push_error(version_message)
		load_failed.emit(version_message)
		return false

	var section_data: Dictionary = payload.get("sections", {})
	for section_id: StringName in _sections:
		var key := String(section_id)
		if not section_data.has(key):
			continue
		var provider: Dictionary = _sections[section_id]
		provider["load"].call(section_data[key])

	load_completed.emit(SAVE_PATH)
	return true


func delete_save() -> bool:
	if not has_save():
		return true
	var result := DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	if result != OK:
		push_error("无法删除存档：%s" % error_string(result))
		return false
	return true
