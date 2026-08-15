extends Node

const NPC_BASE_SCENE_PATH := "res://scenes/npc/npc_base.tscn"

const NPC_CASES: Array[Dictionary] = [
	{
		"path": "res://data/npc/npc_a.json",
		"npc_id": "npc_zhang_yuan",
		"display_name": "Ryan Miller",
		"dialogue_name": "Ryan",
		"profile_photo": "res://TextureAsset/NPC/Profile/ryan_profile.png",
		"first_speaker_name": "Me",
		"memory_scene": "res://scenes/memory/npc1_zhang_yuan_memory.tscn",
		"dialogue_count": 11,
		"note_count": 5,
		"dialogue_complete_on_end": true,
	},
	{
		"path": "res://data/npc/npc_b.json",
		"npc_id": "npc_li_lei",
		"display_name": "Mike Carter",
		"dialogue_name": "Mike",
		"profile_photo": "res://TextureAsset/NPC/Profile/mike_profile.png",
		"first_speaker_name": "???",
		"memory_scene": "res://scenes/memory/npc2_li_lei_memory.tscn",
		"dialogue_count": 3,
		"note_count": 2,
		"dialogue_complete_on_end": true,
	},
	{
		"path": "res://data/npc/npc_c.json",
		"npc_id": "npc_liu_guilan",
		"display_name": "Mary Carter",
		"dialogue_name": "Mary",
		"profile_photo": "res://TextureAsset/NPC/Profile/mary_profile.png",
		"first_speaker_name": "???",
		"memory_scene": "res://scenes/memory/npc3_liu_guilan_memory.tscn",
		"dialogue_count": 4,
		"note_count": 3,
		"dialogue_complete_on_end": true,
	},
	{
		"path": "res://data/npc/npc_d.json",
		"npc_id": "npc_su_qing",
		"display_name": "Lisa Wilson",
		"dialogue_name": "Lisa",
		"profile_photo": "res://TextureAsset/NPC/Profile/lisa_profile.png",
		"first_speaker_name": "???",
		"memory_scene": "res://scenes/memory/npc4_su_qing_memory.tscn",
		"dialogue_count": 5,
		"note_count": 2,
		"dialogue_complete_on_end": true,
	},
	{
		"path": "res://data/npc/npc_e.json",
		"npc_id": "npc_wang_jianguo",
		"display_name": "Tom Brown",
		"dialogue_name": "Tom",
		"profile_photo": "res://TextureAsset/NPC/Profile/tom_profile.png",
		"first_speaker_name": "???",
		"memory_scene": "res://scenes/memory/npc5_wang_jianguo_memory.tscn",
		"dialogue_count": 4,
		"note_count": 3,
		"dialogue_complete_on_end": true,
	},
]


func _ready() -> void:
	GameState.clear_runtime_state()
	assert(ResourceLoader.exists(NPC_BASE_SCENE_PATH, "PackedScene"))

	var npc_scene: PackedScene = load(NPC_BASE_SCENE_PATH)
	var known_npc_ids: Dictionary = {}
	var known_profile_photos: Dictionary = {}
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
		assert(npc_data.dialogue_name == test_case["dialogue_name"])
		assert(npc_data.profile_photo == test_case["profile_photo"])
		assert(not known_profile_photos.has(npc_data.profile_photo))
		known_profile_photos[npc_data.profile_photo] = true
		assert(ResourceLoader.exists(npc_data.profile_photo, "Texture2D"))
		assert(load(npc_data.profile_photo) is Texture2D)
		assert(npc_data.dialogue_complete_on_end == test_case["dialogue_complete_on_end"])
		assert(npc_data.memory_scene == test_case["memory_scene"])
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
		assert(npc_base.get_node("%NPCName").text == test_case["first_speaker_name"])
		assert(npc_base.get_node("%SpeakerName").text == test_case["first_speaker_name"])
		assert(npc_base.get_node_or_null("CharacterLayer") == null)
		assert(npc_base.get_node_or_null("%CharacterPortrait") == null)
		var profile_photo := npc_base.get_node("%ProfilePhoto") as TextureRect
		assert(profile_photo != null)
		assert(profile_photo.texture != null)
		assert(profile_photo.texture.resource_path == test_case["profile_photo"])
		assert(profile_photo.mouse_filter == Control.MOUSE_FILTER_IGNORE)
		assert(npc_base.get_node("Background") is TextureRect)
		assert(npc_base.dialogue_manager is DialogueManager)
		assert(npc_base.unlock_system is UnlockSystem)
		assert(npc_base._valid_unlock_keys.size() == npc_data.notes.size())
		assert(npc_base._note_items_by_key.size() == npc_data.notes.size())
		assert(
			npc_base.get_node("%RelatedDataArea").get_child_count()
			== npc_base._note_anchors.size() + npc_data.notes.size()
		)

		remove_child(npc_base)
		npc_base.free()

	assert(known_npc_ids.size() == NPC_CASES.size())
	assert(known_profile_photos.size() == NPC_CASES.size())
	assert(observed_dialogue_counts.size() > 1)
	assert(observed_note_counts.size() > 1)
	print("MULTI_NPC_DATA_SMOKE_TEST: PASS")
	get_tree().quit(0)
