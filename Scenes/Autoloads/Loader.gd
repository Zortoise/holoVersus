extends Node


# preloading scenes will cause issues, do them on onready variables instead
onready var loaded_audio_scene := load("res://Scenes/Audio/AudioManager.tscn")
onready var loaded_character_scene := load("res://Scenes/Character.tscn")
onready var loaded_entity_scene := load("res://Scenes/Entity.tscn")
onready var loaded_SFX_scene := load("res://Scenes/SFX.tscn")
onready var loaded_afterimage_scene := load("res://Scenes/Afterimage.tscn")
onready var loaded_field_scene := load("res://Scenes/Field.tscn")
onready var loaded_palette_shader = load("res://Scenes/Shaders/Palette.gdshader")
onready var monochrome_shader = load("res://Scenes/Shaders/Monochrome.gdshader")
onready var white_shader = load("res://Scenes/Shaders/White.gdshader")
onready var loaded_guard_gauge = ResourceLoader.load("res://Assets/UI/guard_gauge1.png")
onready var loaded_guard_gauge_pos = load("res://Assets/UI/guard_gauge_pos.tres")
onready var loaded_dmg_num_scene = load("res://Scenes/DamageNumber.tscn")

onready var loaded_ui_audio_scene := load("res://Scenes/Menus/UIAudio.tscn")


onready var common_entity_data = {
	"BurstCounter" : {
		"scene" : load("res://Assets/Entities/BurstCounter.tscn"),
		"frame_data" : load("res://Assets/Entities/FrameData/Burst.tres"),
		"spritesheet" : ResourceLoader.load("res://Assets/Entities/Spritesheets/BurstSprite.png")
	},
	"BurstEscape" : {
		"scene" : load("res://Assets/Entities/BurstEscape.tscn"),
		"frame_data" : load("res://Assets/Entities/FrameData/Burst.tres"),
		"spritesheet" : ResourceLoader.load("res://Assets/Entities/Spritesheets/BurstSprite.png")
	},
	"BurstAwakening" : {
		"scene" : load("res://Assets/Entities/BurstAwakening.tscn"),
		"frame_data" : load("res://Assets/Entities/FrameData/Burst.tres"),
		"spritesheet" : ResourceLoader.load("res://Assets/Entities/Spritesheets/BurstSprite.png")
	},
}

var common_sfx = {}
var common_sfx_palettes = {}
var common_audio = {}


var sfx = {} # code in _ready() will load this with frame_data and spritesheets from res://Assets/Effects/ at start
# example:
#	sfx = {
#		"DustClouds" : {
#			"frame_data" : load("res://Assets/Effects/DustClouds/FrameData/DustClouds.tres")
#			"spritesheet" : ResourceLoader.load("res://Assets/Effects/DustClouds/Spritesheets/DustCloudsSprite.png")
#		}
#		"HitsparkB" : {
#			"frame_data" : load("res://Assets/Effects/Hitsparks/FrameData/HitsparkB.tres")
#			"spritesheet" : ResourceLoader.load("res://Assets/Effects/Hitsparks/Spritesheets/HitsparkBSprite.png")
#		}
#	}

var sfx_palettes = { # code in _ready() will load this with .png files at start
# example:
#	"blue" : ResourceLoader.load("res://Assets/Palettes/blue.png")
}

var audio = { # code in _ready() will load this with .wav files at start
# example:
#	"jump1" : ResourceLoader.load("res://Assets/Audio/Common/jump1.wav")
}

var ui_audio = { # code in _ready() will load this with .wav files at start
# example:
#	"ui_move" : ResourceLoader.load("res://Assets/Audio/UI/ui_move.wav")
}

var char_data = {
#	"Gura" : {
#		"scene" : load("res://Characters/Gura/Gura.tscn")
#		"frame_data_array" : [
#			ResourceLoader.load("res://Characters/Gura/FrameData/Base.tres"), 
#			ResourceLoader.load("res://Characters/Gura/FrameData/F1.tres"), 
#		]
#		"spritesheet" : {
#			"BaseSprite" : ResourceLoader.load("res://Characters/Gura/Spritesheets/BaseSprite.png"),
#			"F1SfxOver" : ResourceLoader.load("res://Characters/Gura/Spritesheets/F1SfxOver.png"),
#		},
#		"palettes" : {
#			"2" : ResourceLoader.load("res://Characters/Gura/Palettes/2.png")
#		}
#	}
#	"GuraM" : {
#		"scene" : load("res://Mobs/GuraM/GuraM.tscn")
#		"frame_data_array" : [
#			ResourceLoader.load("res://Characters/Gura/FrameData/Base.tres"), 
#			ResourceLoader.load("res://Characters/Gura/FrameData/F1.tres"), 
#		]
#		"spritesheet" : {
#			"BaseSprite" : ResourceLoader.load("res://Characters/Gura/Spritesheets/BaseSprite.png"),
#			"F1SfxOver" : ResourceLoader.load("res://Characters/Gura/Spritesheets/F1SfxOver.png"),
#		},
#		"palettes" : {
#			"mimic" : ResourceLoader.load("res://Characters/Gura/Palettes/4.png")
#		}
#	}
}

var entity_data = {
#	"TridentProj" : { # example
#		"scene" : load("res://Characters/Gura/Entities/TridentProj.tscn"),
#		"frame_data" : load("res://Characters/Gura/Entities/FrameData/TridentProj.tres"),
#		"spritesheet" : ResourceLoader.load("res://Characters/Gura/Entities/Spritesheets/TridentProjSprite.png")
#	},
#	"TridentProjM" : { # example
#		"scene" : load("res://Mobs/GuraM/Entities/TridentProjM.tscn"),
#		"frame_data" : load("res://Characters/Gura/Entities/FrameData/TridentProj.tres"),
#		"spritesheet" : ResourceLoader.load("res://Characters/Gura/Entities/Spritesheets/TridentProjSprite.png")
#	},
}

var item_data = {
#	"Coin": {
#		"scene" : load("res://Items/Coin/Coin.tscn"),
#		"frame_data" : ResourceLoader.load("res://Items/Coin/FrameData/Coin.tres"),
#		"spritesheet" : ResourceLoader.load("res://Items/Coin/Spritesheets/CoinSprite.png"),
#		"palettes" : {}
#	}
}


func _ready():
	load_common_sfx() # preloading
	
	
	
func reset(): # run at start of every battle
	char_data = {}
	entity_data = {}
	item_data = {}
	sfx = {}
	sfx_palettes = {}
	audio = {}
	load_commons()

func load_commons(): # reload common data at start of every battle
	for x in common_entity_data.keys():
		entity_data[x] = common_entity_data[x]
	for x in common_sfx.keys():
		sfx[x] = common_sfx[x]
	for x in common_sfx_palettes.keys():
		sfx_palettes[x] = common_sfx_palettes[x]
	for x in common_audio.keys():
		audio[x] = common_audio[x]
	for x in common_sfx.keys():
		sfx[x] = common_sfx[x]
		
func add_loaded(dict: Dictionary, key, data):
	if !key in dict:
		dict[key] = data
	
	
# COMMON SFX ------------------------------------------------------------------------------------------------------------------------

func load_common_sfx():
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
	else: print("Error: Cannot open Effects folder from Loader.gd")
	
	# load .png files from res://Assets/Palettes/
	if dir.change_dir("res://Assets/Palettes/") == OK:
		dir.list_dir_begin(true)
		var file_name = dir.get_next()
		while file_name != "":
			# load all needed directories
			if file_name.ends_with(".png.import"):
				var file_name2 = file_name.trim_suffix(".png.import")
				common_sfx_palettes[file_name2] = ResourceLoader.load("res://Assets/Palettes/" + file_name2 + ".png")
			file_name = dir.get_next()
	else: print("Error: Cannot open Assets/Palettes folder from Loader.gd")
	
	# load .wav files from res://Assets/Audio/Common
	if dir.change_dir("res://Assets/Audio/Common/") == OK:
		dir.list_dir_begin(true)
		var file_name = dir.get_next()
		while file_name != "":
			# load all needed directories
			if file_name.ends_with(".wav.import"):
				var file_name2 = file_name.trim_suffix(".wav.import")
				common_audio[file_name2] = ResourceLoader.load("res://Assets/Audio/Common/" + file_name2 + ".wav")
			file_name = dir.get_next()
	else: print("Error: Cannot open Audio/Common folder from Loader.gd")
	
	# load .wav files from res://Assets/Audio/UI
	if dir.change_dir("res://Assets/Audio/UI/") == OK:
		dir.list_dir_begin(true)
		var file_name = dir.get_next()
		while file_name != "":
			# load all needed directories
			if file_name.ends_with(".wav.import"):
				var file_name2 = file_name.trim_suffix(".wav.import")
				ui_audio[file_name2] = ResourceLoader.load("res://Assets/Audio/UI/" + file_name2 + ".wav")
			file_name = dir.get_next()
	else: print("Error: Cannot open Audio/UI folder from Loader.gd")
	
	
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
				
				common_sfx[frame_data_file_name] = {}
				common_sfx[frame_data_file_name]["frame_data"] = \
						load("res://Assets/Effects/" + folder_name + "/FrameData/" + frame_data_file_name + ".tres")
				common_sfx[frame_data_file_name]["spritesheet"] = \
						load("res://Assets/Effects/" + folder_name + "/Spritesheets/" + frame_data_file_name + "Sprite.png")
				
			frame_data_file_name = dir.get_next()
	else: print("Error: Cannot open FrameData folder for Effects from Loader.gd")
	
	
	

