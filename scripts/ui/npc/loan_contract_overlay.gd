class_name LoanContractOverlay
extends Control

## Reusable contract viewer. Contract content is supplied by NPCData; the stamp
## remains a separate texture layer so its first-open impact can be animated.

signal closed()
signal stamp_impact()
signal stamp_animation_finished()

const DROP_DURATION := 0.16
const SHAKE_STEP_DURATION := 0.035
const REBOUND_STEP_DURATION := 0.055

@onready var dim_background: ColorRect = %DimBackground
@onready var contract_root: Control = %ContractRoot
@onready var contract_texture: TextureRect = %ContractTexture
@onready var approval_stamp: TextureRect = %ApprovalStamp
@onready var close_button: Button = %CloseButton

var _contract_final_position := Vector2.ZERO
var _stamp_final_position := Vector2.ZERO
var _close_enabled := false
var _stamp_animation_played := false
var _shake_played := false
var _stamp_tween: Tween
var _impact_tween: Tween
var _rebound_tween: Tween


func _ready() -> void:
	dim_background.gui_input.connect(_on_dim_background_gui_input)
	close_button.pressed.connect(request_close)
	_contract_final_position = contract_root.position
	_stamp_final_position = approval_stamp.position
	hide()


func open_contract(
	content_texture: Texture2D,
	stamp_texture: Texture2D,
	already_stamped: bool
) -> bool:
	if content_texture == null or stamp_texture == null:
		push_error("LoanContractOverlay: contract and stamp textures are required.")
		return false

	_cancel_tweens()
	contract_texture.texture = content_texture
	approval_stamp.texture = stamp_texture
	contract_root.position = _contract_final_position
	contract_root.scale = Vector2.ONE
	approval_stamp.position = _stamp_final_position
	approval_stamp.scale = Vector2.ONE
	approval_stamp.modulate.a = 1.0
	_stamp_animation_played = false
	_shake_played = false
	_close_enabled = already_stamped
	close_button.disabled = not _close_enabled
	show()
	move_to_front()

	if already_stamped:
		approval_stamp.show()
	else:
		approval_stamp.hide()
		call_deferred("_play_stamp_animation")
	return true


func request_close() -> void:
	if not visible or not _close_enabled:
		return
	_cancel_tweens()
	hide()
	closed.emit()


func was_stamp_animation_played() -> bool:
	return _stamp_animation_played


func was_shake_played() -> bool:
	return _shake_played


func _unhandled_input(event: InputEvent) -> void:
	if visible and _close_enabled and event.is_action_pressed("ui_cancel"):
		request_close()
		get_viewport().set_input_as_handled()


func _play_stamp_animation() -> void:
	if not visible:
		return
	_stamp_animation_played = true
	approval_stamp.show()
	approval_stamp.position = _stamp_final_position + Vector2(0.0, -72.0)
	approval_stamp.scale = Vector2(1.18, 1.18)
	approval_stamp.modulate.a = 0.0

	_stamp_tween = create_tween()
	_stamp_tween.set_parallel(true)
	_stamp_tween.set_trans(Tween.TRANS_QUART)
	_stamp_tween.set_ease(Tween.EASE_IN)
	_stamp_tween.tween_property(
		approval_stamp,
		"position",
		_stamp_final_position,
		DROP_DURATION
	)
	_stamp_tween.tween_property(
		approval_stamp,
		"scale",
		Vector2(0.95, 0.95),
		DROP_DURATION
	)
	_stamp_tween.tween_property(approval_stamp, "modulate:a", 1.0, DROP_DURATION)
	await _stamp_tween.finished
	_stamp_tween = null
	if not visible:
		return

	stamp_impact.emit()
	await _play_impact_feedback()
	if not visible:
		return
	_close_enabled = true
	close_button.disabled = false
	stamp_animation_finished.emit()


func _play_impact_feedback() -> void:
	_shake_played = true
	_impact_tween = create_tween()
	_impact_tween.tween_property(
		contract_root,
		"position",
		_contract_final_position + Vector2(6.0, 2.0),
		SHAKE_STEP_DURATION
	)
	_impact_tween.tween_property(
		contract_root,
		"position",
		_contract_final_position + Vector2(-4.0, -1.0),
		SHAKE_STEP_DURATION
	)
	_impact_tween.tween_property(
		contract_root,
		"position",
		_contract_final_position + Vector2(2.0, 0.0),
		SHAKE_STEP_DURATION
	)
	_impact_tween.tween_property(
		contract_root,
		"position",
		_contract_final_position,
		SHAKE_STEP_DURATION
	)

	_rebound_tween = create_tween()
	_rebound_tween.tween_property(
		approval_stamp,
		"scale",
		Vector2(1.02, 1.02),
		REBOUND_STEP_DURATION
	)
	_rebound_tween.tween_property(
		approval_stamp,
		"scale",
		Vector2.ONE,
		REBOUND_STEP_DURATION
	)

	await _impact_tween.finished
	_impact_tween = null
	contract_root.position = _contract_final_position
	_rebound_tween = null
	approval_stamp.position = _stamp_final_position
	approval_stamp.scale = Vector2.ONE


func _on_dim_background_gui_input(event: InputEvent) -> void:
	if event is not InputEventMouseButton:
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
		request_close()
		dim_background.accept_event()


func _cancel_tweens() -> void:
	if _stamp_tween != null and _stamp_tween.is_valid():
		_stamp_tween.kill()
	if _impact_tween != null and _impact_tween.is_valid():
		_impact_tween.kill()
	if _rebound_tween != null and _rebound_tween.is_valid():
		_rebound_tween.kill()
	_stamp_tween = null
	_impact_tween = null
	_rebound_tween = null
