class_name MemoryObservationData
extends Resource

## 单个可调查物品的纯数据资源。

@export var observation_id: StringName
@export var title := ""
@export_multiline var info := ""
@export var info_page_titles: PackedStringArray = []
@export var info_pages: PackedStringArray = []
@export var images: Array[Texture2D] = []
@export var image_placeholders: PackedStringArray = []
@export var dialogue: PackedStringArray = []
@export var info_panel_background: Texture2D
@export var info_icon: Texture2D
