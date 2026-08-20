extends Control

const NPC_ROSTER_PATH := "res://data/npc/npc_roster.json"
const NPC_ROSTER_SCRIPT = preload("res://scripts/npc/npc_roster.gd")
const INTRO_TIME_DISPLAY_DURATION := 0.35
const INTRO_ARCHIVE_DURATION := 0.45
const INTRO_START_DURATION := 0.5
const INTRO_RULE_DURATION := 0.3

@onready var start_button: Button = %StartButton
@onready var rule_button: Button = %RuleButton
@onready var rule_panel: Control = %RulePanel
@onready var archive_panel: Control = %ArchivePanel
@onready var time_display: Control = %TimeDisplay

var npc_roster: RefCounted
var _intro_tween: Tween
var _intro_layout_captured := false
var _time_display_final_position := Vector2.ZERO
var _archive_panel_final_position := Vector2.ZERO


func _ready() -> void:
	MusicManager.play_home_bgm()
	rule_button.hide()
	start_button.pressed.connect(_on_start_button_pressed)
	rule_button.pressed.connect(_on_rule_button_pressed)
	rule_panel.get_node("%CloseButton").pressed.connect(_on_rule_panel_close_pressed)
	_setup_archive()
	call_deferred("_play_intro_animation")


func _play_intro_animation() -> void:
	if _intro_tween != null and _intro_tween.is_valid():
		_intro_tween.kill()

	if not _intro_layout_captured:
		_time_display_final_position = time_display.position
		_archive_panel_final_position = archive_panel.position
		_intro_layout_captured = true

	_restore_intro_final_state()
	start_button.pivot_offset = start_button.size * 0.5

	time_display.position = _time_display_final_position + Vector2(0.0, -20.0)
	time_display.modulate.a = 0.0
	archive_panel.position = _archive_panel_final_position + Vector2(-30.0, 0.0)
	archive_panel.modulate.a = 0.0
	start_button.scale = Vector2(0.85, 0.85)
	start_button.modulate.a = 0.0
	rule_button.modulate.a = 0.0

	_intro_tween = create_tween()
	_intro_tween.set_parallel(true)
	_intro_tween.tween_property(
		time_display,
		"position",
		_time_display_final_position,
		INTRO_TIME_DISPLAY_DURATION
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_intro_tween.tween_property(
		time_display,
		"modulate:a",
		1.0,
		INTRO_TIME_DISPLAY_DURATION
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_intro_tween.tween_property(
		archive_panel,
		"position",
		_archive_panel_final_position,
		INTRO_ARCHIVE_DURATION
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_intro_tween.tween_property(
		archive_panel,
		"modulate:a",
		1.0,
		INTRO_ARCHIVE_DURATION
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_intro_tween.tween_property(
		start_button,
		"scale",
		Vector2.ONE,
		INTRO_START_DURATION
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_intro_tween.tween_property(
		start_button,
		"modulate:a",
		1.0,
		INTRO_START_DURATION
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_intro_tween.tween_property(
		rule_button,
		"modulate:a",
		1.0,
		INTRO_RULE_DURATION
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _restore_intro_final_state() -> void:
	if not _intro_layout_captured:
		return
	time_display.position = _time_display_final_position
	time_display.modulate.a = 1.0
	archive_panel.position = _archive_panel_final_position
	archive_panel.modulate.a = 1.0
	start_button.scale = Vector2.ONE
	start_button.modulate.a = 1.0
	rule_button.modulate.a = 1.0


func _on_start_button_pressed() -> void:
	_start_game()


func _start_game() -> void:
	if npc_roster == null or not GameState.is_npc_unlocked(GameState.selected_npc_id):
		push_error("MainMenu: no unlocked NPC is selected.")
		return
	var selected_data_path: String = npc_roster.get_data_path(GameState.selected_npc_id)
	if selected_data_path.is_empty():
		push_error("MainMenu: selected NPC has no NPCData path.")
		return
	print("START: switching to gameplay BGM")
	MusicManager.play_gameplay_bgm()
	if not SceneRouter.set_next_transition_mode(SceneRouter.START_TRANSITION_MODE):
		return
	if not SceneRouter.go_to(&"npc_base", {
		"npc_data_path": selected_data_path,
	}):
		SceneRouter.clear_next_transition_mode()


func _setup_archive() -> void:
	npc_roster = NPC_ROSTER_SCRIPT.new()
	if not npc_roster.load_from_json(NPC_ROSTER_PATH):
		push_error("MainMenu: %s" % npc_roster.get_error_message())
		start_button.disabled = true
		return
	if not GameState.initialize_npc_access(npc_roster):
		push_error("MainMenu: failed to initialize NPC access state.")
		start_button.disabled = true
		return
	GameState.advance_from_completed_progress(npc_roster)
	if not archive_panel.setup(npc_roster):
		push_error("MainMenu: failed to initialize ArchivePanel.")
		start_button.disabled = true


func _on_rule_button_pressed() -> void:
	rule_panel.show()


func _on_rule_panel_close_pressed() -> void:
	rule_panel.hide()
