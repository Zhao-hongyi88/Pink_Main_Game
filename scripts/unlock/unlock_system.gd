class_name UnlockSystem
extends RefCounted

## 单个 NPCBase 实例使用的解锁状态层。NPCProgress 是唯一运行时状态来源。

var _valid_keys: Dictionary = {}
var _progress: NPCProgress


func setup(valid_keys: Array[String], progress: NPCProgress) -> bool:
	_valid_keys.clear()
	_progress = progress
	if _progress == null:
		return false
	for key in valid_keys:
		var normalized_key := key.strip_edges()
		if normalized_key.is_empty():
			continue
		_valid_keys[normalized_key] = true
	return true


func request_unlock(unlock_key: String) -> Dictionary:
	var normalized_key := unlock_key.strip_edges()
	var result := {
		"accepted": false,
		"newly_unlocked": false,
		"key": normalized_key,
	}
	if _progress == null or normalized_key.is_empty():
		return result
	if not _valid_keys.has(normalized_key):
		return result

	result["accepted"] = true
	if bool(_progress.unlocked_keys.get(normalized_key, false)):
		return result

	_progress.unlocked_keys[normalized_key] = true
	if not _progress.revealed_note_keys.has(normalized_key):
		_progress.revealed_note_keys.append(normalized_key)
	result["newly_unlocked"] = true
	return result
