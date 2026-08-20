class_name NPC3LiuGuiLanMemory
extends "res://scripts/memory/memory_base.gd"

const DAUGHTER_MESSAGE_TEXTURE: Texture2D = preload(
	"res://TextureAsset/Memory/NPC3/DaughterMessage/daughter_message_preview.png"
)
const PARENT_CHILD_INVITATION_TEXTURE: Texture2D = preload(
	"res://TextureAsset/Memory/NPC3/ParentChildInvitation/parent_child_invitation_preview.png"
)

var _daughter_message_dialogue := PackedStringArray([
	"Her daughter often sends her messages.",
	"It seems that she is really busy and often replies late.",
])
var _parent_child_invitation_dialogue := PackedStringArray([
	"This invitation originally represented an opportunity for the family to participate together.",
	"But in the end, it was never opened and never appeared on Su Qing's schedule.",
])

@onready var employee_overtime_statistics: MemoryObservationPoint = %EmployeeOvertimeStatistics
@onready var li_lei_employee_file: MemoryObservationPoint = %LiLeiEmployeeFile
@onready var project_leader_list: MemoryObservationPoint = %ProjectLeaderList
@onready var daughter_message_marker: Area2D = %DaughterMessageMarker
@onready var parent_child_invitation_marker: Area2D = %ParentChildInvitationMarker

var _active_unexplored_marker: CanvasItem
var _active_observation_id: StringName = &""


func _ready() -> void:
	super._ready()
	register_observation_points([
		employee_overtime_statistics,
		li_lei_employee_file,
		project_leader_list,
	])
	employee_overtime_statistics.observation_requested.connect(
		_on_observation_opened.bind(employee_overtime_statistics)
	)
	li_lei_employee_file.observation_requested.connect(
		_on_observation_opened.bind(li_lei_employee_file)
	)
	project_leader_list.observation_requested.connect(
		_on_observation_opened.bind(project_leader_list)
	)
	daughter_message_marker.input_event.connect(
		_on_secondary_marker_input.bind(
			DAUGHTER_MESSAGE_TEXTURE,
			daughter_message_marker,
			_daughter_message_dialogue
		)
	)
	parent_child_invitation_marker.input_event.connect(
		_on_secondary_marker_input.bind(
			PARENT_CHILD_INVITATION_TEXTURE,
			parent_child_invitation_marker,
			_parent_child_invitation_dialogue
		)
	)
	daughter_message_marker.mouse_entered.connect(_on_secondary_marker_mouse_entered)
	daughter_message_marker.mouse_exited.connect(_on_secondary_marker_mouse_exited)
	parent_child_invitation_marker.mouse_entered.connect(_on_secondary_marker_mouse_entered)
	parent_child_invitation_marker.mouse_exited.connect(_on_secondary_marker_mouse_exited)
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
	dialogue: PackedStringArray
) -> void:
	if event is InputEventMouseButton \
		and event.button_index == MOUSE_BUTTON_LEFT \
		and event.pressed:
		%MemoryInfoPanel.show_standalone_image_with_dialogue(texture, dialogue)
		marker.hide()
		marker.set_deferred("input_pickable", false)
		get_viewport().set_input_as_handled()


func _on_secondary_marker_mouse_entered() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)


func _on_secondary_marker_mouse_exited() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
