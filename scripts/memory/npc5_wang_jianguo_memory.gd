class_name NPC5WangJianGuoMemory
extends "res://scripts/memory/memory_base.gd"

## 王建国 Memory 只声明人物专属调查点，公共流程由 MemoryBase 负责。

@onready var community_supplies: Area2D = %CommunitySupplies
@onready var donation_certificates: Area2D = %DonationCertificates
@onready var charity_forum_record: Area2D = %CharityForumRecord


func _ready() -> void:
	super._ready()
	register_observation_points([
		community_supplies,
		donation_certificates,
		charity_forum_record,
	])
