extends Node2D

# CHARACTER DATA --------------------------------------------------------------------------------------------------
# may be saved in a .tres file later? Or just leave it in the .gd file

const NAME = "Gura"

# character movement stats, use to overwrite
const SPEED = 360.0 # ground speed
const AIR_STRAFE_SPEED = 35
const AIR_STRAFE_LIMIT = 0.8 # speed limit of air strafing, limit depends on ground speed
const JUMP_SPEED = 700.0
const JUMP_HORIZONTAL_SPEED = 0.0
const AIR_JUMP_MOD = 0.9 # reduce height of air jumps
const GRAVITY_MOD = 1.0 # make sure variable's a float
const TERMINAL_VELOCITY_MOD = 7.5 # affect terminal velocity downward
const FASTFALL_MOD = 1.2 # fastfall speed, mod of terminal velocity
const FRICTION = 0.15 # between 0.0 and 1.0
const ACCELERATION = 0.15 # between 0.0 and 1.0
const AIR_RESISTANCE = 0.03 # between 0.0 and 1.0
const FALL_GRAV_MOD = 1.0 # reduced gravity when going down
const MAX_AIR_JUMP = 1
const MAX_AIR_DASH = 2
const GROUND_DASH_SPEED = 480.0 # duration in animation data
const AIR_DASH_SPEED = 390.0 # duration in animation data

const DAMAGE_VALUE_LIMIT = 950.0
const GUARD_GAUGE_FLOOR = -9000.0 # tankier characters have lower GUARD_GAUGE_FLOOR
const GUARD_GAUGE_CEIL = 8000.0 # fixed? use GUARD_GAUGE_GAIN_MOD for tankier characters
const GUARD_GAUGE_REGEN_RATE = 0.05 # % of GG regened per second when GG < 100%
const GUARD_GAUGE_DEGEN_RATE = -0.75 # % of GG degened per second when GG > 100%
const BASE_BLOCK_CHIP_DAMAGE_MOD = 0.35 # % of damage taken as chip damage when blocking (average is 0.25)
const GUARD_GAUGE_GAIN_MOD = 0.8 # modify Guard Gain when being comboed, tankier characters have higher GUARD_GAUGE_GAIN_MOD
const AIR_BLOCK_DRAIN_RATE = 3400.0 # % of EX Gauge drain per second when Air Blocking
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
		"root" : "L1", # for chain combo checking
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
		"atk_attr" : [Globals.atk_attr.LEDGE_DROP, Globals.atk_attr.NO_CHAIN_ON_BLOCK],
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
		"move_sound" : { ref = "water8", aux_data = {"vol" : -10,} },
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
		"atk_attr" : [Globals.atk_attr.JUMP_CANCEL, Globals.atk_attr.ANTI_GUARD, Globals.atk_attr.NO_REPEAT, Globals.atk_attr.NO_IMPULSE],
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
		"attack_level" : 5,
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
		"attack_level" : 6,
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
}


# Steps to add an attack:
# 1. Add it in MOVE_DATABASE
# 2. Add it in state_detect()
# 3. Add it in _on_SpritePlayer_anim_finished() to set the transitions
# 4. Add it in _on_SpritePlayer_anim_started() to set up sfx_over, entity/sfx spawning  and other physics modifying characteristics
# 5. Add it in process_buffered_input() for inputs
# 6. Add it in capture_combinations() if it is a special action

# --------------------------------------------------------------------------------------------------

# shortening code, set by main character node
onready var Character = get_parent()
var Animator
var sprite

func _ready():
	get_node("TestSprite").hide() # test sprite is for sizing collision box
	
# STATE_DETECT --------------------------------------------------------------------------------------------------

func state_detect(anim): # for unique animations, continued from state_detect() of main character node
	match anim:
		
		"AirDashU2", "AirDashD2":
			return Globals.char_state.AIR_RECOVERY
		
		"L1Startup", "L2Startup", "F1Startup", "F2Startup", "F2bStartup", "F3Startup", "HStartup":
			return Globals.char_state.GROUND_ATK_STARTUP
		"L1Active", "L1bActive", "L2Active", "F1Active", "F2Active", "F3Active", "HActive", "HbActive":
			return Globals.char_state.GROUND_ATK_ACTIVE
		"L1Recovery", "L1bRecovery", "L2bRecovery", "F1Recovery", "F2Recovery", "F3Recovery", "HRecovery":
			return Globals.char_state.GROUND_ATK_RECOVERY
		"L1bCRecovery", "F1CRecovery":
			return Globals.char_state.GROUND_C_RECOVERY
			
		"aL1Startup", "aL2Startup", "aF1Startup", "aF3Startup", "aHStartup":
			return Globals.char_state.AIR_ATK_STARTUP
		"aL1Active", "aL2Active", "aF1Active", "aF3Active", "aHActive":
			return Globals.char_state.AIR_ATK_ACTIVE
		"L2Recovery", "aL1Recovery", "aL2Recovery", "aL2bRecovery", "aF1Recovery", "aF3Recovery", "aHRecovery":
			return Globals.char_state.AIR_ATK_RECOVERY
		"L2cCRecovery", "aF1CRecovery", "aF3CRecovery":
			return Globals.char_state.AIR_C_RECOVERY
			
			
func check_collidable(): # some characters have move that can pass through other characters
	match Animator.to_play_animation:
#		"Dash": 			# example
#			return false
		_:
			pass
	return true


# ---------------------------------------------------------------------------------
	
#func hop(): # done by pressing down when jumping, can be different for various characters
#	Character.velocity.y = -JUMP_SPEED * 0.9
#	Character.emit_signal("SFX","JumpDust", "DustClouds", Character.get_feet_pos(), {"facing":Character.facing, "grounded":true})
	
func consume_one_air_dash(): # different characters can have different types of air_dash consumption
	Character.air_dash = max(Character.air_dash - 1, 0)
	
func gain_one_air_dash(): # different characters can have different types of air_dash consumption
	if Character.air_dash < MAX_AIR_DASH: # cannot go over
		Character.air_dash += 1

func shadow_trail():# process shadow trail
	# Character.shadow_trail() can accept 2 parameters, 1st is the starting modulate, 2nd is the lifetime
	
	# shadow trail for certain modulate animations with the key "shadow_trail"
	if LoadedSFX.modulate_animations.has(Character.get_node("ModulatePlayer").current_animation) and \
			LoadedSFX.modulate_animations[Character.get_node("ModulatePlayer").current_animation].has("shadow_trail") and \
			Character.get_node("ModulatePlayer").is_playing():
		# basic shadow trail for "shadow_trail" = 0
		if LoadedSFX.modulate_animations[Character.get_node("ModulatePlayer").current_animation]["shadow_trail"] == 0:
			Character.shadow_trail()
			return
			
	match Animator.to_play_animation:
		"Dash", "AirDash", "AirDashD", "AirDashU", "AirDashUU", "AirDashDD":
			Character.shadow_trail()


func query_move_data(move_name):
	# move data may change for certain moves under certain conditions, unique to character
	var move_data = MOVE_DATABASE[move_name]
	
	match move_data:
		_ :
			pass
	
	return move_data
	

func landed_a_hit(_hit_data): # reaction, can change hit_data from here
	if Animator.query(["aL2Active"]):
		Character.animate("aL2Recovery")
	elif Animator.query(["L2Active"]):
		Character.animate("L2Recovery")
	
	
func being_hit(hit_data): # reaction, can change hit_data from here
	var defender = get_node(hit_data.defender_nodepath)
	
	if !hit_data.weak_hit and hit_data.move_data.damage > 0:
		match defender.state:
			Globals.char_state.AIR_STARTUP, Globals.char_state.AIR_RECOVERY:
				if Animator.query(["AirDashU2", "AirDashD2"]):
					hit_data.punish_hit = true
					
	
func query_traits(): # may have special conditions
	return TRAITS

# ANIMATION AND AUDIO PROCESSING ---------------------------------------------------------------------------------------------------
# these are ran by main character node when it gets the signals so that the order is easier to control

func _on_SpritePlayer_anim_finished(anim_name):
	match anim_name:
		"DashTransit":
			Character.animate("Dash")
		"Dash":
			Character.animate("DashBrake")
		"DashBrake":
			Character.animate("Idle")
		"AirDashTransit":
#			if Character.air_dash > 1:
#				if Character.button_down in Character.input_state.pressed and Character.dir != 0: # downward air dash
##					Character.face(Character.dir)
#					Character.animate("AirDashD")
#				elif Character.button_up in Character.input_state.pressed and Character.dir != 0: # upward air dash
##					Character.face(Character.dir)
#					Character.animate("AirDashU")
#				elif Character.button_down in Character.input_state.pressed: # downward air dash
#					Character.animate("AirDashDD")
#				elif Character.button_up in Character.input_state.pressed: # upward air dash
#					Character.animate("AirDashUU")
#				else: # horizontal air dash
#					Character.animate("AirDash")
#			else:
			if Character.button_down in Character.input_state.pressed: # downward air dash
				Character.animate("AirDashD2")
			elif Character.button_up in Character.input_state.pressed: # upward air dash
				Character.animate("AirDashU2")
			else: # horizontal air dash
				Character.animate("AirDash")	
#		"AirDash", "AirDashD", "AirDashU", "AirDashUU", "AirDashDD", "AirDashD2", "AirDashU2":
		"AirDash", "AirDashD2", "AirDashU2":
			Character.animate("AirDashBrake")
		"AirDashBrake":
			Character.animate("Fall")
			
		"L1Startup":
			Character.animate("L1Active")
			Character.atk_startup_resets() # need to do this here to work
		"L1Active":
			Character.animate("L1Recovery")
		"L1Recovery":
			Character.animate("L1bActive")
			Character.atk_startup_resets()
		"L1bActive":
			Character.animate("L1bRecovery")
		"L1bRecovery":
			Character.animate("L1bCRecovery")
		"L1bCRecovery":
			Character.animate("Idle")
			
		"L2Startup":
			Character.animate("L2Active")
			Character.atk_startup_resets() # need to do this here to work
		"L2Active":
			if Character.grounded:
				Character.animate("L2bRecovery")
			else:
				Character.animate("L2cCRecovery")
		"L2Recovery":
			Character.animate("FallTransit")
		"L2bRecovery":
			Character.animate("Idle")
		"L2cCRecovery":
			Character.animate("FallTransit")
			
		"F1Startup":
			Character.animate("F1Active")
			Character.atk_startup_resets() # need to do this here to work
		"F1Active":
			Character.animate("F1Recovery")
		"F1Recovery":
			Character.animate("F1CRecovery")
		"F1CRecovery":
			Character.animate("Idle")
			
		"F2Startup":
			Character.animate("F2bStartup")
		"F2bStartup":
			Character.animate("F2Active")
			Character.atk_startup_resets()
		"F2Active":
			Character.animate("F2Recovery")
		"F2Recovery":
			Character.animate("Idle")
			
		"F3Startup":
			Character.animate("F3Active")
			Character.atk_startup_resets()
		"F3Active":
			Character.animate("F3Recovery")
		"F3Recovery":
			Character.animate("Idle")

		"HStartup":
			Character.animate("HActive")
			Character.atk_startup_resets()
		"HActive":
			Character.animate("HbActive")
			Character.atk_startup_resets()
		"HbActive":
			Character.animate("HRecovery")	
		"HRecovery":
			Character.animate("Idle")

		"aL1Startup":
			Character.animate("aL1Active")
			Character.atk_startup_resets()
		"aL1Active":
			Character.animate("aL1Recovery")
		"aL1Recovery":
			Character.animate("FallTransit")

		"aL2Startup":
			Character.animate("aL2Active")
			Character.atk_startup_resets()
		"aL2Recovery":
			if Character.button_light in Character.input_state.pressed:
				Character.animate("aL2Startup")
			else:
				Character.animate("aL2bRecovery")
		"aL2bRecovery":
			Character.animate("FallTransit")

		"aF1Startup":
			Character.animate("aF1Active")
			Character.atk_startup_resets()
		"aF1Active":
			Character.animate("aF1Recovery")
		"aF1Recovery":
			Character.animate("aF1CRecovery")
		"aF1CRecovery":
			Character.animate("FallTransit")

		"aF3Startup":
			Character.animate("aF3Active")
			Character.atk_startup_resets()
		"aF3Active":
			Character.animate("aF3Recovery")
		"aF3Recovery":
			Character.animate("aF3CRecovery")
		"aF3CRecovery":
			Character.animate("FallTransit")
	
		"aHStartup":
			Character.animate("aHActive")
			Character.atk_startup_resets()
		"aHActive":
			Character.animate("aHRecovery")
		"aHRecovery":
			Character.animate("FallTransit")

func _on_SpritePlayer_anim_started(anim_name):

	match anim_name:
		"Dash":
			Character.velocity.x = GROUND_DASH_SPEED * Character.facing
			Character.null_friction = true
			Character.shadow_timer = 1 # sync shadow trail
			Character.emit_signal("SFX", "GroundDashDust", "DustClouds", Character.get_feet_pos(), \
					{"facing":Character.facing, "grounded":true})	
		"AirDashTransit":
			Character.aerial_memory = []
			Character.velocity.x *= 0.2
			Character.velocity.y *= 0.2
			Character.null_gravity = true
		"AirDash":
			consume_one_air_dash()
#			if Character.air_dash == 0:
#				Character.velocity.x = AIR_DASH_SPEED * 1.2 * Character.facing
#			else:
			Character.velocity.x = AIR_DASH_SPEED * Character.facing
			Character.velocity.y = 0
			Character.null_gravity = true
			Character.shadow_timer = 1 # sync shadow trail
			Character.emit_signal("SFX", "AirDashDust", "DustClouds", Character.position, {"facing":Character.facing})
#		"AirDashD":
#			consume_one_air_dash()
#			Character.velocity = Vector2(AIR_DASH_SPEED * Character.facing, 0).rotated(PI/4 * Character.facing)
#			Character.null_gravity = true
#			Character.shadow_timer = 1 # sync shadow trail
#			Character.emit_signal("SFX", "AirDashDust", "DustClouds", Character.position, {"facing":Character.facing, "rot":PI/4})
#		"AirDashU":
#			consume_one_air_dash()
#			Character.velocity = Vector2(AIR_DASH_SPEED * Character.facing, 0).rotated(-PI/4 * Character.facing)
#			Character.null_gravity = true
#			Character.shadow_timer = 1 # sync shadow trail
#			Character.emit_signal("SFX", "AirDashDust", "DustClouds", Character.position, {"facing":Character.facing, "rot":-PI/4})	
#		"AirDashDD":
#			consume_one_air_dash()
##			Character.velocity = Vector2(AIR_DASH_SPEED * Character.facing, 0).rotated(PI/2 * Character.facing)
#			Character.velocity.y = AIR_DASH_SPEED
#			Character.null_gravity = true
#			Character.shadow_timer = 1 # sync shadow trail
#			Character.emit_signal("SFX", "AirDashDust", "DustClouds", Character.position, {"facing":Character.facing, "rot":PI/2})
#		"AirDashUU":
#			consume_one_air_dash()
##			Character.velocity = Vector2(AIR_DASH_SPEED * Character.facing, 0).rotated(-PI/2 * Character.facing)
#			Character.velocity.y = -AIR_DASH_SPEED
#			Character.null_gravity = true
#			Character.shadow_timer = 1 # sync shadow trail
#			Character.emit_signal("SFX", "AirDashDust", "DustClouds", Character.position, {"facing":Character.facing, "rot":-PI/2})	
		"AirDashD2":
			consume_one_air_dash()
			Character.velocity = Vector2(AIR_DASH_SPEED * Character.facing, 0).rotated(PI/7 * Character.facing)
			Character.null_gravity = true
			Character.shadow_timer = 1 # sync shadow trail
			Character.emit_signal("SFX", "AirDashDust", "DustClouds", Character.position, {"facing":Character.facing, "rot":PI/7})
		"AirDashU2":
			consume_one_air_dash()
			Character.velocity = Vector2(AIR_DASH_SPEED * Character.facing, 0).rotated(-PI/7 * Character.facing)
			Character.null_gravity = true
			Character.shadow_timer = 1 # sync shadow trail
			Character.emit_signal("SFX", "AirDashDust", "DustClouds", Character.position, {"facing":Character.facing, "rot":-PI/7})	
			
		"L2Startup":
			Character.velocity.x += Character.facing * SPEED * 0.8
		"L2Active":
			Character.velocity.x += Character.facing * SPEED * 1.2
			Character.null_friction = true
		"L2Recovery":
			Character.velocity = Vector2(500 * Character.facing, 0).rotated(-PI/2.3 * Character.facing)
		"F1Startup":
			Character.velocity.x += Character.facing * SPEED * 0.25
		"F1Active":
			Character.velocity.x += Character.facing * SPEED * 0.5
			Character.sfx_over.show()
		"F2bStartup":
			Character.velocity.x += Character.facing * SPEED * 0.5
		"F1Recovery", "F2Active", "F2Recovery", "F3Active", "F3Recovery":
			Character.sfx_over.show()
		"HStartup":
			Character.velocity.x += Character.facing * SPEED * 0.5
		"HActive", "HbActive", "HRecovery":
			Character.sfx_under.show()
			
		"aL1Startup":
			Character.velocity_limiter.x = 0.85
		"aL1Active", "aL1Recovery":
			Character.velocity_limiter.x = 0.85
			Character.velocity_limiter.down = 1.2
			Character.sfx_under.show()
		"aL2Active":
			Character.velocity_limiter.x = 0.85
			Character.velocity_limiter.down = 1.2
		"aL2Recovery":
			Character.velocity.y = -600
			Character.sfx_over.show()
		"aF1Startup":
			Character.velocity_limiter.x = 0.85
		"aF1Active", "aF1Recovery":
			Character.velocity_limiter.x = 0.85
			Character.velocity_limiter.down = 1.0
			Character.sfx_over.show()
		"aF3Startup":
			Character.velocity_limiter.x = 0.85
			Character.velocity_limiter.y_slow = 0.2
			Character.null_gravity = true
		"aF3Active":
			Character.velocity = Vector2(200 * Character.facing, 0).rotated(-PI/2.5 * Character.facing)
			Character.null_gravity = true
			Character.sfx_over.show()
		"aF3Recovery":
			Character.velocity_limiter.x = 0.75
			Character.velocity_limiter.down = 1.0
			Character.sfx_over.show()
		"aHStartup":
			Character.velocity_limiter.x_slow = 0.2
			Character.velocity_limiter.y_slow = 0.2
			Character.null_gravity = true
			Character.sfx_over.show()
		"aHActive":
			Character.velocity = Vector2.ZERO
			Character.velocity_limiter.x = 0
			Character.null_gravity = true
			Character.sfx_over.show()
		"aHRecovery":
			Character.velocity_limiter.x = 0.7
			Character.velocity_limiter.down = 0.7
			Character.sfx_over.show()
		

	start_audio(anim_name)


func start_audio(anim_name):
	
	if Character.is_atk_active():
		var move_name = anim_name.trim_suffix("Active")
		if move_name in MOVE_DATABASE:
			if "move_sound" in MOVE_DATABASE[move_name]:
				if !MOVE_DATABASE[move_name].move_sound is Array:
					Character.play_audio(MOVE_DATABASE[move_name].move_sound.ref, MOVE_DATABASE[move_name].move_sound.aux_data)
				else:
					for sound in MOVE_DATABASE[move_name].move_sound:
						Character.play_audio(sound.ref, sound.aux_data)
	
	match anim_name:
		"JumpTransit2", "WallJumpTransit2", "BlockHopTransit2":
			Character.play_audio("jump1", {"bus":"PitchDown"})
		"AirJumpTransit2":
			Character.play_audio("jump1", {"vol":-2})
		"SoftLanding", "HardLanding", "BlockLanding":
			landing_sound()
		"LaunchTransit":
			if Character.grounded and abs(Character.velocity.y) < 1:
				Character.play_audio("launch2", {"vol" : -3, "bus":"LowPass"})
			else:
				Character.play_audio("launch1", {"vol":-15, "bus":"PitchDown"})
		"Dash":
			Character.play_audio("dash1", {"vol" : -5, "bus":"PitchDown"})
		"AirDash", "AirDashD", "AirDashU", "AirDashDD", "AirDashUU", "AirDashD2", "AirDashU2":
			Character.play_audio("dash1", {"vol" : -6})


func landing_sound(): # can be called by main node
	Character.play_audio("land1", {})


func stagger_audio():
	# WIP, for animations like Run to produce footsteps during certain frames
	
	match Animator.current_animation:
		"Run":
			match sprite.frame:
				38, 41:
					Character.play_audio("footstep2", {"vol":-1})



