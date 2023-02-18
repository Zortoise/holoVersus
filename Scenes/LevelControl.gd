extends Node


var spritesheets = { # filled up at initialization via set_up_spritesheets()
#	"Base" : load("res://Characters/___/Spritesheets/Base.png") # example
	}
var unique_audio = { # filled up at initialization
#	"example" : load("res://Characters/___/UniqueAudio/example.wav") # example
}
var entity_data = { # filled up at initialization
#	"TridentProj" : { # example
#		"scene" : load("res://Characters/Gura/Entities/TridentProj.tscn"),
#		"frame_data" : load("res://Characters/Gura/Entities/FrameData/TridentProj.tres"),
#		"spritesheet" : ResourceLoader.load("res://Characters/Gura/Entities/Spritesheets/TridentProjSprite.png")
#	},
}
var sfx_data = { # filled up at initialization
#	"WaterJet" : { # example
#		"frame_data" : load("res://Characters/Gura/SFX/FrameData/WaterJet.tres"),
#		"spritesheet" : ResourceLoader.load("res://Characters/Gura/SFX/Spritesheets/WaterJetSprite.png")
#	},
}


func init():
	Globals.survival_level
	
	var directory_name
	
	set_up_spritesheets(directory_name) # scan all .png files within Spritesheet folder and add them to "spritesheets" dictionary
	set_up_unique_audio(directory_name) # scan all .wav files within Audio folder and add them to "unique_audio" dictionary
	set_up_entities(directory_name) # scan all .tscn files within Entities folder and add them to "entities_data" dictionary
	set_up_sfx(directory_name) # scan all .tres files within SFX/FrameData folder and add them to "sfx_data" dictionary
	
	
# fill up the "spritesheets" dictionary with spritesheets in the "Spritesheets" folder loaded and ready
func set_up_spritesheets(directory_name):
	# open the Spritesheet folder and get the filenames of all files in it
	var directory = Directory.new()
	if directory.open(directory_name + "Spritesheets/") == OK:
		directory.list_dir_begin(true)
		var file_name = directory.get_next()
		while file_name != "":
			# load all needed files and add them to the dictionary
			if file_name.ends_with(".png.import"):
				var file_name2 = file_name.get_file().trim_suffix(".png.import")
				spritesheets[file_name2] = ResourceLoader.load(directory_name + "Spritesheets/" + file_name2 + ".png")
			file_name = directory.get_next()
	else: print("Error: Cannot open Spritesheets folder for character")
	
	
func set_up_unique_audio(directory_name):
	var directory = Directory.new()
	if directory.open(directory_name + "UniqueAudio/") == OK:
		directory.list_dir_begin(true)
		var file_name = directory.get_next()
		while file_name != "":
			# load all needed files and add them to the dictionary
			if file_name.ends_with(".wav.import"):
				var file_name2 = file_name.get_file().trim_suffix(".wav.import")
				unique_audio[file_name2] = \
					ResourceLoader.load(directory_name + "UniqueAudio/" + file_name2 + ".wav")
			file_name = directory.get_next()
	else: print("Error: Cannot open UniqueAudio folder for character")
	
	
func set_up_entities(directory_name): # scan all .tscn files within Entities folder and add them to "entities_data" dictionary
#	var entity_data = {
#	#	"TridentProj" : { # example
#	#		"scene" : load("res://Characters/Gura/Entities/TridentProj.tscn"),
#	#		"frame_data" : load("res://Characters/Gura/Entities/FrameData/TridentProj.tres"),
#	#		"spritesheet" : ResourceLoader.load("res://Characters/Gura/Entities/Spritesheets/TridentProjSprite.png")
#	#	},
#	}
	var directory = Directory.new()
	if directory.open(directory_name + "Entities") == OK:
		directory.list_dir_begin(true)
		var file_name = directory.get_next()
		while file_name != "":
			# load all needed files and add them to the dictionary
			if file_name.ends_with(".tscn"):
				var file_name2 = file_name.get_file().trim_suffix(".tscn")
				entity_data[file_name2] = {}
				entity_data[file_name2]["scene"] = \
					load(directory_name + "Entities/" + file_name)
				entity_data[file_name2]["frame_data"] = \
					ResourceLoader.load(directory_name + "Entities/FrameData/" + file_name2 + ".tres")
				entity_data[file_name2]["spritesheet"] = \
					ResourceLoader.load(directory_name + "Entities/Spritesheets/" + file_name2 + "Sprite.png")
			file_name = directory.get_next()
	else: print("Error: Cannot open Entities folder for character")
	
	
func set_up_sfx(directory_name): # scan all .tres files within SFX/FrameData folder and add them to "sfx_data" dictionary
#	var sfx_data = {
#	#	"WaterJet" : { # example
#	#		"frame_data" : load("res://Characters/Gura/SFX/FrameData/WaterJet.tres"),
#	#		"spritesheet" : ResourceLoader.load("res://Characters/Gura/SFX/Spritesheets/WaterJetSprite.png")
#	#	},
#	}
	var directory = Directory.new()
	if directory.open(directory_name + "SFX/FrameData/") == OK:
		directory.list_dir_begin(true)
		var file_name = directory.get_next()
		while file_name != "":
			# load all needed files and add them to the dictionary
			if file_name.ends_with(".tres"):
				var file_name2 = file_name.get_file().trim_suffix(".tres")
				sfx_data[file_name2] = {}
				sfx_data[file_name2]["frame_data"] = \
					ResourceLoader.load(directory_name + "SFX/FrameData/" + file_name)
				sfx_data[file_name2]["spritesheet"] = \
					ResourceLoader.load(directory_name + "SFX/Spritesheets/" + file_name2 + "Sprite.png")
			file_name = directory.get_next()
	else: print("Error: Cannot open SFX folder for character")
