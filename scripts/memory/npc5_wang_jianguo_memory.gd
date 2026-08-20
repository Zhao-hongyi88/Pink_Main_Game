class_name NPC5WangJianGuoMemory
extends "res://scripts/memory/memory_base.gd"

const NOTEBOOK_TEXTURE: Texture2D = preload(
	"res://TextureAsset/Memory/NPC5/Notebook/notebook_icon.png"
)
const CERTIFICATE_TEXTURE: Texture2D = preload(
	"res://TextureAsset/Memory/NPC5/Certificate/certificate_icon.png"
)

var _certificate_dialogue := PackedStringArray([
	"This certificate records Tom's many years of participation in community service.",
	"These honors prove his dedication and show that this choice has continued for a long time.",
])
var _notebook_dialogue := PackedStringArray([
	"This notebook records not work arrangements, but the everyday problems of many people.",
	"Tom has long devoted his own time to helping resolve difficulties that other systems cannot solve.",
	"From these records, it seems he is used to treating other people's problems as his own responsibility.",
])

@onready var computer_records: MemoryObservationPoint = %ComputerRecords
@onready var notebook_marker: Area2D = %NotebookMarker
@onready var certificate_marker: Area2D = %CertificateMarker

var _active_unexplored_marker: CanvasItem
var _active_observation_id: StringName = &""


func _ready() -> void:
	super._ready()
	register_observation_points([computer_records])
	computer_records.observation_requested.connect(
		_on_observation_opened.bind(computer_records)
	)
	notebook_marker.input_event.connect(
		_on_secondary_marker_input.bind(
			NOTEBOOK_TEXTURE,
			notebook_marker,
			_notebook_dialogue
		)
	)
	certificate_marker.input_event.connect(
		_on_secondary_marker_input.bind(
			CERTIFICATE_TEXTURE,
			certificate_marker,
			_certificate_dialogue
		)
	)
	notebook_marker.mouse_entered.connect(_on_secondary_marker_mouse_entered)
	notebook_marker.mouse_exited.connect(_on_secondary_marker_mouse_exited)
	certificate_marker.mouse_entered.connect(_on_secondary_marker_mouse_entered)
	certificate_marker.mouse_exited.connect(_on_secondary_marker_mouse_exited)
	%MemoryInfoPanel.observation_cancelled.connect(_on_observation_cancelled_restore_marker)
	%MemoryInfoPanel.observation_completed.connect(_on_observation_completed_keep_hidden)


func _on_observation_opened(data, point: MemoryObservationPoint) -> void:
	_active_observation_id = data.observation_id if data != null else &""
	_active_unexplored_marker = point.get_node_or_null("UnexploredMarker") as CanvasItem
	if _active_unexplored_marker != null:
		_active_unexplored_marker.hide()


func _on_observation_cancelled_restore_marker() -> void:
	if _active_unexplored_marker != null and not is_observed(_active_observation_id):
		_active_unexplored_marker.show()
	_clear_active_observation_marker()


func _on_observation_completed_keep_hidden(_observation_id) -> void:
	_clear_active_observation_marker()


func _clear_active_observation_marker() -> void:
	_active_unexplored_marker = null
	_active_observation_id = &""


func _on_secondary_marker_input(
	_viewport: Node,
	event: InputEvent,
	_shape_index: int,
	texture: Texture2D,
	marker: Area2D,
	dialogue: PackedStringArray = PackedStringArray()
) -> void:
	if event is InputEventMouseButton \
		and event.button_index == MOUSE_BUTTON_LEFT \
		and event.pressed:
		if dialogue.is_empty():
			%MemoryInfoPanel.show_standalone_image(texture)
		else:
			%MemoryInfoPanel.show_standalone_image_with_dialogue(texture, dialogue)
		marker.hide()
		marker.set_deferred("input_pickable", false)
		get_viewport().set_input_as_handled()


func _on_secondary_marker_mouse_entered() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)


func _on_secondary_marker_mouse_exited() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
