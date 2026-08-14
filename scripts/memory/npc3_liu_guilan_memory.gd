class_name NPC3LiuGuiLanMemory
extends "res://scripts/memory/memory_base.gd"

## 刘桂兰 Memory 只声明人物专属调查点，公共流程由 MemoryBase 负责。

@onready var medical_record: Area2D = %MedicalRecord
@onready var treatment_bill: Area2D = %TreatmentBill
@onready var treatment_bed: Area2D = %TreatmentBed
@onready var treatment_room_entry: Area2D = %TreatmentRoomEntry
@onready var stage_one_background: CanvasItem = $Background
@onready var stage_two_background: CanvasItem = $StageTwoBackground

var _active_unexplored_marker: CanvasItem
var _active_observation_id := ""


func _ready() -> void:
	super._ready()
	register_observation_points([
		medical_record,
		treatment_bill,
		treatment_bed,
	])
	medical_record.observation_requested.connect(_on_observation_opened.bind(medical_record))
	treatment_bill.observation_requested.connect(_on_observation_opened.bind(treatment_bill))
	treatment_bed.observation_requested.connect(_on_observation_opened.bind(treatment_bed))
	treatment_room_entry.input_event.connect(_on_treatment_room_entry_input)
	treatment_room_entry.mouse_entered.connect(_on_treatment_room_entry_mouse_entered)
	treatment_room_entry.mouse_exited.connect(_on_treatment_room_entry_mouse_exited)
	%MemoryInfoPanel.observation_cancelled.connect(_on_observation_cancelled_restore_marker)
	%MemoryInfoPanel.observation_completed.connect(_on_observation_completed_keep_hidden)
	treatment_bed.hide()


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


func _on_treatment_room_entry_input(_viewport: Node, event: InputEvent, _shape_index: int) -> void:
	if event is InputEventMouseButton \
		and event.button_index == MOUSE_BUTTON_LEFT \
		and event.pressed:
		_show_treatment_room()


func _on_treatment_room_entry_mouse_entered() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)


func _on_treatment_room_entry_mouse_exited() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _show_treatment_room() -> void:
	stage_one_background.hide()
	stage_two_background.show()
	medical_record.hide()
	treatment_bill.hide()
	treatment_room_entry.hide()
	treatment_bed.show()
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
