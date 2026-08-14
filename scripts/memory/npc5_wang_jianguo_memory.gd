class_name NPC5WangJianGuoMemory
extends "res://scripts/memory/memory_base.gd"

## 王建国 Memory 只声明人物专属调查点，公共流程由 MemoryBase 负责。

@onready var community_supplies: Area2D = %CommunitySupplies
@onready var donation_certificates: Area2D = %DonationCertificates
@onready var charity_forum_record: Area2D = %CharityForumRecord
@onready var activity_room_entry: Area2D = %ActivityRoomEntry
@onready var supplies_room_entry: Area2D = %SuppliesRoomEntry
@onready var stage_one_background: CanvasItem = $Background
@onready var stage_two_background: CanvasItem = $StageTwoBackground
@onready var stage_three_background: CanvasItem = $StageThreeBackground

var _active_unexplored_marker: CanvasItem
var _active_observation_id := ""


func _ready() -> void:
	super._ready()
	register_observation_points([
		community_supplies,
		donation_certificates,
		charity_forum_record,
	])
	community_supplies.observation_requested.connect(_on_observation_opened.bind(community_supplies))
	donation_certificates.observation_requested.connect(_on_observation_opened.bind(donation_certificates))
	charity_forum_record.observation_requested.connect(_on_observation_opened.bind(charity_forum_record))
	activity_room_entry.input_event.connect(_on_activity_room_entry_input)
	supplies_room_entry.input_event.connect(_on_supplies_room_entry_input)
	activity_room_entry.mouse_entered.connect(_on_entry_mouse_entered)
	activity_room_entry.mouse_exited.connect(_on_entry_mouse_exited)
	supplies_room_entry.mouse_entered.connect(_on_entry_mouse_entered)
	supplies_room_entry.mouse_exited.connect(_on_entry_mouse_exited)
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


func _on_activity_room_entry_input(_viewport: Node, event: InputEvent, _shape_index: int) -> void:
	if event is InputEventMouseButton \
		and event.button_index == MOUSE_BUTTON_LEFT \
		and event.pressed:
		_show_activity_room()


func _on_supplies_room_entry_input(_viewport: Node, event: InputEvent, _shape_index: int) -> void:
	if event is InputEventMouseButton \
		and event.button_index == MOUSE_BUTTON_LEFT \
		and event.pressed:
		_show_supplies_room()


func _on_entry_mouse_entered() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)


func _on_entry_mouse_exited() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _show_activity_room() -> void:
	stage_one_background.hide()
	stage_two_background.show()
	stage_three_background.hide()
	activity_room_entry.hide()
	supplies_room_entry.hide()
	charity_forum_record.show()
	donation_certificates.show()
	community_supplies.hide()
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _show_supplies_room() -> void:
	stage_one_background.hide()
	stage_two_background.hide()
	stage_three_background.show()
	activity_room_entry.hide()
	supplies_room_entry.hide()
	charity_forum_record.hide()
	donation_certificates.hide()
	community_supplies.show()
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
