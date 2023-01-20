extends Node

# global variables that contain preloaded SFX animation data
# does not contain unique character's SFX data, store those on the unique character's node

var loaded_sfx = {} # code in _ready() will load this with frame_data and spritesheets from res://Assets/Effects/ at start
# example:
#	loaded_sfx = {
#		"DustClouds" : {
#			"frame_data" : load("res://Assets/Effects/DustClouds/FrameData/DustClouds.tres")
#			"spritesheet" : ResourceLoader.load("res://Assets/Effects/DustClouds/Spritesheets/DustCloudsSprite.png")
#		}
#		"HitsparkB" : {
#			"frame_data" : load("res://Assets/Effects/Hitsparks/FrameData/HitsparkB.tres")
#			"spritesheet" : ResourceLoader.load("res://Assets/Effects/Hitsparks/Spritesheets/HitsparkBSprite.png")
#		}
#	}

var loaded_sfx_palette = { # code in _ready() will load this with .png files at start
# example:
#	"blue" : ResourceLoader.load("res://Assets/Palettes/blue.png")
}

var loaded_audio = { # code in _ready() will load this with .wav files at start
# example:
#	"jump1" : ResourceLoader.load("res://Assets/Audio/Common/jump1.wav")
}

var loaded_ui_audio = { # code in _ready() will load this with .wav files at start
# example:
#	"ui_move" : ResourceLoader.load("res://Assets/Audio/UI/ui_move.wav")
}

# also contain modulate animations
var modulate_animations = {
	"yellow_burst" : {
		"duration": 22,
		"loop" : false,
		"timestamps" : {
			0 :
			{
				"modulate" : Color(4.0, 4.0, 4.0),
			},
			2 :
			{
				"modulate" : Color(2.5, 1.5, 1.0), # red
			},
			5 :
			{
				"modulate" : Color(1.5, 0.8, 0.5), # orange
			},
			9 :
			{
				"modulate" : Color(2.5, 1.25, 0.9), # yellow
			},
			12 :
			{
				"modulate" : Color(2.5, 1.5, 1.0), # red
			},
			15 :
			{
				"modulate" : Color(1.5, 0.8, 0.5), # orange
			},
			19 :
			{
				"modulate" : Color(2.5, 1.25, 0.9), # yellow
			},
		}
	},
	"blue_burst" : {
		"duration": 22,
		"loop" : false,
		"timestamps" : {
			0 :
			{
				"modulate" : Color(4.0, 4.0, 4.0),
			},
			2 :
			{
				"modulate" : Color(1.0, 2.5, 2.5),
			},
			5 :
			{
				"modulate" : Color(0.8, 1.5, 5.0),
			},
			9 :
			{
				"modulate" : Color(1.0, 1.0, 1.5),
			},
			12 :
			{
				"modulate" : Color(1.0, 2.5, 2.5),
			},
			15 :
			{
				"modulate" : Color(0.8, 1.5, 5.0),
			},
			19 :
			{
				"modulate" : Color(1.0, 1.0, 1.5),
			},
		}
	},
	"red_burst" : {
		"duration": 15,
		"loop" : false,
		"timestamps" : {
			0 :
			{
				"modulate" : Color(4.0, 4.0, 4.0),
			},
			3 :
			{
				"modulate" : Color(5.0, 1.0, 1.0),
			},
			7 :
			{
				"modulate" : Color(4.0, 4.0, 4.0),
			},
			11 :
			{
				"modulate" : Color(5.0, 1.0, 1.0),
			},
		}
	},
	"pink_burst" : {
		"duration": 12,
		"loop" : false,
		"afterimage_trail" : 0,
		"timestamps" : {
			0 :
			{
				"modulate" : Color(4.0, 4.0, 4.0),
			},
			3 :
			{
				"modulate" : Color(5.0, 1.0, 1.5),
			},
			5 :
			{
				"modulate" : Color(4.0, 4.0, 4.0),
			},
			7 :
			{
				"modulate" : Color(5.0, 1.0, 1.5),
			},
		}
	},
	"respawn_grace" :{
		"duration": 6,
		"loop" : true,
		"timestamps" : {
			0 :
			{
				"modulate" : Color(2.0, 2.0, 2.0),
			},
			3 :
			{
				"modulate" : Color(1.0, 1.0, 1.0),
			},
		}
	},
	"tech_flash" :{
		"duration": 5,
		"loop" : false,
		"timestamps" : {
			0 :
			{
				"modulate" : Color(10.0, 10.0, 10.0),
			},
		}
	},
	"unflinch_flash" :{
		"duration": 5,
		"loop" : false,
		"timestamps" : {
			0 :
			{
				"modulate" : Color(2.0, 2.0, 2.0),
			},
		}
	},
	"perfectblock_flash" :{
		"duration": 10,
		"loop" : false,
		"timestamps" : {
			0 :
			{
				"modulate" : Color(3.0, 3.0, 3.0),
			},
			2 :
			{
				"modulate" : Color(2.0, 2.0, 2.0),
			},
			4 :
			{
				"modulate" : Color(1.75, 1.75, 1.75),
			},
			6 :
			{
				"modulate" : Color(1.5, 1.5, 1.5),
			},
			8 :
			{
				"modulate" : Color(1.25, 1.25, 1.25),
			},
		}
	},
	"wrongblock_flash" :{
		"priority_lvl": 0,
		"duration": 10,
		"loop" : false,
		"timestamps" : {
			0 :
			{
				"modulate" : Color(0.5, 0.5, 0.5),
			},
			2 :
			{
				"modulate" : Color(0.6, 0.6, 0.6),
			},
			4 :
			{
				"modulate" : Color(0.7, 0.7, 0.7),
			},
			6 :
			{
				"modulate" : Color(0.8, 0.8, 0.8),
			},
			8 :
			{
				"modulate" : Color(0.9, 0.9, 0.9),
			},
		}
	},
	"armor_flash" :{
		"duration": 10,
		"loop" : false,
		"timestamps" : {
			0 :
			{
				"modulate" : Color(0.5, 0.2, 0.5),
			},
			2 :
			{
				"modulate" : Color(0.8, 0.3, 0.8),
			},
			4 :
			{
				"modulate" : Color(0.75, 0.5, 0.75),
			},
			6 :
			{
				"modulate" : Color(0.9, 0.7, 0.9),
			},
			8 :
			{
				"modulate" : Color(1.0, 0.9, 1.0),
			},
		}
	},
	"perfect_guard_flash" : {
		"duration": 5,
		"loop" : false,
		"timestamps" : {
			0 : # this is the timestamp of the key
			{
				"modulate" : Color(2.0, 2.0, 2.0),
			},
		}
	},
	"EX_flash" : {
		"duration": 4,
		"loop" : false,
		"followup" : "EX_flash2",
		"timestamps" : {
			0 : # this is the timestamp of the key
			{
				"modulate" : Color(4.0, 4.0, 4.0),
			},
		}
	},
	"EX_flash2" : {
		"duration": 18,
		"loop" : true,
		"afterimage_trail" : 0,
		"timestamps" : {
			0 : # this is the timestamp of the key
			{
				"modulate" : Color(1.2, 0.8, 0.8), # red
			},
			3 :
			{
				"modulate" : Color(1.2, 1.2, 0.8), # yellow
			},
			6 :
			{
				"modulate" : Color(0.8, 1.2, 0.8), # green
			},
			9 :
			{
				"modulate" : Color(0.8, 1.2, 1.2), # cyan
			},
			12 :
			{
				"modulate" : Color(0.8, 0.8, 1.2), # blue
			},
			15 :
			{
				"modulate" : Color(1.2, 0.8, 1.2), # purple
			},
		}
	},
	"EX_block_flash" : {
		"duration": 4,
		"loop" : false,
#		"followup" : "EX_block_flash2",
		"timestamps" : {
			0 : # this is the timestamp of the key
			{
				"modulate" : Color(4.0, 4.0, 4.0),
			},
		}
	},
#	"EX_block_flash2" : {
#		"duration": 12,
#		"loop" : true,
#		"afterimage_trail" : 0,
#		"timestamps" : {
#			0 : # this is the timestamp of the key
#			{
#				"modulate" : Color(1.3, 0.7, 0.7), # red
#			},
#			2 :
#			{
#				"modulate" : Color(1.3, 1.3, 0.7), # yellow
#			},
#			4 :
#			{
#				"modulate" : Color(0.7, 1.3, 0.7), # green
#			},
#			6 :
#			{
#				"modulate" : Color(0.7, 1.3, 1.3), # cyan
#			},
#			8 :
#			{
#				"modulate" : Color(0.7, 0.7, 1.3), # blue
#			},
#			10 :
#			{
#				"modulate" : Color(1.3, 0.7, 1.3), # purple
#			},
#		}
#	},
	"punish_flash" :{
		"duration": 6,
		"loop" : false,
		"timestamps" : {
			0 :
			{
				"modulate" : Color(2.0, 0.0, 0.0),
			},
		}
	},
	"sweet_flash" :{
		"duration": 8,
		"loop" : false,
		"timestamps" : {
			0 :
			{
				"modulate" : Color(0.0, 0.0, 0.0),
			},
			3 :
			{
				"modulate" : Color(10.0, 10.0, 10.0),
			},
		}
	},
	"punish_sweet_flash" :{
		"duration": 16,
		"loop" : false,
		"timestamps" : {
			0 :
			{
				"modulate" : Color(0.0, 0.0, 0.0),
			},
			3 :
			{
				"modulate" : Color(10.0, 10.0, 10.0),
			},
			6 :
			{
				"modulate" : Color(0.0, 0.0, 0.0),
			},
			9 :
			{
				"modulate" : Color(2.0, 0.0, 0.0),
			},
		}
	},
	"break_flash" :{
		"duration": 10,
		"loop" : false,
		"timestamps" : {
			0 :
			{
				"modulate" : Color(0.0, 0.0, 0.0),
			},
			4 :
			{
				"modulate" : Color(10.0, 10.0, 10.0),
			},
		}
	},
	"break" : {
		"duration": 12,
		"loop" : true,
		"timestamps" : {
			0 :
			{
				"modulate" : Color(2.5, 1.5, 1.0), # red
			},
			4 :
			{
				"modulate" : Color(1.5, 0.8, 0.5), # orange
			},
			10 :
			{
				"modulate" : Color(2.5, 1.25, 0.9), # yellow
			},
		}
	},
	"lethal_flash" :{
		"duration": 12,
		"loop" : false,
		"timestamps" : {
			0 :
			{
				"modulate" : Color(0.0, 0.0, 0.0),
			},
			3 :
			{
				"modulate" : Color(10.0, 10.0, 10.0),
			},
			6 :
			{
				"modulate" : Color(0.0, 0.0, 0.0),
			},
			9 :
			{
				"modulate" : Color(10.0, 10.0, 10.0),
			},
		}
	},
	"lethal" : {
		"duration": 12,
		"loop" : true,
		"timestamps" : {
			0 :
			{
				"modulate" : Color(0.5, 0.5, 0.5),
			},
			4 :
			{
				"modulate" : Color(1.0, 1.0, 1.0),
			},
			10 :
			{
				"modulate" : Color(2.0, 2.0, 2.0),
			},
		}
	},
	"aflame" : {
		"duration": 12,
		"loop" : true,
		"timestamps" : {
			0 :
			{
				"modulate" : Color(4.0, 1.0, 0.5), # red
			},
			4 :
			{
				"modulate" : Color(2.5, 0.8, 0.3), # orange
			},
			10 :
			{
				"modulate" : Color(3.0, 1.25, 0.8), # yellow
			},
		}
	},
	"aflame_purple" : { # for puple flame and shock
		"duration": 12,
		"loop" : true,
		"timestamps" : {
			0 :
			{
				"modulate" : Color(1.0, 0.3, 0.8),
			},
			4 :
			{
				"modulate" : Color(2.0, 0.7, 1.8),
			},
			10 :
			{
				"modulate" : Color(2.0, 1.5, 2.7),
			},
		}
	},
	"aflame_blue" : { # for blue fire, freeze and shock
		"duration": 12,
		"loop" : true,
		"timestamps" : {
			0 :
			{
				"modulate" : Color(1.0, 2.5, 2.5),
			},
			4 :
			{
				"modulate" : Color(0.8, 1.5, 5.0),
			},
			10 :
			{
				"modulate" : Color(1.0, 1.0, 1.5),
			},
		}
	},
	"poison" : {
		"duration": 40,
		"loop" : true,
		"timestamps" : {
			0 :
			{
				"modulate" : Color(0.9, 0.65, 1.0),
			},
			10 :
			{
				"modulate" : Color(1.2, 0.8, 1.2),
			},
			20 :
			{
				"modulate" : Color(1.25, 0.9, 1.5),
			},
			30 :
			{
				"modulate" : Color(1.2, 0.8, 1.2),
			},
		}
	}
}

var fade_animations = {
	"test_fade" : {
		"duration": 12,
		"loop" : false,
		"timestamps" : {
			0 :
			{
				"fade" : 0.8,
			},
			2 :
			{
				"fade" : 0.4,
			},
			4 :
			{
				"fade" : 0.0,
			},
			8 :
			{
				"fade" : 0.4,
			},
			10 :
			{
				"fade" : 0.8,
			},
		}
	},
	"going_invisible": {
		"duration": 5,
		"loop" : false,
		"followup" : "invisibility",
		"timestamps" : {
			0 :
			{
				"fade" : 0.8,
			},
			2 :
			{
				"fade" : 0.4,
			},
			4 :
			{
				"fade" : 0.0,
			},
		}
	},
	"invisibility" : { # for blue fire, freeze and shock
		"duration": 1,
		"loop" : true,
		"timestamps" : {
			0 :
			{
				"fade" : 0.0,
			},
		}
	},
}


func _ready():
	
	# load directories from res://Assets/Effects/
	var dir = Directory.new()
	if dir.open("res://Assets/Effects/") == OK:
		dir.list_dir_begin(true)
		var folder_name = dir.get_next()
		while folder_name != "":
			# load all needed directories
			if !folder_name.begins_with("."):
				load_sfx(folder_name)
			folder_name = dir.get_next()
	else: print("Error: Cannot open Effects folder from LoadedSFX.gd")
	
	# load .png files from res://Assets/Palettes/
	if dir.change_dir("res://Assets/Palettes/") == OK:
		dir.list_dir_begin(true)
		var file_name = dir.get_next()
		while file_name != "":
			# load all needed directories
			if file_name.ends_with(".png.import"):
				var file_name2 = file_name.trim_suffix(".png.import")
				loaded_sfx_palette[file_name2] = ResourceLoader.load("res://Assets/Palettes/" + file_name2 + ".png")
			file_name = dir.get_next()
	else: print("Error: Cannot open Assets/Palettes folder from LoadedSFX.gd")
	
	# load .wav files from res://Assets/Audio/Common
	if dir.change_dir("res://Assets/Audio/Common/") == OK:
		dir.list_dir_begin(true)
		var file_name = dir.get_next()
		while file_name != "":
			# load all needed directories
			if file_name.ends_with(".wav.import"):
				var file_name2 = file_name.trim_suffix(".wav.import")
				loaded_audio[file_name2] = ResourceLoader.load("res://Assets/Audio/Common/" + file_name2 + ".wav")
			file_name = dir.get_next()
	else: print("Error: Cannot open Audio/Common folder from LoadedSFX.gd")
	
	# load .wav files from res://Assets/Audio/UI
	if dir.change_dir("res://Assets/Audio/UI/") == OK:
		dir.list_dir_begin(true)
		var file_name = dir.get_next()
		while file_name != "":
			# load all needed directories
			if file_name.ends_with(".wav.import"):
				var file_name2 = file_name.trim_suffix(".wav.import")
				loaded_ui_audio[file_name2] = ResourceLoader.load("res://Assets/Audio/UI/" + file_name2 + ".wav")
			file_name = dir.get_next()
	else: print("Error: Cannot open Audio/UI folder from LoadedSFX.gd")
	
	
func load_sfx(folder_name):
	
	# load sfx from res://Assets/Effects/
	var dir = Directory.new()
	if dir.open("res://Assets/Effects/" + folder_name + "/FrameData/") == OK:
		dir.list_dir_begin(true)
		var frame_data_file_name = dir.get_next()
		while frame_data_file_name != "":
			# load all needed files and add them to the dictionary
			if frame_data_file_name.ends_with(".tres"):
				frame_data_file_name = frame_data_file_name.trim_suffix(".tres")
				
				loaded_sfx[frame_data_file_name] = {}
				loaded_sfx[frame_data_file_name]["frame_data"] = \
						load("res://Assets/Effects/" + folder_name + "/FrameData/" + frame_data_file_name + ".tres")
				loaded_sfx[frame_data_file_name]["spritesheet"] = \
						load("res://Assets/Effects/" + folder_name + "/Spritesheets/" + frame_data_file_name + "Sprite.png")
				
			frame_data_file_name = dir.get_next()
	else: print("Error: Cannot open FrameData folder for Effects from LoadedSFX.gd")
	
