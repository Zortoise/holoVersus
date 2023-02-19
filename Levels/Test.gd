extends Node


const MOB_LIST = [
	["TestMob", "Base"]
]

var RESOURCE_BORROW = {
	"TestMobBase" : {
		"palettes" : {
			"Red" : ResourceLoader.load("res://Characters/Gura/Palettes/2.png")
		},
		"frame_data_array" : [
			ResourceLoader.load("res://Characters/Gura/FrameData/Base.tres"),
			ResourceLoader.load("res://Characters/Gura/FrameData/F1.tres")
		],
		"spritesheets" : {
			"BaseSprite" : ResourceLoader.load("res://Characters/Gura/Spritesheets/BaseSprite.png"),
			"F1Sprite" : ResourceLoader.load("res://Characters/Gura/Spritesheets/F1Sprite.png"),
			"F1SfxOver" : ResourceLoader.load("res://Characters/Gura/Spritesheets/F1SfxOver.png"),
		},
		"unique_audio": {
			"water1" : ResourceLoader.load("res://Characters/Gura/UniqueAudio/water1.wav")
		},
		"entity_data" : {
#			"TridentProj" : {
#				"scene" : load("res://Mobs/TestMob/Entities/TridentProj.tscn"),
#				"frame_data" : ResourceLoader.load("res://Mobs/TestMob/Entities/FrameData/TridentProj.tres"),
#				"spritesheet" : ResourceLoader.load("res://Mobs/TestMob/Entities/Spritesheets/TridentProjSprite.png")
#			}
		},
		"sfx_data" : {
			"BigSplash" : {
				"frame_data" : ResourceLoader.load("res://Characters/Gura/SFX/FrameData/BigSplash.tres"),
				"spritesheet" : ResourceLoader.load("res://Characters/Gura/SFX/Spritesheets/BigSplashSprite.png")
			}
		},
	}
}

const WAVES = {
	1 : { # wave ID
		"timestamps" :
			{ # wave time
				1 : [
					{"mob" : "TestMobBase", "offset" : Vector2.ZERO},
					{"mob" : "TestMobBase", "offset" : Vector2(-100, 0)},
					{"mob" : "TestMobBase", "offset" : Vector2(100, 0)}
				],
				100 : [
					{"mob" : "TestMobBase", "offset" : Vector2.ZERO},
					{"mob" : "TestMobBase", "offset" : Vector2(-100, 0)},
					{"mob" : "TestMobBase", "offset" : Vector2(100, 0)}
				]
			}
	},
	2 : { # wave ID
		"timestamps" :
			{ # wave time
				1 : [
					{"mob" : "TestMobBase", "offset" : Vector2.ZERO}
				]
			}
	}
}
