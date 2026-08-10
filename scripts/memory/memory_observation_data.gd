class_name MemoryObservationData
extends Resource

## 单个可调查物品的纯数据资源。

@export var observation_id: StringName
@export var title := ""
@export_multiline var info := ""
@export var images: Array[Texture2D] = []
@export var image_placeholders: PackedStringArray = []
@export var dialogue: PackedStringArray = []
