extends Node2D

# CHARACTER DATA --------------------------------------------------------------------------------------------------

const NAME = "Ina'nis"
const CHAR_REF = "Ina"
const ORDER = 0

const CLASS1 = Em.class1.BALANCED
const CLASS2 = Em.class2.AERIAL

# character movement stats, use to overwrite
const SPEED = 280 * FMath.S # ground speed
const JUMP_SPEED = 700 * FMath.S
const EYE_LEVEL = 12 # number of pixels EX Flash appears above position

const MAX_AIR_JUMP = 2
const MAX_AIR_DASH = 1

const GRD_DASH_SPEED = 120 * FMath.S # distance
const AIR_DASH_SPEED = 120 * FMath.S # distance

const TRANSIT_SDASH = ["BlinkTransit", "EBlinkTransit"] # unique dash transits that you can quick cancel into SDash
const TRANSIT_DODGE = ["BlinkTransit"] # unique dash transits that you can quick cancel into Dodge

const TRAITS = [Em.trait.VULN_GRD_DASH, Em.trait.VULN_AIR_DASH, Em.trait.DASH_IMPULSE]

const DEFAULT_HITSPARK_TYPE = Em.hitspark_type.HIT
const DEFAULT_HITSPARK_PALETTE = "dark_purple"
const SDHitspark_COLOR = "dark_purple"


const PALETTE_TO_HITSPARK_PALETTE = {
	1: "dark_purple",
	2: "pink",
	3: "purple",
	4: "dark_pink",
	5: "dark_purple",
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

#const UP_TILTS = ["L3", "F3", "aL3", "aF3", "aSP4", "aSP4[ex]"] # to know which moves can be cancelled from jumpsquat

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
		Em.move.MOVE_SOUND : { ref = "whoosh15", aux_data = {"vol" : -6} },
		Em.move.HIT_SOUND : [{ ref = "book1", aux_data = {"vol" : -5} }, { ref = "impact9", aux_data = {"vol" : -15} }],
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
		Em.move.DMG : 65,
		Em.move.KB : 445 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 4,
		Em.move.KB_ANGLE : -60,
		Em.move.ATK_ATTR : [Em.atk_attr.VULN_LIMBS, Em.atk_attr.SS_LAUNCH],
		Em.move.MOVE_SOUND : [{ ref = "blast4", aux_data = {"vol" : -15} }, { ref = "web1", aux_data = {"vol" : -12} }],
		Em.move.HIT_SOUND : { ref = "impact42", aux_data = {"vol" : -15} },
	},
	"F2" : {
		Em.move.ATK_TYPE : Em.atk_type.FIERCE,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 65,
		Em.move.KB : 445 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 4,
		Em.move.KB_ANGLE : -80,
		Em.move.ATK_ATTR : [Em.atk_attr.VULN_LIMBS, Em.atk_attr.SS_LAUNCH],
		Em.move.MOVE_SOUND : [{ ref = "blast4", aux_data = {"vol" : -15} }, { ref = "web1", aux_data = {"vol" : -12} }],
		Em.move.HIT_SOUND : { ref = "impact42", aux_data = {"vol" : -15} },
	},
	"F3" : {
		Em.move.ATK_TYPE : Em.atk_type.FIERCE,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 65,
		Em.move.KB : 445 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 4,
		Em.move.KB_ANGLE : -90,
		Em.move.ATK_ATTR : [Em.atk_attr.VULN_LIMBS, Em.atk_attr.ANTI_AIR, Em.atk_attr.SS_LAUNCH],
		Em.move.MOVE_SOUND : [{ ref = "blast4", aux_data = {"vol" : -15} }, { ref = "web1", aux_data = {"vol" : -12} }],
		Em.move.HIT_SOUND : { ref = "impact42", aux_data = {"vol" : -15} },
	},
	"H" : {
		Em.move.ATK_TYPE : Em.atk_type.HEAVY,
		Em.move.HITCOUNT : 3,
		Em.move.LAST_HIT_RANGE : 19,
		Em.move.IGNORE_TIME : 4,
		Em.move.FIXED_HITSTOP_MULTI: 7,
		Em.move.FIXED_ATKER_HITSTOP_MULTI: 3,
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
		Em.move.MOVE_SOUND : { ref = "whoosh13", aux_data = {"vol" : -15} },
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
		Em.move.DMG : 65,
		Em.move.KB : 445 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 4,
		Em.move.KB_ANGLE : -60,
		Em.move.ATK_ATTR : [Em.atk_attr.VULN_LIMBS, Em.atk_attr.SS_LAUNCH],
		Em.move.MOVE_SOUND : [{ ref = "blast4", aux_data = {"vol" : -15} }, { ref = "web1", aux_data = {"vol" : -12} }],
		Em.move.HIT_SOUND : { ref = "impact42", aux_data = {"vol" : -15} },
	},
	"aF2" : {
		Em.move.ATK_TYPE : Em.atk_type.FIERCE,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 65,
		Em.move.KB : 445 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 4,
		Em.move.KB_ANGLE : -50,
		Em.move.ATK_ATTR : [Em.atk_attr.VULN_LIMBS, Em.atk_attr.SS_LAUNCH],
		Em.move.MOVE_SOUND : [{ ref = "blast4", aux_data = {"vol" : -15} }, { ref = "web1", aux_data = {"vol" : -12} }],
		Em.move.HIT_SOUND : { ref = "impact42", aux_data = {"vol" : -15} },
	},
	"aF3" : {
		Em.move.ATK_TYPE : Em.atk_type.FIERCE,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 65,
		Em.move.KB : 445 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 4,
		Em.move.KB_ANGLE : -85,
		Em.move.ATK_ATTR : [Em.atk_attr.VULN_LIMBS, Em.atk_attr.SS_LAUNCH],
		Em.move.MOVE_SOUND : [{ ref = "blast4", aux_data = {"vol" : -15} }, { ref = "web1", aux_data = {"vol" : -12} }],
		Em.move.HIT_SOUND : { ref = "impact42", aux_data = {"vol" : -15} },
	},
	"aH" : {
		Em.move.ATK_TYPE : Em.atk_type.HEAVY,
		Em.move.HITCOUNT : 3,
		Em.move.LAST_HIT_RANGE : 28,
		Em.move.IGNORE_TIME : 5,
		Em.move.FIXED_HITSTOP_MULTI: 7,
		Em.move.FIXED_ATKER_HITSTOP_MULTI: 3,
		Em.move.DMG : 30,
		Em.move.KB : 500 * FMath.S,
		Em.move.FIXED_KB_MULTI : 100 * FMath.S,
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
		Em.move.ATK_ATTR : [Em.atk_attr.STRAFE_NON_NORMAL],
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
		Em.move.ATK_ATTR : [Em.atk_attr.VULN_LIMBS],
	},
}



