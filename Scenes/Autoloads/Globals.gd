extends Node

const VERSION = "Test Build 6"

const FRAME = 1.0/60.0
const CAMERA_ZOOM_SPEED = 0.000006
const RespawnTimer_WAIT_TIME = 75
const FLAT_STOCK_LOSS = 1000
const CORNER_SIZE = 64
const ENTITY_AUTO_DESPAWN = 3600


var editor: bool # check if running in editor or not

var startup := true # for main menu transition
var main_menu_focus := "Local" # for transition back to main menu
var net_menu_focus := "Host" # for transition back to netplay menu
var settings_menu_focus := "Change"
var zoom_level := 2.0  # only betweem 1.5 and 2.0! changed by distance between characters
var Game # hold the node for main game scene
var random
var pausing := false # set to true when a player tries to pause the game
var winner = [0, "Gura"] # 0 is the player ID, 1 is the character's name, pass to victory screen
var damage_numbers := false

var debug_mode := false
var debug_mode2 := false

# match settings, changed when starting a game
var player_count = 2
var stage_ref = "Grid"
var P1_char_ref = "Gura"
var P1_palette = 1
#var P1_input_style = 0
var P2_char_ref = "Gura"
var P2_palette = 2
#var P2_input_style = 0
var starting_stock_pts = 3
var time_limit = 445
var assists = 0
var static_stage = 1 # 0 is false, 1 is true
var music = "" # WIP

var match_input_log = load("res://Scenes/InputLog.gd").new() # save here, for easier saving to replays
var orig_rng_seed

var temp_input_buffer_time := [5, 5] # for saving replays
var temp_tap_jump := [true, true] # for saving replays
var temp_dj_fastfall := [false, false] # for saving replays
var temp_input_assist := [true, true] # for saving replays

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

var survival_level = null
var difficulty := 0

#onready var debugger = load("res://Scenes/Debugger.gd").new()


onready var INPUTS = [
	{
		up = ["P1_up", Em.button.P1_UP],
		down = ["P1_down", Em.button.P1_DOWN],
		left = ["P1_left", Em.button.P1_LEFT],
		right = ["P1_right", Em.button.P1_RIGHT],
		jump = ["P1_jump", Em.button.P1_JUMP],
		light = ["P1_light", Em.button.P1_LIGHT],
		fierce = ["P1_fierce", Em.button.P1_FIERCE],
		dash = ["P1_dash", Em.button.P1_DASH],
		aux = ["P1_aux", Em.button.P1_AUX],
		block = ["P1_block", Em.button.P1_BLOCK],
		special = ["P1_special", Em.button.P1_SPECIAL],
		unique = ["P1_unique", Em.button.P1_UNIQUE],
		pause = ["P1_pause", Em.button.P1_PAUSE],
		rs_up = ["P1_rs_up", Em.button.P1_RS_UP],
		rs_down = ["P1_rs_down", Em.button.P1_RS_DOWN],
		rs_left = ["P1_rs_left", Em.button.P1_RS_LEFT],
		rs_right = ["P1_rs_right", Em.button.P1_RS_RIGHT],
	},
	{
		up = ["P2_up", Em.button.P2_UP],
		down = ["P2_down", Em.button.P2_DOWN],
		left = ["P2_left", Em.button.P2_LEFT],
		right = ["P2_right", Em.button.P2_RIGHT],
		jump = ["P2_jump", Em.button.P2_JUMP],
		light = ["P2_light", Em.button.P2_LIGHT],
		fierce = ["P2_fierce", Em.button.P2_FIERCE],
		dash = ["P2_dash", Em.button.P2_DASH],
		aux = ["P2_aux", Em.button.P2_AUX],
		block = ["P2_block", Em.button.P2_BLOCK],
		special = ["P2_special", Em.button.P2_SPECIAL],
		unique = ["P2_unique", Em.button.P2_UNIQUE],
		pause = ["P2_pause", Em.button.P2_PAUSE],
		rs_up = ["P2_rs_up", Em.button.P2_RS_UP],
		rs_down = ["P2_rs_down", Em.button.P2_RS_DOWN],
		rs_left = ["P2_rs_left", Em.button.P2_RS_LEFT],
		rs_right = ["P2_rs_right", Em.button.P2_RS_RIGHT],
	},
]

const PI_NUMBERS = [
	3,1,4,1,5, 9,2,6,5,3, 
	5,8,9,7,9, 3,2,3,8,4,
	6,2,6,4,3, 3,8,3,2,7,
	9,5,0,2,8, 8,4,1,9,7,
	1,6,9,3,9, 9,3,7,5,1,
	0,5,8,2,0, 9,7,4,9,4,
	4,5,9,2,3, 0,7,8,1,6,
	4,0,6,2,8, 6,2,0,8,9,
	9,8,6,2,8, 0,3,4,8,2,
	5,3,4,2,1, 1,7,0,6,7]


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

#func sin_lerp(start, end, weight):
#	if weight <= 0: return start
#	if weight >= 1: return end
#
#	var weight2 = (sin(weight * PI - PI/2) + 1) * 0.5
#	return lerp(start, end , weight2)
	
func is_length_longer(vector: Vector2, target_length: int) -> bool: # cheap way to find length without using square root
	var x = int(vector.x)
	var y = int(vector.y)
	if (x * x) + (y * y) > target_length * target_length:
		return true
	else:
		return false
	
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
		Em.char_state.DEAD:
			return "DEAD"
		Em.char_state.GROUND_STANDBY:
			return "GROUND_STANDBY"
		Em.char_state.CROUCHING:
			return "CROUCHING"
		Em.char_state.AIR_STANDBY:
			return "AIR_STANDBY"
		Em.char_state.GROUND_STARTUP:
			return "GROUND_STARTUP"
		Em.char_state.GROUND_ACTIVE:
			return "GROUND_ACTIVE"
		Em.char_state.GROUND_REC:
			return "GROUND_REC"
		Em.char_state.GROUND_C_REC:
			return "GROUND_C_REC"
		Em.char_state.GROUND_D_REC:
			return "GROUND_D_REC"
		Em.char_state.AIR_STARTUP:
			return "AIR_STARTUP"
		Em.char_state.AIR_ACTIVE:
			return "AIR_ACTIVE"
		Em.char_state.AIR_REC:
			return "AIR_REC"
		Em.char_state.AIR_C_REC:
			return "AIR_C_REC"
		Em.char_state.AIR_D_REC:
			return "AIR_D_REC"
		Em.char_state.GROUND_FLINCH_HITSTUN:
			return "GROUND_FLINCH_HITSTUN"
		Em.char_state.AIR_FLINCH_HITSTUN:
			return "AIR_FLINCH_HITSTUN"
		Em.char_state.LAUNCHED_HITSTUN:
			return "LAUNCHED_HITSTUN"
		Em.char_state.GROUND_RESISTED_HITSTUN:
			return "GROUND_RESISTED_HITSTUN"
		Em.char_state.AIR_RESISTED_HITSTUN:
			return "AIR_RESISTED_HITSTUN"
		Em.char_state.GROUND_ATK_STARTUP:
			return "GROUND_ATK_STARTUP"
		Em.char_state.GROUND_ATK_ACTIVE:
			return "GROUND_ATK_ACTIVE"
		Em.char_state.GROUND_ATK_REC:
			return "GROUND_ATK_REC"
		Em.char_state.AIR_ATK_STARTUP:
			return "AIR_ATK_STARTUP"
		Em.char_state.AIR_ATK_ACTIVE:
			return "AIR_ATK_ACTIVE"
		Em.char_state.AIR_ATK_REC:
			return "AIR_ATK_REC"
		Em.char_state.GROUND_BLOCK:
			return "GROUND_BLOCK"
		Em.char_state.AIR_BLOCK:
			return "AIR_BLOCK"
		Em.char_state.SEQUENCE_TARGET:
			return "SEQUENCE_TARGET"
		Em.char_state.SEQUENCE_USER:
			return "SEQUENCE_USER"
			

func change_zoom_level(change):
	zoom_level += change
	zoom_level = clamp(zoom_level, 1.5, 2.0)
	
#	zoom_level = 0.0 # for taking screenshots of stages

func point_in_polygon(point: Vector2, polygon: Array):
	var point_poly = [Vector2(point.x - 1, point.y + 1), Vector2(point.x + 1, point.y + 1), \
			Vector2(point.x - 1, point.y - 1), Vector2(point.x + 1, point.y - 1)]
	if Geometry.intersect_polygons_2d(point_poly, polygon):
		return true
	else:
		return false
		

# ANGLE SPLITTER ---------------------------------------------------------------------------------------------------

func split_angle(angle: int, split_type = Em.angle_split.FOUR, bias = 1):
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
		Em.angle_split.TWO:
			if angle == 90:
				if bias == 1: return Em.compass.E
				else: return Em.compass.W
			if angle == 270:
				if bias == 1: return Em.compass.E
				else: return Em.compass.W
			if angle > 270 or angle < 90:
				return Em.compass.E
			return Em.compass.W
			
		Em.angle_split.FOUR:
			if angle <= 45 or angle >= 315:
				return Em.compass.E
			if angle < 135:
				return Em.compass.S
			if angle <= 225:
				return Em.compass.W
			return Em.compass.N

		Em.angle_split.FOUR_X:
			if angle == 90:
				if bias == 1: return Em.compass.SE
				else: return Em.compass.SW
			if angle == 270:
				if bias == 1: return Em.compass.NE
				else: return Em.compass.NW
			if angle <= 0 or angle > 270:
				return Em.compass.NE
			if angle < 90:
				return Em.compass.SE
			if angle < 180:
				return Em.compass.SW
			return Em.compass.SE 

		Em.angle_split.EIGHT:
			if angle <= 22 or angle >= 338:
				return Em.compass.E
			if angle <= 67:
				return Em.compass.SE
			if angle <= 112:
				return Em.compass.S
			if angle <= 157:
				return Em.compass.SW	
			if angle <= 202:
				return Em.compass.W	
			if angle <= 247:
				return Em.compass.NW	
			if angle <= 292:
				return Em.compass.N
			return Em.compass.NE

		Em.angle_split.EIGHT_X:
			if angle == 90:
				if bias == 1: return Em.compass.SSE
				else: return Em.compass.SSW
			if angle == 270:
				if bias == 1: return Em.compass.NNE
				else: return Em.compass.NNW
			if angle <= 0 and angle >= 315:
				return Em.compass.ENE
			if angle <= 45:
				return Em.compass.ESE
			if angle < 90:
				return Em.compass.SSE
			if angle < 135:
				return Em.compass.SSW
			if angle < 180:
				return Em.compass.WSW	
			if angle <= 225:
				return Em.compass.WNW	
			if angle < 270:
				return Em.compass.NNW	
			return Em.compass.NNE

		Em.angle_split.SIX: # 12 segments
			if angle == 90:
				if bias == 1: return Em.compass.SSE2
				else: return Em.compass.SSW2
			if angle == 270:
				if bias == 1: return Em.compass.NNE2
				else: return Em.compass.NNW2
			if angle <= 30 or angle >= 330:
				return Em.compass.E
			if angle < 90:
				return Em.compass.SSE2
			if angle < 150:
				return Em.compass.SSW2
			if angle <= 210:
				return Em.compass.W
			if angle < 270:
				return Em.compass.NNW2
			return Em.compass.NNE2
			
		Em.angle_split.SIXTEEN:
			if angle <= 11 or angle >= 349:
				return Em.compass.E
			if angle <= 33:
				return Em.compass.ESE
			if angle <= 56:
				return Em.compass.SE
			if angle <= 78:
				return Em.compass.SSE	
			if angle <= 101:
				return Em.compass.S	
			if angle <= 123:
				return Em.compass.SSW	
			if angle <= 146:
				return Em.compass.SW
			if angle <= 168:
				return Em.compass.WSW
			if angle <= 191:
				return Em.compass.W
			if angle <= 213:
				return Em.compass.WNW
			if angle <= 236:
				return Em.compass.NW	
			if angle <= 258:
				return Em.compass.NNW	
			if angle <= 281:
				return Em.compass.N	
			if angle <= 303:
				return Em.compass.NNE
			if angle <= 326:
				return Em.compass.NE
			return Em.compass.ENE	

	return null
			

func compass_to_angle(in_compass):
	match in_compass:
		Em.compass.E:
			return 0
		Em.compass.ESE:
			return 22
		Em.compass.SE:
			return 45
		Em.compass.SSE2:
			return 60
		Em.compass.SSE:
			return 68
		Em.compass.S:
			return 90
		Em.compass.SSW:
			return 112
		Em.compass.SSW2:
			return 120
		Em.compass.SW:
			return 135
		Em.compass.WSW:
			return 158
		Em.compass.W:
			return 180
		Em.compass.WNW:
			return 202
		Em.compass.NW:
			return 225
		Em.compass.NNW2:
			return 240
		Em.compass.NNW:
			return 248
		Em.compass.N:
			return 270
		Em.compass.NNE:
			return 292
		Em.compass.NNE2:
			return 300
		Em.compass.NE:
			return 315
		Em.compass.ENE:
			return 338

func dir_to_angle(dir: int, v_dir: int, bias: int):
	match dir:
		-1:
			match v_dir:
				-1:
					return 225
				0:
					return 180
				1:
					return 135
		0:
			match v_dir:
				-1:
					return 270
				0:
					match bias:
						1:
							return 0
						-1:
							return 180
				1:
					return 90
		1:
			match v_dir:
				-1:
					return 315
				0:
					return 0
				1:
					return 45


## TURNING CLOCKWISE/COUNTERCLOCKWISE USING DIRECTIONAL KEYS -------------------------------------------------------------------
## turn a direction towards a target direction

func navigate(angle: int, target_angle: int, turn_amount: int) -> int:
	angle = posmod(angle, 360)
	target_angle = posmod(target_angle, 360)
	
	var angle_btw :int = get_angle_btw(angle, target_angle)
	
	if abs(angle_btw) == 180 or angle == target_angle: # no turning if it is exactly backward or same diraction
		return angle
	
	if abs(angle_btw) <= turn_amount:
		return target_angle
		
	if angle_btw > 0:
		return posmod(angle + turn_amount, 360)
	else:
		return posmod(angle - turn_amount, 360)


func get_angle_btw(angle1: int, angle2: int) -> int:
	var angle_btw = posmod(angle2, 360) - posmod(angle1, 360)
	if abs(angle_btw) > 180:
		if angle_btw > 0:
			angle_btw = -(360 - angle_btw)
		else:
			angle_btw = 360 + angle_btw
	return angle_btw
		
	
func atk_type_to_tier(atk_type):
	match atk_type:
		Em.atk_type.LIGHT, Em.atk_type.FIERCE, Em.atk_type.HEAVY:
			return 0
		Em.atk_type.SPECIAL:
			return 1
		Em.atk_type.EX:
			return 2
		Em.atk_type.SUPER:
			return 3
		Em.atk_type.ENTITY, Em.atk_type.SUPER_ENTITY: # just in case
			return -1
	
#enum status_priority {
#	GRACE, LETHAL, STUN, VISUAL, HARMFUL, BUFF, UNIQUE
#}
#
#func status_effect_priority(effect):
#	match effect:
##		Em.status_effect.REPEAT:
##			return 3
#		Em.status_effect.STUN, Em.status_effect.CRUSH:
#			return status_priority.STUN
#		Em.status_effect.LETHAL:
#			return status_priority.LETHAL
#		Em.status_effect.RESPAWN_GRACE:
#			return status_priority.GRACE
#		Em.status_effect.POISON:
#			return status_priority.HARMFUL
#	return 0 # no visual effect
			
#func trait_lookup(trait):
#	match trait:
#		Em.trait.VULN_LIMBS: # 50% damage on SD hits
#			return 50
#
#func atk_attr_lookup(atk_attr):
#	match atk_attr:
#		_:
#			return

# find the timestamp just below or after an array of timestamps
func timestamp_find(timestamps: Array, target_time: int, find_lower: bool):
	timestamps.sort()
	var higher_time = null
	var lower_time = null
	for timestamp in timestamps:
		if timestamp == target_time:
			return target_time
		if timestamp > target_time: # overshot
			higher_time = timestamp
			break
		else:
			lower_time = timestamp
	match find_lower:
		true:
			if lower_time != null:
				return lower_time
			else:
				return null
		false:
			if higher_time != null:
				return higher_time
			else:
				return null
	
func remove_instances(results: Array, to_remove):
	if to_remove in results:
		while to_remove in results:
			results.erase(to_remove)
	
	

