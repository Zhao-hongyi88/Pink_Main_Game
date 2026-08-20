class_name NPC2LiLeiMemory
extends "res://scripts/memory/memory_base.gd"

const MEDICAL_CHECKUP_REPORT_TEXTURE: Texture2D = preload(
	"res://TextureAsset/Memory/NPC2/MedicalCheckupReport/medical_checkup_report.png"
)
const UNUSED_TREATMENT_APPOINTMENT_TEXTURE: Texture2D = preload(
	"res://TextureAsset/Memory/NPC2/UnusedTreatmentAppointment/unused_treatment_appointment.png"
)

var _medical_checkup_report_dialogue := PackedStringArray([
	"This report shows that Li Lei's physical condition has already been affected by long-term pressure.",
	"Most of his time is spent on work and family responsibilities, leaving very little for his own recovery.",
])
var _unused_treatment_appointment_dialogue := PackedStringArray([
	"This appointment was originally part of Li Lei's own treatment plan.",
	"But it has been left here, unused.",
])

## Li Lei Memory only declares character-specific observation points; MemoryBase owns the shared flow.

@onready var mother_message: Area2D = %MotherMessage
@onready var living_expense_record: Area2D = %LivingExpenseRecord
@onready var unfinished_personal_plan: Area2D = %UnfinishedPersonalPlan
@onready var medical_checkup_report_marker: Area2D = %MedicalCheckupReportMarker
@onready var unused_treatment_appointment_marker: Area2D = %UnusedTreatmentAppointmentMarker

var _active_unexplored_marker: CanvasItem


func _ready() -> void:
	super._ready()
	register_observation_points([
		mother_message,
		living_expense_record,
		unfinished_personal_plan,
	])
	mother_message.observation_requested.connect(_on_observation_opened.bind(mother_message))
	living_expense_record.observation_requested.connect(_on_observation_opened.bind(living_expense_record))
	unfinished_personal_plan.observation_requested.connect(_on_observation_opened.bind(unfinished_personal_plan))
	medical_checkup_report_marker.input_event.connect(
		_on_secondary_marker_input.bind(
			MEDICAL_CHECKUP_REPORT_TEXTURE,
			medical_checkup_report_marker,
			_medical_checkup_report_dialogue
		)
	)
	unused_treatment_appointment_marker.input_event.connect(
		_on_secondary_marker_input.bind(
			UNUSED_TREATMENT_APPOINTMENT_TEXTURE,
			unused_treatment_appointment_marker,
			_unused_treatment_appointment_dialogue
		)
	)
	medical_checkup_report_marker.mouse_entered.connect(_on_secondary_marker_mouse_entered)
	medical_checkup_report_marker.mouse_exited.connect(_on_secondary_marker_mouse_exited)
	unused_treatment_appointment_marker.mouse_entered.connect(_on_secondary_marker_mouse_entered)
	unused_treatment_appointment_marker.mouse_exited.connect(_on_secondary_marker_mouse_exited)
	%MemoryInfoPanel.observation_cancelled.connect(_on_observation_cancelled_restore_marker)
	%MemoryInfoPanel.observation_completed.connect(_on_observation_completed_keep_hidden)


func _on_observation_opened(_data, point: Area2D) -> void:
	_active_unexplored_marker = point.get_node_or_null("UnexploredMarker") as CanvasItem
	if _active_unexplored_marker != null:
		_active_unexplored_marker.hide()


func _on_observation_cancelled_restore_marker() -> void:
	if _active_unexplored_marker != null:
		_active_unexplored_marker.show()
	_active_unexplored_marker = null


func _on_observation_completed_keep_hidden(_observation_id) -> void:
	_active_unexplored_marker = null


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
