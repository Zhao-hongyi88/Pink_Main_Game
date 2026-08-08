extends Control

@onready var progress_label: Label = %ProgressLabel
@onready var step_title_label: Label = %StepTitleLabel
@onready var step_summary_label: Label = %StepSummaryLabel
@onready var systems_label: Label = %SystemsLabel
@onready var complete_button: Button = %CompleteButton
@onready var state_label: Label = %StateLabel


func _ready() -> void:
	MainAxisService.current_step_changed.connect(_display_step)
	MainAxisService.run_completed.connect(_display_completion)
	if MainAxisService.is_run_completed:
		_display_completion()
	else:
		var current_step := MainAxisService.get_current_step()
		if current_step == null:
			MainAxisService.start_new_run()
			current_step = MainAxisService.get_current_step()
		_display_step(current_step)
	complete_button.grab_focus()


func _display_step(step: MainAxisStep) -> void:
	if step == null:
		return
	progress_label.text = MainAxisService.get_progress_text()
	step_title_label.text = step.title
	step_summary_label.text = step.summary
	if step.required_systems.is_empty():
		systems_label.text = "本节点不依赖其他系统"
	else:
		var names := PackedStringArray()
		for system_id in step.required_systems:
			names.append(_get_system_display_name(system_id))
		systems_label.text = "预留接入：" + " / ".join(names)
	state_label.text = "节点已加载，等待游戏内容接管完成条件。"
	complete_button.text = "完成当前占位节点"
	complete_button.disabled = false


func _display_completion() -> void:
	progress_label.text = MainAxisService.get_progress_text()
	step_title_label.text = "本阶段流程完成"
	step_summary_label.text = "主页、主线推进与自动存档已形成可运行闭环。后续系统可以按节点逐步接入。"
	systems_label.text = "NPC / 对话 / 证据 / 回忆接口均保留"
	state_label.text = "占位主线已经结束。"
	complete_button.text = "返回主页"
	complete_button.disabled = false


func _on_complete_pressed() -> void:
	if MainAxisService.is_run_completed:
		SceneRouter.go_to(&"home")
		return
	if not MainAxisService.advance_current_step():
		state_label.text = "无法推进节点，请查看调试输出。"


func _on_home_pressed() -> void:
	SceneRouter.go_to(&"home")


func _get_system_display_name(system_id: StringName) -> String:
	var labels := {
		&"npc": "NPC",
		&"dialogue": "对话",
		&"evidence": "证据",
		&"memory": "回忆",
	}
	return labels.get(system_id, String(system_id))
