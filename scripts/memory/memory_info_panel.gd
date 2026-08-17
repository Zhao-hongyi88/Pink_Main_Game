class_name MemoryInfoPanel
extends Control

## Presents Object Info followed by the protagonist's observations.
## Emits observation_completed only after Complete and Close is pressed at the end.

signal observation_completed(observation_id)
signal observation_cancelled()

var _current_data = null
var _dialogue_index := -1
var _info_page_index := 0
var _showing_info := true

@onready var info_panel: Panel = $Panel
@onready var dimmer: ColorRect = $Dimmer
@onready var title_label: Label = $Panel/TitleLabel
@onready var section_label: Label = $Panel/SectionLabel
@onready var content_label: Label = $Panel/ContentLabel
@onready var image_placeholders: HBoxContainer = $Panel/ImagePlaceholders
@onready var continue_button: Button = $Panel/ContinueButton
@onready var close_button: Button = $Panel/CloseButton
@onready var custom_info_background: TextureRect = $Panel/CustomInfoBackground
@onready var custom_info_icon: TextureRect = $Panel/CustomInfoIcon
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
	dialogue_box.gui_input.connect(_on_dialogue_box_gui_input)


func show_observation(data) -> void:
	if data == null:
		push_warning("MemoryInfoPanel: Cannot display null data.")
		return

	_current_data = data
	_dialogue_index = -1
	_info_page_index = 0
	_showing_info = true
	title_label.text = data.title
	$Panel.show()
	dialogue_box.hide()
	section_label.text = "Object Info"
	$Panel.show()
	dialogue_box.hide()
	_show_object_info(data)
	_apply_info_skin(data)
	_update_info_continue_button()
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
		if (
			not _current_data.info_pages.is_empty()
			and _info_page_index < _current_data.info_pages.size() - 1
		):
			_info_page_index += 1
			_show_object_info(_current_data)
			_update_info_continue_button()
			continue_button.grab_focus()
			return
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
	dialogue_continue_button.grab_focus()
	section_label.text = "Protagonist's Observation"
	_reset_info_layout()
	image_placeholders.hide()
	content_label.show()
	if _current_data.dialogue.is_empty():
		_complete_and_close()
		return

	content_label.text = _current_data.dialogue[_dialogue_index]
	dialogue_content_label.text = _current_data.dialogue[_dialogue_index]
	if _dialogue_index == _current_data.dialogue.size() - 1:
		dialogue_continue_button.text = "Complete and Close"
	else:
		dialogue_continue_button.text = "Continue"

func _show_object_info(data) -> void:
	$Panel.show()
	dialogue_box.hide()
	_clear_image_placeholders()
	_reset_info_layout()
	var has_images = not data.images.is_empty() or not data.image_placeholders.is_empty()
	var info_text: String = str(data.info)
	if not data.info_pages.is_empty():
		var safe_page_index := clampi(_info_page_index, 0, data.info_pages.size() - 1)
		info_text = data.info_pages[safe_page_index]
		if safe_page_index < data.info_page_titles.size():
			title_label.text = data.info_page_titles[safe_page_index]
	content_label.text = info_text
	content_label.show()
	image_placeholders.visible = has_images

	if not has_images:
		return

	content_label.offset_bottom = -280.0
	image_placeholders.offset_top = 314.0

	var item_count = max(data.images.size(), data.image_placeholders.size())
	for index in item_count:
		var placeholder_text = "[Image]"
		if index < data.image_placeholders.size():
			placeholder_text = data.image_placeholders[index]

		var texture = null
		if index < data.images.size():
			texture = data.images[index]
		_create_image_card(placeholder_text, texture)


func _update_info_continue_button() -> void:
	var is_last_info_page: bool = (
		not _current_data.info_pages.is_empty()
		and _info_page_index == _current_data.info_pages.size() - 1
	)
	if is_last_info_page and _current_data.dialogue.is_empty():
		continue_button.text = "Complete and Close"
	else:
		continue_button.text = "Continue"


func _apply_info_skin(data) -> void:
	var has_custom_skin := data.info_panel_background != null
	if not has_custom_skin:
		_reset_info_skin()
		return

	info_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	dimmer.show()
	info_panel.offset_left = -400.0
	info_panel.offset_top = -220.0
	info_panel.offset_right = 400.0
	info_panel.offset_bottom = 220.0

	custom_info_background.texture = data.info_panel_background
	custom_info_background.show()
	custom_info_icon.texture = data.info_icon
	custom_info_icon.visible = data.info_icon != null

	title_label.offset_left = 100.0
	title_label.offset_top = 32.0
	title_label.offset_right = -40.0
	title_label.offset_bottom = 70.0
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	section_label.hide()

	content_label.offset_left = 80.0
	content_label.offset_top = 96.0
	content_label.offset_right = -80.0
	content_label.offset_bottom = -84.0
	content_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _reset_info_skin() -> void:
	info_panel.remove_theme_stylebox_override("panel")
	dimmer.hide()
	info_panel.offset_left = -320.0
	info_panel.offset_top = -250.0
	info_panel.offset_right = 320.0
	info_panel.offset_bottom = 250.0

	custom_info_background.hide()
	custom_info_background.texture = null
	custom_info_icon.hide()
	custom_info_icon.texture = null

	title_label.offset_left = 28.0
	title_label.offset_top = 20.0
	title_label.offset_right = -28.0
	title_label.offset_bottom = 54.0
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	section_label.show()

	content_label.offset_left = 38.0
	content_label.offset_top = 102.0
	content_label.offset_right = -38.0
	content_label.offset_bottom = -92.0
	content_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT


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
	_info_page_index = 0
	_showing_info = true
	_reset_info_skin()
	$Panel.show()
	dialogue_box.hide()
	hide()


func _complete_and_close() -> void:
	var completed_id = _current_data.observation_id
	_reset_panel()
	observation_completed.emit(completed_id)
