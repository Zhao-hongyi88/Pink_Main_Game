extends Node

## 集中维护页面路由。业务页面只引用 route_id，不持有其他场景的路径。

signal navigation_started(route_id: StringName)
signal navigation_failed(route_id: StringName, message: String)

const ROUTES: Dictionary = {
	&"home": "res://scenes/main/main_menu.tscn",
	&"lobby": "res://scenes/main/lobby.tscn",
	&"npc_base": "res://scenes/npc/npc_base.tscn",
	&"story": "res://scenes/story/story_placeholder.tscn",
}

var current_route: StringName = &"home"
var _pending_payload: Dictionary = {}


func go_to(route_id: StringName, payload: Dictionary = {}) -> bool:
	if not ROUTES.has(route_id):
		var message := "未注册的页面路由：%s" % route_id
		push_error(message)
		navigation_failed.emit(route_id, message)
		return false

	_pending_payload = payload.duplicate(true)
	current_route = route_id
	navigation_started.emit(route_id)
	var result := get_tree().change_scene_to_file(ROUTES[route_id])
	if result != OK:
		var message := "页面切换失败：%s" % error_string(result)
		push_error(message)
		navigation_failed.emit(route_id, message)
		return false
	return true


func go_to_scene(scene_path: String, payload: Dictionary = {}) -> bool:
	var normalized_path := scene_path.strip_edges()
	var route_id := StringName(normalized_path)
	if normalized_path.is_empty() or not ResourceLoader.exists(normalized_path, "PackedScene"):
		var message := "未找到目标场景：%s" % normalized_path
		push_error(message)
		navigation_failed.emit(route_id, message)
		return false

	_pending_payload = payload.duplicate(true)
	current_route = route_id
	navigation_started.emit(route_id)
	var result := get_tree().change_scene_to_file(normalized_path)
	if result != OK:
		var message := "页面切换失败：%s" % error_string(result)
		push_error(message)
		navigation_failed.emit(route_id, message)
		return false
	return true


func take_payload() -> Dictionary:
	var payload := _pending_payload
	_pending_payload = {}
	return payload
