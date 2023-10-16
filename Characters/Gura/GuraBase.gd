extends Node2D

# CHARACTER DATA --------------------------------------------------------------------------------------------------
# may be saved in a .tres file later? Or just leave it in the .gd file

const NAME = "Gura"
const ORDER = 0

# character movement stats, use to overwrite
const SPEED = 330 * FMath.S # ground speed
#const AWAY_SPEED_MOD = 75 # % of ground speed when moving away from opponent, may not have this const
const AIR_STRAFE_SPEED_MOD = 10 # percent of ground speed
const AIR_STRAFE_LIMIT_MOD = 800 # speed limit of air strafing, limit depends on calculated air strafe speed
const JUMP_SPEED = 900 * FMath.S
const VAR_JUMP_TIME = 10 # frames after jumping where holding jump will reduce gravity
const VAR_JUMP_SLOW_POINT = 5 # frames where JUMP_SLOW starts
#const JUMP_HORIZONTAL_SPEED = 110 * FMath.S
const DIR_JUMP_HEIGHT_MOD = 85 # % of JUMP_SPEED when jumping while holding left/right
const HORIZ_JUMP_BOOST_MOD = 20 # % of SPEED to gain when jumping with left/right held
const HORIZ_JUMP_SPEED_MOD = 150 # % of velocity.x to gain when jumping with left/right held
const AIR_HORIZ_JUMP_SPEED_MOD = 125
const HIGH_JUMP_SLOW = 10 # slow down velocity.y to PEAK_DAMPER_LIMIT when jumping with up/jump held
const SHORT_JUMP_SLOW = 20 # slow down velocity.y to PEAK_DAMPER_LIMIT when jumping with up/jump unheld
const AIR_JUMP_HEIGHT_MOD = 90 # percentage of JUMP_SPEED, reduce height of air jumps
const REVERSE_AIR_JUMP_MOD = 70 # percentage of SPEED when air jumping backwards
const WALL_AIR_JUMP_HORIZ_MOD = 150 # percentage of SPEED when wall jumping
const WALL_AIR_JUMP_VERT_MOD = 100 # percentage of JUMP_SPEED when wall jumping
const GRAVITY_MOD = 100 # make sure variable's a float
const TERMINAL_VELOCITY_MOD = 800 # affect terminal velocity downward
const FASTFALL_MOD = 100 # fastfall speed, mod of terminal velocity
const FRICTION = 15 # between 0 and 100
const ACCELERATION = 15 # between 0 and 100
const AIR_RESISTANCE = 3 # between 0 and 100
const FALL_GRAV_MOD = 100 # reduced gravity when going down
const EYE_LEVEL = 9 # number of pixels EX Flash appears above position

const MAX_AIR_JUMP = 1
const MAX_AIR_DASH = 2
const MAX_AIR_DODGE = 1
const MAX_SUPER_DASH = 1
const GRD_DASH_SPEED = 500 * FMath.S # duration in animation data
const AIR_DASH_SPEED = 400 * FMath.S # duration in animation data
const SDASH_SPEED = 450 * FMath.S # super dash
const SDASH_TURN_RATE = 5 # exact navigate speed when sdashing
const DODGE_GG_COST = 3000
const DODGE_SPEED = 1000 * FMath.S

const IMPULSE_MOD = 150 # multiply by SPEED to get impulse velocity
const WAVE_DASH_SPEED_MOD = 110 # affect speed of wavelanding, multiplied by GRD_DASH_SPEED

#const HITSTUN_REDUCTION_AT_MAX_GG = 70 # max reduction in hitstun when defender's Guard Gauge is at 200%, heavy characters have lower
#const KB_BOOST_AT_MAX_GG = 400 # max increase of knockback when defender's Guard Gauge is at 200%, light characters have higher

const DAMAGE_VALUE_LIMIT = 1100

const GG_REGEN_AMOUNT = 15 # exact GG regened per frame when GG < 100%
const GRD_BLOCK_GG_COST = 35 # exact GG loss per frame when blocking on ground
const AIR_BLOCK_GG_COST = 50 # exact GG loss per frame when blocking in air
const CHIP_DMG_MOD = 30 # % of damage taken as chip damage when blocking

const BASE_EX_REGEN = 20
const HITSTUN_EX_REGEN_MOD = 200  # increase EX Regen during hitstun
const LANDED_EX_REGEN_MOD = 600 # increase EX Regen when doing an unblocked attack
const BLOCKED_EX_REGEN_MOD = 200 # increase EX Regen when doing a blocked attack
const BLOCKING_EX_REGEN_MOD = 200 # increase EX Regen when blocking attack
const PARRYING_EX_REGEN_MOD = 600 # increase EX Regen when parrying attack
#const ATTACK_EX_REGEN_MOD = 200 # increase EX Regen when doing a physical attack, even on whiff
#const NON_ATTACK_EX_REGEN_MOD = 50 # reduce EX Regen when using a non-attack like projectile

const TRAITS = [Em.trait.VULN_GRD_DASH, Em.trait.VULN_AIR_DASH, Em.trait.GRD_DASH_JUMP]

const DEFAULT_HITSPARK_TYPE = Em.hitspark_type.HIT
const DEFAULT_HITSPARK_PALETTE = "blue"
const SDHitspark_COLOR = "blue"

const PALETTE_TO_PORTRAIT = {
	1: Color(0.75, 0.93, 1.25),
	2: Color(1.20, 0.70, 0.70),
	3: Color(0.75, 0.90, 0.70),
	4: Color(1.00, 1.00, 1.10),
	5: Color(0.50, 0.90, 1.00),
}

const PALETTE_TO_HITSPARK_PALETTE = {
	3: "green",
	4: "white",
	5: "pink"
}

const MUSIC = {
		"name" : "Gura's Theme", # to not play the same music as the one currently being played
		"artist" : "Zortoise",
		"audio" : "res://Characters/Gura/Music/GuraTheme.ogg",
#		"loop_start": 27.42,
		"loop_end": 164.57,
		"vol" : -7,
	}

const UNIQUE_DATA_REF = {
#	"groundfin_count" : 0,
	"groundfin_trigger" : false,
	"groundfin_target" : null,
	"nibbler_count" : 0,
#	"nibbler_cancel" : 0, # a timer, if 0 will not cancel, cannot use bool since it is set during detect_hit() and need to last 2 turns
	"last_trident" : null
}

const STARTERS = ["L1", "L2", "L3", "F1", "F2", "F3", "H", "aL1", "aL2", "aL3", "aF1", "aF2", "aF3", "aH", "SP1", "SP1[ex]", "aSP1", "aSP1[ex]", \
	"aSP2", "aSP2[ex]", "SP3", "aSP3", "SP3[ex]", "aSP3[ex]", "SP4", "SP4[ex]", "SP5", "aSP5", "SP5[ex]", "aSP5[ex]", "SP6[ex]", "aSP6[ex]", \
	"SP7", "aSP7", "SP8", "SP9", "SP9a", "SP9b", "SP9c", "aSP9c[r]", "SP9d"]
#const SPECIALS = ["SP1", "aSP1", "aSP2", "SP3", "aSP3", "SP4", "SP5", "aSP5"]
#const EX_MOVES = ["SP1[ex]", "aSP1[ex]", "aSP2[ex]", "SP3[ex]", "aSP3[ex]", "SP4[ex]", "SP5[ex]", "aSP5[ex]", "SP6[ex]", "aSP6[ex]"]
#const SUPERS = []

const UP_TILTS = ["L3", "F3", "SP3", "SP3[ex]", "aL3", "aF3", "aSP3", "aSP3[ex]", "SP9c"] # to know which moves can be cancelled from jumpsquat

# list of movenames that will emit EX flash
const EX_FLASH_ANIM = ["SP1[ex]", "aSP1[ex]", "SP1[b][ex]", "aSP1[b][ex]", "SP1[u][ex]", "aSP1[d][ex]", "aSP2[ex]", "SP3[ex]", "SP3b[ex]", \
		"aSP3[ex]", "aSP3b[ex]", "SP4[ex]", "SP5[ex]", "aSP5[ex]", "SP5b[ex]", "aSP5b[ex]", "SP6[ex]", "aSP6[ex]", "SP6[ex]SeqA", "SP6[ex]SeqB"]
#const EX_FLASH_ANIM = ["H", "Hb"]
# const DIRECTORY_NAME = "res://Characters/Gura/"

# this contain move_data for each active animation this character has
# use trim_suffix("Active") on animation name to find move in the database
const MOVE_DATABASE = {
	"L1" : {
		Em.move.ATK_TYPE : Em.atk_type.LIGHT,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 20,
		Em.move.KB : 200 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED, # for radial, +ve KB_angle means rotating clockwise, -ve is counterclockwise
		Em.move.ATK_LVL : 2,
		Em.move.FIXED_HITSTOP : 10,
		Em.move.FIXED_ATKER_HITSTOP : 1,
		Em.move.KB_ANGLE : -36,
		Em.move.ATK_ATTR : [Em.atk_attr.AUTOCHAIN],
		Em.move.MOVE_SOUND : { ref = "whoosh2", aux_data = {"vol" : -12} },
		Em.move.HIT_SOUND : { ref = "cut1", aux_data = {"vol" : -15} },
	},
	"L1b" : {
		Em.move.ATK_TYPE : Em.atk_type.LIGHT,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 20,
		Em.move.KB : 200 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED, # for radial, +ve KB_angle means rotating clockwise, -ve is counterclockwise
		Em.move.ATK_LVL : 2,
		Em.move.KB_ANGLE : -36,
		Em.move.ATK_ATTR : [Em.atk_attr.FOLLOW_UP, Em.atk_attr.NO_IMPULSE],
		Em.move.MOVE_SOUND : { ref = "whoosh2", aux_data = {"vol" : -12} },
		Em.move.HIT_SOUND : { ref = "cut1", aux_data = {"vol" : -15} },
	},
	"L1b[h]" : {
		Em.move.ATK_TYPE : Em.atk_type.LIGHT,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 20,
		Em.move.KB : 200 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED, # for radial, +ve KB_angle means rotating clockwise, -ve is counterclockwise
		Em.move.ATK_LVL : 3,
		Em.move.FIXED_HITSTOP : 10,
		Em.move.FIXED_ATKER_HITSTOP : 1,
		Em.move.KB_ANGLE : -36,
		Em.move.ATK_ATTR : [Em.atk_attr.FOLLOW_UP, Em.atk_attr.NO_IMPULSE, Em.atk_attr.AUTOCHAIN],
		Em.move.MOVE_SOUND : { ref = "whoosh2", aux_data = {"vol" : -12} },
		Em.move.HIT_SOUND : { ref = "cut1", aux_data = {"vol" : -15} },
	},
	"L1c" : {
		Em.move.ATK_TYPE : Em.atk_type.LIGHT,
		Em.move.ROOT: "L1b",
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 20,
		Em.move.KB : 200 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED, # for radial, +ve KB_angle means rotating clockwise, -ve is counterclockwise
		Em.move.ATK_LVL : 2,
		Em.move.KB_ANGLE : -36,
		Em.move.ATK_ATTR : [Em.atk_attr.FOLLOW_UP, Em.atk_attr.NO_IMPULSE],
		Em.move.MOVE_SOUND : { ref = "whoosh2", aux_data = {"vol" : -12} },
		Em.move.HIT_SOUND : { ref = "cut1", aux_data = {"vol" : -15} },
	},
	"L2" : {
		Em.move.ATK_TYPE : Em.atk_type.LIGHT,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 45,
		Em.move.KB : 180 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED, # for radial, +ve KB_angle means rotating clockwise, -ve is counterclockwise
		Em.move.ATK_LVL : 3,
		Em.move.KB_ANGLE : -36,
		Em.move.ATK_ATTR : [Em.atk_attr.LEDGE_DROP, Em.atk_attr.NO_IMPULSE, Em.atk_attr.NO_REC_CANCEL],
		Em.move.MOVE_SOUND : { ref = "whoosh5", aux_data = {"vol" : -15, "bus" : "PitchDown"} },
		Em.move.HIT_SOUND : { ref = "impact11", aux_data = {"vol" : -10} },
	},
	"L3" : {
		Em.move.ATK_TYPE : Em.atk_type.LIGHT,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 55,
		Em.move.KB : 445 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 4,
		Em.move.PRIORITY_ADD: 2,
		Em.move.KB_ANGLE : -80,
		Em.move.ATK_ATTR : [Em.atk_attr.ANTI_AIR, Em.atk_attr.JUMP_CANCEL_ACTIVE, Em.atk_attr.ONLY_CHAIN_ON_HIT],
		Em.move.MOVE_SOUND : { ref = "whoosh9", aux_data = {"vol" : -18} },
		Em.move.HIT_SOUND : { ref = "cut5", aux_data = {"vol" : -10,} },
	},
	"F1" : {
		Em.move.ATK_TYPE : Em.atk_type.FIERCE, # light/fierce/heavy/special/ex/super
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 60, # chip damage is a certain % of damage, Chipper Attribute can increase chip
		Em.move.KB : 350 * FMath.S,  # knockback strength, block pushback (% of knockback strength), affect hitspark size and hitstop
		Em.move.KB_TYPE: Em.knockback_type.MIRRORED,
		Em.move.ATK_LVL : 3, # 1~8, affect hitstun and blockstun
		Em.move.KB_ANGLE : -36, # in degrees, 0 means straight ahead to the right, positive means rotating downward
		# some moves uses KBOrigin to determine KB_angle, has special data instead
		Em.move.ATK_ATTR : [], # enums
		Em.move.MOVE_SOUND : { ref = "whoosh13", aux_data = {"vol" : -12,} },
		# played when move is used, aux_data carry volume and bus
		Em.move.HIT_SOUND : { ref = "impact16", aux_data = {"vol" : -15} },
	},
	"F2" : {
		Em.move.ATK_TYPE : Em.atk_type.FIERCE,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 60,
		Em.move.KB : 400 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 3,
		Em.move.PRIORITY_ADD : -1,
		Em.move.KB_ANGLE : 0,
		Em.move.ATK_ATTR : [],
		Em.move.MOVE_SOUND : { ref = "whoosh1", aux_data = {"vol" : -12,} },
		Em.move.HIT_SOUND : { ref = "cut2", aux_data = {"vol" : -15} },
	},
	"F2[h]" : {
		Em.move.ATK_TYPE : Em.atk_type.FIERCE,
		Em.move.ROOT: "F2",
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 40,
		Em.move.KB : 350 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 3,
		Em.move.FIXED_SS_HITSTOP : 12,
		Em.move.KB_ANGLE : 0,
		Em.move.ATK_ATTR : [Em.atk_attr.ONLY_CHAIN_ON_HIT, Em.atk_attr.LATE_CHAIN, Em.atk_attr.NO_SS_ATK_LVL_BOOST],
		Em.move.MOVE_SOUND : { ref = "whoosh1", aux_data = {"vol" : -12,} },
		Em.move.HIT_SOUND : { ref = "cut2", aux_data = {"vol" : -15} },
	},
	"F3" : {
		Em.move.ATK_TYPE : Em.atk_type.FIERCE,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 70,
		Em.move.KB : 400 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.RADIAL,
		Em.move.ATK_LVL : 4,
		Em.move.KB_ANGLE : 90,
		Em.move.ATK_ATTR : [Em.atk_attr.ANTI_AIR, Em.atk_attr.ONLY_CHAIN_ON_HIT, Em.atk_attr.LATE_CHAIN],
		Em.move.MOVE_SOUND : { ref = "whoosh7", aux_data = {"vol" : -12,} },
		Em.move.HIT_SOUND : { ref = "impact19", aux_data = {"vol" : -18} },
	},
	"H" : {
		Em.move.ATK_TYPE : Em.atk_type.HEAVY,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 30,
		Em.move.KB : 150 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 6,
		Em.move.KB_ANGLE : -75,
		Em.move.ATK_ATTR : [Em.atk_attr.AUTOCHAIN, Em.atk_attr.NO_CHAIN],
		Em.move.MOVE_SOUND : [{ ref = "water8", aux_data = {"vol" : -13,} }, { ref = "water5", aux_data = {"vol" : -20} }],
		Em.move.HIT_SOUND : { ref = "water7", aux_data = {"vol" : -9} },
	},
	"Hb" : {
		Em.move.ATK_TYPE : Em.atk_type.HEAVY,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 70,
		Em.move.KB : 550 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 6,
		Em.move.KB_ANGLE : -75,
		Em.move.ATK_ATTR : [Em.atk_attr.FOLLOW_UP, Em.atk_attr.NO_IMPULSE],
		Em.move.HIT_SOUND : { ref = "water7", aux_data = {"vol" : -7} },
	},

	"aL1" : {
		Em.move.ATK_TYPE : Em.atk_type.LIGHT,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 40,
		Em.move.KB : 200 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.RADIAL,
		Em.move.ATK_LVL : 2,
		Em.move.KB_ANGLE : 0,
		Em.move.ATK_ATTR : [],
		Em.move.MOVE_SOUND : { ref = "whoosh3", aux_data = {"vol" : -12} },
		Em.move.HIT_SOUND : { ref = "impact14", aux_data = {"vol" : -15} },
	},
	"aL2" : {
		Em.move.ATK_TYPE : Em.atk_type.LIGHT,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 35,
		Em.move.KB : 200 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 3,
		Em.move.KB_ANGLE : 90,
		Em.move.ATK_ATTR : [ Em.atk_attr.NO_REC_CANCEL, Em.atk_attr.CAN_REPEAT_ONCE],
		Em.move.MOVE_SOUND : { ref = "whoosh15", aux_data = {"vol" : -9} },
		Em.move.HIT_SOUND : { ref = "cut8", aux_data = {"vol" : -10} },
	},
	"aL3" : {
		Em.move.ATK_TYPE : Em.atk_type.LIGHT,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 40,
		Em.move.KB : 400 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 3,
		Em.move.PRIORITY_ADD : 1,
		Em.move.KB_ANGLE : -80,
		Em.move.ATK_ATTR : [],
		Em.move.MOVE_SOUND : { ref = "whoosh3", aux_data = {"vol" : -12, "bus" : "PitchDown"} },
		Em.move.HIT_SOUND : { ref = "impact14", aux_data = {"vol" : -15} },
	},
	"aF1" : {
		Em.move.ATK_TYPE : Em.atk_type.FIERCE,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 60,
		Em.move.KB : 350 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.RADIAL, # for radial, +ve KB_angle means rotating clockwise, -ve is counterclockwise
		Em.move.ATK_LVL : 3,
		Em.move.KB_ANGLE : 72,
		Em.move.ATK_ATTR : [],
		Em.move.MOVE_SOUND : { ref = "whoosh14", aux_data = {"vol" : -9, "bus": "PitchDown"} },
		Em.move.HIT_SOUND : { ref = "impact12", aux_data = {"vol" : -15} },
	},
	"aF2" : {
		Em.move.ATK_TYPE : Em.atk_type.FIERCE,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 35,
		Em.move.KB : 350 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 2,
		Em.move.FIXED_SS_HITSTOP : 12,
		Em.move.KB_ANGLE : 70,
		Em.move.ATK_ATTR : [Em.atk_attr.NO_SS_ATK_LVL_BOOST],
		Em.move.MOVE_SOUND : { ref = "whoosh15", aux_data = {"vol" : -5, "bus": "PitchDown"} },
		Em.move.HIT_SOUND : { ref = "cut2", aux_data = {"vol" : -15} },
	},
	"aF2SeqB": {
		Em.move.STARTER : "aF2",
		Em.move.ATK_TYPE : Em.atk_type.FIERCE,
		Em.move.SEQ_LAUNCH : {
			Em.move.DMG : 30,
			Em.move.SEQ_HITSTOP : 0,
			Em.move.SEQ_WEAK : true,
			Em.move.KB : 500 * FMath.S,
			Em.move.KB_ANGLE : -100,
			Em.move.ATK_LVL : 4,
		}
	},
	"aF3" : {
		Em.move.ATK_TYPE : Em.atk_type.FIERCE,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 55,
		Em.move.KB : 350 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 4,
		Em.move.PRIORITY_ADD : 1,
		Em.move.KB_ANGLE : -72,
		Em.move.ATK_ATTR : [],
		Em.move.MOVE_SOUND : { ref = "whoosh12", aux_data = {"vol" : -2} },
		Em.move.HIT_SOUND : { ref = "cut5", aux_data = {"vol" : -10} },
	},
	"aH" : {
		Em.move.ATK_TYPE : Em.atk_type.HEAVY,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 90,
		Em.move.KB : 450 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 5,
		Em.move.KB_ANGLE : 45,
		Em.move.ATK_ATTR : [Em.atk_attr.CRUSH],
		Em.move.MOVE_SOUND : { ref = "water4", aux_data = {"vol" : -12,} },
		Em.move.HIT_SOUND : { ref = "water5", aux_data = {"vol" : -18} },
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
		Em.move.LAST_HIT_RANGE : 27,
		Em.move.IGNORE_TIME : 6,
		Em.move.DMG : 40,
		Em.move.KB : 500 * FMath.S,
		Em.move.FIXED_KB_MULTI : 300 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 3,
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
		Em.move.LAST_HIT_RANGE : 27,
		Em.move.IGNORE_TIME : 5,
		Em.move.DMG : 35,
		Em.move.KB : 600 * FMath.S,
		Em.move.FIXED_KB_MULTI : 300 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 3,
		Em.move.KB_ANGLE : -45,
		Em.move.ATK_ATTR : [Em.atk_attr.PROJ_ARMOR_ACTIVE, Em.atk_attr.WHIFF_SDASH_CANCEL],
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
		Em.move.ATK_LVL : 4,
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
		Em.move.ATK_LVL : 4,
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
		Em.move.ATK_LVL : 4,
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
		Em.move.ATK_LVL : 4,
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
		Em.move.ATK_TYPE : Em.atk_type.EX,
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
		Em.move.ATK_TYPE : Em.atk_type.EX,
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
		Em.move.LAST_HIT_RANGE : 7,
		Em.move.IGNORE_TIME : 4,
		Em.move.DMG : 50,
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



