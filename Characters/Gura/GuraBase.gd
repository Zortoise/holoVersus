extends Node2D

# CHARACTER DATA --------------------------------------------------------------------------------------------------
# may be saved in a .tres file later? Or just leave it in the .gd file

const NAME = "Gura"

# character movement stats, use to overwrite
const SPEED = 340 * FMath.S # ground speed
const AIR_STRAFE_SPEED_MOD = 10 # percent of ground speed
const AIR_STRAFE_LIMIT_MOD = 800 # speed limit of air strafing, limit depends on calculated air strafe speed
const JUMP_SPEED = 700 * FMath.S
const VAR_JUMP_TIME = 10 # frames after jumping where holding jump will reduce gravity
const JUMP_HORIZONTAL_SPEED = 110 * FMath.S
const AIR_JUMP_HEIGHT_MOD = 90 # percentage of JUMP_SPEED, reduce height of air jumps
const REVERSE_AIR_JUMP_MOD = 70 # percentage of SPEED when air jumping backwards
const WALL_AIR_JUMP_HORIZ_MOD = 150 # percentage of SPEED when wall jumping
const WALL_AIR_JUMP_VERT_MOD = 100 # percentage of JUMP_SPEED when wall jumping
const GRAVITY_MOD = 100 # make sure variable's a float
const TERMINAL_VELOCITY_MOD = 800 # affect terminal velocity downward
const FASTFALL_MOD = 115 # fastfall speed, mod of terminal velocity
const FRICTION = 15 # between 0.0 and 1.0
const ACCELERATION = 15 # between 0.0 and 1.0
const AIR_RESISTANCE = 3 # between 0.0 and 1.0
const FALL_GRAV_MOD = 100 # reduced gravity when going down
const EYE_LEVEL = 9 # number of pixels EX Flash appears above position

const MAX_AIR_JUMP = 1
const MAX_AIR_DASH = 2
const MAX_AIR_DODGE = 1
const MAX_SUPER_DASH = 1
const GROUND_DASH_SPEED = 450 * FMath.S # duration in animation data
const AIR_DASH_SPEED = 400 * FMath.S # duration in animation data
const SDASH_SPEED = 450 * FMath.S # super dash
const SDASH_TURN_RATE = 5 # exact navigate speed when sdashing
const DODGE_GG_COST = 2500
const DODGE_SPEED = 1000 * FMath.S

const IMPULSE_MOD = 150 # multiply by SPEED to get impulse velocity
const HOP_JUMP_MOD = 80 # multiply by JUMP_SPEED to get shorthop height
const LONG_HOP_JUMP_MOD = 125 # multiply by SPEED to get horizontal velocity gain when doing long hops
#const SUPER_JUMP_MOD = 150
const WAVE_DASH_SPEED_MOD = 120 # affect speed of wavelanding, multiplied by GROUND_DASH_SPEED

#const F_HITSTUN_REDUCTION_AT_MAX_GG = 50 # max reduction in flinch hitstun when defender's Guard Gauge is at 200%, heavy characters have lower
const KB_BOOST_AT_MAX_GG = 400 # max increase of knockback when defender's Guard Gauge is at 200%, light characters have higher

const DAMAGE_VALUE_LIMIT = 1100

const GUARD_GAUGE_REGEN_AMOUNT = 10 # exact GG regened per frame when GG < 100%
const GROUND_BLOCK_INITIAL_GG_COST = 500
const AIR_BLOCK_INITIAL_GG_COST = 500
const GROUND_BLOCK_GG_COST = 50 # exact GG loss per frame when blocking on ground
const AIR_BLOCK_GG_COST = 50 # exact GG loss per frame when blocking in air
const WEAKBLOCK_CHIP_DMG_MOD = 30 # % of damage taken as chip damage when blocking

const TRAITS = [Globals.trait.CHAIN_DASH, Globals.trait.VULN_GRD_DASH, Globals.trait.VULN_AIR_DASH]

const DEFAULT_HITSPARK_TYPE = Globals.hitspark_type.HIT
const DEFAULT_HITSPARK_PALETTE = "blue"
const SDHitspark_COLOR = "blue"

const PALETTE_TO_PORTRAIT = {
	1: Color(0.75, 0.93, 1.25),
	2: Color(1.20, 0.70, 0.70),
	3: Color(0.75, 0.90, 0.70),
	4: Color(1.00, 1.00, 1.10),
}

const PALETTE_TO_HITSPARK_PALETTE = {
	3: "green",
	4: "white",
}

const UNIQUE_DATA_REF = {
	"groundfin_count" : 0,
	"groundfin_trigger" : false,
	"nibbler_count" : 0,
	"nibbler_cancel" : 0, # a timer, if 0 will not cancel, cannot use bool since it is set during detect_hit() and need to last 2 turns
}

const STARTERS = ["L1", "L2", "L3", "F1", "F2", "F3", "H", "aL1", "aL2", "aL3", "aF1", "aF2", "aF3", "aH", "SP1", "SP1[ex]", "aSP1", "aSP1[ex]", \
	"aSP2", "aSP2[ex]", "SP3", "aSP3", "SP3[ex]", "aSP3[ex]", "SP4", "SP4[ex]", "SP5", "aSP5", "SP5[ex]", "aSP5[ex]", "SP6[ex]", "aSP6[ex]", \
	"SP7", "aSP7"]
#const SPECIALS = ["SP1", "aSP1", "aSP2", "SP3", "aSP3", "SP4", "SP5", "aSP5"]
#const EX_MOVES = ["SP1[ex]", "aSP1[ex]", "aSP2[ex]", "SP3[ex]", "aSP3[ex]", "SP4[ex]", "SP5[ex]", "aSP5[ex]", "SP6[ex]", "aSP6[ex]"]
#const SUPERS = []

const UP_TILTS = ["L3", "F3", "SP3", "SP3[ex]", "aL3", "aF3", "aSP3", "aSP3[ex]"] # to know which moves can be cancelled from jumpsquat

# list of movenames that will emit EX flash
const EX_FLASH_ANIM = ["SP1[ex]", "aSP1[ex]", "SP1b[ex]", "aSP1b[ex]", "aSP2[ex]", "SP3[ex]", "SP3b[ex]", "aSP3[ex]", "aSP3b[ex]", "SP4[ex]", "SP5[ex]", "aSP5[ex]", \
	"SP5b[ex]", "aSP5b[ex]", "SP6[ex]", "aSP6[ex]", "SP6[ex]SeqA", "SP6[ex]SeqB"]
#const EX_FLASH_ANIM = ["H", "Hb"]

# const DIRECTORY_NAME = "res://Characters/Gura/"

# this contain move_data for each active animation this character has
# use trim_suffix("Active") on animation name to find move in the database
const MOVE_DATABASE = {
	"L1" : {
		"atk_type" : Globals.atk_type.LIGHT,
		"hitcount" : 1,
		"damage" : 20,
		"knockback" : 200 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED, # for radial, +ve KB_angle means rotating clockwise, -ve is counterclockwise
		"atk_level" : 2,
		"fixed_hitstop" : 10,
		"fixed_atker_hitstop" : 1,
		"KB_angle" : -36,
		"atk_attr" : [Globals.atk_attr.AUTOCHAIN],
		"move_sound" : { ref = "whoosh2", aux_data = {"vol" : -12} },
		"hit_sound" : { ref = "cut1", aux_data = {"vol" : -15} },
	},
	"L1b" : {
		"atk_type" : Globals.atk_type.LIGHT,
		"hitcount" : 1,
		"damage" : 20,
		"knockback" : 200 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED, # for radial, +ve KB_angle means rotating clockwise, -ve is counterclockwise
		"atk_level" : 2,
		"KB_angle" : -36,
		"atk_attr" : [Globals.atk_attr.FOLLOW_UP, Globals.atk_attr.NO_IMPULSE],
		"move_sound" : { ref = "whoosh2", aux_data = {"vol" : -12} },
		"hit_sound" : { ref = "cut1", aux_data = {"vol" : -15} },
	},
	"L1b[h]" : {
		"atk_type" : Globals.atk_type.LIGHT,
		"hitcount" : 1,
		"damage" : 20,
		"knockback" : 200 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED, # for radial, +ve KB_angle means rotating clockwise, -ve is counterclockwise
		"atk_level" : 3,
		"fixed_hitstop" : 10,
		"fixed_atker_hitstop" : 1,
		"KB_angle" : -36,
		"atk_attr" : [Globals.atk_attr.FOLLOW_UP, Globals.atk_attr.NO_IMPULSE, Globals.atk_attr.AUTOCHAIN],
		"move_sound" : { ref = "whoosh2", aux_data = {"vol" : -12} },
		"hit_sound" : { ref = "cut1", aux_data = {"vol" : -15} },
	},
	"L1c" : {
		"atk_type" : Globals.atk_type.LIGHT,
		"root": "L1b",
		"hitcount" : 1,
		"damage" : 20,
		"knockback" : 200 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED, # for radial, +ve KB_angle means rotating clockwise, -ve is counterclockwise
		"atk_level" : 2,
		"KB_angle" : -36,
		"atk_attr" : [Globals.atk_attr.FOLLOW_UP, Globals.atk_attr.NO_IMPULSE],
		"move_sound" : { ref = "whoosh2", aux_data = {"vol" : -12} },
		"hit_sound" : { ref = "cut1", aux_data = {"vol" : -15} },
	},
	"L2" : {
		"atk_type" : Globals.atk_type.LIGHT,
		"hitcount" : 1,
		"damage" : 45,
		"knockback" : 180 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED, # for radial, +ve KB_angle means rotating clockwise, -ve is counterclockwise
		"atk_level" : 3,
		"KB_angle" : -36,
		"atk_attr" : [Globals.atk_attr.LEDGE_DROP, Globals.atk_attr.NO_IMPULSE, Globals.atk_attr.NO_REC_CANCEL],
		"move_sound" : { ref = "whoosh5", aux_data = {"vol" : -15, "bus" : "PitchDown"} },
		"hit_sound" : { ref = "impact11", aux_data = {"vol" : -10} },
	},
	"L3" : {
		"atk_type" : Globals.atk_type.LIGHT,
		"hitcount" : 1,
		"damage" : 55,
		"knockback" : 445 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED,
		"atk_level" : 4,
		"priority": Globals.priority.gF,
		"KB_angle" : -80,
		"atk_attr" : [Globals.atk_attr.ANTI_AIR],
		"move_sound" : { ref = "whoosh9", aux_data = {"vol" : -18} },
		"hit_sound" : { ref = "cut5", aux_data = {"vol" : -10,} },
	},
	"F1" : {
		"atk_type" : Globals.atk_type.FIERCE, # light/fierce/heavy/special/ex/super
		"hitcount" : 1,
		"damage" : 60, # chip damage is a certain % of damage, Chipper Attribute can increase chip
		"knockback" : 350 * FMath.S,  # knockback strength, block pushback (% of knockback strength), affect hitspark size and hitstop
		"knockback_type": Globals.knockback_type.MIRRORED,
		"atk_level" : 3, # 1~8, affect hitstun and blockstun
		"KB_angle" : -36, # in degrees, 0 means straight ahead to the right, positive means rotating downward
		# some moves uses KBOrigin to determine KB_angle, has special data instead
		"atk_attr" : [], # enums
		"move_sound" : { ref = "whoosh13", aux_data = {"vol" : -12,} },
		# played when move is used, aux_data carry volume and bus
		"hit_sound" : { ref = "impact16", aux_data = {"vol" : -15} },
	},
	"F2" : {
		"atk_type" : Globals.atk_type.FIERCE,
		"hitcount" : 1,
		"damage" : 60,
		"knockback" : 400 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED,
		"atk_level" : 3,
		"priority": Globals.priority.aF,
		"KB_angle" : 0,
		"atk_attr" : [Globals.atk_attr.LATE_CHAIN],
		"move_sound" : { ref = "whoosh1", aux_data = {"vol" : -12,} },
		"hit_sound" : { ref = "cut2", aux_data = {"vol" : -15} },
	},
	"F2[h]" : {
		"atk_type" : Globals.atk_type.FIERCE,
		"hitcount" : 1,
		"damage" : 45,
		"knockback" : 350 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED,
		"atk_level" : 3,
		"fixed_ss_hitstop" : 12,
		"KB_angle" : 0,
		"atk_attr" : [Globals.atk_attr.NO_REPEAT_MOVE, Globals.atk_attr.NO_CHAIN],
		"move_sound" : { ref = "whoosh1", aux_data = {"vol" : -12,} },
		"hit_sound" : { ref = "cut2", aux_data = {"vol" : -15} },
	},
	"F3" : {
		"atk_type" : Globals.atk_type.FIERCE,
		"hitcount" : 1,
		"damage" : 70,
		"knockback" : 400 * FMath.S,
		"knockback_type": Globals.knockback_type.RADIAL,
		"atk_level" : 4,
		"KB_angle" : 90,
		"atk_attr" : [Globals.atk_attr.ANTI_AIR, Globals.atk_attr.DESTROY_ENTITIES, Globals.atk_attr.ONLY_CHAIN_ON_HIT],
		"move_sound" : { ref = "whoosh7", aux_data = {"vol" : -12,} },
		"hit_sound" : { ref = "impact19", aux_data = {"vol" : -18} },
	},
	"H" : {
		"atk_type" : Globals.atk_type.HEAVY,
		"hitcount" : 1,
		"damage" : 30,
		"knockback" : 150 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED,
		"atk_level" : 6,
		"KB_angle" : -75,
		"atk_attr" : [Globals.atk_attr.AUTOCHAIN, Globals.atk_attr.NO_CHAIN, Globals.atk_attr.NO_REPEAT_MOVE],
		"move_sound" : [{ ref = "water8", aux_data = {"vol" : -13,} }, { ref = "water5", aux_data = {"vol" : -20} }],
		"hit_sound" : { ref = "water7", aux_data = {"vol" : -9} },
	},
	"Hb" : {
		"atk_type" : Globals.atk_type.HEAVY,
		"hitcount" : 1,
		"damage" : 70,
		"knockback" : 550 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED,
		"atk_level" : 6,
		"KB_angle" : -75,
		"atk_attr" : [Globals.atk_attr.FOLLOW_UP, Globals.atk_attr.NO_IMPULSE, Globals.atk_attr.DESTROY_ENTITIES, Globals.atk_attr.NO_REPEAT_MOVE],
		"hit_sound" : { ref = "water7", aux_data = {"vol" : -7} },
	},

	"aL1" : {
		"atk_type" : Globals.atk_type.LIGHT,
		"hitcount" : 1,
		"damage" : 40,
		"knockback" : 200 * FMath.S,
		"knockback_type": Globals.knockback_type.RADIAL,
		"atk_level" : 2,
		"KB_angle" : 0,
		"atk_attr" : [],
		"move_sound" : { ref = "whoosh3", aux_data = {"vol" : -12} },
		"hit_sound" : { ref = "impact14", aux_data = {"vol" : -15} },
	},
	"aL2" : {
		"atk_type" : Globals.atk_type.LIGHT,
		"hitcount" : 1,
		"damage" : 35,
		"knockback" : 200 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED,
		"atk_level" : 3,
		"KB_angle" : 90,
		"atk_attr" : [ Globals.atk_attr.NO_REC_CANCEL],
		"move_sound" : { ref = "whoosh15", aux_data = {"vol" : -9} },
		"hit_sound" : { ref = "cut8", aux_data = {"vol" : -10} },
	},
	"aL3" : {
		"atk_type" : Globals.atk_type.LIGHT,
		"hitcount" : 1,
		"damage" : 40,
		"knockback" : 400 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED,
		"atk_level" : 3,
		"KB_angle" : -80,
		"atk_attr" : [],
		"move_sound" : { ref = "whoosh3", aux_data = {"vol" : -12, "bus" : "PitchDown"} },
		"hit_sound" : { ref = "impact14", aux_data = {"vol" : -15} },
	},
	"aF1" : {
		"atk_type" : Globals.atk_type.FIERCE,
		"hitcount" : 1,
		"damage" : 60,
		"knockback" : 350 * FMath.S,
		"knockback_type": Globals.knockback_type.RADIAL, # for radial, +ve KB_angle means rotating clockwise, -ve is counterclockwise
		"atk_level" : 3,
		"KB_angle" : 72,
		"atk_attr" : [],
		"move_sound" : { ref = "whoosh14", aux_data = {"vol" : -9, "bus": "PitchDown"} },
		"hit_sound" : { ref = "impact12", aux_data = {"vol" : -15} },
	},
	"aF2" : {
		"atk_type" : Globals.atk_type.FIERCE,
		"hitcount" : 1,
		"damage" : 45,
		"knockback" : 350 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED,
		"atk_level" : 2,
		"fixed_ss_hitstop" : 12,
		"KB_angle" : 70,
		"atk_attr" : [Globals.atk_attr.NO_REPEAT_MOVE, Globals.atk_attr.NO_SS_ATK_LVL_BOOST],
		"move_sound" : { ref = "whoosh15", aux_data = {"vol" : -5, "bus": "PitchDown"} },
		"hit_sound" : { ref = "cut2", aux_data = {"vol" : -15} },
	},
	"aF2SeqB": {
		"sequence_launch" : {
			"damage" : 30,
			"hitstop" : 0,
			"weak" : true,
			"launch_power" : 500 * FMath.S,
			"launch_angle" : -100,
			"atk_level" : 4,
		}
	},
	"aF3" : {
		"atk_type" : Globals.atk_type.FIERCE,
		"hitcount" : 1,
		"damage" : 55,
		"knockback" : 350 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED,
		"atk_level" : 4,
		"KB_angle" : -72,
		"atk_attr" : [],
		"move_sound" : { ref = "whoosh12", aux_data = {"vol" : -2} },
		"hit_sound" : { ref = "cut5", aux_data = {"vol" : -10} },
	},
	"aH" : {
		"atk_type" : Globals.atk_type.HEAVY,
		"hitcount" : 1,
		"damage" : 90,
		"knockback" : 475 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED,
		"atk_level" : 6,
		"KB_angle" : 45,
		"atk_attr" : [Globals.atk_attr.DESTROY_ENTITIES, Globals.atk_attr.CRUSH],
		"move_sound" : { ref = "water4", aux_data = {"vol" : -12,} },
		"hit_sound" : { ref = "water5", aux_data = {"vol" : -18} },
	},
	
	"SP1": {
		"atk_type" : Globals.atk_type.SPECIAL, # used for chaining
		"reset_type" : Globals.reset_type.NON_ATK_RESET,
		"atk_attr" : [],
	},
	"SP1[ex]": {
		"atk_type" : Globals.atk_type.EX,
		"move_sound" : [{ ref = "water4", aux_data = {"vol" : -20,} }, { ref = "whoosh12", aux_data = {} }],
		"atk_attr" : [],
	},
	
	"aSP2" : {
		"atk_type" : Globals.atk_type.SPECIAL,
		"hitcount" : 3,
		"ignore_time" : 6,
		"damage" : 40,
		"knockback" : 500 * FMath.S,
		"fixed_knockback_multi" : 300 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED,
		"atk_level" : 4,
		"KB_angle" : -45,
		"reset_type" : Globals.reset_type.FULL_ACTIVE_RESET,
		"atk_attr" : [],
		"move_sound" : [{ ref = "water4", aux_data = {"vol" : -15,} }, { ref = "blast3", aux_data = {"vol" : -10, "bus" : "LowPass"} }],
		"hit_sound" : [{ ref = "impact11", aux_data = {"vol" : -20} }, { ref = "water1", aux_data = {"vol" : -8} }],
	},
	"aSP2[h]" : {
		"atk_type" : Globals.atk_type.SPECIAL,
		"root" : "aSP2",
		"hitcount" : 1,
		"damage" : 80,
		"knockback" : 500 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED,
		"atk_level" : 4,
		"priority": Globals.priority.gSp,
		"KB_angle" : -90,
		"reset_type" : Globals.reset_type.FULL_ACTIVE_RESET,
		"atk_attr" : [],
		"move_sound" : [{ ref = "water4", aux_data = {"vol" : -15,} }, { ref = "blast3", aux_data = {"vol" : -10, "bus" : "LowPass"} }],
		"hit_sound" : [{ ref = "impact11", aux_data = {"vol" : -20} }, { ref = "water1", aux_data = {"vol" : -8} }],
	},
	"aSP2[ex]" : {
		"atk_type" : Globals.atk_type.EX,
		"hitcount" : 5,
		"ignore_time" : 5,
		"damage" : 35,
		"knockback" : 600 * FMath.S,
		"fixed_knockback_multi" : 300 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED,
		"atk_level" : 5,
		"KB_angle" : -45,
		"atk_attr" : [Globals.atk_attr.PROJ_ARMOR_ACTIVE],
		"move_sound" : [{ ref = "water4", aux_data = {"vol" : -15,} }, { ref = "blast3", aux_data = {"vol" : -10, "bus" : "LowPass"} }],
		"hit_sound" : [{ ref = "impact11", aux_data = {"vol" : -20} }, { ref = "water1", aux_data = {"vol" : -8} }],
	},
	
	"aSP3" : {
		"atk_type" : Globals.atk_type.SPECIAL,
		"hitcount" : 1,
		"damage" : 40,
		"knockback" : 600 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED,
		"atk_level" : 5,
		"KB_angle" : -90,
		"reset_type" : Globals.reset_type.EARLY_RESET,
		"atk_attr" : [Globals.atk_attr.AUTOCHAIN],
		"move_sound" : { ref = "water8", aux_data = {"vol" : -10,} },
		"hit_sound" : { ref = "water7", aux_data = {"vol" : -9} },
	},
	"aSP3b" : {
		"atk_type" : Globals.atk_type.SPECIAL,
		"hitcount" : 1,
		"damage" : 70,
		"knockback" : 475 * FMath.S,
		"knockback_type": Globals.knockback_type.RADIAL,
		"atk_level" : 5,
		"KB_angle" : 0,
		"atk_attr" : [Globals.atk_attr.FOLLOW_UP],
		"hit_sound" : { ref = "water7", aux_data = {"vol" : -7} },
	},
	"aSP3[h]" : {
		"atk_type" : Globals.atk_type.SPECIAL,
		"root" : "aSP3",
		"hitcount" : 1,
		"damage" : 40,
		"knockback" : 650 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED,
		"atk_level" : 5,
		"KB_angle" : -90,
		"reset_type" : Globals.reset_type.EARLY_RESET,
		"atk_attr" : [Globals.atk_attr.AUTOCHAIN],
		"move_sound" : { ref = "water8", aux_data = {"vol" : -10,} },
		"hit_sound" : { ref = "water7", aux_data = {"vol" : -9} },
	},
	"aSP3b[h]" : {
		"atk_type" : Globals.atk_type.SPECIAL,
		"root" : "aSP3b",
#		"no_revoke_time" : 0,
		"hitcount" : 1,
		"damage" : 70,
		"knockback" : 500 * FMath.S,
		"knockback_type": Globals.knockback_type.RADIAL,
		"atk_level" : 5,
		"KB_angle" : 0,
		"atk_attr" : [Globals.atk_attr.FOLLOW_UP],
		"hit_sound" : { ref = "water7", aux_data = {"vol" : -7} },
	},
	"aSP3[ex]" : {
		"atk_type" : Globals.atk_type.EX,
		"hitcount" : 1,
		"damage" : 60,
		"knockback" : 650 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED,
		"atk_level" : 6,
		"KB_angle" : -90,
		"atk_attr" : [Globals.atk_attr.AUTOCHAIN],
		"move_sound" : { ref = "water8", aux_data = {"vol" : -10,} },
		"hit_sound" : { ref = "water7", aux_data = {"vol" : -9} },
	},
	"aSP3b[ex]" : {
		"atk_type" : Globals.atk_type.EX,
		"hitcount" : 1,
		"damage" : 120,
		"knockback" : 525 * FMath.S,
		"knockback_type": Globals.knockback_type.RADIAL,
		"atk_level" : 6,
		"KB_angle" : 0,
		"atk_attr" : [Globals.atk_attr.FOLLOW_UP],
		"hit_sound" : { ref = "water7", aux_data = {"vol" : -7} },
	},
	
	"SP4": {
		"atk_type" : Globals.atk_type.SPECIAL,
		"atk_attr" : [],
		"reset_type" : Globals.reset_type.NON_ATK_RESET,
		"move_sound" : [{ ref = "water4", aux_data = {"vol" : -16,} }, { ref = "blast4", aux_data = {"vol" : -16,} }],
	},
	"SP4[h]": {
		"atk_type" : Globals.atk_type.SPECIAL,
		"atk_attr" : [],
		"reset_type" : Globals.reset_type.NON_ATK_RESET,
		"move_sound" : [{ ref = "water4", aux_data = {"vol" : -16,} }, { ref = "blast4", aux_data = {"vol" : -16,} }],
	},
	"SP4[ex]": {
		"atk_type" : Globals.atk_type.EX,
		"atk_attr" : [],
		"move_sound" : [{ ref = "water4", aux_data = {"vol" : -16,} }, { ref = "blast4", aux_data = {"vol" : -16,} }],
	},
	
	"aSP5" : {
		"atk_type" : Globals.atk_type.SPECIAL,
#		"quick_turn_limit" : 4, # if on ground, can only quick turn on the first X frames
		"hitcount" : 1,
		"damage" : 80,
		"knockback" : 450 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED,
		"atk_level" : 3,
		"hitspark_palette" : "red",
		"KB_angle" : -45,
		"reset_type" : Globals.reset_type.STARTUP_RESET,
		"atk_attr" : [Globals.atk_attr.DESTROY_ENTITIES],
		"move_sound" : [{ ref = "launch2", aux_data = {"vol" : -5,} }, { ref = "impact33", aux_data = {"vol" : -23,} }],
		"hit_sound" : { ref = "cut5", aux_data = {"vol" : -7} },
	},
	"aSP5[h]" : {
		"atk_type" : Globals.atk_type.SPECIAL,
#		"quick_turn_limit" : 4, # if on ground, can only quick turn on the first X frames
		"hitcount" : 1,
		"damage" : 50,
		"knockback" : 200 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED,
		"atk_level" : 3,
		"fixed_hitstop" : 10,
		"fixed_atker_hitstop" : 1,
		"hitspark_palette" : "red",
		"KB_angle" : -20,
		"reset_type" : Globals.reset_type.STARTUP_RESET,
		"atk_attr" : [Globals.atk_attr.AUTOCHAIN, Globals.atk_attr.DESTROY_ENTITIES],
		"move_sound" : [{ ref = "launch2", aux_data = {"vol" : -5,} }, { ref = "impact33", aux_data = {"vol" : -23,} }],
		"hit_sound" : { ref = "cut5", aux_data = {"vol" : -7} },
	},
	"aSP5[h]b" : {
		"atk_type" : Globals.atk_type.SPECIAL,
#		"quick_turn_limit" : 4, # if on ground, can only quick turn on the first X frames
		"hitcount" : 1,
		"damage" : 50,
		"knockback" : 450 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED,
		"atk_level" : 3,
		"hitspark_palette" : "red",
		"KB_angle" : -45,
		"atk_attr" : [Globals.atk_attr.FOLLOW_UP, Globals.atk_attr.DESTROY_ENTITIES, Globals.atk_attr.NO_IMPULSE],
		"move_sound" : [{ ref = "launch2", aux_data = {"vol" : -5,} }, { ref = "impact33", aux_data = {"vol" : -23,} }],
		"hit_sound" : { ref = "cut5", aux_data = {"vol" : -7} },
	},
	"aSP5[ex]" : {
		"atk_type" : Globals.atk_type.EX,
#		"quick_turn_limit" : 4, # if on ground, can only quick turn on the first X frames
		"hitcount" : 1,
		"damage" : 100,
		"knockback" : 550 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED,
		"atk_level" : 4,
		"hitspark_palette" : "red",
		"KB_angle" : -45,
		"atk_attr" : [Globals.atk_attr.DESTROY_ENTITIES],
		"move_sound" : [{ ref = "launch2", aux_data = {"vol" : -5,} }, { ref = "impact33", aux_data = {"vol" : -23,} }],
		"hit_sound" : { ref = "cut5", aux_data = {"vol" : -7} },
	},
	
	"aSP6[ex]" : {
		"atk_type" : Globals.atk_type.EX,
		"sequence": "SP6[ex]SeqA",
		"hitcount" : 1,
		"hitspark_type" : Globals.hitspark_type.NONE,
		"atk_attr" : [Globals.atk_attr.UNBLOCKABLE, Globals.atk_attr.CANNOT_CHAIN_INTO]
	},
	
	"SP6[ex]SeqE": {
		"sequence_hits" : [{"damage":200, "hitstop": 15}], # for hits during sequence, has a key, only contain damage
		"sequence_launch" : { # for final hit of sequence
			"damage" : 0,
			"hitstop" : 0,
#			"guard_gain" : 3500,
#			"EX_gain": 0,
			"launch_power" : 800 * FMath.S,
			"launch_angle" : -103, # launch backwards
			"atk_level" : 4,
		}
	},
	"aSP6[ex]SeqE": { # if Grabbed hit a ledge while Grabber doesn't
		"sequence_hits" : [{"damage":200, "hitstop": 15}],
		"sequence_launch" : {
			"damage" : 0,
			"hitstop" : 0,
#			"guard_gain" : 3500,
#			"EX_gain": 0,
			"launch_power" : 800 * FMath.S,
			"launch_angle" : -103,
			"atk_level" : 4,
		}
	},
	
	"SP7": {
		"atk_type" : Globals.atk_type.SPECIAL,
		"reset_type" : Globals.reset_type.NON_ATK_RESET,
		"atk_attr" : [Globals.atk_attr.NO_TURN, Globals.atk_attr.NO_QUICK_CANCEL],
	},

}



