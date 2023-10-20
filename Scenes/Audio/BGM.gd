extends Node

# WIP, handle looping and music transitions (fade out)
var BGMPlayerScene = load("res://Scenes/Audio/BGMPlayer.tscn")

var common_music = {
	"TitleThemes" : [],
	"CharSelectThemes" : [],
	"VictoryThemes" : [],
}
	
#	"title_theme" : {
#		"name" : "Title Theme", # to not play the same music as the one currently being played
#		"artist" : "Zortoise",
#		"audio" : "res://Assets/Music/TitleTheme.ogg",
##		"loop_start": 0.0,
#		"loop_end": 206.76,
#		"vol" : 4,
#		},
#	"char_select" : {
#		"name" : "Character Select",
#		"artist" : "Zortoise",
#		"audio" : "res://Assets/Music/CharSelect.ogg",
##		"loop_start": 0.1,
#		"loop_end": 125.15,
#		"vol" : 0,
#		},
#	"victory" : {
#		"name" : "Victory Screen",
#		"artist" : "Zortoise",
#		"audio" : "res://Assets/Music/VictoryScreen.ogg",
#		"loop_start": 0.71,
#		"loop_end": 94.18,
#		"fade" : true, # use code to fade song after loop_end
#		"vol" : 1,
#		}

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
var current_song_type := ""
var muffle_status := 0 # 1 = muffling, -1 = unmuffling
var muffle_speed := 160000

func _ready():
	self.set_pause_mode(2)
	AudioServer.set_bus_effect_enabled(AudioServer.get_bus_index("Music"), 0, false)
	
	load_common()
	load_custom()
#	construct_track_data()
	
	
func load_common():
	var dir = Directory.new()
	
	for folder_name in ["TitleThemes", "CharSelectThemes", "VictoryThemes"]:
		if dir.dir_exists("res://Assets/Music/" + folder_name): # if Music folder exist
			if dir.open("res://Assets/Music/" + folder_name) == OK:
				dir.list_dir_begin(true)
				var file_name = dir.get_next()
				while file_name != "":
					if file_name.ends_with(".ogg"):
						var dictionary = {
							"name" : file_name,
							"vol" : 0,
						}
						dictionary["audio"] = "res://Assets/Music/" + folder_name + "/" + file_name
						
						var tres_name = "res://Assets/Music/" + folder_name + "/" + file_name.trim_suffix(".ogg") + ".tres"
						if ResourceLoader.exists(tres_name):
							var track_data = ResourceLoader.load(tres_name).data
							for key in track_data.keys():
								dictionary[key] = track_data[key]
								
						common_music[folder_name].append(dictionary)
						
					file_name = dir.get_next()
			else: print("Error: Cannot open Music/" + folder_name + " folder")
		
	
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
					var dictionary = {
						"name" : file_name,
						"vol" : 0,
					}
					
					var file = File.new()
					file.open(dir_name + file_name, file.READ)
					var buffer = file.get_buffer(file.get_len())
	
					var new_stream = AudioStreamOGGVorbis.new()
					new_stream.data = buffer
					dictionary["stream"] = new_stream
					
					custom_playlist.append(dictionary)
					
					var tres_name = dir_name + file_name.trim_suffix(".ogg") + ".tres"
					if ResourceLoader.exists(tres_name):
						var track_data = ResourceLoader.load(tres_name).data
						for key in track_data.keys():
							dictionary[key] = track_data[key]
					
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


func play_common(song_type: String):
	
	if current_song_type == song_type:
		return
	else: current_song_type = song_type
				
	if song_type in common_music and common_music[song_type].size() > 0:
		
		var random = Globals.random.randi_range(0, common_music[song_type].size() - 1)
		bgm(common_music[song_type][random].duplicate())


func play_uncommon(bgm_dictionary: Dictionary):
	current_song_type = ""
	bgm(bgm_dictionary)
	

func bgm(bgm_dictionary: Dictionary):
	
	if current_music != bgm_dictionary.name:
		fade() # just in case
		unmuffle()
		current_music = bgm_dictionary.name
		
		yield(get_tree(),"idle_frame")
		var BGMPlayer = BGMPlayerScene.instance()
		get_tree().get_root().add_child(BGMPlayer)
		BGMPlayer.init(bgm_dictionary)
		
		
func bgm_select(bgm_dict_array:Array):
	
	for bgm_dict in bgm_dict_array: # first, if current music is part of array, do not play music
		if current_music == bgm_dict.name:
			return
			
	var random = Globals.random.randi_range(0, bgm_dict_array.size() - 1)
	var chosen_music_dict = bgm_dict_array[random].duplicate()
	bgm(chosen_music_dict)
	
		
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

	
