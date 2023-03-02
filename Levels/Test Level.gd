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

# CHAIN: X, TOUGH: 0-5 (0/1 are weaker), SPEED: 0-6 (0/1 are slow), HP: 0-5 (0/1 are lower, 0 is 1 hp)
# POWER: 0-5 (0/1 are lower), PROJ_SPEED: 0-3 (0/1 are slow), COIN: X (around 40 limit)

const WAVES2 = {
	1 : { # wave ID
		"timestamps" :
			{ # wave time
				0 : [
					{"mob" : "GuraM", "level" : 8, "variant" : "base",
					"attr" : {
						Globals.mob_attr.CHAIN : 7,
						Globals.mob_attr.PROJ_SPEED : 0,
						Globals.mob_attr.WHITE_TRAIL : true,
						Globals.mob_attr.WHITE_PROJ_TRAIL : true,
						} },
				],
				7200 : [
					{"mob" : "GuraM", "level" : 8, "variant" : "base",
					"attr" : {
						Globals.mob_attr.SPEED : 6,
						Globals.mob_attr.PROJ_SPEED : 3,
						Globals.mob_attr.BLACK_TRAIL : true,
						Globals.mob_attr.BLACK_PROJ_TRAIL : true,
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
				1500 : [
					{"mob" : "GuraM", "level" : 3, "variant" : "jump",
					"attr" : {
						} },
				],
			}
		},
	2 : { # wave ID
		"timestamps" :
			{ # wave time
				0 : [
					{"mob" : "GuraM", "level" : 3, "variant" : "base",
					"attr" : {
						} },
				],
				1800 : [
					{"mob" : "GuraM", "level" : 3, "variant" : "zone",
					"attr" : {
						Globals.mob_attr.HP : 1,
						Globals.mob_attr.TOUGH : 0
						} },
				],
			}
		},
	3 : { # wave ID
		"timestamps" :
			{ # wave time
				0 : [
					{"mob" : "GuraM", "level" : 0, "variant" : "base",
					"attr" : {
						} },
					{"mob" : "GuraM", "level" : 0, "variant" : "base",
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
					{"mob" : "GuraM", "level" : 0, "variant" : "zone",
					"attr" : {
						Globals.mob_attr.HP : 1,
						Globals.mob_attr.TOUGH : 0
						} },
					{"mob" : "GuraM", "level" : 0, "variant" : "zone",
					"attr" : {
						Globals.mob_attr.HP : 1,
						Globals.mob_attr.TOUGH : 0
						} },
				],
				1800 : [
					{"mob" : "GuraM", "level" : 7, "variant" : "zone",
					"attr" : {
						Globals.mob_attr.TOUGH : 1
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
				2100 : [
					{"mob" : "GuraM", "level" : 5, "variant" : "jump",
					"attr" : {
						} },
				],
				4200 : [
					{"mob" : "GuraM", "level" : 5, "variant" : "rush",
					"attr" : {
						} },
				],
			}
		},
		
	6 : { # wave ID
		"timestamps" :
			{ # wave time
				0 : [
					{"mob" : "GuraM", "level" : 8, "variant" : "base",
					"attr" : {
						} },
				],
			}
		},
	7 : { # wave ID
		"timestamps" :
			{ # wave time
				0 : [
					{"mob" : "GuraM", "level" : 7, "variant" : "zone",
					"attr" : {
						Globals.mob_attr.PROJ_SPEED: 0,
						Globals.mob_attr.HP : 1,
						Globals.mob_attr.TOUGH : 0,
						} },
					{"mob" : "GuraM", "level" : 7, "variant" : "zone",
					"attr" : {
						Globals.mob_attr.PROJ_SPEED: 0,
						Globals.mob_attr.HP : 1,
						Globals.mob_attr.TOUGH : 0,
						} },
				],
			}
		},
	8 : { # wave ID
		"timestamps" :
			{ # wave time
				0 : [
					{"mob" : "GuraM", "level" : 8, "variant" : "base",
					"attr" : {
						Globals.mob_attr.HP : 0,
						Globals.mob_attr.RAGE : true,
						} },
					{"mob" : "GuraM", "level" : 8, "variant" : "base",
					"attr" : {
						Globals.mob_attr.HP : 0,
						Globals.mob_attr.RAGE : true,
						} },
					{"mob" : "GuraM", "level" : 8, "variant" : "base",
					"attr" : {
						Globals.mob_attr.HP : 0,
						Globals.mob_attr.RAGE : true,
						} },
				],
				1800 : [
					{"mob" : "GuraM", "level" : 8, "variant" : "base",
					"attr" : {
						Globals.mob_attr.HP : 0,
						Globals.mob_attr.RAGE : true,
						} },
					{"mob" : "GuraM", "level" : 8, "variant" : "base",
					"attr" : {
						Globals.mob_attr.HP : 0,
						Globals.mob_attr.RAGE : true,
						} },
					{"mob" : "GuraM", "level" : 8, "variant" : "base",
					"attr" : {
						Globals.mob_attr.HP : 0,
						Globals.mob_attr.RAGE : true,
						} },
					{"mob" : "GuraM", "level" : 8, "variant" : "base",
					"attr" : {
						Globals.mob_attr.HP : 0,
						Globals.mob_attr.RAGE : true,
						} },
				],
				3600 : [
					{"mob" : "GuraM", "level" : 8, "variant" : "base",
					"attr" : {
						Globals.mob_attr.HP : 0,
						Globals.mob_attr.RAGE : true,
						} },
					{"mob" : "GuraM", "level" : 8, "variant" : "base",
					"attr" : {
						Globals.mob_attr.HP : 0,
						Globals.mob_attr.RAGE : true,
						} },
					{"mob" : "GuraM", "level" : 8, "variant" : "base",
					"attr" : {
						Globals.mob_attr.HP : 0,
						Globals.mob_attr.RAGE : true,
						} },
					{"mob" : "GuraM", "level" : 8, "variant" : "base",
					"attr" : {
						Globals.mob_attr.HP : 0,
						Globals.mob_attr.RAGE : true,
						} },
					{"mob" : "GuraM", "level" : 8, "variant" : "base",
					"attr" : {
						Globals.mob_attr.HP : 0,
						Globals.mob_attr.RAGE : true,
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
						Globals.mob_attr.CHAIN : 7,
						Globals.mob_attr.SPEED : 0,
						Globals.mob_attr.HP : 1,
						Globals.mob_attr.TOUGH : 5,
						} },
				],
				600 : [
					{"mob" : "GuraM", "level" : 0, "variant" : "zone",
					"attr" : {
						Globals.mob_attr.HP : 0,
						} },
				],
				1200 : [
					{"mob" : "GuraM", "level" : 0, "variant" : "zone",
					"attr" : {
						Globals.mob_attr.HP : 0,
						} },
				],
				1800 : [
					{"mob" : "GuraM", "level" : 0, "variant" : "zone",
					"attr" : {
						Globals.mob_attr.HP : 0,
						} },
				],
				2400 : [
					{"mob" : "GuraM", "level" : 0, "variant" : "zone",
					"attr" : {
						Globals.mob_attr.HP : 0,
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
						Globals.mob_attr.CHAIN : 7,
						Globals.mob_attr.PROJ_SPEED : 0,
						Globals.mob_attr.WHITE_TRAIL : true,
						Globals.mob_attr.WHITE_PROJ_TRAIL : true,
						} },
				],
				6300 : [
					{"mob" : "GuraM", "level" : 8, "variant" : "base",
					"attr" : {
						Globals.mob_attr.SPEED : 6,
						Globals.mob_attr.PROJ_SPEED : 3,
						Globals.mob_attr.BLACK_TRAIL : true,
						Globals.mob_attr.BLACK_PROJ_TRAIL : true,
						} },
				],
			}
		},
	}


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
