extends Node

const LEVEL_NAME = "Test Level"

const STAGE = "Grid" # filename
const STARTING_STOCKS = 5
const STARTING_COIN = 100
const PRICE_SCALING = 10

const MUSIC = {
		"name" : "Survival1", # to not play the same music as the one currently being played
		"audio_filename" : "res://Assets/Music/Survival1.ogg",
		"loop_end": 157.09,
		"vol" : -4,
	}

const MOB_LIST = [
	["GuraM", "Gura"],
]

const ITEMS = [
	"Coin"
]

var RESOURCE_ADD = {
	"GuraM" : {
		"palettes" : {
			"mimic" : ResourceLoader.load("res://Characters/Gura/Palettes/4.png")
		},
		"entity_data" : {
			"TridentProjM" : {
				"scene" : load("res://Mobs/GuraM/Entities/TridentProjM.tscn"),
				"frame_data" : ResourceLoader.load("res://Characters/Gura/Entities/FrameData/TridentProj.tres"),
				"spritesheet" : ResourceLoader.load("res://Characters/Gura/Entities/Spritesheets/TridentProjSprite.png")
			},
			"WaterDriveM" : {
				"scene" : load("res://Mobs/GuraM/Entities/WaterDriveM.tscn"),
				"frame_data" : ResourceLoader.load("res://Characters/Gura/Entities/FrameData/WaterDrive.tres"),
				"spritesheet" : ResourceLoader.load("res://Characters/Gura/Entities/Spritesheets/WaterDriveSprite.png")
			}
			
		}
	}	
}


#enum mob_attr {POWER, HP, TOUGH, SPEED, CHAIN, TRAIL, BLACK_TRAIL, WHITE_TRAIL, PROJ_SPEED,
#		PROJ_TRAIL, WHITE_PROJ_TRAIL, BLACK_PROJ_TRAIL, RAGE, COIN, PASSIVE_ARMOR}

# CHAIN: X, TOUGH: 0-5 (0/1 are weaker), SPEED: 0-6 (0/1 are slow), HP: 0-5 (0/1 are lower, 0 is 1 hp)
# POWER: 0-5 (0/1 are lower), PROJ_SPEED: 0-3 (0/1 are slow), COIN: X (add to loot pool, 40 limit)

const WAVES2 = {
	1 : { # wave ID
		"timestamps" :
			{ # wave time
				0 : [
					{"mob" : "GuraM", "level" : 1, "variant" : "rush",
					"attr" : {
						Em.mob_attr.SPEED : 0,
#						Em.mob_attr.HP : 4,
#						Em.mob_attr.TOUGH : 5,
#						Em.mob_attr.TRAIL : true,
#						Em.mob_attr.RAGE : true,
						} },
				],
			}
		}
	}


const WAVES = {
	1 : { # wave ID
		"timestamps" :
			{ # wave time
				0 : [
					{"mob" : "GuraM", "level" : 0, "variant" : "base",
					"attr" : {
						} },
				],
				3000 : [
					{"mob" : "GuraM", "level" : 2, "variant" : "zone",
					"attr" : {
						Em.mob_attr.HP : 1,
						Em.mob_attr.TOUGH : 0
						} },
				],
				6000 : [
					{"mob" : "GuraM", "level" : 2, "variant" : "jump",
					"attr" : {
						} },
				],
			}
		},
	2 : { # wave ID
		"timestamps" :
			{ # wave time
				0 : [
					{"mob" : "GuraM", "level" : 2, "variant" : "dash",
					"attr" : {
						} },
				],
				3000 : [
					{"mob" : "GuraM", "level" : 2, "variant" : "shark",
					"attr" : {
						} },
				],
			}
		},
	3 : { # wave ID
		"timestamps" :
			{ # wave time
				0 : [
					{"mob" : "GuraM", "level" : 2, "variant" : "base",
					"attr" : {
						} },
					{"mob" : "GuraM", "level" : 2, "variant" : "base",
					"attr" : {
						} },
				],
				3000 : [
					{"mob" : "GuraM", "level" : 5, "variant" : "base",
					"attr" : {
						} },
				],
			}
		},
	4 : { # wave ID
		"timestamps" :
			{ # wave time
				0 : [
					{"mob" : "GuraM", "level" : 3, "variant" : "zone",
					"attr" : {
						Em.mob_attr.HP : 1,
						Em.mob_attr.TOUGH : 0
						} },
					{"mob" : "GuraM", "level" : 3, "variant" : "zone",
					"attr" : {
						Em.mob_attr.HP : 1,
						Em.mob_attr.TOUGH : 0
						} },
				],
				1800 : [
					{"mob" : "GuraM", "level" : 6, "variant" : "zone",
					"attr" : {
						Em.mob_attr.HP : 1,
						Em.mob_attr.TOUGH : 1
						} },
				],
			}
		},
		
	5 : { # wave ID
		"timestamps" :
			{ # wave time
				0 : [
					{"mob" : "GuraM", "level" : 5, "variant" : "shark",
					"attr" : {
						} },
				],
				1800 : [
					{"mob" : "GuraM", "level" : 5, "variant" : "jump",
					"attr" : {
						} },
				],
				4800 : [
					{"mob" : "GuraM", "level" : 8, "variant" : "base",
					"attr" : {
						} },
				],
			}
		},
		
	6 : { # wave ID
		"timestamps" :
			{ # wave time
				0 : [
					{"mob" : "GuraM", "level" : 5, "variant" : "rush",
					"attr" : {
						} },
					{"mob" : "GuraM", "level" : 5, "variant" : "shark",
					"attr" : {
						} },
				],
				4200 : [
					{"mob" : "GuraM", "level" : 8, "variant" : "rush",
					"attr" : {
						Em.mob_attr.PASSIVE_ARMOR: true,
						Em.mob_attr.SPEED: 1,
						} },
				],
			}
		},
	7 : { # wave ID
		"timestamps" :
			{ # wave time
				0 : [
					{"mob" : "GuraM", "level" : 0, "variant" : "base",
					"attr" : {
						Em.mob_attr.HP : 1,
						Em.mob_attr.RAGE : true,
						} },
					{"mob" : "GuraM", "level" : 0, "variant" : "base",
					"attr" : {
						Em.mob_attr.HP : 1,
						Em.mob_attr.RAGE : true,
						} },
					{"mob" : "GuraM", "level" : 0, "variant" : "base",
					"attr" : {
						Em.mob_attr.HP : 1,
						Em.mob_attr.RAGE : true,
						} },
				],
				1800 : [
					{"mob" : "GuraM", "level" : 0, "variant" : "base",
					"attr" : {
						Em.mob_attr.HP : 1,
						Em.mob_attr.RAGE : true,
						} },
					{"mob" : "GuraM", "level" : 0, "variant" : "base",
					"attr" : {
						Em.mob_attr.HP : 1,
						Em.mob_attr.RAGE : true,
						} },
					{"mob" : "GuraM", "level" : 0, "variant" : "base",
					"attr" : {
						Em.mob_attr.HP : 1,
						Em.mob_attr.RAGE : true,
						} },
					{"mob" : "GuraM", "level" : 0, "variant" : "base",
					"attr" : {
						Em.mob_attr.HP : 1,
						Em.mob_attr.RAGE : true,
						} },
				],
				3600 : [
					{"mob" : "GuraM", "level" : 0, "variant" : "base",
					"attr" : {
						Em.mob_attr.HP : 1,
						Em.mob_attr.RAGE : true,
						} },
					{"mob" : "GuraM", "level" : 0, "variant" : "base",
					"attr" : {
						Em.mob_attr.HP : 1,
						Em.mob_attr.RAGE : true,
						} },
					{"mob" : "GuraM", "level" : 0, "variant" : "base",
					"attr" : {
						Em.mob_attr.HP : 1,
						Em.mob_attr.RAGE : true,
						} },
					{"mob" : "GuraM", "level" : 0, "variant" : "base",
					"attr" : {
						Em.mob_attr.HP : 1,
						Em.mob_attr.RAGE : true,
						} },
					{"mob" : "GuraM", "level" : 0, "variant" : "base",
					"attr" : {
						Em.mob_attr.HP : 1,
						Em.mob_attr.RAGE : true,
						} },
				],
			}
		},
	8 : { # wave ID
		"timestamps" :
			{ # wave time
				0 : [
					{"mob" : "GuraM", "level" : 6, "variant" : "zone",
					"attr" : {
						Em.mob_attr.PROJ_SPEED: 0,
						Em.mob_attr.HP : 1,
						Em.mob_attr.TOUGH : 0,
						} },
					{"mob" : "GuraM", "level" : 6, "variant" : "zone",
					"attr" : {
						Em.mob_attr.PROJ_SPEED: 0,
						Em.mob_attr.HP : 1,
						Em.mob_attr.TOUGH : 0,
						} },
				],
				4200 : [
					{"mob" : "GuraM", "level" : 6, "variant" : "dash",
					"attr" : {
						Em.mob_attr.RAGE : true,
						Em.mob_attr.HP : 1,
						Em.mob_attr.TOUGH : 1,
						} },
					{"mob" : "GuraM", "level" : 6, "variant" : "base",
					"attr" : {
						Em.mob_attr.RAGE : true,
						Em.mob_attr.HP : 1,
						Em.mob_attr.TOUGH : 1,
						} },
				],
			}
		},
	9 : { # wave ID
		"timestamps" :
			{ # wave time
				0 : [
					{"mob" : "GuraM", "level" : 8, "variant" : "rush",
					"attr" : {
						Em.mob_attr.SPEED : 0,
						Em.mob_attr.HP : 4,
						Em.mob_attr.TOUGH : 5,
						Em.mob_attr.TRAIL : true,
						Em.mob_attr.RAGE : true,
						} },
				],
				600 : [
					{"mob" : "GuraM", "level" : 0, "variant" : "zone",
					"attr" : {
						Em.mob_attr.HP : 1,
						} },
				],
				1200 : [
					{"mob" : "GuraM", "level" : 0, "variant" : "zone",
					"attr" : {
						Em.mob_attr.HP : 1,
						} },
				],
				1800 : [
					{"mob" : "GuraM", "level" : 0, "variant" : "zone",
					"attr" : {
						Em.mob_attr.HP : 1,
						} },
				],
				2400 : [
					{"mob" : "GuraM", "level" : 0, "variant" : "zone",
					"attr" : {
						Em.mob_attr.HP : 1,
						} },
				],
			}
		},
	10 : { # wave ID
		"timestamps" :
			{ # wave time
				0 : [
					{"mob" : "GuraM", "level" : 8, "variant" : "base",
					"attr" : {
						Em.mob_attr.CHAIN : 7,
						Em.mob_attr.PROJ_SPEED : 0,
						Em.mob_attr.WHITE_TRAIL : true,
						Em.mob_attr.WHITE_PROJ_TRAIL : true,
						Em.mob_attr.HP : 2,
						} },
				],
				6300 : [
					{"mob" : "GuraM", "level" : 8, "variant" : "base",
					"attr" : {
						Em.mob_attr.SPEED : 6,
						Em.mob_attr.PROJ_SPEED : 3,
						Em.mob_attr.BLACK_TRAIL : true,
						Em.mob_attr.BLACK_PROJ_TRAIL : true,
						} },
				],
				12600 : [
					{"mob" : "GuraM", "level" : 8, "variant" : "base",
					"attr" : {
						Em.mob_attr.CHAIN : 7,
						Em.mob_attr.PROJ_SPEED : 0,
						Em.mob_attr.WHITE_TRAIL : true,
						Em.mob_attr.WHITE_PROJ_TRAIL : true,
						} },
					{"mob" : "GuraM", "level" : 8, "variant" : "base",
					"attr" : {
						Em.mob_attr.SPEED : 6,
						Em.mob_attr.PROJ_SPEED : 3,
						Em.mob_attr.BLACK_TRAIL : true,
						Em.mob_attr.BLACK_PROJ_TRAIL : true,
						} },
				],
			}
		},
	}


#				0 : [
#					{"mob" : "GuraM", "level" : 8, "variant" : "base",
#					"attr" : {
#						Em.mob_attr.SPEED : 6,
#						Em.mob_attr.CHAIN : 10,
#						Em.mob_attr.BLACK_TRAIL : true,
#						Em.mob_attr.PROJ_SPEED : 3,
#						Em.mob_attr.BLACK_PROJ_TRAIL : true,
#						} },
#				],

#				0 : [
#					{"mob" : "GuraM", "level" : 8, "variant" : "base",
#					"attr" : {
#						Em.mob_attr.BLACK_TRAIL : true,
#						} },
#					{"mob" : "GuraM", "level" : 8, "variant" : "base",
#					"attr" : {
#						Em.mob_attr.BLACK_TRAIL : true,
#						} },
#				],
