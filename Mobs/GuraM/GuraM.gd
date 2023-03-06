extends Node2D

# Steps to add an attack:
# 1. Add it in MOVE_DATABASE and STARTERS
# 2. Add it in state_detect()
# 3. Add it in _on_SpritePlayer_anim_finished() to set the transitions
# 4. Add it in _on_SpritePlayer_anim_started() to set up entity/sfx spawning and other physics modifying Characteristics
# 5. Set up COMMANDS for it
# 6. Set up the commands in ATK_LOOKUP in the correct attack ranges and mob_rank
	
# Steps to add auto-sequences:
# 1. Add final Sequence Steps and steps with damage into MOVE_DATABASE
# 2. Add Sequence Steps and GrabRec animations into state_detect()
# 3. Add Sequence Steps in _on_SpritePlayer_anim_finished() to set the transitions, place "end_sequence_step()" in last/branching steps
# 4. Add Sequence Steps in _on_SpritePlayer_anim_started(), place "start_sequence_step()" on each step
# 5. Add initial actions for each Step in start_sequence_step()
# 6. Add frame-by-frame events and physics (gravity, air res) in simulate_sequence()
# 7. Add frame-by-frame movement for the opponent in simulate_sequence_after() as "move_sequence_target(grab_point)" and "rotate_partner(Partner)"
# 8. Add final Steps and branching Steps in end_sequence_step(), for final Step place in "Partner.sequence_launch()" there
# 9. Add GrabRec animations into refine_move_name()
# 10. For hitgrabs, add the conditions in UniqChar.landed_a_hit()
	
# --------------------------------------------------------------------------------------------------

# shortening code, set by main Character node
onready var Character = get_parent()
var Animator
var sprite
var uniqueHUD


const NAME = "Gura"

# Character movement stats, use to overwrite
const SPEED = 340 * FMath.S # ground speed
const AIR_STRAFE_SPEED_MOD = 10 # percent of ground speed
const AIR_STRAFE_LIMIT_MOD = 800 # speed limit of air strafing, limit depends on calculated air strafe speed
const GRAVITY_MOD = 100 # make sure variable's a float
const TERMINAL_VELOCITY_MOD = 800 # affect terminal velocity downward
const FRICTION = 15 # between 0.0 and 1.0
const ACCELERATION = 15 # between 0.0 and 1.0
const AIR_RESISTANCE = 3 # between 0.0 and 1.0
const FALL_GRAV_MOD = 100 # reduced gravity when going down
const EYE_LEVEL = 9 # number of pixels EX Flash appears above position

const KB_BOOST_AT_MAX_GG = 200 # max increase of knockback when Character's Guard Gauge is at 100%, light Characters have higher

const DAMAGE_VALUE_LIMIT = 700

const GUARD_DRAIN_MOD = 100
const GG_REGEN_AMOUNT = 5 # exact GG regened per frame when GG < 100%
const GUARD_GAUGE_SWELL_RATE = 50

const LONG_RANGE_PASSIVE_CHANCE = 70 # if passive, chance of idling instead when using a long range move
const LONG_FAIL_CHANCE = 20 # chance of ignoring long zones to get closer instead


const TRAITS = []

const DEFAULT_HITSPARK_TYPE = Globals.hitspark_type.HIT
const DEFAULT_HITSPARK_PALETTE = "gray"

const UNIQUE_DATA_REF = {
}

const STARTERS = ["L1", "L3", "F1", "F2", "F3", "H", "aL1", "aL3", "aF1", "aF2", "aF3", "aH", "SP1", "aSP1", \
	"aSP2", "SP3", "SP6[ex]"]
const NO_IMPULSE = ["SP1"]


const MOVE_DATABASE = {
	"L1" : {
		"atk_type" : Globals.atk_type.LIGHT,
		"hitcount" : 1,
		"damage" : 20,
		"knockback" : 200 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED,
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
		"knockback_type": Globals.knockback_type.FIXED,
		"atk_level" : 2,
		"KB_angle" : -36,
		"atk_attr" : [Globals.atk_attr.FOLLOW_UP],
		"move_sound" : { ref = "whoosh2", aux_data = {"vol" : -12} },
		"hit_sound" : { ref = "cut1", aux_data = {"vol" : -15} },
	},
	"L3" : {
		"atk_type" : Globals.atk_type.LIGHT,
		"hitcount" : 1,
		"damage" : 55,
		"knockback" : 445 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED,
		"atk_level" : 4,
		"priority_add" : 2,
		"KB_angle" : -80,
		"atk_attr" : [],
		"move_sound" : { ref = "whoosh9", aux_data = {"vol" : -18} },
		"hit_sound" : { ref = "cut5", aux_data = {"vol" : -10,} },
	},
	"F1" : {
		"atk_type" : Globals.atk_type.FIERCE,
		"hitcount" : 1,
		"damage" : 60,
		"knockback" : 350 * FMath.S,
		"knockback_type": Globals.knockback_type.MIRRORED,
		"atk_level" : 3,
		"KB_angle" : -36,
		"atk_attr" : [],
		"move_sound" : { ref = "whoosh13", aux_data = {"vol" : -12,} },
		"hit_sound" : { ref = "impact16", aux_data = {"vol" : -15} },
	},
	"F2" : {
		"atk_type" : Globals.atk_type.FIERCE,
		"hitcount" : 1,
		"damage" : 60,
		"knockback" : 400 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED,
		"atk_level" : 4,
		"priority_add" : -1,
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
		"KB_angle" : 90,
		"atk_attr" : [],
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
		"atk_attr" : [Globals.atk_attr.AUTOCHAIN],
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
		"atk_attr" : [Globals.atk_attr.FOLLOW_UP],
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
	"aL3" : {
		"atk_type" : Globals.atk_type.LIGHT,
		"hitcount" : 1,
		"damage" : 40,
		"knockback" : 400 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED,
		"atk_level" : 3,
		"priority_add": 1,
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
		"knockback_type": Globals.knockback_type.RADIAL,
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
		"atk_level" : 4,
		"fixed_ss_hitstop" : 12,
		"KB_angle" : 70,
		"atk_attr" : [],
		"move_sound" : { ref = "whoosh15", aux_data = {"vol" : -5, "bus": "PitchDown"} },
		"hit_sound" : { ref = "cut2", aux_data = {"vol" : -15} },
	},
	"aF2SeqB": {
		"starter" : "aF2",
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
		"priority_add" : 1,
		"KB_angle" : -72,
		"atk_attr" : [],
		"move_sound" : { ref = "whoosh12", aux_data = {"vol" : -2} },
		"hit_sound" : { ref = "cut5", aux_data = {"vol" : -10} },
	},
	"aH" : {
		"atk_type" : Globals.atk_type.HEAVY,
		"hitcount" : 1,
		"damage" : 90,
		"knockback" : 450 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED,
		"atk_level" : 5,
		"KB_angle" : 45,
		"atk_attr" : [],
		"move_sound" : { ref = "water4", aux_data = {"vol" : -12,} },
		"hit_sound" : { ref = "water5", aux_data = {"vol" : -18} },
	},
	"SP1": {
		"atk_type" : Globals.atk_type.SPECIAL, # used for chaining
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
		"reset_type" : Globals.reset_type.ACTIVE_RESET,
		"atk_attr" : [],
		"move_sound" : [{ ref = "water4", aux_data = {"vol" : -15,} }, { ref = "blast3", aux_data = {"vol" : -10, "bus" : "LowPass"} }],
		"hit_sound" : [{ ref = "impact11", aux_data = {"vol" : -20} }, { ref = "water1", aux_data = {"vol" : -8} }],
	},
	"SP3" : {
		"atk_type" : Globals.atk_type.SPECIAL,
		"hitcount" : 1,
		"damage" : 40,
		"knockback" : 600 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED,
		"atk_level" : 4,
		"KB_angle" : -90,
		"reset_type" : Globals.reset_type.EARLY_RESET,
		"atk_attr" : [Globals.atk_attr.AUTOCHAIN],
		"move_sound" : { ref = "water8", aux_data = {"vol" : -10,} },
		"hit_sound" : { ref = "water7", aux_data = {"vol" : -9} },
	},
	"SP3b" : {
		"atk_type" : Globals.atk_type.SPECIAL,
		"hitcount" : 1,
		"damage" : 70,
		"knockback" : 475 * FMath.S,
		"knockback_type": Globals.knockback_type.RADIAL,
		"atk_level" : 4,
		"KB_angle" : 0,
		"atk_attr" : [Globals.atk_attr.FOLLOW_UP],
		"hit_sound" : { ref = "water7", aux_data = {"vol" : -7} },
	},
	
	"aSP6[ex]" : {
		"atk_type" : Globals.atk_type.EX,
		"sequence": "SP6[ex]SeqA",
		"hitcount" : 1,
		"atk_attr" : []
	},
	
	"SP6[ex]SeqE": {
		"starter" : "aSP6[ex]",
		"sequence_hits" : [{"damage":150, "hitstop": 15}], # for hits during sequence, has a key, only contain damage
		"sequence_launch" : { # for final hit of sequence
			"damage" : 0,
			"hitstop" : 0,
			"launch_power" : 800 * FMath.S,
			"launch_angle" : -103, # launch backwards
			"atk_level" : 4,
		}
	},

}

const TRIGGERS = {
	
	"point_blank" : {"type" : "zone", "origin" : Vector2.ZERO, "size" : Vector2(100, 80), "decision" : "point_blank",},
	"close_range" : {"type" : "zone", "origin" : Vector2.ZERO, "size" : Vector2(180, 100), "decision" : "close_range",},
	"mid_range" : {"type" : "zone", "long" : true, "origin" : Vector2.ZERO, "size" : Vector2(270, 100), "decision" : "mid_range",},
	"anti_air_short" : {"type" : "zone", "origin" : Vector2(0, -50), "size" : Vector2(100, 100), "decision" : "anti_air_short",},
	"anti_air" : {"type" : "zone", "origin" : Vector2(0, -200), "size" : Vector2(150, 300), "decision" : "anti_air",},
	"anti_air_long" : {"type" : "zone", "long" : true, "origin" : Vector2(0, -75), "size" : Vector2(270, 100),"decision" : "anti_air_long",},
	
	"jump_peak" :{"type" : "peak", "decision" : "jump_peak",},
	"air_close" : {"type" : "zone", "origin" : Vector2.ZERO, "size" : Vector2(100, 100), "decision" : "air_close",},
	"air_high" : {"type" : "zone", "origin" : Vector2(0, -100), "size" : Vector2(100, 150), "low_height" : true, "decision" : "air_high",},
	"air_high_long" : {"type" : "zone", "long" : true, "origin" : Vector2(0, -75), "size" : Vector2(250, 100), "low_height" : true, "decision" : "air_high_long",},
	"air_low_short" : {"type" : "zone", "origin" : Vector2(0, 50), "size" : Vector2(100, 100), "downward" : true, "decision" : "air_low_short",},
	"air_low_long" : {"type" : "zone", "long" : true, "origin" : Vector2(0, 75), "size" : Vector2(250, 100), "downward" : true, "decision" : "air_low_long",},
	"air_low" : {"type" : "zone", "long" : true, "origin" : Vector2(0, 150), "size" : Vector2(150, 200), "decision" : "air_low",},
	"air_far" : {"type" : "zone", "origin" : Vector2.ZERO, "size" : Vector2(200, 100), "decision" : "air_far",},
	
}

const COMMANDS = {
	
		# STANCES ------------------------------------------------------------------------------------------------
	
		"idle": { # stand idle, attack if player is close
			"action": "idle",
			"rand_time" :[0, 30],
			"triggers" : [
				TRIGGERS.point_blank,
				TRIGGERS.anti_air_short,
				TRIGGERS.close_range,
				TRIGGERS.mid_range,
				TRIGGERS.anti_air,
				TRIGGERS.anti_air_long,
			]
		},
		"seek": { # run towards player, attack if player is close or cross above them
			"action": "run",
			"rand_time" :[0, 60],
			"triggers" : [
				TRIGGERS.point_blank,
				TRIGGERS.anti_air_short,
				TRIGGERS.close_range,
				TRIGGERS.mid_range,
				TRIGGERS.anti_air,
				TRIGGERS.anti_air_long,
			]
		},
		"option_close": { # special ground stance that last 1 frame on ground, attack if player is close
			"action": "option",
			"decision" : "offense",
			"triggers" : [
				TRIGGERS.point_blank,
				TRIGGERS.anti_air_short,
				TRIGGERS.close_range,
				TRIGGERS.mid_range,
				TRIGGERS.anti_air,
				TRIGGERS.anti_air_long,
			]
		},
		"option_air": { # special air stance that last till hit the ground, do air attacks if player is close
			"action": "option",
			"next" : "option_close",
			"triggers" : [
				TRIGGERS.jump_peak,
				TRIGGERS.air_close,
				TRIGGERS.air_high,
				TRIGGERS.air_high_long,
				TRIGGERS.air_low_short,
				TRIGGERS.air_low,
				TRIGGERS.air_low_long,
				TRIGGERS.air_far,
			]
		},
		"option_air_short": { # shorthop
			"action": "option",
			"next" : "option_close",
			"triggers" : [
				TRIGGERS.air_close,
				TRIGGERS.air_low_short,
			]
		},
		
		# MOVEMENT ------------------------------------------------------------------------------------------------
		
		"dash": {
			"action": "anim",
			"no_c_rec" : true, # cannot use from C_RECOVERY
			"anim" : "DashTransit",	
			"next" : "option_close"
		},
		"back_dash": {
			"action": "anim",
			"no_c_rec" : true,
			"dir": "retreat",
			"anim" : "DashTransit",	
#			"decision" : "retreat",
		},
		"dash_dance": {
			"action": "anim",
			"no_c_rec" : true,
			"dir": "retreat",
			"anim" : "DashTransit",	
			"style" : "dash_dance",
			"next" : "option_close"
#			"decision" : "retreat",
		},
		
		
		"air_dash": {
			"action": "anim",
			"no_c_rec" : true, # cannot use from C_RECOVERY
			"anim" : "aDashTransit",	
			"next" : "option_air",
		},
		"air_back_dash": {
			"action": "anim",
			"no_c_rec" : true, # cannot use from C_RECOVERY
			"anim" : "aDashTransit",	
			"next" : "option_air",
			"style" : "air_back_dash"
		},
		
		"forward_jump": {
			"action": "anim",
			"anim" : "JumpTransit",
			"style" : "forward_jump", # provide further instructions even after current_command has changed
			"next" : "option_air"
		},
		"back_jump": {
			"action": "anim",
			"anim" : "JumpTransit",
			"style" : "back_jump", # provide further instructions even after current_command has changed
			"next" : "option_air"
		},
		"neutral_jump": {
			"action": "anim",
			"anim" : "JumpTransit",
			"style" : "neutral_jump",
			"next" : "option_air"
		},
		"shorthop": {
			"action": "anim",
			"anim" : "JumpTransit",
			"style" : "shorthop",
			"next" : "option_air_short"
		},
		"cross_jump": {
			"action": "anim",
			"anim" : "JumpTransit",
			"style" : "cross_jump",
			"next" : "option_close"
		},
	
		# GROUND ATTACKS ------------------------------------------------------------------------------------------------
		
		"double_stab": {
			"action": "anim",
			"anim" : "L1Startup",
		},
		"double_stab_combo1": {
			"action": "anim",
			"anim" : ["L1Startup", "F1Startup"],
		},
		"double_stab_combo2": {
			"action": "anim",
			"anim" : ["L1Startup", "F1Startup", "F2Startup"],
		},
		
		"backswing": {
			"action": "anim",
			"anim" : "F1Startup",
		},
		"backswing_combo": {
			"action": "anim",
			"anim" : ["F1Startup", "F2Startup"],
		},
		
		"rush_upthrust": {
			"action": "anim",
			"anim" : "L3Startup",
		},
		"rush_upthrust_combo": {
			"action": "anim",
			"anim" : ["L3Startup", "F3Startup"],
		},
		
		"thrust": {
			"action": "anim",
			"anim" : "F2Startup",
		},
		"thrust_combo": {
			"action": "anim",
			"anim" : ["F2Startup", "SP1Startup"],
		},
		
		"overhead": {
			"action": "anim",
			"anim" : "F3Startup",
		},
		
		"sharkstomp": {
			"action": "anim",
			"anim" : "HStartup",
		},
		"sharkstomp_dash": {
			"action": "anim",
			"no_c_rec" : true,
			"anti_air_dash" : true,
			"anim" : ["DashTransit", "HStartup"],
		},
		
#		"sharkstomp_combo": {
#			"action": "anim",
#			"no_c_rec" : true,
#			"anim" : ["HStartup", "SP3Startup", "aSP1Startup"],
#		},
		
		"hammerhead": {
			"action": "anim",
			"anim" : "SP3Startup",
		},
		"hammerhead_combo": {
			"action": "anim",
			"anim" : ["SP3Startup", "aSP1Startup"],
		},
#		"hammerhead_dash":{
#			"action": "anim",
#			"no_c_rec" : true,
#			"anti_air_dash" : true,
#			"anim" : ["DashTransit", "SP3Startup"],
#		},
			
		"command_grab": {
			"action": "anim",
			"anim" : "SP6[ex]Startup",
		},
		
		# PROJECTILES ------------------------------------------------------------------------------------------------
		
		"throw_trident": {
			"action": "anim",
			"anim" : "SP1Startup",
		},
		"up_throw_trident": {
			"action": "anim",
			"anim" : "SP1Startup",
			"style": "up_trident",
		},
		"tri_throw_trident": {
			"action": "anim",
			"anim" : "SP1Startup",
			"style": "tri_throw_trident",
		},
		"up_tri_throw_trident": {
			"action": "anim",
			"anim" : "SP1Startup",
			"style": "up_tri_throw_trident",
		},
		
		# AIR ATTACKS ------------------------------------------------------------------------------------------------
		
		"air_tail": {
			"action": "anim",
			"anim" : "aL1Startup",
		},
		"air_uptail": {
			"action": "anim",
			"anim" : ["aL3Startup", "aL1Startup"],
		},
		"air_overhead": {
			"action": "anim",
			"anim" : "aF1Startup",
		},
		"air_shark": {
			"action": "anim",
			"anim" : "aHStartup",
		},
		"air_upthrust": {
			"action": "anim",
			"anim" : "aF3Startup",
		},
		"air_down_trident": {
			"action": "anim",
			"anim" : "aSP1Startup",
			"style": "down_trident",
		},
		"air_trident": {
			"action": "anim",
			"anim" : "aSP1Startup",
		},
		"air_surf": {
			"action": "anim",
			"anim" : "aSP2Startup",
		},
		"air_hitgrab": {
			"action": "anim",
			"anim" : "aF2Startup",
		}
		
	}
	
enum atk_range {POINTBLANK, CLOSE_RANGE, MID_RANGE, LONG_RANGE, ANTI_AIR_SHORT, ANTI_AIR, ANTI_AIR_LONG, 
		AIR_CLOSE, AIR_HIGH, AIR_HIGH_LONG, AIR_LOW_SHORT, AIR_LOW, AIR_LOW_LONG, AIR_FAR, AIR_LONG}
enum rank {LOW, MID, HIGH, SHARK, RUSH, ZONE}
	
const ATK_LOOKUP = {
	atk_range.POINTBLANK : {
		rank.LOW : ["double_stab"],
		rank.MID : ["double_stab_combo1", "hammerhead"],
		rank.HIGH : ["command_grab", "double_stab_combo2", "hammerhead_combo"],
		rank.RUSH : ["command_grab", "double_stab_combo2", "hammerhead"],
		rank.SHARK : ["hammerhead"],
		rank.ZONE : ["back_dash"]
	},
	atk_range.CLOSE_RANGE : {
		rank.LOW : ["double_stab", "backswing", "rush_upthrust"],
		rank.MID : ["dash_dance", "shorthop", "double_stab_combo1", "thrust", "backswing", "sharkstomp", "rush_upthrust", "overhead"],
		rank.HIGH : ["dash_dance", "dash_dance", "shorthop", "double_stab_combo2", "thrust_combo", "backswing_combo", "sharkstomp_combo", \
				"hammerhead_combo", "rush_upthrust_combo", "overhead"],
		rank.RUSH : ["dash_dance", "dash_dance", "shorthop", "double_stab_combo2", "thrust", "backswing_combo", "sharkstomp", \
				"rush_upthrust_combo", "hammerhead"],
		rank.SHARK : ["dash_dance", "shorthop", "sharkstomp", "hammerhead", "shorthop"],
		rank.ZONE : ["back_dash", "back_jump"]
	},
	atk_range.MID_RANGE : {
		rank.LOW : ["rush_upthrust", "thrust", "backswing", "dash"],
		rank.MID : ["shorthop", "thrust", "backswing_combo", "rush_upthrust_combo", "dash", "throw_trident"],
		rank.HIGH : ["shorthop", "shorthop", "sharkstomp_combo", "thrust_combo", "backswing_combo", "rush_upthrust_combo", \
				"throw_trident"],
		rank.SHARK : ["shorthop", "sharkstomp", "dash", "shorthop"],
		rank.RUSH : ["shorthop", "shorthop", "thrust", "backswing_combo", "rush_upthrust", "rush_upthrust_combo"],
		rank.ZONE : ["back_dash", "back_jump", "back_dash", "back_jump", "throw_trident"]
	},
	atk_range.LONG_RANGE : {
		rank.LOW : ["idle"],
		rank.MID : ["throw_trident"],
		rank.HIGH : ["throw_trident", "tri_throw_trident", "up_tri_throw_trident"],
		rank.SHARK : ["seek"],
		rank.RUSH : ["seek"],
		rank.ZONE : ["throw_trident", "throw_trident", "tri_throw_trident", "up_tri_throw_trident"],
	},
	atk_range.ANTI_AIR_SHORT: {
		rank.LOW : ["overhead"],
		rank.MID : ["overhead", "sharkstomp"],
		rank.HIGH : ["sharkstomp_combo", "overhead", "hammerhead_combo"],
		rank.RUSH : ["overhead", "sharkstomp", "hammerhead"],
		rank.SHARK : ["sharkstomp", "hammerhead"],
		rank.ZONE : ["back_dash", "up_throw_trident"]
	},
	atk_range.ANTI_AIR: {
		rank.LOW : ["neutral_jump"],
		rank.MID : ["neutral_jump", "hammerhead", "up_throw_trident"],
		rank.HIGH : ["neutral_jump", "hammerhead_combo", "up_throw_trident"],
		rank.SHARK : ["neutral_jump", "hammerhead"],
		rank.RUSH : ["neutral_jump"],
		rank.ZONE : ["up_throw_trident", "up_tri_throw_trident"]
	},
	atk_range.ANTI_AIR_LONG: {
		rank.LOW : ["forward_jump"],
		rank.MID : ["forward_jump", "dash", "up_throw_trident"],
		rank.HIGH : ["forward_jump", "dash", "dash", "up_throw_trident"],
		rank.SHARK : ["forward_jump", "dash", "dash"],
		rank.RUSH : ["forward_jump", "dash", "dash"],
		rank.ZONE : ["up_throw_trident", "up_tri_throw_trident"]
	},
	atk_range.AIR_CLOSE: {
		rank.LOW : ["air_tail"],
		rank.MID : ["air_uptail", "air_tail", "air_overhead"],
		rank.HIGH : ["air_uptail", "air_overhead", "air_shark"],
		rank.SHARK : ["air_shark"],
		rank.ZONE : ["air_back_dash", "air_trident"]
	},
	atk_range.AIR_HIGH: {
		rank.LOW : ["option_air"],
		rank.MID : ["air_upthrust"],
		rank.HIGH : ["air_upthrust"],
		rank.SHARK : ["options_air"],
		rank.ZONE : ["air_back_dash"]
	},
	atk_range.AIR_HIGH_LONG: {
		rank.LOW : ["option_air"],
		rank.MID : ["air_dash", "option_air", "air_surf"],
		rank.HIGH : ["air_dash", "air_surf"],
		rank.SHARK : ["air_dash"],
		rank.ZONE : ["option_air"]
	},
	atk_range.AIR_LOW_SHORT: {
		rank.LOW : ["air_tail"],
		rank.MID : ["air_hitgrab", "air_tail"],
		rank.HIGH : ["air_hitgrab", "air_tail", "air_down_trident"],
		rank.RUSH : ["air_hitgrab", "air_tail"],
		rank.SHARK : ["air_shark"],
		rank.ZONE : ["air_down_trident"]
	},
	atk_range.AIR_LOW: {
		rank.LOW : ["option_air"],
		rank.MID : ["option_air", "air_down_trident"],
		rank.HIGH : ["air_down_trident"],
		rank.RUSH : ["option_air"],
		rank.SHARK : ["options_air"],
		rank.ZONE : ["air_down_trident"]
	},
	atk_range.AIR_LOW_LONG: {
		rank.LOW : ["option_air"],
		rank.MID : ["option_air", "air_down_trident"],
		rank.HIGH : ["air_down_trident"],
		rank.RUSH : ["option_air"],
		rank.SHARK : ["options_air"],
		rank.ZONE : ["air_down_trident"]
	},
	atk_range.AIR_FAR: {
		rank.LOW : ["air_tail"],
		rank.MID : ["air_dash","air_shark", "air_uptail", "air_overhead"],
		rank.HIGH : ["air_dash","air_surf", "air_shark", "air_trident", "air_overhead"],
		rank.SHARK : ["air_dash","air_shark"],
		rank.RUSH : ["air_dash","air_surf", "air_uptail", "air_overhead"],
		rank.ZONE : ["air_trident"]
	},
	atk_range.AIR_LONG: { # run at jump_peak
		rank.LOW : ["option_air"],
		rank.MID : ["air_dash", "option_air", "air_trident"],
		rank.HIGH : ["air_dash", "air_trident"],
		rank.SHARK : ["air_dash"],
		rank.ZONE : ["air_trident"]
	},
}
	
# --------------------------------------------------------------------------------------------------------------------------
	
func decision(decision_ref = null) -> bool:
	match Character.mob_variant:
		"test":
			match decision_ref:
#				"air_low_short":
#					Character.start_command("air_hitgrab")
#					return true
#				"close_range":
#					Character.target_closest()
#					filter(atk_range.CLOSE_RANGE)
#					return true
				"start", "passive", "standby", null:
					Character.start_command("command_grab")
					return true
					
		"base":
			match decision_ref:
				"start", "passive":
					Character.start_command("idle")
					return true
				"offense":
					if Globals.Game.rng_generate(100) < idle_chance():
						Character.start_command("idle")
					else:
						var array = ["seek", "seek", "forward_jump", "shorthop", "dash"]
						jump_filter(array)
						Character.start_command(Globals.Game.rng_array(array))
					return true
					
				"point_blank":
					Character.target_closest()
					filter(atk_range.POINTBLANK)
					return true
				"close_range":
					Character.target_closest()
					filter(atk_range.CLOSE_RANGE)
					return true
				"mid_range":
					if Globals.Game.rng_generate(100) <= LONG_FAIL_CHANCE:
						Character.long_fail()
						return false
					Character.target_closest()
					filter(atk_range.MID_RANGE)
					return true
				"anti_air_short":
					Character.target_closest()
					filter(atk_range.ANTI_AIR_SHORT)
					return true
				"anti_air_long":
					if Globals.Game.rng_generate(100) <= LONG_FAIL_CHANCE:
						Character.long_fail()
						return false
					Character.target_closest()
					filter(atk_range.ANTI_AIR_LONG)
					return true
				"anti_air":
					Character.target_closest()
					filter(atk_range.ANTI_AIR)
					return true
					
				"jump_peak":
					if Character.get_opponent_x_dist() > 100:
						filter(atk_range.AIR_LONG)
						return true
				"air_close":
					Character.target_closest()
					filter(atk_range.AIR_CLOSE)
					return true
				"air_high":
					Character.target_closest()
					filter(atk_range.AIR_HIGH)
					return true
				"air_high_long":
					if Globals.Game.rng_generate(100) <= LONG_FAIL_CHANCE:
						Character.long_fail()
						return false
					Character.target_closest()
					filter(atk_range.AIR_HIGH_LONG)
					return true
				"air_low_short":
					Character.target_closest()
					filter(atk_range.AIR_LOW_SHORT)
					return true
				"air_low_long":
					if Globals.Game.rng_generate(100) <= LONG_FAIL_CHANCE:
						Character.long_fail()
						return false
					Character.target_closest()
					filter(atk_range.AIR_LOW_LONG)
					return true
				"air_low":
					if Globals.Game.rng_generate(100) <= LONG_FAIL_CHANCE:
						Character.long_fail()
						return false
					Character.target_closest()
					filter(atk_range.AIR_LOW)
					return true
				"air_far":
					Character.target_closest()
					filter(atk_range.AIR_FAR)
					return true

				"standby", null: # if opponent is close, do offense, if not has a chance to do LONG_RANGE
					if Globals.Game.rng_generate(100) < idle_chance():
						Character.start_command("idle")
						return true
					elif Character.get_opponent_x_dist() <= 150 or Globals.Game.rng_generate(100) < 70:
						Character.start_command("option_close")
						return true
					elif Character.is_passive() and Globals.Game.rng_generate(100) < LONG_RANGE_PASSIVE_CHANCE:
						Character.start_command("idle")
						return true
					else:
						if Character.get_target().is_hitstunned_or_sequenced():
							Character.start_command("option_close")
						else:
							filter(atk_range.LONG_RANGE)
						return true
					
		"rush", "shark":
			match decision_ref:
				"start":
					Character.start_command("seek")
					return true
				"passive":
					Character.start_command("idle")
					return true
				"offense":
					if Globals.Game.rng_generate(100) < idle_chance():
						Character.start_command("idle")
					else:
						var array = ["seek", "seek", "forward_jump", "shorthop", "dash"]
						jump_filter(array)
						Character.start_command(Globals.Game.rng_array(array))
					return true
					
				"point_blank":
					Character.target_closest()
					filter(atk_range.POINTBLANK)
					return true
				"close_range":
					Character.target_closest()
					filter(atk_range.CLOSE_RANGE)
					return true
				"mid_range":
					if Globals.Game.rng_generate(100) <= LONG_FAIL_CHANCE:
						Character.long_fail()
						return false
					Character.target_closest()
					filter(atk_range.MID_RANGE)
					return true
				"anti_air_short":
					Character.target_closest()
					filter(atk_range.ANTI_AIR_SHORT)
					return true
				"anti_air_long":
					if Globals.Game.rng_generate(100) <= LONG_FAIL_CHANCE:
						Character.long_fail()
						return false
					Character.target_closest()
					filter(atk_range.ANTI_AIR_LONG)
					return true
				"anti_air":
					Character.target_closest()
					filter(atk_range.ANTI_AIR)
					return true
					
				"jump_peak":
					if Character.get_opponent_x_dist() > 100:
						if !Character.air_dashed:
							Character.start_command("air_dash")
						else:
							Character.start_command("option_air")
						return true
				"air_close":
					Character.target_closest()
					filter(atk_range.AIR_CLOSE)
					return true
				"air_high":
					Character.target_closest()
					filter(atk_range.AIR_HIGH)
					return true
				"air_high_long":
					if Globals.Game.rng_generate(100) <= LONG_FAIL_CHANCE:
						Character.long_fail()
						return false
					Character.target_closest()
					filter(atk_range.AIR_HIGH_LONG)
					return true
				"air_low_short":
					Character.target_closest()
					filter(atk_range.AIR_LOW_SHORT)
					return true
				"air_low_long":
					if Globals.Game.rng_generate(100) <= LONG_FAIL_CHANCE:
						Character.long_fail()
						return false
					Character.target_closest()
					filter(atk_range.AIR_LOW_LONG)
					return true
				"air_low":
					if Globals.Game.rng_generate(100) <= LONG_FAIL_CHANCE:
						Character.long_fail()
						return false
					Character.target_closest()
					filter(atk_range.AIR_LOW)
					return true
				"air_far":
					Character.target_closest()
					filter(atk_range.AIR_FAR)
					return true

				"standby", null:
					if Globals.Game.rng_generate(100) < idle_chance():
						Character.start_command("idle")
						return true
					else:
						Character.start_command("option_close")
						return true
					
		"zone":		
			match decision_ref:
				"start", "passive":
					Character.start_command("idle")
					return true
					
				"point_blank":
					Character.target_closest()
					filter(atk_range.POINTBLANK)
					return true
				"close_range":
					Character.target_closest()
					filter(atk_range.CLOSE_RANGE)
					return true
				"mid_range":
					Character.target_closest()
					filter(atk_range.MID_RANGE)
					return true
				"anti_air_short":
					Character.target_closest()
					filter(atk_range.ANTI_AIR_SHORT)
					return true
				"anti_air_long":
					Character.target_closest()
					filter(atk_range.ANTI_AIR_LONG)
					return true
				"anti_air":
					Character.target_closest()
					filter(atk_range.ANTI_AIR)
					return true
					
				"jump_peak":
					if Character.get_opponent_x_dist() > 100:
						filter(atk_range.AIR_LONG)
						return true
				"air_close":
					Character.target_closest()
					filter(atk_range.AIR_CLOSE)
					return true
				"air_high":
					Character.target_closest()
					filter(atk_range.AIR_HIGH)
					return true
				"air_high_long":
					Character.target_closest()
					filter(atk_range.AIR_HIGH_LONG)
					return true
				"air_low_short":
					Character.target_closest()
					filter(atk_range.AIR_LOW_SHORT)
					return true
				"air_low_long":
					Character.target_closest()
					filter(atk_range.AIR_LOW_LONG)
					return true
				"air_low":
					Character.target_closest()
					filter(atk_range.AIR_LOW)
					return true
				"air_far":
					Character.target_closest()
					filter(atk_range.AIR_FAR)
					return true

				"standby", null:
					if Globals.Game.rng_generate(100) < idle_chance():
						Character.start_command("idle")
					elif Character.get_opponent_x_dist() < 250 and Globals.Game.rng_generate(100) < 50:
						if !Character.is_at_corners(): 
							Character.start_command(Globals.Game.rng_array(["back_dash", "back_jump"]))
						else:
							Character.start_command("cross_jump")
					elif Character.is_passive() and Globals.Game.rng_generate(100) < LONG_RANGE_PASSIVE_CHANCE:
						Character.start_command("idle")
					else:
						if Character.get_target().is_hitstunned_or_sequenced():
							Character.start_command("idle")
						else:
							filter(atk_range.LONG_RANGE)
					return true
					
		"jump":
			match decision_ref:
				"start":
					Character.start_command("forward_jump")
					return true
				"passive":
					Character.start_command("idle")
					return true
				"offense":
					if Globals.Game.rng_generate(100) < idle_chance():
						Character.start_command("idle")
					else:
						Character.start_command(Globals.Game.rng_array(["forward_jump", "shorthop"]))
					return true
					
				"point_blank":
					Character.target_closest()
					Character.start_command("shorthop")
					return true
				"close_range":
					Character.target_closest()
					Character.start_command(Globals.Game.rng_array(["forward_jump", "shorthop"]))
					return true
				"mid_range":
					Character.target_closest()
					Character.start_command(Globals.Game.rng_array(["forward_jump", "shorthop"]))
					return true
				"anti_air_short":
					Character.target_closest()
					Character.start_command("neutral_jump")
					return true
				"anti_air_long":
					Character.target_closest()
					Character.start_command("forward_jump")
					return true
				"anti_air":
					Character.target_closest()
					Character.start_command("neutral_jump")
					return true
					
				"jump_peak":
					if Character.get_opponent_x_dist() > 100:
						if !Character.air_dashed:
							Character.start_command("air_dash")
						else:
							Character.start_command("option_air")
						return true
				"air_close":
					Character.target_closest()
					filter(atk_range.AIR_CLOSE)
					return true
				"air_high":
					Character.target_closest()
					filter(atk_range.AIR_HIGH)
					return true
				"air_high_long":
					if Globals.Game.rng_generate(100) <= LONG_FAIL_CHANCE:
						Character.long_fail()
						return false
					Character.target_closest()
					filter(atk_range.AIR_HIGH_LONG)
					return true
				"air_low_short":
					Character.target_closest()
					filter(atk_range.AIR_LOW_SHORT)
					return true
				"air_low_long":
					if Globals.Game.rng_generate(100) <= LONG_FAIL_CHANCE:
						Character.long_fail()
						return false
					Character.target_closest()
					filter(atk_range.AIR_LOW_LONG)
					return true
				"air_low":
					if Globals.Game.rng_generate(100) <= LONG_FAIL_CHANCE:
						Character.long_fail()
						return false
					Character.target_closest()
					filter(atk_range.AIR_LOW)
					return true
				"air_far":
					Character.target_closest()
					filter(atk_range.AIR_FAR)
					return true

				"standby", null:
					if Globals.Game.rng_generate(100) < idle_chance():
						Character.start_command("idle")
						return true
					else:
						Character.start_command("option_close")
						return true
					
	return false


func idle_chance():
	var chance = Character.IDLE_CHANCE[Character.mob_level]
	var mobs_left = get_tree().get_nodes_in_group("MobNodes").size()
	if mobs_left == 2:
		chance = FMath.percent(chance, 50)
	elif mobs_left == 1:
		chance = FMath.percent(chance, 25)
	return chance
	
	
func jump_filter(array: Array):
	var to_filter = Globals.Game.rng_generate(100) <= Character.no_jump_chance
	if !to_filter: return
	
	Globals.remove_instances(array, "forward_jump")
	Globals.remove_instances(array, "shorthop")
	

func filter(atk_range: int):
	var results = []
	match Character.mob_variant:
		"rush":
			if rank.RUSH in ATK_LOOKUP[atk_range]:
				results = ATK_LOOKUP[atk_range][rank.RUSH]
			else: continue
		"zone":
			if rank.ZONE in ATK_LOOKUP[atk_range]:
				results = ATK_LOOKUP[atk_range][rank.ZONE]
				if Character.mob_level <= 5:
					Globals.remove_instances(results, "tri_throw_trident")
					Globals.remove_instances(results, "up_tri_throw_trident")
			else: continue
		"shark":
			if rank.SHARK in ATK_LOOKUP[atk_range]:
				results = ATK_LOOKUP[atk_range][rank.SHARK]
			else: continue
		_:		
			match Character.mob_level:
				0, 1, 2: # mass enemies, remove annoying moves
					results = ATK_LOOKUP[atk_range][rank.LOW]
				3, 4, 5: # early enemies, remove powerful moves
					results = ATK_LOOKUP[atk_range][rank.MID]
				6, 7, 8: # late-game enemies, remove weaker moves
					results = ATK_LOOKUP[atk_range][rank.HIGH]
					
	jump_filter(results)		
			
	if Character.air_dashed:
		Globals.remove_instances(results, "air_dash") # can only air_dash once per airtime
		Globals.remove_instances(results, "air_back_dash") # can only air_dash once per airtime
				
	if Character.is_at_corners(): # no retreating if at corner
		Globals.remove_instances(results, "back_dash")
		Globals.remove_instances(results, "air_back_dash")
		Globals.remove_instances(results, "back_jump")
				
# warning-ignore:return_value_discarded
	if results.size() == 0: decision()
	else:
		Character.start_command(Globals.Game.rng_array(results))


func get_stat(stat: String): # later can have effects that changes stats
	
	var to_return = get(stat)
	
	return to_return
	
	
	
func jump_style_check(): # from main character node
	Character.velocity.x = FMath.percent(Character.velocity.x, 50)
	Character.strafe_style = Globals.strafe_style.NONE
	
	match Character.command_style:
		"forward_jump":
			Character.velocity.y = -1000 * FMath.S
			Character.velocity.x += FMath.percent(Character.facing * 400 * FMath.S, Character.get_stat("SPEED_MOD"))
			Globals.Game.spawn_SFX("JumpDust", "DustClouds", Character.get_feet_pos(), {"facing":Character.facing, "grounded":true})
			if Globals.Game.rng_bool():
				Character.strafe_style = Globals.strafe_style.TOWARDS
		"back_jump":
			Character.velocity.y = -1000 * FMath.S
			Character.velocity.x -= FMath.percent(Character.facing * 400 * FMath.S, Character.get_stat("SPEED_MOD"))
			Globals.Game.spawn_SFX("JumpDust", "DustClouds", Character.get_feet_pos(), {"facing":Character.facing, "grounded":true})
			Character.strafe_style = Globals.strafe_style.AWAY
		"neutral_jump":
			Character.velocity.y = -1000 * FMath.S
			Character.strafe_style = Globals.strafe_style.TOWARDS
			Globals.Game.spawn_SFX("JumpDust", "DustClouds", Character.get_feet_pos(), {"facing":Character.facing, "grounded":true})
		"shorthop":
			Character.velocity.y = -625 * FMath.S
			Character.velocity.x += FMath.percent(Character.facing * 450 * FMath.S, Character.get_stat("SPEED_MOD"))
			var sfx_point = Character.get_feet_pos()
			sfx_point.x -= Character.facing * 5 # spawn the dust behind slightly
			Character.strafe_style = Globals.strafe_style.TOWARDS
			Globals.Game.spawn_SFX("GroundDashDust", "DustClouds", sfx_point, {"facing":Character.facing, "grounded":true})
		"cross_jump":
			Character.velocity.y = -1000 * FMath.S
			Character.velocity.x += FMath.percent(Character.facing * 800 * FMath.S, Character.get_stat("SPEED_MOD"))
			Character.strafe_style = Globals.strafe_style.AWAY_ON_DESCEND
			Globals.Game.spawn_SFX("JumpDust", "DustClouds", Character.get_feet_pos(), {"facing":Character.facing, "grounded":true})
	Character.command_style = ""


func generate_loot() -> Array:
	var loot = []
	
	if Globals.mob_attr.COIN in Character.mob_attr:
		for x in min(Character.mob_attr[Globals.mob_attr.COIN], Globals.Game.LevelControl.ITEM_LIMIT):
			loot.append("Coin")
			
	else:	
		match Character.mob_level:
			0, 1:
				loot.append_array(["Coin", "Coin", "Coin"])
			2, 3:
				loot.append_array(["Coin", "Coin", "Coin", "Coin"])
			4, 5:
				loot.append_array(["Coin", "Coin", "Coin", "Coin", "Coin"])
			6, 7:
				loot.append_array(["Coin", "Coin", "Coin", "Coin", "Coin", "Coin"])
			8:
				loot.append_array(["Coin", "Coin", "Coin", "Coin", "Coin", "Coin", "Coin"])
	
	var random = Globals.Game.rng_generate(3)
	if random == 0: loot.append("Coin")
	elif random == 1: loot.erase("Coin")
	
	return loot


# ------------------------------------------------------------------------------------------------------------------------------------

func _ready():
	get_node("TestSprite").free() # test sprite is for sizing collision box


func load_palette():
	match Character.mob_variant:
		_:
			Character.palette_ref = "mimic"
			
	if Character.palette_ref != "":
		Character.loaded_palette = Globals.Game.LevelControl.mob_data[Character.mob_ref].palettes[Character.palette_ref]
	
# STATE_DETECT --------------------------------------------------------------------------------------------------

func state_detect(anim): # for unique animations, continued from state_detect() of main Character node
	match anim:
			
		"L1Startup", "L3Startup", "F1Startup", "F2Startup", "F3Startup", "HStartup":
			return Globals.char_state.GROUND_ATK_STARTUP
		"L1Active", "L1Rec", "L1bActive", "L3Active", "F1Active", "F2Active", "F3Active", "HActive", "HbActive":
			return Globals.char_state.GROUND_ATK_ACTIVE
		"L1bRec", "L3Rec", "F1Rec", "F2Rec", "F3Rec", "HbRec":
			return Globals.char_state.GROUND_ATK_RECOVERY
			
		"aL1Startup", "aL3Startup", "aF1Startup", "aF2Startup", "aF3Startup", "aHStartup":
			return Globals.char_state.AIR_ATK_STARTUP
		"aL1Active", "aL3Active", "aF1Active", "aF2Active", "aF3Active", "aHActive":
			return Globals.char_state.AIR_ATK_ACTIVE
		"aL1Rec", "aL3Rec", "aF1Rec", "aF2Rec", "aF3Rec", "aHRec":
			return Globals.char_state.AIR_ATK_RECOVERY

		"aF2SeqA", "aF2SeqB":
			return Globals.char_state.SEQUENCE_USER
		"aF2GrabRec":
			return Globals.char_state.AIR_C_RECOVERY

		"SP1Startup", "SP1[b]Startup", "SP1[c1]bStartup", "SP1[u]Startup", "SP1[u][c1]bStartup":
			return Globals.char_state.GROUND_ATK_STARTUP
		"SP1[c1]Active", "SP1[u][c1]Active":
			return Globals.char_state.GROUND_ATK_ACTIVE
		"SP1Rec":
			return Globals.char_state.GROUND_ATK_RECOVERY
		"aSP1Startup", "aSP1[b]Startup", "aSP1[c1]bStartup", "aSP1[d]Startup", "aSP1[d][c1]bStartup":
			return Globals.char_state.AIR_ATK_STARTUP
		"aSP1[c1]Active", "aSP1[d][c1]Active":
			return Globals.char_state.AIR_ATK_ACTIVE
		"aSP1Rec":
			return Globals.char_state.AIR_ATK_RECOVERY
		
		"aSP2Startup":
			return Globals.char_state.AIR_ATK_STARTUP
		"aSP2Active":
			return Globals.char_state.AIR_ATK_ACTIVE
		"aSP2Rec":
			return Globals.char_state.AIR_ATK_RECOVERY
		"aSP2CRec":
			return Globals.char_state.AIR_C_RECOVERY
			
		"SP3Startup":
			return Globals.char_state.GROUND_ATK_STARTUP
		"SP3Active", "SP3bActive":
			return Globals.char_state.AIR_ATK_ACTIVE
		"aSP3Rec":
			return Globals.char_state.AIR_ATK_RECOVERY
			
		"SP6[ex]Startup":
			return Globals.char_state.GROUND_ATK_STARTUP
		"aSP6[ex]Active":
			return Globals.char_state.AIR_ATK_ACTIVE
		"SP6[ex]Rec", "SP6[ex]GrabRec":
			return Globals.char_state.GROUND_ATK_RECOVERY
		"SP6[ex]SeqA", "SP6[ex]SeqB", "SP6[ex]SeqC", "SP6[ex]SeqD", "SP6[ex]SeqE":
			return Globals.char_state.SEQUENCE_USER
		
	print("Error: " + anim + " not found.")
		
func check_collidable():  # some Characters have move that can pass through other Characters
	match Animator.to_play_animation:
		_:
			pass
	return true
	
func check_semi_invuln():
	return false

# --------------------------------------------------------------------------------------------------

func simulate():
	
	# can strafe up/down while doing air surf
	if Character.state == Globals.char_state.AIR_ATK_ACTIVE and Animator.query_current(["aSP2Active"]):
		var v_dir = Character.get_opponent_v_dir()  # if +1, target is under, if -1, target is above
		if v_dir != 0:
			Character.velocity.y += v_dir * 100 * FMath.S
			



func afterimage_trail():# process afterimage trail
	
	if Globals.mob_attr.TRAIL in Character.mob_attr:
			Character.afterimage_trail()
			return
	if Globals.mob_attr.BLACK_TRAIL in Character.mob_attr:
			Character.afterimage_trail(Color(0,0,0), 0.6, 10)
			return
	if Globals.mob_attr.WHITE_TRAIL in Character.mob_attr:
			Character.afterimage_trail(null, 0.6, 10, Globals.afterimage_shader.WHITE)
			return
	
	match Animator.to_play_animation:
		"Dash", "aDash", "aDashD", "aDashU":
			Character.afterimage_trail()

			
func unique_flash():
	match Animator.to_play_animation:
		_:
			pass
			
			
# GET DATA --------------------------------------------------------------------------------------------------
	
	
func query_traits(): # may have special conditions
	return TRAITS
			
#func get_root(move_name): # for aerial and chain memory, only needed for versions with active frames not in MOVE_DATABASE
#
#	if move_name in MOVE_DATABASE and "root" in MOVE_DATABASE[move_name]:
#		return MOVE_DATABASE[move_name].root
#
#	match move_name:
#		_:
#			pass
#
#	return move_name
		
			
func refine_move_name(move_name):
		
	match move_name:
		"SP1[b]", "aSP1", "aSP1[b]", "SP1[c1]", "SP1[c2]", "SP1[c1]b", "SP1[c2]b", "SP1[c3]", "aSP1[c1]", "aSP1[c2]", "aSP1[c1]b", "aSP1[c2]b", "aSP1[c3]", \
			"SP1[u]", "SP1[u][c1]", "SP1[u][c2]", "SP1[u][c1]b", "SP1[u][c2]b", "SP1[u][c3]", \
			"aSP1[d]", "aSP1[d][c1]", "aSP1[d][c2]", "aSP1[d][c1]b", "aSP1[d][c2]b", "aSP1[d][c3]":
			return "SP1"
			
		"SP6[ex]", "SP6[ex]Grab", "aSP6[ex]Grab":
			return "aSP6[ex]"
			
	return move_name
			
			
func query_move_data(move_name) -> Dictionary: # can change under conditions
	
	var orig_move_name = move_name
	move_name = refine_move_name(move_name)
	
	if !move_name in MOVE_DATABASE:
		print("Error: Cannot retrieve move_data for " + move_name)
		return {}
	
	var move_data = MOVE_DATABASE[move_name].duplicate(true)
	move_data["atk_attr"] = query_atk_attr(orig_move_name)
	
	if "damage" in move_data:
		move_data.damage = FMath.percent(move_data.damage, Character.MOB_LEVEL_TO_DMG[Character.mob_level])
	
	if Globals.mob_attr.POWER in Character.mob_attr:
		if "damage" in move_data:
			move_data.damage = Character.modify_stat(move_data.damage, Globals.mob_attr.POWER, [50, 75, 125, 150, 175, 200])

	return move_data
	
	
func query_atk_attr(move_name) -> Array: # can change under conditions

	var orig_move_name = move_name
	move_name = refine_move_name(move_name)

	var atk_attr := []
	if move_name in MOVE_DATABASE and "atk_attr" in MOVE_DATABASE[move_name]:
		atk_attr = MOVE_DATABASE[move_name].atk_attr.duplicate(true)
	else:
		print("Error: Cannot retrieve atk_attr for " + move_name)
		return []
	
	match orig_move_name: # can add various atk_attr to certain animations under under conditions
		_:
			pass
			
	return atk_attr
	

# HIT REACTIONS --------------------------------------------------------------------------------------------------

func landed_a_hit(hit_data): # reaction, can change hit_data from here
	
	match hit_data.move_name:
		"aF2":
			if hit_data.sweetspotted:
				hit_data.move_data["sequence"] = "aF2SeqA"
			

func being_hit(hit_data):
	
	match hit_data.move_name:
		_:
			pass
		
	
# AUTO SEQUENCES --------------------------------------------------------------------------------------------------

func simulate_sequence(): # this is ran on every frame during a sequence
	var Partner = Character.get_seq_partner()
	if Partner == null:
		Character.animate("Idle")
		return
	
	match Animator.to_play_animation:
		"SP6[ex]SeqA":
			if Animator.time == 10:
				Globals.Game.spawn_SFX("HitsparkB", "HitsparkB", Animator.query_point("grabpoint"), {"facing":-Character.facing, \
						"palette":Character.get_default_hitspark_palette()})
				Character.play_audio("cut1", {"vol":-12})
		"SP6[ex]SeqB":
			if Character.dir != 0: # can air strafe when going up
				Character.velocity.x += Character.dir * 10 * FMath.S
			else:
				Character.velocity.x = FMath.f_lerp(Character.velocity.x, 0, 20) # air res
			Character.velocity.x = clamp(Character.velocity.x, -100 * FMath.S, 100 * FMath.S) # max air strafe speed
			Character.velocity.y += 18 * FMath.S # gravity
			if Animator.time in [0, 21]:
				Character.play_audio("whoosh3", {"vol":-10})
		"SP6[ex]SeqC":
			Character.velocity.x = FMath.f_lerp(Character.velocity.x, 0, 20) # air res
		"SP6[ex]SeqD":
			Partner.afterimage_trail()
			if Character.grounded: end_sequence_step("ground")
		"SP6[ex]SeqE":
			pass
						
func simulate_sequence_after(): # called after moving and animating every frame, grab_point and grab_rot_dir are only updated then
	
	var Partner = Character.get_seq_partner()
	if Partner == null:
		Character.animate("Idle")
		return
		
	var grab_point = Animator.query_point("grabpoint")
	
	match Animator.to_play_animation:
		"aF2SeqA", "aF2SeqB":
			move_sequence_target(grab_point)
			rotate_partner(Partner)
			
		"SP6[ex]SeqA", "SP6[ex]SeqB", "SP6[ex]SeqC", "SP6[ex]SeqD":
			move_sequence_target(grab_point)
			rotate_partner(Partner)
#		"SP6[ex]SeqE":
#			pass
						

func start_sequence_step(): # this is ran at the start of every sequence_step
	
	var Partner = Character.get_seq_partner()
	if Partner == null:
		Character.animate("Idle")
		return

	match Animator.to_play_animation:
		"aF2SeqA":
			Globals.Game.get_node("Players").move_child(Character, 0)
			Character.velocity.set_vector(0, 0)
			Partner.velocity.set_vector(0, 0)
			Partner.animate("aSeqFlinchAFreeze")
			Partner.face(-Character.facing)
			rotate_partner(Partner)
			Partner.get_node("ModulatePlayer").play("unlaunch_flash")
			Character.play_audio("cut2", {"vol":-20})
			Globals.Game.spawn_SFX("HitsparkC", "HitsparkC", Animator.query_point("grabpoint"), {"facing":-Character.facing, \
					"rot":deg2rad(-70), "palette":Character.get_default_hitspark_palette()})
		"aF2SeqB":
			Character.velocity.set_vector(150 * FMath.S * Character.facing, 0)
			Character.velocity.rotate(70 * Character.facing)
			Character.play_audio("whoosh15", {"vol":-8})
			Character.play_audio("whoosh3", {"vol":-13, "bus":"PitchDown"})
			
		"SP6[ex]SeqA":
			Globals.Game.get_node("Players").move_child(Character, 0) # move Grabber to back, some grabs move Grabbed to back
			Character.velocity.set_vector(0, 0) # freeze first
			Partner.velocity.set_vector(0, 0)
			Partner.animate("aSeqFlinchAFreeze")
			Partner.face(-Character.facing)
			rotate_partner(Partner)
			Partner.get_node("ModulatePlayer").play("unlaunch_flash")
			Character.play_audio("impact29", {"vol":-27})
		"SP6[ex]SeqB":
			Character.velocity.set_vector(0, -500 * FMath.S)  # jump up
			if Character.grounded:
				Globals.Game.spawn_SFX("BigSplash", "BigSplash", Character.get_feet_pos(), \
						{"facing":Globals.Game.rng_facing(), "grounded":true, "back":true, "palette":"master"}, Character.player_ID)
				Character.play_audio("water4", {"vol" : -20})
#				Globals.Game.spawn_SFX("JumpDust", "DustClouds", Character.get_feet_pos(), {"facing":Character.facing, "grounded":true})
#				Globals.Game.spawn_SFX("BounceDust", "DustClouds", Character.get_feet_pos(), {"facing":Character.facing, "grounded":true})
		"SP6[ex]SeqC":
			Character.velocity.set_vector(0, 600 * FMath.S)  # dive down
			Globals.Game.spawn_SFX("WaterJet", "WaterJet", Character.position, \
					{"facing":Character.facing, "rot":PI/2, "palette":"master"}, Character.player_ID)
			Character.play_audio("water14", {})
		"SP6[ex]SeqE":  # you hit ground
			Partner.sequence_hit(0)
			Character.velocity.set_vector(0, 0)
			Partner.move_sequence_player_by(Vector2(0, Character.get_feet_pos().y - Partner.get_feet_pos().y)) # move opponent down to your level
			Globals.Game.spawn_SFX("BounceDust", "DustClouds", Character.get_feet_pos(), {"facing":Character.facing, "grounded":true})
			Globals.Game.spawn_SFX("BigSplash", "BigSplash", Partner.get_feet_pos(), \
					{"facing":Globals.Game.rng_facing(), "grounded":true, "palette":"master"}, Character.player_ID)
			Globals.Game.spawn_SFX("HitsparkD", "HitsparkD", Partner.get_feet_pos(), {"facing":Character.facing, \
					"palette":Character.get_default_hitspark_palette(), "rot":PI/2})
			Globals.Game.set_screenshake()
			Character.play_audio("impact41", {"vol":-15, "bus":"LowPass"})
			Character.play_audio("rock3", {})
			
							
func end_sequence_step(trigger = null): # this is ran at the end of certain sequence_step, or to end a trigger sequence_step
	# return true if sequence_step ended
	var Partner = Character.get_seq_partner()
	if Partner == null:
		Character.animate("Idle")
		return
	
	if trigger == "break": # grab break
		Character.animate("Idle")
		Partner.animate("Idle")
		return true
	
	match Animator.to_play_animation:
		"aF2SeqB":
			Partner.sequence_launch()
			return true
			
		"SP6[ex]SeqD": # ends when either you or parther hit the ground
			if trigger == "ground" or trigger == "target_ground": # you/target hit the ground
				Character.animate("SP6[ex]SeqE")
				return true
#			elif trigger == "target_ground": # parther hit the ground but not you
#				Character.animate("aSP6[ex]SeqE")
#				return true
		"SP6[ex]SeqE":
			Partner.sequence_launch()
			return true
			
			
func rotate_partner(Partner): # rotate partner according to grabrotdir
	var grab_point = Animator.query_point("grabpoint")
	var grab_rot_dir = Animator.query_point("grabrotdir")

	if grab_rot_dir != null:
		if Partner.facing == -1:
			Partner.sprite.rotation = grab_point.angle_to_point(grab_rot_dir)
		else:
			Partner.sprite.rotation = grab_point.angle_to_point(grab_rot_dir) + PI
			
func move_sequence_target(new_position): # move sequence_target to new position
	if new_position == null: return # no grab point
	
	var Partner = Character.get_seq_partner()
	if Partner == null:
		Character.animate("Idle")
		return
		
	var results = Partner.move_sequence_player_to(new_position) # [landing_check, collision_check, ledgedrop_check]
	
	if results[0]: # Grabbed hit the ground, ends sequence step if it is triggered by Grabbed being grounded
		if end_sequence_step("target_ground"):
			return
			
	if results[1]: # Grabbed hit the wall/ceiling/ground outside ground trigger, reposition Grabber
		var reposition = Partner.position + (Character.position - Animator.query_point("grabpoint"))
		var reposition_results = Character.move_sequence_player_to(reposition) # [landing_check, collision_check, ledgedrop_check]
		if reposition_results[1]: # fail to reposition properly
			end_sequence_step("break") # break grab
			
			
func get_seq_hit_data(hit_key: int):
	var seq_hit_data = MOVE_DATABASE[Animator.to_play_animation].sequence_hits[hit_key].duplicate(true)
	
	if "damage" in seq_hit_data:
		seq_hit_data.damage = FMath.percent(seq_hit_data.damage, Character.MOB_LEVEL_TO_DMG[Character.mob_level])
	
		if Globals.mob_attr.POWER in Character.mob_attr:
			seq_hit_data.damage = Character.modify_stat(seq_hit_data.damage, Globals.mob_attr.POWER, [50, 75, 125, 150, 175, 200])
	
	return seq_hit_data
	
	
	
func get_seq_launch_data():
	var seq_data = MOVE_DATABASE[Animator.to_play_animation].sequence_launch.duplicate(true)

	if "damage" in seq_data:
		seq_data.damage = FMath.percent(seq_data.damage, Character.MOB_LEVEL_TO_DMG[Character.mob_level])
	
		if Globals.mob_attr.POWER in Character.mob_attr:
			seq_data.damage = Character.modify_stat(seq_data.damage, Globals.mob_attr.POWER, [50, 75, 125, 150, 175, 200])

	return seq_data
			
			
func sequence_fallthrough(): # which step in sequence ignore soft platforms
	return false
	
func sequence_ledgestop(): # which step in sequence are stopped by ledges
	return false
	
func sequence_passthrough(): # which step in sequence ignore all platforms (for cinematic supers)
	return false
	
func sequence_partner_passthrough(): # which step in sequence has partner ignore all platforms
	return false
	
#func sequence_passfloor(): # which step in sequence ignore hard floor
#	return false
	
	
# CODE FOR CERTAIN MOVES ---------------------------------------------------------------------------------------------------



# ANIMATION AND AUDIO PROCESSING ---------------------------------------------------------------------------------------------------
# these are ran by main Character node when it gets the signals so that the order is easier to control

func _on_SpritePlayer_anim_finished(anim_name):
	
	match anim_name:
		"DashTransit":
			Character.animate("Dash")
		"Dash":
			if Character.command_style == "dash_dance":
				Character.face(-Character.facing)
				Character.animate("DashTransit")
				Character.command_style = ""
			else:
				Character.animate("DashBrake")
		"DashBrake":
			Character.animate("Idle")
		"aDashTransit":
			if Character.command_style != "air_back_dash":
				Character.face_opponent()
				match Character.get_opponent_angle_seg(Globals.angle_split.FOUR):
					Globals.compass.E, Globals.compass.W:
						Character.animate("aDash")
					Globals.compass.N:
						Character.animate("aDashU")
					Globals.compass.S:
						Character.animate("aDashD")
			else:
				Character.face_away_from_opponent()
				Character.animate("aDash")
				Character.command_style = "back_jump"
		"aDash", "aDashD", "aDashU":
			Character.animate("aDashBrake")
		"aDashBrake":
			Character.animate("Fall")
			
		"F1Startup":
			Character.animate("F1Active")
		"F1Active":
			Character.animate("F1Rec")
		"F1Rec":
			Character.animate("Idle")
			
		"L1Startup":
			Character.animate("L1Active")
		"L1Active":
			Character.animate("L1Rec")
		"L1Rec":
			Character.animate("L1bActive")
		"L1bActive":
			Character.animate("L1bRec")
		"L1bRec":
			Character.animate("Idle")
		
		"L3Startup":
			Character.animate("L3Active")
		"L3Active":
			Character.animate("L3Rec")
		"L3Rec":
			Character.animate("Idle")
		
		"F2Startup":
			Character.animate("F2Active")
		"F2Active":
			Character.animate("F2Rec")
		"F2Rec":
			Character.animate("Idle")
		
		"F3Startup":
			Character.animate("F3Active")
		"F3Active":
			Character.animate("F3Rec")
		"F3Rec":
			Character.animate("Idle")
			
		"HStartup":
			Character.animate("HActive")
		"HActive":
			Character.animate("HbActive")
		"HbActive":
			Character.animate("HbRec")
		"HbRec":
			Character.animate("Idle")
		
		"aL1Startup":
			Character.animate("aL1Active")
		"aL1Active":
			Character.animate("aL1Rec")
		"aL1Rec":
			Character.animate("FallTransit")
			
		"aL3Startup":
			Character.animate("aL3Active")
		"aL3Active":
			Character.animate("aL3Rec")
		"aL3Rec":
			Character.animate("FallTransit")
			
		"aF1Startup":
			Character.animate("aF1Active")
		"aF1Active":
			Character.animate("aF1Rec")
		"aF1Rec":
			Character.animate("FallTransit")
		
		"aF2Startup":
			Character.animate("aF2Active")
		"aF2Active":
			Character.animate("aF2Rec")
		"aF2Rec":
			Character.animate("FallTransit")
		
		"aF2SeqA":
			Character.animate("aF2SeqB")
		"aF2SeqB":
			end_sequence_step()
			Character.animate("aF2GrabRec")
		"aF2GrabRec":
			Character.animate("FallTransit")
		
		"aF3Startup":
			Character.animate("aF3Active")
		"aF3Active":
			Character.animate("aF3Rec")
		"aF3Rec":
			Character.animate("FallTransit")
		
		"aHStartup":
			Character.animate("aHActive")
		"aHActive":
			Character.animate("aHRec")
		"aHRec":
			Character.animate("FallTransit")
		
		"SP1Startup":
			match Character.command_style:
				"up_tri_throw_trident", "up_tri_throw_trident2":
					Character.animate("SP1[u]Startup")
				"up_trident":
					Character.animate("SP1[u]Startup")
					Character.command_style = ""
				_:
					if Character.are_players_in_box(Vector2(0, -200), Vector2(180, 150)):
						Character.animate("SP1[u]Startup")
					else:
						Character.animate("SP1[b]Startup")
		"SP1[b]Startup":
			Character.animate("SP1[c1]bStartup")
		"SP1[c1]bStartup":
			Character.animate("SP1[c1]Active")
		"SP1[c1]Active":
			match Character.command_style:
				"tri_throw_trident":
					Character.animate("SP1Startup")
					Character.afterimage_cancel()
					Character.command_style = "tri_throw_trident2"
				"tri_throw_trident2":
					Character.animate("SP1Startup")
					Character.afterimage_cancel()
					Character.command_style = ""
				_:
					Character.animate("SP1Rec")
		"SP1[u]Startup":
			Character.animate("SP1[u][c1]bStartup")
		"SP1[u][c1]bStartup":
			Character.animate("SP1[u][c1]Active")
		"SP1[u][c1]Active":
			match Character.command_style:
				"up_tri_throw_trident":
					Character.animate("SP1Startup")
					Character.afterimage_cancel()
					Character.command_style = "up_tri_throw_trident2"
				"up_tri_throw_trident2":
					Character.animate("SP1Startup")
					Character.afterimage_cancel()
					Character.command_style = "up_trident"
				_:
					Character.animate("SP1Rec")
		"SP1Rec":
			Character.animate("Idle")

		"aSP1Startup":
			match Character.command_style:
				"down_trident":
					Character.animate("aSP1[d]Startup")
					Character.command_style = ""
				_:
					if Character.are_players_in_box(Vector2(0, 150), Vector2(150, 200)):
						Character.animate("aSP1[d]Startup")
					else:
						Character.animate("aSP1[b]Startup")
		"aSP1[b]Startup":
			Character.animate("aSP1[c1]bStartup")
		"aSP1[c1]bStartup":
			Character.animate("aSP1[c1]Active")
		"aSP1[c1]Active":
			Character.animate("aSP1Rec")
		"aSP1[d]Startup":
			Character.animate("aSP1[d][c1]bStartup")
		"aSP1[d][c1]bStartup":
			Character.animate("aSP1[d][c1]Active")
		"aSP1[d][c1]Active":
			Character.animate("aSP1Rec")
		"aSP1Rec":
			Character.animate("FallTransit")
			
		"aSP2Startup":
			Character.animate("aSP2Active")
		"aSP2Active":
			Character.animate("aSP2Rec")
		"aSP2Rec":
			Character.animate("aSP2CRec")
		"aSP2CRec":
			Character.animate("FallTransit")
			
		"SP3Startup":
			Character.animate("SP3Active")
			Globals.Game.spawn_mob_SFX("BigSplash", "BigSplash", Character.get_feet_pos(), \
					{"facing":Globals.Game.rng_facing(), "grounded":true, "back":true, \
					"palette":Character.palette_ref}, Character.mob_ref)
		"SP3Active":
			Character.animate("SP3bActive")
		"SP3bActive":
			Character.animate("aSP3Rec")
		"aSP3Rec":
			Character.animate("FallTransit")
			
		"SP6[ex]Startup":
			Character.animate("aSP6[ex]Active")
		"aSP6[ex]Active":
			Character.animate("SP6[ex]Rec")
		"SP6[ex]Rec":
			Character.animate("Idle")
			
		"SP6[ex]SeqA":
			Character.animate("SP6[ex]SeqB")
		"SP6[ex]SeqB":
			Character.animate("SP6[ex]SeqC")
		"SP6[ex]SeqC":
			Character.animate("SP6[ex]SeqD")
		"SP6[ex]SeqE":
			end_sequence_step()
			Character.animate("SP6[ex]GrabRec")
		"SP6[ex]GrabRec":
			Character.animate("Idle")
			
			
	if Globals.mob_attr.CHAIN in Character.mob_attr:
		if Character.is_atk_recovery():
			if Character.chain_memory.size() < Character.rand_max_chain_size and !Character.is_opponent_crossing_mob():
				Character.chaining = true
				var select = []
				if Character.grounded:
					select = ["SP1Startup", "SP3Startup", "L1Startup", "L3Startup", "F1Startup", "F2Startup", "F3Startup", "HStartup"]
				else:
					select = ["aSP1Startup", "aSP2Startup", "aL1Startup", "aL3Startup", "aF1Startup", "aHStartup"]
				
				for chained in Character.chain_memory: # remove repeats
					if chained in select:
						select.erase(chained)
				
				if select.size() > 0:
					Character.afterimage_cancel()
					Character.animate(Globals.Game.rng_array(select))
				else:
					Character.chaining = false
				

func _on_SpritePlayer_anim_started(anim_name):
				
	if Globals.mob_attr.CHAIN in Character.mob_attr and \
			Character.is_atk_startup() and Character.get_move_name() in STARTERS:
		if Character.chain_memory.size() == 0: # 1st attack in chain set the rand_max_chain_size
			Character.rand_max_chain_size = Globals.Game.rng_generate(Character.mob_attr[Globals.mob_attr.CHAIN] + 1)
		Character.chain_memory.append(anim_name)
						
	if Character.chaining:
#		Character.afterimage_cancel()
		Character.face_opponent()
		Character.chaining = false
		
	if Character.is_atk_startup() and !refine_move_name(Character.get_move_name()) in NO_IMPULSE: # impulse
		Character.velocity.x = FMath.percent(Character.velocity.x, 50)
		if Character.grounded:
			Character.velocity.x += Character.facing * FMath.percent(Character.get_stat("SPEED"), 200)
	#			Character.velocity.x = int(clamp(Character.velocity.x, -Character.get_stat("SPEED"), Character.get_stat("SPEED")))
			Globals.Game.spawn_SFX( "GroundDashDust", "DustClouds", Character.get_feet_pos(), \
				{"facing":Character.facing, "grounded":true})
		else:
			Character.velocity.y = FMath.percent(Character.velocity.y, 50)

	match anim_name:
		"Dash":
			Character.velocity.x = FMath.percent(450 * FMath.S * Character.facing, Character.get_stat("SPEED_MOD"))
			Character.anim_friction_mod = 0
			Character.afterimage_timer = 1 # sync afterimage trail
			Globals.Game.spawn_SFX( "GroundDashDust", "DustClouds", Character.get_feet_pos(), \
				{"facing":Character.facing, "grounded":true})
		"aDash":
			Character.velocity.set_vector(FMath.percent(400 * FMath.S * Character.facing, Character.get_stat("SPEED_MOD")), 0)
			Character.anim_gravity_mod = 0
			Character.afterimage_timer = 1 # sync afterimage trail
			Globals.Game.spawn_SFX( "AirDashDust", "DustClouds", Character.position, {"facing":Character.facing})
			Character.air_dashed = true
		"aDashD":
			Character.velocity.set_vector(FMath.percent(400 * FMath.S * Character.facing, Character.get_stat("SPEED_MOD")), 0)
			Character.velocity.rotate(26 * Character.facing)
			Character.anim_gravity_mod = 0
			Character.afterimage_timer = 1 # sync afterimage trail
			Globals.Game.spawn_SFX( "AirDashDust", "DustClouds", Character.position, {"facing":Character.facing, "rot":PI/7})
			Character.air_dashed = true
		"aDashU":
			Character.velocity.set_vector(FMath.percent(400 * FMath.S * Character.facing, Character.get_stat("SPEED_MOD")), 0)
			Character.velocity.rotate(-26 * Character.facing)
			Character.anim_gravity_mod = 0
			Character.afterimage_timer = 1 # sync afterimage trail
			Globals.Game.spawn_SFX( "AirDashDust", "DustClouds", Character.position, {"facing":Character.facing, "rot":-PI/7})
			Character.air_dashed = true
		
		
		"L3Startup":
			Character.velocity.x += Character.facing * FMath.percent(Character.get_stat("SPEED"), 100)
#			Globals.Game.spawn_SFX( "GroundDashDust", "DustClouds", Character.get_feet_pos(), \
#				{"facing":Character.facing, "grounded":true})
		
		"F1Startup":
			Character.velocity.x += Character.facing * FMath.percent(Character.get_stat("SPEED"), 25)
		"F1Active":
			Character.velocity.x += Character.facing * FMath.percent(Character.get_stat("SPEED"), 50)
		"F2Startup":
			Character.velocity.x += Character.facing * FMath.percent(Character.get_stat("SPEED"), 50)
			
		"HStartup":
			Character.velocity.x += Character.facing * FMath.percent(Character.get_stat("SPEED"), 50)
			
		"aL1Startup", "aL3Startup":
			Character.velocity_limiter.x = 85
			Character.anim_gravity_mod = 75
		"aL1Active", "aL3Active":
			Character.velocity_limiter.x = 85
			Character.anim_gravity_mod = 75
		"aL1Rec", "aL3Rec":
			Character.velocity_limiter.x = 85
			
		"aF2Startup":
			Character.velocity_limiter.x_slow = 20
			Character.velocity_limiter.y_slow = 20
			Character.anim_gravity_mod = 0
		"aF2Active":
			Character.velocity_limiter.x = 50
			Character.velocity_limiter.down = 85
			Character.anim_gravity_mod = 50
		"aF2Rec":
			Character.velocity_limiter.x = 70
			Character.velocity_limiter.down = 70
		"aF2SeqA", "aF2SeqB":
			start_sequence_step()
		"aF2GrabRec":
			Character.face(-Character.facing)
			Character.velocity_limiter.x = 50
			Character.velocity_limiter.down = 85
			Character.anim_gravity_mod = 50
			
		"aF3Startup":
			Character.velocity_limiter.x = 85
			Character.velocity_limiter.down = 0
			Character.velocity_limiter.up = 100
			Character.anim_gravity_mod = 0
		"aF3Active":
			Character.velocity.set_vector(200 * FMath.S * Character.facing, 0)
			Character.velocity.rotate(-72 * Character.facing)
			Character.anim_gravity_mod = 0
		"aF3Rec":
			Character.velocity_limiter.x = 75
			Character.velocity_limiter.down = 100
			
		"aHStartup":
			Character.velocity_limiter.x_slow = 20
			Character.velocity_limiter.y_slow = 20
			Character.anim_gravity_mod = 0
		"aHActive":
			Character.velocity.set_vector(0, 0)
			Character.velocity_limiter.x = 0
			Character.anim_gravity_mod = 0
		"aHRec":
			Character.velocity_limiter.x = 70
			Character.velocity_limiter.down = 70
			
		"aSP1Startup", "aSP1[b]Startup", "aSP1[d]Startup":
			Character.velocity_limiter.x_slow = 20
			Character.velocity_limiter.y_slow = 20
			Character.anim_gravity_mod = 0
		"SP1[c1]Active": # spawn projectile at EntitySpawn
			Character.velocity.x += Character.facing * FMath.percent(Character.get_stat("SPEED"), 50)
			Globals.Game.LevelControl.spawn_mob_entity(Character.player_ID, "GuraM", "TridentProjM", Animator.query_point("entityspawn"), \
					{"facing": Character.facing, "target_ID" : Character.target_ID}, Character.mob_level, Character.mob_attr, Character.palette_ref)
			Globals.Game.spawn_SFX("SpecialDust", "DustClouds", Character.get_feet_pos(), {"facing":Character.facing, "grounded":true})
		"SP1[u][c1]Active": # spawn projectile at EntitySpawn
			Globals.Game.LevelControl.spawn_mob_entity(Character.player_ID, "GuraM", "TridentProjM", Animator.query_point("entityspawn"), \
					{"facing": Character.facing, "target_ID" : Character.target_ID, "alt_aim" : true}, Character.mob_level, Character.mob_attr, \
					Character.palette_ref)
			Globals.Game.spawn_SFX("SpecialDust", "DustClouds", Character.get_feet_pos(), {"facing":Character.facing, "grounded":true})
		"aSP1[c1]Active":
			Globals.Game.LevelControl.spawn_mob_entity(Character.player_ID, "GuraM", "TridentProjM", Animator.query_point("entityspawn"), \
					{"facing": Character.facing, "target_ID" : Character.target_ID, "aerial" : true}, Character.mob_level, Character.mob_attr, \
					Character.palette_ref)
		"aSP1[d][c1]Active":
			Globals.Game.LevelControl.spawn_mob_entity(Character.player_ID, "GuraM", "TridentProjM", Animator.query_point("entityspawn"), \
					{"facing": Character.facing, "target_ID" : Character.target_ID, "aerial" : true, "alt_aim" : true}, Character.mob_level, \
					Character.mob_attr, Character.palette_ref)
		"aSP1Rec":
			Character.velocity_limiter.x = 70
			Character.velocity_limiter.down = 70
			
		"aSP2Startup":
			Character.velocity_limiter.x_slow = 20
			Character.velocity_limiter.y_slow = 20
			Character.anim_gravity_mod = 0
		"aSP2Active":
			Character.velocity.set_vector(Character.facing * 500 * FMath.S, 0) # don't make multi-hit moves like this go fast
			Character.anim_gravity_mod = 0
			Character.anim_friction_mod = 0
			Character.velocity_limiter.y_slow = 50
			Globals.Game.spawn_mob_SFX("WaterJet", "WaterJet", Animator.query_point("sfxspawn"), {"facing":Character.facing, "palette":Character.palette_ref}, \
					Character.mob_ref)
		"aSP2Rec", "aSP2CRec":
			Character.velocity_limiter.down = 70
			Character.velocity.x = FMath.percent(Character.velocity.x, 50)
			Character.anim_gravity_mod = 25
			
		"SP3Active":
			if Character.get_opponent_x_dist() <= 50 or Character.get_opponent_dir() != Character.facing:
				Character.velocity.x = FMath.percent(Character.velocity.x, 50)
			else:
				Character.velocity.x += Character.facing * FMath.percent(Character.get_stat("SPEED"), 50)
			Character.velocity.y = -700 * FMath.S
			Character.anim_gravity_mod = 0
		"aSP3Rec":
			Character.velocity_limiter.x = 70
			
#		"SP6[ex]Startup":
#			Character.anim_friction_mod = 200
		"aSP6[ex]Active":
			Character.velocity.x = FMath.percent(100 * FMath.S * Character.facing, Character.get_stat("SPEED_MOD"))
			Character.velocity.y = 0
			Character.anim_gravity_mod = 0
		"SP6[ex]Rec": # whiff grab
			Character.play_audio("fail1", {"vol":-20})
		"SP6[ex]SeqA", "SP6[ex]SeqB", "SP6[ex]SeqC", "SP6[ex]SeqD", "SP6[ex]SeqE":
			start_sequence_step()
		"SP6[ex]GrabRec":
			Character.face(-Character.facing)
			
			
	start_audio(anim_name)


func start_audio(anim_name):
	if Character.is_atk_active():
		var move_name = anim_name.trim_suffix("Active")
		var orig_move_name = move_name
		if !move_name in MOVE_DATABASE:
			move_name = refine_move_name(move_name)
		if move_name in MOVE_DATABASE:
			if "move_sound" in MOVE_DATABASE[move_name]:
				if !MOVE_DATABASE[move_name].move_sound is Array:
					Character.play_audio(MOVE_DATABASE[move_name].move_sound.ref, MOVE_DATABASE[move_name].move_sound.aux_data)
				else:
					for sound in MOVE_DATABASE[move_name].move_sound:
						Character.play_audio(sound.ref, sound.aux_data)
						
		match orig_move_name:
			"SP1[c1]", "SP1[u][c1]", "aSP1[c1]", "aSP1[d][c1]":
				Character.play_audio("whoosh12", {"bus":"PitchDown"})
	
	match anim_name:
		"JumpTransit2":
			Character.play_audio("jump1", {"bus":"PitchDown"})
		"SoftLanding":
			landing_sound()
		"Dash":
			Character.play_audio("dash1", {"vol" : -5, "bus":"PitchDown"})
		"aDash", "aDashD", "aDashU":
			Character.play_audio("dash1", {"vol" : -6})
			
		"LaunchTransit":
			if Character.grounded and abs(Character.velocity.y) < 1 * FMath.S:
				Character.play_audio("launch2", {"vol" : -3, "bus":"LowPass"})
			else:
				Character.play_audio("launch1", {"vol":-15, "bus":"PitchDown"})

func landing_sound(): # can be called by main node
	Character.play_audio("land1", {"vol" : -3})

func stagger_anim():
	match Animator.current_animation:
		"Run":
			match sprite.frame:
				38, 41:
					Character.play_audio("footstep2", {"vol":-1})
					
					
