class_name StartTransitionLayer
extends CanvasLayer

## START 专属转场表现层。导航和 payload 仍由 SceneRouter 负责。

@export_range(0.01, 2.0, 0.01) var move_duration := 0.45
@export_range(0.01, 1.0, 0.01) var loading_fade_duration := 0.2
@export_range(0.01, 1.0, 0.01) var center_hold_duration := 0.25
@export_range(0.01, 1.0, 0.01) var grow_duration := 0.35
@export_range(0.01, 2.0, 0.01) var reveal_duration := 0.55
@export_range(0.1, 10.0, 0.1) var gear_rotation_speed := 3.2
@export_range(1.0, 2.0, 0.01) var center_gear_scale := 1.18
@export_range(0.1, 2.0, 0.01) var reveal_max_radius := 1.2

@onready var transition_root: Control = %TransitionRoot
@onready var dim_overlay: ColorRect = %DimOverlay
@onready var reveal_overlay: ColorRect = %RevealOverlay
@onready var gear_back: TextureRect = %GearBack
@onready var gear_front: TextureRect = %GearFront
@onready var loading_label: Label = %LoadingLabel

var current_phase: StringName = &"idle"
var last_transition_started := false
var last_center_reached := false
var last_reveal_completed := false

var _stage_tween: Tween
var _gear_rotation_tween: Tween
var _source_gear_back: CanvasItem
var _source_gear_front: CanvasItem
var _source_back_visible := true
var _source_front_visible := true


func _ready() -> void:
	_reset_visual_state()


func play_out(source_scene: Node) -> bool:
	var start_button := _find_start_button(source_scene)
	if start_button == null:
		push_warning("StartTransitionLayer: 当前场景没有可用的 StartButton，回退普通转场。")
		return false
	var source_back := start_button.get_node_or_null("Gear_Back") as TextureRect
	var source_front := start_button.get_node_or_null("Gear_Front") as TextureRect
	if source_back == null or source_front == null:
		push_warning("StartTransitionLayer: StartButton 缺少双齿轮节点，回退普通转场。")
		return false

	_kill_tweens()
	_capture_source_gears(source_back, source_front)
	last_transition_started = true
	last_center_reached = false
	last_reveal_completed = false
	current_phase = &"move_to_center"
	transition_root.show()
	transition_root.mouse_filter = Control.MOUSE_FILTER_STOP
	reveal_overlay.hide()
	dim_overlay.modulate.a = 0.0
	loading_label.show()
	loading_label.modulate.a = 0.0
	gear_back.show()
	gear_front.show()

	var viewport_center := get_viewport().get_visible_rect().size * 0.5
	var back_target := viewport_center - gear_back.size * 0.5 + Vector2(-26.0, -4.0)
	var front_target := viewport_center - gear_front.size * 0.5 + Vector2(30.0, 18.0)
	_stage_tween = create_tween()
	_stage_tween.set_parallel(true)
	_stage_tween.set_trans(Tween.TRANS_SINE)
	_stage_tween.set_ease(Tween.EASE_IN_OUT)
	_stage_tween.tween_property(gear_back, "position", back_target, move_duration)
	_stage_tween.tween_property(gear_front, "position", front_target, move_duration)
	_stage_tween.tween_property(dim_overlay, "modulate:a", 1.0, move_duration)
	_stage_tween.tween_property(
		loading_label,
		"modulate:a",
		1.0,
		loading_fade_duration
	)
	await _stage_tween.finished

	last_center_reached = true
	current_phase = &"center_spin"
	_start_gear_rotation()
	_stage_tween = create_tween()
	_stage_tween.set_parallel(true)
	_stage_tween.set_trans(Tween.TRANS_SINE)
	_stage_tween.set_ease(Tween.EASE_OUT)
	_stage_tween.tween_property(
		gear_back,
		"scale",
		Vector2.ONE * center_gear_scale,
		grow_duration
	)
	_stage_tween.tween_property(
		gear_front,
		"scale",
		Vector2.ONE * center_gear_scale,
		grow_duration
	)
	await _stage_tween.finished
	await get_tree().create_timer(center_hold_duration).timeout
	return true


func reveal_new_scene() -> void:
	current_phase = &"reveal"
	_set_reveal_radius(0.0)
	reveal_overlay.show()
	dim_overlay.modulate.a = 0.0
	_stage_tween = create_tween()
	_stage_tween.set_parallel(true)
	_stage_tween.set_trans(Tween.TRANS_SINE)
	_stage_tween.set_ease(Tween.EASE_IN_OUT)
	_stage_tween.tween_method(_set_reveal_radius, 0.0, reveal_max_radius, reveal_duration)
	_stage_tween.tween_property(
		loading_label,
		"modulate:a",
		0.0,
		minf(loading_fade_duration, reveal_duration)
	)
	_stage_tween.tween_property(
		gear_back,
		"modulate:a",
		0.0,
		minf(grow_duration, reveal_duration)
	)
	_stage_tween.tween_property(
		gear_front,
		"modulate:a",
		0.0,
		minf(grow_duration, reveal_duration)
	)
	await _stage_tween.finished
	last_reveal_completed = true
	_finish_transition()


func cancel_transition() -> void:
	_restore_source_gears()
	_finish_transition()


func is_active() -> bool:
	return transition_root.visible


func is_input_locked() -> bool:
	return transition_root.visible and transition_root.mouse_filter == Control.MOUSE_FILTER_STOP


func get_screen_center() -> Vector2:
	return get_viewport().get_visible_rect().size * 0.5


func _find_start_button(source_scene: Node) -> Control:
	if source_scene == null:
		return null
	var start_button := source_scene.get_node_or_null("%StartButton") as Control
	if start_button == null:
		start_button = source_scene.find_child("StartButton", true, false) as Control
	return start_button


func _capture_source_gears(source_back: TextureRect, source_front: TextureRect) -> void:
	_source_gear_back = source_back
	_source_gear_front = source_front
	_source_back_visible = source_back.visible
	_source_front_visible = source_front.visible
	_copy_gear_visual(source_back, gear_back)
	_copy_gear_visual(source_front, gear_front)
	_source_gear_back.hide()
	_source_gear_front.hide()


func _copy_gear_visual(source: TextureRect, target: TextureRect) -> void:
	var source_rect := source.get_global_rect()
	target.texture = source.texture
	target.size = source_rect.size
	target.position = source_rect.position
	target.pivot_offset = target.size * 0.5
	target.rotation = source.rotation
	target.scale = Vector2.ONE
	target.modulate = source.modulate


func _start_gear_rotation() -> void:
	if _gear_rotation_tween != null and _gear_rotation_tween.is_valid():
		_gear_rotation_tween.kill()
	var rotation_duration := TAU / maxf(gear_rotation_speed, 0.001)
	_gear_rotation_tween = create_tween()
	_gear_rotation_tween.set_loops()
	_gear_rotation_tween.set_parallel(true)
	_gear_rotation_tween.tween_property(
		gear_back,
		"rotation",
		TAU,
		rotation_duration
	).as_relative().set_trans(Tween.TRANS_LINEAR)
	_gear_rotation_tween.tween_property(
		gear_front,
		"rotation",
		-TAU,
		rotation_duration
	).as_relative().set_trans(Tween.TRANS_LINEAR)


func _set_reveal_radius(radius: float) -> void:
	var shader_material := reveal_overlay.material as ShaderMaterial
	if shader_material != null:
		shader_material.set_shader_parameter("radius", radius)


func _restore_source_gears() -> void:
	if is_instance_valid(_source_gear_back):
		_source_gear_back.visible = _source_back_visible
	if is_instance_valid(_source_gear_front):
		_source_gear_front.visible = _source_front_visible


func _finish_transition() -> void:
	_kill_tweens()
	transition_root.hide()
	transition_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reveal_overlay.hide()
	loading_label.hide()
	gear_back.hide()
	gear_front.hide()
	_source_gear_back = null
	_source_gear_front = null
	current_phase = &"idle"


func _kill_tweens() -> void:
	if _stage_tween != null and _stage_tween.is_valid():
		_stage_tween.kill()
	if _gear_rotation_tween != null and _gear_rotation_tween.is_valid():
		_gear_rotation_tween.kill()
	_stage_tween = null
	_gear_rotation_tween = null


func _reset_visual_state() -> void:
	transition_root.hide()
	transition_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim_overlay.modulate.a = 0.0
	reveal_overlay.hide()
	_set_reveal_radius(0.0)
	gear_back.hide()
	gear_front.hide()
	loading_label.hide()
	current_phase = &"idle"
