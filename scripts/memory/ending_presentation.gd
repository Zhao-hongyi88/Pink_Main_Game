class_name MemoryEndingPresentation
extends Control

## Shared presentation behavior for every NPC ending scene.
@export var text_node_path: NodePath = ^"EndingText"
@export var fade_duration := 0.8
@export var scroll_duration := 0.7
@export_file("*.tscn") var next_scene_path := ""

@onready var ending_text: CanvasItem = get_node_or_null(text_node_path) as CanvasItem

var _can_fade_out := false
var _is_fading_out := false


func _ready() -> void:
	if ending_text == null:
		push_warning("MemoryEndingPresentation: EndingText node was not found.")
		return

	ending_text.modulate.a = 0.0
	var fade_in := create_tween()
	fade_in.tween_property(ending_text, "modulate:a", 1.0, fade_duration)
	fade_in.finished.connect(_on_text_fade_in_finished)


func _input(event: InputEvent) -> void:
	if not _can_fade_out or _is_fading_out:
		return
	if event is InputEventMouseButton \
		and event.button_index == MOUSE_BUTTON_LEFT \
		and event.pressed:
		_is_fading_out = true
		var fade_out := create_tween()
		fade_out.tween_property(ending_text, "modulate:a", 0.0, fade_duration)
		fade_out.finished.connect(_on_text_fade_out_finished)
		get_viewport().set_input_as_handled()


func _on_text_fade_in_finished() -> void:
	_can_fade_out = true


func _on_text_fade_out_finished() -> void:
	if next_scene_path.is_empty():
		return
	var scroll_out := create_tween()
	scroll_out.set_trans(Tween.TRANS_SINE)
	scroll_out.set_ease(Tween.EASE_IN_OUT)
	scroll_out.tween_property(
		self,
		"position:y",
		-get_viewport().get_visible_rect().size.y,
		scroll_duration
	)
	scroll_out.finished.connect(_open_next_ending_scene)


func _open_next_ending_scene() -> void:
	var change_error := get_tree().change_scene_to_file(next_scene_path)
	if change_error != OK:
		push_warning("MemoryEndingPresentation: Unable to open next ending scene: " + next_scene_path)
