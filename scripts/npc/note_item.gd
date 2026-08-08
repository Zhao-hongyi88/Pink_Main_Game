class_name NoteItem
extends Control

## 可复用资料便利贴。只负责把外部数据写入两个 Label。

@onready var note_header: Label = %NoteHeader
@onready var note_content: Label = %NoteContent

var _pending_header := ""
var _pending_content := ""


func _ready() -> void:
	_apply_text()


func setup(header: String, content: String) -> void:
	_pending_header = header
	_pending_content = content
	if is_node_ready():
		_apply_text()


func _apply_text() -> void:
	note_header.text = _pending_header
	note_content.text = _pending_content
