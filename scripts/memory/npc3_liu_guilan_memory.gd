class_name NPC3LiuGuiLanMemory
extends "res://scripts/memory/memory_base.gd"

## 刘桂兰 Memory 只声明人物专属调查点，公共流程由 MemoryBase 负责。

@onready var medical_record: Area2D = %MedicalRecord
@onready var treatment_bill: Area2D = %TreatmentBill
@onready var treatment_bed: Area2D = %TreatmentBed


func _ready() -> void:
	super._ready()
	register_observation_points([
		medical_record,
		treatment_bill,
		treatment_bed,
	])
