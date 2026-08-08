class_name DialogueManager
extends RefCounted

## 单个 NPCBase 实例使用的对话逻辑层。NPCProgress 是唯一运行时状态来源。

var _dialogues: Array[Dictionary] = []
var _progress: NPCProgress


func setup(dialogues: Array[Dictionary], progress: NPCProgress) -> bool:
	_dialogues = dialogues.duplicate(true)
	_progress = progress
	if _dialogues.is_empty() or _progress == null:
		return false

	_progress.current_dialogue_index = clampi(
		_progress.current_dialogue_index,
		0,
		_dialogues.size() - 1
	)
	if _progress.dialogue_completed:
		_progress.current_dialogue_index = _dialogues.size() - 1
	return true


func get_current_dialogue() -> Dictionary:
	if not _is_ready():
		return {}
	return _dialogues[_progress.current_dialogue_index]


func get_current_text() -> String:
	return str(get_current_dialogue().get("text", ""))


func get_current_unlock_key() -> String:
	return str(get_current_dialogue().get("unlock_key", "")).strip_edges()


func has_next() -> bool:
	if not _is_ready() or _progress.dialogue_completed:
		return false
	return _progress.current_dialogue_index < _dialogues.size() - 1


func advance() -> Dictionary:
	var result := {
		"accepted": false,
		"moved_to_next": false,
		"unlock_key": "",
		"dialogue_completed": _progress.dialogue_completed if _progress != null else false,
	}
	if not _is_ready() or _progress.dialogue_completed:
		return result

	# 必须先读取当前条目的 key，再推进或完成，保证最后一条的 key 不会丢失。
	result["accepted"] = true
	result["unlock_key"] = get_current_unlock_key()
	if has_next():
		_progress.current_dialogue_index += 1
		result["moved_to_next"] = true
	else:
		_progress.dialogue_completed = true
	result["dialogue_completed"] = _progress.dialogue_completed
	return result


func _is_ready() -> bool:
	return _progress != null and not _dialogues.is_empty()
