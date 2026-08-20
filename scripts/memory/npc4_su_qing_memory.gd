class_name NPC4SuQingMemory
extends "res://scripts/memory/memory_base.gd"

const TOM_PORTRAIT: Texture2D = preload("res://TextureAsset/Memory/NPC4/tom_portrait.png")

## Su Qing Memory only declares character-specific observation points; MemoryBase owns the shared flow.


@onready var table_phone: Area2D = %TablePhone
@onready var hospital_care_record: Area2D = %HospitalCareRecord
@onready var dialogue_marker: Area2D = %DialogueMarker

var _hospital_dialogue := PackedStringArray([
	"Tom:\nHow has she been recently?",
	"Medical Staff:\nThe treatment has been working reasonably well so far, but she will still need to be monitored continuously.",
	"Tom:\nHow much longer will it take?",
	"Medical Staff:\nThat is difficult to determine.",
	"Medical Staff:\nWith this kind of long-term treatment, the longer it continues, the more medical time it requires.",
	"Tom:\nIs there a limit to medical time as well?",
	"Medical Staff:\nEach person is granted a different allowance.",
	"Medical Staff:\nSome families can continue to pay; others can only choose to reduce the treatment cycle.",
	"Tom:\nHer son has been applying for new time allowances.",
	"Medical Staff:\nWe know.",
	"Medical Staff:\nBut his situation is not easy either.",
	"Medical Staff:\nLong-term work, combined with caring for a patient, has also begun to lower his own health indicators.",
	"Tom:\nHe never said anything.",
	"Medical Staff:\nMany family members do not.",
	"Medical Staff:\nThey think they can keep going.",
	"Medical Staff:\nUntil time truly runs out.",
	"(Tom falls silent.)",
])

var _active_unexplored_marker: CanvasItem
var _active_observation_id := ""


func _ready() -> void:
	super._ready()
	register_observation_points([
		table_phone,
		hospital_care_record,
	])
	table_phone.observation_requested.connect(_on_observation_opened.bind(table_phone))
	hospital_care_record.observation_requested.connect(_on_observation_opened.bind(hospital_care_record))
	dialogue_marker.input_event.connect(_on_dialogue_marker_input)
	dialogue_marker.mouse_entered.connect(_on_dialogue_marker_mouse_entered)
	dialogue_marker.mouse_exited.connect(_on_dialogue_marker_mouse_exited)
	%MemoryInfoPanel.observation_cancelled.connect(_on_observation_cancelled_restore_marker)
	%MemoryInfoPanel.observation_completed.connect(_on_observation_completed_keep_hidden)


func _on_observation_opened(data, point: Area2D) -> void:
	_active_observation_id = str(data.observation_id)
	_active_unexplored_marker = point.get_node_or_null("UnexploredMarker") as CanvasItem
	if _active_unexplored_marker != null:
		_active_unexplored_marker.hide()


func _on_observation_cancelled_restore_marker() -> void:
	if _active_unexplored_marker != null and not is_observed(_active_observation_id):
		_active_unexplored_marker.show()
	_active_unexplored_marker = null
	_active_observation_id = ""


func _on_observation_completed_keep_hidden(_observation_id) -> void:
	_active_unexplored_marker = null
	_active_observation_id = ""


func _on_dialogue_marker_input(
	_viewport: Node,
	event: InputEvent,
	_shape_index: int
) -> void:
	if event is InputEventMouseButton \
		and event.button_index == MOUSE_BUTTON_LEFT \
		and event.pressed:
		%MemoryInfoPanel.show_standalone_dialogue_with_portrait(
			_hospital_dialogue,
			"Tom",
			TOM_PORTRAIT
		)
		dialogue_marker.hide()
		dialogue_marker.set_deferred("input_pickable", false)
		get_viewport().set_input_as_handled()


func _on_dialogue_marker_mouse_entered() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)


func _on_dialogue_marker_mouse_exited() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
