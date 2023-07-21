extends Node2D

# CHARACTER DATA --------------------------------------------------------------------------------------------------

const NAME = "Ina'nis"

# character movement stats, use to overwrite
const SPEED = 300 * FMath.S # ground speed
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
const GRAVITY_MOD = 80 # make sure variable's a float
const TERMINAL_VELOCITY_MOD = 500 # affect terminal velocity downward
const FASTFALL_MOD = 115 # fastfall speed, mod of terminal velocity
const FRICTION = 4 # between 0 and 100
const ACCELERATION = 3 # between 0 and 100
const AIR_RESISTANCE = 3 # between 0 and 100
const FALL_GRAV_MOD = 40 # reduced gravity when going down
const EYE_LEVEL = 9 # number of pixels EX Flash appears above position

const MAX_AIR_JUMP = 2
const MAX_AIR_DASH = 1
const MAX_AIR_DODGE = 1
const MAX_SUPER_DASH = 1
const GRD_DASH_SPEED = 120 * FMath.S # distance
const AIR_DASH_SPEED = 120 * FMath.S # distance
const SDASH_SPEED = 385 * FMath.S # super dash
const SDASH_TURN_RATE = 6 # exact navigate speed when sdashing

# fixed?
const DODGE_GG_COST = 2500
const DODGE_SPEED = 1000 * FMath.S

# fixed?
const IMPULSE_MOD = 150 # multiply by SPEED to get impulse velocity
const WAVE_DASH_SPEED_MOD = 110 # affect speed of wavelanding, multiplied by GRD_DASH_SPEED

# fixed?
const HITSTUN_REDUCTION_AT_MAX_GG = 70 # max reduction in hitstun when defender's Guard Gauge is at 200%, heavy characters have lower?
const KB_BOOST_AT_MAX_GG = 400 # max increase of knockback when defender's Guard Gauge is at 200%, light characters have higher?

const DAMAGE_VALUE_LIMIT = 1300

const GG_REGEN_AMOUNT = 13 # exact GG regened per frame when GG < 100%
const GRD_BLOCK_GG_COST = 30 # exact GG loss per frame when blocking on ground
const AIR_BLOCK_GG_COST = 40 # exact GG loss per frame when blocking in air
const WEAKBLOCK_CHIP_DMG_MOD = 20 # % of damage taken as chip damage when blocking

# fixed?
const BASE_EX_REGEN = 20
const HITSTUN_EX_REGEN_MOD = 200  # increase EX Regen during hitstun
const LANDED_EX_REGEN_MOD = 600 # increase EX Regen when doing an unblocked attack
const BLOCKED_EX_REGEN_MOD = 200 # increase EX Regen when doing a blocked attack
#const ATTACK_EX_REGEN_MOD = 200 # increase EX Regen when doing a physical attack, even on whiff
#const NON_ATTACK_EX_REGEN_MOD = 50 # reduce EX Regen when using a non-attack like projectile

const TRANSIT_SDASH = ["BlinkTransit", "EBlinkTransit"] # unique dash transits that you can quick cancel into SDash
const TRANSIT_DODGE = ["BlinkTransit"] # unique dash transits that you can quick cancel into Dodge

const TRAITS = [Em.trait.VULN_GRD_DASH, Em.trait.VULN_AIR_DASH]

const DEFAULT_HITSPARK_TYPE = Em.hitspark_type.HIT
const DEFAULT_HITSPARK_PALETTE = "purple"
const SDHitspark_COLOR = "purple"

const PALETTE_TO_PORTRAIT = {
	1: Color(0.75, 0.93, 1.25),
	2: Color(1.20, 0.70, 0.70),
	3: Color(0.75, 0.90, 0.70),
	4: Color(1.00, 1.00, 1.10),
}

const PALETTE_TO_HITSPARK_PALETTE = {
	1: "dark_purple",
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
}

const STARTERS = ["L1", "L2", "L3", "F1", "F2", "F3", "H", "aL1", "aL2", "aL3", "aF1", "aF2", "aF3", "aH"]

const UP_TILTS = ["L3", "F3", "aL3", "aF3"] # to know which moves can be cancelled from jumpsquat

# list of movenames that will emit EX flash
const EX_FLASH_ANIM = []

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
		Em.move.ATK_ATTR : [Em.atk_attr.VULN_LIMBS],
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
		Em.move.IGNORE_TIME : 4,
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
	
	"SP1": {
		Em.move.ATK_TYPE : Em.atk_type.SPECIAL, # used for chaining
#		"reset_type" : Globals.reset_type.ACTIVE_RESET,
		Em.move.ATK_ATTR : [Em.atk_attr.AIR_REPEAT],
	},
	"SP1[ex]": {
		Em.move.ATK_TYPE : Em.atk_type.EX,
		Em.move.MOVE_SOUND : [{ ref = "water4", aux_data = {"vol" : -20,} }, { ref = "whoosh12", aux_data = {} }],
		Em.move.ATK_ATTR : [Em.atk_attr.AIR_REPEAT],
	},
	
	"aSP2" : {
		Em.move.ATK_TYPE : Em.atk_type.SPECIAL,
		Em.move.HITCOUNT : 3,
		Em.move.IGNORE_TIME : 6,
		Em.move.DMG : 40,
		Em.move.KB : 500 * FMath.S,
		Em.move.FIXED_KB_MULTI : 300 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 4,
		Em.move.KB_ANGLE : -45,
#		"reset_type" : Globals.reset_type.ACTIVE_RESET,
		Em.move.ATK_ATTR : [Em.atk_attr.WHIFF_SDASH_CANCEL],
		Em.move.MOVE_SOUND : [{ ref = "water4", aux_data = {"vol" : -15,} }, { ref = "blast3", aux_data = {"vol" : -10, "bus" : "LowPass"} }],
		Em.move.HIT_SOUND : [{ ref = "impact11", aux_data = {"vol" : -20} }, { ref = "water1", aux_data = {"vol" : -8} }],
	},
	"aSP2[h]" : {
		Em.move.ATK_TYPE : Em.atk_type.SPECIAL,
		Em.move.ROOT : "aSP2",
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 80,
		Em.move.KB : 500 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 4,
		Em.move.KB_ANGLE : -90,
#		"reset_type" : Globals.reset_type.ACTIVE_RESET,
		Em.move.ATK_ATTR : [Em.atk_attr.WHIFF_SDASH_CANCEL],
		Em.move.MOVE_SOUND : [{ ref = "water4", aux_data = {"vol" : -15,} }, { ref = "blast3", aux_data = {"vol" : -10, "bus" : "LowPass"} }],
		Em.move.HIT_SOUND : [{ ref = "impact11", aux_data = {"vol" : -20} }, { ref = "water1", aux_data = {"vol" : -8} }],
	},
	"aSP2[ex]" : {
		Em.move.ATK_TYPE : Em.atk_type.EX,
		Em.move.HITCOUNT : 5,
		Em.move.IGNORE_TIME : 5,
		Em.move.DMG : 35,
		Em.move.KB : 600 * FMath.S,
		Em.move.FIXED_KB_MULTI : 300 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 5,
		Em.move.KB_ANGLE : -45,
		Em.move.ATK_ATTR : [Em.atk_attr.PROJ_ARMOR_ACTIVE],
		Em.move.MOVE_SOUND : [{ ref = "water4", aux_data = {"vol" : -15,} }, { ref = "blast3", aux_data = {"vol" : -10, "bus" : "LowPass"} }],
		Em.move.HIT_SOUND : [{ ref = "impact11", aux_data = {"vol" : -20} }, { ref = "water1", aux_data = {"vol" : -8} }],
	},
	
	"aSP3" : {
		Em.move.ATK_TYPE : Em.atk_type.SPECIAL,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 40,
		Em.move.KB : 600 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 4,
		Em.move.KB_ANGLE : -90,
#		"reset_type" : Globals.reset_type.EARLY_RESET,
		Em.move.ATK_ATTR : [Em.atk_attr.AUTOCHAIN],
		Em.move.MOVE_SOUND : { ref = "water8", aux_data = {"vol" : -10,} },
		Em.move.HIT_SOUND : { ref = "water7", aux_data = {"vol" : -9} },
	},
	"aSP3b" : {
		Em.move.ATK_TYPE : Em.atk_type.SPECIAL,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 70,
		Em.move.KB : 475 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.RADIAL,
		Em.move.ATK_LVL : 4,
		Em.move.KB_ANGLE : 0,
		Em.move.ATK_ATTR : [Em.atk_attr.FOLLOW_UP],
		Em.move.HIT_SOUND : { ref = "water7", aux_data = {"vol" : -7} },
	},
	"aSP3[h]" : {
		Em.move.ATK_TYPE : Em.atk_type.SPECIAL,
		Em.move.ROOT : "aSP3",
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 40,
		Em.move.KB : 650 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 4,
		Em.move.KB_ANGLE : -90,
#		"reset_type" : Globals.reset_type.EARLY_RESET,
		Em.move.ATK_ATTR : [Em.atk_attr.AUTOCHAIN],
		Em.move.MOVE_SOUND : { ref = "water8", aux_data = {"vol" : -10,} },
		Em.move.HIT_SOUND : { ref = "water7", aux_data = {"vol" : -9} },
	},
	"aSP3b[h]" : {
		Em.move.ATK_TYPE : Em.atk_type.SPECIAL,
		Em.move.ROOT : "aSP3b",
#		"no_revoke_time" : 0,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 70,
		Em.move.KB : 500 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.RADIAL,
		Em.move.ATK_LVL : 4,
		Em.move.KB_ANGLE : 0,
		Em.move.ATK_ATTR : [Em.atk_attr.FOLLOW_UP],
		Em.move.HIT_SOUND : { ref = "water7", aux_data = {"vol" : -7} },
	},
	"aSP3[ex]" : {
		Em.move.ATK_TYPE : Em.atk_type.EX,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 60,
		Em.move.KB : 650 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 5,
		Em.move.KB_ANGLE : -90,
		Em.move.ATK_ATTR : [Em.atk_attr.AUTOCHAIN],
		Em.move.MOVE_SOUND : { ref = "water8", aux_data = {"vol" : -10,} },
		Em.move.HIT_SOUND : { ref = "water7", aux_data = {"vol" : -9} },
	},
	"aSP3b[ex]" : {
		Em.move.ATK_TYPE : Em.atk_type.EX,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 120,
		Em.move.KB : 525 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.RADIAL,
		Em.move.ATK_LVL : 5,
		Em.move.KB_ANGLE : 0,
		Em.move.ATK_ATTR : [Em.atk_attr.FOLLOW_UP],
		Em.move.HIT_SOUND : { ref = "water7", aux_data = {"vol" : -7} },
	},
	
	"SP4": {
		Em.move.ATK_TYPE : Em.atk_type.SPECIAL,
		Em.move.ATK_ATTR : [],
#		"reset_type" : Globals.reset_type.ACTIVE_RESET,
		Em.move.MOVE_SOUND : [{ ref = "water4", aux_data = {"vol" : -16,} }, { ref = "blast4", aux_data = {"vol" : -16,} }],
	},
	"SP4[h]": {
		Em.move.ATK_TYPE : Em.atk_type.SPECIAL,
		Em.move.ATK_ATTR : [],
#		"reset_type" : Globals.reset_type.ACTIVE_RESET,
		Em.move.MOVE_SOUND : [{ ref = "water4", aux_data = {"vol" : -16,} }, { ref = "blast4", aux_data = {"vol" : -16,} }],
	},
	"SP4[ex]": {
		Em.move.ATK_TYPE : Em.atk_type.EX,
		Em.move.ATK_ATTR : [],
		Em.move.MOVE_SOUND : [{ ref = "water4", aux_data = {"vol" : -16,} }, { ref = "blast4", aux_data = {"vol" : -16,} }],
	},
	
	"aSP5" : {
		Em.move.ATK_TYPE : Em.atk_type.SPECIAL,
#		"quick_turn_limit" : 4, # if on ground, can only quick turn on the first X frames
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 80,
		Em.move.KB : 450 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 5,
		Em.move.HITSPARK_PALETTE : "red",
		Em.move.KB_ANGLE : -45,
		Em.move.KB_ANGLE : -45,
#		"reset_type" : Globals.reset_type.STARTUP_RESET,
		Em.move.ATK_ATTR : [],
		Em.move.MOVE_SOUND : [{ ref = "launch2", aux_data = {"vol" : -5,} }, { ref = "impact33", aux_data = {"vol" : -23,} }],
		Em.move.HIT_SOUND : { ref = "cut5", aux_data = {"vol" : -7} },
	},
	"aSP5[h]" : {
		Em.move.ATK_TYPE : Em.atk_type.SPECIAL,
		Em.move.ROOT: "aSP5",
#		"quick_turn_limit" : 4, # if on ground, can only quick turn on the first X frames
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 100,
		Em.move.KB : 450 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 5,
		Em.move.HITSPARK_PALETTE : "red",
		Em.move.KB_ANGLE : -45,
#		"reset_type" : Globals.reset_type.STARTUP_RESET,
		Em.move.ATK_ATTR : [],
		Em.move.MOVE_SOUND : [{ ref = "launch2", aux_data = {"vol" : -5,} }, { ref = "impact33", aux_data = {"vol" : -23,} }],
		Em.move.HIT_SOUND : { ref = "cut5", aux_data = {"vol" : -7} },
	},
	"aSP5[ex]" : {
		Em.move.ATK_TYPE : Em.atk_type.EX,
#		"quick_turn_limit" : 4, # if on ground, can only quick turn on the first X frames
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 70,
		Em.move.KB : 250 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 6,
		Em.move.FIXED_HITSTOP : 10,
		Em.move.FIXED_ATKER_HITSTOP : 1,
		Em.move.HITSPARK_PALETTE : "red",
		Em.move.KB_ANGLE : -45,
#		Em.move.BURSTLOCK : 15,
		Em.move.ATK_ATTR : [Em.atk_attr.AUTOCHAIN],
		Em.move.MOVE_SOUND : [{ ref = "launch2", aux_data = {"vol" : -5,} }, { ref = "impact33", aux_data = {"vol" : -23,} }],
		Em.move.HIT_SOUND : { ref = "cut5", aux_data = {"vol" : -7} },
	},
	"aSP5b[ex]" : {
		Em.move.ATK_TYPE : Em.atk_type.EX,
#		"quick_turn_limit" : 4, # if on ground, can only quick turn on the first X frames
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 70,
		Em.move.KB : 550 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 6,
		Em.move.HITSPARK_PALETTE : "red",
		Em.move.KB_ANGLE : -45,
		Em.move.ATK_ATTR : [Em.atk_attr.FOLLOW_UP, Em.atk_attr.NO_IMPULSE],
		Em.move.MOVE_SOUND : [{ ref = "launch2", aux_data = {"vol" : -5,} }, { ref = "impact33", aux_data = {"vol" : -23,} }],
		Em.move.HIT_SOUND : { ref = "cut5", aux_data = {"vol" : -7} },
	},
	
	"aSP6[ex]" : {
		Em.move.ATK_TYPE : Em.atk_type.EX,
		Em.move.SEQ: "SP6[ex]SeqA",
		Em.move.HITCOUNT : 1,
		Em.move.ATK_ATTR : [Em.atk_attr.QUICK_GRAB, Em.atk_attr.CANNOT_CHAIN_INTO, Em.atk_attr.NOT_FROM_MOVE_REC]
	},
	
	"SP6[ex]SeqE": {
		Em.move.STARTER : "aSP6[ex]", # for cards in survival mode
		Em.move.SEQ_HITS : [{Em.move.DMG:200, Em.move.SEQ_HITSTOP: 15}], # for hits during sequence, has a key, only contain damage
		Em.move.SEQ_LAUNCH : { # for final hit of sequence
			Em.move.DMG : 0,
			Em.move.SEQ_HITSTOP : 0,
#			"guard_gain" : 3500,
#			"EX_gain": 0,
			Em.move.KB : 900 * FMath.S,
			Em.move.KB_ANGLE : -103, # launch backwards
			Em.move.ATK_LVL : 2,
		}
	},
	"aSP6[ex]SeqE": { # if Grabbed hit a ledge while Grabber doesn't
		Em.move.STARTER : "aSP6[ex]",
		Em.move.SEQ_HITS : [{Em.move.DMG:200, Em.move.SEQ_HITSTOP: 15}],
		Em.move.SEQ_LAUNCH : {
			Em.move.DMG : 0,
			Em.move.SEQ_HITSTOP : 0,
#			"guard_gain" : 3500,
#			"EX_gain": 0,
			Em.move.KB : 900 * FMath.S,
			Em.move.KB_ANGLE : -103,
			Em.move.ATK_LVL : 2,
		}
	},
	
	"SP7": {
		Em.move.ATK_TYPE : Em.atk_type.SPECIAL,
#		"reset_type" : Globals.reset_type.ACTIVE_RESET,
		Em.move.ATK_ATTR : [Em.atk_attr.AIR_REPEAT, Em.atk_attr.NO_TURN, Em.atk_attr.NO_QUICK_CANCEL],
	},
	
	"SP8": {
		Em.move.ATK_TYPE : Em.atk_type.SPECIAL,
		Em.move.ATK_ATTR : [Em.atk_attr.NO_TURN, Em.atk_attr.NO_SDASH_CANCEL],
	},

	"SP9": {
		Em.move.ATK_TYPE : Em.atk_type.SPECIAL,
		Em.move.ATK_ATTR : [Em.atk_attr.LEDGE_DROP, Em.atk_attr.NO_IMPULSE, Em.atk_attr.NO_TURN],
		Em.move.MOVE_SOUND : [{ ref = "water4", aux_data = {"vol" : -16, "bus" : "LowPass"} }, { ref = "launch1", aux_data = {"vol" : -10} }],
	},
	
	"aSP9a": {
		Em.move.ATK_TYPE : Em.atk_type.SPECIAL,
		Em.move.REKKA: "SP9", # allow Quick Cancel between Rekkas
		Em.move.HITCOUNT : 2,
		Em.move.IGNORE_TIME : 4,
		Em.move.DMG : 60,
		Em.move.FIXED_KB_MULTI : 200 * FMath.S,
		Em.move.KB : 500 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 5,
		Em.move.FIXED_KB_ANGLE_MULTI : 0,
		Em.move.KB_ANGLE : -25,
		Em.move.ATK_ATTR : [Em.atk_attr.NO_IMPULSE, Em.atk_attr.NO_TURN],
		Em.move.MOVE_SOUND : [{ ref = "water4", aux_data = {"vol" : -15} }, { ref = "whoosh7", aux_data = {"vol" : -15,} }],
		Em.move.HIT_SOUND : [{ ref = "cut2", aux_data = {"vol" : -18} }, { ref = "water1", aux_data = {"vol" : -9} }],
	},
	
	"SP9b": {
		Em.move.ATK_TYPE : Em.atk_type.SPECIAL,
		Em.move.REKKA: "SP9",
		Em.move.HITCOUNT : 4,
		Em.move.IGNORE_TIME : 4,
		Em.move.DMG : 20,
#		Em.move.FIXED_KB_MULTI : 100 * FMath.S,
		Em.move.FIXED_HITSTOP: 7,
		Em.move.FIXED_ATKER_HITSTOP: 3,
		Em.move.KB : 449 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 3,
		Em.move.KB_ANGLE : -75,
		Em.move.ATK_ATTR : [Em.atk_attr.NO_IMPULSE, Em.atk_attr.NO_TURN, Em.atk_attr.REFLECT_ENTITIES],
		Em.move.MOVE_SOUND : { ref = "whoosh3", aux_data = {"vol" : -8, "bus" : "PitchDown"} },
		Em.move.HIT_SOUND : [{ ref = "cut8", aux_data = {"vol" : -13} }, { ref = "cut1", aux_data = {"vol" : -12, "bus" : "LowPass"} }],
	},
	
	"aSP9c": {
		Em.move.ATK_TYPE : Em.atk_type.SPECIAL,
		Em.move.REKKA: "SP9",
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 70,
		Em.move.KB : 450 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 3,
		Em.move.KB_ANGLE : -75,
		Em.move.ATK_ATTR : [Em.atk_attr.NO_IMPULSE, Em.atk_attr.NO_TURN, Em.atk_attr.ANTI_AIR],
		Em.move.MOVE_SOUND : [{ ref = "whoosh13", aux_data = {"vol" : -13,} }, { ref = "whoosh9", aux_data = {"vol" : -13,"bus" : "LowPass"} }],
		Em.move.HIT_SOUND : [{ ref = "impact16", aux_data = {"vol" : -15} },{ ref = "impact19", aux_data = {"vol" : -20,"bus" : "LowPass"} }]
	},
	
	"aSP9c[r]": {
		Em.move.ATK_TYPE : Em.atk_type.SPECIAL,
		Em.move.REKKA: "aSP9c",
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 80,
		Em.move.KB : 450 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.RADIAL,
		Em.move.ATK_LVL : 5,
		Em.move.KB_ANGLE : 70,
		Em.move.ATK_ATTR : [],
		Em.move.MOVE_SOUND : { ref = "whoosh7", aux_data = {"vol" : -12,} },
		Em.move.HIT_SOUND : [{ ref = "impact12", aux_data = {"vol" : -15} }, { ref = "impact19", aux_data = {"vol" : -20,"bus" : "LowPass"} }],
	},
	
	"aSP9c[r]b": {
		Em.move.ATK_TYPE : Em.atk_type.SPECIAL,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 80,
		Em.move.KB : 450 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 5,
		Em.move.KB_ANGLE : 70,
		Em.move.ATK_ATTR : [Em.atk_attr.NO_TURN, Em.atk_attr.NO_HITCOUNT_RESET],
		Em.move.HIT_SOUND : [{ ref = "impact12", aux_data = {"vol" : -15} }, { ref = "impact19", aux_data = {"vol" : -20,"bus" : "LowPass"} }],
	},

	"SP9d": {
		Em.move.ATK_TYPE : Em.atk_type.SPECIAL,
		Em.move.REKKA: "SP9",
		Em.move.MOVE_SOUND : { ref = "water11", aux_data = {"vol" : -8,} },
		Em.move.ATK_ATTR : [],
	},
	
}



