class_name NoteItem
extends Button

## 可复用的可点击资料卡。完整数据仅用于弹窗，卡面只显示标题与摘要。

signal note_selected(note_key: String, header: String, content: String)

@export_range(12, 120, 1) var summary_length := 42

@onready var note_header: Label = %NoteHeader
@onready var note_content: Label = %NoteContent

var note_key := ""
var full_header := ""
var full_content := ""


func _ready() -> void:
	pressed.connect(_on_pressed)
	_apply_text()


func setup(header: String, content: String, key: String = "") -> void:
	note_key = key
	full_header = header
	full_content = content
	if is_node_ready():
		_apply_text()


func _apply_text() -> void:
	note_header.text = full_header
	note_content.text = _make_summary(full_content)
	tooltip_text = full_header


func _make_summary(content: String) -> String:
	var normalized := content.replace("\r", " ").replace("\n", " ").strip_edges()
	if normalized.length() <= summary_length:
		return normalized
	return normalized.left(summary_length).strip_edges() + "…"


func _on_pressed() -> void:
	note_selected.emit(note_key, full_header, full_content)
