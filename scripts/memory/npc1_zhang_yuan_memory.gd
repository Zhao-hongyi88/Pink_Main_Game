class_name NPC1ZhangYuanMemory
extends "res://scripts/memory/memory_base.gd"

## Zhang Yuan Memory only declares character-specific observation points; MemoryBase owns the shared flow.

const GRADUATION_CERTIFICATE_TEXTURE: Texture2D = preload(
	"res://TextureAsset/Memory/NPC1/graduation_certificate_content.png"
)
var _graduation_certificate_dialogue := PackedStringArray([
	"This certificate records his experience of completing his studies.",
	"From this, it seems that he has the educational background and abilities required.",
])
const AWARD_CERTIFICATE_TEXTURE: Texture2D = preload(
	"res://TextureAsset/Memory/NPC1/award_certificate_content.png"
)
var _award_certificate_dialogue := PackedStringArray([
	"These are awards for outstanding students and competitions that he received during university. It seems that he was an excellent student.",
])

@onready var personal_practice_report: MemoryObservationPoint = %PersonalPracticeReport
@onready var time_loan_application: MemoryObservationPoint = %TimeLoanApplication
@onready var job_search_record: MemoryObservationPoint = %JobSearchRecord
@onready var graduation_certificate_marker: Area2D = %GraduationCertificateMarker
@onready var award_certificate_marker: Area2D = %AwardCertificateMarker

var _active_unexplored_marker: CanvasItem
var _active_observation_id: StringName = &""


func _ready() -> void:
	super._ready()
	register_observation_points([
		personal_practice_report,
		time_loan_application,
		job_search_record,
	])
	personal_practice_report.observation_requested.connect(_on_observation_opened.bind(personal_practice_report))
	time_loan_application.observation_requested.connect(_on_observation_opened.bind(time_loan_application))
	job_search_record.observation_requested.connect(_on_observation_opened.bind(job_search_record))
	graduation_certificate_marker.input_event.connect(
		_on_secondary_marker_input.bind(
			GRADUATION_CERTIFICATE_TEXTURE,
			_graduation_certificate_dialogue,
			graduation_certificate_marker
		)
	)
	award_certificate_marker.input_event.connect(
		_on_secondary_marker_input.bind(
			AWARD_CERTIFICATE_TEXTURE,
			_award_certificate_dialogue,
			award_certificate_marker
		)
	)
	graduation_certificate_marker.mouse_entered.connect(_on_secondary_marker_mouse_entered)
	graduation_certificate_marker.mouse_exited.connect(_on_secondary_marker_mouse_exited)
	award_certificate_marker.mouse_entered.connect(_on_secondary_marker_mouse_entered)
	award_certificate_marker.mouse_exited.connect(_on_secondary_marker_mouse_exited)
	%MemoryInfoPanel.observation_cancelled.connect(_on_observation_cancelled_restore_marker)
	%MemoryInfoPanel.observation_completed.connect(_on_observation_completed_keep_hidden)


func _on_observation_opened(data, point: MemoryObservationPoint) -> void:
	_active_observation_id = data.observation_id if data != null else &""
	_active_unexplored_marker = point.get_node_or_null("UnexploredMarker") as CanvasItem
	if _active_unexplored_marker != null:
		_active_unexplored_marker.hide()


func _on_observation_cancelled_restore_marker() -> void:
	if (
		_active_unexplored_marker != null
		and not is_observed(_active_observation_id)
	):
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
	dialogue: PackedStringArray = PackedStringArray(),
	marker: Area2D = null
) -> void:
	if event is InputEventMouseButton \
		and event.button_index == MOUSE_BUTTON_LEFT \
		and event.pressed:
		if dialogue.is_empty():
			%MemoryInfoPanel.show_standalone_image(texture)
		else:
			%MemoryInfoPanel.show_standalone_image_with_dialogue(texture, dialogue)
		if marker != null:
			marker.hide()
			marker.set_deferred("input_pickable", false)
		get_viewport().set_input_as_handled()


func _on_secondary_marker_mouse_entered() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)


func _on_secondary_marker_mouse_exited() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
