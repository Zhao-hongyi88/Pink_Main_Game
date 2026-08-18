extends Node

@onready var bgm_player: AudioStreamPlayer = $BGMPlayer

var home_bgm = preload("res://Music/BGM/home_bgm.mp3")
var gameplay_bgm = preload("res://Music/BGM/gameplay_bgm.mp3")

func _ready():
	play_home_bgm()

func play_home_bgm():
	if bgm_player.stream != home_bgm:
		bgm_player.stop()
		bgm_player.stream = home_bgm
		bgm_player.play()

func play_gameplay_bgm():
	print("MusicManager: gameplay BGM called")
	if bgm_player.stream != gameplay_bgm:
		bgm_player.stop()
		bgm_player.stream = gameplay_bgm
		bgm_player.play()
