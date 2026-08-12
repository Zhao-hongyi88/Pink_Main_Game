class_name NoteDetailPopup
extends Control

## NPCBase 内部的资料详情弹窗，只负责显示外部传入的 Note 数据。

signal popup_closed()

@onready var title_label: Label = %TitleLabel
@onready var content_label: Label = %ContentLabel
@onready var close_hit_area: TextureButton = %CloseHitArea
@onready var dim_background: ColorRect = %DimBackground
@onready var document_root: Control = %DocumentRoot
@onready var preview_image: TextureRect = %PreviewImage

var current_note_key := ""
var _popup_tween: Tween
var _animation_generation := 0

const ANIMATION_DURATION := 0.25
const CLOSED_DOCUMENT_SCALE := Vector2(0.96, 0.96)


func _ready() -> void:
	close_hit_area.pressed.connect(close_popup)
	dim_background.gui_input.connect(_on_dim_background_gui_input)
	_reset_closed_visual()
	hide()


func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		close_popup()
		get_viewport().set_input_as_handled()


func open_note(
	note_key: String,
	header: String,
	content: String,
	preview_texture: Texture2D = null
) -> void:
	current_note_key = note_key
	title_label.text = header
	content_label.text = content
	# 测试阶段的 NoteCard 仍使用 GradientTexture 占位；详情页保留档案图片占位，
	# 正式图片接入后会直接显示传入的 Texture2D。
	if (
		preview_texture != null
		and preview_texture is not GradientTexture1D
		and preview_texture is not GradientTexture2D
	):
		preview_image.texture = preview_texture
	_start_open_animation()


func _start_open_animation() -> void:
	_cancel_popup_tween()
	_animation_generation += 1
	show()
	dim_background.modulate.a = 1.0
	document_root.modulate.a = 0.0
	document_root.scale = CLOSED_DOCUMENT_SCALE
	_popup_tween = create_tween()
	_popup_tween.set_parallel(true)
	_popup_tween.set_trans(Tween.TRANS_SINE)
	_popup_tween.set_ease(Tween.EASE_OUT)
	_popup_tween.tween_property(document_root, "modulate:a", 1.0, ANIMATION_DURATION)
	_popup_tween.tween_property(
		document_root, "scale", Vector2.ONE, ANIMATION_DURATION
	)
	close_hit_area.grab_focus()


func close_popup() -> void:
	if not visible:
		return
	_cancel_popup_tween()
	_animation_generation += 1
	var close_generation := _animation_generation
	_popup_tween = create_tween()
	_popup_tween.set_parallel(true)
	_popup_tween.set_trans(Tween.TRANS_SINE)
	_popup_tween.set_ease(Tween.EASE_IN)
	_popup_tween.tween_property(document_root, "modulate:a", 0.0, ANIMATION_DURATION)
	_popup_tween.tween_property(
		document_root, "scale", CLOSED_DOCUMENT_SCALE, ANIMATION_DURATION
	)
	_popup_tween.finished.connect(_finish_close.bind(close_generation))


func _finish_close(close_generation: int) -> void:
	if close_generation != _animation_generation:
		return
	_popup_tween = null
	hide()
	_reset_closed_visual()
	popup_closed.emit()


func _cancel_popup_tween() -> void:
	if _popup_tween != null and _popup_tween.is_valid():
		_popup_tween.kill()
	_popup_tween = null


func _reset_closed_visual() -> void:
	dim_background.modulate.a = 1.0
	document_root.modulate.a = 0.0
	document_root.scale = CLOSED_DOCUMENT_SCALE


func _on_dim_background_gui_input(event: InputEvent) -> void:
	if event is not InputEventMouseButton:
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
		close_popup()
		dim_background.accept_event()
