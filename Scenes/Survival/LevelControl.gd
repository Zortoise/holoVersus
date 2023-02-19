extends Node

onready var loaded_mob_scene := load("res://Scenes/Survival/Mob.tscn")
onready var loaded_mob_entity_scene := load("res://Scenes/Survival/MobEntity.tscn")

var UniqLevel

# to save
var wave_active := true
var wave_timer := 0
var wave_ID := 1
var mob_ID_ref := -1

var mob_data = {
	
#	"TestMob": {
#		"scene" : load("res://Mobs/TestMob/TestMob.tscn")
#		"variant" : "Base"
#		"palettes" : {
#			"Red" : ResourceLoader.load("res://Mobs/TestMob/Palettes/Red.png")
#		}
#		"frame_data_array" : [
#			ResourceLoader.load("res://Mobs/TestMob/FrameData/Base.tres"), 
#			ResourceLoader.load("res://Mobs/TestMob/FrameData/Act1.tres"), 
#		]
#		"spritesheets" : {
#			"Base" : ResourceLoader.load("res://Mobs/TestMob/Spritesheets/Base.png")
#		},
#		"unique_audio": {
#			"example" : ResourceLoader.load("res://Mobs/TestMob/UniqueAudio/example.wav")
#		},
#		"entity_data" : {
#			"TridentProj" : {
#				"scene" : load("res://Mobs/TestMob/Entities/TridentProj.tscn"),
#				"frame_data" : ResourceLoader.load("res://Mobs/TestMob/Entities/FrameData/TridentProj.tres"),
#				"spritesheet" : ResourceLoader.load("res://Mobs/TestMob/Entities/Spritesheets/TridentProjSprite.png")
#			}
#		},
#		"sfx_data" : {
#			"WaterJet" : {
#				"frame_data" : ResourceLoader.load("res://Mobs/TestMob/SFX/FrameData/WaterJet.tres"),
#				"spritesheet" : ResourceLoader.load("res://Mobs/TestMob/SFX/Spritesheets/WaterJetSprite.png")
#			}
#		}
#	}
	
}


# SETUP LEVEL --------------------------------------------------------------------------------------------------

func init():
	
	var test_level = get_child(0) # test character node should be directly under this node
	test_level.free()
	
	UniqLevel = load("res://Levels/" + Globals.survival_level + ".tscn").instance()
	add_child(UniqLevel)
	move_child(UniqLevel, 0)
	
	for mob in UniqLevel.MOB_LIST:
		
		var directory_name = "res://Mobs/" + mob[0] + "/"
		var mob_name: String = mob[0] + mob[1] # example: "Golem" + "Fire" = "GolemFire"

		mob_data[mob_name] = {
			"scene" : load(directory_name + mob[0] + ".tscn"),
			"variant" : mob[1], 
			"palettes" : {},
			"frame_data_array" : [],
			"spritesheets" : {},
			"unique_audio": {},
			"entity_data" : {},
			"sfx_data" : {},
		}

		set_up_frame_data(mob_name, directory_name)
		set_up_palettes(mob_name, directory_name)
		set_up_spritesheets(mob_name, directory_name) # scan all .png files within Spritesheet folder and add them to "spritesheets" dictionary
		set_up_unique_audio(mob_name, directory_name) # scan all .wav files within Audio folder and add them to "unique_audio" dictionary
		set_up_entities(mob_name, directory_name) # scan all .tscn files within Entities folder and add them to "entities_data" dictionary
		set_up_sfx(mob_name, directory_name) # scan all .tres files within SFX/FrameData folder and add them to "sfx_data" dictionary
	
		
		if mob_name in UniqLevel.RESOURCE_BORROW:
			if "palettes" in UniqLevel.RESOURCE_BORROW[mob_name]:
				mob_data[mob_name].palettes.merge(UniqLevel.RESOURCE_BORROW[mob_name].palettes)
			if "frame_data_array" in UniqLevel.RESOURCE_BORROW[mob_name]:
				mob_data[mob_name].frame_data_array.append_array(UniqLevel.RESOURCE_BORROW[mob_name].frame_data_array)
			if "spritesheets" in UniqLevel.RESOURCE_BORROW[mob_name]:
				mob_data[mob_name].spritesheets.merge(UniqLevel.RESOURCE_BORROW[mob_name].spritesheets)
			if "unique_audio" in UniqLevel.RESOURCE_BORROW[mob_name]:
				mob_data[mob_name].unique_audio.merge(UniqLevel.RESOURCE_BORROW[mob_name].unique_audio)
			if "entity_data" in UniqLevel.RESOURCE_BORROW[mob_name]:
				mob_data[mob_name].entity_data.merge(UniqLevel.RESOURCE_BORROW[mob_name].entity_data)
			if "sfx_data" in UniqLevel.RESOURCE_BORROW[mob_name]:
				mob_data[mob_name].sfx_data.merge(UniqLevel.RESOURCE_BORROW[mob_name].sfx_data)
	
	
func set_up_frame_data(mob_name: String, directory_name):
	# open the FrameData folder and get the filenames of all files in it
	var directory = Directory.new()
	if directory.open(directory_name + "FrameData/") == OK:
		directory.list_dir_begin(true)
		var file_name = directory.get_next()
		while file_name != "":
			# load all needed files and add them to the dictionary
			if file_name.ends_with(".tres"):
				mob_data[mob_name].frame_data_array.append(ResourceLoader.load(directory_name + "FrameData/" + file_name))
			file_name = directory.get_next()
	else: print("Error: Cannot open FrameData folder for mob")
	
	
func set_up_palettes(mob_name: String, directory_name):
	# open the Palettes folder and get the filenames of all files in it
	var directory = Directory.new()
	if directory.open(directory_name + "Palettes/") == OK:
		directory.list_dir_begin(true)
		var file_name = directory.get_next()
		while file_name != "":
			# load all needed files and add them to the dictionary
			if file_name.ends_with(".png.import"):
				var file_name2 = file_name.get_file().trim_suffix(".png.import")
				mob_data[mob_name].palettes[file_name2] = ResourceLoader.load(directory_name + "Palettes/" + file_name2 + ".png")
			file_name = directory.get_next()
	else: print("Error: Cannot open Palettes folder for mob")
	
# fill up the "spritesheets" dictionary with spritesheets in the "Spritesheets" folder loaded and ready
func set_up_spritesheets(mob_name: String, directory_name):
	# open the Spritesheet folder and get the filenames of all files in it
	var directory = Directory.new()
	if directory.open(directory_name + "Spritesheets/") == OK:
		directory.list_dir_begin(true)
		var file_name = directory.get_next()
		while file_name != "":
			# load all needed files and add them to the dictionary
			if file_name.ends_with(".png.import"):
				var file_name2 = file_name.get_file().trim_suffix(".png.import")
				mob_data[mob_name].spritesheets[file_name2] = ResourceLoader.load(directory_name + "Spritesheets/" + file_name2 + ".png")
			file_name = directory.get_next()
	else: print("Error: Cannot open Spritesheets folder for mob")
	
func set_up_unique_audio(mob_name: String, directory_name):
	var directory = Directory.new()
	if directory.open(directory_name + "UniqueAudio/") == OK:
		directory.list_dir_begin(true)
		var file_name = directory.get_next()
		while file_name != "":
			# load all needed files and add them to the dictionary
			if file_name.ends_with(".wav.import"):
				var file_name2 = file_name.get_file().trim_suffix(".wav.import")
				mob_data[mob_name].unique_audio[file_name2] = \
					ResourceLoader.load(directory_name + "UniqueAudio/" + file_name2 + ".wav")
			file_name = directory.get_next()
	else: print("Error: Cannot open UniqueAudio folder for mob")
	
func set_up_entities(mob_name: String, directory_name): # scan all .tscn files within Entities folder and add them to "entities_data" dictionary
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
				mob_data[mob_name].entity_data[file_name2] = {}
				mob_data.mob_name.entity_data[file_name2]["scene"] = \
					load(directory_name + "Entities/" + file_name)
				mob_data[mob_name].entity_data[file_name2]["frame_data"] = \
					ResourceLoader.load(directory_name + "Entities/FrameData/" + file_name2 + ".tres")
				mob_data[mob_name].entity_data[file_name2]["spritesheet"] = \
					ResourceLoader.load(directory_name + "Entities/Spritesheets/" + file_name2 + "Sprite.png")
			file_name = directory.get_next()
	else: print("Error: Cannot open Entities folder for mob")
	
	
func set_up_sfx(mob_name: String, directory_name): # scan all .tres files within SFX/FrameData folder and add them to "sfx_data" dictionary
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
				mob_data[mob_name].sfx_data[file_name2] = {}
				mob_data[mob_name].sfx_data[file_name2]["frame_data"] = \
					ResourceLoader.load(directory_name + "SFX/FrameData/" + file_name)
				mob_data[mob_name].sfx_data[file_name2]["spritesheet"] = \
					ResourceLoader.load(directory_name + "SFX/Spritesheets/" + file_name2 + "Sprite.png")
			file_name = directory.get_next()
	else: print("Error: Cannot open SFX folder for mob")

#-----------------------------------------------------------------------------------------------------------------------------


func simulate():
	if wave_active:
		wave_timer += 1
	
	if wave_timer in UniqLevel.WAVES[wave_ID].timestamps:
		var spawn_array = UniqLevel.WAVES[wave_ID].timestamps[wave_timer] # array of dictionaries
		var mem_tester := 0
		for spawn in spawn_array:
			spawn_mob(spawn.mob, spawn.offset)
			mem_tester += 1
		if mem_tester > 10: print("LevelControl")
			
	if wave_timer > UniqLevel.WAVES[wave_ID].timestamps.keys().max():
		wave_active = false
	
# SPAWNERS -----------------------------------------------------------------------------------------------------------------------------

	
func spawn_mob(mob_name: String, offset: Vector2):
	var mob = loaded_mob_scene.instance()
	Globals.Game.get_node("Players").add_child(mob)
	Globals.Game.get_node("Players").move_child(mob, 0)
	var out_position = Globals.Game.middle_point + offset
	mob.init(mob_name, out_position)
	
func spawn_mob_entity(master_ID: int, creator_mob_ref: String, entity_ref: String, out_position, aux_data: Dictionary):
	var mob_entity = loaded_mob_entity_scene.instance()
	Globals.Game.get_node("MobEntities").add_child(mob_entity)
	mob_entity.init(master_ID, creator_mob_ref, entity_ref, out_position, aux_data)
	
# SAVE AND LOAD-----------------------------------------------------------------------------------------------------------------------------

func save_state():
	var state_data = {
		
		"wave_active" : wave_active,
		"wave_timer" : wave_timer,
		"wave_ID" : wave_ID,
		"mob_ID_ref" : mob_ID_ref,
		
	}
	return state_data
	
	
func load_state(state_data):
	
	wave_active = state_data.wave_active
	wave_timer = state_data.wave_timer
	wave_ID = state_data.wave_ID
	mob_ID_ref = state_data.mob_ID_ref

	
	
	
