extends Node

# NSAnims = Non-Sprite Animations, contain modulate animations and fade animations

enum priority {
	GRACE, FLASH, LETHAL, STUN, MOB_ARMOR, REPEAT, ACTION, VISUAL, HARMFUL, BUFF, UNIQUE, DARKEN
}

var modulate_animations = {
	"darken" : {
		"priority" : priority.DARKEN,
		"duration": 2,
		"loop" : false,
		"timestamps" : {
			0 :
			{
				"modulate" : Color(0.7, 0.7, 0.7),
			},
		}
	},
	"yellow_burst" : {
		"priority" : priority.ACTION,
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
		"priority" : priority.ACTION,
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
	"white_burst" :{
		"priority" : priority.ACTION,
		"duration": 25,
		"loop" : false,
		"timestamps" : {
			0 :
			{
				"modulate" : Color(5.0, 5.0, 5.0),
			},
			8 :
			{
				"modulate" : Color(3.0, 3.0, 3.0),
			},
			15 :
			{
				"modulate" : Color(2.0, 2.0, 2.0),
			},
			20 :
			{
				"modulate" : Color(1.5, 1.5, 1.5),
			},
			23 :
			{
				"modulate" : Color(1.25, 1.25, 1.25),
			},
		}
	},
#	"red_burst" : {
#		"duration": 24,
#		"loop" : false,
#		"timestamps" : {
#			0 :
#			{
#				"modulate" : Color(4.0, 4.0, 4.0),
#			},
#			4 :
#			{
#				"modulate" : Color(5.0, 1.0, 1.0),
#			},
#			8 :
#			{
#				"modulate" : Color(4.0, 4.0, 4.0),
#			},
#			12 :
#			{
#				"modulate" : Color(5.0, 1.0, 1.0),
#			},
#			16 :
#			{
#				"modulate" : Color(4.0, 4.0, 4.0),
#			},
#			20 :
#			{
#				"modulate" : Color(5.0, 1.0, 1.0),
#			},
#		}
#	},
#	"pink_reset" : {
#		"priority" : priority.ACTION,
#		"duration": 12,
#		"loop" : false,
#		"afterimage_trail" : 0,
#		"timestamps" : {
#			0 :
#			{
#				"modulate" : Color(4.0, 4.0, 4.0),
#			},
#			3 :
#			{
#				"modulate" : Color(5.0, 1.0, 1.5),
#			},
#			5 :
#			{
#				"modulate" : Color(4.0, 4.0, 4.0),
#			},
#			7 :
#			{
#				"modulate" : Color(5.0, 1.0, 1.5),
#			},
#		}
#	},
	"respawn_grace" :{
		"priority" : priority.GRACE,
		"duration": 6,
		"loop" : true,
		"timestamps" : {
			0 :
			{
				"modulate" : Color(2.0, 2.0, 2.0),
			},
			3 :
			{
				"modulate" : Color(0.8, 0.8, 0.8),
			},
		}
	},
	"unlaunch_flash" :{
		"priority" : priority.FLASH,
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
		"priority" : priority.FLASH,
		"duration": 5,
		"loop" : false,
		"timestamps" : {
			0 :
			{
				"modulate" : Color(2.0, 2.0, 2.0),
			},
		}
	},
	"repeat" :{
		"priority" : priority.REPEAT,
		"duration": 15,
		"loop" : false,
		"monochrome" : true,
		"timestamps" : {
			0 :
			{
				"modulate" : Color(1.0, 1.0, 1.0),
			},
		}
	},
	"dodge_flash" :{
		"priority" : priority.ACTION,
		"duration": 10,
		"loop" : false,
		"monochrome" : true,
		"timestamps" : {
			0 :
			{
				"modulate" : Color(3.0, 3.0, 3.0),
			},
			1 :
			{
				"modulate" : Color(2.0, 2.0, 2.0),
			},
			2 :
			{
				"modulate" : Color(1.75, 1.75, 1.75),
			},
			3 :
			{
				"modulate" : Color(1.5, 1.5, 1.5),
			},
			4 :
			{
				"modulate" : Color(1.25, 1.25, 1.25),
			},
		}
	},
	"block" :{
		"priority" : priority.ACTION,
		"duration": 16,
		"loop" : true,
		"timestamps" : {
			0 :
			{
				"modulate" : Color(2.0, 2.0, 2.0),
			},
			2 :
			{
				"modulate" : Color(1.75, 1.75, 1.75),
			},
			4 :
			{
				"modulate" : Color(1.5, 1.5, 1.5),
			},
			6 :
			{
				"modulate" : Color(1.25, 1.25, 1.25),
			},
			8 :
			{
				"modulate" : Color(1.0, 1.0, 1.0),
			},
			10 :
			{
				"modulate" : Color(1.25, 1.25, 1.25),
			},
			12 :
			{
				"modulate" : Color(1.5, 1.5, 1.5),
			},
			14 :
			{
				"modulate" : Color(1.75, 1.75, 1.75),
			},
		}
	},
	"strongblock_flash" :{
		"priority" : priority.FLASH,
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
	"weakblock_flash" :{
		"priority" : priority.FLASH,
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
	"mob_armor_time" :{
		"priority" : priority.MOB_ARMOR,
		"duration": 6,
		"loop" : true,
		"timestamps" : {
			0 :
			{
				"modulate" : Color(0.0, 0.0, 0.0),
			},
			2 :
			{
				"modulate" : Color(0.0, 0.0, 1.5),
			},
			4 :
			{
				"modulate" : Color(0.7, 0.7, 1.2),
			},
		}
	},
	"mob_armor_flash" :{
		"priority" : priority.FLASH,
		"duration": 10,
		"loop" : false,
		"timestamps" : {
			0 :
			{
				"modulate" : Color(0.0, 0.0, 0.0),
			},
			2 :
			{
				"modulate" : Color(0.3, 0.3, 0.8),
			},
			4 :
			{
				"modulate" : Color(0.5, 0.5, 0.75),
			},
			6 :
			{
				"modulate" : Color(0.7, 0.7, 0.9),
			},
			8 :
			{
				"modulate" : Color(0.9, 0.9, 1.0),
			},
		}
	},
	"armor_flash" :{
		"priority" : priority.FLASH,
		"duration": 10,
		"loop" : false,
		"timestamps" : {
			0 :
			{
				"modulate" : Color(0.0, 0.0, 0.0),
			},
			2 :
			{
				"modulate" : Color(0.8, 0.3, 0.3),
			},
			4 :
			{
				"modulate" : Color(0.75, 0.5, 0.5),
			},
			6 :
			{
				"modulate" : Color(0.9, 0.7, 0.7),
			},
			8 :
			{
				"modulate" : Color(1.0, 0.9, 0.9),
			},
		}
	},
	"passive_armor" :{
		"priority" : priority.BUFF,
		"duration": 16,
		"loop" : true,
		"timestamps" : {
			0 :
			{
				"modulate" : Color(0.0, 0.0, 0.0),
			},
			2 :
			{
				"modulate" : Color(0.8, 0.3, 0.3),
			},
			4 :
			{
				"modulate" : Color(0.75, 0.5, 0.5),
			},
			6 :
			{
				"modulate" : Color(0.9, 0.7, 0.7),
			},
			8 :
			{
				"modulate" : Color(1.0, 0.9, 0.9),
			},
			10 :
			{
				"modulate" : Color(0.9, 0.7, 0.7),
			},
			12 :
			{
				"modulate" : Color(0.75, 0.5, 0.5),
			},
			14 :
			{
				"modulate" : Color(0.8, 0.3, 0.3),
			},
		}
	},
	"perfect_guard_flash" : {
		"priority" : priority.FLASH,
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
		"priority" : priority.FLASH,
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
		"priority" : priority.ACTION,
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
	"blue_reset" : {
		"priority" : priority.ACTION,
		"duration": 24,
		"loop" : false,
		"timestamps" : {
			0 :
			{
				"modulate" : Color(1.0, 2.5, 2.5),
			},
			4 :
			{
				"modulate" : Color(0.8, 1.5, 5.0),
			},
			8 :
			{
				"modulate" : Color(1.0, 1.0, 1.5),
			},
			12 :
			{
				"modulate" : Color(1.0, 2.5, 2.5),
			},
			16 :
			{
				"modulate" : Color(0.8, 1.5, 5.0),
			},
			20 :
			{
				"modulate" : Color(1.0, 1.0, 1.5),
			},
		}
	},
#	"fdash_cancel2" : {
#		"duration": 22,
#		"loop" : false,
#		"timestamps" : {
#			0 :
#			{
#				"modulate" : Color(4.0, 4.0, 4.0),
#			},
#			4 : # this is the timestamp of the key
#			{
#				"modulate" : Color(1.2, 0.8, 0.8), # red
#			},
#			7 :
#			{
#				"modulate" : Color(1.2, 1.2, 0.8), # yellow
#			},
#			10 :
#			{
#				"modulate" : Color(0.8, 1.2, 0.8), # green
#			},
#			13 :
#			{
#				"modulate" : Color(0.8, 1.2, 1.2), # cyan
#			},
#			17 :
#			{
#				"modulate" : Color(0.8, 0.8, 1.2), # blue
#			},
#			19 :
#			{
#				"modulate" : Color(1.2, 0.8, 1.2), # purple
#			},
#		}
#	},
#	"air_block_flash" : {
#		"duration": 4,
#		"loop" : false,
##		"followup" : "EX_block_flash2",
#		"timestamps" : {
#			0 : # this is the timestamp of the key
#			{
#				"modulate" : Color(4.0, 4.0, 4.0),
#			},
#		}
#	},
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
		"priority" : priority.FLASH,
		"duration": 6,
		"loop" : false,
		"timestamps" : {
			0 :
			{
				"modulate" : Color(2.0, 0.0, 0.0),
			},
		}
	},
	"mob_hit_flash" :{
		"priority" : priority.FLASH,
		"duration": 7,
		"loop" : false,
		"timestamps" : {
			0 :
			{
				"modulate" : Color(0.0, 0.0, 0.0),
			},
			2 :
			{
				"modulate" : Color(2.0, 0.0, 0.0),
			},
			5 :
			{
				"modulate" : Color(1.5, 0.5, 0.5),
			},
		}
	},
	"sweet_flash" :{
		"priority" : priority.FLASH,
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
		"priority" : priority.FLASH,
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
	"stun_flash" :{
		"priority" : priority.FLASH,
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
	"stun" : {
		"priority" : priority.STUN,
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
		},
	},
	"crush" : {
		"priority" : priority.STUN,
		"duration": 12,
		"loop" : true,
		"timestamps" : {
			0 :
			{
				"modulate" : Color(1.5, 0.8, 0.5), # orange
			},
			4 :
			{
				"modulate" : Color(5.0, 0.7, 0.7),
			},
			10 :
			{
				"modulate" : Color(0.5, 0.2, 0.2)
			},
		}
	},
	"lethal_flash" :{
		"priority" : priority.FLASH,
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
		"priority" : priority.LETHAL,
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
		"priority" : priority.VISUAL,
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
		"priority" : priority.VISUAL,
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
	"aflame_blue" : { # for blue fire and shock
		"priority" : priority.VISUAL,
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
	"gravitize" : {
		"priority" : priority.HARMFUL,
		"duration": 12,
		"loop" : true,
		"timestamps" : {
			0 :
			{
				"modulate" : Color(0.3, 0.2, 0.65),
			},
			4 :
			{
				"modulate" : Color(0.7, 0.7, 1.5),
			},
			8 :
			{
				"modulate" : Color(0.9, 0.9, 1.0),
			},
		}
	},
	"ignite" : {
		"priority" : priority.HARMFUL,
		"duration": 12,
		"loop" : true,
		"timestamps" : {
			0 :
			{
				"modulate" : Color(4.0, 0.8, 0.8), # red
			},
			4 :
			{
				"modulate" : Color(2.5, 0.8, 0.3), # orange
			},
			8 :
			{
				"modulate" : Color(3.0, 1.25, 0.8), # yellow
			},
		}
	},
	"enfeeble" : {
		"priority" : priority.HARMFUL,
		"duration": 12,
		"loop" : true,
		"timestamps" : {
			0 :
			{
				"modulate" : Color(2.5, 1.0, 2.0),
			},
			4 :
			{
				"modulate" : Color(2.0, 0.7, 1.3),
			},
			10 :
			{
				"modulate" : Color(1.5, 1.0, 1.0),
			},
		}
	},
	"freeze" : {
		"priority" : priority.HARMFUL,
		"duration": 12,
		"loop" : true,
		"timestamps" : {
			0 :
			{
				"modulate" : Color(2.5, 2.5, 3.5),
			},
			4 :
			{
				"modulate" : Color(0.9, 1.5, 3.0),
			},
			10 :
			{
				"modulate" : Color(1.2, 1.2, 1.8),
			},
		}
	},
	"poison" : {
		"priority" : priority.HARMFUL,
		"duration": 40,
		"loop" : true,
		"timestamps" : {
			0 :
			{
				"modulate" : Color(0.8, 0.4, 0.6),
			},
			10 :
			{
				"modulate" : Color(1.1, 0.6, 1.0),
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



	
