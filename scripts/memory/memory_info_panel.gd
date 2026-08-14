class_name MemoryInfoPanel
extends Control

## 依序展示“物品信息”与“主角观察”。
## 只有最后一句点击“完成并关闭”时才发出 observation_completed。

signal observation_completed(observation_id)
signal observation_cancelled()

var _current_data = null
var _dialogue_index := -1
var _showing_info := true

@onready var title_label: Label = $Panel/TitleLabel
@onready var section_label: Label = $Panel/SectionLabel
@onready var content_label: Label = $Panel/ContentLabel
@onready var image_placeholders: HBoxContainer = $Panel/ImagePlaceholders
@onready var continue_button: Button = $Panel/ContinueButton
@onready var close_button: Button = $Panel/CloseButton
@onready var dialogue_box: Control = $DialogueBox
@onready var dialogue_content_label: Label = $DialogueBox/DialogueContentLabel
@onready var dialogue_continue_button: Button = $DialogueBox/DialogueContinueButton
@onready var dialogue_close_button: Button = $DialogueBox/DialogueCloseButton


func _ready() -> void:
	hide()
	dialogue_box.hide()
	continue_button.pressed.connect(_on_continue_pressed)
	close_button.pressed.connect(close_without_completion)
	dialogue_continue_button.pressed.connect(_on_continue_pressed)
	dialogue_close_button.pressed.connect(close_without_completion)
<<<<<<< HEAD
	dialogue_box.gui_input.connect(_on_dialogue_box_gui_input)
=======
>>>>>>> 412671b62599c70a0377e5ed355a215f41bab903


func show_observation(data) -> void:
	if data == null:
		push_warning("MemoryInfoPanel: 尝试展示空数据。")
		return

	_current_data = data
	_dialogue_index = -1
	_showing_info = true
	title_label.text = data.title
	$Panel.show()
	dialogue_box.hide()
	section_label.text = "物品信息"
	$Panel.show()
	dialogue_box.hide()
	_show_object_info(data)
	continue_button.text = "继续"
	show()
	continue_button.grab_focus()


func _unhandled_input(event) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close_without_completion()
		get_viewport().set_input_as_handled()


func _on_continue_pressed() -> void:
	if _current_data == null:
		return

	if _showing_info:
		_showing_info = false
		_dialogue_index = 0
		_show_dialogue_line()
		return

	if _dialogue_index < _current_data.dialogue.size() - 1:
		_dialogue_index += 1
		_show_dialogue_line()
		return

	_complete_and_close()


func _on_dialogue_box_gui_input(event: InputEvent) -> void:
	if _showing_info:
		return
	if event is InputEventMouseButton \
		and event.button_index == MOUSE_BUTTON_LEFT \
		and event.pressed:
		_on_continue_pressed()
		dialogue_box.accept_event()


func _show_dialogue_line() -> void:
	$Panel.hide()
	dialogue_box.show()
<<<<<<< HEAD
	dialogue_continue_button.grab_focus()
	section_label.text = "主角观察"
	_reset_info_layout()
	image_placeholders.hide()
	content_label.show()
=======
>>>>>>> 412671b62599c70a0377e5ed355a215f41bab903
	if _current_data.dialogue.is_empty():
		_complete_and_close()
		return

<<<<<<< HEAD
	content_label.text = _current_data.dialogue[_dialogue_index]
=======
>>>>>>> 412671b62599c70a0377e5ed355a215f41bab903
	dialogue_content_label.text = _current_data.dialogue[_dialogue_index]
	if _dialogue_index == _current_data.dialogue.size() - 1:
		dialogue_continue_button.text = "完成并关闭"
	else:
		dialogue_continue_button.text = "继续"

	dialogue_continue_button.text = continue_button.text


func _show_object_info(data) -> void:
	$Panel.show()
	dialogue_box.hide()
	_clear_image_placeholders()
	_reset_info_layout()
	var has_images = not data.images.is_empty() or not data.image_placeholders.is_empty()
	content_label.text = data.info
	content_label.show()
	image_placeholders.visible = has_images

	if not has_images:
		return

	content_label.offset_bottom = -280.0
	image_placeholders.offset_top = 314.0

	var item_count = max(data.images.size(), data.image_placeholders.size())
	for index in item_count:
		var placeholder_text = "[图片]"
		if index < data.image_placeholders.size():
			placeholder_text = data.image_placeholders[index]

		var texture = null
		if index < data.images.size():
			texture = data.images[index]
		_create_image_card(placeholder_text, texture)


func _reset_info_layout() -> void:
	content_label.offset_bottom = -92.0
	image_placeholders.offset_top = 126.0


func _clear_image_placeholders() -> void:
	for child in image_placeholders.get_children():
		child.queue_free()


func _create_image_card(placeholder_text, texture) -> void:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(160, 140)
	var layout = VBoxContainer.new()
	card.add_child(layout)

	if texture != null:
		var image = TextureRect.new()
		image.texture = texture
		image.custom_minimum_size = Vector2(140, 96)
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		layout.add_child(image)

	var caption = Label.new()
	caption.text = placeholder_text
	caption.custom_minimum_size = Vector2(140, 0)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(caption)
	image_placeholders.add_child(card)


func close_without_completion() -> void:
	var has_active_observation = _current_data != null
	_reset_panel()
	if has_active_observation:
		observation_cancelled.emit()


func _reset_panel() -> void:
	_current_data = null
	_dialogue_index = -1
	_showing_info = true
<<<<<<< HEAD
=======
	$Panel.show()
>>>>>>> 412671b62599c70a0377e5ed355a215f41bab903
	dialogue_box.hide()
	hide()


func _complete_and_close() -> void:
	var completed_id = _current_data.observation_id
	_reset_panel()
	observation_completed.emit(completed_id)
