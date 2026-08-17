class_name HomeAvatar
extends CharacterBody2D

signal movement_started(target_position: Vector2)
signal movement_stopped(final_position: Vector2)

const IDLE_ANIMATION: StringName = &"idle"
const WALK_DOWN_ANIMATION: StringName = &"walk_down"
const WALK_UP_ANIMATION: StringName = &"walk_up"
const WALK_LEFT_ANIMATION: StringName = &"walk_left"
const WALK_RIGHT_ANIMATION: StringName = &"walk_right"

@export_range(1.0, 1000.0, 1.0, "or_greater") var move_speed := 180.0
@export_range(0.0, 100.0, 0.5, "or_greater") var stopping_distance := 6.0

@onready var navigation_agent: NavigationAgent2D = %NavigationAgent2D
@onready var visual: AnimatedSprite2D = %AvatarVisual

var _target_global_position := Vector2.ZERO
var _is_moving := false
var _navigation_ready := false


func _ready() -> void:
	_target_global_position = global_position
	navigation_agent.path_desired_distance = maxf(1.0, stopping_distance * 0.5)
	navigation_agent.target_desired_distance = maxf(1.0, stopping_distance)
	_play_visual_animation(IDLE_ANIMATION)
	call_deferred("_enable_navigation_after_sync")


func _unhandled_input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event == null:
		return
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
		return

	var canvas_transform := get_viewport().get_canvas_transform()
	var target_global_position := canvas_transform.affine_inverse() * mouse_event.position
	set_movement_target(target_global_position)
	get_viewport().set_input_as_handled()


func _physics_process(_delta: float) -> void:
	if not _is_moving or not _navigation_ready:
		velocity = Vector2.ZERO
		return
	if global_position.distance_to(_target_global_position) <= stopping_distance:
		_stop_movement()
		return

	var next_path_position := navigation_agent.get_next_path_position()
	if navigation_agent.is_navigation_finished():
		_stop_movement()
		return

	var movement_direction := global_position.direction_to(next_path_position)
	if movement_direction.is_zero_approx():
		velocity = Vector2.ZERO
		return
	velocity = movement_direction * move_speed
	_update_movement_animation(velocity)
	move_and_slide()

	if global_position.distance_to(_target_global_position) <= stopping_distance:
		_stop_movement()


func set_movement_target(target_global_position: Vector2) -> void:
	_target_global_position = target_global_position
	_is_moving = true
	_update_movement_animation(global_position.direction_to(_target_global_position))
	if _navigation_ready:
		navigation_agent.target_position = _target_global_position
	movement_started.emit(_target_global_position)


func get_movement_target() -> Vector2:
	return _target_global_position


func is_moving() -> bool:
	return _is_moving


func stop_movement() -> void:
	_stop_movement()


func _enable_navigation_after_sync() -> void:
	await get_tree().physics_frame
	_navigation_ready = true
	if _is_moving:
		navigation_agent.target_position = _target_global_position


func _update_movement_animation(movement_velocity: Vector2) -> void:
	var direction := movement_velocity.normalized()
	if absf(direction.x) > absf(direction.y):
		if direction.x > 0.0:
			_play_visual_animation(WALK_RIGHT_ANIMATION)
		else:
			_play_visual_animation(WALK_LEFT_ANIMATION)
	elif direction.y > 0.0:
		_play_visual_animation(WALK_DOWN_ANIMATION)
	else:
		_play_visual_animation(WALK_UP_ANIMATION)


func _play_visual_animation(animation_name: StringName) -> void:
	if visual.animation == animation_name and visual.is_playing():
		return
	visual.play(animation_name)


func _stop_movement() -> void:
	var was_moving := _is_moving
	_is_moving = false
	velocity = Vector2.ZERO
	_play_visual_animation(IDLE_ANIMATION)
	if was_moving:
		movement_stopped.emit(global_position)
