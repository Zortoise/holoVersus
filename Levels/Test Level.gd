extends Node

const STAGE = "Grid"
const STARTING_STOCKS = 5

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
			}
		}
	}	
}


#enum mob_attr {POWER, HP, TOUGH, SPEED, CHAIN, TRAIL, BLACK_TRAIL, WHITE_TRAIL, PROJ_SPEED,
#		PROJ_TRAIL, WHITE_PROJ_TRAIL, BLACK_PROJ_TRAIL, RAGE, COIN}

# CHAIN: X, TOUGH: 0-3, SPEED: 0-6 (0/1 are slow), HP: 0-5 (0/1 are lower, 0 is 1 hp)
# POWER: 0-5 (0/1 are lower), PROJ_SPEED: 0-3 (0/1 are slow), COIN: X (around 40 limit)

const WAVES = {
	1 : { # wave ID
		"timestamps" :
			{ # wave time
				0 : [
					{"mob" : "GuraM", "level" : 3, "variant" : "rush",
					"attr" : {
						} },
					{"mob" : "GuraM", "level" : 3, "variant" : "rush",
					"attr" : {
						} },
				],
			}
	},
	2 : { # wave ID
		"timestamps" :
			{ # wave time
				0 : [
					{"mob" : "GuraM", "level" : 0, "variant" : "zone",
					"attr" : {
						} },
				],
			}
	},
	3 : { # wave ID
		"timestamps" :
			{ # wave time
				0 : [
					{"mob" : "GuraM", "level" : 0, "variant" : "rush",
					"attr" : {
						} },
				],
			}
	},
	4 : { # wave ID
		"timestamps" :
			{ # wave time
				0 : [
					{"mob" : "GuraM", "level" : 0, "variant" : "jump",
					"attr" : {
						} },
				],
			}
	},
	5 : { # wave ID
		"timestamps" :
			{ # wave time
				0 : [
					{"mob" : "GuraM", "level" : 0, "variant" : "shark",
					"attr" : {
						} },
				],
			}
	},
	6 : { # wave ID
		"timestamps" :
			{ # wave time
				0 : [
					{"mob" : "GuraM", "level" : 0, "variant" : "base",
					"attr" : {
						} },
				],
			}
	},
	7 : { # wave ID
		"timestamps" :
			{ # wave time
				0 : [
					{"mob" : "GuraM", "level" : 0, "variant" : "zone",
					"attr" : {
						} },
				],
			}
	},
	8 : { # wave ID
		"timestamps" :
			{ # wave time
				0 : [
					{"mob" : "GuraM", "level" : 0, "variant" : "rush",
					"attr" : {
						} },
				],
			}
	},
	9 : { # wave ID
		"timestamps" :
			{ # wave time
				0 : [
					{"mob" : "GuraM", "level" : 0, "variant" : "jump",
					"attr" : {
						} },
				],
			}
	},
	10 : { # wave ID
		"timestamps" :
			{ # wave time
				0 : [
					{"mob" : "GuraM", "level" : 0, "variant" : "shark",
					"attr" : {
						} },
				],
			}
	},
#	2 : { # wave ID
#		"timestamps" :
#			{ # wave time
#				0 : [
#					{"mob" : "GuraM", "level" : 8, "variant" : "base", "offset" : Vector2(-300, 0),
#					"attr" : {
#						Globals.mob_attr.HP : 0
#						} },
#					{"mob" : "GuraM", "level" : 8, "variant" : "base", "offset" : Vector2(300, 0),
#					"attr" : {
#						Globals.mob_attr.HP : 0
#						} },
#				],
#				1 : [
#					{"mob" : "GuraM", "level" : 8, "variant" : "base", "offset" : Vector2(-200, 0),
#					"attr" : {
#						Globals.mob_attr.HP : 0
#						} },
#				],
#				999 : [
#					{"mob" : "GuraM", "level" : 8, "variant" : "base", "offset" : Vector2(200, 0),
#					"attr" : {
#						Globals.mob_attr.HP : 0
#						} },
#				],
#			}
#	},
}

#					"attr" : {
#						Globals.mob_attr.HP : 0,
#						Globals.mob_attr.CHAIN : 10,
#						Globals.mob_attr.SPEED : 0,
#						Globals.mob_attr.TOUGH : 3,
#						Globals.mob_attr.POWER : 5,
#						Globals.mob_attr.PROJ_SPEED : 0,
#						} },


#const WAVES = {
#	1 : { # wave ID
#		"timestamps" :
#			{ # wave time
#				0 : [
#					{"mob" : "GuraM", "level" : 0, "variant" : "base",
#					"attr" : {
#						} },
#				],
#				1200 : [
#					{"mob" : "GuraM", "level" : 0, "variant" : "zone",
#					"attr" : {
#						} },
#				],
#			}
#	},


#				0 : [
#					{"mob" : "GuraM", "level" : 8, "variant" : "base",
#					"attr" : {
#						Globals.mob_attr.SPEED : 6,
#						Globals.mob_attr.CHAIN : 10,
#						Globals.mob_attr.BLACK_TRAIL : true,
#						Globals.mob_attr.PROJ_SPEED : 3,
#						Globals.mob_attr.BLACK_PROJ_TRAIL : true,
#						} },
#				],

#				0 : [
#					{"mob" : "GuraM", "level" : 8, "variant" : "base",
#					"attr" : {
#						Globals.mob_attr.BLACK_TRAIL : true,
#						} },
#					{"mob" : "GuraM", "level" : 8, "variant" : "base",
#					"attr" : {
#						Globals.mob_attr.BLACK_TRAIL : true,
#						} },
#				],
