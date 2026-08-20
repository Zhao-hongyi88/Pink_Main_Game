class_name DialogueManager
extends RefCounted

## 单个 NPCBase 实例使用的对话逻辑层。NPCProgress 是唯一运行时状态来源。

const TRACK_MAIN := 0
const TRACK_FINAL := 1

var _dialogues: Array[Dictionary] = []
var _progress: NPCProgress
var _track := TRACK_MAIN


func setup(
	dialogues: Array[Dictionary],
	progress: NPCProgress,
	track: int = TRACK_MAIN
) -> bool:
	_dialogues = dialogues.duplicate(true)
	_progress = progress
	_track = track
	if _dialogues.is_empty() or _progress == null:
		return false
	if _track not in [TRACK_MAIN, TRACK_FINAL]:
		return false

	_set_current_index(clampi(
		_get_current_index(),
		0,
		_dialogues.size() - 1
	))
	if _is_dialogue_completed():
		_set_current_index(_dialogues.size() - 1)
	return true


func get_current_dialogue() -> Dictionary:
	if not _is_ready():
		return {}
	return _dialogues[_get_current_index()]


func get_current_text() -> String:
	return str(get_current_dialogue().get("text", ""))


func get_current_unlock_key() -> String:
	return str(get_current_dialogue().get("unlock_key", "")).strip_edges()


func has_next() -> bool:
	if not _is_ready() or _is_dialogue_completed():
		return false
	return _get_current_index() < _dialogues.size() - 1


func advance() -> Dictionary:
	var result := {
		"accepted": false,
		"moved_to_next": false,
		"unlock_key": "",
		"dialogue_completed": _is_dialogue_completed() if _progress != null else false,
	}
	if not _is_ready() or _is_dialogue_completed():
		return result

	# 必须先读取当前条目的 key，再推进或完成，保证最后一条的 key 不会丢失。
	result["accepted"] = true
	result["unlock_key"] = get_current_unlock_key()
	if has_next():
		_set_current_index(_get_current_index() + 1)
		result["moved_to_next"] = true
	else:
		_set_dialogue_completed(true)
	result["dialogue_completed"] = _is_dialogue_completed()
	return result


func _is_ready() -> bool:
	return _progress != null and not _dialogues.is_empty()


func _get_current_index() -> int:
	if _progress == null:
		return 0
	if _track == TRACK_FINAL:
		return _progress.final_dialogue_index
	return _progress.current_dialogue_index


func _set_current_index(value: int) -> void:
	if _progress == null:
		return
	if _track == TRACK_FINAL:
		_progress.final_dialogue_index = value
	else:
		_progress.current_dialogue_index = value


func _is_dialogue_completed() -> bool:
	if _progress == null:
		return false
	if _track == TRACK_FINAL:
		return _progress.final_dialogue_completed
	return _progress.dialogue_completed


func _set_dialogue_completed(value: bool) -> void:
	if _progress == null:
		return
	if _track == TRACK_FINAL:
		_progress.final_dialogue_completed = value
	else:
		_progress.dialogue_completed = value
