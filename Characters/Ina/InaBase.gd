extends Node2D

# CHARACTER DATA --------------------------------------------------------------------------------------------------

const NAME = "Ina'nis"
const ORDER = 0

# character movement stats, use to overwrite
const SPEED = 280 * FMath.S # ground speed
const AIR_STRAFE_SPEED_MOD = 16 # percent of ground speed
const AIR_STRAFE_LIMIT_MOD = 700 # speed limit of air strafing, limit depends on calculated air strafe speed
const JUMP_SPEED = 700 * FMath.S
const VAR_JUMP_TIME = 20 # frames after jumping where holding jump will reduce gravity
const VAR_JUMP_SLOW_POINT = 5 # frames where JUMP_SLOW starts
const DIR_JUMP_HEIGHT_MOD = 85 # % of JUMP_SPEED when jumping while holding left/right
const HORIZ_JUMP_BOOST_MOD = 20 # % of SPEED to gain when jumping with left/right held
const HORIZ_JUMP_SPEED_MOD = 150 # % of velocity.x to gain when jumping with left/right held
const AIR_HORIZ_JUMP_SPEED_MOD = 125
const HIGH_JUMP_SLOW = 10 # slow down velocity.y to PEAK_DAMPER_LIMIT when jumping with up/jump held
const SHORT_JUMP_SLOW = 20 # slow down velocity.y to PEAK_DAMPER_LIMIT when jumping with up/jump unheld
const AIR_JUMP_HEIGHT_MOD = 70 # percentage of JUMP_SPEED, reduce height of air jumps
const REVERSE_AIR_JUMP_MOD = 70 # percentage of SPEED when air jumping backwards
const WALL_AIR_JUMP_HORIZ_MOD = 150 # percentage of SPEED when wall jumping
const WALL_AIR_JUMP_VERT_MOD = 70 # percentage of JUMP_SPEED when wall jumping
const GRAVITY_MOD = 90 # make sure variable's a float
const TERMINAL_VELOCITY_MOD = 600 # affect terminal velocity downward
const FASTFALL_MOD = 115 # fastfall speed, mod of terminal velocity
const FRICTION = 7 # between 0 and 100
const ACCELERATION = 5 # between 0 and 100
const AIR_RESISTANCE = 3 # between 0 and 100
const FALL_GRAV_MOD = 40 # reduced gravity when going down
const EYE_LEVEL = 12 # number of pixels EX Flash appears above position

const MAX_AIR_JUMP = 2
const MAX_AIR_DASH = 1
const MAX_AIR_DODGE = 1
const MAX_SUPER_DASH = 1
const GRD_DASH_SPEED = 120 * FMath.S # distance
const AIR_DASH_SPEED = 120 * FMath.S # distance
const SDASH_SPEED = 385 * FMath.S # super dash
const SDASH_TURN_RATE = 6 # exact navigate speed when sdashing

# fixed?
const DODGE_GG_COST = 3000
const DODGE_SPEED = 1000 * FMath.S

# fixed?
const IMPULSE_MOD = 150 # multiply by SPEED to get impulse velocity
const WAVE_DASH_SPEED_MOD = 110 # affect speed of wavelanding, multiplied by GRD_DASH_SPEED

# fixed?
#const HITSTUN_REDUCTION_AT_MAX_GG = 70 # max reduction in hitstun when defender's Guard Gauge is at 200%, heavy characters have lower?
#const KB_BOOST_AT_MAX_GG = 400 # max increase of knockback when defender's Guard Gauge is at 200%, light characters have higher?

const DAMAGE_VALUE_LIMIT = 1300

const GG_REGEN_AMOUNT = 13 # exact GG regened per frame when GG < 100%
const GRD_BLOCK_GG_COST = 30 # exact GG loss per frame when blocking on ground
const AIR_BLOCK_GG_COST = 40 # exact GG loss per frame when blocking in air
const CHIP_DMG_MOD = 20 # % of damage taken as chip damage when blocking

# fixed?
const BASE_EX_REGEN = 20
const HITSTUN_EX_REGEN_MOD = 200  # increase EX Regen during hitstun
const LANDED_EX_REGEN_MOD = 600 # increase EX Regen when doing an unblocked attack
const BLOCKED_EX_REGEN_MOD = 200 # increase EX Regen when doing a blocked attack
const BLOCKING_EX_REGEN_MOD = 200 # increase EX Regen when blocking attack
const PARRYING_EX_REGEN_MOD = 600 # increase EX Regen when parrying attack
#const ATTACK_EX_REGEN_MOD = 200 # increase EX Regen when doing a physical attack, even on whiff
#const NON_ATTACK_EX_REGEN_MOD = 50 # reduce EX Regen when using a non-attack like projectile

const TRANSIT_SDASH = ["BlinkTransit", "EBlinkTransit"] # unique dash transits that you can quick cancel into SDash
const TRANSIT_DODGE = ["BlinkTransit"] # unique dash transits that you can quick cancel into Dodge

const TRAITS = [Em.trait.VULN_GRD_DASH, Em.trait.VULN_AIR_DASH]

const DEFAULT_HITSPARK_TYPE = Em.hitspark_type.HIT
const DEFAULT_HITSPARK_PALETTE = "dark_purple"
const SDHitspark_COLOR = "dark_purple"

const PALETTE_TO_PORTRAIT = {
	1: Color(0.84, 0.77, 1.00),
	2: Color(0.86, 0.75, 0.67),
}

const PALETTE_TO_HITSPARK_PALETTE = {
	1: "dark_purple",
	2: "pink",
}

const MUSIC = {
		"name" : "GuraTheme", # to not play the same music as the one currently being played
		"audio_filename" : "res://Characters/Gura/Music/GuraTheme.ogg",
#		"loop_start": 27.42,
		"loop_end": 164.57,
		"vol" : -7,
	}

const UNIQUE_DATA_REF = {
	"float_used" : false,
	"float_time" : 60,
	"blink_vec" : Vector2.ZERO,
	"combination" : [],
	"instant_command" : null,
	"draw_lock" : false,
}

const STARTERS = ["L1", "L2", "L3", "F1", "F2", "F3", "H", "aL1", "aL2", "aL3", "aF1", "aF2", "aF3", "aH", "aSP1", "aSP2", "aSP3", \
		"aSP4", "aSP4[ex]", "aSP5", "aSP5[ex]", "aSP1[ex]", "aSP2[ex]"]

const UP_TILTS = ["L3", "F3", "aL3", "aF3", "aSP4", "aSP4[ex]"] # to know which moves can be cancelled from jumpsquat

# list of movenames that will emit EX flash
const EX_FLASH_ANIM = ["aSP1[ex]", "aSP1[ex][u]", "aSP1[ex][d]", "aSP2[ex]", "aSP4[ex]", "aSP5[ex]"]

# this contain move_data for each active animation this character has
# use trim_suffix("Active") on animation name to find move in the database
const MOVE_DATABASE = {
	"L1" : {
		Em.move.ATK_TYPE : Em.atk_type.LIGHT,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 50,
		Em.move.KB : 350 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.RADIAL,
		Em.move.ATK_LVL : 2,
		Em.move.KB_ANGLE : 50,
		Em.move.ATK_ATTR : [],
		Em.move.MOVE_SOUND : { ref = "whoosh15", aux_data = {"vol" : -5} },
		Em.move.HIT_SOUND : [{ ref = "book1", aux_data = {} }, { ref = "impact9", aux_data = {"vol" : -10} }],
	},

	"L2" : {
		Em.move.ATK_TYPE : Em.atk_type.LIGHT,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 55,
		Em.move.KB : 445 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 4,
		Em.move.KB_ANGLE : -80,
		Em.move.ATK_ATTR : [Em.atk_attr.VULN_LIMBS],
		Em.move.MOVE_SOUND : { ref = "whoosh3", aux_data = {"vol" : -8} },
		Em.move.HIT_SOUND : { ref = "cut1", aux_data = {"vol" : -15} },
	},
	
	"L3" : {
		Em.move.ATK_TYPE : Em.atk_type.LIGHT,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 55,
		Em.move.KB : 445 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.RADIAL,
		Em.move.ATK_LVL : 4,
		Em.move.KB_ANGLE : 0,
		Em.move.ATK_ATTR : [Em.atk_attr.VULN_LIMBS, Em.atk_attr.ANTI_AIR, Em.atk_attr.ONLY_CHAIN_ON_HIT],
		Em.move.MOVE_SOUND : { ref = "whoosh6", aux_data = {"vol" : -10, "bus" : "PitchDown"} },
		Em.move.HIT_SOUND : [{ ref = "cut8", aux_data = {"vol" : -5} }, { ref = "cut8", aux_data = {"vol" : -2, "bus" : "LowPass"} }],
	},
	
	"F1" : {
		Em.move.ATK_TYPE : Em.atk_type.FIERCE,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 70,
		Em.move.KB : 450 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 4,
		Em.move.KB_ANGLE : -60,
		Em.move.ATK_ATTR : [Em.atk_attr.VULN_LIMBS],
		Em.move.MOVE_SOUND : [{ ref = "blast4", aux_data = {"vol" : -15} }, { ref = "web1", aux_data = {"vol" : -12} }],
		Em.move.HIT_SOUND : { ref = "impact42", aux_data = {"vol" : -15} },
	},
	"F2" : {
		Em.move.ATK_TYPE : Em.atk_type.FIERCE,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 70,
		Em.move.KB : 450 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 4,
		Em.move.KB_ANGLE : -80,
		Em.move.ATK_ATTR : [Em.atk_attr.VULN_LIMBS],
		Em.move.MOVE_SOUND : [{ ref = "blast4", aux_data = {"vol" : -15} }, { ref = "web1", aux_data = {"vol" : -12} }],
		Em.move.HIT_SOUND : { ref = "impact42", aux_data = {"vol" : -15} },
	},
	"F3" : {
		Em.move.ATK_TYPE : Em.atk_type.FIERCE,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 70,
		Em.move.KB : 450 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 4,
		Em.move.KB_ANGLE : -90,
		Em.move.ATK_ATTR : [Em.atk_attr.VULN_LIMBS],
		Em.move.MOVE_SOUND : [{ ref = "blast4", aux_data = {"vol" : -15} }, { ref = "web1", aux_data = {"vol" : -12} }],
		Em.move.HIT_SOUND : { ref = "impact42", aux_data = {"vol" : -15} },
	},
	"H" : {
		Em.move.ATK_TYPE : Em.atk_type.HEAVY,
		Em.move.HITCOUNT : 3,
		Em.move.LAST_HIT_RANGE : 19,
		Em.move.IGNORE_TIME : 4,
		Em.move.FIXED_HITSTOP: 7,
		Em.move.FIXED_ATKER_HITSTOP: 3,
		Em.move.DMG : 35,
		Em.move.KB : 550 * FMath.S,
		Em.move.FIXED_KB_MULTI : 100 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.RADIAL,
		Em.move.ATK_LVL : 6,
		Em.move.KB_ANGLE : 0,
		Em.move.ATK_ATTR : [Em.atk_attr.VULN_LIMBS],
		Em.move.MOVE_SOUND : [{ ref = "vortex1", aux_data = {"vol" : -17} }, { ref = "magic1", aux_data = {"vol" : -14} }],
		Em.move.HIT_SOUND : { ref = "impact43", aux_data = {"vol" : -18} },
	},

	"aL1" : {
		Em.move.ATK_TYPE : Em.atk_type.LIGHT,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 50,
		Em.move.KB : 445 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 3,
		Em.move.KB_ANGLE : -60,
		Em.move.ATK_ATTR : [],
		Em.move.MOVE_SOUND : { ref = "whoosh13", aux_data = {"vol" : -10} },
		Em.move.HIT_SOUND : [{ ref = "book2", aux_data = {"vol" : -5} }, { ref = "book1", aux_data = {"vol" : 5} } ],
	},
	"aL2" : {
		Em.move.ATK_TYPE : Em.atk_type.LIGHT,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 55,
		Em.move.KB : 445 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 4,
		Em.move.KB_ANGLE : -60,
		Em.move.ATK_ATTR : [Em.atk_attr.VULN_LIMBS],
		Em.move.MOVE_SOUND : [{ ref = "whip1", aux_data = {"vol" : -10, "bus" : "PitchDown"} }, { ref = "web1", aux_data = {"vol" : -10} }],
		Em.move.HIT_SOUND : { ref = "cut5", aux_data = {"vol" : -8} },
	},
	"aL3" : {
		Em.move.ATK_TYPE : Em.atk_type.LIGHT,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 55,
		Em.move.KB : 445 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 4,
		Em.move.KB_ANGLE : -80,
		Em.move.ATK_ATTR : [Em.atk_attr.VULN_LIMBS],
		Em.move.MOVE_SOUND : [{ ref = "whip1", aux_data = {"vol" : -11} }, { ref = "web1", aux_data = {"vol" : -10} }],
		Em.move.HIT_SOUND : { ref = "cut5", aux_data = {"vol" : -8} },
	},
	"aF1" : {
		Em.move.ATK_TYPE : Em.atk_type.FIERCE,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 70,
		Em.move.KB : 450 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 4,
		Em.move.KB_ANGLE : -60,
		Em.move.ATK_ATTR : [Em.atk_attr.VULN_LIMBS],
		Em.move.MOVE_SOUND : [{ ref = "blast4", aux_data = {"vol" : -15} }, { ref = "web1", aux_data = {"vol" : -12} }],
		Em.move.HIT_SOUND : { ref = "impact42", aux_data = {"vol" : -15} },
	},
	"aF2" : {
		Em.move.ATK_TYPE : Em.atk_type.FIERCE,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 70,
		Em.move.KB : 450 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 4,
		Em.move.KB_ANGLE : -50,
		Em.move.ATK_ATTR : [Em.atk_attr.VULN_LIMBS],
		Em.move.MOVE_SOUND : [{ ref = "blast4", aux_data = {"vol" : -15} }, { ref = "web1", aux_data = {"vol" : -12} }],
		Em.move.HIT_SOUND : { ref = "impact42", aux_data = {"vol" : -15} },
	},
	"aF3" : {
		Em.move.ATK_TYPE : Em.atk_type.FIERCE,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 70,
		Em.move.KB : 450 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 4,
		Em.move.KB_ANGLE : -85,
		Em.move.ATK_ATTR : [Em.atk_attr.VULN_LIMBS],
		Em.move.MOVE_SOUND : [{ ref = "blast4", aux_data = {"vol" : -15} }, { ref = "web1", aux_data = {"vol" : -12} }],
		Em.move.HIT_SOUND : { ref = "impact42", aux_data = {"vol" : -15} },
	},
	"aH" : {
		Em.move.ATK_TYPE : Em.atk_type.HEAVY,
		Em.move.HITCOUNT : 3,
		Em.move.LAST_HIT_RANGE : 28,
		Em.move.IGNORE_TIME : 5,
		Em.move.FIXED_HITSTOP: 7,
		Em.move.FIXED_ATKER_HITSTOP: 3,
		Em.move.DMG : 30,
		Em.move.KB : 500 * FMath.S,
		Em.move.FIXED_KB_MULTI : 445 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.RADIAL,
		Em.move.ATK_LVL : 5,
		Em.move.PRIORITY_ADD: -2,
		Em.move.KB_ANGLE : 0,
		Em.move.ATK_ATTR : [Em.atk_attr.VULN_LIMBS, Em.atk_attr.NO_STRAFE_NORMAL],
		Em.move.MOVE_SOUND : [{ ref = "whoosh3", aux_data = {"vol" : -8, "bus" : "PitchDown"} }, { ref = "web1", aux_data = {"vol" : -10} }],
		Em.move.HIT_SOUND : [{ ref = "impact40", aux_data = {"vol" : -20} }, { ref = "impact34", aux_data = {"vol" : -20} }],
	},
	
	"aSP1": {
		Em.move.ATK_TYPE : Em.atk_type.SPECIAL,
		Em.move.ATK_ATTR : [],
	},
	
	"aSP1[ex]": {
		Em.move.ATK_TYPE : Em.atk_type.EX,
		Em.move.ATK_ATTR : [],
	},
	
	"aSP2": {
		Em.move.ATK_TYPE : Em.atk_type.SPECIAL,
		Em.move.ATK_ATTR : [],
	},
	
	"aSP2[ex]": {
		Em.move.ATK_TYPE : Em.atk_type.EX,
		Em.move.ATK_ATTR : [],
	},
	
	"aSP3": {
		Em.move.ATK_TYPE : Em.atk_type.SPECIAL,
		Em.move.ATK_ATTR : [],
	},
	
	"aSP4": {
		Em.move.ATK_TYPE : Em.atk_type.SPECIAL,
		Em.move.ATK_ATTR : [],
	},
	
	"aSP4[ex]": {
		Em.move.ATK_TYPE : Em.atk_type.EX,
		Em.move.ATK_ATTR : [],
	},
	
	"aSP5": {
		Em.move.ATK_TYPE : Em.atk_type.SPECIAL,
		Em.move.ATK_ATTR : [],
	},
	
	"aSP5[ex]": {
		Em.move.ATK_TYPE : Em.atk_type.EX,
		Em.move.ATK_ATTR : [Em.atk_attr.VULN_LIMBS, Em.atk_attr.NO_SDASH_CANCEL],
	},
}



