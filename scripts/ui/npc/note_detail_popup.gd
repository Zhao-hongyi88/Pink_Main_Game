class_name NoteDetailPopup
extends Control

## NPCBase 内部的资料详情弹窗，只负责显示外部传入的 Note 数据。

signal popup_closed()

@onready var title_label: Label = %TitleLabel
@onready var content_label: Label = %ContentLabel
@onready var close_button: Button = %CloseButton

var current_note_key := ""


func _ready() -> void:
	close_button.pressed.connect(close_popup)
	hide()


func open_note(note_key: String, header: String, content: String) -> void:
	current_note_key = note_key
	title_label.text = header
	content_label.text = content
	show()
	close_button.grab_focus()


func close_popup() -> void:
	if not visible:
		return
	hide()
	popup_closed.emit()

