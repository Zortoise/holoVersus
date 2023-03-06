extends "res://Scenes/Survival/LoadCards.gd"

signal wave_start (wave_ID)
signal wave_cleared
signal level_cleared
# warning-ignore:unused_signal
signal level_failed

const STARTING_TIME = -48
const ITEM_LIMIT = 40

onready var loaded_mob_scene := load("res://Scenes/Survival/Mob.tscn")
onready var loaded_mob_entity_scene := load("res://Scenes/Survival/MobEntity.tscn")
onready var loaded_pickup_scene := load("res://Scenes/Survival/PickUp.tscn")
onready var loaded_card_scene := load("res://Scenes/Survival/Card.tscn")

var UniqLevel

# to save
var level_active := true
var wave_active := true
var wave_timer := STARTING_TIME
var wave_ID := 1
var mob_ID_ref := -1
var time_of_last_spawn = null
var wave_standby_timer := 120

var starting_coin := 0

var to_spawn = {
#	0: {
#		"offset" : _,
#		"mob_data" : _,
#	}
}

var item_data = {
#	"Coin": {
#		"scene" : load("res://Items/Coin/Coin.tscn"),
#		"frame_data" : ResourceLoader.load("res://Items/Coin/FrameData/Coin.tres"),
#		"spritesheet" : ResourceLoader.load("res://Items/Coin/Spritesheets/CoinSprite.png"),
#		"palettes" : {}
#	}
}


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
	
# warning-ignore:return_value_discarded
	connect("wave_start", Globals.Game.viewport, "_on_wave_start")
# warning-ignore:return_value_discarded
	connect("wave_cleared", Globals.Game.viewport, "_on_wave_cleared")
# warning-ignore:return_value_discarded
	connect("level_cleared", Globals.Game.viewport, "_on_level_cleared")
# warning-ignore:return_value_discarded
	connect("level_failed", Globals.Game.viewport, "_on_level_failed")
	
	var test_level = get_child(0) # test character node should be directly under this node
	test_level.free()
	
	UniqLevel = load("res://Levels/" + Globals.survival_level + ".tscn").instance()
	add_child(UniqLevel)
	move_child(UniqLevel, 0)
	
	if Globals.player_count == 1:
		Globals.Game.starting_stock_pts = UniqLevel.STARTING_STOCKS
		starting_coin = UniqLevel.STARTING_COIN
	else:
		Globals.Game.starting_stock_pts = int(ceil(UniqLevel.STARTING_STOCKS / 2.0))
		starting_coin = FMath.percent(UniqLevel.STARTING_COIN, 50)
	Globals.Game.stage_ref = UniqLevel.STAGE
	
	load_items()
	
	for mob in UniqLevel.MOB_LIST:
		
		var directory = "res://Mobs/" + mob[0] + "/"
		var borrow_directory = "res://Characters/" + mob[1] + "/"

		mob_data[mob[0]] = {
			"scene" : load(directory + mob[0] + ".tscn"),
			"palettes" : {},
			"frame_data_array" : [],
			"spritesheets" : {},
			"unique_audio": {},
			"entity_data" : {},
			"sfx_data" : {},
		}

		set_up_frame_data(mob[0], borrow_directory)
#		set_up_palettes(mob[0], directory_name)
		set_up_spritesheets(mob[0], borrow_directory) # scan all .png files within Spritesheet folder and add them to "spritesheets" dictionary
		set_up_unique_audio(mob[0], borrow_directory) # scan all .wav files within Audio folder and add them to "unique_audio" dictionary
#		set_up_entities(mob[0], directory_name) # scan all .tscn files within Entities folder and add them to "entities_data" dictionary
		set_up_sfx(mob[0], borrow_directory) # scan all .tres files within SFX/FrameData folder and add them to "sfx_data" dictionary
	
		
		if mob[0] in UniqLevel.RESOURCE_ADD:
			if "palettes" in UniqLevel.RESOURCE_ADD[mob[0]]:
				mob_data[mob[0]].palettes.merge(UniqLevel.RESOURCE_ADD[mob[0]].palettes)
#			if "frame_data_array" in UniqLevel.RESOURCE_ADD[mob]:
#				mob_data[mob].frame_data_array.append_array(UniqLevel.RESOURCE_ADD[mob].frame_data_array)
#			if "spritesheets" in UniqLevel.RESOURCE_ADD[mob]:
#				mob_data[mob].spritesheets.merge(UniqLevel.RESOURCE_ADD[mob].spritesheets)
#			if "unique_audio" in UniqLevel.RESOURCE_ADD[mob]:
#				mob_data[mob].unique_audio.merge(UniqLevel.RESOURCE_ADD[mob].unique_audio)
			if "entity_data" in UniqLevel.RESOURCE_ADD[mob[0]]:
				mob_data[mob[0]].entity_data.merge(UniqLevel.RESOURCE_ADD[mob[0]].entity_data)
#			if "sfx_data" in UniqLevel.RESOURCE_ADD[mob]:
#				mob_data[mob].sfx_data.merge(UniqLevel.RESOURCE_ADD[mob].sfx_data)
	
	Inventory.stock_pool()

		
# ------------------------------------------------------------------------------------------------------------------------------------
	
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


#func set_up_palettes(mob_name: String, directory_name):
#	# open the Palettes folder and get the filenames of all files in it
#	var directory = Directory.new()
#	if directory.open(directory_name + "Palettes/") == OK:
#		directory.list_dir_begin(true)
#		var file_name = directory.get_next()
#		while file_name != "":
#			# load all needed files and add them to the dictionary
#			if file_name.ends_with(".png.import"):
#				var file_name2 = file_name.get_file().trim_suffix(".png.import")
#				mob_data[mob_name].palettes[file_name2] = ResourceLoader.load(directory_name + "Palettes/" + file_name2 + ".png")
#			file_name = directory.get_next()
#	else: print("Error: Cannot open Palettes folder for mob")

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

#func set_up_entities(mob_name: String, directory_name): # scan all .tscn files within Entities folder and add them to "entities_data" dictionary
##	var entity_data = {
##	#	"TridentProj" : { # example
##	#		"scene" : load("res://Characters/Gura/Entities/TridentProj.tscn"),
##	#		"frame_data" : load("res://Characters/Gura/Entities/FrameData/TridentProj.tres"),
##	#		"spritesheet" : ResourceLoader.load("res://Characters/Gura/Entities/Spritesheets/TridentProjSprite.png")
##	#	},
##	}
#	var directory = Directory.new()
#	if directory.open(directory_name + "Entities") == OK:
#		directory.list_dir_begin(true)
#		var file_name = directory.get_next()
#		while file_name != "":
#			# load all needed files and add them to the dictionary
#			if file_name.ends_with(".tscn"):
#				var file_name2 = file_name.get_file().trim_suffix(".tscn")
#				mob_data[mob_name].entity_data[file_name2] = {}
#				mob_data.mob_name.entity_data[file_name2]["scene"] = \
#					load(directory_name + "Entities/" + file_name)
#				mob_data[mob_name].entity_data[file_name2]["frame_data"] = \
#					ResourceLoader.load(directory_name + "Entities/FrameData/" + file_name2 + ".tres")
#				mob_data[mob_name].entity_data[file_name2]["spritesheet"] = \
#					ResourceLoader.load(directory_name + "Entities/Spritesheets/" + file_name2 + "Sprite.png")
#			file_name = directory.get_next()
#	else: print("Error: Cannot open Entities folder for mob")


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
	
	
func load_items():
	for item in UniqLevel.ITEMS:
		item_data[item] = {}
		item_data[item]["scene"] = load("res://Items/" + item + "/" + item + ".tscn")
		item_data[item]["frame_data"] = ResourceLoader.load("res://Items/" + item + "/FrameData/" + item + ".tres")
		item_data[item]["spritesheet"] = ResourceLoader.load("res://Items/" + item + "/Spritesheets/" + item + "Sprite.png")
		item_data[item]["palettes"] = {}
		
		var directory = Directory.new()
		if directory.open("res://Items/" + item + "/Palettes/") == OK:
			directory.list_dir_begin(true)
			var file_name = directory.get_next()
			while file_name != "":
				# load all palettes and add them to the dictionary
				if file_name.ends_with(".png.import"):
					var file_name2 = file_name.get_file().trim_suffix(".png.import")
					item_data[item].palettes[file_name2] = ResourceLoader.load("res://Items/" + item + "/Palettes/" + file_name2 + ".png")
				file_name = directory.get_next()
		else: print("No Palettes folder for item: " + item)

#-----------------------------------------------------------------------------------------------------------------------------


func simulate():
	
	if !Globals.Game.game_set:
		var failure: = true
		for player in get_tree().get_nodes_in_group("PlayerNodes"):
			if player.stock_points_left > 0:
				failure = false
				break
		if failure:
			Globals.Game.game_set = true
			emit_signal("level_failed")
		
	if level_active:
		if wave_standby_timer > 0:
			if wave_ID > 1 and wave_standby_timer == 90:
				Globals.Game.card_menu.open_shop()
			elif wave_standby_timer == 60:
				emit_signal("wave_start", wave_ID)
			wave_standby_timer -= 1
		else:
	
#			if wave_timer in UniqLevel.WAVES[wave_ID].timestamps:
#				for spawn in UniqLevel.WAVES[wave_ID].timestamps[wave_timer]:
#					spawn_mob(spawn.mob, spawn.level, spawn.variant, spawn.attr, spawn.offset)
				
			if wave_timer + 48 in UniqLevel.WAVES[wave_ID].timestamps: # place warning
				to_spawn[wave_timer + 48] = []
				for spawn in UniqLevel.WAVES[wave_ID].timestamps[wave_timer + 48]:
					time_of_last_spawn = wave_timer + 48
					
					if "offset" in spawn:
						var out_position = Globals.Game.middle_point + spawn.offset
						out_position.y -= 25
						Globals.Game.spawn_SFX("Warning", "Warning", out_position, {})
						to_spawn[wave_timer + 48].append({"offset": spawn.offset, "mob_data": spawn,})
						
					else: # if no listed offset, random spot
						var new_spawn_point := Vector2(Globals.Game.rng_range(Globals.Game.left_corner, Globals.Game.right_corner), 0)
						var out_position = Globals.Game.middle_point + new_spawn_point
						out_position.y -= 25
						Globals.Game.spawn_SFX("Warning", "Warning", out_position, {})
						to_spawn[wave_timer + 48].append({"offset": new_spawn_point, "mob_data": spawn,})
					
			if wave_timer in to_spawn:
				for spawn_dict in to_spawn[wave_timer]:
					spawn_mob(spawn_dict.mob_data.mob, spawn_dict.mob_data.level, spawn_dict.mob_data.variant, spawn_dict.mob_data.attr, \
							spawn_dict.offset)
					
	
			if wave_timer > UniqLevel.WAVES[wave_ID].timestamps.keys().max():
				wave_active = false
				
			if time_of_last_spawn != null and wave_timer > time_of_last_spawn and get_tree().get_nodes_in_group("MobNodes").size() == 0:
				
				if wave_active: # fastforward to next wave
					var result = Globals.timestamp_find(UniqLevel.WAVES[wave_ID].timestamps.keys(), wave_timer, false)
					if result == null:
						wave_active = false # just in case
					else:
						wave_timer = result - 48 - 1
						
				if !wave_active: # wave cleared!
					next_wave()
					return
				
			if wave_active:
				wave_timer += 1
		
		
func next_wave():
	wave_ID += 1
	
	for player in get_tree().get_nodes_in_group("PlayerNodes"):
		if player.stock_points_left == 0:
			player.stock_points_left = 1
			player.get_node("RespawnTimer").stop()
	
	if !wave_ID in UniqLevel.WAVES:
		all_waves_cleared()
		return
	else:
		to_spawn = {}
		wave_active = true
		wave_timer = STARTING_TIME
		time_of_last_spawn = null
		wave_standby_timer = 210
		emit_signal("wave_cleared")
		
	
func all_waves_cleared():
	level_active = false
	
#	return
	emit_signal("level_cleared")

	
	
	
# SPAWNERS -----------------------------------------------------------------------------------------------------------------------------

	
func spawn_mob(mob_name: String, level: int, variant: String, attr: Dictionary, offset: Vector2):
	var mob = loaded_mob_scene.instance()
	Globals.Game.get_node("Players").add_child(mob)
	Globals.Game.get_node("Players").move_child(mob, 0)
	var out_position = Globals.Game.middle_point + offset
	mob.init(mob_name, level, variant, attr, out_position)
	return mob
	
func spawn_mob_entity(master_ID: int, creator_mob_ref: String, entity_ref: String, out_position, aux_data: Dictionary, \
		mob_level: int, mob_attr: Dictionary, out_palette_ref = null):
	var mob_entity = loaded_mob_entity_scene.instance()
	Globals.Game.get_node("MobEntities").add_child(mob_entity)
	mob_entity.init(master_ID, creator_mob_ref, entity_ref, out_position, aux_data, mob_level, mob_attr, out_palette_ref)
	return mob_entity
	
# in_item_ref: String, in_position: Vector2, aux_data: Dictionary, in_lifespan: int = BASE_LIFESPAN, in_palette_ref = null
func spawn_item(item_ref: String, out_position: Vector2, aux_data: Dictionary, lifespan = null, palette_ref = null):
	if Globals.Game.get_node("PickUps").get_child_count() <= ITEM_LIMIT:
		var pickup = loaded_pickup_scene.instance()
		Globals.Game.get_node("PickUps").add_child(pickup)
		pickup.init(item_ref, out_position, aux_data, lifespan, palette_ref)
		return pickup
	
# SAVE AND LOAD-----------------------------------------------------------------------------------------------------------------------------

func save_state():
	var state_data = {
		
		"level_active" : level_active,
		"wave_active" : wave_active,
		"wave_timer" : wave_timer,
		"wave_ID" : wave_ID,
		"mob_ID_ref" : mob_ID_ref,
		"time_of_last_spawn" : time_of_last_spawn,
		"wave_standby_timer" : wave_standby_timer,
		
	}
	return state_data
	
	
func load_state(state_data):
	
	level_active = state_data.level_active
	wave_active = state_data.wave_active
	wave_timer = state_data.wave_timer
	wave_ID = state_data.wave_ID
	mob_ID_ref = state_data.mob_ID_ref
	time_of_last_spawn = state_data.time_of_last_spawn
	wave_standby_timer = state_data.wave_standby_timer

	
	
	
