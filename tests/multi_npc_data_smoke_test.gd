extends Node

const NPC_BASE_SCENE_PATH := "res://scenes/npc/npc_base.tscn"
const MEMORY_SCENE_PATH := "res://scenes/memory/memory_test.tscn"

const NPC_CASES: Array[Dictionary] = [
	{
		"path": "res://data/npc/npc_a.json",
		"npc_id": "npc_a",
		"display_name": "NPC_A",
		"dialogue_count": 5,
		"note_count": 5,
	},
	{
		"path": "res://data/npc/npc_b.json",
		"npc_id": "npc_b",
		"display_name": "NPC_B",
		"dialogue_count": 3,
		"note_count": 2,
	},
	{
		"path": "res://data/npc/npc_c.json",
		"npc_id": "npc_c",
		"display_name": "NPC_C",
		"dialogue_count": 4,
		"note_count": 3,
	},
	{
		"path": "res://data/npc/npc_d.json",
		"npc_id": "npc_d",
		"display_name": "NPC_D",
		"dialogue_count": 5,
		"note_count": 2,
	},
	{
		"path": "res://data/npc/npc_e.json",
		"npc_id": "npc_e",
		"display_name": "NPC_E",
		"dialogue_count": 4,
		"note_count": 3,
	},
]


func _ready() -> void:
	GameState.clear_runtime_state()
	assert(ResourceLoader.exists(NPC_BASE_SCENE_PATH, "PackedScene"))
	assert(ResourceLoader.exists(MEMORY_SCENE_PATH, "PackedScene"))

	var npc_scene: PackedScene = load(NPC_BASE_SCENE_PATH)
	var known_npc_ids: Dictionary = {}
	var observed_dialogue_counts: Dictionary = {}
	var observed_note_counts: Dictionary = {}

	for test_case: Dictionary in NPC_CASES:
		var data_path: String = test_case["path"]
		var npc_data := NPCData.load_from_json(data_path)
		assert(npc_data.is_valid(), "%s: %s" % [data_path, npc_data.get_error_message()])
		assert(String(npc_data.npc_id) == test_case["npc_id"])
		assert(not known_npc_ids.has(npc_data.npc_id), "Duplicate npc_id: %s" % npc_data.npc_id)
		known_npc_ids[npc_data.npc_id] = true
		assert(npc_data.display_name == test_case["display_name"])
		assert(npc_data.portrait.is_empty())
		assert(npc_data.memory_scene == MEMORY_SCENE_PATH)
		assert(ResourceLoader.exists(npc_data.memory_scene, "PackedScene"))
		assert(npc_data.dialogues.size() == test_case["dialogue_count"])
		assert(npc_data.notes.size() == test_case["note_count"])
		observed_dialogue_counts[npc_data.dialogues.size()] = true
		observed_note_counts[npc_data.notes.size()] = true

		var note_keys: Dictionary = {}
		for note: Dictionary in npc_data.notes:
			var note_key := str(note["key"])
			assert(not note_key.is_empty())
			assert(not note_keys.has(note_key))
			note_keys[note_key] = true

		for dialogue: Dictionary in npc_data.dialogues:
			var unlock_key := str(dialogue["unlock_key"])
			if not unlock_key.is_empty():
				assert(note_keys.has(unlock_key), "%s references unknown key: %s" % [data_path, unlock_key])

		var name_unlock_key := String(npc_data.name_unlock_key)
		assert(not name_unlock_key.is_empty())
		assert(note_keys.has(name_unlock_key))

		var npc_base := npc_scene.instantiate()
		assert(npc_base is NPCBase)
		npc_base.npc_data_path = data_path
		add_child(npc_base)
		await get_tree().process_frame

		assert(npc_base.npc_data != null)
		assert(npc_base.npc_data.source_path == data_path)
		assert(npc_base.npc_id == npc_data.npc_id)
		assert(npc_base.get_node("%NPCName").text == npc_data.display_name)
		assert(npc_base.get_node("%CharacterArea").texture != null)
		assert(npc_base.dialogue_manager is DialogueManager)
		assert(npc_base.unlock_system is UnlockSystem)
		assert(npc_base._valid_unlock_keys.size() == npc_data.notes.size())
		assert(npc_base._note_items_by_key.size() == npc_data.notes.size())
		assert(npc_base.get_node("%NoteContainer").get_child_count() == npc_data.notes.size())

		remove_child(npc_base)
		npc_base.free()

	assert(known_npc_ids.size() == NPC_CASES.size())
	assert(observed_dialogue_counts.size() > 1)
	assert(observed_note_counts.size() > 1)
	print("MULTI_NPC_DATA_SMOKE_TEST: PASS")
	get_tree().quit(0)
