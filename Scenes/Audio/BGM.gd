extends Node

# WIP, handle looping and music transitions (fade out)
var BGMPlayerScene = load("res://Scenes/Audio/BGMPlayer.tscn")

var common_music = {
	"title_theme" : {
		"name" : "Title Theme", # to not play the same music as the one currently being played
		"artist" : "Zortoise",
		"audio" : "res://Assets/Music/TitleTheme.ogg",
#		"loop_start": 0.0,
		"loop_end": 206.76,
		"vol" : 4,
		},
	"char_select" : {
		"name" : "Character Select",
		"artist" : "Zortoise",
		"audio" : "res://Assets/Music/CharSelect.ogg",
#		"loop_start": 0.1,
		"loop_end": 125.15,
		"vol" : 0,
		},
	"victory" : {
		"name" : "Victory Screen",
		"artist" : "Zortoise",
		"audio" : "res://Assets/Music/VictoryScreen.ogg",
		"loop_start": 0.71,
		"loop_end": 94.18,
		"fade" : true, # use code to fade song after loop_end
		"vol" : 1,
		}
}

var custom_playlist = [
#	{
#	"name" : "VictoryScreen",
#	"audio" : "res://Assets/Music/VictoryScreen.ogg",
#	"loop_start": 0.71,
#	"loop_end": 94.18,
#	"fade" : true, # use code to fade song after loop_end
#	"vol" : 1,
#	}
]

var current_music := ""
var muffle_status := 0 # 1 = muffling, -1 = unmuffling
var muffle_speed := 160000

func _ready():
	self.set_pause_mode(2)
	AudioServer.set_bus_effect_enabled(AudioServer.get_bus_index("Music"), 0, false)
	
	load_custom()
#	construct_track_data()
	
	
func load_custom():
	var dir_name = OS.get_executable_path().get_base_dir() + "/CustomPlaylist/"
	var dir = Directory.new()
	
	if dir.dir_exists(dir_name): # if CustomPlaylist folder exist
		if dir.open(dir_name) == OK:
			dir.list_dir_begin(true)
			var file_name = dir.get_next()
			while file_name != "":
				# load all needed files and add them to the dictionary
				if file_name.ends_with(".ogg"):
					var directionary = {
						"name" : file_name,
						"vol" : 0,
					}
					
					var file = File.new()
					file.open(dir_name + file_name, file.READ)
					var buffer = file.get_buffer(file.get_len())
	
					var new_stream = AudioStreamOGGVorbis.new()
					new_stream.data = buffer
					directionary["stream"] = new_stream
					
					custom_playlist.append(directionary)
					
					var tres_name = dir_name + file_name.trim_suffix(".ogg") + ".tres"
					if ResourceLoader.exists(tres_name):
						var track_data = ResourceLoader.load(tres_name).data
						for key in track_data.keys():
							directionary[key] = track_data[key]
					
				file_name = dir.get_next()
		else: print("Error: Cannot open CustomPlaylist folder")
			
			
#func construct_track_data():
#
#	var track_data = {
#		"loop_start": 0.0,
#		"loop_end": 2.0,
#		"fade" : true,
#		"vol" : 1,
#	}
#
#	var custom_data = load("res://Scenes/Audio/CustomData.gd").new() # save config data
#	custom_data.data = track_data.duplicate()
## warning-ignore:return_value_discarded
#	ResourceSaver.save(OS.get_executable_path().get_base_dir() + "/CustomPlaylist/test.tres", custom_data)

func fade():
	current_music = ""
	var old_bgm = get_tree().get_nodes_in_group("BGMPlayers")
	for x in old_bgm:
		x.decaying = true

func bgm(bgm_dictionary):
	
	if current_music != bgm_dictionary.name:
		fade() # just in case
		unmuffle()
		current_music = bgm_dictionary.name
		
		yield(get_tree(),"idle_frame")
		var BGMPlayer = BGMPlayerScene.instance()
		get_tree().get_root().add_child(BGMPlayer)
		BGMPlayer.init(bgm_dictionary)
		
		
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
		
#func instant_unmuffle():
#	muffle_status = 0
#	AudioServer.get_bus_effect(AudioServer.get_bus_index("Music"), 0).cutoff_hz = 22000
#	AudioServer.set_bus_effect_enabled(AudioServer.get_bus_index("Music"), 0, false)

	
