extends Node2D

# CHARACTER DATA --------------------------------------------------------------------------------------------------
# may be saved in a .tres file later? Or just leave it in the .gd file

const NAME = "Gura"

# character movement stats, use to overwrite
const SPEED = 325.0 # ground speed
const AIR_STRAFE_SPEED = 30
const AIR_STRAFE_LIMIT = 0.8 # speed limit of air strafing, limit depends on ground speed
const JUMP_SPEED = 600.0
const AIR_JUMP_MOD = 0.9 # reduce height of air jumps
const GRAVITY_MOD = 1.0 # make sure variable's a float
const TERMINAL_VELOCITY_MOD = 8.25 # affect terminal velocity downward
const FRICTION = 0.15 # between 0.0 and 1.0
const ACCELERATION = 0.15 # between 0.0 and 1.0
const AIR_RESISTANCE = 0.03 # between 0.0 and 1.0
const FALL_GRAV_MOD = 1.0 # reduced gravity when going down
const MAX_AIR_JUMP = 1
const MAX_AIR_DASH = 2
const GROUND_DASH_SPEED = 425.0 # duration in animation data
const AIR_DASH_SPEED = 375.0 # duration in animation data

const DAMAGE_VALUE_LIMIT = 950.0
const GUARD_GAUGE_FLOOR = -8000.0
const GUARD_GAUGE_CEIL = 6000.0
const GUARD_GAUGE_REGEN_RATE = 0.05 # % of GG regened per second when GG < 100%
const GUARD_GAUGE_DEGEN_RATE = -0.5 # % of GG degened per second when GG > 100%
#const EX_GAUGE_LIMIT = 400.0 # each bar is 100 units
const KB_MOD = 1.2 # light character take more knockback?
const CHIP_DMG_MOD = 1.3 # take extra chip damage on block
const GUARD_GAUGE_GAIN_MOD = 0.8 # modify Guard Gain when being comboed
const TRAITS = [Globals.trait.CROUCH_CANCEL, Globals.trait.VULN_GRD_DASH, Globals.trait.VULN_AIR_DASH]

const SDHitspark_COLOR = "blue"

const PALETTE_TO_PORTRAIT = {
	1: Color(0.75, 0.93, 1.25),
	2: Color(1.20, 0.70, 0.70),
}

# const DIRECTORY_NAME = "res://Characters/Gura/"

# this contain move_data for each active animation this character has
# use trim_suffix("Active") on animation name to find move in the database
const MOVE_DATABASE = {
	"L1" : {
		"atk_type" : Globals.atk_type.LIGHT,
		"hitcount" : 1,
		"damage" : 30,
		"knockback" : 0,
		"knockback_type": Globals.knockback_type.FIXED, # for radial, +ve KB_angle means rotating clockwise, -ve is counterclockwise
		"attack_level" : 3,
		"fixed_hitstop" : 0,
		"priority": 2,
		"guard_drain": 2000,
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
		"root" : "L1", # for chain combo checking
		"hitcount" : 1,
		"damage" : 30,
		"knockback" : 200,
		"knockback_type": Globals.knockback_type.FIXED, # for radial, +ve KB_angle means rotating clockwise, -ve is counterclockwise
		"attack_level" : 3,
		"priority": 2,
		"guard_drain": 0,
		"guard_gain_on_combo" : 0,
		"EX_gain": 600,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : -PI/5,
		"atk_attr" : [],
		"move_sound" : { ref = "whoosh2", aux_data = {"vol" : -12} },
		"hit_sound" : { ref = "cut1", aux_data = {"vol" : -15} },
	},
	"L2" : {
		"atk_type" : Globals.atk_type.LIGHT,
		"hitcount" : 1,
		"damage" : 40,
		"knockback" : 180,
		"knockback_type": Globals.knockback_type.FIXED, # for radial, +ve KB_angle means rotating clockwise, -ve is counterclockwise
		"attack_level" : 4,
		"priority": 2,
		"guard_drain": 1500,
		"guard_gain_on_combo" : 2500,
		"EX_gain": 1500,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : -PI/5,
		"atk_attr" : [Globals.atk_attr.AIR_ATTACK, Globals.atk_attr.LEDGE_DROP, Globals.atk_attr.NO_CHAIN_ON_BLOCK],
		"move_sound" : { ref = "whoosh14", aux_data = {"vol" : -9, "bus" : "PitchDown"} },
		"hit_sound" : { ref = "impact11", aux_data = {"vol" : -10} },
	},
	"F1" : {
		"atk_type" : Globals.atk_type.FIERCE, # light/fierce/heavy/special/ex/super
		"hitcount" : 1,
		"damage" : 90, # chip damage is a certain % of damage, Chipper Attribute can increase chip
		"knockback" : 350,  # knockback strength, block pushback (% of knockback strength), affect hitspark size and hitstop
		"knockback_type": Globals.knockback_type.MIRRORED,
		"attack_level" : 4, # 1~8, affect hitstun and blockstun
		"priority": 4, # aL < L < aF < F < aH < H < Specials (depend on move) < EX (depend on move), Super, but some moves are different
		"guard_drain": 2000, # on blocking opponent and opponent in neutral (multiplied), affect how well the move can guardcrush/break
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
		"damage" : 100,
		"knockback" : 400,
		"knockback_type": Globals.knockback_type.FIXED,
		"attack_level" : 4,
		"priority": 4,
		"guard_drain": 2000,
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
		"damage" : 100,
		"knockback" : 350,
		"knockback_type": Globals.knockback_type.RADIAL,
		"attack_level" : 4,
		"fixed_blockstun" : 5,
		"priority": 4,
		"guard_drain": 2000,
		"guard_gain_on_combo" : 2500,
		"EX_gain": 2000,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : PI/2,
		"atk_attr" : [Globals.atk_attr.ANTIAIR, Globals.atk_attr.NO_CHAIN_ON_BLOCK],
		"move_sound" : { ref = "whoosh7", aux_data = {"vol" : -12,} },
		"hit_sound" : { ref = "impact19", aux_data = {"vol" : -18} },
	},
	"H" : {
		"atk_type" : Globals.atk_type.HEAVY,
		"hitcount" : 1,
		"damage" : 80,
		"knockback" : 400,
		"knockback_type": Globals.knockback_type.FIXED,
		"attack_level" : 3,
		"priority": 5,
		"guard_drain": 3000,
		"guard_gain_on_combo" : 3500,
		"EX_gain": 1000,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : -PI/2.4,
		"atk_attr" : [Globals.atk_attr.AUTOCHAIN, Globals.atk_attr.HARD_TO_BLOCK, Globals.atk_attr.NO_CHAIN],
		"move_sound" : { ref = "water8", aux_data = {"vol" : -10,} },
		"hit_sound" : { ref = "water7", aux_data = {"vol" : -9} },
	},
	"Hb" : {
		"atk_type" : Globals.atk_type.HEAVY,
		"hitcount" : 1,
		"damage" : 100,
		"knockback" : 500,
		"knockback_type": Globals.knockback_type.FIXED,
		"attack_level" : 6,
		"priority": 5,
		"guard_drain": 0,
		"guard_gain_on_combo" : 0,
		"EX_gain": 1500,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : -PI/2.4,
		"atk_attr" : [Globals.atk_attr.JUMP_CANCEL, Globals.atk_attr.HARD_TO_BLOCK],
		"hit_sound" : { ref = "water7", aux_data = {"vol" : -7} },
	},
	"aL1" : {
		"atk_type" : Globals.atk_type.LIGHT,
		"hitcount" : 1,
		"damage" : 50,
		"knockback" : 200,
		"knockback_type": Globals.knockback_type.FIXED, # for radial, +ve KB_angle means rotating clockwise, -ve is counterclockwise
		"attack_level" : 3,
		"priority": 1,
		"guard_drain": 1500,
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
		"damage" : 40,
		"knockback" : 200,
		"knockback_type": Globals.knockback_type.FIXED,
		"attack_level" : 3,
		"priority": 1,
		"guard_drain": 1000,
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
		"damage" : 90,
		"knockback" : 350,
		"knockback_type": Globals.knockback_type.RADIAL, # for radial, +ve KB_angle means rotating clockwise, -ve is counterclockwise
		"attack_level" : 5,
		"priority": 3,
		"guard_drain": 2000,
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
		"damage" : 90,
		"knockback" : 350,
		"knockback_type": Globals.knockback_type.FIXED,
		"attack_level" : 5,
		"priority": 3,
		"guard_drain": 2000,
		"guard_gain_on_combo" : 2500,
		"EX_gain": 2000,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : -PI/2.5,
		"atk_attr" : [Globals.atk_attr.AIR_ATTACK, Globals.atk_attr.ANTIAIR],
		"move_sound" : { ref = "whoosh12", aux_data = {"vol" : -2} },
		"hit_sound" : { ref = "cut5", aux_data = {"vol" : -10} },
	},
	"aH" : {
		"atk_type" : Globals.atk_type.HEAVY,
		"hitcount" : 1,
		"damage" : 150,
		"knockback" : 450,
		"knockback_type": Globals.knockback_type.FIXED,
		"attack_level" : 6,
		"priority": 5,
		"guard_drain": 3000,
		"guard_gain_on_combo" : 3500,
		"EX_gain": 2500,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : PI/4,
		"atk_attr" : [Globals.atk_attr.AIR_ATTACK, Globals.atk_attr.HARD_TO_BLOCK],
		"move_sound" : { ref = "water4", aux_data = {"vol" : -12,} },
		"hit_sound" : { ref = "water5", aux_data = {"vol" : -18} },
	},
}
