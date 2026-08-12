class_name NPC2LiLeiMemory
extends "res://scripts/memory/memory_base.gd"

## 李磊 Memory 只声明人物专属调查点，公共流程由 MemoryBase 负责。

@onready var attendance_record: Area2D = %AttendanceRecord
@onready var computer_idle_time: Area2D = %ComputerIdleTime
@onready var rental_contract: Area2D = %RentalContract


func _ready() -> void:
	super._ready()
	register_observation_points([
		attendance_record,
		computer_idle_time,
		rental_contract,
	])
