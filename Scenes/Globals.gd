extends Node

const VERSION = "Test Build 6"

enum char_state {DEAD, GROUND_STANDBY, CROUCHING, AIR_STANDBY, GROUND_STARTUP, GROUND_ACTIVE, GROUND_RECOVERY,
		GROUND_C_RECOVERY, AIR_STARTUP, AIR_ACTIVE, AIR_RECOVERY, AIR_C_RECOVERY, GROUND_FLINCH_HITSTUN,
		AIR_FLINCH_HITSTUN, LAUNCHED_HITSTUN, GROUND_ATK_STARTUP, GROUND_ATK_ACTIVE, GROUND_ATK_RECOVERY,
		AIR_ATK_STARTUP, AIR_ATK_ACTIVE, AIR_ATK_RECOVERY, GROUND_BLOCK, GROUND_BLOCKSTUN, AIR_BLOCK, AIR_BLOCKSTUN,
		SEQUENCE_USER, SEQUENCE_TARGET}
enum atk_type {LIGHT, FIERCE, HEAVY, SPECIAL, EX, SUPER, ENTITY}
enum compass {N, NNE, NNE2, NE, ENE, E, ESE, SE, SSE2, SSE, S, SSW, SSW2, SW, WSW, W, WNW, NW, NNW2, NNW}
enum angle_split {TWO, FOUR, FOUR_X, SIX, EIGHT, EIGHT_X, SIXTEEN}
enum hitspark_type {NONE, CUSTOM, HIT, SLASH}
enum knockback_type {FIXED, RADIAL, MIRRORED}
enum chain_combo {RESET, NO_CHAIN, NORMAL, BLOCKED_NORMAL, SPECIAL, BLOCKED_SPECIAL, SUPER}
enum atk_attr {AIR_ATTACK, NO_CHAIN, NO_CHAIN_ON_BLOCK, ANTI_AIR, AUTOCHAIN, JUMP_CANCEL, LEDGE_DROP, NO_TURN, EASY_BLOCK, ANTI_GUARD
		NO_JUMP_CANCEL, SEMI_INVUL_STARTUP, SEMI_INVUL_GROUND_STARTUP, UNBLOCKABLE, SCREEN_SHAKE, NO_IMPULSE
		SUPERARMOR_STARTUP, SUPERARMOR_ACTIVE, DRAG_KB, NO_PUSHBACK, NO_STRAFE, REPEATABLE, NON_ATTACK
		CANNOT_CHAIN_INTO, CANNOT_CHAIN_INTO_ON_BLOCK, NOT_FROM_C_REC, LATE_CHAIN, LATE_CHAIN_INTO
		COMMAND_GRAB, VULN_LIMBS, NO_REPEAT_NORMAL, DESTROY_ENTITIES, DESTRUCTIBLE_ENTITY, INDESTRUCTIBLE_ENTITY, HARMLESS_ENTITY}
# AIR_ATTACK = for all aerial Normals/Specials, used for anti-air and preventing aerial anti-guard moves from working on grounded opponents
# NO_CHAIN = mostly for autochain moves, some can chain but some cannot
# NO_CHAIN_ON_BLOCK = no chain combo on block
# ANTI_AIR = startup and active are immune to non-grounded moves above you on the same tier
# AUTOCHAIN = for rekkas and supers with more than one strike for non-finishers, will have fixed KB and hitstun, considered weak hits
# JUMP_CANCEL = can cancel recovery with a jump, place this on the active animation with same name as the recovery animation
# LEDGE_DROP = if move during attack will fall off ledges
# NO_TURN = for rekkas, prevent turning during startup
# EASY_BLOCK = can be blocked correctly in either direction
# ANTI_GUARD = always wrongblocked if chain_combo is false, cannot perfect block
# SEMI_INVUL_STARTUP = startup is invulnerable to anything but EX Moves/Supers and moves with UNBLOCKABLE
# SEMI_INVUL_GROUND_STARTUP = startup is only semi-invulnerable if character is grounded
# UNBLOCKABLE = for command grabs
# SCREEN_SHAKE = cause screen to shake on hit
# NO_IMPULSE = cannot do impulse, for secondary hits of autochained moves
# SUPERARMOR_STARTUP = Wrongblock all attacks during startup
# SUPERARMOR_ACTIVE = Wrongblock all attacks during startup
# DRAG_KB = for multi-hit moves, unless it is the last one, knockback = velocity of the attacker/entity
# NO_PUSHBACK = no pushback if not blocked, used mainly to make certain moves more punishable
# NO_STRAFE = for certain aerials, prevent air strafing during active frames
# REPEATABLE = will not incur repeat penalty, use for multi-entities
# NON_ATTACK = projectiles and stuff, cannot be Burst Revoked if targeted opponent is in hitstun/blockstun
# CANNOT_CHAIN_INTO = automatically fails test_chain_combo(), for stuff like command grabs
# CANNOT_CHAIN_INTO_ON_BLOCK = fails test_chain_combo() if chain combo == BLOCKED_NORMAL or BLOCKED_SPECIAL
# NOT_FROM_C_REC = cannot use during cancellable recovery, for certain moves like command grabs
# LATE_CHAIN = can only chain into other moves during recovery and not active frames
# LATE_CHAIN_INTO = can only be chained into from other moves during recovery and not active frames
# COMMAND_GRAB = cannot hit opponents during ground/air movement startup
# VULN_LIMBS = take full damage from SDHits
# NO_REPEAT_NORMAL = a Light/Fierce that can only be repeated once
# DESTROY_ENTITIES = hitbox destroys entities
# DESTRUCTIBLE_ENTITY = this entity can be destroyed by opponent's non-projectile attacks
# INDESTRUCTIBLE_ENTITY = this entity cannot be destroyed by attacks with DESTROY_ENTITIES attribute
# HARMLESS_ENTITY = this entity has a hitbox but does not hit opponent (for clashing and being destroyed)

enum status_effect {LETHAL, BREAK, BREAK_RECOVER, REPEAT, RESPAWN_GRACE, POS_FLOW}
# BREAK_RECOVER = get this when you got Broken, remove when out of hitstun and recovery some Guard Gauge

enum block_state {UNBLOCKED, GROUND, AIR, GROUND_WRONG, AIR_WRONG, GROUND_PERFECT, AIR_PERFECT}
enum trait {CHAIN_DASH, VULN_GRD_DASH, VULN_AIR_DASH, AIR_PERFECT_BLOCK,
		DASH_BLOCK, AIR_DASH_BLOCK}
enum entity_trait {GROUNDED, LEDGE_STOP}
enum afterimage_shader {NONE, MASTER, MONOCHROME, WHITE}
enum moving_platform {MOVING, WARPING}

enum button {P1_UP, P1_DOWN, P1_LEFT, P1_RIGHT, P1_JUMP, P1_LIGHT, P1_FIERCE, P1_DASH, P1_BLOCK, P1_AUX, P1_SPECIAL, 
		P1_UNIQUE, P1_PAUSE,
		P2_UP, P2_DOWN, P2_LEFT, P2_RIGHT, P2_JUMP, P2_LIGHT, P2_FIERCE, P2_DASH, P2_BLOCK, P2_AUX, P2_SPECIAL, P2_UNIQUE,
		P2_PAUSE}

const FRAME = 1.0/60.0
const CAMERA_ZOOM_SPEED = 0.000006
const RespawnTimer_WAIT_TIME = 60
const FLAT_STOCK_LOSS = 500

# preloading scenes will cause issues, do them on onready variables instead
onready var loaded_audio_scene := load("res://Scenes/AudioManager.tscn")
onready var loaded_character_scene := load("res://Scenes/Character.tscn")
onready var loaded_entity_scene := load("res://Scenes/Entity.tscn")
onready var loaded_SFX_scene := load("res://Scenes/SFX.tscn")
onready var loaded_afterimage_scene := load("res://Scenes/Afterimage.tscn")
onready var loaded_palette_shader = load("res://Scenes/Shaders/Palette.gdshader")
onready var monochrome_shader = load("res://Scenes/Shaders/Monochrome.gdshader")
onready var white_shader = load("res://Scenes/Shaders/White.gdshader")
onready var loaded_guard_gauge = ResourceLoader.load("res://Assets/UI/guard_gauge1.png")
onready var loaded_guard_gauge_pos = load("res://Assets/UI/guard_gauge_pos.tres")

onready var loaded_ui_audio_scene := load("res://Scenes/Menus/UIAudio.tscn")


onready var common_entity_data = {
	"BurstCounter" : {
		"scene" : load("res://Assets/Entities/BurstCounter.tscn"),
		"frame_data" : load("res://Assets/Entities/FrameData/Burst.tres"),
		"spritesheet" : ResourceLoader.load("res://Assets/Entities/Spritesheets/BurstSprite.png")
	},
	"BurstEscape" : {
		"scene" : load("res://Assets/Entities/BurstEscape.tscn"),
		"frame_data" : load("res://Assets/Entities/FrameData/Burst.tres"),
		"spritesheet" : ResourceLoader.load("res://Assets/Entities/Spritesheets/BurstSprite.png")
	},
	"BurstExtend" : {
		"scene" : load("res://Assets/Entities/BurstExtend.tscn"),
		"frame_data" : load("res://Assets/Entities/FrameData/Burst.tres"),
		"spritesheet" : ResourceLoader.load("res://Assets/Entities/Spritesheets/BurstSprite.png")
	},
	"BurstRevoke" : {
		"scene" : load("res://Assets/Entities/BurstRevoke.tscn"),
		"frame_data" : load("res://Assets/Entities/FrameData/Burst.tres"),
		"spritesheet" : ResourceLoader.load("res://Assets/Entities/Spritesheets/BurstSprite.png")
	},
}


var editor: bool # check if running in editor or not

var startup := true # for main menu transition
var main_menu_focus := "Local" # for transition back to main menu
var net_menu_focus := "Host" # for transition back to netplay menu
var settings_menu_focus := "Change"
var zoom_level := 2.0  # only betweem 0.0 and 2.0! changed by distance between characters
var Game # hold the node for main game scene
var random
var pausing := false # set to true when a player tries to pause the game
var winner = [0, "Gura"] # 0 is the player ID, 1 is the character's name, pass to victory screen

var debug_mode := false
var debug_mode2 := false

# match settings, changed when starting a game
var player_count = 2 # WIP
var stage_ref = "Grid"
var P1_char_ref = "Gura"
var P1_palette = 1
var P1_input_style = 0
var P2_char_ref = "Gura"
var P2_palette = 2
var P2_input_style = 0
var starting_stock_pts = 4450
var time_limit = 445
var assists = 0
var static_stage = 1 # 0 is false, 1 is true
var music = "" # WIP

var match_input_log = load("res://Scenes/InputLog.gd").new() # save here, for easier saving to replays
var orig_rng_seed

var temp_input_buffer_time := [5, 5] # for saving replays
var temp_tap_jump := [true, true] # for saving replays
var temp_dj_fastfall := [false, false] # for saving replays

var watching_replay := false # flag
var replay_input_log: Dictionary = {} # not a resource
var replay_is_netgame := false # flag
var replay_profiles := ["", ""] # names of players when watching replay

var training_mode := false # flag
var training_settings := {
	"gganchor" : 0,
	"regen" : 1,
	"input_viewer" : 0,
	"hitbox_viewer" : 0,
	"frame_viewer" : 0,
}

#onready var debugger = load("res://Scenes/Debugger.gd").new()


onready var INPUTS = [ # acts like a const, need "onready var" since using enums
	{
		up = ["P1_up", Globals.button.P1_UP],
		down = ["P1_down", Globals.button.P1_DOWN],
		left = ["P1_left", Globals.button.P1_LEFT],
		right = ["P1_right", Globals.button.P1_RIGHT],
		jump = ["P1_jump", Globals.button.P1_JUMP],
		light = ["P1_light", Globals.button.P1_LIGHT],
		fierce = ["P1_fierce", Globals.button.P1_FIERCE],
		dash = ["P1_dash", Globals.button.P1_DASH],
		aux = ["P1_aux", Globals.button.P1_AUX],
		block = ["P1_block", Globals.button.P1_BLOCK],
		special = ["P1_special", Globals.button.P1_SPECIAL],
		unique = ["P1_unique", Globals.button.P1_UNIQUE],
		pause = ["P1_pause", Globals.button.P1_PAUSE]
	},
	{
		up = ["P2_up", Globals.button.P2_UP],
		down = ["P2_down", Globals.button.P2_DOWN],
		left = ["P2_left", Globals.button.P2_LEFT],
		right = ["P2_right", Globals.button.P2_RIGHT],
		jump = ["P2_jump", Globals.button.P2_JUMP],
		light = ["P2_light", Globals.button.P2_LIGHT],
		fierce = ["P2_fierce", Globals.button.P2_FIERCE],
		dash = ["P2_dash", Globals.button.P2_DASH],
		aux = ["P2_aux", Globals.button.P2_AUX],
		block = ["P2_block", Globals.button.P2_BLOCK],
		special = ["P2_special", Globals.button.P2_SPECIAL],
		unique = ["P2_unique", Globals.button.P2_UNIQUE],
		pause = ["P2_pause", Globals.button.P2_PAUSE]
	},
]

func _ready():
	self.set_pause_mode(2)
	
	random = RandomNumberGenerator.new()
	random.randomize()
	randomize() # needed for Array.shuffle()
	
	Input.use_accumulated_input = false # need to do this in Godot 3.5 for AltInputs to work
	editor = OS.has_feature("editor")
	

func _process(_delta):
	if Globals.editor:
		if Input.is_action_just_pressed("debug"):
			debug_mode = !debug_mode
		if Input.is_action_just_pressed("debug2"):
			debug_mode2 = !debug_mode2
			
#func _physics_process(delta):
#	if Input.is_action_just_pressed("sound_test"):
#		print(match_input_log.input_log)

#	var target_var = 0.0
#	test_life += delta * 2
#	test_var = sin_lerp(target_var, -80.0, test_life)
#	print(test_var)

#func d_lerp(start, end, weight):
#	return start + weight * (end - start)

func sin_lerp(start, end, weight):
	if weight <= 0: return start
	if weight >= 1: return end
	
	var weight2 = (sin(weight * PI - PI/2) + 1) * 0.5
	return lerp(start, end , weight2)
	
	
#func ease_in_lerp(start, end, weight, factor = 2): # low weight changes a less, high weight changes a lot
#	if weight <= 0: return start
#	if weight >= 1: return end
#
#	var weight2 = pow(weight, factor)
#	return lerp(start, end , weight2)
#
#
#func ease_out_lerp(start, end, weight, factor = 2): # low weight changes a lot, high weight changes less
#	if weight <= 0: return start
#	if weight >= 1: return end
#
#	var weight2 = pow(weight, 1.0 / factor)
#	return lerp(start, end , weight2)
	

func input_to_string(input, player_ID):
	if input is String: return input
	for key in INPUTS[player_ID].keys():
		if INPUTS[player_ID][key][1] == input:
			return key
			
func input_string_to_action_string(input_string: String):
	input_string = input_string.trim_prefix("P1_")
	input_string = input_string.trim_prefix("P2_")
	input_string = input_string.trim_prefix("P3_")
	input_string = input_string.trim_prefix("P4_")
	input_string = input_string.to_lower()
	return input_string


func char_state_to_string(state):
	match state:
		Globals.char_state.DEAD:
			return "DEAD"
		Globals.char_state.GROUND_STANDBY:
			return "GROUND_STANDBY"
		Globals.char_state.CROUCHING:
			return "CROUCHING"
		Globals.char_state.AIR_STANDBY:
			return "AIR_STANDBY"
		Globals.char_state.GROUND_STARTUP:
			return "GROUND_STARTUP"
		Globals.char_state.GROUND_ACTIVE:
			return "GROUND_ACTIVE"
		Globals.char_state.GROUND_RECOVERY:
			return "GROUND_RECOVERY"
		Globals.char_state.GROUND_C_RECOVERY:
			return "GROUND_C_RECOVERY"
		Globals.char_state.AIR_STARTUP:
			return "AIR_STARTUP"
		Globals.char_state.AIR_ACTIVE:
			return "AIR_ACTIVE"
		Globals.char_state.AIR_RECOVERY:
			return "AIR_RECOVERY"
		Globals.char_state.AIR_C_RECOVERY:
			return "AIR_C_RECOVERY"
		Globals.char_state.GROUND_FLINCH_HITSTUN:
			return "GROUND_FLINCH_HITSTUN"
		Globals.char_state.AIR_FLINCH_HITSTUN:
			return "AIR_FLINCH_HITSTUN"
		Globals.char_state.LAUNCHED_HITSTUN:
			return "LAUNCHED_HITSTUN"
		Globals.char_state.GROUND_ATK_STARTUP:
			return "GROUND_ATK_STARTUP"
		Globals.char_state.GROUND_ATK_ACTIVE:
			return "GROUND_ATK_ACTIVE"
		Globals.char_state.GROUND_ATK_RECOVERY:
			return "GROUND_ATK_RECOVERY"
		Globals.char_state.AIR_ATK_STARTUP:
			return "AIR_ATK_STARTUP"
		Globals.char_state.AIR_ATK_ACTIVE:
			return "AIR_ATK_ACTIVE"
		Globals.char_state.AIR_ATK_RECOVERY:
			return "AIR_ATK_RECOVERY"
		Globals.char_state.GROUND_BLOCK:
			return "GROUND_BLOCK"
		Globals.char_state.GROUND_BLOCKSTUN:
			return "GROUND_BLOCKSTUN"
		Globals.char_state.AIR_BLOCK:
			return "AIR_BLOCK"
		Globals.char_state.AIR_BLOCKSTUN:
			return "AIR_BLOCKSTUN"
		Globals.char_state.SEQUENCE_TARGET:
			return "SEQUENCE_TARGET"
		Globals.char_state.SEQUENCE_USER:
			return "SEQUENCE_USER"
			

func change_zoom_level(change):
	zoom_level += change
	zoom_level = clamp(zoom_level, 0.0, 2.0)
	
#	zoom_level = 0.0 # for taking screenshots of stages
	

# ANGLE SPLITTER ---------------------------------------------------------------------------------------------------

func split_angle(angle: int, split_type = angle_split.FOUR, bias = 1):
	# for angle, 0 is straight right, positive is turning clockwise
	# for 4 way split, the ranges would be 315 ~ 45, 45 ~ 135, 135 ~ 225 , 225 ~ 315
	# for 4 way split cross, the ranges would be 270 ~ 0, 0 ~ 90, 90 ~ 180 , 180 ~ 270
	# for 8 way split, the ranges would be
	# 	338 ~ 23, 23 ~ 68, 68 ~ 113, 113 ~ 158, 158 ~ 203, 203 ~ 248, 248 ~ 293, 293 ~ 338
	# for 8 way split cross, the ranges would be
	# 	0 ~ 45, 45 ~ 90, 90 ~ 135, 135 ~ 180, 180 ~ 225, 225 ~ 270, 270 ~ 315, 315 ~ 0
	# for 6 way split, the ranges would be
	#	330 ~ 30, 30 ~ 90, 90 ~ 150, 150 ~ 210, 210 ~ 270, 270 ~ 330
	# biased towards sideways and upward
	# can be biased towards left/right for straight up and straight down angles

	angle = posmod(angle, 360)

	match split_type:
		angle_split.TWO:
			if angle == 90:
				if bias == 1: return compass.E
				else: return compass.W
			if angle == 270:
				if bias == 1: return compass.E
				else: return compass.W
			if angle > 270 or angle < 90:
				return compass.E
			return compass.W
			
		angle_split.FOUR:
			if angle <= 45 or angle >= 315:
				return compass.E
			if angle < 135:
				return compass.S
			if angle <= 225:
				return compass.W
			return compass.N

		angle_split.FOUR_X:
			if angle == 90:
				if bias == 1: return compass.SE
				else: return compass.SW
			if angle == 270:
				if bias == 1: return compass.NE
				else: return compass.NW
			if angle <= 0 or angle > 270:
				return compass.NE
			if angle < 90:
				return compass.SE
			if angle < 180:
				return compass.SW
			return compass.SE 

		angle_split.EIGHT:
			if angle <= 22 or angle >= 338:
				return compass.E
			if angle <= 67:
				return compass.SE
			if angle <= 112:
				return compass.S
			if angle <= 157:
				return compass.SW	
			if angle <= 202:
				return compass.W	
			if angle <= 247:
				return compass.NW	
			if angle <= 292:
				return compass.N
			return compass.NE

		angle_split.EIGHT_X:
			if angle == 90:
				if bias == 1: return compass.SSE
				else: return compass.SSW
			if angle == 270:
				if bias == 1: return compass.NNE
				else: return compass.NNW
			if angle <= 0 and angle >= 315:
				return compass.ENE
			if angle <= 45:
				return compass.ESE
			if angle < 90:
				return compass.SSE
			if angle < 135:
				return compass.SSW
			if angle < 180:
				return compass.WSW	
			if angle <= 225:
				return compass.WNW	
			if angle < 270:
				return compass.NNW	
			return compass.NNE

		angle_split.SIX: # 12 segments
			if angle == 90:
				if bias == 1: return compass.SSE2
				else: return compass.SSW2
			if angle == 270:
				if bias == 1: return compass.NNE2
				else: return compass.NNW2
			if angle <= 30 or angle >= 330:
				return compass.E
			if angle < 90:
				return compass.SSE2
			if angle < 150:
				return compass.SSW2
			if angle <= 210:
				return compass.W
			if angle < 270:
				return compass.NNW2
			return compass.NNE2
			
		angle_split.SIXTEEN:
			if angle <= 11 or angle >= 349:
				return compass.E
			if angle <= 33:
				return compass.ESE
			if angle <= 56:
				return compass.SE
			if angle <= 78:
				return compass.SSE	
			if angle <= 101:
				return compass.S	
			if angle <= 123:
				return compass.SSW	
			if angle <= 146:
				return compass.SW
			if angle <= 168:
				return compass.WSW
			if angle <= 191:
				return compass.W
			if angle <= 213:
				return compass.WNW
			if angle <= 236:
				return compass.NW	
			if angle <= 258:
				return compass.NNW	
			if angle <= 281:
				return compass.N	
			if angle <= 303:
				return compass.NNE
			if angle <= 326:
				return compass.NE
			return compass.ENE	

	return null
			

#func split_angle2(angle: float, split_type = 0, bias = 1):
#	# for angle, 0 is straight right, positive is turning clockwise
#	# for 4 way split, the ranges would be 315 ~ 45, 45 ~ 135, 135 ~ 225 , 225 ~ 315
#	# for 8 way split, the ranges would be
#	# 338 ~ 23, 23 ~ 68, 68 ~ 113, 113 ~ 158, 158 ~ 203, 203 ~ 248, 248 ~ 293, 293 ~ 338
#	# biased towards sideways and upward
#	# can be biased towards left/right for straight up and straight down angles
#
#	angle = wrapf(angle, 0, TAU) # just in case
#
#	var segment: float
#
#	match split_type:
#		0:
#			segment = angle / (PI/4)
#			if segment <= 1 or segment >= 7:
#				return compass.E
#			if segment < 3:
#				return compass.S
#			if segment <= 5:
#				return compass.W
#			return compass.N
#
#		1:
#			segment = angle / (PI/2)
#			if segment == 1:
#				if bias == 1: return compass.SE
#				else: return compass.SW
#			if segment == 3:
#				if bias == 1: return compass.NE
#				else: return compass.NW
#			if segment > 0 and segment < 1:
#				return compass.SE
#			if segment < 2:
#				return compass.SW
#			if segment < 3:
#				return compass.NW
#			return compass.NE
#
#		2:
#			segment = angle / (PI/8)
#			if segment <= 1 or segment >= 15:
#				return compass.E
#			if segment < 3:
#				return compass.SE
#			if segment <= 5:
#				return compass.S
#			if segment < 7:
#				return compass.SW	
#			if segment <= 9:
#				return compass.W	
#			if segment < 11:
#				return compass.NW	
#			if segment <= 13:
#				return compass.N
#			return compass.NE
#
#		3:
#			segment = angle / (PI/4)
#			if segment == 2:
#				if bias == 1: return compass.SSE
#				else: return compass.SSW
#			if segment == 6:
#				if bias == 1: return compass.NNE
#				else: return compass.NNW
#			if segment > 0 and segment <= 1:
#				return compass.ESE
#			if segment < 2:
#				return compass.SSE
#			if segment < 3:
#				return compass.SSW
#			if segment < 4:
#				return compass.WSW	
#			if segment <= 5:
#				return compass.WNW	
#			if segment < 6:
#				return compass.NNW	
#			if segment < 7:
#				return compass.NNE
#			return compass.ENE
#
#		4: # 12 segments
#			segment = angle / (PI/6)
#			if segment == 3:
#				if bias == 1: return compass.SSE2
#				else: return compass.SSW2
#			if segment == 9:
#				if bias == 1: return compass.NNE2
#				else: return compass.NNW2
#			if segment <= 1 or segment >= 11:
#				return compass.E
#			if segment < 3:
#				return compass.SSE2
#			if segment < 5:
#				return compass.SSW2
#			if segment <= 7:
#				return compass.W
#			if segment < 9:
#				return compass.NNW2
#			return compass.NNE2
#
#	return null

func compass_to_angle(compass):
	match compass:
		Globals.compass.E:
			return 0
		Globals.compass.ESE:
			return 22
		Globals.compass.SE:
			return 45
		Globals.compass.SSE2:
			return 60
		Globals.compass.SSE:
			return 68
		Globals.compass.S:
			return 90
		Globals.compass.SSW:
			return 112
		Globals.compass.SSW2:
			return 120
		Globals.compass.SW:
			return 135
		Globals.compass.WSW:
			return 158
		Globals.compass.W:
			return 180
		Globals.compass.WNW:
			return 202
		Globals.compass.NW:
			return 225
		Globals.compass.NNW2:
			return 240
		Globals.compass.NNW:
			return 248
		Globals.compass.N:
			return 270
		Globals.compass.NNE:
			return 292
		Globals.compass.NNE2:
			return 300
		Globals.compass.NE:
			return 315
		Globals.compass.ENE:
			return 338

#func compass_to_angle(compass):
#	match compass:
#		Globals.compass.E:
#			return 0.0
#		Globals.compass.ESE:
#			return PI/8
#		Globals.compass.SE:
#			return PI/4
#		Globals.compass.SSE2:
#			return PI/3
#		Globals.compass.SSE:
#			return 3*PI/8
#		Globals.compass.S:
#			return PI/2
#		Globals.compass.SSW:
#			return 5*PI/8
#		Globals.compass.SSW2:
#			return 2*PI/3
#		Globals.compass.SW:
#			return 3*PI/4
#		Globals.compass.WSW:
#			return 7*PI/8
#		Globals.compass.W:
#			return PI
#		Globals.compass.WNW:
#			return -7*PI/8
#		Globals.compass.NW:
#			return -3*PI/4
#		Globals.compass.NNW2:
#			return -2*PI/3
#		Globals.compass.NNW:
#			return -5*PI/8
#		Globals.compass.N:
#			return -PI/2
#		Globals.compass.NNE:
#			return -3*PI/8
#		Globals.compass.NNE2:
#			return -PI/3
#		Globals.compass.NE:
#			return -PI/4
#		Globals.compass.ENE:
#			return -PI/8

## TURNING CLOCKWISE/COUNTERCLOCKWISE USING DIRECTIONAL KEYS -------------------------------------------------------------------
## turn a direction towards a target direction
#
## direction and target_direction is in angle or Vector 2, return an angle
## for constant turning, multiply turn_amount by FRAME before passing it in
#func navigate(direction, target_direction, turn_amount: float):
#	var new_direction_angle
#
#	var direction_angle: float
#	var direction_vec: Vector2
#
#	var target_direction_angle: float
#	var target_direction_vec: Vector2
#
#	# convert direction and target_direction into both angle and vec forms 1st
#	if direction is float:
#		direction_angle = direction
#		direction_vec = Vector2(cos(direction), sin(direction))
#	elif direction is Vector2:
#		direction_vec = direction
#		direction_angle = atan2(direction.y, direction.x)
#	if target_direction is float:
#		target_direction_angle = target_direction
#		target_direction_vec = Vector2(cos(target_direction), sin(target_direction))
#	elif target_direction is Vector2:
#		target_direction_vec = target_direction
#		target_direction_angle = atan2(target_direction.y, target_direction.x)
#
#	# get angle between direction and target_direction
#	var angle = direction_vec.angle_to(target_direction_vec)
#
#	if angle > 0: # turn clockwise
#		new_direction_angle = direction_angle + turn_amount
#		# test for overshoot
#		var new_direction_vec = Vector2(cos(new_direction_angle), sin(new_direction_angle))
#		if new_direction_vec.angle_to(target_direction_vec) < 0: # if overshoot, return target_direction as angle
#			return target_direction_angle
#		else:
#			return new_direction_angle # no overshoot, return new direction as angle
#	elif angle < 0:
#		new_direction_angle = direction_angle - turn_amount
#		# test for overshoot
#		var new_direction_vec = Vector2(cos(new_direction_angle), sin(new_direction_angle))
#		if new_direction_vec.angle_to(target_direction_vec) > 0: # if overshoot, return target_direction as angle
#			return target_direction_angle
#		else:
#			return new_direction_angle # no overshoot, return new direction as angle
#	else:
#		return direction_angle
		
	
func atk_type_to_tier(atk_type):
	match atk_type:
		Globals.atk_type.LIGHT, Globals.atk_type.FIERCE, Globals.atk_type.HEAVY:
			return 0
		Globals.atk_type.SPECIAL:
			return 1
		Globals.atk_type.EX:
			return 2
		Globals.atk_type.SUPER:
			return 3
		Globals.atk_type.ENTITY: # just in case
			return -1
	
func status_effect_priority(effect):
	match effect:
		Globals.status_effect.REPEAT:
			return 3
		Globals.status_effect.BREAK:
			return 3
		Globals.status_effect.LETHAL:
			return 2
		Globals.status_effect.RESPAWN_GRACE:
			return 1	
	return 0 # no visual effect
			
#func trait_lookup(trait):
#	match trait:
#		Globals.trait.VULN_LIMBS: # 50% damage on SD hits
#			return 50
#
#func atk_attr_lookup(atk_attr):
#	match atk_attr:
#		_:
#			return
