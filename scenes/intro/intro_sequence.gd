extends Control

const INTRO_LOOP_STREAM: VideoStream = preload("res://Video/Intro/intro_loop.ogv")
const INTRO_STORY_STREAM: VideoStream = preload("res://Video/Intro/intro_story.ogv")
const FADE_DURATION := 0.35

@onready var video_player: VideoStreamPlayer = %VideoPlayer
@onready var start_button: TextureButton = %StartButton
@onready var continue_button: TextureButton = %ContinueButton
@onready var exit_button: TextureButton = %ExitButton
@onready var fade_black: ColorRect = %FadeBlack

var _is_starting_story := false
var _is_playing_story := false


func _ready() -> void:
	MusicManager.stop_bgm()
	fade_black.modulate.a = 0.0
	video_player.stream = INTRO_LOOP_STREAM
	video_player.loop = true
	video_player.play()
	start_button.pressed.connect(_on_start_button_pressed)
	continue_button.pressed.connect(_on_continue_button_pressed)
	exit_button.pressed.connect(_on_exit_button_pressed)
	video_player.finished.connect(_on_video_finished)


func _on_start_button_pressed() -> void:
	if _is_starting_story:
		return
	_is_starting_story = true
	for button in _menu_buttons():
		button.disabled = true
	await _fade_to(1.0)
	video_player.stop()
	for button in _menu_buttons():
		button.hide()
	video_player.stream = INTRO_STORY_STREAM
	video_player.loop = false
	video_player.stream_position = 0.0
	_is_playing_story = true
	video_player.play()
	await _fade_to(0.0)


func _on_continue_button_pressed() -> void:
	print("CONTINUE is not implemented.")


func _on_exit_button_pressed() -> void:
	print("EXIT is not implemented.")


func _menu_buttons() -> Array[TextureButton]:
	return [start_button, continue_button, exit_button]


func _on_video_finished() -> void:
	if not _is_playing_story:
		return
	_is_playing_story = false
	await _fade_to(1.0)
	SceneRouter.go_to(&"home")


func _fade_to(target_alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(fade_black, "modulate:a", target_alpha, FADE_DURATION).set_trans(
		Tween.TRANS_SINE
	).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
