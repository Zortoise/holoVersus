extends Node

# WIP, handle looping and music transitions (fade out)
var BGMPlayerScene = load("res://Scenes/Audio/BGMPlayer.tscn")

var common_music = {
	"title_theme" : {
		"name" : "TitleTheme", # to not play the same music as the one currently being played
		"audio" : ResourceLoader.load("res://Assets/Music/TitleTheme.ogg"),
#		"loop_start": 0.0,
		"loop_end": 224.0,
		"vol" : 4,
		},
	"char_select" : {
		"name" : "CharSelect",
		"audio" : ResourceLoader.load("res://Assets/Music/CharSelect.ogg"),
#		"loop_start": 0.1,
		"loop_end": 125.15,
		"vol" : 0,
		},
	"victory" : {
		"name" : "VictoryScreen",
		"audio" : ResourceLoader.load("res://Assets/Music/VictoryScreen.ogg"),
		"loop_start": 0.71,
		"loop_end": 94.18,
		"fade" : true, # use code to fade song after loop_end
		"vol" : 1,
		}
}

var current_music := ""
var muffle_status := 0 # 1 = muffling, -1 = unmuffling
var muffle_speed := 160000

func _ready():
	self.set_pause_mode(2)
	AudioServer.set_bus_effect_enabled(AudioServer.get_bus_index("Music"), 0, false)

func fade():
	current_music = ""
	var old_bgm = get_tree().get_nodes_in_group("BGMPlayers")
	for x in old_bgm:
		x.decaying = true

func bgm(bgm_dictionary):
	
	if current_music != bgm_dictionary.name:
		fade() # just in case
		current_music = bgm_dictionary.name
		
		yield(get_tree(),"idle_frame")
		var BGMPlayer = BGMPlayerScene.instance()
		get_tree().get_root().add_child(BGMPlayer)
		BGMPlayer.init(bgm_dictionary)
		unmuffle()
		
		
func _process(delta):
	if muffle_status != 0:
		match muffle_status:
			1:
				var cutoff = AudioServer.get_bus_effect(AudioServer.get_bus_index("Music"), 0).cutoff_hz
				if cutoff > 200:
					cutoff = max(cutoff - muffle_speed * delta, 200)
					AudioServer.get_bus_effect(AudioServer.get_bus_index("Music"), 0).cutoff_hz = cutoff
					
			-1:
				var cutoff = AudioServer.get_bus_effect(AudioServer.get_bus_index("Music"), 0).cutoff_hz
				if cutoff < 22000:
					cutoff = min(cutoff + muffle_speed * delta, 22000)
					AudioServer.get_bus_effect(AudioServer.get_bus_index("Music"), 0).cutoff_hz = cutoff
				else:
					AudioServer.set_bus_effect_enabled(AudioServer.get_bus_index("Music"), 0, false)
					muffle_status = 0
					
		
func muffle():
	if muffle_status != 1:
		AudioServer.set_bus_effect_enabled(AudioServer.get_bus_index("Music"), 0, true)
		AudioServer.get_bus_effect(AudioServer.get_bus_index("Music"), 0).cutoff_hz = 22000.0
		muffle_status = 1
	
func unmuffle():
	if muffle_status == 1:
		muffle_status = -1

	
