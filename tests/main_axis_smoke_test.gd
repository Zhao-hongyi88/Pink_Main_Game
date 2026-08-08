extends Node

## 可通过命令行运行的主轴闭环冒烟测试。


func _ready() -> void:
	assert(MainAxisService.definition.steps.size() == 3)
	assert(MainAxisService.definition.validate_definition().is_empty())

	assert(MainAxisService.start_new_run())
	assert(MainAxisService.get_current_step().id == &"prologue")
	assert(SaveService.has_save())

	assert(MainAxisService.advance_current_step())
	assert(MainAxisService.get_current_step().id == &"investigation")
	assert(MainAxisService.completed_step_ids == [&"prologue"])

	# 清空内存状态，确认继续游戏确实从文件恢复，而非沿用当前值。
	MainAxisService.current_step_id = &""
	MainAxisService.completed_step_ids.clear()
	MainAxisService.has_active_run = false
	assert(MainAxisService.resume_run())
	assert(MainAxisService.get_current_step().id == &"investigation")
	assert(MainAxisService.completed_step_ids == [&"prologue"])

	assert(MainAxisService.advance_current_step())
	assert(MainAxisService.get_current_step().id == &"recollection")
	assert(MainAxisService.advance_current_step())
	assert(MainAxisService.is_run_completed)
	assert(not MainAxisService.has_active_run)
	assert(MainAxisService.completed_step_ids.size() == 3)

	print("MAIN_AXIS_SMOKE_TEST: PASS")
	get_tree().quit(0)
