class_name MainAxisDefinition
extends Resource

## 主线流程的静态定义。顺序、页面和系统需求全部由资源配置。

@export var initial_step_id: StringName
@export var steps: Array[MainAxisStep] = []


func get_step(step_id: StringName) -> MainAxisStep:
	for step in steps:
		if step != null and step.id == step_id:
			return step
	return null


func get_step_index(step_id: StringName) -> int:
	for index in steps.size():
		if steps[index] != null and steps[index].id == step_id:
			return index
	return -1


func validate_definition() -> PackedStringArray:
	var errors := PackedStringArray()
	var known_ids: Dictionary = {}
	for step in steps:
		if step == null:
			errors.append("主线中存在空节点。")
			continue
		if step.id.is_empty():
			errors.append("主线节点 ID 不能为空。")
		elif known_ids.has(step.id):
			errors.append("主线节点 ID 重复：%s" % step.id)
		else:
			known_ids[step.id] = true
	if not known_ids.has(initial_step_id):
		errors.append("起始节点不存在：%s" % initial_step_id)
	for step in steps:
		if step != null and not step.next_step_id.is_empty() and not known_ids.has(step.next_step_id):
			errors.append("节点 %s 指向不存在的后续节点 %s" % [step.id, step.next_step_id])
	return errors
