extends Node2D

# CHARACTER DATA --------------------------------------------------------------------------------------------------
# may be saved in a .tres file later? Or just leave it in the .gd file

const NAME = "Gura"

# character movement stats, use to overwrite
const SPEED = 360.0 # ground speed
const AIR_STRAFE_SPEED = 35
const AIR_STRAFE_LIMIT = 0.8 # speed limit of air strafing, limit depends on ground speed
const JUMP_SPEED = 700.0
const JUMP_HORIZONTAL_SPEED = 100.0
const AIR_JUMP_MOD = 0.9 # reduce height of air jumps
const GRAVITY_MOD = 1.0 # make sure variable's a float
const TERMINAL_VELOCITY_MOD = 7.2 # affect terminal velocity downward
const FASTFALL_MOD = 1.2 # fastfall speed, mod of terminal velocity
const FRICTION = 0.15 # between 0.0 and 1.0
const ACCELERATION = 0.15 # between 0.0 and 1.0
const AIR_RESISTANCE = 0.03 # between 0.0 and 1.0
const FALL_GRAV_MOD = 1.0 # reduced gravity when going down
const MAX_AIR_JUMP = 1
const MAX_AIR_DASH = 2
const GROUND_DASH_SPEED = 480.0 # duration in animation data
const AIR_DASH_SPEED = 390.0 # duration in animation data
const IMPULSE_MOD = 1.25 # multiply by SPEED to get impulse velocity
const LONG_HOP_JUMP_MOD = 1.25 # multiply by SPEED to get horizontal velocity gain when doing long hops
const SUPER_JUMP_MOD = 1.5

const HITSTUN_REDUCTION_AT_MAX_GG = 0.75 # max reduction in hitstun when defender's Guard Gauge is at 200%, heavy characters have higher
const KB_BOOST_AT_MAX_GG = 2.0 # max increase of knockback when defender's Guard Gauge is at 200%, light characters have higher

const DAMAGE_VALUE_LIMIT = 950.0
const GUARD_GAUGE_REGEN_RATE = 0.05 # % of GG regened per second when GG < 100%
const GUARD_GAUGE_DEGEN_RATE = -0.55 # % of GG degened per second when GG > 100%
const BASE_BLOCK_CHIP_DAMAGE_MOD = 0.35 # % of damage taken as chip damage when blocking (average is 0.25)
#const GUARD_GAUGE_GAIN_MOD = 0.8 # modify Guard Gain when being comboed, tankier characters have higher GUARD_GAUGE_GAIN_MOD
#const GUARD_GAUGE_LOSS_MOD = 1.2 # modify Guard Loss, tankier characters have lower GUARD_GAUGE_LOSS_MOD
const AIR_BLOCK_GG_COST = -2000.0 # Guard Gauge drain when starting an Air Block
const TRAITS = [Globals.trait.CHAIN_DASH, Globals.trait.VULN_GRD_DASH, Globals.trait.VULN_AIR_DASH]

const SDHitspark_COLOR = "blue"

const PALETTE_TO_PORTRAIT = {
	1: Color(0.75, 0.93, 1.25),
	2: Color(1.20, 0.70, 0.70),
}

const UNIQUE_DATA_REF = {
	"groundfin_count" : 0,
	"groundfin_trigger" : false,
	"instinct_gauge" : 0
}

const STARTERS = ["L1", "L2", "F1", "F2", "F3", "H", "aL1", "aL2", "aF1", "aF3", "aH", "SP1", "SP1[ex]", "aSP1", "aSP1[ex]", \
		"aSP2", "aSP2[ex]", "SP3", "aSP3", "SP3[ex]", "aSP3[ex]", "SP4", "SP4[ex]"]
const EX_MOVES = ["SP1[ex]", "aSP1[ex]", "aSP2[ex]", "SP3[ex]", "aSP3[ex]", "SP4[ex]"]
const SUPERS = []

const EX_FLASH_ANIM = ["SP1[ex]", "aSP1[ex]", "aSP2[ex]", "SP3[ex]", "aSP3[ex]", "SP3b[ex]", "SP4[ex]"] # list of movenames that will emit EX flash
#const EX_FLASH_ANIM = ["H", "Hb"]

# const DIRECTORY_NAME = "res://Characters/Gura/"

# this contain move_data for each active animation this character has
# use trim_suffix("Active") on animation name to find move in the database
const MOVE_DATABASE = {
	"L1" : {
		"atk_type" : Globals.atk_type.LIGHT,
		"hitcount" : 1,
		"damage" : 20,
		"knockback" : 0,
		"knockback_type": Globals.knockback_type.FIXED, # for radial, +ve KB_angle means rotating clockwise, -ve is counterclockwise
		"attack_level" : 2,
		"fixed_hitstop" : 1,
		"priority": 2,
		"guard_drain": 1500,
		"guard_gain_on_combo" : 2500,
		"EX_gain": 600,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : -PI/5,
		"atk_attr" : [Globals.atk_attr.AUTOCHAIN],
		"move_sound" : { ref = "whoosh2", aux_data = {"vol" : -12} },
		"hit_sound" : { ref = "cut1", aux_data = {"vol" : -15} },
	},
	"L1b" : {
		"atk_type" : Globals.atk_type.LIGHT,
		"hitcount" : 1,
		"damage" : 20,
		"knockback" : 200,
		"knockback_type": Globals.knockback_type.FIXED, # for radial, +ve KB_angle means rotating clockwise, -ve is counterclockwise
		"attack_level" : 2,
		"priority": 2,
		"guard_drain": 0,
		"guard_gain_on_combo" : 0,
		"EX_gain": 600,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : -PI/5,
		"atk_attr" : [Globals.atk_attr.NO_IMPULSE],
		"move_sound" : { ref = "whoosh2", aux_data = {"vol" : -12} },
		"hit_sound" : { ref = "cut1", aux_data = {"vol" : -15} },
	},
	"L2" : {
		"atk_type" : Globals.atk_type.LIGHT,
		"hitcount" : 1,
		"damage" : 30,
		"knockback" : 180,
		"knockback_type": Globals.knockback_type.FIXED, # for radial, +ve KB_angle means rotating clockwise, -ve is counterclockwise
		"attack_level" : 3,
		"priority": 2,
		"guard_drain": 1000,
		"guard_gain_on_combo" : 2500,
		"EX_gain": 1500,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : -PI/5,
		"atk_attr" : [Globals.atk_attr.LEDGE_DROP, Globals.atk_attr.NO_IMPULSE],
		"move_sound" : { ref = "whoosh14", aux_data = {"vol" : -9, "bus" : "PitchDown"} },
		"hit_sound" : { ref = "impact11", aux_data = {"vol" : -10} },
	},
	"F1" : {
		"atk_type" : Globals.atk_type.FIERCE, # light/fierce/heavy/special/ex/super
		"hitcount" : 1,
		"damage" : 60, # chip damage is a certain % of damage, Chipper Attribute can increase chip
		"knockback" : 350,  # knockback strength, block pushback (% of knockback strength), affect hitspark size and hitstop
		"knockback_type": Globals.knockback_type.MIRRORED,
		"attack_level" : 4, # 1~8, affect hitstun and blockstun
		"priority": 4, # aL < L < aF < F < aH < H < Specials (depend on move) < EX (depend on move), Super, but some moves are different
		"guard_drain": 1500, # on blocking opponent and opponent in neutral (multiplied), affect how well the move can guardcrush/break
		# Supers have 0 Guard Drain
		"guard_gain_on_combo" : 2500, # affect comboability
		"EX_gain": 2000, # EX Gain on block is a certain % of EX Gain on hit, defenders blocking this attack will gain a certain % as well
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : -PI/5, # in radians, 0 means straight ahead to the right, positive means rotating downward
		# some moves uses KBOrigin to determine KB_angle, has special data instead
		"atk_attr" : [], # enums
		"move_sound" : { ref = "whoosh13", aux_data = {"vol" : -12,} },
		# played when move is used, aux_data carry volume and bus
		"hit_sound" : { ref = "impact16", aux_data = {"vol" : -15} },
	},
	"F2" : {
		"atk_type" : Globals.atk_type.FIERCE,
		"hitcount" : 1,
		"damage" : 70,
		"knockback" : 400,
		"knockback_type": Globals.knockback_type.FIXED,
		"attack_level" : 4,
		"priority": 4,
		"guard_drain": 1500,
		"guard_gain_on_combo" : 2500,
		"EX_gain": 2000,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : 0,
		"atk_attr" : [],
		"move_sound" : { ref = "whoosh1", aux_data = {"vol" : -12,} },
		"hit_sound" : { ref = "cut2", aux_data = {"vol" : -15} },
	},
	"F3" : {
		"atk_type" : Globals.atk_type.FIERCE,
		"hitcount" : 1,
		"damage" : 70,
		"knockback" : 400,
		"knockback_type": Globals.knockback_type.RADIAL,
		"attack_level" : 4,
		"fixed_blockstun" : 5,
		"priority": 4,
		"guard_drain": 1500,
		"guard_gain_on_combo" : 2500,
		"EX_gain": 2000,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : PI/2,
		"atk_attr" : [Globals.atk_attr.ANTI_AIR, Globals.atk_attr.NO_CHAIN_ON_BLOCK],
		"move_sound" : { ref = "whoosh7", aux_data = {"vol" : -12,} },
		"hit_sound" : { ref = "impact19", aux_data = {"vol" : -18} },
	},
	"H" : {
		"atk_type" : Globals.atk_type.HEAVY,
		"hitcount" : 1,
		"damage" : 40,
		"knockback" : 150,
		"knockback_type": Globals.knockback_type.FIXED,
		"attack_level" : 2,
		"priority": 5,
		"guard_drain": 2000,
		"guard_gain_on_combo" : 3500,
		"EX_gain": 1000,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : -PI/2.4,
		"atk_attr" : [Globals.atk_attr.AUTOCHAIN, Globals.atk_attr.ANTI_GUARD, Globals.atk_attr.NO_CHAIN],
		"move_sound" : [{ ref = "water8", aux_data = {"vol" : -13,} }, { ref = "water5", aux_data = {"vol" : -20} }],
		"hit_sound" : { ref = "water7", aux_data = {"vol" : -9} },
	},
	"Hb" : {
		"atk_type" : Globals.atk_type.HEAVY,
		"hitcount" : 1,
		"damage" : 70,
		"knockback" : 550,
		"knockback_type": Globals.knockback_type.FIXED,
		"attack_level" : 6,
		"priority": 5,
		"guard_drain": 0,
		"guard_gain_on_combo" : 0,
		"EX_gain": 1500,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : -PI/2.4,
		"atk_attr" : [Globals.atk_attr.JUMP_CANCEL, Globals.atk_attr.ANTI_GUARD, Globals.atk_attr.NO_IMPULSE],
		"hit_sound" : { ref = "water7", aux_data = {"vol" : -7} },
	},
	"H[h]" : {
		"atk_type" : Globals.atk_type.HEAVY,
		"root" : "H",
		"hitcount" : 1,
		"damage" : 40,
		"knockback" : 150,
		"knockback_type": Globals.knockback_type.FIXED,
		"attack_level" : 2,
		"priority": 5,
		"guard_drain": 2000,
		"guard_gain_on_combo" : 3500,
		"EX_gain": 1000,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : -PI/2.4,
		"atk_attr" : [Globals.atk_attr.AUTOCHAIN, Globals.atk_attr.ANTI_GUARD, Globals.atk_attr.NO_CHAIN],
		"move_sound" : [{ ref = "water8", aux_data = {"vol" : -13,} }, { ref = "water5", aux_data = {"vol" : -20} }],
		"hit_sound" : { ref = "water7", aux_data = {"vol" : -9} },
	},
	"Hb[h]" : {
		"atk_type" : Globals.atk_type.HEAVY,
		"root" : "Hb",
		"hitcount" : 1,
		"damage" : 70,
		"knockback" : 550,
		"knockback_type": Globals.knockback_type.FIXED,
		"attack_level" : 6,
		"priority": 5,
		"guard_drain": 0,
		"guard_gain_on_combo" : 0,
		"EX_gain": 1500,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : -PI/2.4,
		"atk_attr" : [Globals.atk_attr.JUMP_CANCEL, Globals.atk_attr.ANTI_GUARD, Globals.atk_attr.NO_IMPULSE],
		"hit_sound" : { ref = "water7", aux_data = {"vol" : -7} },
	},
	"aL1" : {
		"atk_type" : Globals.atk_type.LIGHT,
		"hitcount" : 1,
		"damage" : 35,
		"knockback" : 200,
		"knockback_type": Globals.knockback_type.FIXED, # for radial, +ve KB_angle means rotating clockwise, -ve is counterclockwise
		"attack_level" : 2,
		"priority": 1,
		"guard_drain": 1000,
		"guard_gain_on_combo" : 2000,
		"EX_gain": 1600,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : PI/2.5,
		"atk_attr" : [Globals.atk_attr.AIR_ATTACK],
		"move_sound" : { ref = "whoosh3", aux_data = {"vol" : -12} },
		"hit_sound" : { ref = "impact14", aux_data = {"vol" : -15} },
	},
	"aL2" : {
		"atk_type" : Globals.atk_type.LIGHT,
		"hitcount" : 1,
		"damage" : 30,
		"knockback" : 200,
		"knockback_type": Globals.knockback_type.FIXED,
		"attack_level" : 2,
		"priority": 1,
		"guard_drain": 750,
		"guard_gain_on_combo" : 1500,
		"EX_gain": 1000,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : PI/2,
		"atk_attr" : [Globals.atk_attr.AIR_ATTACK, Globals.atk_attr.NO_JUMP_CANCEL],
		"move_sound" : { ref = "whoosh15", aux_data = {"vol" : -9} },
		"hit_sound" : { ref = "cut8", aux_data = {"vol" : -10} },
	},
	"aF1" : {
		"atk_type" : Globals.atk_type.FIERCE,
		"hitcount" : 1,
		"damage" : 60,
		"knockback" : 350,
		"knockback_type": Globals.knockback_type.RADIAL, # for radial, +ve KB_angle means rotating clockwise, -ve is counterclockwise
		"attack_level" : 3,
		"priority": 3,
		"guard_drain": 1500,
		"guard_gain_on_combo" : 2500,
		"EX_gain": 2000,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : PI/2.5,
		"atk_attr" : [Globals.atk_attr.AIR_ATTACK],
		"move_sound" : { ref = "whoosh14", aux_data = {"vol" : -9, "bus": "PitchDown"} },
		"hit_sound" : { ref = "impact12", aux_data = {"vol" : -15} },
	},
	"aF3" : {
		"atk_type" : Globals.atk_type.FIERCE,
		"hitcount" : 1,
		"damage" : 60,
		"knockback" : 350,
		"knockback_type": Globals.knockback_type.FIXED,
		"attack_level" : 4,
		"priority": 3,
		"guard_drain": 1500,
		"guard_gain_on_combo" : 2500,
		"EX_gain": 2000,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : -PI/2.5,
		"atk_attr" : [Globals.atk_attr.AIR_ATTACK, Globals.atk_attr.ANTI_AIR],
		"move_sound" : { ref = "whoosh12", aux_data = {"vol" : -2} },
		"hit_sound" : { ref = "cut5", aux_data = {"vol" : -10} },
	},
	"aH" : {
		"atk_type" : Globals.atk_type.HEAVY,
		"hitcount" : 1,
		"damage" : 100,
		"knockback" : 475,
		"knockback_type": Globals.knockback_type.FIXED,
		"attack_level" : 4,
		"priority": 5,
		"guard_drain": 2000,
		"guard_gain_on_combo" : 3500,
		"EX_gain": 2500,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : PI/4,
		"atk_attr" : [Globals.atk_attr.AIR_ATTACK, Globals.atk_attr.ANTI_GUARD],
		"move_sound" : { ref = "water4", aux_data = {"vol" : -12,} },
		"hit_sound" : { ref = "water5", aux_data = {"vol" : -18} },
	},
	
	"SP1": {
		"atk_type" : Globals.atk_type.SPECIAL, # used for chaining
		"priority": 0,
		"atk_attr" : [], # some projectile moves can have attributes like superarmor
	},
	"aSP1": {
		"atk_type" : Globals.atk_type.SPECIAL,
		"priority": 0,
		"atk_attr" : [],
	},
	"SP1[c1]": {
		"root" : "SP1", # needed for aerial memory
		"move_sound" : { ref = "whoosh12", aux_data = {"vol" : -2} },
	},
	"SP1[c2]": {
		"root" : "SP1",
		"move_sound" : { ref = "whoosh12", aux_data = {} },
	},
	"SP1[c3]": {
		"root" : "SP1",
		"move_sound" : [{ ref = "water4", aux_data = {"vol" : -20,} }, { ref = "whoosh12", aux_data = {} }],
	},
	"aSP1[c1]": {
		"root" : "aSP1",
		"move_sound" : { ref = "whoosh12", aux_data = {"vol" : -2} },
	},
	"aSP1[c2]": {
		"root" : "aSP1",
		"move_sound" : { ref = "whoosh12", aux_data = {} },
	},
	"aSP1[c3]": {
		"root" : "aSP1",
		"move_sound" : [{ ref = "water4", aux_data = {"vol" : -20,} }, { ref = "whoosh12", aux_data = {} }],
	},
	"SP1[ex]": {
		"atk_type" : Globals.atk_type.EX,
		"priority": 0,
		"move_sound" : [{ ref = "water4", aux_data = {"vol" : -20,} }, { ref = "whoosh12", aux_data = {} }],
		"atk_attr" : [], # some projectile moves can have attributes like superarmor
	},
	"aSP1[ex]": {
		"atk_type" : Globals.atk_type.EX,
		"priority": 0,
		"move_sound" : [{ ref = "water4", aux_data = {"vol" : -20,} }, { ref = "whoosh12", aux_data = {} }],
		"atk_attr" : [],
	},
	
	"aSP2" : {
		"atk_type" : Globals.atk_type.SPECIAL,
		"hitcount" : 3,
		"ignore_time" : 6,
		"damage" : 40,
		"knockback" : 500,
		"fixed_knockback_multi" : 300,
		"knockback_type": Globals.knockback_type.FIXED,
		"attack_level" : 4,
		"fixed_blockstun" : 5,
		"priority": 7,
		"guard_drain": 1500,
		"guard_gain_on_combo" : 2500,
		"EX_gain": 1000,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : -PI/4,
		"atk_attr" : [Globals.atk_attr.NO_PUSHBACK, Globals.atk_attr.NO_STRAFE],
		"move_sound" : [{ ref = "water4", aux_data = {"vol" : -15,} }, { ref = "blast3", aux_data = {"vol" : -10, "bus" : "LowPass"} }],
		"hit_sound" : [{ ref = "impact11", aux_data = {"vol" : -20} }, { ref = "water1", aux_data = {"vol" : -8} }],
	},
	"aSP2[h]" : {
		"atk_type" : Globals.atk_type.SPECIAL,
		"hitcount" : 1,
		"damage" : 80,
		"knockback" : 500,
		"knockback_type": Globals.knockback_type.FIXED,
		"attack_level" : 4,
		"fixed_blockstun" : 5,
		"priority": 7,
		"guard_drain": 1500,
		"guard_gain_on_combo" : 2500,
		"EX_gain": 2500,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : -PI/2,
		"atk_attr" : [Globals.atk_attr.NO_PUSHBACK, Globals.atk_attr.NO_STRAFE],
		"move_sound" : [{ ref = "water4", aux_data = {"vol" : -15,} }, { ref = "blast3", aux_data = {"vol" : -10, "bus" : "LowPass"} }],
		"hit_sound" : [{ ref = "impact11", aux_data = {"vol" : -20} }, { ref = "water1", aux_data = {"vol" : -8} }],
	},
	"aSP2[ex]" : {
		"atk_type" : Globals.atk_type.SPECIAL,
		"hitcount" : 5,
		"ignore_time" : 5,
		"damage" : 40,
		"knockback" : 600,
		"fixed_knockback_multi" : 300,
		"knockback_type": Globals.knockback_type.FIXED,
		"attack_level" : 5,
		"fixed_blockstun" : 5,
		"priority": 10,
		"guard_drain": 2000,
		"guard_gain_on_combo" : 3500,
		"EX_gain": 0,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : -PI/4,
		"atk_attr" : [Globals.atk_attr.NO_PUSHBACK, Globals.atk_attr.NO_STRAFE],
		"move_sound" : [{ ref = "water4", aux_data = {"vol" : -15,} }, { ref = "blast3", aux_data = {"vol" : -10, "bus" : "LowPass"} }],
		"hit_sound" : [{ ref = "impact11", aux_data = {"vol" : -20} }, { ref = "water1", aux_data = {"vol" : -8} }],
	},
	
	"SP3" : {
		"atk_type" : Globals.atk_type.SPECIAL,
		"hitcount" : 1,
		"damage" : 40,
		"knockback" : 600,
		"knockback_type": Globals.knockback_type.FIXED,
		"attack_level" : 2,
		"fixed_blockstun" : 5,
		"burstlock": 8,
		"priority": 8,
		"guard_drain": 2000,
		"guard_gain_on_combo" : 3500,
		"EX_gain": 1000,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : 0,
		"atk_attr" : [Globals.atk_attr.ANTI_AIR, Globals.atk_attr.AUTOCHAIN, Globals.atk_attr.NO_CHAIN, Globals.atk_attr.DRAG_KB, \
				Globals.atk_attr.NO_PUSHBACK],
		"move_sound" : { ref = "water8", aux_data = {"vol" : -10,} },
		"hit_sound" : { ref = "water7", aux_data = {"vol" : -9} },
	},
	"SP3b" : {
		"atk_type" : Globals.atk_type.SPECIAL,
		"hitcount" : 1,
		"damage" : 70,
		"knockback" : 475,
		"knockback_type": Globals.knockback_type.RADIAL,
		"attack_level" : 5,
		"fixed_blockstun" : 5,
		"priority": 8,
		"guard_drain": 0,
		"guard_gain_on_combo" : 0,
		"EX_gain": 1500,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : 0,
		"atk_attr" : [Globals.atk_attr.ANTI_AIR, Globals.atk_attr.NO_PUSHBACK],
		"hit_sound" : { ref = "water7", aux_data = {"vol" : -7} },
	},
	"SP3[h]" : {
		"atk_type" : Globals.atk_type.SPECIAL,
		"root" : "aSP3",
		"hitcount" : 1,
		"damage" : 40,
		"knockback" : 650,
		"knockback_type": Globals.knockback_type.FIXED,
		"attack_level" : 2,
		"fixed_blockstun" : 5,
		"burstlock": 8,
		"priority": 8,
		"guard_drain": 2000,
		"guard_gain_on_combo" : 3500,
		"EX_gain": 1000,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : 0,
		"atk_attr" : [Globals.atk_attr.ANTI_AIR, Globals.atk_attr.AUTOCHAIN, Globals.atk_attr.NO_CHAIN, Globals.atk_attr.DRAG_KB, \
				Globals.atk_attr.NO_PUSHBACK],
		"move_sound" : { ref = "water8", aux_data = {"vol" : -10,} },
		"hit_sound" : { ref = "water7", aux_data = {"vol" : -9} },
	},
	"SP3b[h]" : {
		"atk_type" : Globals.atk_type.SPECIAL,
		"root" : "aSP3b",
		"hitcount" : 1,
		"damage" : 70,
		"knockback" : 500,
		"knockback_type": Globals.knockback_type.RADIAL,
		"attack_level" : 5,
		"fixed_blockstun" : 5,
		"priority": 8,
		"guard_drain": 0,
		"guard_gain_on_combo" : 0,
		"EX_gain": 1500,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : 0,
		"atk_attr" : [Globals.atk_attr.ANTI_AIR, Globals.atk_attr.NO_PUSHBACK],
		"hit_sound" : { ref = "water7", aux_data = {"vol" : -7} },
	},
	"SP3[ex]" : {
		"atk_type" : Globals.atk_type.SPECIAL,
		"hitcount" : 1,
		"damage" : 60,
		"knockback" : 650,
		"knockback_type": Globals.knockback_type.FIXED,
		"attack_level" : 2,
		"fixed_blockstun" : 5,
		"burstlock": 8,
		"priority": 11,
		"guard_drain": 2000,
		"guard_gain_on_combo" : 3500,
		"EX_gain": 0,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : 0,
		"atk_attr" : [Globals.atk_attr.ANTI_AIR, Globals.atk_attr.AUTOCHAIN, Globals.atk_attr.NO_CHAIN, Globals.atk_attr.DRAG_KB, \
				Globals.atk_attr.NO_PUSHBACK, Globals.atk_attr.SEMI_INVUL_STARTUP],
		"move_sound" : { ref = "water8", aux_data = {"vol" : -10,} },
		"hit_sound" : { ref = "water7", aux_data = {"vol" : -9} },
	},
	"SP3b[ex]" : {
		"atk_type" : Globals.atk_type.SPECIAL,
		"hitcount" : 1,
		"damage" : 120,
		"knockback" : 525,
		"knockback_type": Globals.knockback_type.RADIAL,
		"attack_level" : 6,
		"fixed_blockstun" : 5,
		"priority": 11,
		"guard_drain": 0,
		"guard_gain_on_combo" : 0,
		"EX_gain": 0,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : 0,
		"atk_attr" : [Globals.atk_attr.ANTI_AIR, Globals.atk_attr.NO_PUSHBACK, Globals.atk_attr.SEMI_INVUL_STARTUP],
		"hit_sound" : { ref = "water7", aux_data = {"vol" : -7} },
	},
	
	"SP4": {
		"atk_type" : Globals.atk_type.SPECIAL,
		"priority": 0,
		"atk_attr" : [],
		"move_sound" : [{ ref = "water4", aux_data = {"vol" : -16,} }, { ref = "blast4", aux_data = {"vol" : -16,} }],
	},
	"SP4[h]": {
		"atk_type" : Globals.atk_type.SPECIAL,
		"priority": 0,
		"atk_attr" : [],
		"move_sound" : [{ ref = "water4", aux_data = {"vol" : -16,} }, { ref = "blast4", aux_data = {"vol" : -16,} }],
	},
	"SP4[ex]": {
		"atk_type" : Globals.atk_type.SPECIAL,
		"priority": 0,
		"atk_attr" : [],
		"move_sound" : [{ ref = "water4", aux_data = {"vol" : -16,} }, { ref = "blast4", aux_data = {"vol" : -16,} }],
	},
}

