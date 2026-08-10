extends Node

## Central scene navigation. Business pages use route IDs or data-provided scene paths.
signal navigation_started(route_id: StringName)
signal navigation_failed(route_id: StringName, message: String)

const ROUTES: Dictionary = {
	&"home": "res://scenes/main/main_menu.tscn",
	&"lobby": "res://scenes/main/lobby.tscn",
	&"npc_base": "res://scenes/npc/npc_base.tscn",
	&"story": "res://scenes/story/story_placeholder.tscn",
}
const TRANSITION_LAYER_SCENE: PackedScene = preload("res://scenes/ui/transition_layer.tscn")

var current_route: StringName = &"home"
var _pending_payload: Dictionary = {}
var _is_transitioning := false
var _transition_layer: CanvasLayer


func _ready() -> void:
	_transition_layer = TRANSITION_LAYER_SCENE.instantiate() as CanvasLayer
	add_child(_transition_layer)


func go_to(route_id: StringName, payload: Dictionary = {}) -> bool:
	if not ROUTES.has(route_id):
		var message := "Unregistered scene route: %s" % route_id
		push_error(message)
		navigation_failed.emit(route_id, message)
		return false
	return _request_navigation(route_id, ROUTES[route_id], payload)


func go_to_scene(scene_path: String, payload: Dictionary = {}) -> bool:
	var normalized_path := scene_path.strip_edges()
	var route_id := StringName(normalized_path)
	if normalized_path.is_empty() or not ResourceLoader.exists(normalized_path, "PackedScene"):
		var message := "Target scene was not found: %s" % normalized_path
		push_error(message)
		navigation_failed.emit(route_id, message)
		return false
	return _request_navigation(route_id, normalized_path, payload)


func take_payload() -> Dictionary:
	var payload := _pending_payload
	_pending_payload = {}
	return payload


func is_transitioning() -> bool:
	return _is_transitioning


func _request_navigation(route_id: StringName, scene_path: String, payload: Dictionary) -> bool:
	if _is_transitioning:
		return false

	var previous_route := current_route
	_pending_payload = payload.duplicate(true)
	current_route = route_id
	_is_transitioning = true
	navigation_started.emit(route_id)
	_perform_navigation(route_id, scene_path, previous_route)
	return true


func _perform_navigation(
	route_id: StringName,
	scene_path: String,
	previous_route: StringName
) -> void:
	await _transition_layer.fade_out()
	var result := get_tree().change_scene_to_file(scene_path)
	if result != OK:
		var message := "Scene change failed: %s" % error_string(result)
		push_error(message)
		_pending_payload.clear()
		current_route = previous_route
		await _transition_layer.fade_in()
		_is_transitioning = false
		navigation_failed.emit(route_id, message)
		return

	# change_scene_to_file() replaces the current scene at the end of the frame.
	await get_tree().process_frame
	await get_tree().process_frame
	await _transition_layer.fade_in()
	_is_transitioning = false
