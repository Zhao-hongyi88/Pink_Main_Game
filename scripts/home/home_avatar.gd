class_name HomeAvatar
extends CharacterBody2D

signal movement_started(target_position: Vector2)
signal movement_stopped(final_position: Vector2)

const IDLE_ANIMATION: StringName = &"idle"
const WALK_DOWN_ANIMATION: StringName = &"walk_down"
const WALK_UP_ANIMATION: StringName = &"walk_up"
const WALK_LEFT_ANIMATION: StringName = &"walk_left"
const WALK_RIGHT_ANIMATION: StringName = &"walk_right"
const FIXED_IDLE_POSITION := Vector2(455.0, 535.0)
const SHADOW_TEXTURE: Texture2D = preload("res://TextureAsset/HomeAvatar/home_avatar_shadow.png")

@export_range(1.0, 1000.0, 1.0, "or_greater") var move_speed := 180.0
@export_range(0.0, 100.0, 0.5, "or_greater") var stopping_distance := 6.0

@onready var navigation_agent: NavigationAgent2D = %NavigationAgent2D
@onready var visual: AnimatedSprite2D = %AvatarVisual

var _target_global_position := Vector2.ZERO
var _is_moving := false
var _navigation_ready := false
var _shadow: Sprite2D


func _ready() -> void:
	global_position = FIXED_IDLE_POSITION
	_target_global_position = FIXED_IDLE_POSITION
	_add_ground_shadow()
	navigation_agent.path_desired_distance = maxf(1.0, stopping_distance * 0.5)
	navigation_agent.target_desired_distance = maxf(1.0, stopping_distance)
	_play_visual_animation(IDLE_ANIMATION)
	call_deferred("_enable_navigation_after_sync")


func _add_ground_shadow() -> void:
	_shadow = Sprite2D.new()
	_shadow.name = "GroundShadow"
	_shadow.texture = SHADOW_TEXTURE
	_shadow.position = Vector2(0.0, 4.0)
	_shadow.scale = Vector2(0.22, 0.22)
	_shadow.modulate.a = 0.7
	_shadow.z_index = 0
	add_child(_shadow)
	move_child(_shadow, 0)


func _unhandled_input(_event: InputEvent) -> void:
	pass


func _physics_process(_delta: float) -> void:
	velocity = Vector2.ZERO
	if _is_moving:
		_stop_movement()


func set_movement_target(target_global_position: Vector2) -> void:
	_target_global_position = FIXED_IDLE_POSITION
	_stop_movement()


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
