class_name MainAxisStep
extends Resource

## 一个可配置的主线节点。未来可将 required_systems 与具体系统注册表对接。

@export var id: StringName
@export var title: String
@export_multiline var summary: String
@export var next_step_id: StringName
@export var scene_route: StringName = &"story"
@export var required_systems: Array[StringName] = []
