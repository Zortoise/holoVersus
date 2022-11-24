extends "res://Scenes/Physics/Physics.gd"

signal SFX (anim, loaded_sfx_ref, out_position, aux_data)
# aux_data contain {"back" : bool, "facing" : 1/-1, "v_mirror" : bool, "rot" : radians, "grounded" : true, "back" : true}
signal shadow_trail (sprite_node_path, out_position, starting_modulate_a, lifetime)
signal projectile (out_owner_ID, out_loaded_proj_ref, out_move_data, out_position, aux_data)

# constants
const GRAVITY = 4000.0
const SpecialTimer_WAIT_TIME = 10 # special button buffer, also used for SuperTimer
const PEAK_DAMPER_MOD = 0.6 # used to reduce gravity at jump peak
const PEAK_DAMPER_LIMIT = 400.0 # min velocity.y where jump peak gravity reduction kicks in
const TERMINAL_THRESHOLD = 1.5 # if velocity.y is over this during hitstun, no terminal velocity slowdown
const VarJumpTimer_WAIT_TIME = 8 # frames after jumping where holding jump will reduce gravity
const VAR_JUMP_GRAV_MOD = 0.2 # gravity multiplier during Variable Jump time
const DashLandDBox_HEIGHT = 15 # allow snapping up to dash land easier on soft platforms
const WallJumpDBox_WIDTH = 10 # for detecting walls for walljumping
const QUICK_CANCEL_TIME = 1 # number of frames at startup the user can still change direction or cancel into a combination action
const HitStunGraceTimer_TIME = 10 # number of frames that move_memory will be cleared after hitstun/blockstun ends and dash/airdash being invulnerable
const MAX_EX_GAUGE = 50000.0
const EX_GAUGE_REGEN_RATE = 1000 # EX Gauge regened per second when idling
const GUARD_GAUGE_FLOOR = -10000.0
const GUARD_GAUGE_CEIL = 10000.0
const BURSTCOUNTER_EX_COST = 1
const BURSTESCAPE_GG_COST = 0.5
const AIRBLOCK_GRAV_MOD = 0.5 # multiply to GRAVITY to get gravity during air blocking
const AIRBLOCK_TERMINAL_MOD = 0.7 # multiply to get terminal velocity during air blocking
#const TAP_MEMORY_DURATION = 5
const MAX_WALL_JUMP = 5
const HITSTUN_TERMINAL_VELOCITY_MOD = 7.5 # multiply to GRAVITY to get terminal velocity during hitstun
const HOP_JUMP_MOD = 0.8 # can hop by using up + jump
const IMPULSE_MOD = 1.25 # multiply by UniqueCharacter.SPEED to get impulse velocity
const PERFECT_IMPULSE_MOD = 1.75 # multiply by UniqueCharacter.SPEED to get impulse velocity

const MIN_HITSTOP = 5
const MAX_HITSTOP = 13
const REPEAT_DMG_MOD = 0.5 # damage modifier on repeat_penalty 
const DMG_VAL_KB_LIMIT = 3.0 # max damage percent before knockback stop increasing
const KB_BOOST_AT_DMG_VAL_LIMIT = 1.5 # knockback power when damage percent is at 100%, goes pass it when damage percent goes >100%
#const DMG_THRES_WHEN_KB_BOOST_STARTS = 0.7 # knockback only start increasing when damage percent is over this
# const DMG_BOOST_AT_DMG_VAL_LIMIT = 1.5 # increase in damage taken when damage percent is at 100%, goes pass it when damage percent goes >100%
# const DMG_THRES_WHEN_DMG_BOOST_STARTS = 0.7 # increase in damage taken when damage percent is over this
const PERFECTCHAIN_GGG_MOD = 0.5 # Guard Gain on hitstunned defender is reduced on perfect chains
const REPEAT_GGG_MOD = 2.0 # Guard Gain on hitstunned defender is increased on repeat_penalty
const DMG_REDUCTION_AT_MAX_GG = 0.5 # max reduction in damage when defender's Guard Gauge is at 200%
#const FIRST_HIT_GUARD_DRAIN_MOD = 0.7 # % of listed Guard Drain on 1st hit of combo or stray hits
const POS_FLOW_REGEN_MOD = 7.0 # increased Guard Guard Regen during Postive Flow
#const AIRBLOCK_GUARD_DRAIN_MOD = 1.5 # increased Guard Drain when blocking in air

const HITSTUN_GRAV_MOD = 0.65  # gravity multiplier during hitstun
const HITSTUN_FRICTION = 0.15  # friction during hitstun
const HITSTUN_AIR_RES = 0.03 # air resistance during hitstun

const LETHAL_KB_MOD = 1.5 # multiply knockback strength when defender is at Damage Value Limit
const LETHAL_HITSTOP = 25
const LETHAL_HITSTUN_MOD = 1.5 # multiply hitstun when defender is at Damage Value Limit

const SD_KNOCKBACK_LIMIT = 300.0 # knockback strength limit of a semi-disjoint hit
const SD_HIT_GUARD_DRAIN_MOD = 1.0 # Guard Drain on semi-disjoint hits

const SWEETSPOT_KB_MOD = 1.15
const SWEETSPOT_DMG_MOD = 1.5 # damage modifier on sweetspotted hit 
const SWEETSTOP_GUARD_DRAIN_MOD = 1.3 # Guard Drain on non-hitstunned defender is increased on sweetspotted hit
const SWEETSPOT_HITSTOP_MOD = 1.3 # sweetspotted hits has 30% more hitstop
const SWEETSPOT_GGG_MOD = 0.5 # Guard Gain on hitstunned defender is reduced on sweetspotted hit

const PUNISH_DMG_MOD = 1.5 # damage modifier on punish_hit 
const PUNISH_GUARD_DRAIN_MOD = 1.3 # Guard Drain on non-hitstunned defender is increased on a punish hit
const PUNISH_HITSTOP_MOD = 1.3 # punish hits has 30% more hitstop

const BREAK_DMG_MOD = 1.5 # damage modifier on break_hit 
const BREAK_STUN_TIME = 75 # number of frames stun time last for Break
const BREAK_HITSTOP_ATTACKER = 15 # hitstop for attacker when causing Break

const BASE_BLOCK_PUSHBACK_MOD = 0.7 # % of base knockback of attack
const BASE_BLOCK_ATKER_PUSHBACK = 300 # how much the attacker is pushed away, fixed
const DOWNWARD_KB_REDUCTION_ON_BLOCK = 0.25 # when being knocked downward (45 degree arc) while blocking, knockback is reduced
const MAX_BASE_BLOCKSTUN = 8

const WRONGBLOCK_CHIP_DMG_MOD = 2.0 # increased chip damage for wrongblocking
const WRONGBLOCK_GUARD_DRAIN_MOD = 2.5 # increased guard drain for wrongblocking
const WRONGBLOCK_BLOCKSTUN_MOD = 2.0 # increased blockstun for wrongblocking
const WRONGBLOCK_PUSHBACK_MOD = 1.0 # % of base knockback of attack
const WRONGBLOCK_ATKER_PUSHBACK = 200 # how much the attacker is pushed away, fixed
const WRONGBLOCK_HITSTOP = 7

const PERFECTBLOCK_GUARD_DRAIN_MOD = 0.15 # reduced guard drain for perfect blocking
const PERFECTBLOCK_BLOCKSTUN_MOD = 0.5 # reduced blockstun for perfect blocking
const PERFECTBLOCK_PUSHBACK_MOD = 0.25 # % of base knockback of attack
const PERFECTBLOCK_ATKER_PUSHBACK = 700 # how much the attacker is pushed away, fixed
const PERFECTBLOCK_HITSTOP = 10
const PBlockTimer_WAIT_TIME = 5
const PBlockCDTimer_WAIT_TIME = 15


const LAUNCH_THRESHOLD = 450.0 # max knockback strength before a flinch becomes a launch, also added knockback during a Break
const LAUNCH_BOOST = 250.0 # increased knockback strength when a flinch becomes a launch
const LAUNCH_ROT_SPEED = 5*PI # speed of sprite rotation when launched
const TECH_THRESHOLD = 450.0 # max velocity when hitting the ground to tech land

const STRONG_HIT_AUDIO_BOOST = 3
const WEAK_HIT_AUDIO_NERF = -9

const BOUNCE_DUST_THRESHOLD = 100.0 # min velocity towards surface needed to release BounceDust when bouncing
const LAUNCH_DUST_THRESHOLD = 1400.0 # velocity where launch dust increase in frequency

const AERIAL_STRAFE_MOD = 0.5 # reduction of air strafe speed and limit during aerials (non-active frames) and air cancellable recovery
const HITSTUN_FALL_THRESHOLD = 400.0 # if falling too fast during hitstun will help out
const DDI_SIDE_MAX = 30 # horizontal Drift DI speed at 200% Guard Gauge
const MAX_DDI_SIDE_SPEED = 300.0 # max horizontal Drift DI speed
const GDI_UP_MAX = 0.8 # gravity decrease upward Gravity DI at 200% Guard Gauge
const GDI_DOWN_MAX = 1.3 # gravity increase downward Gravity DI at 200% Guard Gauge
const VDI_MAX = 0.3 # change in knockback vector when using Vector DI at 200% Guard Gauge
const DI_MIN_MOD = 0.0 # percent of max DI at 100% Guard Gauge
const PLAYER_PUSH_SLOWDOWN = 0.95 # how much characters are slowed when they push against each other
const RESPAWN_GRACE_DURATION = 60 # how long invincibility last when respawning
const CROUCH_REDUCTION_MOD = 0.5 # reduce knockback and hitstun if opponent is crouching


# variables used, don't touch these
var loaded_palette
onready var Animator = $SpritePlayer # clean code
onready var sprite = $Sprites/Sprite # clean code
onready var sfx_under = $Sprites/SfxUnder # clean code
onready var sfx_over = $Sprites/SfxOver # clean code
var UniqueCharacter # unique character node
var directory_name
var palette_number
var spritesheets = { # filled up at initialization via set_up_spritesheets()
#	"Base" : load("res://Characters/___/Spritesheets/Base.png") # example
	}
var unique_audio = { # filled up at initialization
#	"example" : load("res://Characters/___/UniqueAudio/example.wav") # example
}
var loaded_entities = { # filled up at initialization, WIP
	
}
var floor_level
var input_state = {
		"pressed" : [],
		"just_pressed" : [],
		"just_released" : [],
	}
var dir := 0
var v_dir := 0
var wall_jump_dir := 0
var grounded := true
var soft_grounded := false
var hitstop = null # holder to influct hitstop at end of frame
var status_effect_to_remove = [] # holder to remove status effects at end of frame
var startup_cancel_flag := false # to avoid buffering attack when purposely cancelling startup

var player_ID: int # player number controlling this character, 0 for P1, 1 for P2


# character state, save these when saving and loading along with position, sprite frame and animation progress
var air_jump := 0
var wall_jump := 0
var air_dash := 0
var state = Globals.char_state.GROUND_STANDBY
var new_state = Globals.char_state.GROUND_STANDBY
var velocity := Vector2.ZERO
var facing := 1 # 1 for facing right, -1 for facing left
var velocity_previous_frame := Vector2.ZERO # needed to check for landings
var null_gravity := false # set to true during certain special states, like air dashing
var null_friction := false # set to true during certain special states, like ground dashing
var velocity_limiter = { # as % of speed, some animations limit max velocity in a certain direction, if null means no limit
	"x" : null, "up" : null, "down" : null, "x_slow" : null, "y_slow" : null
	}
var input_buffer = []
var shadow_timer := 0 # for use by unique character node
var monochrome := false

onready var current_damage_value: float = 0.0
onready var current_guard_gauge: float = 0.0
onready var current_ex_gauge: float = 10000.0
var stock_points_left

var hitcount_record = [] # record number of hits for current attack for each player, cannot do anymore hits if maxed out
var ignore_list = [] # some moves has ignore_time, after hitting will ignore that player for a number of frames, used for multi-hit specials

var launch_starting_rot := 0.0 # starting rotation when being launched, current rotation calculated using hitstun timer and this
var orig_hitstun := 0 # used to set rotation when being launched, use to count up during hitstun
var unique_data = {} # data unique for the character, stored as a dictionary
var status_effects = [] # an Array of arrays, in each Array store a enum of the status effect and a duration, can have a third data as well
var chain_combo := 0 # set to 1/2 when landing a Normal (1 for unblocked, 2 for blocked), set to 0 when starting any attack
var chain_memory = [] # appended whenever you attack, reset when starting an attack not from a chain
#var chaining := false # set to true when chaining any attack, false when starting an attack not from a chain, chained heavies loses ANTI_GUARD
var dash_cancel := false # set to true when landing a Sweetspotted Normal, set to false when starting any attack
var jump_cancel := false # set to true when landing any unblocked hit, set to false when starting any attack
var perfect_chain := false # set to true when doing a 1 frame cancel, set to false when not in active frames
var move_memory = [] # appended whenever hit by a move, cleared whenever you recover from hitstun, to incur Repeat Penalty on attacker
					# each entry is an array with [0] being the move name and [1] being the player_ID
var aerial_memory = [] # appended whenever an air attack (Normal/Special) is made, cannot do the same air attack twice in a jump
					   # reset on landing or air jump
var block_rec_cancel := false # set to true after blocking an attack, allow block recovery to be cancellable, reset on block startup
var targeted_opponent: int # player_ID of the opponent, changes whenever you land a hit on an opponent or is attacked
var has_burst := false # gain burst by ringing out opponent
#var tap_memory = [] # for double taps
var impulse_used := false

# controls
var button_up
var button_down
var button_left
var button_right
var button_jump
var button_light
var button_fierce
var button_dash
var button_block
var button_aux
var button_special
var button_unique
var button_pause

var test := false # used to test specific player, set by main game scene to just one player
var test_num := 0


# SETUP CHARACTER --------------------------------------------------------------------------------------------------

# this is run after adding this node to the tree
func init(in_player_ID, in_character, start_position, start_facing, in_palette_number):
	
	player_push_slowdown = PLAYER_PUSH_SLOWDOWN # used by Physics.gd
	
	player_ID = in_player_ID
	
	button_up = Globals.INPUTS[player_ID].up[1] # each button is an int variable enum
	button_down = Globals.INPUTS[player_ID].down[1]
	button_left = Globals.INPUTS[player_ID].left[1]
	button_right = Globals.INPUTS[player_ID].right[1]
	button_jump = Globals.INPUTS[player_ID].jump[1]
	button_light = Globals.INPUTS[player_ID].light[1]
	button_fierce = Globals.INPUTS[player_ID].fierce[1]
	button_dash = Globals.INPUTS[player_ID].dash[1]
	button_block = Globals.INPUTS[player_ID].block[1]
	button_aux = Globals.INPUTS[player_ID].aux[1]
	button_special = Globals.INPUTS[player_ID].special[1]
	button_unique = Globals.INPUTS[player_ID].unique[1]
	button_pause = Globals.INPUTS[player_ID].pause[1]
	
	# remove test character node and add the real character node
	var test_character = get_child(0) # test character node should be directly under this node
	test_character.free()
	
	UniqueCharacter = in_character
	add_child(UniqueCharacter)
	move_child(UniqueCharacter, 0)
	directory_name = "res://Characters/" + UniqueCharacter.NAME + "/"
	
	set_up_spritesheets() # scan all .png files within Spritesheet folder and add them to "spritesheets" dictionary
	set_up_unique_audio() # scan all .wav files within Audio folder and add them to "unique_audio" dictionary in UniqueCharacter node
	
	UniqueCharacter.sprite = sprite
	sprite.texture = spritesheets["BaseSprite"]
	
	# set up animators
	UniqueCharacter.Animator = $SpritePlayer
	Animator.init(sprite, sfx_over, sfx_under, directory_name + "FrameData/")
	animate("Idle")
	$ModulatePlayer.sprite = sprite
	$FadePlayer.sprite = sprite
	
	# overwrite default movement stats
	
	setup_boxes(UniqueCharacter.get_node("DefaultCollisionBox"))
	reset_jumps()
	
	# incoming start position points at the floor
	start_position.y -= $PlayerCollisionBox.rect_position.y + $PlayerCollisionBox.rect_size.y
	
	position = start_position
	floor_level = Globals.Game.middle_point.y # get floor level of stage
	
	if facing != start_facing:
		face(start_facing)
		
	palette_number = in_palette_number
	if palette_number > 1:
		loaded_palette = ResourceLoader.load(directory_name + "Palettes/" + str(palette_number) + ".png")
	palette()
	sfx_under.hide()
	sfx_over.hide()
	
	if palette_number in UniqueCharacter.PALETTE_TO_PORTRAIT:
		Globals.Game.HUD.get_node("P" + str(player_ID + 1) + "_HUDRect/Portrait").self_modulate = \
				UniqueCharacter.PALETTE_TO_PORTRAIT[palette_number]
	
	stock_points_left = Globals.Game.starting_stock_pts
	Globals.Game.damage_update(self)
	Globals.Game.guard_gauge_update(self)
	Globals.Game.ex_gauge_update(self)
	Globals.Game.stock_points_update(self)
	Globals.Game.burst_update(self)
	
# warning-ignore:return_value_discarded
	connect("SFX", Globals.Game, "_on_Character_SFX")
# warning-ignore:return_value_discarded
	connect("shadow_trail", Globals.Game, "_on_Character_shadow_trail")
# warning-ignore:return_value_discarded
	connect("projectile", Globals.Game, "_on_Character_projectile")
	
	# target a random opponent
	var players = []
	for x in Globals.player_count:
		if x != player_ID:
			players.append(x)
	targeted_opponent = players[rng_generate(players.size())]
	

func setup_boxes(ref_rect): # set up detection boxes
	
	$PlayerCollisionBox.rect_position = ref_rect.rect_position
	$PlayerCollisionBox.rect_size = ref_rect.rect_size

	# if SoftPlatformDBox detects a soft platform, that means that character is currently phasing through
	# no collision with soft platforms if so
	$SoftPlatformDBox.rect_position.x = ref_rect.rect_position.x
	$SoftPlatformDBox.rect_position.y = ref_rect.rect_position.y + ref_rect.rect_size.y - 1
	$SoftPlatformDBox.rect_size.x = ref_rect.rect_size.x
	$SoftPlatformDBox.rect_size.y = 1
	
	# if DashLandDBox detects a soft platform while DashLandDBox2 doesn't, that means that the conditions
	# are right for a dash landing, air dashes here will snap you to the soft platform
	$DashLandDBox.rect_position.x = ref_rect.rect_position.x
	$DashLandDBox.rect_position.y = ref_rect.rect_position.y + ref_rect.rect_size.y - DashLandDBox_HEIGHT
	$DashLandDBox.rect_size.x = ref_rect.rect_size.x
	$DashLandDBox.rect_size.y = DashLandDBox_HEIGHT
	
	$DashLandDBox2.rect_position.x = ref_rect.rect_position.x
	$DashLandDBox2.rect_position.y = ref_rect.rect_position.y + ref_rect.rect_size.y - (DashLandDBox_HEIGHT + 1)
	$DashLandDBox2.rect_size.x = ref_rect.rect_size.x
	$DashLandDBox2.rect_size.y = 1
	
	$WallJumpLeftDBox.rect_size.x = WallJumpDBox_WIDTH
	$WallJumpLeftDBox.rect_position.x = ref_rect.rect_position.x - $WallJumpLeftDBox.rect_size.x
	$WallJumpLeftDBox.rect_position.y = ref_rect.rect_position.y
	$WallJumpLeftDBox.rect_size.y = ref_rect.rect_size.y
	
	$WallJumpRightDBox.rect_size.x = WallJumpDBox_WIDTH
	$WallJumpRightDBox.rect_position.x = ref_rect.rect_position.x + ref_rect.rect_size.x
	$WallJumpRightDBox.rect_position.y = ref_rect.rect_position.y
	$WallJumpRightDBox.rect_size.y = ref_rect.rect_size.y


# change palette and reset monochrome
func palette():
	
	monochrome = false
	
	if palette_number <= 1:
		sprite.material = null
		sfx_over.material = null
		sfx_under.material = null
	else:
		sprite.material = ShaderMaterial.new()
		sprite.material.shader = Globals.loaded_palette_shader
		sprite.material.set_shader_param("swap", loaded_palette)
		sfx_over.material = ShaderMaterial.new()
		sfx_over.material.shader = Globals.loaded_palette_shader
		sfx_over.material.set_shader_param("swap", loaded_palette)
		sfx_under.material = ShaderMaterial.new()
		sfx_under.material.shader = Globals.loaded_palette_shader
		sfx_under.material.set_shader_param("swap", loaded_palette)
		
# fill up the "spritesheets" dictionary with spritesheets in the "Spritesheets" folder loaded and ready
func set_up_spritesheets():
	# open the Spritesheet folder and get the filenames of all files in it
	var directory = Directory.new()
	if directory.open(directory_name + "Spritesheets/") == OK:
		directory.list_dir_begin()
		var file_name = directory.get_next()
		while file_name != "":
			# load all needed files and add them to the dictionary
			if file_name.ends_with(".png.import"):
				var file_name2 = file_name.get_file().trim_suffix(".png.import")
				spritesheets[file_name2] = ResourceLoader.load(directory_name + "Spritesheets/" + file_name2 + ".png")
			file_name = directory.get_next()
	else: print("Error: Cannot open Spritesheets folder for character")
	
func set_up_unique_audio():
	var directory = Directory.new()
	if directory.open(directory_name + "UniqueAudio/") == OK:
		directory.list_dir_begin()
		var file_name = directory.get_next()
		while file_name != "":
			# load all needed files and add them to the dictionary
			if file_name.ends_with(".wav.import"):
				var file_name2 = file_name.get_file().trim_suffix(".wav.import")
				unique_audio[file_name2] = \
						ResourceLoader.load(directory_name + "UniqueAudio/" + file_name2 + ".wav")
			file_name = directory.get_next()
	else: print("Error: Cannot open UniqueAudio folder for character")
	
# TESTING --------------------------------------------------------------------------------------------------

# for testing only
func test1():
	if $HitStopTimer.is_running():
		test0()
	$TestNode2D/TestLabel.text = $TestNode2D/TestLabel.text + "old state: " + Globals.char_state_to_string(state) + \
			"\n" + Animator.current_animation + " > " + Animator.to_play_animation + "  time: " + str(Animator.time) + "\n"
			
func test0():
	var string_input_buffer = []
	for buffered_input in input_buffer:
		var string_buffered_input = [Globals.input_to_string(buffered_input[0], player_ID), buffered_input[1]]
		string_input_buffer.append(string_buffered_input)
	$TestNode2D/TestLabel.text = "buffer: " + str(string_input_buffer) + "\n"
	
			
func test2():
	$TestNode2D/TestLabel.text = $TestNode2D/TestLabel.text + "new state: " + Globals.char_state_to_string(state) + \
			"\n" + Animator.current_animation + " > " + Animator.to_play_animation + "  time: " + str(Animator.time) + \
			"\n" + str(velocity) + "  grounded: " + str(grounded) + \
			"\nchain_memory: " + str(chain_memory) + " " + str(chain_combo) + " " + str(perfect_chain) + "\n" + \
			str(input_buffer) + "\n" + str(current_guard_gauge) + " " + \
			str(current_ex_gauge)
			
			
func _process(_delta):
	if Globals.debug_mode:
		$PlayerCollisionBox.show()
#		$SoftPlatformDBox.show()
#		$DashLandDBox.show()
#		$DashLandDBox2.show()
#		$WallJumpLeftDBox.show()
#		$WallJumpRightDBox.show()
	else:
		$PlayerCollisionBox.hide()
#		$SoftPlatformDBox.hide()
#		$DashLandDBox.hide()
#		$DashLandDBox2.hide()
#		$WallJumpLeftDBox.hide()
#		$WallJumpRightDBox.hide()

	if Globals.watching_replay:
		if Globals.Game.get_node("ReplayControl").show_hitbox:
			$PlayerCollisionBox.show()
		else:
			$PlayerCollisionBox.hide()

	if test:
		if Globals.debug_mode2:
			$TestNode2D.show()
		else:
			$TestNode2D.hide()
			
			
func stimulate(new_input_state):
		
	input_state = new_input_state # so that I can use it in other functions
	
#	for button in input_state.just_released:
#		tap_memory.append([button, TAP_MEMORY_DURATION])
		
	
			
	if Globals.editor and Input.is_action_just_pressed("sound_test") and test:
		$ModulatePlayer.play("red_burst")
		
#		var test_pt = Detection.ground_finder(position, facing, Vector2(100, 50), Vector2(100, 100))
#		if test_pt: emit_signal("SFX", "HitsparkB", "HitsparkB", test_pt, {})
		
		match test_num % 3:
			0:
				play_audio("kill1", {"vol" : -10})
			1:
				play_audio("kill2", {"vol" : -12})
			2:
				play_audio("kill3", {"vol" : -12, "bus" : "Reverb"})

		test_num += 1
		
		change_guard_gauge_percent(-1.0)
		
		
# PAUSING --------------------------------------------------------------------------------------------------
		
	if button_pause in input_state.just_pressed:
		Globals.pausing = true
	elif button_pause in input_state.just_released:
		Globals.pausing = false

# FRAMESKIP DURING HITSTOP --------------------------------------------------------------------------------------------------
	# while buffering all inputs
	
	hitstop = null
	status_effect_to_remove = []
	
	$HitStopTimer.stimulate() # advancing the hitstop timer at start of frame allow for one frame of knockback before hitstop
	# will be needed for multi-hit moves
	$RespawnTimer.stimulate()
	
	if !$RespawnTimer.is_running():
		if $HitStopTimer.is_running():
			buffer_actions() # can still buffer buttons during hitstop
		else:
			stimulate2()
		


func stimulate2(): # only ran if not in hitstop
	
# START OF FRAME --------------------------------------------------------------------------------------------------

	if state == Globals.char_state.DEAD:
		respawn()

	dir = 0
	v_dir = 0
	
	if abs(velocity.x) < 1.0: # do this at start too
		velocity.x = 0.0
	if abs(velocity.y) < 1.0:
		velocity.y = 0.0
		
	ignore_list_progress_timer()
	process_status_effects_timer() # remove expired status effects before running hit detection since that can add effects
	
	# clearing move memory, has a time between hitstun/blockstun ending and move memory being cleared
	if move_memory.size() > 0 and !$HitStunGraceTimer.is_running():
		move_memory = []

	# regen/degen GG
	if move_memory.size() == 0:
		if current_guard_gauge < 0 and !is_blocking():
			var guard_gauge_regen = UniqueCharacter.GUARD_GAUGE_REGEN_RATE * abs(GUARD_GAUGE_FLOOR) * Globals.FRAME
			if query_status_effect(Globals.status_effect.POS_FLOW):
				guard_gauge_regen *= POS_FLOW_REGEN_MOD # increased regen during positive flow
			guard_gauge_regen = round(guard_gauge_regen)
			current_guard_gauge = min(0, current_guard_gauge + guard_gauge_regen) # don't use change_guard_gauge() since it stops at 0
			Globals.Game.guard_gauge_update(self)
		elif current_guard_gauge > 0:
			var guard_gauge_degen = UniqueCharacter.GUARD_GAUGE_DEGEN_RATE * GUARD_GAUGE_CEIL * Globals.FRAME
			guard_gauge_degen = round(guard_gauge_degen)
			current_guard_gauge = max(0, current_guard_gauge + guard_gauge_degen)
			Globals.Game.guard_gauge_update(self)
		
	# regen EX Gauge when standing still
	if !Globals.Game.input_lock and state == Globals.char_state.GROUND_STANDBY:
		change_ex_gauge(EX_GAUGE_REGEN_RATE * Globals.FRAME)
		

	if is_on_ground($SoftPlatformDBox, velocity):
		grounded = true
		reset_jumps() # reset air jumps and air dashes here
	else:
		grounded = false
		
	if is_on_soft_ground($SoftPlatformDBox, velocity):
		soft_grounded = true
	else:
		soft_grounded = false
		
	
	# drain EX Gauge when air blocking
#	if !grounded and is_blocking():
#		var ex_gauge_drain = round(UniqueCharacter.AIR_BLOCK_DRAIN_RATE * Globals.FRAME)
#		change_ex_gauge(-ex_gauge_drain)
#		if current_ex_gauge <= 0.0:
#			match Animator.current_animation:
#				"AirBlock":
#					animate("FallTransit")
#	elif $ModulatePlayer.is_playing() and $ModulatePlayer.query_current(["EX_block_flash", "EX_block_flash2"]):
#		reset_modulate()
		
	if !is_attacking():
		reset_cancels()

	startup_cancel_flag = false # to cancel startup without incurring auto-buffer

# CAPTURE DIRECTIONAL INPUTS --------------------------------------------------------------------------------------------------
	
	if button_right in input_state.pressed:
		dir += 1
	if button_left in input_state.pressed:
		dir -= 1
	if button_up in input_state.pressed:
		v_dir -= 1
	if button_down in input_state.pressed:
		v_dir += 1
		
# LEFT/RIGHT BUTTON --------------------------------------------------------------------------------------------------

	if dir != 0:
		match state:
			
	# GROUND MOVEMENT --------------------------------------------------------------------------------------------------
	
			Globals.char_state.GROUND_STANDBY:
				if dir != facing: # flipping over
					face(dir)
					animate("RunTransit") # restart run animation
				 # if not in run animation, do run animation
				if !Animator.query(["Run", "RunTransit"]):
						animate("RunTransit")
						
				velocity.x = lerp(velocity.x, dir * UniqueCharacter.SPEED, UniqueCharacter.ACCELERATION)
	
	# AIR STRAFE --------------------------------------------------------------------------------------------------
		# can air strafe during aerials at reduced speed
	
			Globals.char_state.AIR_STANDBY, Globals.char_state.AIR_ATK_STARTUP, Globals.char_state.AIR_ATK_ACTIVE, \
					Globals.char_state.AIR_ATK_RECOVERY, Globals.char_state.AIR_C_RECOVERY, \
					Globals.char_state.AIR_BLOCK:
				
				if !grounded:
					if state == Globals.char_state.AIR_STANDBY and dir != facing: # flipping over
						face(dir)
					
					# reduce air_strafe_speed and air_strafe_limit during AIR_ATK_STARTUP
					var air_strafe_speed_temp = UniqueCharacter.AIR_STRAFE_SPEED
					var air_strafe_limit_temp = UniqueCharacter.AIR_STRAFE_LIMIT
					if state != Globals.char_state.AIR_STANDBY:
						air_strafe_speed_temp *= AERIAL_STRAFE_MOD
						air_strafe_limit_temp *= AERIAL_STRAFE_MOD
					
					if abs(velocity.x + (dir * air_strafe_speed_temp)) > abs(velocity.x): # if speeding up
						if abs(velocity.x) < UniqueCharacter.SPEED * air_strafe_limit_temp: # only allow strafing if below speed limit
							velocity.x += dir * air_strafe_speed_temp
					else: # slowing down
						velocity.x += dir * air_strafe_speed_temp
					
	# LEFT/RIGHT DI --------------------------------------------------------------------------------------------------
					
			_:
				if $HitStunTimer.is_running() and current_guard_gauge > 0 and get_damage_percent() < 1.0:
					# no changing facing
					
					# DDI speed and speed limit depends on guard gauge
					var DDI_speed = lerp(DDI_SIDE_MAX * DI_MIN_MOD, DDI_SIDE_MAX, get_guard_gauge_percent_above())
					var DDI_speed_limit = lerp(MAX_DDI_SIDE_SPEED * DI_MIN_MOD, MAX_DDI_SIDE_SPEED, get_guard_gauge_percent_above())
					if abs(velocity.x + (dir * DDI_speed)) > abs(velocity.x): # if speeding up
						if abs(velocity.x) < DDI_speed_limit: # only allow DIing if below speed limit
							# WIP, speed limit depends on Guard Gauge
							velocity.x += dir * DDI_speed
					else: # slowing down
						velocity.x += dir * DDI_speed
						
	
	# TURN AT START OF CERTAIN MOVES --------------------------------------------------------------------------------------------------

		if facing != dir:
				
			if check_quick_cancel(true) and !Globals.atk_attr.NO_TURN in query_atk_attr():
				face(dir)
				
		# quick impulse
		if state == Globals.char_state.GROUND_ATK_STARTUP and !impulse_used and\
				Animator.time <= QUICK_CANCEL_TIME:
			impulse_used = true
			var move_name = Animator.to_play_animation.trim_suffix("Startup")
			if move_name in UniqueCharacter.MOVE_DATABASE:
				if !Globals.atk_attr.NO_IMPULSE in UniqueCharacter.MOVE_DATABASE[move_name].atk_attr: # ground impulse
					velocity.x = dir * UniqueCharacter.SPEED * IMPULSE_MOD
					emit_signal("SFX", "GroundDashDust", "DustClouds", get_feet_pos(), {"facing":dir, "grounded":true})	

	# IMPULSE --------------------------------------------------------------------------------------------------
	
#	if button_left in input_state.pressed or button_right in input_state.pressed: # don't use dir for this one...
#		if new_state == Globals.char_state.GROUND_ATK_STARTUP and Animator.time == QUICK_CANCEL_TIME: # only possible on frame 1
#			var move_name = Animator.to_play_animation.trim_suffix("Startup")
#			if move_name in UniqueCharacter.MOVE_DATABASE and \
#					!Globals.atk_attr.NO_IMPULSE in UniqueCharacter.MOVE_DATABASE[move_name].atk_attr: # ground impulse
#				if button_left in input_state.just_pressed or button_right in input_state.just_pressed:
#					velocity.x = facing * UniqueCharacter.SPEED * PERFECT_IMPULSE_MOD
#					emit_signal("SFX", "SpecialDust", "DustClouds", get_feet_pos(), {"facing":facing, "grounded":true})
#				else:
#					velocity.x = facing * UniqueCharacter.SPEED * IMPULSE_MOD
#					emit_signal("SFX", "GroundDashDust", "DustClouds", get_feet_pos(), {"facing":facing, "grounded":true})


# DOWN BUTTON --------------------------------------------------------------------------------------------------
	
	if button_down in input_state.pressed:
		
		match state:
			
		# TO CROUCH --------------------------------------------------------------------------------------------------
		
			Globals.char_state.GROUND_STANDBY:
				animate("CrouchTransit")
				
		# CROUCH CANCELS FOR CHAINDASHING --------------------------------------------------------------------------------------------------
			# crouch to cancel ground dash recovery
	
			Globals.char_state.GROUND_C_RECOVERY:
				if Animator.query(["SoftLanding", "HardLanding"]):
					animate("Crouch")
				elif Animator.query(["DashBrake"]):
					if Globals.trait.CHAIN_DASH in query_traits():
						animate("CrouchTransit")
				else:
					animate("CrouchTransit")

		# FASTFALL --------------------------------------------------------------------------------------------------
			# cannot fastfall right after jumping
			
			Globals.char_state.AIR_STANDBY:
				if !Animator.query(["JumpTransit2", "JumpTransit3"]):


					if Settings.dj_fastfall[player_ID] == 0 or \
						(Settings.dj_fastfall[player_ID] == 1 and button_jump in input_state.pressed):
#						if Settings.dt_fastfall[player_ID] == 1:
#							tap_memory.append([button_down, 2]) # allow you to double tap then hold down
					
						velocity.y = lerp(velocity.y, GRAVITY * Globals.FRAME * UniqueCharacter.TERMINAL_VELOCITY_MOD * \
								UniqueCharacter.FASTFALL_MOD, 0.3)
						if Animator.query(["FallTransit"]): # go straight to fall animation
							animate("Fall")
				
						# fastfall reduce horizontal speed limit
						if velocity.x < -UniqueCharacter.SPEED * 0.7:
							velocity.x = lerp(velocity.x, -UniqueCharacter.SPEED * 0.7, 0.5)
						elif velocity.x > UniqueCharacter.SPEED * 0.7:
							velocity.x = lerp(velocity.x, UniqueCharacter.SPEED * 0.7, 0.5)
							
			Globals.char_state.AIR_STARTUP: # can cancel air jump startup to fastfall
				if Settings.dj_fastfall[player_ID] == 0 or \
					(Settings.dj_fastfall[player_ID] == 1 and button_jump in input_state.pressed):
						
					if !Animator.query(["AirJumpTransit2"]):
						animate("Fall")
					
						
			Globals.char_state.AIR_ATK_RECOVERY: # fastfall cancel from aerial hits
				if Settings.dj_fastfall[player_ID] == 0 or \
					(Settings.dj_fastfall[player_ID] == 1 and button_jump in input_state.pressed):
						
					if test_fastfall_cancel():
						animate("Fall")

# BLOCK BUTTON --------------------------------------------------------------------------------------------------	
	
#	if UniqueCharacter.STYLE == 0:
	if button_block in input_state.pressed:
		match state:
			Globals.char_state.GROUND_STANDBY:
				animate("BlockStartup")
			Globals.char_state.GROUND_C_RECOVERY:
				if Animator.query(["DashBrake"]): # cannot block out of ground dash unless you have the DASH_BLOCK trait
					if Globals.trait.DASH_BLOCK in query_traits():
						animate("BlockStartup")
				else:
					animate("BlockStartup")
			Globals.char_state.AIR_STANDBY:
#				if current_ex_gauge >= UniqueCharacter.AIR_BLOCK_DRAIN_RATE * 0.5:
				animate("AirBlockStartup")
				$VarJumpTimer.stop()
			Globals.char_state.AIR_C_RECOVERY:
				if !Animator.query_current(["AirDashBrake"]): # cannot air block out of air dash
#					if current_ex_gauge >= UniqueCharacter.AIR_BLOCK_DRAIN_RATE * 0.5:
					animate("AirBlockStartup")
					$VarJumpTimer.stop()
			

# SPECIAL/EX BUTTON --------------------------------------------------------------------------------------------------	

	if !query_status_effect(Globals.status_effect.RESPAWN_GRACE): # no special/ex/supers during respawn grace
		if button_special in input_state.just_released and !button_block in input_state.pressed:
			if !$SpecialTimer.is_running() and !$SuperTimer.is_running():
				$EXTimer.stop()
				$SpecialTimer.time = SpecialTimer_WAIT_TIME
			else: # double/triple tab Special, prep for Super
				$SpecialTimer.stop()
				$SuperTimer.time = SpecialTimer_WAIT_TIME
				
#		if button_EX in input_state.just_released:
#			$SpecialTimer.stop()
#			$SuperTimer.stop()
#			$EXTimer.time = SpecialTimer_WAIT_TIME


# --------------------------------------------------------------------------------------------------

	UniqueCharacter.stimulate() # some holdable buttons can have effect unique to the character
	
	buffer_actions()
	test0()
	
	if input_buffer.size() > 0:
		process_input_buffer()

# CHECK DROPS AND LANDING ---------------------------------------------------------------------------------------------------
	
	if !grounded:
		match new_state:
			Globals.char_state.GROUND_STANDBY, Globals.char_state.CROUCHING, Globals.char_state.GROUND_C_RECOVERY, \
					Globals.char_state.GROUND_STARTUP, Globals.char_state.GROUND_ACTIVE, Globals.char_state.GROUND_RECOVERY, \
					Globals.char_state.GROUND_ATK_STARTUP, Globals.char_state.GROUND_ATK_ACTIVE, Globals.char_state.GROUND_ATK_RECOVERY, \
					Globals.char_state.GROUND_FLINCH_HITSTUN, Globals.char_state.GROUND_BLOCK, Globals.char_state.GROUND_BLOCKSTUN:
				check_drop()
				
	else: # just in case, normally called when physics.gd runs into a floor
		match new_state:
			Globals.char_state.AIR_STANDBY, Globals.char_state.AIR_C_RECOVERY, Globals.char_state.AIR_STARTUP, \
					Globals.char_state.AIR_ACTIVE, Globals.char_state.AIR_RECOVERY, Globals.char_state.AIR_ATK_STARTUP, \
					Globals.char_state.AIR_ATK_ACTIVE, Globals.char_state.AIR_ATK_RECOVERY, Globals.char_state.AIR_FLINCH_HITSTUN, \
					Globals.char_state.LAUNCHED_HITSTUN, Globals.char_state.AIR_BLOCK, Globals.char_state.AIR_BLOCKSTUN:
				check_landing()

# GRAVITY --------------------------------------------------------------------------------------------------

	var gravity_temp
	
	if $HitStunTimer.is_running(): # fix and lower gravity during hitstun
		gravity_temp = HITSTUN_GRAV_MOD * GRAVITY
	else:
		gravity_temp = GRAVITY * UniqueCharacter.GRAVITY_MOD # each character are affected by gravity differently out of hitstun
	
	if $VarJumpTimer.is_running() and (button_jump in input_state.pressed or button_up in input_state.pressed):
		# variable jump system reduces gravity if you hold down the jump button
		gravity_temp *= VAR_JUMP_GRAV_MOD

	if !grounded and (abs(velocity.y) < PEAK_DAMPER_LIMIT): # reduce gravity at peak of jump
		gravity_temp = lerp(gravity_temp, gravity_temp * PEAK_DAMPER_MOD, \
				(PEAK_DAMPER_LIMIT - abs(velocity.y)) / float(PEAK_DAMPER_LIMIT))	
		# transit from jump to fall animation
		if Animator.query_to_play(["Jump"]): # don't use query() for this one
			animate("FallTransit")

	if !null_gravity and !grounded: # gravity only pulls you if you are in the air
		
		if $HitStunTimer.is_running():
			if current_guard_gauge > 0 and get_damage_percent() < 1.0: # up/down DI, depends on Guard Gauge
				if v_dir == -1: # DIing upward
					gravity_temp *= lerp((GDI_UP_MAX - 1.0) * DI_MIN_MOD + 1, GDI_UP_MAX, get_guard_gauge_percent_above())
				elif v_dir == 1: # DIing downward
					gravity_temp *= lerp((GDI_DOWN_MAX - 1.0) * DI_MIN_MOD + 1, GDI_DOWN_MAX, get_guard_gauge_percent_above())
		else:
			if velocity.y > 0: # some characters may fall at different speed compared to going up
				gravity_temp *= UniqueCharacter.FALL_GRAV_MOD
				if state == Globals.char_state.AIR_BLOCK: # air blocking reduce gravity
					gravity_temp *= AIRBLOCK_GRAV_MOD
				
		velocity.y += gravity_temp * Globals.FRAME
		
	# terminal velocity downwards
	var terminal
	if $HitStunTimer.is_running(): # during hitstun, only slowdown within a certain range
		terminal = GRAVITY * Globals.FRAME * HITSTUN_TERMINAL_VELOCITY_MOD
		
		if velocity.y < terminal * TERMINAL_THRESHOLD and velocity.y > terminal:
			velocity.y = lerp(velocity.y, terminal, 0.75)
			
	else:
		terminal = GRAVITY * Globals.FRAME * UniqueCharacter.TERMINAL_VELOCITY_MOD
	
		if state == Globals.char_state.AIR_STANDBY and button_down in input_state.pressed:
			terminal *= UniqueCharacter.FASTFALL_MOD # increase terminal velocity when fastfalling
		if state == Globals.char_state.AIR_BLOCK: # air blocking reduce terminal velocity
			terminal *= AIRBLOCK_TERMINAL_MOD

		if velocity.y > terminal:
			velocity.y = lerp(velocity.y, terminal, 0.75)
		

# FRICTION/AIR RESISTANCE AND TRIGGERED ANIMATION CHANGES ----------------------------------------------------------
	# place this at end of frame later
	# for triggered animation changes, use query_to_play() instead
	# query() check animation at either start/end of frame, query_to_play() only check final animation
	
	var friction_this_frame
	var air_res_this_frame
	
	if !$HitStunTimer.is_running():
		friction_this_frame = UniqueCharacter.FRICTION
		air_res_this_frame = UniqueCharacter.AIR_RESISTANCE
	else:
		friction_this_frame = HITSTUN_FRICTION
		air_res_this_frame = HITSTUN_AIR_RES
	
	match state:
		Globals.char_state.GROUND_STANDBY:
			if dir == 0: # if not moving
				# if in run animation, do brake animation
				if Animator.query_to_play(["Run", "RunTransit"]):
					animate("Brake")
			else: # no friction when moving
				friction_this_frame = 0
			
		Globals.char_state.CROUCHING:
			if !button_down in input_state.pressed and Animator.query_to_play(["Crouch"]):
				animate("CrouchReturn") # stand up
	
		Globals.char_state.GROUND_STARTUP:
			friction_this_frame *= 0.0
				
		Globals.char_state.GROUND_C_RECOVERY:
			if Animator.query(["HardLanding"]): # lower friction when hardlanding?
				friction_this_frame *= 0.5

		Globals.char_state.AIR_STANDBY:
			# just in case, fall animation if falling downwards without slowing down
			if velocity.y > 0 and Animator.query_to_play(["Jump"]):
				animate("FallTransit")
	
		Globals.char_state.AIR_STARTUP, Globals.char_state.AIR_RECOVERY:
			# air dash into wall, stop instantly
			if Animator.query_to_play(["AirDash", "AirDashD", "AirDashU"]) and is_against_wall($PlayerCollisionBox, $SoftPlatformDBox, facing):
				animate("FallTransit")
				if Animator.current_animation == "AirDashTransit": # to fix a bug when touching a wall during AirDashTransit > AirDash
					UniqueCharacter.consume_one_air_dash() # reduce air_dash count by 1

		Globals.char_state.GROUND_BLOCK:
#			if UniqueCharacter.STYLE == 0:
			if !button_block in input_state.pressed and Animator.query_to_play(["Block"]):
				if !block_rec_cancel:
					animate("BlockRecovery")
				else:
					animate("BlockCRecovery")
#			else:
#				if !button_dash in input_state.pressed and Animator.query_to_play(["Block"]):
#					if !block_rec_cancel:
#						animate("BlockRecovery")
#					else:
#						animate("BlockCRecovery")	
			
		Globals.char_state.GROUND_BLOCKSTUN:
			if !$BlockStunTimer.is_running():
				animate("BlockstunReturn")
			
		Globals.char_state.AIR_BLOCK:
#			if UniqueCharacter.STYLE == 0:
			if !button_block in input_state.pressed and Animator.query_to_play(["AirBlock"]):
				if !block_rec_cancel:
					animate("AirBlockRecovery")
				else:
					animate("AirBlockCRecovery")
			air_res_this_frame *= 1.5
#			else:
#				if !button_dash in input_state.pressed and Animator.query_to_play(["AirBlock"]):
#					if !block_rec_cancel:
#						animate("AirBlockRecovery")
#					else:
#						animate("AirBlockCRecovery")
#				air_res_this_frame *= 1.5
			
		Globals.char_state.AIR_BLOCKSTUN:
			if !$BlockStunTimer.is_running():
				animate("AirBlockstunReturn")
			air_res_this_frame *= 1.5

		Globals.char_state.AIR_ATK_STARTUP:
			air_res_this_frame *= 0.0
			friction_this_frame *= 0.75 # lower friction when landing while doing an aerial
			
		Globals.char_state.GROUND_FLINCH_HITSTUN:
			# when out of hitstun, recover
			if !$HitStunTimer.is_running():
				if Animator.query_to_play(["FlinchA"]):
					animate("FlinchAReturn")
				elif Animator.query_to_play(["FlinchB"]):
					animate("FlinchBReturn")
				$ModulatePlayer.play("unflinch_flash")
			else:
				friction_this_frame *= 0.5 # lower friction during flinch hitstun
					
		Globals.char_state.AIR_FLINCH_HITSTUN:
			# when out of hitstun, recover
			if velocity.y > HITSTUN_FALL_THRESHOLD and position.y > floor_level:
				velocity.y = HITSTUN_FALL_THRESHOLD # limit downward velocity during air flinch
			if !$HitStunTimer.is_running():
				if Animator.query_to_play(["AirFlinchA"]):
					animate("AirFlinchAReturn")
				elif Animator.query_to_play(["AirFlinchB"]):
					animate("AirFlinchBReturn")
				$ModulatePlayer.play("unflinch_flash")
		
		Globals.char_state.LAUNCHED_HITSTUN:
			# when out of hitstun, recover
			if !$HitStunTimer.is_running() and Animator.query_to_play(["Launch"]):
				animate("FallTransit")
				$ModulatePlayer.play("tech_flash")
				play_audio("bling4", {"vol" : -15, "bus" : "PitchDown"})
			elif !Animator.query_to_play(["HardLanding"]): # only bounce if not teching next frame
				friction_this_frame *= 0.25 # lower friction during launch hitstun
				# WIP, bounce off surfaces
				
# warning-ignore:unassigned_variable
				var test_velocity: Vector2 # get higher of velocities between this frame and previous frame for checking
				# this is needed as velocity resets to zero on hitting a wall, but if using only velocity previous frame,
				# it wouldn't bounce if it hits the wall on the 1st frame
				if abs(velocity.x) > abs(velocity_previous_frame.x):
					test_velocity.x = velocity.x
				else:
					test_velocity.x = velocity_previous_frame.x
				if abs(velocity.y) > abs(velocity_previous_frame.y):
					test_velocity.y = velocity.y
				else:
					test_velocity.y = velocity_previous_frame.y
				
				
				if grounded:
					velocity.y = -test_velocity.y * 0.75
					if abs(velocity.y) > BOUNCE_DUST_THRESHOLD: # release bounce dust if fast enough towards ground
						emit_signal("SFX", "BounceDust", "DustClouds", get_feet_pos(), {"grounded":true})
						play_audio("rock3", {"vol" : -10,})
				elif is_against_wall($PlayerCollisionBox, $SoftPlatformDBox, sign(test_velocity.x)):
					velocity.x = -test_velocity.x * 0.75
					if abs(velocity.x) > BOUNCE_DUST_THRESHOLD: # release bounce dust if fast enough
						emit_signal("SFX", "BounceDust", "DustClouds", position + sign(test_velocity.x) * \
								Vector2($PlayerCollisionBox.rect_size.x / 2, 0), {"facing":sign(test_velocity.x), "rot":-PI/2})
						play_audio("rock3", {"vol" : -10,})
				elif is_against_ceiling($PlayerCollisionBox, $SoftPlatformDBox):
					velocity.y = -test_velocity.y * 0.75
					if abs(velocity.y) > BOUNCE_DUST_THRESHOLD: # release bounce dust if fast enough
						emit_signal("SFX", "BounceDust", "DustClouds", position + Vector2(0, $PlayerCollisionBox.rect_position.y), \
								{"rot":PI})
						play_audio("rock3", {"vol" : -10,})
	
	
# APPLY FRICTION/AIR RESISTANCE --------------------------------------------------------------------------------------------------

	# apply friction if on ground
	if grounded and !null_friction:
		velocity.x = lerp(velocity.x, 0, friction_this_frame)
			
	# apply air resistance if in air
	if !grounded and !null_gravity: # null gravity means no air resistance as well
		velocity.x = lerp(velocity.x, 0, air_res_this_frame)
	

# --------------------------------------------------------------------------------------------------
	
	# finally move the damn thing

	# limit velocity if velocity limiter is not null, "if velocity_limiter.x" will not pass if it is zero!
	if velocity_limiter.x != null:
		velocity.x = clamp(velocity.x, -velocity_limiter.x * UniqueCharacter.SPEED, velocity_limiter.x * UniqueCharacter.SPEED)
	if velocity_limiter.up != null and velocity.y < -velocity_limiter.up * UniqueCharacter.SPEED:
		velocity.y = -velocity_limiter.up * UniqueCharacter.SPEED
	if velocity_limiter.down != null and velocity.y > velocity_limiter.down * UniqueCharacter.SPEED:
		velocity.y = velocity_limiter.down * UniqueCharacter.SPEED
	if velocity_limiter.x_slow != null:
		velocity.x = lerp(velocity.x, 0, velocity_limiter.x_slow) # x_slow is around 0.03?
	if velocity_limiter.y_slow != null:
		velocity.y = lerp(velocity.y, 0, velocity_limiter.y_slow) # y_slow is around 0.03?
	
	process_VDI()
	
	if !$HitStopTimer.is_running() and state == Globals.char_state.LAUNCHED_HITSTUN:
		launch_trail() # do launch trail before moving
		
	velocity.x = round(velocity.x) # makes it more consistent, may reduce rounding errors across platforms hopefully?
	velocity.y = round(velocity.y)
	
	if abs(velocity.x) < 5.0:
		velocity.x = 0.0
	if abs(velocity.y) < 5.0:
		velocity.y = 0.0
	
	velocity_previous_frame = velocity # needed to check for hard landings
	var results = character_move($PlayerCollisionBox, $SoftPlatformDBox, velocity, check_ledge_stop())
	velocity = results[0]
	if results[1]: check_landing()
		
	# must process hitbox/hurtboxes after calculation (since need to use to_play_animation after it is calculated)
	# however, must process before running the animation and advancing the time counter
	# must process after moving the character as well or will misalign
	
	# ends here, process hit detection in game scene, afterwards game scene will call stimulate_after() to finish up
	

func stimulate_after(): # called by game scene after hit detection to finish up the frame
	
	test1()
	
#	progress_tap_memory()
	
	for effect in status_effect_to_remove: # remove certain status effects at end of frame after hit detection
										   # useful for status effects that are removed after being hit
		remove_status_effect(effect)
	
	if !$RespawnTimer.is_running():
	
		process_status_effects_visual()
		
		if !$HitStopTimer.is_running():
			
			# render the next frame, this update the time!
			$SpritePlayer.stimulate()
			$FadePlayer.stimulate() # ModulatePlayer ignore hitstop but FadePlayer doesn't
			
			if !hitstop: # timers do not run on exact frame frame hitstop starts
				$VarJumpTimer.stimulate()
				$HitStunTimer.stimulate()
				$BlockStunTimer.stimulate()
				$PBlockTimer.stimulate()
				$PBlockCDTimer.stimulate()
				if !$HitStunTimer.is_running() and !$BlockStunTimer.is_running():
					$HitStunGraceTimer.stimulate()
				
				# spike protection before 70% damage
				if get_damage_percent() < 0.7 and velocity.y >= HITSTUN_FALL_THRESHOLD and position.y > floor_level:
					match state:
						Globals.char_state.AIR_FLINCH_HITSTUN: # hitstun decay instantly if falling too fast during air flinch when too low
							$HitStunTimer.stop()
						Globals.char_state.LAUNCHED_HITSTUN:
							$HitStunTimer.stimulate()
							$HitStunTimer.stimulate() # hitstun decay thrice as fast if falling too fast during launch when too low
				
			
			# do shadow trails
			UniqueCharacter.shadow_trail()
			
			# spin character during launch, be sure to do this after SpritePlayer since rotation is reset at start of each animation
			if !$HitStopTimer.is_running() and state == Globals.char_state.LAUNCHED_HITSTUN:
				sprite.rotation = launch_starting_rot - facing * (orig_hitstun - $HitStunTimer.time) * \
						LAUNCH_ROT_SPEED * Globals.FRAME
		
		# start hitstop timer at end of frame after SpritePlayer.stimulate() by setting hitstop to a number other than null for the frame
		# new hitstops override old ones
		if hitstop:
			$HitStopTimer.time = hitstop
			
		$ModulatePlayer.stimulate() # modulate animations continue even in hitstop
		# advance special input timers
		$SpecialTimer.stimulate()
		$EXTimer.stimulate()
		$SuperTimer.stimulate()
		
	test2()
		
		
# BUFFERING BUTTONs --------------------------------------------------------------------------------------------------	
	# directional keys, Block, Special and EX buttons should NEVER be buffered, since they can just be held down
	
func buffer_actions():
	
	# WIP, set Special/EX/Super timers here as well
	
	if button_up in input_state.just_pressed:
		input_buffer.append([button_up, Settings.input_buffer_time[player_ID]])
	if button_dash in input_state.just_pressed:
		input_buffer.append([button_dash, Settings.input_buffer_time[player_ID]])
		
	if !query_status_effect(Globals.status_effect.RESPAWN_GRACE): # no attacking during respawn grace
		if button_light in input_state.just_pressed:
			input_buffer.append([button_light, Settings.input_buffer_time[player_ID]])
		if button_fierce in input_state.just_pressed:
			input_buffer.append([button_fierce, Settings.input_buffer_time[player_ID]])
		if button_aux in input_state.just_pressed:
			input_buffer.append([button_aux, Settings.input_buffer_time[player_ID]])
	
	if input_buffer.size() > 0:
		capture_combinations() # look for combinations in input buffer, erase buttons used in the combinations

	if button_jump in input_state.just_pressed:
		input_buffer.push_front([button_jump, Settings.input_buffer_time[player_ID]])
		
# SPECIAL ACTIONS --------------------------------------------------------------------------------------------------
		
func capture_combinations():
	
	# instant air dash, place at back
	combination(button_jump, button_dash, "InstaAirDash", null, true)
	
	combination(button_block, button_aux, "Burst") # can quick_cancel from block/unique startup
			
	UniqueCharacter.capture_combinations()


func combination_single(button1, action, back = false): # useful for Special/EX/Super Moves
	if button1 in input_state.just_pressed:
		if !back:
			input_buffer.push_front([action, Settings.input_buffer_time[player_ID]])
		else:
			input_buffer.append([action, Settings.input_buffer_time[player_ID]])

func combination(button1, button2, action, extra = null, back = false):
	if (button1 in input_state.just_pressed and button2 in input_state.pressed) or \
			(button1 in input_state.pressed and button2 in input_state.just_pressed):
		if extra:
			if !back:
				input_buffer.push_front([action, Settings.input_buffer_time[player_ID], extra])
			else:
				input_buffer.append([action, Settings.input_buffer_time[player_ID], extra])
		else:
			if !back:
				input_buffer.push_front([action, Settings.input_buffer_time[player_ID]])
			else:
				input_buffer.append([action, Settings.input_buffer_time[player_ID]])
				
func combination_trio(button1, button2, button3, action, extra = null, back = false):
	if (button1 in input_state.just_pressed and button2 in input_state.pressed and button3 in input_state.pressed) or \
			(button1 in input_state.pressed and button2 in input_state.just_pressed and button3 in input_state.pressed) or \
			(button1 in input_state.pressed and button2 in input_state.pressed and button3 in input_state.just_pressed):
		if extra:
			if !back:
				input_buffer.push_front([action, Settings.input_buffer_time[player_ID], extra])
			else:
				input_buffer.append([action, Settings.input_buffer_time[player_ID], extra])
		else:
			if !back:
				input_buffer.push_front([action, Settings.input_buffer_time[player_ID]])
			else:
				input_buffer.append([action, Settings.input_buffer_time[player_ID]])
		
	
# INPUT BUFFER ---------------------------------------------------------------------------------------------------
	
func process_input_buffer():

	var input_to_erase = [] # need this as cannot erase array members while iterating through it
	var input_to_add = [] # some actions add inputs to the buffer, adding array members while iterating through it can cause issues
	
	var has_acted := [false]
	# any attack/instajump when processed when turn this to true causing all further jumps/attacks to be ignored and erased
	# used an array for this so I don't have to pass it back...
	
	
	
	for buffered_input in input_buffer:
		var keep := true

		match buffered_input[0]:
			
			button_jump, button_up:
				if buffered_input[0] == button_up and Settings.tap_jump[player_ID] == 0: # can set so that up does not jump
					continue
				if Animator.query(["JumpTransit", "AirJumpTransit"]): # consume buffered jumps during jump transits
					keep = false
					continue
				if !has_acted[0]:
					match new_state:
						
						# JUMPING ON GROUND --------------------------------------------------------------------------------------------------
						
						Globals.char_state.GROUND_STANDBY, Globals.char_state.CROUCHING, Globals.char_state.GROUND_C_RECOVERY:
							if button_down in input_state.pressed and !button_dash in input_state.pressed \
									and soft_grounded: # cannot be pressing dash
			#							!Character.button_left in Character.input_state.pressed and \f
			#							!Character.button_right in Character.input_state.pressed: # don't use dir
								
								# fallthrough
#								if new_state in [Globals.char_state.GROUND_STANDBY, Globals.char_state.CROUCHING, \
#										Globals.char_state.GROUND_C_RECOVERY]:
								position.y += 2 # 1 will cause issues with downward moving platforms
								animate("FallTransit")
								keep = false
									
							if keep:
								animate("JumpTransit") # ground jump
								keep = false
							
						# BUFFERING AN INSTANT AIRDASH ---------------------------------------------------------------------------------
							
						Globals.char_state.GROUND_STARTUP:
							if Animator.query(["DashTransit"]):
								input_buffer.append(["InstaAirDash", Settings.input_buffer_time[player_ID]])
								keep = false
								
						# WALL JUMPS  --------------------------------------------------------------------------------------------------
			
						Globals.char_state.AIR_STANDBY, Globals.char_state.AIR_C_RECOVERY:
							if Settings.dj_fastfall[player_ID] == 1 and button_down in input_state.pressed:
								continue
								
							if check_wall_jump():
								animate("WallJumpTransit")
								keep = false
#
#						# SNAP UP WAVEDASH --------------------------------------------------------------------------------------------------
#
#
#							elif button_down in input_state.pressed and button_dash in input_state.pressed and \
#									Animator.time <= 1 and check_snap_up():
#								 # moving downward and within 1st frame of falling, for easy wavedashing on soft platforms
#								snap_up($PlayerCollisionBox, $DashLandDBox)
#								animate("JumpTransit") # if snapping up while falling downward, instantly wavedash
#								input_to_add.append([button_dash, Settings.input_buffer_time[player_ID]])
#								keep = false
								
						# AIR JUMPS  --------------------------------------------------------------------------------------------------
								
							elif air_jump > 0 and !button_dash in input_state.pressed: # no dash for easier wavedashing
								animate("AirJumpTransit")
								keep = false
								
						# AERIAL AIR JUMP CANCEL ---------------------------------------------------------------------------------
							
						Globals.char_state.AIR_ATK_RECOVERY:		
							if Settings.dj_fastfall[player_ID] == 1 and button_down in input_state.pressed:
								continue
								
							if test_jump_cancel():
								animate("AirJumpTransit")
								keep = false
								
								
						# JUMP CANCELS ---------------------------------------------------------------------------------
								
						Globals.char_state.GROUND_ATK_RECOVERY:
							if test_jump_cancel():
								if button_down in input_state.pressed and !button_dash in input_state.pressed \
									and soft_grounded: # cannot be pressing dash
									position.y += 2 # 1 will cause issues with downward moving platforms
									animate("FallTransit")
									keep = false
								else:
									animate("JumpTransit")
									keep = false
						
						Globals.char_state.GROUND_ATK_ACTIVE: # some attacks can jump cancel on active frames
							if jump_cancel:
								shadow_cancel()
								animate("JumpTransit")
								keep = false
									
			# FOR NON_JUMP ACTIONS --------------------------------------------------------------------------------------------------
		
			"Burst":
				match new_state:
					Globals.char_state.GROUND_STANDBY, Globals.char_state.CROUCHING, Globals.char_state.GROUND_C_RECOVERY, \
							Globals.char_state.AIR_STANDBY, Globals.char_state.AIR_C_RECOVERY, \
							Globals.char_state.GROUND_BLOCK, Globals.char_state.GROUND_BLOCKSTUN, \
							Globals.char_state.AIR_BLOCK, Globals.char_state.AIR_BLOCKSTUN:
						if Animator.query(["WBlockstun", "AirWBlockstun"]): # no burst during wrongblock
							continue
						if burst_counter_check():
							animate("BurstCounterStartup")
							chain_memory = []
							has_acted[0] = true
							keep = false
					Globals.char_state.GROUND_FLINCH_HITSTUN, Globals.char_state.AIR_FLINCH_HITSTUN, Globals.char_state.LAUNCHED_HITSTUN:
						if burst_escape_check():
							animate("BurstEscapeStartup")
							chain_memory = []
							has_acted[0] = true
							keep = false
					Globals.char_state.GROUND_ATK_RECOVERY, Globals.char_state.AIR_ATK_RECOVERY, \
							Globals.char_state.GROUND_ATK_ACTIVE, Globals.char_state.AIR_ATK_ACTIVE:
						if burst_extend_check():
							animate("BurstExtend")
							chain_memory = []
							has_acted[0] = true
							keep = false
		
			_:
				# pass to process_buffered_input() in unique character node, it returns a bool of whether input should be kept
				# some special buttons can also add new buffered inputs, this are added at the end
				if !UniqueCharacter.process_buffered_input(new_state, buffered_input, input_to_add, has_acted):
					keep = false
				
		# remove expired
		buffered_input[1] -= 1
		if buffered_input[1] < 0:
			keep = false
			
		if !keep or has_acted[0]:
			input_to_erase.append(buffered_input)
	
	for input in input_to_erase:
		input_buffer.erase(input)
	input_buffer.append_array(input_to_add) # add the inputs added by special actions

# STATE DETECT ---------------------------------------------------------------------------------------------------

func animate(anim):
	
	Animator.play(anim)
	new_state = state_detect(anim)
	
	if anim.ends_with("Active"):
		atk_startup_resets() # need to do this here to work! resets hitcount and ignore list

	# when changing to a non-attacking state from attack startup, auto-buffer pressed attack buttons
	# actions that cancel startup frames deliberately (land cancel, EX Shift) will set startup_cancel_flag to true to prevent auto-buffer
	if !startup_cancel_flag and !is_attacking():
		match state:
			Globals.char_state.GROUND_ATK_STARTUP, Globals.char_state.AIR_ATK_STARTUP:
				cancel_and_buffer()
			_: # for animation transitions on the same frame as you pressing an attack
				if button_light in input_state.just_pressed:
					if button_fierce in input_state.just_pressed:
						input_buffer.append(["H", Settings.input_buffer_time[player_ID]])
					input_buffer.append([button_light, Settings.input_buffer_time[player_ID]])
				if button_fierce in input_state.just_pressed:
					input_buffer.append([button_fierce, Settings.input_buffer_time[player_ID]])
				if button_aux in input_state.just_pressed:
					input_buffer.append([button_aux, Settings.input_buffer_time[player_ID]])
			
func cancel_and_buffer():
	if button_light in input_state.pressed:
		if button_fierce in input_state.pressed:
			input_buffer.append(["H", Settings.input_buffer_time[player_ID]])
		input_buffer.append([button_light, Settings.input_buffer_time[player_ID]])
	if button_fierce in input_state.pressed:
		input_buffer.append([button_fierce, Settings.input_buffer_time[player_ID]])
	if button_aux in input_state.pressed:
		input_buffer.append([button_aux, Settings.input_buffer_time[player_ID]])

func query_state(query_states: Array):
	for x in query_states:
		if state == x or new_state == x:
			return true
	return false

func state_detect(anim):
	match anim:
		# universal animations
		"Idle", "RunTransit", "Run", "Brake":
			return Globals.char_state.GROUND_STANDBY
		"CrouchTransit", "Crouch", "CrouchReturn":
			return Globals.char_state.CROUCHING
		"JumpTransit", "DashTransit":
			return Globals.char_state.GROUND_STARTUP
		"Dash", "BlockRecovery":
			return Globals.char_state.GROUND_RECOVERY
		"SoftLanding", "DashBrake", "BlockCRecovery", "HardLanding":
			return Globals.char_state.GROUND_C_RECOVERY
			
		"JumpTransit3","AirJumpTransit3", "Jump", "FallTransit", "Fall":
			return Globals.char_state.AIR_STANDBY
		"AirJumpTransit", "WallJumpTransit", "AirJumpTransit2", "WallJumpTransit2", "AirDashTransit", "JumpTransit2":
			# ground/air jumps have 1 frame of AIR_STARTUP after lift-off to delay actions like instant air dash/wavedashing
			return Globals.char_state.AIR_STARTUP
		"AirDash", "AirDashD", "AirDashU", "AirDashDD", "AirDashUU", "AirBlockRecovery":
			return Globals.char_state.AIR_RECOVERY
		"AirDashBrake", "AirBlockCRecovery":
			return Globals.char_state.AIR_C_RECOVERY
			
		"FlinchAStop", "FlinchA", "FlinchBStop", "FlinchB":
			return Globals.char_state.GROUND_FLINCH_HITSTUN
		"FlinchAReturn", "FlinchBReturn":
			return Globals.char_state.GROUND_C_RECOVERY
		"AirFlinchAStop", "AirFlinchA", "AirFlinchBStop", "AirFlinchB":
			return Globals.char_state.AIR_FLINCH_HITSTUN
		"AirFlinchAReturn", "AirFlinchBReturn":
			return Globals.char_state.AIR_C_RECOVERY
		"LaunchAStop", "LaunchBStop", "LaunchCStop", "LaunchDStop", "LaunchEStop", "LaunchTransit", "Launch":
			return Globals.char_state.LAUNCHED_HITSTUN
			
		"BlockStartup":
			return Globals.char_state.GROUND_BLOCK
		"AirBlockStartup":
			return Globals.char_state.AIR_BLOCK
		"Block", "BlockstunReturn", "BlockLanding":
			return Globals.char_state.GROUND_BLOCK
		"AirBlock", "AirBlockstunReturn":
			return Globals.char_state.AIR_BLOCK
		"Blockstun", "PBlockstun", "WBlockstun":
			return Globals.char_state.GROUND_BLOCKSTUN
		"AirBlockstun", "AirPBlockstun", "AirWBlockstun":
			return Globals.char_state.AIR_BLOCKSTUN
			
		"BurstCounterStartup", "BurstEscapeStartup":
			return Globals.char_state.AIR_ATK_STARTUP
		"BurstCounter", "BurstEscape", "BurstExtend":
			return Globals.char_state.AIR_ATK_ACTIVE
		"BurstRecovery":
			return Globals.char_state.AIR_ATK_RECOVERY
			
		_: # unique animations
			return UniqueCharacter.state_detect(anim)
			
	
# ---------------------------------------------------------------------------------------------------

func perfect_block():
	if $PBlockCDTimer.is_running():
		$PBlockCDTimer.time = PBlockCDTimer_WAIT_TIME
	else:
		$PBlockCDTimer.time = PBlockCDTimer_WAIT_TIME
		$PBlockTimer.time = PBlockTimer_WAIT_TIME

func on_kill():
	if state != Globals.char_state.DEAD:
		play_audio("kill1", {"vol" : -2})
		var sfx_facing = 1
		if rng_generate(2) == 0:
			sfx_facing = -1
		var rot = Globals.Game.get_killblast_angle_and_screenshake(position) * -sfx_facing
		var aux_data = {"facing" : sfx_facing, "rot" : rot}
		match player_ID:
			0:
				pass
			1:
				aux_data["palette"] = "blue"
		emit_signal("SFX", "KillBlast", "KillBlast", position, aux_data)
		
		$VarJumpTimer.stop()
		$BlockStunTimer.stop()
		$HitStunTimer.stop()
		$HitStopTimer.stop()
		$SpecialTimer.stop()
		$EXTimer.stop()
		$SuperTimer.stop()
		
		$Sprites.hide()
		state = Globals.char_state.DEAD
		velocity = Vector2.ZERO
		move_memory = []
		input_buffer = []
		hitcount_record = []
		ignore_list = []
		remove_all_status_effects()
		reset_jumps()
		
		var stock_loss = -(Globals.FLAT_STOCK_LOSS + current_damage_value)
		change_stock_points(stock_loss)
		if stock_points_left > 0 and !Globals.Game.game_set:
			$RespawnTimer.time = Globals.RespawnTimer_WAIT_TIME
		else:
			$RespawnTimer.time = 9999
			
		# your targeted opponent gain burst token
		Globals.Game.get_player_node(targeted_opponent).change_burst_token(true)
			
	
func respawn():
	
	var respawn_dir := 0
	var respawn_v_dir := 0
	if button_right in input_state.pressed:
		respawn_dir += 1
	if button_left in input_state.pressed:
		respawn_dir -= 1
	if button_up in input_state.pressed:
		respawn_v_dir -= 1
	if button_down in input_state.pressed:
		respawn_v_dir += 1
	
	if respawn_dir == -1:
		if respawn_v_dir == -1:
			position = Globals.Game.respawn_points[1]
		elif respawn_v_dir == 1:
			position = Globals.Game.respawn_points[2]
		else:
			position = Globals.Game.respawn_points[0]
	elif respawn_dir == 1:
		if respawn_v_dir == -1:
			position = Globals.Game.respawn_points[7]
		elif respawn_v_dir == 1:
			position = Globals.Game.respawn_points[6]
		else:
			position = Globals.Game.respawn_points[8]
	else:
		if respawn_v_dir == -1:
			position = Globals.Game.respawn_points[3]
		elif respawn_v_dir == 1:
			position = Globals.Game.respawn_points[5]
		else:
			position = Globals.Game.respawn_points[4]
			
	current_damage_value = 0
	current_guard_gauge = 0
	change_burst_token(true) # gain Burst on death
	Globals.Game.damage_update(self)
	Globals.Game.guard_gauge_update(self)
	Globals.Game.ex_gauge_update(self)
	Globals.Game.stock_points_update(self)
	
	$Sprites.show()	
	animate("Idle")
	state = Globals.char_state.GROUND_STANDBY
	add_status_effect(Globals.status_effect.RESPAWN_GRACE, RESPAWN_GRACE_DURATION)
	
	var v_mirror: bool
	if rng_generate(2) == 0: v_mirror = true
	else: v_mirror = false
	var h_direction: int
	if rng_generate(2) == 0: h_direction = 1
	else: h_direction = -1
	
	var aux_data = {"back":true, "facing":h_direction, "v_mirror":v_mirror}
	match player_ID:
		0:
			pass
		1:
			aux_data["palette"] = "blue"
	
	emit_signal("SFX", "Respawn", "Respawn", position, aux_data)
	play_audio("bling7", {"vol" : -15, "bus" : "PitchUp2"})

		
func face(in_dir):
	facing = in_dir
	sprite.scale.x = facing
	
func reset_jumps():
	air_jump = UniqueCharacter.MAX_AIR_JUMP # reset jump count on ground
	wall_jump = MAX_WALL_JUMP # reset wall jump count on ground
	air_dash = UniqueCharacter.MAX_AIR_DASH
	aerial_memory = []
	
func reset_jumps_except_walljumps():
	air_jump = UniqueCharacter.MAX_AIR_JUMP # reset jump count on wall
	air_dash = UniqueCharacter.MAX_AIR_DASH
	
func gain_one_air_jump(): # hitting with an aerial (not block unless wrongblock) give you +1 air jump
	if air_jump < UniqueCharacter.MAX_AIR_JUMP: # cannot go over
		air_jump += 1
	
func reset_cancels(): # done whenever you use an attack
	chain_combo = 0
	dash_cancel = false
	jump_cancel = false
	
func check_wall_jump():
	var left_wall = Detection.detect_bool([$WallJumpLeftDBox], ["SolidPlatforms"])
	var right_wall = Detection.detect_bool([$WallJumpRightDBox], ["SolidPlatforms"])
	if (left_wall or right_wall) and wall_jump > 0:
		
		wall_jump -= 1
		
		wall_jump_dir = 0 # 1 is right -1 is left
		if left_wall:
			wall_jump_dir += 1
		if right_wall:
			wall_jump_dir -= 1
		return true
	else: return false
	
		
func check_landing(): # called by physics.gd when character stopped by floor
	match new_state:
		Globals.char_state.AIR_STANDBY, Globals.char_state.AIR_C_RECOVERY:
			animate("SoftLanding")
			
		Globals.char_state.AIR_STARTUP:
			if Animator.query(["AirJumpTransit"]):
				animate("SoftLanding")
				input_buffer.append([button_jump, Settings.input_buffer_time[player_ID]])
			elif Animator.query(["AirDashTransit"]):
				animate("SoftLanding")
				input_buffer.append([button_dash, Settings.input_buffer_time[player_ID]])
				
		Globals.char_state.AIR_ACTIVE:
			pass # AIR_ACTIVE not used for now
			
		Globals.char_state.AIR_RECOVERY:
			if Animator.to_play_animation.begins_with("AirDash") and !Animator.to_play_animation.ends_with("DD"): # wave landing
				animate("DashBrake")
				emit_signal("SFX","GroundDashDust", "DustClouds", get_feet_pos(), {"facing":facing, "grounded":true})
				velocity.x = facing * UniqueCharacter.AIR_DASH_SPEED
				
			elif Animator.query(["AirBlockRecovery"]): # AirBlockRecovery to BlockCRecovery
				emit_signal("SFX","LandDust", "DustClouds", get_feet_pos(), {"facing":facing, "grounded":true})  
				animate("BlockCRecovery")
				UniqueCharacter.landing_sound()
				
			else: # landing during AirDashBrake or AirDashDD
				animate("HardLanding")
				
		Globals.char_state.AIR_ATK_STARTUP, Globals.char_state.AIR_ATK_ACTIVE, Globals.char_state.AIR_ATK_RECOVERY:
			# cannot land during aerial startup and active frames unless they have the LAND_CANCEL atk attr
			if Globals.atk_attr.LAND_CANCEL in query_atk_attr():
				startup_cancel_flag = true
				animate("HardLanding")
				
		Globals.char_state.AIR_FLINCH_HITSTUN: # land during hitstun               
			emit_signal("SFX","LandDust", "DustClouds", get_feet_pos(), {"facing":facing, "grounded":true})               
			match Animator.to_play_animation:
				"AirFlinchAStop", "AirFlinchA":
					animate("FlinchA")
				"AirFlinchBStop", "AirFlinchB":
					animate("FlinchB")
			UniqueCharacter.landing_sound()
			
		Globals.char_state.LAUNCHED_HITSTUN: # land during launch_hitstun, can bounce or tech land
			if new_state == Globals.char_state.LAUNCHED_HITSTUN:
				# need to use new_state to prevent an issue with grounded Break state causing HardLanding on flinch
				var velocity_to_check: Vector2 # check using either velocity this frame or last frame
				if velocity_previous_frame.length() > velocity.length():
					velocity_to_check = velocity_previous_frame
				else:
					velocity_to_check = velocity
				if velocity_to_check.length() <= TECH_THRESHOLD:
					animate("HardLanding")
					$HitStunTimer.stop()              
					velocity.y = 0 # stop bouncing
					$ModulatePlayer.play("tech_flash")
					play_audio("bling4", {"vol" : -15, "bus" : "PitchDown"})   
			
		Globals.char_state.AIR_BLOCK: # air block to ground block
			emit_signal("SFX","LandDust", "DustClouds", get_feet_pos(), {"facing":facing, "grounded":true})  
			animate("BlockLanding")
			
		Globals.char_state.AIR_BLOCKSTUN: # air blockstun to ground blockstun
			emit_signal("SFX","LandDust", "DustClouds", get_feet_pos(), {"facing":facing, "grounded":true})  
			if Animator.query(["AirBlockstun"]):
				animate("Blockstun")
			elif Animator.query(["AirPBlockstun"]):
				animate("PBlockstun")
			elif Animator.query(["AirWBlockstun"]):
				animate("WBlockstun")
			UniqueCharacter.landing_sound()

			
func check_drop(): # called when character becomes airborne while in a grounded state
	match new_state:
		
		Globals.char_state.GROUND_STANDBY, Globals.char_state.CROUCHING, Globals.char_state.GROUND_C_RECOVERY:
			animate("FallTransit")
			
		Globals.char_state.GROUND_STARTUP:
			if Animator.query(["JumpTransit"]): # instantly jump if dropped during jump transit
				animate("JumpTransit2")
			else:
				animate("FallTransit")
				
		Globals.char_state.GROUND_ACTIVE:
			pass # GROUND_ACTIVE not used for now
			
		Globals.char_state.GROUND_RECOVERY:
			if Animator.query(["BlockRecovery"]):
				animate("AirBlockCRecovery")
			else:
				animate("FallTransit")
				
		Globals.char_state.GROUND_ATK_STARTUP:
			animate("FallTransit")
				
		Globals.char_state.GROUND_ATK_ACTIVE, Globals.char_state.GROUND_ATK_RECOVERY:
			var move_name = get_move_name()
			if move_name in UniqueCharacter.MOVE_DATABASE and \
					Globals.atk_attr.LEDGE_DROP in UniqueCharacter.MOVE_DATABASE[move_name].atk_attr:
				continue
			else:
				animate("FallTransit")
			
		Globals.char_state.GROUND_FLINCH_HITSTUN:
			match Animator.to_play_animation:
				"FlinchAStop", "FlinchA":
					animate("AirFlinchA")
				"FlinchBStop", "FlinchB":
					animate("AirFlinchB")
			
		Globals.char_state.GROUND_BLOCK:
			animate("AirBlock")
			
		Globals.char_state.GROUND_BLOCKSTUN: # ground blockstun to air blockstun
			if Animator.query(["Blockstun"]):
				animate("AirBlockstun")
			elif Animator.query(["PBlockstun"]):
				animate("AirPBlockstun")
			elif Animator.query(["WBlockstun"]):
				animate("AirWBlockstun")


		
func check_auto_drop(): # during aerials, can drop through platforms if down is held
	if !grounded and is_attacking():
		if button_down in input_state.pressed:
			return true
	return false
		
# check if in place for a down-dash snap up landing, if so, snap up
func check_snap_up():
	if Detection.detect_bool([$DashLandDBox], ["SoftPlatforms"]) and \
			!Detection.detect_bool([$DashLandDBox2], ["SoftPlatforms"]):
		return true
	else:
		return false
		
func get_feet_pos(): # return global position of the point the character is standing on, for SFX emission
	return position + Vector2(0, $PlayerCollisionBox.rect_position.y + $PlayerCollisionBox.rect_size.y)
	
func rng_generate(upper_limit: int): # will return a number from 0 to (upper_limit - 1)
	if Globals.Game.has_method("rng_generate"):
		return Globals.Game.rng_generate(upper_limit)
	else: return null

func process_VDI():
	# to be able to DI, must be entering knockback animation and has a directional key pressed
	if (dir != 0 or v_dir != 0) and current_guard_gauge > 0 and get_damage_percent() < 1.0 and \
			((state == Globals.char_state.LAUNCHED_HITSTUN and Animator.query_to_play(["LaunchTransit"]) and \
			!Animator.query_current(["LaunchTransit"])) or \
			(state == Globals.char_state.GROUND_FLINCH_HITSTUN and Animator.query_to_play(["FlinchA", "FlinchB"]) and \
			!Animator.query_current(["FlinchA", "FlinchB"])) or \
			(state == Globals.char_state.AIR_FLINCH_HITSTUN and Animator.query_to_play(["AirFlinchA", "AirFlinchB"]) and \
			!Animator.query_current(["AirFlinchA", "AirFlinchB"]))):
		var VDI_amount = lerp(VDI_MAX * DI_MIN_MOD, VDI_MAX, get_guard_gauge_percent_above()) # adjust according to Guard Gauge
#		var new_angle = Globals.navigate(velocity, Vector2(dir, v_dir), DI_amount) # this return an angle closer to the target direction
#		velocity = Vector2(velocity.length(), 0).rotated(new_angle)
		var VDI_vector = Vector2(dir, v_dir).normalized() * (VDI_amount * velocity.length())
		velocity += VDI_vector

# SPECIAL EFFECTS --------------------------------------------------------------------------------------------------

func set_monochrome():
	if !monochrome:
		monochrome = true
		sprite.material = ShaderMaterial.new()
		sprite.material.shader = Globals.monochrome_shader

# particle emitter
func particle(anim: String, loaded_sfx_ref: String, palette: String, interval, number, radius, v_mirror_rand = false):
	if Globals.Game.frametime % interval == 0:  # only shake every X frames
		for x in number:
			var angle = rng_generate(10) * PI/5.0
			var distance = rng_generate(5) * radius/5.0
			var particle_pos = position + Vector2(distance, 0).rotated(angle)
			particle_pos.x = round(particle_pos.x)
			particle_pos.y = round(particle_pos.y)
			var particle_facing = 1
			if rng_generate(2) == 0:
				particle_facing = -1
			var aux_data = {"facing" : particle_facing}
			if v_mirror_rand and rng_generate(2) == 0:
				aux_data["v_mirror"] = true
			if palette != "":
				aux_data["palette"] = palette
			emit_signal("SFX", anim, loaded_sfx_ref, particle_pos, aux_data)
			
func shadow_trail(starting_modulate_a = 0.5, lifetime = 10.0): # one shadow every 2 frames
	if shadow_timer <= 0:
		shadow_timer = 1
		emit_signal("shadow_trail", sprite.get_path(), position, starting_modulate_a, lifetime)
	else:
		shadow_timer -= 1
		
func shadow_cancel(starting_modulate_a = 0.6, lifetime = 15.0):
	emit_signal("shadow_trail", sprite.get_path(), position, starting_modulate_a, lifetime)
		
func launch_trail():
	var frequency: int
	if velocity.length() <= LAUNCH_DUST_THRESHOLD * 0.5:
		frequency = 5
	elif velocity.length() <= LAUNCH_DUST_THRESHOLD: # the faster you go the more frequent the launch dust
		frequency = 3
	elif velocity.length() <= LAUNCH_DUST_THRESHOLD * 2:
		frequency = 2
	else:
		frequency = 1
		
		
	if posmod($HitStunTimer.time, frequency) == 0:
		
		var v_mirror: bool
		if rng_generate(2) == 0: v_mirror = true
		else: v_mirror = false
		var h_direction: int
		if rng_generate(2) == 0: h_direction = 1
		else: h_direction = -1
		
		
		if !grounded:
			emit_signal("SFX", "LaunchDust", "DustClouds", position, {"back":true, "facing":h_direction, "v_mirror":v_mirror})
		else:
			emit_signal("SFX", "DragRocks", "DustClouds", get_feet_pos(), {"facing":h_direction})
	
# QUICK STATE CHECK ---------------------------------------------------------------------------------------------------
	
func get_move_name():
	var move_name = Animator.to_play_animation.trim_suffix("Startup")
	move_name = move_name.trim_suffix("Active")
	move_name = move_name.trim_suffix("Recovery")
	return move_name
	
func check_quick_cancel(turning = false): # return true if you can change direction or cancel into a combination action currently
	match state: # use current state instead of new_state
		Globals.char_state.GROUND_STARTUP, Globals.char_state.AIR_STARTUP:
			if turning:
				return true
			elif Animator.time <= QUICK_CANCEL_TIME and Animator.time != 0:
				return true
		Globals.char_state.GROUND_ATK_STARTUP:
			if turning:
				var move_name = get_move_name()
				if move_name == null: return false # if name at name of animation not found in database
				if !Globals.atk_attr.NO_TURN in query_atk_attr(move_name):
					return true
			else: continue
		Globals.char_state.GROUND_ATK_STARTUP, Globals.char_state.AIR_ATK_STARTUP:
			if !turning:
				if Animator.time <= QUICK_CANCEL_TIME and Animator.time != 0:
					# when time = 0 state is still in the previous one, since state only update when a new animation begins
					return true
			else: # for turning, the QUICK_CANCEL_TIME is 1 frame lower, min is 1 frame
				if Animator.time <= max(QUICK_CANCEL_TIME - 1, 1) and Animator.time != 0:
					return true
		Globals.char_state.GROUND_BLOCK:
			if Animator.query(["BlockStartup"]):
				return true
		Globals.char_state.AIR_BLOCK:
			if Animator.query(["AirBlockStartup"]):
				return true
	return false
		
func check_ledge_stop(): # some animations prevent you from dropping off
	if !grounded:
		return false
	if is_attacking():
		# test if move has LEDGE_DROP, no ledge stop if so
		if new_state != Globals.char_state.GROUND_ATK_STARTUP:
			if Globals.atk_attr.LEDGE_DROP in query_atk_attr():
				return false # even with LEDGE_DROP, startup animation will still stop you at the ledge
			else:
				return true # no LEDGE_DROP, will stop at ledge
		else:
			if dir == facing: # can drop off ledge on startup if you are holding forward
				return false
			else:
				return true
	else:
		return false # not attacking
	
func is_attacking():
	match new_state:
		Globals.char_state.GROUND_ATK_STARTUP, Globals.char_state.GROUND_ATK_ACTIVE, Globals.char_state.GROUND_ATK_RECOVERY, \
				Globals.char_state.AIR_ATK_STARTUP, Globals.char_state.AIR_ATK_ACTIVE, Globals.char_state.AIR_ATK_RECOVERY:
			return true
	return false
	
func is_blocking():
	match new_state:
		Globals.char_state.GROUND_BLOCK, Globals.char_state.AIR_BLOCK, Globals.char_state.GROUND_BLOCKSTUN, \
				Globals.char_state.AIR_BLOCKSTUN:
			return true
	return false
	
func is_aerial():
	match new_state:
		Globals.char_state.AIR_ATK_STARTUP, Globals.char_state.AIR_ATK_ACTIVE, Globals.char_state.AIR_ATK_RECOVERY:
			return true
	return false
	
func is_atk_startup():
	match new_state:
		Globals.char_state.GROUND_ATK_STARTUP, Globals.char_state.AIR_ATK_STARTUP:
			return true
	return false
	
func is_atk_active():
	match new_state:
		Globals.char_state.GROUND_ATK_ACTIVE, Globals.char_state.AIR_ATK_ACTIVE:
			return true
	return false
	
func is_atk_recovery():
	match new_state:
		Globals.char_state.GROUND_ATK_RECOVERY, Globals.char_state.AIR_ATK_RECOVERY:
			return true
	return false
	
func is_normal_attack(move_name):
	if UniqueCharacter.MOVE_DATABASE.has(move_name):
		match UniqueCharacter.MOVE_DATABASE[move_name].atk_type:
			Globals.atk_type.LIGHT, Globals.atk_type.FIERCE, Globals.atk_type.HEAVY: # can only chain combo into a Normal
				return true
	return false
	
	
func is_burst(move_name):
	if move_name == "BurstCounter" or move_name == "BurstEscape" or move_name == "BurstExtend":
		return true
	return false
	
func burst_counter_check(): # check if have resources to do it, then take away those resources and return a bool
	if current_ex_gauge < BURSTCOUNTER_EX_COST * 10000:
		return false # not enough EX Gauge to use it
	change_ex_gauge(-BURSTCOUNTER_EX_COST * 10000)
	return true
	
func burst_escape_check(): # check if have resources to do it, then take away those resources and return a bool
	if get_damage_percent() >= 1.0: # cannot Burst Escape at lethal range
		return false
	if current_guard_gauge >= GUARD_GAUGE_CEIL:
		change_guard_gauge_percent(-1.0)
		return true
	if !has_burst or current_guard_gauge <= 0:
		return false # not enough resouces to use it
	change_guard_gauge_percent(-BURSTESCAPE_GG_COST)
	change_burst_token(false)
	return true
	
func burst_extend_check(): # check if have resources to do it, then take away those resources and return a bool
	if !has_burst or chain_combo != 1:
		return false
	change_burst_token(false)
	return true
	
func test_jump_cancel():
	if grounded:
		if chain_combo != 1: return false # can only jump cancel on hit (not block)
	else:
		if air_jump == 0: return false # if in air, need >1 air jump left
		if chain_combo == 0: return false # if in air, can jump cancel on blocking opponents
		
	var move_name = Animator.to_play_animation.trim_suffix("Recovery")
	if !is_normal_attack(move_name): return false # can only jump cancel Normals
	if Globals.atk_attr.NO_JUMP_CANCEL in query_atk_attr(move_name) : return false # Normals with NO_JUMP_CANCEL cannot be jump cancelled
	
	shadow_cancel()
	return true
	
func test_dash_cancel():
	if chain_combo != 1: return false # can only dash cancel on hit (not block)
	if !grounded and air_dash == 0: return false # if in air, need >1 air dash left
	
	var move_name = Animator.to_play_animation.trim_suffix("Recovery")
	if !is_normal_attack(move_name): return false # can only dash cancel Normals
	if Globals.atk_attr.NO_JUMP_CANCEL in query_atk_attr(move_name) : return false # Normals with NO_JUMP_CANCEL cannot be dash cancelled
	
	shadow_cancel()
	return true
	
func test_fastfall_cancel():
	if chain_combo != 1: return false # can only fastfall cancel on hit (not block)
	
	var move_name = Animator.to_play_animation.trim_suffix("Recovery")
	if !is_normal_attack(move_name): return false # can only fastfall cancel Normals
	if !move_name.begins_with("a"): return false # can only fastfall cancel aerials
	if Globals.atk_attr.NO_JUMP_CANCEL in query_atk_attr(move_name) : return false # Normals with NO_JUMP_CANCEL cannot be fastfall cancelled
	
	shadow_cancel()
	return true
	
#func test_air_jump_cancel(): # for aerials' innate air jump cancel, some conditions must be fulfilled
#	if grounded or chain_combo == 0 or chain_combo == 2: return false # must be in air and have hitted an opponent with the aerial
#	# can only jump cancel on unblock or wrongblock
#
#	var move_name = Animator.to_play_animation.trim_suffix("Recovery")
#	# must be an aerial normal
#	if is_normal_attack(move_name) and move_name.begins_with("a"): # note: some specials/supers may begin with "a"
#		if Globals.atk_attr.NO_JUMP_CANCEL in query_atk_attr(move_name):
#			return false
#		else:
#			return true
#	else: return false


func query_traits(): # may have certain conditions
	return UniqueCharacter.query_traits()
	
	
# name should be stripped already!
func query_atk_attr(in_move_name = null): # may have certain conditions, if no move name passed in, check current attack
	
	if is_burst(in_move_name):
		return [Globals.atk_attr.SEMI_INVUL_STARTUP, Globals.atk_attr.SCREEN_SHAKE, Globals.atk_attr.NO_TURN]
	
	var move_name = in_move_name
	if move_name == null:
		move_name = get_move_name()
		
	return UniqueCharacter.query_atk_attr(move_name)


#func progress_tap_memory(): # remove taps that expired
#	var to_erase = []
#	for tap in tap_memory:
#		tap[1] -= 1
#		if tap[1] <= 0:
#			to_erase.append(tap)
#	if to_erase.size() > 0:
#		for x in to_erase:
#			tap_memory.erase(x)
#
#func test_doubletap(button):
#	for tap in tap_memory:
#		if tap[0] == button:
#			return true
#	return false
			

# STATUS EFFECTS ---------------------------------------------------------------------------------------------------
	# rule: status_effect is array contain [effect, lifetime], effect can be a Globals.status_effect enum or a string
	
func add_status_effect(effect, lifetime):
	
	for status_effect in status_effects: # look to see if already inflicted with the same one, if so, overwrite its lifetime if new one last longer
		if status_effect[0] == effect: # found effect already inflicted
			if lifetime != null and (status_effect[1] == null or status_effect[1] < lifetime):
				status_effect[1] = lifetime # overwrite effect if new effect last longer
			return # return after finding effect already inflicted regardless of whether you overwrite it
			
	 # new status effect, add it to the array in order of visual priority
	for index in status_effects.size() + 1:
		if index >= status_effects.size(): # end of array, add new effect at the end with the highest priority
			status_effects.append([effect, lifetime])
		elif Globals.status_effect_priority(effect) < Globals.status_effect_priority(status_effects[index][0]):
			status_effects.insert(index, [effect, lifetime]) # if found an existing effect with higher priority, insert before it
			break
	new_status_effect(effect)

func query_status_effect(effect):
	for status_effect in status_effects:
		if status_effect[0] == effect:
			return true
	return false
	
func process_status_effects_visual(): # called during hitstop as well
	for status_effect in status_effects:
		continue_visual_effect_of_status(status_effect[0])

func process_status_effects_timer(): # reduce lifetime and remove expired status effects
	var effect_to_erase = []
	
	for status_effect in status_effects:
		
		if status_effect[1] != null: # a lifetime of "null" means no duration
			status_effect[1] -= 1
			if status_effect[1] < 0:
				effect_to_erase.append(status_effect)
				
		match status_effect[0]:
			Globals.status_effect.BREAK_RECOVER: # when recovering from a combo where a Break occur, restore Guard Gauge
				if !$HitStunTimer.is_running():
					effect_to_erase.append(status_effect)
					if current_guard_gauge < 0:
						current_guard_gauge = 0
						Globals.Game.guard_gauge_update(self)
			Globals.status_effect.POS_FLOW: # positive flow ends if guard gauge returns to 0
				if current_guard_gauge >= 0:
					effect_to_erase.append(status_effect)
			
	for status_effect in effect_to_erase:
		status_effects.erase(status_effect)
		clear_visual_effect_of_status(status_effect[0])
		
func new_status_effect(effect): # run on frame the status effect is inflicted, used to modify stats
	match effect:
		Globals.status_effect.POS_FLOW:
			Globals.Game.HUD.get_node("P" + str(player_ID + 1) + "_HUDRect/GaugesUnder/GuardGauge1").texture_progress = \
					Globals.loaded_guard_gauge_pos
		
func continue_visual_effect_of_status(effect): # run every frame, will not add visual effect if there is already one of higher priority
	match effect:
		Globals.status_effect.LETHAL:
			if !$ModulatePlayer.playing or !$ModulatePlayer.query(["lethal", "lethal_flash"]):
				$ModulatePlayer.play("lethal")
			set_monochrome()
			sprite_shake()
		Globals.status_effect.BREAK:
			if !$ModulatePlayer.playing or !$ModulatePlayer.query(["break", "break_flash"]):
				$ModulatePlayer.play("break")
			particle("Sparkle", "Particles", "yellow", 4, 1, 25) # WIP for the loaded_sfx_ref
			set_monochrome() # you want to do shaders here instead of new_status_effect() since shaders can be changed
			sprite_shake()
		Globals.status_effect.REPEAT:
			set_monochrome()
		Globals.status_effect.RESPAWN_GRACE:
			if !$ModulatePlayer.playing or !$ModulatePlayer.query(["break", "respawn_grace"]):
				$ModulatePlayer.play("respawn_grace")

func remove_status_effect(effect): # comb through the dictionary to remove a specific status effect
	var effect_to_erase = []
	for status_effect in status_effects:
		if status_effect[0] == effect:
			effect_to_erase.append(status_effect)
	for status_effect in effect_to_erase:
		status_effects.erase(status_effect)
		clear_visual_effect_of_status(status_effect[0])
		
func remove_all_status_effects():
	for status_effect in status_effects:
		clear_visual_effect_of_status(status_effect[0])
	status_effects = []
		
func clear_visual_effect_of_status(effect): # must run this when removing status effects to remove the visual effect
	match effect:
		Globals.status_effect.LETHAL, Globals.status_effect.BREAK:
			if $ModulatePlayer.query_current(["lethal", "break"]):
				palette()
				reset_modulate()
				sprite.position = Vector2.ZERO
		Globals.status_effect.REPEAT:
			palette()
		Globals.status_effect.RESPAWN_GRACE:
			if $ModulatePlayer.query_current(["respawn_grace"]):
				reset_modulate()
		Globals.status_effect.POS_FLOW:
			Globals.Game.HUD.get_node("P" + str(player_ID + 1) + "_HUDRect/GaugesUnder/GuardGauge1").texture_progress = \
					Globals.loaded_guard_gauge
				
func test_status_visual_effect_priority():
	# visual effects of status effects like Poison has lower priority over effects like EX
	pass
	
func sprite_shake(): # used for Break and lethal blows
	if Globals.Game.frametime % 2 == 0:  # only shake every 2 frames
		var random = rng_generate(9) + 1
		var shake := Vector2.ZERO
		match random:
			1, 2, 3:
				shake.y = 2
				continue
			7, 8, 9:
				shake.y = -2
				continue
			9, 6, 3:
				shake.x = 2
				continue
			7, 4, 1:
				shake.x = -2
		sprite.position = shake
				
	
# HIT DETECTION AND PROCESSING ---------------------------------------------------------------------------------------------------

func query_polygons(): # requested by main game node when doing hit detection
	
	var polygons_queried = {
		"hurtbox" : null,
		"sdhurtbox" : null,
		"hitbox" : null,
		"sweetbox": null,
		"kborigin": null,
	}

	if is_attacking():
		if is_atk_active():
			if !$HitStopTimer.is_running(): # no hitbox during hitstop
				polygons_queried.hitbox = Animator.query_polygon("hitbox")
				polygons_queried.sweetbox = Animator.query_polygon("sweetbox")
				polygons_queried.kborigin = Animator.query_point("kborigin")
		polygons_queried.sdhurtbox = Animator.query_polygon("sdhurtbox")
		
	if query_status_effect(Globals.status_effect.RESPAWN_GRACE):
		pass  # no hurtbox during respawn grace
	if $HitStunGraceTimer.is_running() and new_state in [Globals.char_state.GROUND_STARTUP, Globals.char_state.GROUND_ACTIVE, \
			Globals.char_state.GROUND_RECOVERY, Globals.char_state.AIR_STARTUP, Globals.char_state.AIR_ACTIVE, \
			Globals.char_state.AIR_RECOVERY]:
		pass  # no hurtbox during HitStunGrace in certain states
	else:
		polygons_queried.hurtbox = Animator.query_polygon("hurtbox")

	return polygons_queried
	
	
func query_move_data_and_name(): # requested by main game node when doing hit detection
	if Animator.query(["BurstCounter"]):
		return {"move_data" : LoadedSFX.burst_escape_move_data, "move_name" : "Burst"}
	if Animator.query(["BurstEscape"]):
		return {"move_data" : LoadedSFX.burst_counter_move_data, "move_name" : "Burst"}
	if Animator.query(["BurstExtend"]):
		return {"move_data" : LoadedSFX.burst_extend_move_data, "move_name" : "Burst"}
	
	if Animator.to_play_animation.ends_with("Active"):
		var move_name = Animator.to_play_animation.trim_suffix("Active")
		if UniqueCharacter.MOVE_DATABASE.has(move_name):
			return {"move_data" : UniqueCharacter.query_move_data(move_name), "move_name" : move_name}
	else:
		print("Error: query_move_data_and_name() called by main game node outside of Active frames")
		return null
		
	
func test_chain_combo(attack_ref): # attack_ref is the attack you want to chain to
	
	if !is_atk_recovery() and !is_atk_active(): return false
	if chain_combo == 0: return false # can only chain combo on hit
	if attack_ref in chain_memory: return false # cannot chain into moves already done
	
	var move_name = Animator.current_animation.trim_suffix("Recovery")
	move_name = move_name.trim_suffix("Active")
	
	if !move_name in UniqueCharacter.MOVE_DATABASE:
		return false # just in case
	
#	# test if chaining into itself
#	if move_name == attack_ref:
#		return false # can only chain combo into a different move
#	if "root" in UniqueCharacter.MOVE_DATABASE[move_name] and UniqueCharacter.MOVE_DATABASE[move_name].root == attack_ref:
#		return false # for move variations/auto-chains with a root move

	if Globals.atk_attr.NO_CHAIN in query_atk_attr(move_name):
		return false
	
	if chain_combo == 2: # on blocking opponent, can only chain into moves of higher strength
		if get_atk_strength(move_name) >= get_atk_strength(attack_ref):
			return false
	
	shadow_cancel()
	return true
#	return is_normal_attack(move_name) # can only chain combo if chaining from a Normal Attack, just in case
	
func test_qc_chain_combo(attack_ref):
	
	if attack_ref in chain_memory: return false # cannot quick cancel into moves already done
	
	if chain_combo == 2: # on blocking opponent, can only qc into moves of higher strength
		if get_atk_strength(chain_memory.back()) >= get_atk_strength(attack_ref):
			return false
	else: return true
	
	
func get_atk_strength(move):
	if !move in UniqueCharacter.MOVE_DATABASE:
		return 0 # just in case
	match UniqueCharacter.MOVE_DATABASE[move].atk_type:
		Globals.atk_type.LIGHT:
			return 0
		Globals.atk_type.FIERCE:
			return 1
		Globals.atk_type.HEAVY:
			return 2
		Globals.atk_type.SPECIAL:
			return 3
		Globals.atk_type.EX:
			return 4
		Globals.atk_type.SUPER:
			return 5
	
# HITCOUNT RECORD ------------------------------------------------------------------------------------------------
	
func increment_hitcount(in_ID):
	for record in hitcount_record: # look for player ID in hitcount_record to increment
		if record[0] == in_ID:
			record[1] += 1
			return
	hitcount_record.append([in_ID, 1]) # if not found, create a new record
	
func get_hitcount(in_ID):
	for record in hitcount_record: # search hitcount record for this player
		if record[0] == in_ID:
			return record[1]
	return 0
	
func is_hitcount_maxed(in_ID, move_data): # called by main game node
	var recorded_hitcount = get_hitcount(in_ID)
	
	if recorded_hitcount >= move_data.hitcount:
		return true
	else: return false
	
	
func is_hitcount_last_hit(in_ID, move_data):
	var recorded_hitcount = get_hitcount(in_ID)
	
	if recorded_hitcount >= move_data.hitcount - 1:
		return true
	else: return false
	
#	# test record to see if hit the hitcount limit of the current move
#	var move_name = Animator.current_animation.trim_suffix("Startup") # check current 1st
#	move_name = move_name.trim_suffix("Active")
#	move_name = move_name.trim_suffix("Recovery")
#	if move_name in UniqueCharacter.MOVE_DATABASE:
#		if recorded_hitcount >= UniqueCharacter.MOVE_DATABASE[move_name].hitcount - 1:
#			return true
#	else:
#		move_name = get_move_name().trim_suffix("Startup") # check to_play next
#		move_name = move_name.trim_suffix("Active")
#		move_name = move_name.trim_suffix("Recovery")
#		if move_name in UniqueCharacter.MOVE_DATABASE:
#			if recorded_hitcount >= UniqueCharacter.MOVE_DATABASE[move_name].hitcount - 1:
#				return true
#	return false
	
func is_hitcount_first_hit(in_ID): # for multi-hit moves, only 1st hit affect Guard Gauge
	var recorded_hitcount = get_hitcount(in_ID)
	if recorded_hitcount == 0: return true
	else: return false
	
# IGNORE LIST ------------------------------------------------------------------------------------------------
	
func append_ignore_list(in_ID, ignore_time): # added if the move has "ignore_time"
	for ignored in ignore_list:
		if ignored[0] == in_ID:
			print("Error: attempting to ignore an ignored player")
			return
	ignore_list.append([in_ID, ignore_time])
		
func ignore_list_progress_timer(): # progress time and remove those that ran out of time
	var to_erase = []
	for ignored in ignore_list:
		ignored[1] -= 1
		if ignored[1] <= 0:
			to_erase.append(ignored)
	for x in to_erase: # cannot erase items from array while iterating through it
		ignore_list.erase(x)
		
func is_player_in_ignore_list(in_ID):
	for ignored in ignore_list:
		if ignored[0] == in_ID:
			return true
	return false
		
func atk_startup_resets():# ran whenever an attack starts
	hitcount_record = []
	ignore_list = []
	
# -----------------------------------------------------------------------------------------------------------------------------
	
func get_damage_percent():
	return current_damage_value / UniqueCharacter.DAMAGE_VALUE_LIMIT
	
func get_guard_gauge_percent_below():
	if current_guard_gauge <= GUARD_GAUGE_FLOOR:
		return 0.0
	elif current_guard_gauge < 0:
		return 1.0 - (current_guard_gauge / GUARD_GAUGE_FLOOR)
	else: return 1.0
	
func get_guard_gauge_percent_above():
	if current_guard_gauge >= GUARD_GAUGE_CEIL:
		return 1.0
	elif current_guard_gauge > 0:
		return (current_guard_gauge / GUARD_GAUGE_CEIL)
	else: return 0.0
	
func take_damage(damage): # called by attacker
	current_damage_value += damage
	current_damage_value = round(current_damage_value)
	Globals.Game.damage_update(self, damage)
	
func change_guard_gauge(guard_gauge_change): # called by attacker
	current_guard_gauge += guard_gauge_change
	current_guard_gauge = clamp(current_guard_gauge, GUARD_GAUGE_FLOOR, GUARD_GAUGE_CEIL)
	current_guard_gauge = round(current_guard_gauge)
	Globals.Game.guard_gauge_update(self)
	
func reset_guard_gauge():
	current_guard_gauge = 0
	Globals.Game.guard_gauge_update(self)
	
func change_guard_gauge_percent(guard_gauge_change_percent):
	var guard_gauge_change := 0.0
	
	if guard_gauge_change_percent < 0: # reduce GG
		if current_guard_gauge > 0:
			
			var GG_above_percent = get_guard_gauge_percent_above()
			if GG_above_percent >= abs(guard_gauge_change_percent): # if enough, substract normally
				guard_gauge_change = guard_gauge_change_percent * abs(GUARD_GAUGE_CEIL)
				
			else: # not enough, must go under 0
				guard_gauge_change_percent += GG_above_percent # get leftovers
				guard_gauge_change = -current_guard_gauge # lower to 0 1st
				guard_gauge_change += guard_gauge_change_percent * abs(GUARD_GAUGE_FLOOR) # reduce below 0
				
		else: # GG below 0, substract normally
			guard_gauge_change = guard_gauge_change_percent * abs(GUARD_GAUGE_FLOOR)
			
	elif guard_gauge_change_percent > 0: # increase GG
		if current_guard_gauge < 0:
			
			var GG_below_percent = get_guard_gauge_percent_below()
			if GG_below_percent <= abs(guard_gauge_change_percent): # if low enough, increase normally
				guard_gauge_change = guard_gauge_change_percent * abs(GUARD_GAUGE_FLOOR)
				
			else: # will go above 0
				guard_gauge_change_percent -= 1.0 - GG_below_percent # get leftovers
				guard_gauge_change = -current_guard_gauge # raise to 0 1st
				guard_gauge_change += guard_gauge_change_percent * abs(GUARD_GAUGE_CEIL) # raise above 0
							
		else: # over 0, increase normally
			guard_gauge_change = guard_gauge_change_percent * abs(GUARD_GAUGE_CEIL)
			
	change_guard_gauge(guard_gauge_change)
	
	
func change_ex_gauge(ex_gauge_change):
#	current_ex_gauge += ex_gauge_change * 3 # boosted for testing
	current_ex_gauge += ex_gauge_change
	current_ex_gauge = clamp(current_ex_gauge, 0.0, MAX_EX_GAUGE)
	current_ex_gauge = round(current_ex_gauge)
	Globals.Game.ex_gauge_update(self)

func change_stock_points(stock_points_change):
	stock_points_left += stock_points_change
	stock_points_left = max(stock_points_left, 0.0)
	stock_points_left = round(stock_points_left)
	Globals.Game.stock_points_update(self, stock_points_change)
	
func change_burst_token(get_burst: bool):
	has_burst = get_burst
	Globals.Game.burst_update(self)
	
# LANDING A HIT ---------------------------------------------------------------------------------------------- 
	
func landed_a_hit(hit_data): # called by main game node when landing a hit
	
	UniqueCharacter.landed_a_hit(hit_data) # reaction, nothing here yet, can change hit_data from there
	
	var defender = get_node(hit_data.defender_nodepath)
	increment_hitcount(defender.player_ID) # for measuring hitcount of attacks
	targeted_opponent = defender.player_ID # target last attacked opponent
	
	if current_guard_gauge < 0 and hit_data.adjusted_atk_level > 1 and \
			!hit_data.block_state in [Globals.block_state.GROUND_PERFECT, Globals.block_state.AIR_PERFECT]:
		add_status_effect(Globals.status_effect.POS_FLOW, null) # gain Positive Flow if GG is under 100%, atk_level > 1 and not p-blocked
	
	# EX GAIN ----------------------------------------------------------------------------------------------
	
	match hit_data.block_state:
		Globals.block_state.UNBLOCKED:
			if !hit_data.double_repeat:
				change_ex_gauge(hit_data.move_data.EX_gain)
			defender.change_ex_gauge(hit_data.move_data.EX_gain * 0.25)
		Globals.block_state.AIR_WRONG, Globals.block_state.GROUND_WRONG:
			if !hit_data.double_repeat:
				change_ex_gauge(hit_data.move_data.EX_gain)
		Globals.block_state.AIR_PERFECT, Globals.block_state.GROUND_PERFECT:
			defender.change_ex_gauge(hit_data.move_data.EX_gain)
		_:  # normal block
			if !hit_data.double_repeat:
				change_ex_gauge(hit_data.move_data.EX_gain * 0.5)
				defender.change_ex_gauge(hit_data.move_data.EX_gain * 0.5)
	
	# ATTACKER HITSTOP ----------------------------------------------------------------------------------------------
		# hitstop is only set into HitStopTimer at end of frame
	
	if "fixed_atker_hitstop" in hit_data.move_data:
		# multi-hit special/super moves are done by having lower atker hitstop then defender hitstop, and high "hitcount" and ignore_time
		hitstop = hit_data.move_data.fixed_atker_hitstop
	elif !hit_data.break_hit:
		if hitstop == null or hit_data.hitstop > hitstop: # need to do this to set consistent hitstop during clashes
			hitstop = hit_data.hitstop
	else:
		if hitstop == null or hit_data.hitstop > hitstop:
			hitstop = BREAK_HITSTOP_ATTACKER # fixed hitstop for attacking for Break Hits
	
	# CANCELING ----------------------------------------------------------------------------------------------
		# only set chain_combo and dash_cancel to true if no Repeat Penalty and not perfect blocked
		
	if Globals.atk_attr.NO_CHAIN_ON_BLOCK in query_atk_attr(hit_data.move_name) and hit_data.block_state != Globals.block_state.UNBLOCKED and \
			hit_data.block_state != Globals.block_state.GROUND_WRONG and hit_data.block_state != Globals.block_state.AIR_WRONG:
		
		chain_combo = 0 # no chain combo if a move with NO_CHAIN_ON_BLOCK is blocked, unless it's wrongblocked
		# NO_CHAIN_ON_BLOCK is for moves like anti-air to become punishable on block, not for Heavy attacks
		
	elif !hit_data.double_repeat and hit_data.block_state != Globals.block_state.AIR_PERFECT and \
			hit_data.block_state != Globals.block_state.GROUND_PERFECT:
				
		match hit_data.move_data.atk_type:
			
			Globals.atk_type.LIGHT, Globals.atk_type.FIERCE, Globals.atk_type.HEAVY:
				# if it's a normal, allow chaining into other normals and do jump cancel (for aerial) on hit/block
				if hit_data.block_state == Globals.block_state.UNBLOCKED or \
					hit_data.block_state == Globals.block_state.GROUND_WRONG or \
					hit_data.block_state == Globals.block_state.AIR_WRONG:
					chain_combo = 1 
				else:
					chain_combo = 2 # if blocked properly, can only chain combo into normals of higher strength or specials
					
				
				if hit_data.sweetspotted or hit_data.punish_hit:
					dash_cancel = true # for sweetspotted/punish hit, allow dash_cancel
					
				if is_aerial() and hit_data.block_state in [Globals.block_state.UNBLOCKED, Globals.block_state.GROUND_WRONG, \
						Globals.block_state.AIR_WRONG]:
					gain_one_air_jump() # for unblocked/wrongblocked aerial you regain 1 air jump
					if hit_data.sweetspotted:
						UniqueCharacter.gain_one_air_dash() # for unblocked sweetspotted aerial you regain 1 air dash
			_:
				# for specials/EX, sweetspotting allowing you to get a discount on Advance during active and recovery frames
				# no sweetspots on supers
				pass
				
		if hit_data.block_state == Globals.block_state.UNBLOCKED and \
				Globals.atk_attr.JUMP_CANCEL in query_atk_attr(hit_data.move_name):
			jump_cancel = true
				
	# BLOCK PUSHBACK ----------------------------------------------------------------------------------------------
		# if blocked hit, pushback
	
	if hit_data.block_state != Globals.block_state.UNBLOCKED and is_hitcount_last_hit(defender.player_ID, hit_data.move_data):
		 # for multi-hit only last hit has pushback
		var pushback_strength := 0.0
		match hit_data.block_state:
			Globals.block_state.AIR_WRONG, Globals.block_state.GROUND_WRONG:
				pushback_strength = WRONGBLOCK_ATKER_PUSHBACK
			Globals.block_state.AIR_PERFECT, Globals.block_state.GROUND_PERFECT:
				pushback_strength = PERFECTBLOCK_ATKER_PUSHBACK
			_:
				pushback_strength = BASE_BLOCK_ATKER_PUSHBACK # normal block
		var pushback_dir = hit_data.angle_to_atker
		var pushback_dir_enum = Globals.split_angle(pushback_dir, 4, facing) # this return an enum
		pushback_dir = Globals.compass_to_angle(pushback_dir_enum)	
		velocity += Vector2(pushback_strength, 0).rotated(pushback_dir) # reset momentum
		
	# AUDIO ----------------------------------------------------------------------------------------------
	
	if hit_data.block_state != Globals.block_state.UNBLOCKED: # block sound
		match hit_data.block_state:
			Globals.block_state.AIR_WRONG, Globals.block_state.GROUND_WRONG:
				play_audio("block3", {"vol" : -15})
			Globals.block_state.AIR_PERFECT, Globals.block_state.GROUND_PERFECT:
				play_audio("bling2", {"vol" : -3, "bus" : "PitchDown"})
			_: # normal block
				play_audio("block1", {"vol" : -10, "bus" : "LowPass"})

	elif hit_data.semi_disjoint and !Globals.trait.VULN_LIMBS in defender.query_traits(): # SD Hit sound
		play_audio("bling3", {"bus" : "LowPass"})
		
	elif "hit_sound" in hit_data.move_data:
		
		var volume_change = 0
		if hit_data.lethal_hit or hit_data.break_hit or hit_data.sweetspotted:
			volume_change += STRONG_HIT_AUDIO_BOOST
		elif hit_data.move_data.attack_level <= 1 or hit_data.double_repeat or hit_data.semi_disjoint: # last for VULN_LIMBS
			volume_change += WEAK_HIT_AUDIO_NERF # WEAK_HIT_AUDIO_NERF is negative
		
		if !hit_data.move_data.hit_sound is Array:
			
			var aux_data = hit_data.move_data.hit_sound.aux_data.duplicate(true)
			if "vol" in aux_data:
				aux_data["vol"] = min(aux_data["vol"] + volume_change, 0) # max is 0
			elif volume_change < 0:
				aux_data["vol"] = volume_change
			play_audio(hit_data.move_data.hit_sound.ref, aux_data)
			
		else: # multiple sounds at once
			for sound in hit_data.move_data.hit_sound:
				var aux_data = sound.aux_data.duplicate(true)
				if "vol" in aux_data:
					aux_data["vol"] = min(aux_data["vol"] + volume_change, 0) # max is 0
				elif volume_change < 0:
					aux_data["vol"] = volume_change
				play_audio(sound.ref, aux_data)
	

# TAKING A HIT ---------------------------------------------------------------------------------------------- 	

func being_hit(hit_data): # called by main game node when taking a hit
	
	$HitStunGraceTimer.time = HitStunGraceTimer_TIME # reset HitStunGraceTimer which only ticks down out of hitstun/blockstun

	
	var attacker = get_node(hit_data.attacker_nodepath)
	var defender = get_node(hit_data.defender_nodepath)
	
	var attacker_or_entity = attacker # cleaner code
	if "entity_nodepath" in hit_data:
		attacker_or_entity = get_node(hit_data.entity_nodepath)

	
	targeted_opponent = attacker.player_ID # target opponent who last attacked you
	
	# get direction to attacker
	var vec_to_attacker = attacker_or_entity.position - defender.position
	if vec_to_attacker.x == 0: # rare case of attacker directly on defender
		 vec_to_attacker.x = hit_data.attack_facing
	var dir_to_attacker = sign(vec_to_attacker.x) # for setting facing on defender
		
	if "ignore_time" in hit_data.move_data: # some moves only hit once every few frames, done via an ignore list on the attacker/projectile
			attacker_or_entity.append_ignore_list(defender.player_ID, hit_data.move_data.ignore_time)
			
			
	hit_data["angle_to_atker"] = atan2(vec_to_attacker.y, vec_to_attacker.x)
	
	hit_data["lethal_hit"] = false
	hit_data["punish_hit"] = false
	hit_data["break_hit"] = false
	hit_data["block_state"] = Globals.block_state.UNBLOCKED # WIP
	hit_data["repeat_penalty"] = false
	hit_data["double_repeat"] = false
	
	# REPEAT PENALTY AND WEAK HITS ----------------------------------------------------------------------------------------------
		
	var double_repeat = false
	for array in move_memory:
		if array[0] == attacker.player_ID and array[1] == hit_data.move_name:
			if !hit_data.repeat_penalty:
				hit_data.repeat_penalty = true # found a repeat
				if Globals.atk_attr.NO_REPEAT in attacker.query_atk_attr(hit_data.move_name):
					double_repeat = true
					hit_data["double_repeat"] = true
			elif !double_repeat:
				double_repeat = true
				hit_data["double_repeat"] = true # found multiple repeats
				break
	# append repeated move to move_memory later after guard gauge change calculation
	# for projectiles, use the attacker's ID
	
	var weak_hit
	if hit_data.move_data.attack_level <= 1 or hit_data.double_repeat or hit_data.semi_disjoint or \
			!attacker_or_entity.is_hitcount_last_hit(defender.player_ID, hit_data.move_data): # multi-hit moves cannot cause lethal/break/sweetspot/punish outside of last hit
		weak_hit = true
		hit_data.sweetspotted = false # cannot sweetspot for weak hits
		
	hit_data["weak_hit"] = weak_hit
		
		
	# CHECK BLOCK STATE ----------------------------------------------------------------------------------------------
	
	
	match defender.state:
		
		Globals.char_state.GROUND_ATK_STARTUP:
			if !Globals.atk_attr.ANTI_GUARD in attacker.query_atk_attr(hit_data.move_name) and \
					Globals.atk_attr.SUPERARMOR in defender.query_atk_attr(): # defender has superarmor
				hit_data.block_state = Globals.block_state.GROUND_WRONG
		Globals.char_state.AIR_ATK_STARTUP:		
			if !Globals.atk_attr.ANTI_GUARD in attacker.query_atk_attr(hit_data.move_name) and \
					Globals.atk_attr.SUPERARMOR in defender.query_atk_attr(): # defender has superarmor
				hit_data.block_state = Globals.block_state.AIR_WRONG
		
		Globals.char_state.GROUND_BLOCK, Globals.char_state.GROUND_BLOCKSTUN:
			hit_data.sweetspotted = false # blocking will not cause sweetspot hits
			
			if (defender.get_node("PBlockTimer").is_running() or defender.Animator.query(["PBlockstun", "AirPBlockStun"])) and \
				!Globals.atk_attr.ANTI_GUARD in attacker.query_atk_attr(hit_data.move_name): # cannot p-block hard-to-block moves
				# being in PBlockstun will continue to PBlock all attacks
				hit_data.block_state = Globals.block_state.GROUND_PERFECT
				
			elif !"entity_nodepath" in hit_data and Globals.atk_attr.ANTI_GUARD in attacker.query_atk_attr(hit_data.move_name) and \
					attacker.chain_memory.size() == 0 and !defender.get_node("BlockStunTimer").is_running():
				# ANTI_GUARD attacks cannot work if opponent is in blockstun or you chain into it
				hit_data.block_state = Globals.block_state.GROUND_WRONG
				
			elif "entity_nodepath" in hit_data and Globals.atk_attr.ANTI_GUARD in attacker.query_atk_attr(hit_data.move_name) and \
					!defender.get_node("BlockStunTimer").is_running():
				# rare ANTI_GUARD projectiles, ignore chaining requirement
				hit_data.block_state = Globals.block_state.GROUND_WRONG
				
			elif defender.Animator.query(["WBlockstun"]): # being in WBlockstun will continye to WBlock all attacks
				hit_data.block_state = Globals.block_state.GROUND_WRONG
			elif defender.Animator.query(["Blockstun", "PBlockstun"]):
				# being in non-WrongBlock Blockstun will contine to block normally even wrong attacks, no unblockable setups
				hit_data.block_state = Globals.block_state.GROUND
				
			elif !"entity_nodepath" in hit_data and check_if_crossed_up(vec_to_attacker): # projectiles cannot cross-up
				hit_data.block_state = Globals.block_state.GROUND_WRONG
				
			else:
				hit_data.block_state = Globals.block_state.GROUND
				
		Globals.char_state.AIR_BLOCK, Globals.char_state.AIR_BLOCKSTUN:
			hit_data.sweetspotted = false  # blocking will not cause sweetspot hits

			if Globals.atk_attr.ANTI_AIR in attacker.query_atk_attr(hit_data.move_name):
				hit_data.block_state = Globals.block_state.AIR_WRONG # anti-air attacks always wrongblock airborne defenders
			
			elif ((defender.get_node("PBlockTimer").is_running() and Globals.trait.AIR_PERFECT_BLOCK in defender.query_traits()) or \
					defender.Animator.query(["PBlockstun", "AirPBlockStun"])) and \
					!Globals.atk_attr.ANTI_GUARD in attacker.query_atk_attr(hit_data.move_name):
				#  being in PBlockstun will continue to PBlock all aerial attacks
				hit_data.block_state = Globals.block_state.AIR_PERFECT # only those with the trait can perfect block in air
				
			elif !"entity_nodepath" in hit_data and Globals.atk_attr.ANTI_GUARD in attacker.query_atk_attr(hit_data.move_name) and \
					attacker.chain_memory.size() == 0 and !defender.get_node("BlockStunTimer").is_running():
				# ANTI_GUARD attacks cannot work if opponent is in blockstun or you chain into it
				hit_data.block_state = Globals.block_state.AIR_WRONG
				
			elif "entity_nodepath" in hit_data and Globals.atk_attr.ANTI_GUARD in attacker.query_atk_attr(hit_data.move_name) and \
					!defender.get_node("BlockStunTimer").is_running():
				# rare ANTI_GUARD projectiles, ignore chaining requirement
				hit_data.block_state = Globals.block_state.AIR_WRONG
				
			elif defender.Animator.query(["AirWBlockstun"]): # being in WBlockstun will continye to WBlock all attacks
				hit_data.block_state = Globals.block_state.AIR_WRONG
			elif defender.Animator.query(["AirBlockstun", "AirPBlockstun"]):
				# being in non-WrongBlock Blockstun will contine to block normally even wrong attacks, no unblockable setups
				hit_data.block_state = Globals.block_state.AIR
				
			elif !"entity_nodepath" in hit_data and check_if_crossed_up(vec_to_attacker): # projectiles cannot cross-up
				hit_data.block_state = Globals.block_state.AIR_WRONG
				
			else:
				hit_data.block_state = Globals.block_state.AIR
				
			
	# CHECK PUNISH HIT ----------------------------------------------------------------------------------------------
	
	if !hit_data.weak_hit and hit_data.move_data.damage > 0: # cannot Punish Hit for weak hits and non-damaging moves like Burst
		match defender.state:
			Globals.char_state.GROUND_ATK_ACTIVE, Globals.char_state.GROUND_ATK_RECOVERY, \
					Globals.char_state.AIR_ATK_ACTIVE, Globals.char_state.AIR_ATK_RECOVERY:
				hit_data.punish_hit = true
			# check for Punish Hits for dashes
			Globals.char_state.GROUND_STARTUP, Globals.char_state.GROUND_RECOVERY:
				if Globals.trait.VULN_GRD_DASH in query_traits():
					if Animator.query(["DashTransit", "Dash"]):
						hit_data.punish_hit = true
			Globals.char_state.AIR_STARTUP, Globals.char_state.AIR_RECOVERY:
				if Globals.trait.VULN_AIR_DASH in query_traits():
					if Animator.query(["AirDashTransit", "AirDash", "AirDashU", "AirDashD", "AirDashUU", "AirDashDD"]):
						hit_data.punish_hit = true
						
	
	# DAMAGE AND GUARD DRAIN/GAIN CALCULATION ------------------------------------------------------------------
	
	defender.change_guard_gauge(calculate_guard_gauge_change(hit_data)) # do GG calculation
	
	if defender.get_guard_gauge_percent_below() <= 0.001 and !hit_data.weak_hit and \
			!Globals.atk_attr.AUTOCHAIN in attacker.query_atk_attr(hit_data.move_name):  # check for break hit
		# setting to 0.001 instead of 0 allow multi-hit moves to cause break_hits on the last attack
		hit_data.break_hit = true
		hit_data.block_state = Globals.block_state.UNBLOCKED
		
	defender.take_damage(calculate_damage(hit_data)) # do damage calculation
	if defender.get_damage_percent() >= 1.0 and !hit_data.weak_hit and hit_data.move_data.damage > 0: # check for lethal
		if hit_data.block_state == Globals.block_state.UNBLOCKED or hit_data.block_state == Globals.block_state.AIR_WRONG or \
				hit_data.block_state == Globals.block_state.GROUND_WRONG:
			hit_data.lethal_hit = true
			hit_data.block_state = Globals.block_state.UNBLOCKED # wrongblocking has no effect when damage is over limit
				
	# append repeated move to move memory here since calculation for guard_gauge change uses it
	if !double_repeat and attacker_or_entity.is_hitcount_last_hit(defender.player_ID, hit_data.move_data): # for multi-hit move, only the last hit count
		move_memory.append([attacker.player_ID, hit_data.move_name])
				
				
	# ---------------------------------------------------------------------------------
				
	UniqueCharacter.being_hit(hit_data) # reaction, nothing here yet, can change hit_data from there
	
	# SPECIAL HIT EFFECTS ---------------------------------------------------------------------------------
	
	# for moves that automatically chain into more moves, will not cause lethal or break hits, will have fixed_hitstop and no KB boost
	if Globals.atk_attr.AUTOCHAIN in attacker.query_atk_attr(hit_data.move_name):
		hit_data.lethal_hit = false
	
	if hit_data.double_repeat:
		add_status_effect(Globals.status_effect.REPEAT, 10)
		
	elif hit_data.break_hit:
		add_status_effect(Globals.status_effect.BREAK, 0)
		add_status_effect(Globals.status_effect.BREAK_RECOVER, null) # null means no duration
		defender.move_memory = [] # reset move memory for getting a Break
		Globals.Game.set_screenshake() # screenshake
		$ModulatePlayer.play("break_flash")
		play_audio("break1", {"vol" : -18})
		
	elif hit_data.lethal_hit:
		add_status_effect(Globals.status_effect.LETHAL, 0)
		Globals.Game.set_screenshake()
		$ModulatePlayer.play("lethal_flash")
		play_audio("lethal1", {"vol" : -10, "bus" : "Reverb"})
		
	elif hit_data.punish_hit and hit_data.sweetspotted:
		$ModulatePlayer.play("punish_sweet_flash")
		play_audio("break2", {"vol" : -15})
		play_audio("impact29", {"vol" : -18, "bus" : "LowPass"})
		
	elif hit_data.punish_hit:
		$ModulatePlayer.play("punish_flash")
		play_audio("impact29", {"vol" : -18, "bus" : "LowPass"})
		
	elif hit_data.sweetspotted:
		$ModulatePlayer.play("sweet_flash")
		play_audio("break2", {"vol" : -15})
		
	elif hit_data.block_state != Globals.block_state.UNBLOCKED:
		match hit_data.block_state:
			Globals.block_state.AIR_WRONG, Globals.block_state.GROUND_WRONG:
				$ModulatePlayer.play("wrongblock_flash") 
			Globals.block_state.AIR_PERFECT, Globals.block_state.GROUND_PERFECT:
				$ModulatePlayer.play("perfectblock_flash")
				
	if !hit_data.break_hit and !hit_data.lethal_hit and Globals.atk_attr.SCREEN_SHAKE in attacker.query_atk_attr(hit_data.move_name):
		Globals.Game.set_screenshake()
		
	if hit_data.block_state == Globals.block_state.UNBLOCKED:
		if hit_data.move_name == "BurstCounter":
			attacker.reset_jumps()
			defender.reset_jumps()
			attacker.reset_guard_gauge()
		elif hit_data.move_name == "BurstEscape":
			attacker.reset_jumps()
			defender.reset_jumps()
		elif hit_data.move_name == "BurstExtend":
			attacker.reset_jumps()
			defender.reset_jumps()
			defender.current_guard_gauge = 0.0
			Globals.Game.guard_gauge_update(defender)
			defender.move_memory = []
			
	# -------------------------------------------------------------------------------------------
	
	var adjusted_atk_level = adjusted_atk_level(hit_data) # check for weak hit
	hit_data["adjusted_atk_level"] = adjusted_atk_level
	
	if adjusted_atk_level > 1 and !hit_data.block_state in [Globals.block_state.GROUND_PERFECT, Globals.block_state.AIR_PERFECT]:
		 # loses Positive Flow for atk_level > 1 if not perfect blocked
		defender.status_effect_to_remove.append(Globals.status_effect.POS_FLOW)
		# remove it at end of frame, this way both players loses positive flow during clashes
	
	if hit_data.block_state == Globals.block_state.UNBLOCKED:
		$HitStunTimer.time = calculate_hitstun(hit_data)
		orig_hitstun = $HitStunTimer.time # used to calculation sprite rotation during launched state
	else:
		$BlockStunTimer.time = calculate_blockstun(hit_data)
	
#	print($HitStunTimer.time)
	
	$VarJumpTimer.stop()
	
	# WIP, some modulate animations stop if you are hit
	
	# these take into account blocking
	var knockback_dir = calculate_knockback_dir(hit_data)
	hit_data["knockback_dir"] = knockback_dir
	var knockback_strength = calculate_knockback_strength(hit_data)
	hit_data["knockback_strength"] = knockback_strength
	
#	print(knockback_strength)
	
	# HITSTOP ---------------------------------------------------------------------------------------------------
	
	if !hit_data.lethal_hit:
		hitstop = calculate_hitstop(hit_data, knockback_strength)
	else:
		hitstop = LETHAL_HITSTOP # set for both attacker and defender
		
	hit_data["hitstop"] = hitstop # send this to attacker as well
	
	if hit_data.break_hit:
		hitstop = BREAK_STUN_TIME # fixed hitstop overwrite for stun time when Broken
	
	# HITSPARK ---------------------------------------------------------------------------------------------------
	
	if hit_data.block_state == Globals.block_state.UNBLOCKED:
		generate_hitspark(hit_data)
	else:
		generate_blockspark(hit_data)
		
	if hit_data.break_hit: # breakspark is on top of regular hitspark
		var v_mirror := false
		if rng_generate(2) == 0: v_mirror = true
		var out_facing := 1
		if rng_generate(2) == 0: out_facing = -1
		emit_signal("SFX", "Breakspark", "Breakspark", hit_data.hit_center, {"facing":out_facing, "v_mirror":v_mirror})
	
	# ---------------------------------------------------------------------------------------------------
			
	if hit_data.block_state == Globals.block_state.UNBLOCKED:
			
		# if knockback_strength is high enough, get launched, else get flinched
		if knockback_strength <= LAUNCH_THRESHOLD:
			
			face(dir_to_attacker) # turn towards attacker              
			
			if adjusted_atk_level <= 1 and !state in [Globals.char_state.GROUND_STANDBY, Globals.char_state.GROUND_RECOVERY, \
					Globals.char_state.GROUND_C_RECOVERY, Globals.char_state.AIR_STANDBY, Globals.char_state.AIR_RECOVERY, \
					Globals.char_state.AIR_C_RECOVERY] and (knockback_dir == 0.0 or knockback_dir == PI): # last part needed to avoid AirDropHard
				pass # level 1 hit when defender is in non-passive states just push them back
						
			elif hit_data.hit_center.y >= position.y: # A/B depending on height hit
				if grounded:
					animate("FlinchAStop")    
				else:
					animate("AirFlinchAStop") 
			else: 
				if grounded:
					animate("FlinchBStop")    
				else:
					animate("AirFlinchBStop") 
					
		else: # launch
			knockback_strength += LAUNCH_BOOST
			var segment = Globals.split_angle(knockback_dir, 2)
			match segment:
				Globals.compass.N:
					face(-hit_data.attack_facing) # turn towards attacker
					animate("LaunchEStop")
					if facing == 1:
						launch_starting_rot = PI/2
					else:
						launch_starting_rot = 3*PI/2
				Globals.compass.NE:
					face(-1)
					animate("LaunchDStop")
					launch_starting_rot = 7*PI/4
				Globals.compass.E:
					face(-1)
					animate("LaunchCStop")
					launch_starting_rot = 0
				Globals.compass.SE:
					face(-1)
					animate("LaunchBStop")
					launch_starting_rot = 9*PI/4
				Globals.compass.S:
					face(-hit_data.attack_facing) # turn towards attacker
					animate("LaunchAStop")
					if facing == -1:
						launch_starting_rot = PI/2
					else:
						launch_starting_rot = 3*PI/2
				Globals.compass.SW:
					face(1)
					animate("LaunchBStop")
					launch_starting_rot = 7*PI/4
				Globals.compass.W:
					face(1)
					animate("LaunchCStop")
					launch_starting_rot = 0.0
				Globals.compass.NW:
					face(1)
					animate("LaunchDStop")
					launch_starting_rot = PI/4
					
	else: # blocking
		if !"entity_nodepath" in hit_data:
			if attacker.is_hitcount_last_hit(defender.player_ID, hit_data.move_data):
				face(dir_to_attacker) # turn towards attacker, for multi-hit move only the last hit turns blocking defender for cross-ups
		else:
			face(dir_to_attacker) # multi-hit projectiles turn on 1st hit
			
		match hit_data.block_state:
			Globals.block_state.GROUND:
				animate("Blockstun")
				block_rec_cancel = true
			Globals.block_state.GROUND_WRONG:
				if !defender.is_atk_startup():
					animate("WBlockstun")
					block_rec_cancel = false
			Globals.block_state.GROUND_PERFECT:
				animate("PBlockstun")
				block_rec_cancel = true
			Globals.block_state.AIR:
				animate("AirBlockstun")
				block_rec_cancel = true
			Globals.block_state.AIR_WRONG:
				if !defender.is_atk_startup():
					animate("AirWBlockstun")
					block_rec_cancel = false
			Globals.block_state.AIR_PERFECT:
				animate("AirPBlockstun")
				block_rec_cancel = true


	# currently using reset velocity method, round values for more consistency
	var knockback_velocity := Vector2(knockback_strength, 0).rotated(knockback_dir)
	
	if hit_data.block_state != Globals.block_state.UNBLOCKED and grounded:
		knockback_velocity.y = 0 # set horizontal pushback on blocking defender
		
	velocity = knockback_velocity
		
		
# HIT CALCULATION ---------------------------------------------------------------------------------------------------
	
func calculate_damage(hit_data):
	
	var defender = get_node(hit_data.defender_nodepath)
	
	var damage = hit_data.move_data.damage
	
	if hit_data.semi_disjoint:
		if Globals.trait.VULN_LIMBS in defender.query_traits():
			damage *= Globals.trait_lookup(Globals.trait.VULN_LIMBS) # VULN_LIMBS trait cause SD hits to do more damage
		else:
			damage = 0
	elif hit_data.double_repeat:
		damage *= REPEAT_DMG_MOD
	else:
		if hit_data.break_hit:
			damage *= BREAK_DMG_MOD
		if hit_data.sweetspotted:
			damage *= SWEETSPOT_DMG_MOD
		if hit_data.punish_hit:
			damage *= PUNISH_DMG_MOD

	if defender.current_guard_gauge > 0: # damage is reduced by defender's Guard Gauge when it is > 100%
		damage *= lerp(1.0, DMG_REDUCTION_AT_MAX_GG, defender.get_guard_gauge_percent_above())

	if hit_data.block_state != Globals.block_state.UNBLOCKED:
		damage *= defender.UniqueCharacter.BASE_BLOCK_CHIP_DAMAGE_MOD # each character take different amount of chip damage
		match hit_data.block_state:
			Globals.block_state.AIR_WRONG, Globals.block_state.GROUND_WRONG:
				damage *= WRONGBLOCK_CHIP_DMG_MOD # increase chip damage for wrongblock
			Globals.block_state.AIR_PERFECT, Globals.block_state.GROUND_PERFECT:
				damage *= 0 # negate chip damage for perfect block

		
	damage = ceil(damage) # whole numbers for damage, minimum damage is 1
	return damage
	
	
func calculate_guard_gauge_change(hit_data):
	
	var attacker_or_entity = get_node(hit_data.attacker_nodepath) # cleaner code
	if "entity_nodepath" in hit_data:
		attacker_or_entity = get_node(hit_data.entity_nodepath)
		
	var defender = get_node(hit_data.defender_nodepath)
	
	var guard_gauge_change := 0.0
	
	if !attacker_or_entity.is_hitcount_first_hit(defender.player_ID): # for multi-hit moves, only 1st hit affect GG
		return 0.0
	
	if hit_data.block_state == Globals.block_state.UNBLOCKED and (defender.move_memory.size() > 0 or defender.get_node("HitStunTimer").is_running()):
		# on a successful hit while defender in hitstun or a little after, guard_gauge_change is positive
		guard_gauge_change = hit_data.move_data.guard_gain_on_combo
		if hit_data.double_repeat:
			guard_gauge_change *= REPEAT_GGG_MOD # Guard Gain on hitstunned defender is increased on double_repeat
		if hit_data.sweetspotted:
			guard_gauge_change *= SWEETSPOT_GGG_MOD # Guard Gain on hitstunned defender is reduced on sweetspotted hit
		if !"entity_nodepath" in hit_data and attacker_or_entity.perfect_chain:
			guard_gauge_change *= PERFECTCHAIN_GGG_MOD # Guard Gain on hitstunned defender is reduced on perfect chains
	
	else: # defender NOT in hitstun or just recovered from one, or blocking, guard_gauge_change is negative
		guard_gauge_change = -hit_data.move_data.guard_drain
		if hit_data.semi_disjoint:
			guard_gauge_change *= 1.0 # may lower it, or let whiff punishes drain GG?
		elif hit_data.double_repeat:
			guard_gauge_change *= 0.0 # on blockstunned target
		else:
			if hit_data.sweetspotted:
				guard_gauge_change *= SWEETSTOP_GUARD_DRAIN_MOD # Guard Drain on non-hitstunned defender is increased on sweetspotted hit
			if hit_data.punish_hit:
				guard_gauge_change *= PUNISH_GUARD_DRAIN_MOD # Guard Drain on non-hitstunned defender is increased on a punish hit
		
		if hit_data.block_state != Globals.block_state.UNBLOCKED:
			match hit_data.block_state:
				Globals.block_state.AIR_WRONG, Globals.block_state.GROUND_WRONG:
					guard_gauge_change *= WRONGBLOCK_GUARD_DRAIN_MOD # increase GDrain for wrongblock
				Globals.block_state.AIR_PERFECT, Globals.block_state.GROUND_PERFECT:
					guard_gauge_change *= PERFECTBLOCK_GUARD_DRAIN_MOD # reduce/negate GDrain for perfect block
#			if !defender.grounded:
#				guard_gauge_change *= AIRBLOCK_GUARD_DRAIN_MOD # increase GDrain for airblocking opponent
#		else:
#			guard_gauge_change *= FIRST_HIT_GUARD_DRAIN_MOD # 1st hit of a combo or a stray hit inflict guard drain
		
	return round(guard_gauge_change)

	
func calculate_knockback_strength(hit_data):

	var attacker = get_node(hit_data.attacker_nodepath)
	
	var attacker_or_entity = attacker # cleaner code
	if "entity_nodepath" in hit_data:
		attacker_or_entity = get_node(hit_data.entity_nodepath)
		
	var defender = get_node(hit_data.defender_nodepath)

	var knockback_strength = hit_data.move_data.knockback
	
	# for certain multi-hit attacks (not autochain), fixed KB till the last hit
	if "fixed_knockback_multi" in hit_data.move_data and !attacker_or_entity.is_hitcount_last_hit(player_ID, hit_data.move_data):
		knockback_strength = hit_data.move_data.fixed_knockback_multi
	
	if hit_data.semi_disjoint:
		knockback_strength = clamp(knockback_strength, 0, SD_KNOCKBACK_LIMIT)
	elif hit_data.sweetspotted:
		knockback_strength *= SWEETSPOT_KB_MOD
	
	if hit_data.break_hit: # broke the guard
		knockback_strength += LAUNCH_THRESHOLD # increased knockback on a Break hit
	elif hit_data.block_state != Globals.block_state.UNBLOCKED:
		match hit_data.block_state:
			Globals.block_state.AIR_WRONG, Globals.block_state.GROUND_WRONG:
				knockback_strength *= WRONGBLOCK_PUSHBACK_MOD # increase KB for wrongblock
			Globals.block_state.AIR_PERFECT, Globals.block_state.GROUND_PERFECT:
				knockback_strength *= PERFECTBLOCK_PUSHBACK_MOD # reduce/negate KB for perfect block
			_:
				knockback_strength *= BASE_BLOCK_PUSHBACK_MOD # normal block
		if Globals.split_angle(hit_data.knockback_dir) == Globals.compass.S:
			# when being knocked downward (45 degree arc) while blocking, knockback is reduced
			knockback_strength *= DOWNWARD_KB_REDUCTION_ON_BLOCK 

	# for rekkas and combo-type moves/supers, no KB boost for non-finishers, these are considered "weak hits" as well
	if Globals.atk_attr.AUTOCHAIN in attacker.query_atk_attr(hit_data.move_name):
		return knockback_strength

	if hit_data.lethal_hit: # increased knockback on a lethal hit, multi-hit and autochain will not cause lethal
		if !hit_data.break_hit:
			knockback_strength += LAUNCH_THRESHOLD
		knockback_strength *= LETHAL_KB_MOD
		
	elif defender.state == Globals.char_state.CROUCHING: # reduce knockback if opponent is crouching
		knockback_strength *= CROUCH_REDUCTION_MOD
			
#	knockback_strength *= defender.UniqueCharacter.KB_MOD # defender's weight
	
	if attacker_or_entity.is_hitcount_last_hit(player_ID, hit_data.move_data) and defender.get_damage_percent() >= 1.0:
		# no KB boost for multi-hit attacks till the last hit
		var dmg_val_boost = min((defender.get_damage_percent() - 1.0) / 0.25 * 0.5 + 2.0 \
				, DMG_VAL_KB_LIMIT)
		#	0.0 percent damage over is x2.0 knockback
		#	0.25 percent damage over is x2.5 knockback
		# 	0.5 percent damage over is x3.0 knockback
		knockback_strength *= dmg_val_boost
		
	if defender.current_guard_gauge > 0: # knockback is increased by defender's Guard Gauge when it is > 100%
		knockback_strength *= lerp(1.0, UniqueCharacter.KB_BOOST_AT_MAX_GG, defender.get_guard_gauge_percent_above())
	
	return knockback_strength # lethal knockback is around 2000
	
	
func calculate_knockback_dir(hit_data):
	
	var knockback_dir := 0.0
	
	var knockback_type = hit_data.move_data.knockback_type
	var KBOrigin = hit_data.kborigin
	var ref_vector: Vector2 # vector from KBOrigin to hit_center
	if KBOrigin:
		ref_vector = hit_data.hit_center - KBOrigin
	
	match knockback_type:
		Globals.knockback_type.FIXED, Globals.knockback_type.MIRRORED:
			knockback_dir = 2 * PI + hit_data.move_data.KB_angle # mirror knockback angle vertically
			if hit_data.attack_facing < 0:
				knockback_dir = PI - knockback_dir # mirror knockback angle horizontally if needed
				knockback_dir = wrapf(knockback_dir, 0, TAU)
				
			if knockback_type == Globals.knockback_type.MIRRORED:
				if KBOrigin:
					if sign(cos(knockback_dir)) != sign(ref_vector.x):
						knockback_dir = PI - knockback_dir # mirror it again if wrong way
				else: print("Error: No KBOrigin found for knockback_type.MIRRORED")
				
		Globals.knockback_type.RADIAL:
			if KBOrigin:
				knockback_dir = atan2(ref_vector.y, ref_vector.x)
				if hit_data.attack_facing > 0:
					knockback_dir += hit_data.move_data.KB_angle
				else:
					knockback_dir -= hit_data.move_data.KB_angle
			else: print("Error: No KBOrigin found for knockback_type.RADIAL")
			
	# for weak hit and grounded defender, or grounded blocking defender, if the hit is towards left or right, level it
	var defender = get_node(hit_data.defender_nodepath)	
	if defender.grounded and (hit_data.adjusted_atk_level <= 1 or \
			hit_data.block_state != Globals.block_state.UNBLOCKED):
		var segment = Globals.split_angle(knockback_dir, 0)
		if segment == Globals.compass.E or segment == Globals.compass.W:
			knockback_dir = atan2(0, cos(knockback_dir))
				
	return knockback_dir


func adjusted_atk_level(hit_data): # mostly for hitstun and blockstun
	# atk_level = 1 are weak hits and cannot do a lot of stuff, cannot cause hitstun
	
	var attack_level = hit_data.move_data.attack_level
	if hit_data.semi_disjoint: # semi-disjoint hits limit hitstun
		attack_level -= 1 # atk lvl 2 become weak hit
		attack_level = clamp(attack_level, 1, 2)
	elif hit_data.double_repeat:
		return 1 # double repeat is forced attack level 1
	else:
		if hit_data.sweetspotted: # sweetspotted and Punish Hits give more hitstun
			attack_level += 2
			attack_level = clamp(attack_level, 1, 8)
		if hit_data.punish_hit:
			attack_level += 2
			attack_level = clamp(attack_level, 1, 8)
		
	return attack_level
	
	
func calculate_hitstun(hit_data): # hitstun and blockstun determined by attack level and defender's Guard Gauge
	
	if "fixed_hitstun" in hit_data.move_data:
		return hit_data.move_data.fixed_hitstun
	
	var defender = get_node(hit_data.defender_nodepath)
	
	if hit_data.adjusted_atk_level <= 1 and !defender.get_node("HitStunTimer").is_running():
		return 0 # weak hit on opponent not in hitstun

	var hitstun = ceil(lerp(15, 50, (hit_data.adjusted_atk_level - 1)/7.0))
		
	if hit_data.lethal_hit:
		# increased hitstun on a lethal hit and no reduction from high Guard Gauge
		hitstun *= LETHAL_HITSTUN_MOD
		if defender.get_damage_percent() > 1.0:
			hitstun *= defender.get_damage_percent()
	else:
		if defender.current_guard_gauge > 0: # hitstun is reduced by defender's Guard Gauge when it is > 100%
			hitstun *= lerp(1.0, UniqueCharacter.HITSTUN_REDUCTION_AT_MAX_GG, defender.get_guard_gauge_percent_above())
			
		if defender.state == Globals.char_state.CROUCHING: # reduce hitstun if opponent is crouching
			hitstun *= CROUCH_REDUCTION_MOD
		
		
	return hitstun


func calculate_blockstun(hit_data):
	
	var blockstun = max(ceil(calculate_hitstun(hit_data) * 0.4) , MAX_BASE_BLOCKSTUN)
	
	if hit_data.block_state == Globals.block_state.AIR_WRONG or hit_data.block_state == Globals.block_state.GROUND_WRONG:
		blockstun *= WRONGBLOCK_BLOCKSTUN_MOD
	elif hit_data.block_state == Globals.block_state.AIR_PERFECT or hit_data.block_state == Globals.block_state.GROUND_PERFECT:
		blockstun *= PERFECTBLOCK_BLOCKSTUN_MOD
		
	if "fixed_blockstun" in hit_data.move_data:
		blockstun = hit_data.move_data.fixed_blockstun
	
	return blockstun
	
	
func check_if_crossed_up(vec_to_attacker):
	var angle_to_attacker = atan2(vec_to_attacker.y, vec_to_attacker.x)
	var segment = Globals.split_angle(angle_to_attacker, 2)
	if segment == Globals.compass.N or segment == Globals.compass.S:
		return false
	if sign(vec_to_attacker.x) == facing:
		return false
	return true


func calculate_hitstop(hit_data, knockback_strength): # hitstop determined by knockback power
		
	if hit_data.block_state != Globals.block_state.UNBLOCKED:
		match hit_data.block_state:
			Globals.block_state.AIR_PERFECT, Globals.block_state.GROUND_PERFECT:
				return PERFECTBLOCK_HITSTOP # increase hitstop for perfect block
			Globals.block_state.AIR_WRONG, Globals.block_state.GROUND_WRONG:
				return WRONGBLOCK_HITSTOP
			_:
				if "fixed_hitstop" in hit_data.move_data and hit_data.move_data.fixed_hitstop < MIN_HITSTOP:
					return hit_data.move_data.fixed_hitstop # moves with fixed hitstop should not be slowed by blocking
				return MIN_HITSTOP # normal block or wrong block

	# some moves have predetermined hitstop
	if "fixed_hitstop" in hit_data.move_data:
		return hit_data.move_data.fixed_hitstop
	
	var hitstop_temp = 2 + ceil(knockback_strength / 100.0) # +1 frame of hitstop for each 100 knockback
	
	if hit_data.semi_disjoint: # on semi-disjoint hits, lowest hitstop
		hitstop_temp = MIN_HITSTOP
	else:
		if hit_data.sweetspotted: # sweetspotted hits has 30% more hitstop
			hitstop_temp = ceil(hitstop_temp * SWEETSPOT_HITSTOP_MOD)
		if hit_data.punish_hit: # punish hits has 30% more hitstop
			hitstop_temp = ceil(hitstop_temp * PUNISH_HITSTOP_MOD)
		
	hitstop_temp = clamp(hitstop_temp, MIN_HITSTOP, MAX_HITSTOP) # max hitstop is 13, min hitstop is 5
			
#	print(hitstop_temp)
	return int(hitstop_temp)
	

func generate_hitspark(hit_data): # hitspark size determined by knockback power
	
	var defender = get_node(hit_data.defender_nodepath)
	
	# SD hits have special hitspark, unless has VULN_LIMBS
	if hit_data.semi_disjoint and !Globals.trait.VULN_LIMBS in defender.query_traits():
		var v_mirror := false
		if rng_generate(2) == 0: v_mirror = true
		var out_facing := 1
		if rng_generate(2) == 0: out_facing = -1
		var aux_data = {"facing":out_facing, "v_mirror":v_mirror}
		if UniqueCharacter.SDHitspark_COLOR != "red":
			aux_data["palette"] = UniqueCharacter.SDHitspark_COLOR
		emit_signal("SFX", "SDHitspark", "SDHitspark", hit_data.hit_center, aux_data)
		return
	
	var hitspark_level
	
	if is_burst(hit_data.move_name):
		hitspark_level = 5
	elif hit_data.break_hit:
		hitspark_level = 5 # max size for Break
	else:
		if hit_data.knockback_strength <= LAUNCH_THRESHOLD * 0.4:
			hitspark_level = 1
		elif hit_data.knockback_strength <= LAUNCH_THRESHOLD:
			hitspark_level = 2
		elif hit_data.knockback_strength <= LAUNCH_THRESHOLD * 1.7:
			hitspark_level = 3
		elif hit_data.knockback_strength <= LAUNCH_THRESHOLD * 2.0:
			hitspark_level = 4
		else:
			hitspark_level = 5
		
		if hit_data.sweetspotted or hit_data.punish_hit: # if sweetspotted/punish hit, hitspark level increased by 1
			hitspark_level = clamp(hitspark_level + 1, 1, 5) # max is 5
#		elif hit_data.repeat_penalty: # reduce by 1 if repeat
#			hitspark_level = clamp(hitspark_level - 1, 1, 5) # min is 5
		
	var hitspark = ""
		
	match hit_data.move_data.hitspark_type:
		Globals.hitspark_type.HIT:
			match hitspark_level:
#				1:
#					hitspark = "HitsparkA"
				1, 2:
					hitspark = "HitsparkB"
				3, 4:
					hitspark = "HitsparkC"
				5:
					hitspark = "HitsparkD"
		Globals.hitspark_type.SLASH:
			match hitspark_level:
#				1:
#					hitspark = "SlashsparkA"
				1, 2:
					hitspark = "SlashsparkB"
				3, 4:
					hitspark = "SlashsparkC"
				5:
					hitspark = "SlashsparkD"
					
	var v_mirror := false
	if rng_generate(2) == 0: v_mirror = true # 50% change of mirror the hitspark
	var aux_data = {"rot": hit_data.knockback_dir + PI, "v_mirror":v_mirror}
	if hit_data.move_data["hitspark_palette"] != "red":
		aux_data["palette"] = hit_data.move_data["hitspark_palette"]
	emit_signal("SFX", hitspark, hitspark, hit_data.hit_center, aux_data)
	
	
func generate_blockspark(hit_data):
	
	var block_dir_enum = Globals.split_angle(hit_data.angle_to_atker, 4, facing) # this return an enum
	var block_dir = Globals.compass_to_angle(block_dir_enum)
	
	var blockspark
	if hit_data.block_state == Globals.block_state.AIR_WRONG or hit_data.block_state == Globals.block_state.GROUND_WRONG:
		blockspark = "WBlockspark"
	elif hit_data.block_state == Globals.block_state.AIR_PERFECT or hit_data.block_state == Globals.block_state.GROUND_PERFECT:
		blockspark = "PBlockspark"
	else:
		blockspark = "Blockspark"
	emit_signal("SFX", blockspark, "Blocksparks", hit_data.hit_center, {"rot" : block_dir})
	
		
# ANIMATION AND AUDIO PROCESSING ---------------------------------------------------------------------------------------------------
	
# universal actions
func _on_SpritePlayer_anim_finished(anim_name):
	
	if is_atk_startup():
		reset_cancels()
	
	match anim_name:
		"RunTransit":
			animate("Run")
		"CrouchTransit", "HardLanding":
			animate("Crouch")   
		"CrouchReturn", "SoftLanding", "Brake":
			animate("Idle")
			
		"JumpTransit":
			animate("JumpTransit2")
		"JumpTransit2":
			animate("JumpTransit3")
		"AirJumpTransit":
			animate("AirJumpTransit2")
		"WallJumpTransit":
			animate("WallJumpTransit2")
		"AirJumpTransit2", "WallJumpTransit2":
			animate("AirJumpTransit3")
		"JumpTransit3", "AirJumpTransit3":
			animate("Jump")
		"FallTransit":
			animate("Fall")
			
		"FlinchAStop":
			animate("FlinchA")
		"FlinchBStop":
			animate("FlinchB")
		"FlinchAReturn", "FlinchBReturn":
			animate("Idle")
			
		"AirFlinchAStop":
			animate("AirFlinchA")
		"AirFlinchBStop":
			animate("AirFlinchB")
		"AirFlinchAReturn", "AirFlinchBReturn":
			animate("FallTransit")
			
		"LaunchAStop", "LaunchBStop", "LaunchCStop", "LaunchDStop", "LaunchEStop":
			animate("LaunchTransit")
		"LaunchTransit":
			animate("Launch")
			
		"BlockStartup":
			animate("Block")
		"BlockstunReturn":
			animate("Block")
		"BlockRecovery":
			animate("Idle")
		"BlockCRecovery":
			animate("Idle")
		"AirBlockStartup":
			animate("AirBlock")
		"AirBlockstunReturn":
			animate("AirBlock")
		"AirBlockRecovery":
			animate("FallTransit")
		"AirBlockCRecovery":
			animate("FallTransit")
		"BlockLanding":
			animate("Block")
		"WBlockstun": # special, will return to regular blockstun after 6 frames (subjected to change)
			animate("Blockstun")
		"AirWBlockstun": # special, will return to regular blockstun after 6 frames (subjected to change)
			animate("AirBlockstun")
			
		"BurstCounterStartup":
			animate("BurstCounter")
		"BurstCounter":
			animate("BurstRecovery")
		"BurstEscapeStartup":
			animate("BurstEscape")
		"BurstEscape":
			animate("BurstRecovery")
		"BurstExtend":
			animate("BurstRecovery")
		"BurstRecovery":
			animate("FallTransit")

	UniqueCharacter._on_SpritePlayer_anim_finished(anim_name)


func _on_SpritePlayer_anim_started(anim_name):
	
	state = state_detect(Animator.current_animation) # update state
	
	if is_atk_startup():
		var move_name = anim_name.trim_suffix("Startup")
		if move_name in UniqueCharacter.MOVE_DATABASE:
			if Globals.atk_attr.AIR_ATTACK in UniqueCharacter.MOVE_DATABASE[move_name].atk_attr:
				aerial_memory.append(move_name)  #add to aerial memory if needed
				
		if dir != 0: # impulse
			if state == Globals.char_state.GROUND_ATK_STARTUP:
#				var move_name = Animator.to_play_animation.trim_suffix("Startup")
				if !impulse_used and move_name in UniqueCharacter.MOVE_DATABASE and \
						!Globals.atk_attr.NO_IMPULSE in UniqueCharacter.MOVE_DATABASE[move_name].atk_attr: # ground impulse
					impulse_used = true
					if button_left in input_state.just_pressed or button_right in input_state.just_pressed:
						velocity.x = dir * UniqueCharacter.SPEED * PERFECT_IMPULSE_MOD
						emit_signal("SFX", "SpecialDust", "DustClouds", get_feet_pos(), {"facing":dir, "grounded":true})
					else:
						velocity.x = dir * UniqueCharacter.SPEED * IMPULSE_MOD
						emit_signal("SFX", "GroundDashDust", "DustClouds", get_feet_pos(), {"facing":dir, "grounded":true})
	else:
		impulse_used = false
		
		if is_atk_active():
			var move_name = anim_name.trim_suffix("Active")
			if move_name in UniqueCharacter.MOVE_DATABASE:
				chain_memory.append(move_name)
		else:
			perfect_chain = false # change to false if neither startup nor active

	
	null_friction = false
	null_gravity = false
	velocity_limiter = {"x" : null, "up" : null, "down" : null, "x_slow" : null, "y_slow" : null}
	sprite.rotation = 0
	sfx_under.hide()
	sfx_over.hide()
	
	match anim_name:
		"Run":
			emit_signal("SFX","RunDust", "DustClouds", get_feet_pos(), {"facing":facing, "grounded":true})
		"JumpTransit2":
			if button_up in input_state.pressed and button_jump in input_state.pressed: # up and jump to hop
				velocity.y = -UniqueCharacter.JUMP_SPEED * HOP_JUMP_MOD
			else:
				velocity.y = -UniqueCharacter.JUMP_SPEED
				$VarJumpTimer.time = VarJumpTimer_WAIT_TIME
			if dir != 0:
				velocity.x += dir * UniqueCharacter.JUMP_HORIZONTAL_SPEED
			emit_signal("SFX","JumpDust", "DustClouds", get_feet_pos(), {"facing":facing, "grounded":true})
		"AirJumpTransit2":
			aerial_memory = []
			if !check_wall_jump():
				air_jump -= 1
				# air jump directional boost
				if dir != 0:
					if dir * velocity.x < 0: # air jump change direction (no change in velocity if same direction)
						velocity.x += dir * UniqueCharacter.SPEED * 0.7
					else:
						velocity.x = velocity.x * 0.9 # air jump is slower horizontally since no startup
				else: # neutral air jump
					velocity.x = velocity.x * 0.7		
				velocity.y = -UniqueCharacter.JUMP_SPEED * UniqueCharacter.AIR_JUMP_MOD
				$VarJumpTimer.time = VarJumpTimer_WAIT_TIME
				emit_signal("SFX","AirJumpDust", "DustClouds", get_feet_pos(), {"facing":facing})
			else: # if next to wall when starting an air jump, do wall jump instead
				if wall_jump_dir != 0:
					velocity.x = wall_jump_dir * UniqueCharacter.SPEED * 0.5
				else:
					velocity.x = 0
					wall_jump_dir = facing
				velocity.y = -UniqueCharacter.JUMP_SPEED
				$VarJumpTimer.time = VarJumpTimer_WAIT_TIME
				var wall_point = Detection.wall_finder(position - (wall_jump_dir * Vector2($PlayerCollisionBox.rect_size.x / 2, 0)), \
						-wall_jump_dir)
				if wall_point != null:
					emit_signal("SFX","GroundDashDust", "DustClouds", wall_point, {"facing":wall_jump_dir, "rot":PI/2})
				else:
					emit_signal("SFX","AirJumpDust", "DustClouds", get_feet_pos(), {"facing":facing})
				reset_jumps_except_walljumps()
		"WallJumpTransit2":
			aerial_memory = []
			if wall_jump_dir != 0:
				velocity.x = wall_jump_dir * UniqueCharacter.SPEED * 0.5
			else:
				velocity.x = 0
				wall_jump_dir = facing
			velocity.y = -UniqueCharacter.JUMP_SPEED
			$VarJumpTimer.time = VarJumpTimer_WAIT_TIME
			var wall_point = Detection.wall_finder(position - (wall_jump_dir * Vector2($PlayerCollisionBox.rect_size.x / 2, 0)), \
					-wall_jump_dir)
			if wall_point != null:
				emit_signal("SFX","GroundDashDust", "DustClouds", wall_point, {"facing":wall_jump_dir, "rot":PI/2})
			else:
				emit_signal("SFX","AirJumpDust", "DustClouds", get_feet_pos(), {"facing":facing})
			reset_jumps_except_walljumps()
		"HardLanding":
			emit_signal("SFX","LandDust", "DustClouds", get_feet_pos(), {"facing":facing, "grounded":true})
		"SoftLanding":
			emit_signal("SFX","LandDust", "DustClouds", get_feet_pos(), {"facing":facing, "grounded":true})
			
		"BlockStartup":
			block_rec_cancel = false
			perfect_block()
		"AirBlockStartup":
			block_rec_cancel = false
			perfect_block()
			$ModulatePlayer.play("EX_block_flash")
			change_guard_gauge(UniqueCharacter.AIR_BLOCK_GG_COST)
			play_audio("bling1", {"vol" : -12,})
			remove_status_effect(Globals.status_effect.POS_FLOW)
		"BlockRecovery", "AirBlockRecovery", "BlockCRecovery", "AirBlockCRecovery":
			$PBlockTimer.stop() # stop perfect blocking		
		"BurstCounterStartup", "BurstEscapeStartup":
			velocity_limiter.x_slow = 0.2
			velocity_limiter.y_slow = 0.2
			null_gravity = true
			if anim_name == "BurstCounterStartup":
				$ModulatePlayer.play("yellow_burst")
			else:
				$ModulatePlayer.play("blue_burst")
			play_audio("faller1", {"vol" : -12,})
		"BurstCounter", "BurstEscape", "BurstExtend":
#			chain_combo = 0
			velocity = Vector2.ZERO
			velocity_limiter.x = 0
			null_gravity = true
			var burst_facing = 1
			if rng_generate(2) == 0:
				burst_facing = -1
			if anim_name == "BurstCounter":
				emit_signal("projectile", player_ID, "Burst", LoadedSFX.burst_counter_move_data, position, {"facing" : burst_facing})
			elif anim_name == "BurstEscape":
				emit_signal("projectile", player_ID, "Burst", LoadedSFX.burst_escape_move_data, position, {"facing" : burst_facing})
			else:
				emit_signal("projectile", player_ID, "Burst", LoadedSFX.burst_extend_move_data, position, {"facing" : burst_facing})
				$ModulatePlayer.play("red_burst")
			play_audio("blast1", {"vol" : -18,})
			
	UniqueCharacter._on_SpritePlayer_anim_started(anim_name)
	
	
func _on_SpritePlayer_frame_update(): # emitted after every frame update, useful for staggering audio
	UniqueCharacter.stagger_audio()

# return modulate to normal after ModulatePlayer finishes playing
# may do follow-up modulate animation
func _on_ModulatePlayer_anim_finished(anim_name):
	if LoadedSFX.modulate_animations[anim_name].has("followup"):
		$ModulatePlayer.play(LoadedSFX.modulate_animations[anim_name]["followup"])
	else:
		reset_modulate()
	
func _on_FadePlayer_anim_finished(anim_name):
	if LoadedSFX.fade_animations[anim_name].has("followup"):
		$FadePlayer.play(LoadedSFX.fade_animations[anim_name]["followup"])
	else:
		reset_fade()
		
		
func reset_modulate():
	$ModulatePlayer.stop()
	$ModulatePlayer.current_animation = ""
	sprite.modulate.r = 1.0
	sprite.modulate.g = 1.0
	sprite.modulate.b = 1.0
	
func reset_fade():
	$FadePlayer.stop()
	$FadePlayer.current_animation = ""
	sprite.modulate.a = 1.0
	
	
# aux_data contain "vol", "bus" and "unique_path" (added by this function)
func play_audio(audio_ref: String, aux_data: Dictionary):
	var new_audio = Globals.loaded_audio_scene.instance()
	Globals.Game.get_node("AudioPlayers").add_child(new_audio)
	
	if audio_ref in LoadedSFX.loaded_audio: # common audio
		new_audio.init(audio_ref, aux_data)
	else: # custom audio, have the audioplayer search this node's unique_audio dictionary
		aux_data["unique_path"] = get_path() # add a new key to aux_data
		new_audio.init(audio_ref, aux_data)
		

# triggered by SpritePlayer at start of each animation
func _on_change_spritesheet(spritesheet_filename):
	sprite.texture = spritesheets[spritesheet_filename]
func _on_change_SfxOver_spritesheet(SfxOver_spritesheet_filename):
	sfx_over.texture = spritesheets[SfxOver_spritesheet_filename]
func _on_change_SfxUnder_spritesheet(SfxUnder_spritesheet_filename):
	sfx_under.texture = spritesheets[SfxUnder_spritesheet_filename]

# SAVE/LOAD STATE --------------------------------------------------------------------------------------------------

func save_state():
	var state_data = {
			
		"position" : position,
		"air_jump" : air_jump,
		"wall_jump" : wall_jump,
		"air_dash" : air_dash,
		"state" : state,
		"new_state": new_state,
		"velocity" : velocity,
		"facing" : facing,
		"velocity_previous_frame" : velocity_previous_frame,
		"null_gravity" : null_gravity,
		"null_friction" : null_friction,
		"velocity_limiter" : velocity_limiter,
		"input_buffer" : input_buffer,
		"shadow_timer" : shadow_timer,
		"launch_starting_rot" : launch_starting_rot,
		"orig_hitstun" : orig_hitstun,
		"chain_combo" : chain_combo,
		"chain_memory" : chain_memory,
		"dash_cancel" : dash_cancel,
		"jump_cancel" : jump_cancel,
		"perfect_chain" : perfect_chain,
		"block_rec_cancel" : block_rec_cancel,
		"targeted_opponent" : targeted_opponent,
		"has_burst": has_burst,
		"impulse_used" : impulse_used,
		
		"current_damage_value" : current_damage_value,
		"current_guard_gauge" : current_guard_gauge,
		"current_ex_gauge" : current_ex_gauge,
		"stock_points_left" : stock_points_left,
		
		"unique_data" : unique_data,
		"move_memory" : move_memory,
		"aerial_memory" : aerial_memory,
		"status_effects" : status_effects,
		"hitcount_record" : hitcount_record,
		"ignore_list" : ignore_list,
#		"tap_memory" : tap_memory,
		
		"sprite_scale" : sprite.scale,
		"sprite_rotation" : sprite.rotation,
		"sfx_over_visible" : sfx_over.visible,
		"sfx_under_visible" : sfx_under.visible,
		"Sprites_visible" : $Sprites.visible,

		"SpritePlayer_data" : $SpritePlayer.save_state(),
		"ModulatePlayer_data" : $ModulatePlayer.save_state(),
		"FadePlayer_data" : $FadePlayer.save_state(),
		
		"VarJumpTimer_time" : $VarJumpTimer.time,
		"HitStunTimer_time" : $HitStunTimer.time,
		"BlockStunTimer_time" : $BlockStunTimer.time,
		"HitStopTimer_time" : $HitStopTimer.time,
		"SpecialTimer_time" : $SpecialTimer.time,
		"EXTimer_time" : $EXTimer.time,
		"SuperTimer_time" : $SuperTimer.time,
		"PBlockTimer_time" : $PBlockTimer.time,
		"PBlockCDTimer_time" : $PBlockCDTimer.time,
		"RespawnTimer_time" : $RespawnTimer.time,
		"HitStunGraceTimer_time" : $HitStunGraceTimer.time
	}

	return state_data
	
func load_state(state_data):
	
	position = state_data.position
	air_jump = state_data.air_jump
	wall_jump = state_data.wall_jump
	air_dash = state_data.air_dash
	state = state_data.state
	new_state = state_data.new_state
	velocity = state_data.velocity
	facing = state_data.facing
	velocity_previous_frame = state_data.velocity_previous_frame
	null_gravity = state_data.null_gravity
	null_friction = state_data.null_friction
	velocity_limiter = state_data.velocity_limiter
	input_buffer = state_data.input_buffer
	shadow_timer = state_data.shadow_timer
	launch_starting_rot = state_data.launch_starting_rot
	orig_hitstun = state_data.orig_hitstun
	chain_combo = state_data.chain_combo
	chain_memory = state_data.chain_memory
	dash_cancel = state_data.dash_cancel
	jump_cancel = state_data.jump_cancel
	perfect_chain = state_data.perfect_chain
	block_rec_cancel = state_data.block_rec_cancel
	targeted_opponent = state_data.targeted_opponent
	has_burst = state_data.has_burst
	impulse_used = state_data.impulse_used
	
	current_damage_value = state_data.current_damage_value
	current_guard_gauge = state_data.current_guard_gauge
	current_ex_gauge = state_data.current_ex_gauge
	stock_points_left = state_data.stock_points_left
	Globals.Game.damage_update(self)
	Globals.Game.guard_gauge_update(self)
	Globals.Game.ex_gauge_update(self)
	Globals.Game.stock_points_update(self)
	Globals.Game.burst_update(self)
	
	unique_data = state_data.unique_data
	move_memory = state_data.move_memory
	aerial_memory = state_data.aerial_memory
	status_effects = state_data.status_effects
	hitcount_record = state_data.hitcount_record
	ignore_list = state_data.ignore_list
#	tap_memory = state_data.tap_memory
		
	sprite.scale = state_data.sprite_scale
	sprite.rotation = state_data.sprite_rotation
	sfx_over.visible = state_data.sfx_over_visible
	sfx_under.visible = state_data.sfx_under_visible
	$Sprites.visible = state_data.Sprites_visible
	
	$SpritePlayer.load_state(state_data.SpritePlayer_data)
	reset_modulate()
	$ModulatePlayer.load_state(state_data.ModulatePlayer_data)
	reset_fade()
	$FadePlayer.load_state(state_data.FadePlayer_data)
	palette()
	
	$VarJumpTimer.time = state_data.VarJumpTimer_time
	$HitStunTimer.time = state_data.HitStunTimer_time
	$BlockStunTimer.time = state_data.BlockStunTimer_time
	$HitStopTimer.time = state_data.HitStopTimer_time
	$SpecialTimer.time = state_data.SpecialTimer_time
	$EXTimer.time = state_data.EXTimer_time
	$SuperTimer.time = state_data.SuperTimer_time
	$PBlockTimer.time = state_data.PBlockTimer_time
	$PBlockCDTimer.time = state_data.PBlockCDTimer_time
	$RespawnTimer.time = state_data.RespawnTimer_time
	$HitStunGraceTimer.time = state_data.HitStunGraceTimer_time


	
#--------------------------------------------------------------------------------------------------

