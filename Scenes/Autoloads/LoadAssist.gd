extends Node

const ASSIST_BORROW = {
	"GuraA": {
		"icon": "res://Assists/GuraA/Icon.png",
		"NPC_data": {
			"scene" : "res://Assists/GuraA/GuraA.tscn",
			"frame_data_array" : [
				"res://Characters/Gura/FrameData/Base.tres",
				"res://Characters/Gura/FrameData/SP1.tres",
				"res://Characters/Gura/FrameData/SP9.tres",
			],
			"spritesheet" : {
				"BaseSprite" : "res://Characters/Gura/Spritesheets/BaseSprite.png",
				"SP1Sprite" : "res://Characters/Gura/Spritesheets/SP1Sprite.png",
				"SP1SfxOver" : "res://Characters/Gura/Spritesheets/SP1SfxOver.png",
				"SP9Sprite" : "res://Characters/Gura/Spritesheets/SP9Sprite.png",
				"SP9SfxOver" : "res://Characters/Gura/Spritesheets/SP9SfxOver.png",
				"SP9SfxUnder" : "res://Characters/Gura/Spritesheets/SP9SfxUnder.png",
			}
		},
		"entity_data": {
			"TridentProjA" : {
				"scene" : "res://Assists/GuraA/Entities/TridentProjA.tscn",
				"frame_data" : "res://Characters/Gura/Entities/FrameData/TridentProj.tres",
				"spritesheet" : "res://Characters/Gura/Entities/Spritesheets/TridentProjSprite.png",
			}
		},
		"sfx_data": {
			"TridentRing": {
				"frame_data" : "res://Characters/Gura/SFX/FrameData/TridentRing.tres",
				"spritesheet" : "res://Characters/Gura/SFX/Spritesheets/TridentRingSprite.png",
			},
			"WaterJet": {
				"frame_data" : "res://Characters/Gura/SFX/FrameData/WaterJet.tres",
				"spritesheet" : "res://Characters/Gura/SFX/Spritesheets/WaterJetSprite.png",
			},
			"WaterBurst": {
				"frame_data" : "res://Characters/Gura/SFX/FrameData/WaterBurst.tres",
				"spritesheet" : "res://Characters/Gura/SFX/Spritesheets/WaterBurstSprite.png",
			},
		},
		"audio_data": {
			"water1": "res://Characters/Gura/UniqueAudio/water1.wav",
			"water4": "res://Characters/Gura/UniqueAudio/water4.wav",
		},
	},
	
	"InaA": {
		"icon": "res://Assists/InaA/Icon.png",
		"NPC_data": {
			"scene" : "res://Assists/InaA/InaA.tscn",
			"frame_data_array" : [
				"res://Characters/Ina/FrameData/Base.tres",
				"res://Characters/Ina/FrameData/SP1.tres",
				"res://Characters/Ina/FrameData/SP4.tres",
			],
			"spritesheet" : {
				"BaseSprite" : "res://Characters/Ina/Spritesheets/BaseSprite.png",
				"SP1Sprite" : "res://Characters/Ina/Spritesheets/SP1Sprite.png",
				"SP1SfxOver" : "res://Characters/Ina/Spritesheets/SP1SfxOver.png",
				"SP1SfxUnder" : "res://Characters/Ina/Spritesheets/SP1SfxUnder.png",
				"SP4Sprite" : "res://Characters/Ina/Spritesheets/SP4Sprite.png",
				"SP4SfxOver" : "res://Characters/Ina/Spritesheets/SP4SfxOver.png",
			}
		},
		"entity_data": {
			"TakoA" : {
				"scene" : "res://Assists/InaA/Entities/TakoA.tscn",
				"frame_data" : "res://Characters/Ina/Entities/FrameData/Tako.tres",
				"spritesheet" : "res://Characters/Ina/Entities/Spritesheets/TakoSprite.png",
			},
			"InaDrillA" : {
				"scene" : "res://Assists/InaA/Entities/InaDrillA.tscn",
				"frame_data" : "res://Characters/Ina/Entities/FrameData/InaDrill.tres",
				"spritesheet" : "res://Characters/Ina/Entities/Spritesheets/InaDrillSprite.png",
			}
		},
		"sfx_data": {
			"Blink": {
				"frame_data" : "res://Characters/Ina/SFX/FrameData/Blink.tres",
				"spritesheet" : "res://Characters/Ina/SFX/Spritesheets/BlinkSprite.png",
			},
			"TakoFlash": {
				"frame_data" : "res://Characters/Ina/SFX/FrameData/TakoFlash.tres",
				"spritesheet" : "res://Characters/Ina/SFX/Spritesheets/TakoFlashSprite.png",
			},
		},
		"audio_data": {
			"energy8": "res://Characters/Ina/UniqueAudio/energy8.wav",
			"magic1": "res://Characters/Ina/UniqueAudio/magic1.wav",
			"magic3": "res://Characters/Ina/UniqueAudio/magic3.wav",
			"web1": "res://Characters/Ina/UniqueAudio/web1.wav",
		},
	}
	
}

func load_assist(assist_ref: String):
	
	if assist_ref in Loader.NPC_data: return # already loaded
	
	if assist_ref in ASSIST_BORROW: # is an assist that borrows resources from a playable character
		Loader.NPC_data[assist_ref] = {
			"icon" : ResourceLoader.load(ASSIST_BORROW[assist_ref].icon),
			"scene" : load(ASSIST_BORROW[assist_ref].NPC_data.scene),
			"frame_data_array" : [],
			"spritesheet" : {},
			"palettes" : {},
		}
		for frame_data in ASSIST_BORROW[assist_ref].NPC_data.frame_data_array:
			Loader.NPC_data[assist_ref].frame_data_array.append(ResourceLoader.load(frame_data))
		for spritename in ASSIST_BORROW[assist_ref].NPC_data.spritesheet.keys():
			Loader.NPC_data[assist_ref].spritesheet[spritename] = \
					ResourceLoader.load(ASSIST_BORROW[assist_ref].NPC_data.spritesheet[spritename])
					
		for entity_name in ASSIST_BORROW[assist_ref].entity_data.keys():
			if !entity_name in Loader.entity_data:
				Loader.entity_data[entity_name] = {
					"scene" : load(ASSIST_BORROW[assist_ref].entity_data[entity_name].scene),
					"frame_data" : ResourceLoader.load(ASSIST_BORROW[assist_ref].entity_data[entity_name].frame_data),
					"spritesheet" : ResourceLoader.load(ASSIST_BORROW[assist_ref].entity_data[entity_name].spritesheet),
				}
				
		for sfx_name in ASSIST_BORROW[assist_ref].sfx_data.keys():
			if !sfx_name in Loader.sfx:
				Loader.sfx[sfx_name] = {
					"frame_data" : ResourceLoader.load(ASSIST_BORROW[assist_ref].sfx_data[sfx_name].frame_data),
					"spritesheet" : ResourceLoader.load(ASSIST_BORROW[assist_ref].sfx_data[sfx_name].spritesheet),
				}
				
		for audio_name in ASSIST_BORROW[assist_ref].audio_data.keys():
			if !audio_name in Loader.audio:
				Loader.audio[audio_name] = ResourceLoader.load(ASSIST_BORROW[assist_ref].audio_data[audio_name])

		
	else: # standalone, load the data inside the folders
		pass # WIP


#	Loader.NPC_data["GuraA"] = {
#		"scene" : load("res://Assists/GuraA/GuraA.tscn"),
#		"frame_data_array" : Loader.char_data[NAME].frame_data_array,
#		"spritesheet" : Loader.char_data[NAME].spritesheet,
#		"palettes" : Loader.char_data[NAME].palettes,
#	}
#
#	Loader.entity_data["TridentProjA"] = {
#		"scene" : load("res://Assists/GuraA/Entities/TridentProjA.tscn"),
#		"frame_data" : load("res://Characters/Gura/Entities/FrameData/TridentProj.tres"),
#		"spritesheet" : ResourceLoader.load("res://Characters/Gura/Entities/Spritesheets/TridentProjSprite.png"),
#	}

#var NPC_data = {
##	"GuraTest" : {
##		"scene" : load("res://Characters/Gura/GuraNPCtest.tscn"),
##		"frame_data_array" : [
##			ResourceLoader.load("res://Characters/Gura/FrameData/Base.tres"), 
##			ResourceLoader.load("res://Characters/Gura/FrameData/F1.tres"), 
##		]
##		"spritesheet" : {
##			"BaseSprite" : ResourceLoader.load("res://Characters/Gura/Spritesheets/BaseSprite.png"),
##			"F1SfxOver" : ResourceLoader.load("res://Characters/Gura/Spritesheets/F1SfxOver.png"),
##		},
##		"palettes" : {
##			"2" : ResourceLoader.load("res://Characters/Gura/Palettes/2.png")
##		}
##	}
#}
#
#var entity_data = {
##	"TridentProj" : { # example
##		"scene" : load("res://Characters/Gura/Entities/TridentProj.tscn"),
##		"frame_data" : load("res://Characters/Gura/Entities/FrameData/TridentProj.tres"),
##		"spritesheet" : ResourceLoader.load("res://Characters/Gura/Entities/Spritesheets/TridentProjSprite.png")
##	},
##	"TridentProjM" : { # example
##		"scene" : load("res://Mobs/GuraM/Entities/TridentProjM.tscn"),
##		"frame_data" : load("res://Characters/Gura/Entities/FrameData/TridentProj.tres"),
##		"spritesheet" : ResourceLoader.load("res://Characters/Gura/Entities/Spritesheets/TridentProjSprite.png")
##	},
#}

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

#var audio = { # code in _ready() will load this with .wav files at start
## example:
##	"jump1" : ResourceLoader.load("res://Assets/Audio/Common/jump1.wav")
#}




	
	
	

