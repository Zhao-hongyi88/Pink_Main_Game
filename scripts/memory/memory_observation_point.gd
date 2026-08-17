class_name MemoryObservationPoint
extends Area2D

## Handles clicking and hover for one observation point without owning presentation or completion state.

signal observation_requested(data)

@export var observation_data: Resource

@onready var visual: CanvasItem = get_node_or_null("Visual") as CanvasItem


func _ready() -> void:
	if observation_data == null:
		push_warning("MemoryObservationPoint: Missing observation_data.")

	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _on_input_event(_viewport: Node, event: InputEvent, _shape_index: int) -> void:
	if event is InputEventMouseButton \
		and event.button_index == MOUSE_BUTTON_LEFT \
		and event.pressed \
		and observation_data != null:
		observation_requested.emit(observation_data)


func _on_mouse_entered() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	if visual != null:
		visual.modulate = Color(0.72, 0.9, 1.0, 1.0)


func _on_mouse_exited() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	if visual != null:
		visual.modulate = Color.WHITE
