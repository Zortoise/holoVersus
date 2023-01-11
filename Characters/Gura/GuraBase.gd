extends Node2D

# CHARACTER DATA --------------------------------------------------------------------------------------------------
# may be saved in a .tres file later? Or just leave it in the .gd file

const NAME = "Gura"

# character movement stats, use to overwrite
const SPEED = 340 * FMath.S # ground speed
const AIR_STRAFE_SPEED_MOD = 10 # percent of ground speed
const AIR_STRAFE_LIMIT_MOD = 800 # speed limit of air strafing, limit depends on calculated air strafe speed
const JUMP_SPEED = 700 * FMath.S
const JUMP_HORIZONTAL_SPEED = 100 * FMath.S
const AIR_JUMP_MOD = 90 # reduce height of air jumps
const GRAVITY_MOD = 100 # make sure variable's a float
const TERMINAL_VELOCITY_MOD = 720 # affect terminal velocity downward
const FASTFALL_MOD = 125 # fastfall speed, mod of terminal velocity
const FRICTION = 15 # between 0.0 and 1.0
const ACCELERATION = 10 # between 0.0 and 1.0
const AIR_RESISTANCE = 3 # between 0.0 and 1.0
const FALL_GRAV_MOD = 100 # reduced gravity when going down
const MAX_AIR_JUMP = 1
const MAX_AIR_DASH = 2
const GROUND_DASH_SPEED = 420 * FMath.S # duration in animation data
const AIR_DASH_SPEED = 390 * FMath.S # duration in animation data
const IMPULSE_MOD = 150 # multiply by SPEED to get impulse velocity
const LONG_HOP_JUMP_MOD = 125 # multiply by SPEED to get horizontal velocity gain when doing long hops
#const SUPER_JUMP_MOD = 150
const WAVE_DASH_SPEED_MOD = 150 # affect speed of wavelanding, multiplied by GROUND_DASH_SPEED

const HITSTUN_REDUCTION_AT_MAX_GG = 75 # max reduction in hitstun when defender's Guard Gauge is at 200%, heavy characters have higher
const KB_BOOST_AT_MAX_GG = 200 # max increase of knockback when defender's Guard Gauge is at 200%, light characters have higher

const DAMAGE_VALUE_LIMIT = 950
const GUARD_GAUGE_REGEN_AMOUNT = 10 # exact GG regened per frame when GG < 100%
const GUARD_GAUGE_DEGEN_AMOUNT = 90 # exact GG degened per frame when GG > 100%
const BASE_BLOCK_CHIP_DAMAGE_MOD = 35 # % of damage taken as chip damage when blocking (average is 0.25)
#const GUARD_GAUGE_GAIN_MOD = 0.8 # modify Guard Gain when being comboed, tankier characters have higher GUARD_GAUGE_GAIN_MOD
#const GUARD_GAUGE_LOSS_MOD = 1.2 # modify Guard Loss, tankier characters have lower GUARD_GAUGE_LOSS_MOD
const AIR_BLOCK_GG_COST = -2000 # Guard Gauge drain when starting an Air Block
const TRAITS = [Globals.trait.CHAIN_DASH, Globals.trait.VULN_GRD_DASH, Globals.trait.VULN_AIR_DASH]

const SDHitspark_COLOR = "blue"

const PALETTE_TO_PORTRAIT = {
	1: Color(0.75, 0.93, 1.25),
	2: Color(1.20, 0.70, 0.70),
}

const UNIQUE_DATA_REF = {
	"groundfin_count" : 0,
	"groundfin_trigger" : false,
	"nibbler_count" : 0,
	"nibbler_cancel" : 0, # a timer, if 0 will not cancel, cannot use bool since it is set during detect_hit() and need to last 2 turns
}

const STARTERS = ["L1", "L2", "F1", "F2", "F3", "H", "aL1", "aL2", "aF1", "aF3", "aH", "SP1", "SP1[ex]", "aSP1", "aSP1[ex]", \
		"aSP2", "aSP2[ex]", "SP3", "aSP3", "SP3[ex]", "aSP3[ex]", "SP4", "SP4[ex]", "SP5", "aSP5", "SP5[ex]", "aSP5[ex]", "SP6[ex]", "aSP6[ex]"]
const SPECIALS = ["SP1", "aSP1", "aSP2", "SP3", "aSP3", "SP4", "SP5", "aSP5"]
const EX_MOVES = ["SP1[ex]", "aSP1[ex]", "aSP2[ex]", "SP3[ex]", "aSP3[ex]", "SP4[ex]", "SP5[ex]", "aSP5[ex]", "SP6[ex]", "aSP6[ex]"]
const SUPERS = []

const UP_TILTS = ["F3", "SP3", "SP3[ex]", "aF3", "aSP3", "aSP3[ex]"] # to know which moves can be cancelled from jumpsquat

# list of movenames that will emit EX flash
const EX_FLASH_ANIM = ["SP1[ex]", "aSP1[ex]", "aSP2[ex]", "SP3[ex]", "aSP3[ex]", "aSP3b[ex]", "SP4[ex]", "SP5[ex]", "aSP5[ex]", \
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
		"knockback" : 0,
		"knockback_type": Globals.knockback_type.FIXED, # for radial, +ve KB_angle means rotating clockwise, -ve is counterclockwise
		"atk_level" : 2,
		"fixed_hitstop" : 1,
		"priority": 2,
		"guard_drain": 1500,
		"guard_gain_on_combo" : 2500,
		"EX_gain": 600,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : -36,
		"impulse_mod" : 50,
		"atk_attr" : [Globals.atk_attr.AUTOCHAIN],
		"move_sound" : { ref = "whoosh2", aux_data = {"vol" : -12} },
		"hit_sound" : { ref = "cut1", aux_data = {"vol" : -15} },
	},
	"L1b" : {
		"atk_type" : Globals.atk_type.LIGHT,
		"chain_starter" : "L1",
		"hitcount" : 1,
		"damage" : 20,
		"knockback" : 200 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED, # for radial, +ve KB_angle means rotating clockwise, -ve is counterclockwise
		"atk_level" : 2,
		"priority": 2,
		"EX_gain": 600,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : -36,
		"atk_attr" : [Globals.atk_attr.NO_IMPULSE],
		"move_sound" : { ref = "whoosh2", aux_data = {"vol" : -12} },
		"hit_sound" : { ref = "cut1", aux_data = {"vol" : -15} },
	},
	"L2" : {
		"atk_type" : Globals.atk_type.LIGHT,
		"hitcount" : 1,
		"damage" : 30,
		"knockback" : 180 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED, # for radial, +ve KB_angle means rotating clockwise, -ve is counterclockwise
		"atk_level" : 3,
		"priority": 2,
		"guard_drain": 1000,
		"guard_gain_on_combo" : 2500,
		"EX_gain": 1500,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : -36,
		"atk_attr" : [Globals.atk_attr.LEDGE_DROP, Globals.atk_attr.NO_IMPULSE],
		"move_sound" : { ref = "whoosh14", aux_data = {"vol" : -9, "bus" : "PitchDown"} },
		"hit_sound" : { ref = "impact11", aux_data = {"vol" : -10} },
	},
	"F1" : {
		"atk_type" : Globals.atk_type.FIERCE, # light/fierce/heavy/special/ex/super
		"hitcount" : 1,
		"damage" : 60, # chip damage is a certain % of damage, Chipper Attribute can increase chip
		"knockback" : 350 * FMath.S,  # knockback strength, block pushback (% of knockback strength), affect hitspark size and hitstop
		"knockback_type": Globals.knockback_type.MIRRORED,
		"atk_level" : 4, # 1~8, affect hitstun and blockstun
		"priority": 4, # aL < L < aF < F < aH < H < Specials (depend on move) < EX (depend on move), Super, but some moves are different
		"guard_drain": 1500, # on blocking opponent and opponent in neutral (multiplied), affect how well the move can guardcrush/break
		# Supers have 0 Guard Drain
		"guard_gain_on_combo" : 2500, # affect comboability
		"EX_gain": 2000, # EX Gain on block is a certain % of EX Gain on hit, defenders blocking this attack will gain a certain % as well
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
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
		"damage" : 70,
		"knockback" : 400 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED,
		"atk_level" : 4,
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
		"knockback" : 400 * FMath.S,
		"knockback_type": Globals.knockback_type.RADIAL,
		"atk_level" : 4,
		"fixed_blockstun" : 5,
		"priority": 4,
		"guard_drain": 1500,
		"guard_gain_on_combo" : 2500,
		"EX_gain": 2000,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : 90,
		"atk_attr" : [Globals.atk_attr.ANTI_AIR, Globals.atk_attr.NO_CHAIN_ON_BLOCK],
		"move_sound" : { ref = "whoosh7", aux_data = {"vol" : -12,} },
		"hit_sound" : { ref = "impact19", aux_data = {"vol" : -18} },
	},
	"H" : {
		"atk_type" : Globals.atk_type.HEAVY,
		"hitcount" : 1,
		"damage" : 40,
		"knockback" : 150 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED,
		"atk_level" : 2,
		"priority": 5,
		"guard_drain": 2000,
		"guard_gain_on_combo" : 3500,
		"EX_gain": 1000,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : -75,
		"atk_attr" : [Globals.atk_attr.AUTOCHAIN, Globals.atk_attr.ANTI_GUARD, Globals.atk_attr.NO_CHAIN],
		"move_sound" : [{ ref = "water8", aux_data = {"vol" : -13,} }, { ref = "water5", aux_data = {"vol" : -20} }],
		"hit_sound" : { ref = "water7", aux_data = {"vol" : -9} },
	},
	"Hb" : {
		"atk_type" : Globals.atk_type.HEAVY,
		"chain_starter" : "H",
		"hitcount" : 1,
		"damage" : 70,
		"knockback" : 550 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED,
		"atk_level" : 6,
		"priority": 5,
		"EX_gain": 1500,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : -75,
		"atk_attr" : [Globals.atk_attr.JUMP_CANCEL, Globals.atk_attr.ANTI_GUARD, Globals.atk_attr.NO_IMPULSE],
		"hit_sound" : { ref = "water7", aux_data = {"vol" : -7} },
	},
	"H[h]" : {
		"atk_type" : Globals.atk_type.HEAVY,
		"root" : "H",
		"hitcount" : 1,
		"damage" : 40,
		"knockback" : 150 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED,
		"atk_level" : 2,
		"priority": 5,
		"guard_drain": 2000,
		"guard_gain_on_combo" : 3500,
		"EX_gain": 1000,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : -75,
		"atk_attr" : [Globals.atk_attr.AUTOCHAIN, Globals.atk_attr.ANTI_GUARD, Globals.atk_attr.NO_CHAIN],
		"move_sound" : [{ ref = "water8", aux_data = {"vol" : -13,} }, { ref = "water5", aux_data = {"vol" : -20} }],
		"hit_sound" : { ref = "water7", aux_data = {"vol" : -9} },
	},
	"Hb[h]" : {
		"atk_type" : Globals.atk_type.HEAVY,
		"root" : "Hb",
		"chain_starter" : "H[h]",
		"hitcount" : 1,
		"damage" : 70,
		"knockback" : 550 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED,
		"atk_level" : 6,
		"priority": 5,
		"EX_gain": 1500,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : -75,
		"atk_attr" : [Globals.atk_attr.JUMP_CANCEL, Globals.atk_attr.ANTI_GUARD, Globals.atk_attr.NO_IMPULSE],
		"hit_sound" : { ref = "water7", aux_data = {"vol" : -7} },
	},
	"aL1" : {
		"atk_type" : Globals.atk_type.LIGHT,
		"hitcount" : 1,
		"damage" : 35,
		"knockback" : 200 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED, # for radial, +ve KB_angle means rotating clockwise, -ve is counterclockwise
		"atk_level" : 2,
		"priority": 1,
		"guard_drain": 1000,
		"guard_gain_on_combo" : 2000,
		"EX_gain": 1600,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : 72,
		"atk_attr" : [Globals.atk_attr.AIR_ATTACK],
		"move_sound" : { ref = "whoosh3", aux_data = {"vol" : -12} },
		"hit_sound" : { ref = "impact14", aux_data = {"vol" : -15} },
	},
	"aL2" : {
		"atk_type" : Globals.atk_type.LIGHT,
		"hitcount" : 1,
		"damage" : 30,
		"knockback" : 200 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED,
		"atk_level" : 2,
		"priority": 1,
		"guard_drain": 750,
		"guard_gain_on_combo" : 1500,
		"EX_gain": 1000,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : 90,
		"atk_attr" : [Globals.atk_attr.AIR_ATTACK, Globals.atk_attr.NO_JUMP_CANCEL],
		"move_sound" : { ref = "whoosh15", aux_data = {"vol" : -9} },
		"hit_sound" : { ref = "cut8", aux_data = {"vol" : -10} },
	},
	"aF1" : {
		"atk_type" : Globals.atk_type.FIERCE,
		"hitcount" : 1,
		"damage" : 60,
		"knockback" : 350 * FMath.S,
		"knockback_type": Globals.knockback_type.RADIAL, # for radial, +ve KB_angle means rotating clockwise, -ve is counterclockwise
		"atk_level" : 3,
		"priority": 3,
		"guard_drain": 1500,
		"guard_gain_on_combo" : 2500,
		"EX_gain": 2000,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : 72,
		"atk_attr" : [Globals.atk_attr.AIR_ATTACK],
		"move_sound" : { ref = "whoosh14", aux_data = {"vol" : -9, "bus": "PitchDown"} },
		"hit_sound" : { ref = "impact12", aux_data = {"vol" : -15} },
	},
	"aF3" : {
		"atk_type" : Globals.atk_type.FIERCE,
		"hitcount" : 1,
		"damage" : 60,
		"knockback" : 350 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED,
		"atk_level" : 4,
		"priority": 3,
		"guard_drain": 1500,
		"guard_gain_on_combo" : 2500,
		"EX_gain": 2000,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : -72,
		"atk_attr" : [Globals.atk_attr.AIR_ATTACK, Globals.atk_attr.ANTI_AIR],
		"move_sound" : { ref = "whoosh12", aux_data = {"vol" : -2} },
		"hit_sound" : { ref = "cut5", aux_data = {"vol" : -10} },
	},
	"aH" : {
		"atk_type" : Globals.atk_type.HEAVY,
		"hitcount" : 1,
		"damage" : 100,
		"knockback" : 475 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED,
		"atk_level" : 4,
		"priority": 5,
		"guard_drain": 2000,
		"guard_gain_on_combo" : 3500,
		"EX_gain": 2500,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : 45,
		"atk_attr" : [Globals.atk_attr.AIR_ATTACK, Globals.atk_attr.ANTI_GUARD],
		"move_sound" : { ref = "water4", aux_data = {"vol" : -12,} },
		"hit_sound" : { ref = "water5", aux_data = {"vol" : -18} },
	},
	
	"SP1": {
		"atk_type" : Globals.atk_type.SPECIAL, # used for chaining
		"priority": 0,
		"atk_attr" : [Globals.atk_attr.NON_ATTACK], # some projectile moves can have attributes like superarmor
	},
	"aSP1": {
		"atk_type" : Globals.atk_type.SPECIAL,
		"priority": 0,
		"atk_attr" : [Globals.atk_attr.NON_ATTACK],
	},
	"SP1[c1]": {
		"atk_type" : Globals.atk_type.SPECIAL, # needed to check atk_type for Burst Revoke
		"root" : "SP1", # needed for aerial memory
		"move_sound" : { ref = "whoosh12", aux_data = {"vol" : -2} },
	},
	"SP1[c2]": {
		"atk_type" : Globals.atk_type.SPECIAL,
		"root" : "SP1",
		"move_sound" : { ref = "whoosh12", aux_data = {} },
	},
	"SP1[c3]": {
		"atk_type" : Globals.atk_type.SPECIAL,
		"root" : "SP1",
		"move_sound" : [{ ref = "water4", aux_data = {"vol" : -20,} }, { ref = "whoosh12", aux_data = {} }],
	},
	"aSP1[c1]": {
		"atk_type" : Globals.atk_type.SPECIAL,
		"root" : "aSP1",
		"move_sound" : { ref = "whoosh12", aux_data = {"vol" : -2} },
	},
	"aSP1[c2]": {
		"atk_type" : Globals.atk_type.SPECIAL,
		"root" : "aSP1",
		"move_sound" : { ref = "whoosh12", aux_data = {} },
	},
	"aSP1[c3]": {
		"atk_type" : Globals.atk_type.SPECIAL,
		"root" : "aSP1",
		"move_sound" : [{ ref = "water4", aux_data = {"vol" : -20,} }, { ref = "whoosh12", aux_data = {} }],
	},
	"SP1[ex]": {
		"atk_type" : Globals.atk_type.EX,
		"priority": 0,
		"move_sound" : [{ ref = "water4", aux_data = {"vol" : -20,} }, { ref = "whoosh12", aux_data = {} }],
		"atk_attr" : [Globals.atk_attr.NON_ATTACK], # some projectile moves can have attributes like superarmor
	},
	"aSP1[ex]": {
		"atk_type" : Globals.atk_type.EX,
		"priority": 0,
		"move_sound" : [{ ref = "water4", aux_data = {"vol" : -20,} }, { ref = "whoosh12", aux_data = {} }],
		"atk_attr" : [Globals.atk_attr.NON_ATTACK],
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
		"fixed_blockstun" : 5,
		"priority": 7,
		"guard_drain": 1500,
		"guard_gain_on_combo" : 2500,
		"EX_gain": 1000,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : -45,
		"atk_attr" : [Globals.atk_attr.NO_PUSHBACK, Globals.atk_attr.NO_STRAFE, Globals.atk_attr.AIR_ATTACK],
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
		"fixed_blockstun" : 5,
		"priority": 7,
		"guard_drain": 1500,
		"guard_gain_on_combo" : 2500,
		"EX_gain": 2500,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : -90,
		"atk_attr" : [Globals.atk_attr.NO_PUSHBACK, Globals.atk_attr.NO_STRAFE, Globals.atk_attr.AIR_ATTACK],
		"move_sound" : [{ ref = "water4", aux_data = {"vol" : -15,} }, { ref = "blast3", aux_data = {"vol" : -10, "bus" : "LowPass"} }],
		"hit_sound" : [{ ref = "impact11", aux_data = {"vol" : -20} }, { ref = "water1", aux_data = {"vol" : -8} }],
	},
	"aSP2[ex]" : {
		"atk_type" : Globals.atk_type.EX,
		"hitcount" : 5,
		"ignore_time" : 5,
		"damage" : 40,
		"knockback" : 600 * FMath.S,
		"fixed_knockback_multi" : 300 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED,
		"atk_level" : 5,
		"fixed_blockstun" : 5,
		"priority": 10,
		"guard_drain": 2000,
		"guard_gain_on_combo" : 3500,
		"EX_gain": 0,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : -45,
		"atk_attr" : [Globals.atk_attr.NO_PUSHBACK, Globals.atk_attr.NO_STRAFE],
		"move_sound" : [{ ref = "water4", aux_data = {"vol" : -15,} }, { ref = "blast3", aux_data = {"vol" : -10, "bus" : "LowPass"} }],
		"hit_sound" : [{ ref = "impact11", aux_data = {"vol" : -20} }, { ref = "water1", aux_data = {"vol" : -8} }],
	},
	
	"aSP3" : {
		"atk_type" : Globals.atk_type.SPECIAL,
		"hitcount" : 1,
		"damage" : 40,
		"knockback" : 600 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED,
		"atk_level" : 2,
		"fixed_blockstun" : 5,
		"burstlock": 8,
		"priority": 8,
		"guard_drain": 2000,
		"guard_gain_on_combo" : 3500,
		"EX_gain": 1000,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : -90,
		"atk_attr" : [Globals.atk_attr.ANTI_AIR, Globals.atk_attr.AUTOCHAIN, Globals.atk_attr.NO_CHAIN, \
				Globals.atk_attr.NO_PUSHBACK],
		"move_sound" : { ref = "water8", aux_data = {"vol" : -10,} },
		"hit_sound" : { ref = "water7", aux_data = {"vol" : -9} },
	},
	"aSP3b" : {
		"atk_type" : Globals.atk_type.SPECIAL,
		"chain_starter" : "aSP3",
		"no_revoke_time" : 0, # time after which you cannot use burst revoke
		"hitcount" : 1,
		"damage" : 70,
		"knockback" : 475 * FMath.S,
		"knockback_type": Globals.knockback_type.RADIAL,
		"atk_level" : 5,
		"fixed_blockstun" : 5,
		"priority": 8,
		"EX_gain": 1500,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : 0,
		"atk_attr" : [Globals.atk_attr.ANTI_AIR, Globals.atk_attr.NO_PUSHBACK],
		"hit_sound" : { ref = "water7", aux_data = {"vol" : -7} },
	},
	"aSP3[h]" : {
		"atk_type" : Globals.atk_type.SPECIAL,
		"root" : "aSP3",
		"hitcount" : 1,
		"damage" : 40,
		"knockback" : 650 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED,
		"atk_level" : 2,
		"fixed_blockstun" : 5,
		"burstlock": 8,
		"priority": 8,
		"guard_drain": 2000,
		"guard_gain_on_combo" : 3500,
		"EX_gain": 1000,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : -90,
		"atk_attr" : [Globals.atk_attr.ANTI_AIR, Globals.atk_attr.AUTOCHAIN, Globals.atk_attr.NO_CHAIN, \
				Globals.atk_attr.NO_PUSHBACK],
		"move_sound" : { ref = "water8", aux_data = {"vol" : -10,} },
		"hit_sound" : { ref = "water7", aux_data = {"vol" : -9} },
	},
	"aSP3b[h]" : {
		"atk_type" : Globals.atk_type.SPECIAL,
		"root" : "aSP3b",
		"chain_starter" : "aSP3[h]",
		"no_revoke_time" : 0, 
		"hitcount" : 1,
		"damage" : 70,
		"knockback" : 500 * FMath.S,
		"knockback_type": Globals.knockback_type.RADIAL,
		"atk_level" : 5,
		"fixed_blockstun" : 5,
		"priority": 8,
		"EX_gain": 1500,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : 0,
		"atk_attr" : [Globals.atk_attr.ANTI_AIR, Globals.atk_attr.NO_PUSHBACK],
		"hit_sound" : { ref = "water7", aux_data = {"vol" : -7} },
	},
	"aSP3[ex]" : {
		"atk_type" : Globals.atk_type.EX,
		"hitcount" : 1,
		"damage" : 60,
		"knockback" : 650 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED,
		"atk_level" : 2,
		"fixed_blockstun" : 5,
		"burstlock": 8,
		"priority": 11,
		"guard_drain": 2500,
		"guard_gain_on_combo" : 3500,
		"EX_gain": 0,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : -90,
		"atk_attr" : [Globals.atk_attr.ANTI_AIR, Globals.atk_attr.AUTOCHAIN, Globals.atk_attr.NO_CHAIN, \
				Globals.atk_attr.NO_PUSHBACK, Globals.atk_attr.SEMI_INVUL_STARTUP],
		"move_sound" : { ref = "water8", aux_data = {"vol" : -10,} },
		"hit_sound" : { ref = "water7", aux_data = {"vol" : -9} },
	},
	"aSP3b[ex]" : {
		"atk_type" : Globals.atk_type.EX,
		"chain_starter" : "aSP3[ex]",
		"hitcount" : 1,
		"damage" : 120,
		"knockback" : 525 * FMath.S,
		"knockback_type": Globals.knockback_type.RADIAL,
		"atk_level" : 6,
		"fixed_blockstun" : 5,
		"priority": 11,
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
		"atk_attr" : [Globals.atk_attr.NON_ATTACK],
		"move_sound" : [{ ref = "water4", aux_data = {"vol" : -16,} }, { ref = "blast4", aux_data = {"vol" : -16,} }],
	},
	"SP4[h]": {
		"atk_type" : Globals.atk_type.SPECIAL,
		"priority": 0,
		"atk_attr" : [Globals.atk_attr.NON_ATTACK],
		"move_sound" : [{ ref = "water4", aux_data = {"vol" : -16,} }, { ref = "blast4", aux_data = {"vol" : -16,} }],
	},
	"SP4[ex]": {
		"atk_type" : Globals.atk_type.EX,
		"priority": 0,
		"atk_attr" : [Globals.atk_attr.NON_ATTACK],
		"move_sound" : [{ ref = "water4", aux_data = {"vol" : -16,} }, { ref = "blast4", aux_data = {"vol" : -16,} }],
	},
	
	"aSP5" : {
		"atk_type" : Globals.atk_type.SPECIAL,
		"quick_turn_limit" : 4, # if on ground, can only quick turn on the first X frames
		"hitcount" : 1,
		"damage" : 100,
		"knockback" : 475 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED,
		"atk_level" : 4,
		"fixed_blockstun" : 19,
		"priority": 8,
		"guard_drain": 2000,
		"guard_gain_on_combo" : 3500,
		"EX_gain": 2500,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "red",
		"KB_angle" : -45,
		"atk_attr" : [Globals.atk_attr.QUICK_TURN_LIMIT],
		"move_sound" : [{ ref = "launch2", aux_data = {"vol" : -5,} }, { ref = "impact33", aux_data = {"vol" : -23,} }],
		"hit_sound" : { ref = "cut5", aux_data = {"vol" : -7} },
	},
	"aSP5[ex]" : {
		"atk_type" : Globals.atk_type.EX,
		"quick_turn_limit" : 4, # if on ground, can only quick turn on the first X frames
		"hitcount" : 1,
		"damage" : 150,
		"knockback" : 500 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED,
		"atk_level" : 5,
		"fixed_blockstun" : 25,
		"priority": 11,
		"guard_drain": 2500,
		"guard_gain_on_combo" : 3500,
		"EX_gain": 0,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "red",
		"KB_angle" : -45,
		"atk_attr" : [Globals.atk_attr.QUICK_TURN_LIMIT],
		"move_sound" : [{ ref = "launch2", aux_data = {"vol" : -5,} }, { ref = "impact33", aux_data = {"vol" : -23,} }],
		"hit_sound" : { ref = "cut5", aux_data = {"vol" : -7} },
	},
	
	"aSP6[ex]" : {
		"atk_type" : Globals.atk_type.EX,
		"sequence": "SP6[ex]SeqA",
		"hitcount" : 1,
		"priority": 11,
		"hitspark_type" : Globals.hitspark_type.NONE,
		"atk_attr" : [Globals.atk_attr.UNBLOCKABLE, Globals.atk_attr.NO_IMPULSE, Globals.atk_attr.CANNOT_CHAIN_INTO, \
				Globals.atk_attr.NOT_FROM_C_REC, Globals.atk_attr.COMMAND_GRAB]
	},
	
	"SP6[ex]SeqE": {
		"sequence_hits" : [{"damage":200, "hitstop": 15}], # for hits during sequence, has a key, only contain damage
		"sequence_launch" : { # for final hit of sequence
			"damage" : 0,
			"hitstop" : 0,
			"guard_gain" : 3500,
			"EX_gain": 0,
			"launch_power" : 700 * FMath.S,
			"launch_angle" : -103, # launch backwards
			"atk_level" : 6,
		}
	},
	"aSP6[ex]SeqE": { # if Grabbed hit a ledge while Grabber doesn't
		"sequence_hits" : [{"damage":200, "hitstop": 15}],
		"sequence_launch" : {
			"damage" : 0,
			"hitstop" : 0,
			"guard_gain" : 3500,
			"EX_gain": 0,
			"launch_power" : 700 * FMath.S,
			"launch_angle" : -103,
			"atk_level" : 6,
		}
	},

}



