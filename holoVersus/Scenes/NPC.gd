extends "res://Scenes/Physics/Physics.gd"

# TO BE USED ONLY FOR AMELIA, SHION AND FUWAMOCO

# constants
const GRAVITY = 70 * FMath.S # per frame
const PEAK_DAMPER_MOD = 60 # used to reduce gravity at jump peak
const PEAK_DAMPER_LIMIT = 400 * FMath.S # min velocity.y where jump peak gravity reduction kicks in
const TERMINAL_THRESHOLD = 150 # if velocity.y is over this during hitstun, no terminal velocity slowdown
const VAR_JUMP_GRAV_MOD = 20 # gravity multiplier during Variable Jump time
const DashLandDBox_HEIGHT = 15 # allow snapping up to dash land easier on soft platforms
const WallJumpDBox_WIDTH = 10 # for detecting walls for walljumping
const TAP_MEMORY_DURATION = 20

const AIRBLOCK_GRAV_MOD = 50 # multiply to GRAVITY to get gravity during air blocking
const AIRBLOCK_TERMINAL_MOD = 70 # multiply to get terminal velocity during air blocking
const MAX_WALL_JUMP = 2
const HITSTUN_TERMINAL_VELOCITY_MOD = 650 # multiply to GRAVITY to get terminal velocity during hitstun
#const PERFECT_IMPULSE_MOD = 140 # multiply by get_stat("SPEED") and get_stat("IMPULSE MOD") to get perfect impulse velocity
const AERIAL_STRAFE_MOD = 50 # reduction of air strafe speed and limit during aerials (non-active frames) and air cancellable recovery
const AERIAL_STARTUP_LAND_CANCEL_TIME = 3 # number of frames when aerials can land cancel their startup and auto-buffer pressed attacks

const HITSTUN_GRAV_MOD = 65  # gravity multiplier during hitstun
const HITSTUN_FRICTION = 15  # friction during hitstun
const HITSTUN_AIR_RES = 3 # air resistance during hitstun

const CORNER_PUSHBACK = 200 * FMath.S # attacker is pushed back when attacking at the corner towards the corner
const CROSS_UP_MIN_DIST = 10 # characters must be at least a certain number of pixels away horizontally to count as a cross-up

const STUN_HITSTOP_ATTACKER = 15 # hitstop for attacker when causing Stun

const NPC_KB_STR = 1000 * FMath.S # knockback strength is fixed
const NPC_BLOCK_KB_STR = 300 * FMath.S # knockback strength is fixed
const NPC_HITSTOP = 10 # fixed hitstop, for NPC defender only, attacker take no hitstop
const NPC_BLOCK_HITSTOP = 5

const BLOCK_ATKER_PUSHBACK = 450 * FMath.S # how much the attacker is pushed away when blocked, fixed
const BLOCK_KNOCKBACK_MOD = 200 # % of knockback defender experience when blocked
const PARRY_ATKER_PUSHBACK = 600 * FMath.S # how much the attacker is pushed away when parried, fixed
const RESIST_ATKER_PUSHBACK = 300 * FMath.S # how much the attacker is pushed away when resisted by mobs, fixed

const LAUNCH_ROT_SPEED = 5*PI # speed of sprite rotation when launched, don't need fixed-point as sprite rotation is only visuals
const TECHLAND_THRESHOLD = 300 * FMath.S # max velocity when hitting the ground to tech land

const WALL_SLAM_THRESHOLD = 100 * FMath.S # min velocity towards surface needed to do release BounceDust when bouncing

# variables used, don't touch these
#var loaded_palette = null
onready var Animator = $SpritePlayer # clean code
onready var sprite = $Sprites/Sprite # clean code
onready var sfx_under = $Sprites/SfxUnder # clean code
onready var sfx_over = $Sprites/SfxOver # clean code
var UniqNPC # unique character node

var master_node

var floor_level

var input_state = {
	"pressed" : [],
	"just_pressed" : [],
	"just_released" : [],
}

var dir := 0
var instant_dir := 0
var v_dir := 0
var wall_jump_dir := 0
var grounded := true
var soft_grounded := false
var hitstop = null # holder to inflict hitstop at end of frame
var startup_cancel_flag := false # allow cancelling of startup frames without rebuffering


# character state, save these when saving and loading along with position, sprite frame and animation progress

var free := false
var NPC_ID: int # based on Globals.Game.entity_ID_ref
var master_ID : int # player_ID of owner

var palette_ref
var NPC_ref : String

var air_jump := 0
var wall_jump := 0
var air_dash := 0
var super_dash := 0
var state = Em.char_state.GRD_STANDBY
var new_state = Em.char_state.GRD_STANDBY
var true_position := FVector.new() # scaled int vector, needed for slow and precise movement
var velocity := FVector.new()
var facing := 1 # 1 for facing right, -1 for facing left
var velocity_previous_frame := FVector.new() # needed to check for landings
var anim_gravity_mod := 100 # set to percent during certain special states, like air dashing
var anim_friction_mod := 100 # set to percent during certain special states, like ground dashing
var velocity_limiter = { # as % of speed, some animations limit max velocity in a certain direction, if null means no limit
	"x" : null, "up" : null, "down" : null, "x_slow" : null, "y_slow" : null
	}
var input_buffer = []
var afterimage_timer := 0 # for use by unique character node
var monochrome := false

var sprite_texture_ref = { # used for afterimages, each contain spritesheet_filename, a string ref to the spritesheet in loaded data
	"sprite" : null,
	"sfx_over" : null,
	"sfx_under" : null
}


var hitcount_record = [] # record number of hits for current attack for each player, cannot do anymore hits if maxed out
var ignore_list = [] # some moves has ignore_time, after hitting will ignore that player for a number of frames, used for multi-hit specials

var launch_starting_rot := 0.0 # starting rotation when being launched, current rotation calculated using hitstun timer and this, can leave as float
var launchstun_rotate := 0 # used to set rotation when being launched, use to count up during hitstun
var unique_data = {} # data unique for the character, stored as a dictionary
var chain_combo: int = Em.chain_combo.RESET # set to Em.chain_combo
var chain_memory = [] # appended whenever you attack, reset when not attacking or in air/ground startup
var active_cancel := false # set to true when landing a Sweetspotted Normal or certain Launchers, set to false when starting any attack
var aerial_memory = [] # appended whenever an air normal attack is made, cannot do the same air normal twice in a jump
					   # reset on landing or air jump
var aerial_sp_memory = [] # appended whenever an air normal attack is made, cannot do the same air normal twice before landing
						  # reset on landing
var seq_partner_ID = null # not always target_ID during Survival Mode
var tap_memory = []
var release_memory = []
var impulse_used := false
var quick_turn_used := false # can only quick turn once per attack
var strafe_lock_dir := 0 # when pressing left/right when doing an aerial, lock the air strafe direction during startup
var last_dir := 0 # dir last frame

var from_move_rec := false # to prevent QCing into NOT_FROM_MOVE_REC moves
var slowed := 0
var gravity_frame_mod := 100 # modify gravity this frame
var js_cancel_target = Em.js_cancel_target.ALL # set to certain enums when jump cancelling, decide which moves can be quick canceled from jumpsquat
var sdash_points := 0 # set to duration of sdash when you begin a sdash, reduce per frame base on angle, stop sdash when hit 0

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
var button_rs_up
var button_rs_down
var button_rs_left
var button_rs_right


# SETUP CHARACTER --------------------------------------------------------------------------------------------------

func load_NPC(): # ran when loading state
	
	set_master_id(master_ID)
	
	add_to_group("NPCNodes")
	
	if NPC_ref in Loader.NPC_data:
		UniqNPC = Loader.NPC_data[NPC_ref].scene.instance()
		# load frame data
		Animator.init_with_loaded_frame_data_array(sprite, sfx_over, sfx_under, Loader.NPC_data[NPC_ref].frame_data_array)
	else:
		print("Error: " + NPC_ref + " NPC not found in Loader.NPC_data")
		
	add_child(UniqNPC)
	move_child(UniqNPC, 0)
	
	UniqNPC.sprite = sprite
	UniqNPC.Animator = $SpritePlayer
	$ModulatePlayer.sprite = sprite
	$FadePlayer.sprite = sprite
	
	setup_boxes(UniqNPC.get_node("DefaultCollisionBox"))

	palette() # set up palette to copy master's
	sfx_under.hide()
	sfx_over.hide()
	
	floor_level = Globals.Game.middle_point.y # get floor level of stage
	
	
# this is run after adding this node to the tree and not when loading state
func init(in_master_ID, in_NPC_ref, start_position, start_facing, in_palette_ref):
	
	NPC_ID = Globals.Game.entity_ID_ref
	Globals.Game.entity_ID_ref += 1
	
	master_ID = in_master_ID
	palette_ref = in_palette_ref
	NPC_ref = in_NPC_ref
	
	load_NPC()

	animate("Idle")

	reset_jumps()
	
	# incoming start position points at the floor
	start_position.y -= $PlayerCollisionBox.rect_position.y + $PlayerCollisionBox.rect_size.y
	
	position = start_position
	set_true_position()

	if facing != start_facing:
		face(start_facing)

	unique_data = UniqNPC.UNIQUE_DATA_REF.duplicate(true)
	
	
func set_master_id(in_master_ID):
	
	master_ID = in_master_ID
	master_node = Globals.Game.get_player_node(master_ID)
	
	button_up = Globals.INPUTS[master_ID].up[1] # each button is an int variable enum
	button_down = Globals.INPUTS[master_ID].down[1]
	button_left = Globals.INPUTS[master_ID].left[1]
	button_right = Globals.INPUTS[master_ID].right[1]
	button_jump = Globals.INPUTS[master_ID].jump[1]
	button_light = Globals.INPUTS[master_ID].light[1]
	button_fierce = Globals.INPUTS[master_ID].fierce[1]
	button_dash = Globals.INPUTS[master_ID].dash[1]
	button_block = Globals.INPUTS[master_ID].block[1]
	button_aux = Globals.INPUTS[master_ID].aux[1]
	button_special = Globals.INPUTS[master_ID].special[1]
	button_unique = Globals.INPUTS[master_ID].unique[1]
	button_pause = Globals.INPUTS[master_ID].pause[1]
	button_rs_up = Globals.INPUTS[master_ID].rs_up[1]
	button_rs_down = Globals.INPUTS[master_ID].rs_down[1]
	button_rs_left = Globals.INPUTS[master_ID].rs_left[1]
	button_rs_right = Globals.INPUTS[master_ID].rs_right[1]

func setup_boxes(ref_rect): # set up detection boxes
	
	$PlayerCollisionBox.rect_position = ref_rect.rect_position
	$PlayerCollisionBox.rect_size = ref_rect.rect_size
	$PlayerCollisionBox.add_to_group("NPCBoxes")
	$PlayerCollisionBox.add_to_group("Grounded")

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
	
	if palette_ref in Loader.NPC_data[NPC_ref].palettes:
		sprite.material = ShaderMaterial.new()
		sprite.material.shader = Loader.loaded_palette_shader
		sprite.material.set_shader_param("swap", Loader.NPC_data[NPC_ref].palettes[palette_ref])
		sfx_over.material = ShaderMaterial.new()
		sfx_over.material.shader = Loader.loaded_palette_shader
		sfx_over.material.set_shader_param("swap", Loader.NPC_data[NPC_ref].palettes[palette_ref])
		sfx_under.material = ShaderMaterial.new()
		sfx_under.material.shader = Loader.loaded_palette_shader
		sfx_under.material.set_shader_param("swap", Loader.NPC_data[NPC_ref].palettes[palette_ref])
		
		
	
	
# TESTING --------------------------------------------------------------------------------------------------

# for testing only
func test1():
	if Globals.debug_mode2:
		if $HitStopTimer.is_running():
			test0()
		$TestNode2D/TestLabel.text = $TestNode2D/TestLabel.text + "old state: " + Globals.char_state_to_string(state) + \
			"\n" + Animator.current_anim + " > " + Animator.to_play_anim + "  time: " + str(Animator.time) + "\n"
	else:
		$TestNode2D/TestLabel.text = ""
			
func test0():
	if Globals.debug_mode2:
		var string_input_buffer = []
		for buffered_input in input_buffer:
			var string_buffered_input = [Globals.input_to_string(buffered_input[0], master_ID), buffered_input[1]]
			string_input_buffer.append(string_buffered_input)
		$TestNode2D/TestLabel.text = "buffer: " + str(string_input_buffer) + "\n"
	else:
		$TestNode2D/TestLabel.text = ""
			
func test2():
	if Globals.debug_mode2:
		$TestNode2D/TestLabel.text = $TestNode2D/TestLabel.text + "new state: " + Globals.char_state_to_string(state) + \
			"\n" + Animator.current_anim + " > " + Animator.to_play_anim + "  time: " + str(Animator.time) + \
			"\n" + str(velocity.y) + "  grounded: " + str(grounded) + \
			"\ntap_memory: " + str(tap_memory) + " " + str(chain_combo) + "\n" + \
			str(input_buffer)
	else:
		$TestNode2D/TestLabel.text = ""
			
func _process(_delta):

	if master_node.test:
		if Globals.debug_mode2:
			$TestNode2D.show()
		else:
			$TestNode2D.hide()
			
			
func simulate():

	UniqNPC.get_input_state() # change input_state from UniqNPC

# SET NON-SAVEABLE DATA --------------------------------------------------------------------------------------------------
# reset even on hitstop and respawning
# variables that are reseted right before being used don't need to be reset here

	dir = 0
	instant_dir = 0
	v_dir = 0
	
	hitstop = null
	startup_cancel_flag = false # to cancel startup without incurring auto-buffer

	var soft_dbox = get_soft_dbox(get_collision_box())
	if is_on_ground(soft_dbox):
		grounded = true
	else:
		grounded = false
		
	if is_on_soft_ground(soft_dbox):
		soft_grounded = true
	else:
		soft_grounded = false


# FRAMESKIP DURING HITSTOP --------------------------------------------------------------------------------------------------
	# while buffering all inputs
	
	
	if Globals.Game.is_stage_paused(): # screenfrozen
		return
		
	if slowed < 0:
		buffer_actions()
		return
	
	$HitStopTimer.simulate() # advancing the hitstop timer at start of frame allow for one frame of knockback before hitstop
	# will be needed for multi-hit moves
	
	if !$HitStopTimer.is_running():
		simulate2()
	else:
		buffer_actions() # can still buffer buttons during hitstop
		


func simulate2(): # only ran if not in hitstop
	
# START OF FRAME --------------------------------------------------------------------------------------------------

	if grounded:
		reset_jumps()
		
	if js_cancel_target != Em.js_cancel_target.ALL:
		match state: # do not use new_state!
			Em.char_state.GRD_STARTUP:
				if !Animator.query_current(["JumpTransit"]):
					js_cancel_target = Em.js_cancel_target.ALL
			Em.char_state.AIR_STARTUP:
				if !Animator.query_current(["aJumpTransit"]):
					js_cancel_target = Em.js_cancel_target.ALL
			_:
				js_cancel_target = Em.js_cancel_target.ALL
		
	ignore_list_progress_timer()
		
	if !new_state in [Em.char_state.SEQ_TARGET, Em.char_state.SEQ_USER]:
		seq_partner_ID = null
		

	if !is_attacking():
		chain_combo = Em.chain_combo.RESET
		active_cancel = false
		if !new_state in [Em.char_state.AIR_STARTUP, Em.char_state.GRD_STARTUP, Em.char_state.AIR_D_REC, Em.char_state.GRD_D_REC]:
			chain_memory = []
		hitcount_record = []
		ignore_list = []
		
	elif is_atk_active():
		var refined_move = UniqNPC.refine_move_name(get_move_name())
		if Em.move.MULTI_HIT_REFRESH in UniqNPC.MOVE_DATABASE[refined_move]:
			if Animator.time in UniqNPC.MOVE_DATABASE[refined_move][Em.move.MULTI_HIT_REFRESH]:
				ignore_list = []


# CAPTURE DIRECTIONAL INPUTS --------------------------------------------------------------------------------------------------
	
	if button_right in input_state.pressed:
		dir += 1
	if button_left in input_state.pressed:
		dir -= 1
	if button_up in input_state.pressed:
		v_dir -= 1
	if button_down in input_state.pressed:
		v_dir += 1
		
	if button_right in input_state.just_pressed:
		instant_dir += 1
	if button_left in input_state.just_pressed:
		instant_dir -= 1
		
	if instant_dir != 0 and dir == 0:
		dir = instant_dir
		
	if dir == 0 and button_right in input_state.pressed and button_left in input_state.pressed:
		dir = last_dir
		
	last_dir = dir
		
	if new_state in [Em.char_state.SEQ_USER, Em.char_state.SEQ_TARGET]:
		simulate_sequence()
		return
		
# LEFT/RIGHT BUTTON --------------------------------------------------------------------------------------------------

	if dir != 0:
		match state:
			
	# GROUND MOVEMENT --------------------------------------------------------------------------------------------------
	
			Em.char_state.GRD_STANDBY:
				if dir != facing: # flipping over
					face(dir)
					animate("RunTransit") # restart run animation
				 # if not in run animation, do run animation
				if !Animator.query(["Run", "RunTransit"]):
					animate("RunTransit")
						
				var speed_target = dir * get_stat("SPEED")
				if "AWAY_SPEED_MOD" in UniqNPC:
					if dir != get_opponent_dir():
						speed_target = FMath.percent(speed_target, get_stat("AWAY_SPEED_MOD"))
				velocity.x = FMath.f_lerp(velocity.x, speed_target, get_stat("ACCELERATION"))
	
	# AIR STRAFE --------------------------------------------------------------------------------------------------
		# can air strafe during aerials at reduced speed
	
			Em.char_state.AIR_STANDBY, Em.char_state.AIR_ATK_STARTUP, Em.char_state.AIR_ATK_ACTIVE, \
				Em.char_state.AIR_ATK_REC, Em.char_state.AIR_C_REC, \
				Em.char_state.AIR_BLOCK:
					
				if !grounded:
					var strafe_dir = dir
					var can_strafe := true
					match new_state:
						Em.char_state.AIR_ATK_STARTUP: # locked strafe during startup
							strafe_dir = strafe_lock_dir
							
						Em.char_state.AIR_ATK_ACTIVE:
							var move_data = query_move_data()
							if !can_air_strafe(move_data):
								can_strafe = false # some attacks cannot be air strafed
						Em.char_state.AIR_STANDBY:
							face(strafe_dir) # turning in air

					if can_strafe:
						var air_strafe_speed_temp: int = FMath.percent(get_stat("SPEED"), get_stat("AIR_STRAFE_SPEED_MOD"))
						var air_strafe_limit_temp: int = FMath.percent(air_strafe_speed_temp, get_stat("AIR_STRAFE_LIMIT_MOD"))
						
						# reduce air_strafe_speed and air_strafe_limit during AIR_ATK_STARTUP
						if state != Em.char_state.AIR_STANDBY:
							air_strafe_speed_temp = FMath.percent(air_strafe_speed_temp, AERIAL_STRAFE_MOD)
							air_strafe_limit_temp = FMath.percent(air_strafe_limit_temp, AERIAL_STRAFE_MOD)
						
						if abs(velocity.x + (strafe_dir * air_strafe_speed_temp)) > abs(velocity.x): # if speeding up
							if abs(velocity.x) < air_strafe_limit_temp: # only allow strafing if below speed limit
								velocity.x = int(clamp(velocity.x + strafe_dir * air_strafe_speed_temp, -air_strafe_limit_temp, air_strafe_limit_temp))
						else: # slowing down
							velocity.x += strafe_dir * air_strafe_speed_temp
					
			
			
	# TURN AT START OF CERTAIN MOVES --------------------------------------------------------------------------------------------------
						
		if facing != dir:
				
			if check_quick_turn():
				if !grounded:
					quick_turn_used = true
				face(dir)
				
		if Settings.input_assist[master_ID]:
			# quick impulse
			match state:
				Em.char_state.GRD_ATK_STARTUP, Em.char_state.AIR_ATK_STARTUP:
					if state == Em.char_state.AIR_ATK_STARTUP and (!grounded or check_fallthrough()): continue
					
					if !impulse_used and Animator.time <= 1:
						var move_name = Animator.to_play_anim.trim_suffix("Startup")
						if move_name in UniqNPC.STARTERS:
							if !Em.atk_attr.NO_IMPULSE in query_atk_attr(move_name): # ground impulse
								impulse_used = true
								var impulse: int = dir * FMath.percent(get_stat("SPEED"), get_stat("IMPULSE_MOD"))
								# some moves have their own impulse mod
			#					if move_name in UniqNPC.MOVE_DATABASE and "impulse_mod" in UniqNPC.MOVE_DATABASE[move_name]:
			#						var impulse_mod: int = UniqNPC.query_move_data(move_name).impulse_mod
			#						impulse = FMath.percent(impulse, impulse_mod)
								velocity.x = int(clamp(velocity.x + impulse, -abs(impulse), abs(impulse)))
								Globals.Game.spawn_SFX("GroundDashDust", "DustClouds", get_feet_pos(), {"facing":dir, "grounded":true})
				
				Em.char_state.GRD_BLOCK:
					if !impulse_used and Animator.time <= 1 and Animator.to_play_anim == "BlockStartup":
						impulse_used = true
						var impulse: int = dir * FMath.percent(get_stat("SPEED"), get_stat("IMPULSE_MOD"))
						impulse = FMath.percent(impulse, 70)
						velocity.x = int(clamp(velocity.x + impulse, -abs(impulse), abs(impulse)))
						Globals.Game.spawn_SFX("GroundDashDust", "DustClouds", get_feet_pos(), {"facing":dir, "grounded":true})
				
			# quick strafe-lock
				Em.char_state.AIR_ATK_STARTUP:
					if strafe_lock_dir == 0 and Animator.time <= 1:
						var move_name = Animator.to_play_anim.trim_suffix("Startup")
						if move_name in UniqNPC.STARTERS:
							strafe_lock_dir = dir

# DOWN BUTTON --------------------------------------------------------------------------------------------------
	
	if button_down in input_state.pressed and !button_unique in input_state.pressed and !button_aux in input_state.pressed:
		if Globals.survival_level != null and Inventory.shop_open:
			pass
		else:
		
			match state:
				
				Em.char_state.AIR_STANDBY:
					if !Animator.query_to_play(["JumpTransit2", "JumpTransit3", "FastFallTransit", "FastFall"]):


						if Settings.dj_fastfall[master_ID] == 0 or \
							(Settings.dj_fastfall[master_ID] == 1 and button_jump in input_state.pressed):
								
							animate("FastFallTransit")
							
					
					elif Animator.query_to_play(["FastFall"]): # hold down while in fastfall animation to fast fall

						velocity.y = FMath.percent(FMath.percent(GRAVITY, get_stat("TERMINAL_VELOCITY_MOD")), get_stat("FASTFALL_MOD"))
						# fastfall reduce horizontal speed limit
						var ff_speed_limit: int = FMath.percent(get_stat("SPEED"), 70)
						if velocity.x < -ff_speed_limit:
							velocity.x = FMath.f_lerp(velocity.x, -ff_speed_limit, 50)
						elif velocity.x > ff_speed_limit:
							velocity.x = FMath.f_lerp(velocity.x, ff_speed_limit, 50)
								
				Em.char_state.AIR_STARTUP: # can cancel air jump startup to fastfall if dj_fastfall is on
#					if Settings.dj_fastfall[master_ID] == 1 and button_jump in input_state.pressed:
					if button_jump in input_state.pressed:
							
						if Animator.query_to_play(["aJumpTransit"]):
							animate("FastFallTransit")
						
							
				Em.char_state.GRD_ATK_REC, Em.char_state.AIR_ATK_REC: # fastfall cancel from aerial hits
					if Settings.dj_fastfall[master_ID] == 0 or \
						(Settings.dj_fastfall[master_ID] == 1 and button_jump in input_state.pressed):
							
						if test_fastfall_cancel():
							animate("FastFallTransit")

# BLOCK BUTTON --------------------------------------------------------------------------------------------------	
	
			
	if button_block in input_state.pressed and !button_aux in input_state.pressed and !button_jump in input_state.pressed and \
			!button_special in input_state.pressed and !button_unique in input_state.pressed:
		if Globals.survival_level != null and Inventory.shop_open:
			pass

		else:
			match state: # don't use new_state or will be able to block Supers after screenfreeze
				
				Em.char_state.GRD_STANDBY:
					animate("BlockStartup")
				Em.char_state.GRD_C_REC:
					if has_trait(Em.trait.D_REC_BLOCK):
						animate("BlockStartup")
					elif !Animator.query_to_play(["DashBrake", "WaveDashBrake"]): # cannot block out of ground dash unless you have the D_REC_BLOCK trait
						animate("BlockStartup")
						
				Em.char_state.GRD_ATK_REC: # block cancelling
					if chain_combo in [Em.chain_combo.NORMAL, Em.chain_combo.HEAVY]:
						afterimage_cancel()
						animate("BlockStartup")
					elif Globals.survival_level != null and Inventory.has_quirk(master_ID, Cards.effect_ref.BLOCK_CANCEL):
						afterimage_cancel()
						animate("BlockStartup")
						
				Em.char_state.GRD_REC: # quick turn block
					if dir == -facing and Animator.query_current(["BlockRec"]):
						face(dir)
						animate("TBlockStartup")
						

				Em.char_state.AIR_STANDBY:
					animate("aBlockStartup")
					$VarJumpTimer.stop()
					
				Em.char_state.AIR_C_REC:
					if has_trait(Em.trait.D_REC_BLOCK):
						animate("aBlockStartup")
						$VarJumpTimer.stop()
					elif !Animator.query_to_play(["aDashBrake"]):
						animate("aBlockStartup")
						$VarJumpTimer.stop()
			
				Em.char_state.AIR_ATK_REC: # block cancelling
					if chain_combo in [Em.chain_combo.NORMAL, Em.chain_combo.HEAVY]:
						afterimage_cancel()
						animate("aBlockStartup")
					elif Globals.survival_level != null and Inventory.has_quirk(master_ID, Cards.effect_ref.BLOCK_CANCEL):
						afterimage_cancel()
						animate("aBlockStartup")
						
				Em.char_state.AIR_REC: # quick turn block
					if dir == -facing and Animator.query_current(["aBlockRec"]):
						face(dir)
						animate("aTBlockStartup")

# CHECK DROPS AND LANDING ---------------------------------------------------------------------------------------------------
	
	if !grounded:
		match new_state:
			Em.char_state.GRD_STANDBY, Em.char_state.GRD_C_REC, \
				Em.char_state.GRD_STARTUP, Em.char_state.GRD_ACTIVE, Em.char_state.GRD_REC, \
				Em.char_state.GRD_ATK_STARTUP, Em.char_state.GRD_ATK_ACTIVE, Em.char_state.GRD_ATK_REC, \
				Em.char_state.GRD_FLINCH_HITSTUN, Em.char_state.GRD_BLOCK:
				check_drop()
				
	elif velocity.y >= 0: # just in case, normally called when physics.gd runs into a floor
		match new_state:
			Em.char_state.AIR_STANDBY, Em.char_state.AIR_C_REC, Em.char_state.AIR_STARTUP, \
				Em.char_state.AIR_ACTIVE, Em.char_state.AIR_REC, Em.char_state.AIR_ATK_STARTUP, \
				Em.char_state.AIR_ATK_ACTIVE, Em.char_state.AIR_ATK_REC, Em.char_state.AIR_FLINCH_HITSTUN, \
				Em.char_state.LAUNCHED_HITSTUN, Em.char_state.AIR_BLOCK:
				check_landing()

# GRAVITY --------------------------------------------------------------------------------------------------

	var gravity_temp: int
	
	if is_hitstunned(): # fix and lower gravity during hitstun
		gravity_temp = FMath.percent(GRAVITY, HITSTUN_GRAV_MOD)
	else:
		gravity_temp = FMath.percent(GRAVITY, get_stat("GRAVITY_MOD")) # each character are affected by gravity differently out of hitstun
	
	if $VarJumpTimer.is_running() and !grounded and \
			(button_jump in input_state.pressed or button_up in input_state.pressed):
		# variable jump system reduces gravity if you hold down the jump button
		gravity_temp = FMath.percent(GRAVITY, VAR_JUMP_GRAV_MOD)
		
	if anim_gravity_mod != 100:
		gravity_temp = FMath.percent(GRAVITY, anim_gravity_mod) # anim_gravity_mod is based off current animation
		
	if gravity_frame_mod != 100: # for temp gravity changes
		gravity_temp = FMath.percent(GRAVITY, gravity_frame_mod)
		gravity_frame_mod = 100

	if !grounded and (abs(velocity.y) < PEAK_DAMPER_LIMIT): # reduce gravity at peak of jump
# warning-ignore:narrowing_conversion
		var weight: int = FMath.get_fraction_percent(PEAK_DAMPER_LIMIT - abs(velocity.y), PEAK_DAMPER_LIMIT)
		gravity_temp = FMath.f_lerp(gravity_temp, FMath.percent(gravity_temp, PEAK_DAMPER_MOD), weight)
		# transit from jump to fall animation
		if new_state == Em.char_state.AIR_STANDBY and Animator.query_to_play(["Jump"]): # don't use query() for this one
			animate("FallTransit")

	if !grounded: # gravity only pulls you if you are in the air
		
		if is_hitstunned():
			pass
		else:
			if velocity.y > 0: # some characters may fall at different speed compared to going up
				gravity_temp = FMath.percent(gravity_temp, get_stat("FALL_GRAV_MOD"))
				if state == Em.char_state.AIR_BLOCK: # air blocking reduce gravity
					gravity_temp = FMath.percent(gravity_temp, AIRBLOCK_GRAV_MOD)

		velocity.y += gravity_temp
		
	# terminal velocity downwards
	var terminal: int
	
	var has_terminal := true
	
	
	if is_atk_active():
		if Em.atk_attr.NO_TERMINAL_VEL_ACTIVE in query_atk_attr():
			 has_terminal = false

	if has_terminal:
		if is_hitstunned(): # during hitstun, only slowdown within a certain range
			terminal = FMath.percent(GRAVITY, HITSTUN_TERMINAL_VELOCITY_MOD)
			
			if velocity.y < FMath.percent(terminal, TERMINAL_THRESHOLD) and velocity.y > terminal:
				velocity.y = FMath.f_lerp(velocity.y, terminal, 75)
				
		else:
			terminal = FMath.percent(GRAVITY, get_stat("TERMINAL_VELOCITY_MOD"))
		
			if state == Em.char_state.AIR_STANDBY and button_down in input_state.pressed:
				if Settings.dj_fastfall[master_ID] == 0 or (Settings.dj_fastfall[master_ID] == 1 and button_jump in input_state.pressed):
					terminal = FMath.percent(terminal, get_stat("FASTFALL_MOD")) # increase terminal velocity when fastfalling
			if state == Em.char_state.AIR_BLOCK: # air blocking reduce terminal velocity
				terminal = FMath.percent(terminal, AIRBLOCK_TERMINAL_MOD)

			if velocity.y > terminal:
				velocity.y = FMath.f_lerp(velocity.y, terminal, 75)
				
	if velocity.y < 0 and $VarJumpTimer.is_running() and !grounded and abs(velocity.y) > PEAK_DAMPER_LIMIT:
		if (button_jump in input_state.pressed or button_up in input_state.pressed):
			if $VarJumpTimer.time <= get_stat("VAR_JUMP_SLOW_POINT"):
				velocity.y = FMath.f_lerp(velocity.y, PEAK_DAMPER_LIMIT, get_stat("HIGH_JUMP_SLOW"))
				 # during variable jump time, slow down velocity.y to PEAK_DAMPER_LIMIT when jumping with up/jump held
		else:
			velocity.y = FMath.f_lerp(velocity.y, PEAK_DAMPER_LIMIT, get_stat("SHORT_JUMP_SLOW"))
			 # during variable jump time, slow down velocity.y to PEAK_DAMPER_LIMIT when jumping with up/jump held
		

# FRICTION/AIR RESISTANCE AND TRIGGERED ANIMATION CHANGES ----------------------------------------------------------
	# place this at end of frame later
	# for triggered animation changes, use query_to_play() instead
	# query() check animation at either start/end of frame, query_to_play() only check final animation
	
	var friction_this_frame: int # 15
	var air_res_this_frame: int
		
	if is_hitstunned() or is_blocking() or Animator.query_to_play(["BlockRec", "aBlockRec"]):
		friction_this_frame = HITSTUN_FRICTION # 15
		air_res_this_frame = HITSTUN_AIR_RES # 3
	else:
		friction_this_frame = get_stat("FRICTION")
		air_res_this_frame = get_stat("AIR_RESISTANCE")
	
	match state:
		Em.char_state.GRD_STANDBY:
			if dir == 0: # if not moving
				# if in run animation, do brake animation
				if Animator.query_to_play(["Run", "RunTransit"]):
					animate("Brake")
			else: # no friction when moving
				friction_this_frame = 0
			
#		Em.char_state.CROUCHING:
#			if !button_down in input_state.pressed and Animator.query_to_play(["Crouch"]):
#				animate("CrouchReturn") # stand up
	
		Em.char_state.GRD_STARTUP:
			friction_this_frame = 0 # no friction when starting a ground jump/dash
				
		Em.char_state.GRD_C_REC:
			if Animator.query(["HardLanding"]): # lower friction when hardlanding?
				friction_this_frame = FMath.percent(friction_this_frame, 50)

		Em.char_state.AIR_STANDBY:
			# just in case, fall animation if falling downwards without slowing down
			if velocity.y > 0 and Animator.query_to_play(["Jump"]):
				animate("FallTransit")
				
			if Animator.query_to_play(["FastFallTransit", "FastFall"]) and !button_down in input_state.pressed:
				animate("Fall")
				
			if Globals.assists != 0 and button_aux in input_state.just_pressed and Animator.query_to_play(["FastFallTransit"]):
				animate("Fall") # cancel fastfall if assist is called
	
		Em.char_state.AIR_D_REC:
			air_res_this_frame = 0
			# air dash into wall/ceiling, stop instantly
			var stopped := false
			var soft_dbox = get_soft_dbox(get_collision_box())
			if Animator.query_to_play(["aDash", "aDashD", "aDashU"]) and is_against_wall(facing, soft_dbox):
				stopped = true
			elif Animator.query_to_play(["aDashU"]) and is_against_ceiling(soft_dbox):
				stopped = true
			if stopped:
				animate("aDashBrake")
				if Animator.current_anim == "aDashTransit": # to fix a bug when touching a wall during aDashTransit > aDash
					lose_one_air_dash() # reduce air_dash count by 1
					
	
		Em.char_state.AIR_STARTUP, Em.char_state.AIR_REC:
			air_res_this_frame = 0
			
			var sdashing := false
			if Animator.query_current(["SDash"]):
				if button_dash in input_state.pressed:
					sdashing = true
#					if !grounded: # if airborne, change to aSDash
#						animate("aSDash")
				else:
					if !grounded:
						animate("aDashBrake")
					else:
						animate("DashBrake")
#			elif Animator.query_current(["aSDash"]):
#				if button_dash in input_state.pressed:
#					sdashing = true
##					if grounded: # if landed on ground, change to SDash
##						animate("SDash")
#				else:
#					if !grounded:
#						animate("aDashBrake")
#					else:
#						animate("DashBrake")
				
			if sdashing:
				
				if !velocity.is_longer_than(FMath.percent(get_stat("SDASH_SPEED"), 90)):
					if !grounded:
						animate("aDashBrake")
					else:
						animate("DashBrake")
				else:
						
					var vel_angle = velocity.angle() # rotation and navigation
					
					if is_too_high():
						match Globals.split_angle(vel_angle, Em.angle_split.EIGHT):
							Em.compass.S, Em.compass.SE, Em.compass.SW:
								sdash_points -= 1
							Em.compass.E, Em.compass.W:
								sdash_points -= 2
							Em.compass.N, Em.compass.NE, Em.compass.NW:
								sdash_points -= 3
					else:
						sdash_points -= 1

					if sdash_points <= 0:
						if !grounded:
							animate("aDashBrake")
						else:
							animate("DashBrake")
					
					var rotated := false
					if dir != 0 or v_dir != 0:
						var target_angle = Globals.dir_to_angle(dir, v_dir, facing)
						var new_angle = Globals.navigate(vel_angle, target_angle, get_stat("SDASH_TURN_RATE"))
						if new_angle != vel_angle:
							velocity.rotate(new_angle - vel_angle)
							rotate_sprite(new_angle)
							rotated = true
					if !rotated:
						rotate_sprite(vel_angle)
					
					
		Em.char_state.GRD_BLOCK:
			if !button_block in input_state.pressed and !button_dash in input_state.pressed and Animator.query_current(["Block"]):
				animate("BlockRec")

			
		Em.char_state.AIR_BLOCK:
			if !button_block in input_state.pressed and !button_dash in input_state.pressed and Animator.query_current(["aBlock"]): # don't use to_play
				animate("aBlockRec")
					
			air_res_this_frame = 5


		Em.char_state.AIR_ATK_STARTUP:
			if anim_gravity_mod == 0:
				air_res_this_frame = 0
			friction_this_frame = FMath.percent(friction_this_frame, 75) # lower friction when landing while doing an aerial
			
		Em.char_state.AIR_ATK_ACTIVE:
			if anim_gravity_mod == 0:
				air_res_this_frame = 0
		
		Em.char_state.LAUNCHED_HITSTUN:
			friction_this_frame = FMath.percent(friction_this_frame, 25) # lower friction during launch hitstun
							
	
# APPLY FRICTION/AIR RESISTANCE --------------------------------------------------------------------------------------------------

	if grounded: # apply friction if on ground
		if anim_friction_mod != 100:
			friction_this_frame = FMath.percent(friction_this_frame, anim_friction_mod)
		velocity.x = FMath.f_lerp(velocity.x, 0, friction_this_frame)

	else: # apply air resistance if in air
		velocity.x = FMath.f_lerp(velocity.x, 0, air_res_this_frame)
	
	
# UNIQUE JUMP/FASTFALL CANCEL --------------------------------------------------------------------------------------------------
# pressing Unique will cancel fastfall if done immediately afterwards while Down is held
# these allow for input leniency for Unique + Down actions
	
	if Settings.input_assist[master_ID]:
		if button_unique in input_state.just_pressed:
			if button_down in input_state.pressed:
				match new_state:
					Em.char_state.AIR_STANDBY:
						if Animator.query_to_play(["FastFallTransit"]):
							animate("Fall")
#			if Settings.tap_jump[master_ID] == 1 and button_up in input_state.pressed:
#				match new_state:
#					Em.char_state.GRD_STARTUP:
#						if Animator.query_to_play(["JumpTransit"]):
#							animate("Idle")
#					Em.char_state.AIR_STARTUP:
#						if Animator.query_to_play(["aJumpTransit", "WallJumpTransit"]):
#							animate("Fall")
						
# --------------------------------------------------------------------------------------------------

	buffer_actions()
	UniqNPC.simulate() # some holdable buttons can have effect unique to the character
	
	test0()
	
	if input_buffer.size() > 0:
		process_input_buffer()

# --------------------------------------------------------------------------------------------------
	
	# finally move the damn thing

	# limit velocity if velocity limiter is not null, "if velocity_limiter.x" will not pass if it is zero!
	if velocity_limiter.x != null:
		var limit: int = FMath.percent(get_stat("SPEED"), velocity_limiter.x)
		velocity.x = int(clamp(velocity.x, -limit, limit))
	if velocity_limiter.up != null and velocity.y < -FMath.percent(get_stat("SPEED"), velocity_limiter.up):
		velocity.y = -FMath.percent(get_stat("SPEED"), velocity_limiter.up)
	if velocity_limiter.down != null and velocity.y > FMath.percent(get_stat("SPEED"), velocity_limiter.down):
		velocity.y = FMath.percent(get_stat("SPEED"), velocity_limiter.down)
	if velocity_limiter.x_slow != null:
		velocity.x = FMath.f_lerp(velocity.x, 0, velocity_limiter.x_slow)
	if velocity_limiter.y_slow != null:
		velocity.y = FMath.f_lerp(velocity.y, 0, velocity_limiter.y_slow)
	
		
	if grounded and dir == 0 and abs(velocity.x) < 2 * FMath.S * get_stat("FRICTION"):
		velocity.x = 0  # this reduces slippiness by canceling grounded horizontal velocity when moving less than 0.5 pixels per frame

	
	velocity_previous_frame.x = velocity.x
	velocity_previous_frame.y = velocity.y
	
	var orig_pos = position
	var results = move(check_ledge_stop()) # [landing_check, collision_check, ledgedrop_check]
	
#	if results[0]: check_landing()

	if results[1]:
		if $NoCollideTimer.is_running(): # if collide during 1st/Xth frame after hitstop, will return to position before moving
			position = orig_pos
			set_true_position()
			velocity.x = velocity_previous_frame.x
			velocity.y = velocity_previous_frame.y
		else:
			if UniqNPC.has_method("collision") and UniqNPC.collision(results):
				pass # unique collisions, UniqNPC.collision() returns true if has special outcome
			else:
				if results[0]:
					check_landing()
				
				if new_state == Em.char_state.AIR_REC and Animator.query_to_play(["SDash"]):
					check_sdash_crash()
				elif new_state == Em.char_state.LAUNCHED_HITSTUN:
					bounce(results[0])
			
		
	# must process hitbox/hurtboxes after calculation (since need to use to_play_anim after it is calculated)
	# however, must process before running the animation and advancing the time counter
	# must process after moving the character as well or will misalign
	
	# ends here, process hit detection in game scene, afterwards game scene will call simulate_after() to finish up
	

func simulate_after(): # called by game scene after hit detection to finish up the frame
	
	test1()
	
	progress_tap_and_release_memory()
		
	if Globals.Game.is_stage_paused():
		hitstop = null
		return
	if slowed != 0 and (slowed < 0 or posmod(Globals.Game.frametime, slowed) != 0):
		slowed = 0
		$HitStopTimer.stop()
		return
	slowed = 0
	
	flashes()
	
	if !$HitStopTimer.is_running():
		
		process_afterimage_trail() 	# do afterimage trails
		
		# render the next frame, this update the time!
		$SpritePlayer.simulate()
		$FadePlayer.simulate() # ModulatePlayer ignore hitstop but FadePlayer doesn't
		
		if !hitstop: # timers do not run on exact frame hitstop starts
			$VarJumpTimer.simulate()
			$NoCollideTimer.simulate()
		
		# spin character during launch, be sure to do this after SpritePlayer since rotation is reset at start of each animation
		if state == Em.char_state.LAUNCHED_HITSTUN and Animator.query_current(["LaunchTransit", "Launch"]):
			sprite.rotation = launch_starting_rot - facing * launchstun_rotate * LAUNCH_ROT_SPEED * Globals.FRAME
			launchstun_rotate += 1
		
		# start hitstop timer at end of frame after SpritePlayer.simulate() by setting hitstop to a number other than null for the frame
		# new hitstops override old ones
		if hitstop:
			$HitStopTimer.time = hitstop
			
		$ModulatePlayer.simulate() # modulate animations continue even in hitstop
		

	test2()
	

# BOUNCE --------------------------------------------------------------------------------------------------	

func bounce(against_ground: bool):
	var soft_dbox = get_soft_dbox(get_collision_box())
# warning-ignore:narrowing_conversion
	if is_against_wall(sign(velocity_previous_frame.x), soft_dbox):
		velocity.x = -FMath.percent(velocity_previous_frame.x, 75)
		if abs(velocity.x) > WALL_SLAM_THRESHOLD: # release bounce dust if fast enough

			if sign(velocity_previous_frame.x) > 0:
				bounce_dust(Em.compass.E)
			else:
				bounce_dust(Em.compass.W)
			play_audio("rock3", {"vol" : -10,})
				
				
	elif is_against_ceiling(soft_dbox):
		velocity.y = -FMath.percent(velocity_previous_frame.y, 50)
		if abs(velocity.y) > WALL_SLAM_THRESHOLD: # release bounce dust if fast enough
						
			bounce_dust(Em.compass.N)
			play_audio("rock3", {"vol" : -10,})
				
				
	elif against_ground:
		velocity.y = -FMath.percent(velocity_previous_frame.y, 50) # shorter bounce if techable
		if abs(velocity.y) > WALL_SLAM_THRESHOLD: # release bounce dust if fast enough towards ground
			bounce_dust(Em.compass.S)
			play_audio("rock3", {"vol" : -10,})
			
		
# TRUE POSITION --------------------------------------------------------------------------------------------------	
	# to move an object, first do move_true_position(), then get_rounded_position()
	# compare it to node position to get move_amount and plug it in move_amount()
	# on collision, or anything that manipulate position directly (fallthrough, moving platforms), reset true_position to node position
		
func set_true_position():
	true_position.x = int(position.x * FMath.S)
	true_position.y = int(position.y * FMath.S)
	
func get_rounded_position() -> Vector2:
	return true_position.convert_to_vec()
	
func move_true_position(in_velocity: FVector):
# warning-ignore:integer_division
	true_position.x += int(in_velocity.x / 60)
# warning-ignore:integer_division
	true_position.y += int(in_velocity.y / 60)
	
		
# BUFFERING BUTTONs --------------------------------------------------------------------------------------------------	
	
func buffer_time():
	return Settings.input_buffer_time[master_ID]
	
func buffer_actions():

	if Globals.survival_level != null and Inventory.shop_open:
		return

	if button_left in input_state.just_released:
		release_memory.append([button_left, TAP_MEMORY_DURATION])
	if button_right in input_state.just_released:
		release_memory.append([button_right, TAP_MEMORY_DURATION])
		
	if button_up in input_state.just_pressed:
		if !button_unique in input_state.pressed and Settings.tap_jump[master_ID] == 1:
			input_buffer.append([button_up, buffer_time()])
		tap_memory.append([button_up, TAP_MEMORY_DURATION])
	if button_down in input_state.just_pressed:
		tap_memory.append([button_down, TAP_MEMORY_DURATION])
	if button_dash in input_state.just_pressed:
#		if !alt_block and !button_unique in input_state.pressed:
		tap_memory.append([button_dash, TAP_MEMORY_DURATION])
		if !button_unique in input_state.pressed:
			input_buffer.append([button_dash, buffer_time()])
		
	if button_special in input_state.just_pressed:
		tap_memory.append([button_special, TAP_MEMORY_DURATION])
	if button_unique in input_state.just_pressed:
		tap_memory.append([button_unique, TAP_MEMORY_DURATION])
		
	if button_special in input_state.just_released:
		release_memory.append([button_special, TAP_MEMORY_DURATION])
	if button_unique in input_state.just_released:
		release_memory.append([button_unique, TAP_MEMORY_DURATION])
		
	if button_light in input_state.just_pressed:
		if !button_unique in input_state.pressed:
			input_buffer.append([button_light, buffer_time()])
		tap_memory.append([button_light, TAP_MEMORY_DURATION])
	if button_fierce in input_state.just_pressed:
		if !button_unique in input_state.pressed:
			input_buffer.append([button_fierce, buffer_time()])
		tap_memory.append([button_fierce, TAP_MEMORY_DURATION])
	if button_aux in input_state.just_pressed:
		if !button_unique in input_state.pressed:
			input_buffer.append([button_aux, buffer_time()])
		tap_memory.append([button_aux, TAP_MEMORY_DURATION])
	
	if input_state.just_pressed.size() > 0 or release_memory.size() > 0:
		capture_combinations() # look for combinations

	if button_jump in input_state.just_pressed:
		input_buffer.push_front([button_jump, buffer_time()])
		tap_memory.append([button_jump, TAP_MEMORY_DURATION])
#	if button_jump in input_state.just_released:
#		release_memory.append([button_jump, TAP_MEMORY_DURATION])
		
	# quick cancel from button release
	if Settings.input_assist[master_ID] and (button_up in input_state.just_released or button_down in input_state.just_released):
		match new_state:
			Em.char_state.GRD_ATK_STARTUP:
				if Animator.time <= 1 and Animator.time != 0:
					rebuffer_actions()
			Em.char_state.AIR_ATK_STARTUP:
				if Animator.time <= 3 and Animator.time != 0:
					rebuffer_actions()
					
	if button_rs_up in input_state.just_pressed or button_rs_down in input_state.just_pressed or button_rs_left in input_state.just_pressed or \
			button_rs_right in input_state.just_pressed:
		input_buffer.append(["SDash", buffer_time()])
		
		
# SPECIAL ACTIONS --------------------------------------------------------------------------------------------------
		
func capture_combinations():
	
	# instant air dash, place at back
	if Settings.input_assist[master_ID]:
		combination(button_jump, button_dash, "InstaAirDash")
		
	if !button_unique in input_state.pressed:
		UniqNPC.capture_combinations()
	else:
		UniqNPC.capture_unique_combinations()

	combination(button_light, button_dash, "Dodge")
	combination(button_fierce, button_dash, "SDash")
	combination(button_block, button_dash, "Burst")

# used for rebuffer_actions()
func rebuffer(button1, button2, action, back = false):
	if button1 in input_state.pressed and button2 in input_state.pressed:
#		spend_button(button1)
		if !back:
			input_buffer.push_front([action, buffer_time()])
		else:
			input_buffer.append([action, buffer_time()])

				
func rebuffer_trio(button1, button2, button3, action, back = false):
	if button1 in input_state.pressed and button2 in input_state.pressed and button3 in input_state.pressed:
#		spend_button(button1)
		if !back:
			input_buffer.push_front([action, buffer_time()])
		else:
			input_buffer.append([action, buffer_time()])


func combination(button1, button2, action, back = false):
	if (button1 in input_state.just_pressed and is_button_pressed(button2)) or \
		(button2 in input_state.just_pressed and is_button_pressed(button1)):

		if !back:
			input_buffer.push_front([action, buffer_time()])
		else:
			input_buffer.append([action, buffer_time()])

		return true
	return false
				
func combination_trio(button1, button2, button3, action, back = false):
	if (button1 in input_state.just_pressed and is_button_pressed(button2) and is_button_pressed(button3)) or \
		(button2 in input_state.just_pressed and is_button_pressed(button1) and is_button_pressed(button3)) or \
		(button3 in input_state.just_pressed and is_button_pressed(button1) and is_button_pressed(button2)):
		if !back:
			input_buffer.push_front([action, buffer_time()])
		else:
			input_buffer.append([action, buffer_time()])
		return true
	return false
			
			
		
func is_button_pressed(button):
#	if button in [button_dash]: # dash command needs to be at most 2 frames apart
#		if is_button_tapped_in_last_X_frames(button, 2):
#			return true
	if button in [button_light, button_fierce, button_aux, button_dash, button_block]: # for attack buttons, only considered "pressed" a few frame after being tapped
		# so you cannot hold attack and press down to do down-tilts, for instance. Have to hold down and press attack
		if is_button_tapped_in_last_X_frames(button, 3):
			return true
	else:
		if button in input_state.pressed:
			return true
	return false

	
func is_button_released_in_last_X_frames(button, x_time):
	if !Settings.input_assist[master_ID]:
		if button in input_state.just_released:
			return true
		else:
			return false
	
	for x in release_memory.size():
		var release = release_memory[-x-1]
		if release[1] < TAP_MEMORY_DURATION - x_time:
			return false
		if release[0] == button:
			return true
	return false
	
func is_button_tapped_in_last_X_frames(button, x_time):
	for x in tap_memory.size():
		var tap = tap_memory[-x-1]
		if tap[1] < TAP_MEMORY_DURATION - x_time:
			return false
		if tap[0] == button:
			return true
	return false
	
func count_tap(button, x_time):
	var count := 0
	for x in tap_memory.size():
		var tap = tap_memory[-x-1]
		if tap[1] < TAP_MEMORY_DURATION - x_time:
			break
		if tap[0] == button:
			count += 1
	return count
			
	
func held_version(button): # for held version of moves, called 8 frames after startup
	if !button in input_state.pressed:
		return false
	if is_button_tapped_in_last_X_frames(button, 7): # if this button is pressed in the last X frames, return false
		return false
	return true
	
func perfect_release(button): # always at least 8 frames after startup
	if !button in input_state.just_released:
		return false
	if is_button_tapped_in_last_X_frames(button, 7): # if this button is pressed in the last X frames, return false
		return false
	return true

		
func cancel_action(): # called from UniqNPC for character-unique action cancelling
	input_buffer = []
	startup_cancel_flag = true
	afterimage_cancel()
	if grounded:
		animate("Idle")
	else:
		animate("FallTransit")
	
# INPUT BUFFER ---------------------------------------------------------------------------------------------------
	
func process_input_buffer():

#	var input_to_erase = [] # need this as cannot erase array members while iterating through it
	var clear_buffer := false
	var input_to_add = [] # some actions add inputs to the buffer, adding array members while iterating through it can cause issues
	
	var has_acted := [false]
	# any attack/sdash when processed when turn this to true causing all further jumps/attacks to be ignored and erased
	# used an array for this so I don't have to pass it back...
	
	
	
	for buffered_input in input_buffer:
		var keep := true

		match buffered_input[0]:
			
			button_jump, button_up:
				if Animator.query_current(["JumpTransit2", "aJumpTransit2", "WallTransit2"]): # consume buffered jumps during jump transits
					keep = false
					continue
				if !has_acted[0]:
					match new_state:
						
						# JUMPING ON GROUND --------------------------------------------------------------------------------------------------
						
						Em.char_state.GRD_STANDBY, Em.char_state.GRD_C_REC, Em.char_state.GRD_D_REC:
							
							if new_state == Em.char_state.GRD_D_REC:
								if UniqNPC.has_method("check_jc_d_rec") and UniqNPC.check_jc_d_rec():
									pass # some characters has certain jump cancellable d_rec
								elif !has_trait(Em.trait.GRD_DASH_JUMP):
									continue # some characters can jump while dashing
							
							if button_down in input_state.pressed and !button_dash in input_state.pressed and soft_grounded:
								# fallthrough

								position.y += 2 # 1 will cause issues with downward moving platforms
								set_true_position()
								animate("FallTransit")
								grounded = false # need to do this since moving outside of the end of simulate2()
								keep = false
									
							if keep:
								
								if button_dash in input_state.pressed: # for wavedash alternate input
									input_to_add.append([button_dash, buffer_time()])
								
								animate("JumpTransit") # ground jump
								keep = false
								
						Em.char_state.GRD_BLOCK: # instant air block
							if Settings.input_assist[master_ID] and Animator.time <= 1:
								animate("JumpTransit") 
								keep = false
							
								
						# AIR JUMPS  --------------------------------------------------------------------------------------------------
			
						Em.char_state.AIR_STANDBY, Em.char_state.AIR_C_REC, Em.char_state.AIR_D_REC:
							
							if grounded:
								animate("JumpTransit") # ground jump
								keep = false
								continue

							if new_state == Em.char_state.AIR_D_REC:
								if UniqNPC.has_method("check_jc_d_rec") and UniqNPC.check_jc_d_rec():
									pass # some characters has certain jump cancellable d_rec
								elif !has_trait(Em.trait.AIR_DASH_JUMP):
									continue # some characters can jump while dashing
							
#							if Settings.dj_fastfall[master_ID] == 1 and button_down in input_state.pressed:
#								continue
							if button_down in input_state.pressed:
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
#								input_to_add.append([button_dash, buffer_time()])
#								keep = false
								
						# AIR JUMPS  --------------------------------------------------------------------------------------------------
								
							elif air_jump > 0 and !button_dash in input_state.pressed: # no dash for easier wavedashing
								animate("aJumpTransit")
								keep = false
								
						# AERIAL AIR JUMP CANCEL ---------------------------------------------------------------------------------
							
						Em.char_state.AIR_ATK_REC:
#							if Settings.dj_fastfall[master_ID] == 1 and button_down in input_state.pressed:
#								continue
							if button_down in input_state.pressed:
								continue
								
							if test_jump_cancel():
								animate("aJumpTransit")
								keep = false
								
						Em.char_state.AIR_ATK_ACTIVE: # some attacks can jump cancel on active frames
							if button_down in input_state.pressed:
								continue
								
							if test_jump_cancel_active():
								if !grounded:
									if air_jump > 0:
										afterimage_cancel()
										animate("aJumpTransit")
										keep = false
								else: # grounded
									afterimage_cancel()
									animate("JumpTransit")
									keep = false
	
						# JUMP CANCELS ---------------------------------------------------------------------------------
								
						Em.char_state.GRD_ATK_REC:
							if test_jump_cancel():
								if button_down in input_state.pressed and !button_dash in input_state.pressed \
									and soft_grounded: # cannot be pressing dash
									position.y += 2 # 1 will cause issues with downward moving platforms
									set_true_position()
									animate("FallTransit")
									keep = false
								else:
									animate("JumpTransit")
									keep = false
						
						Em.char_state.GRD_ATK_ACTIVE: # some attacks can jump cancel on active frames
							if test_jump_cancel_active():
								afterimage_cancel()
								if button_down in input_state.pressed and !button_dash in input_state.pressed \
									and soft_grounded: # cannot be pressing dash
									position.y += 2 # 1 will cause issues with downward moving platforms
									set_true_position()
									animate("FallTransit")
									keep = false
								else:
									animate("JumpTransit")
									keep = false
	
								
						Em.char_state.GRD_ATK_STARTUP: # can quick jump cancel the 1st few frame of ground attacks, helps with instant aerials
							if buffered_input[0] != button_jump:
								continue # cannot quick jump cancel with up button
							if !Settings.input_assist[master_ID]:
								continue
							if chain_memory.size() != 0:
								continue # cannot quick jump cancel attacks in chains
							var move_name = get_move_name()
							if move_name in UniqNPC.STARTERS and !is_ex_move(move_name) and !is_super(move_name):
								if Animator.time <= 1 and Animator.time != 0:
									animate("JumpTransit")
									rebuffer_actions() # this buffers the attack buttons currently being pressed
									keep = false
									
				if keep and UniqNPC.has_method("unique_jump"):
					keep = UniqNPC.unique_jump()
					
									
			# FOR NON_JUMP ACTIONS --------------------------------------------------------------------------------------------------
									
			"SDash":
				if is_attacking(): # new state must not be standby
					match state:
						Em.char_state.GRD_ATK_ACTIVE, Em.char_state.AIR_ATK_ACTIVE, \
								Em.char_state.GRD_ATK_REC, Em.char_state.AIR_ATK_REC:
							if test_sdash_cancel():
								animate("SDashTransit")
								has_acted[0] = true
								keep = false
								
				if keep:
					match new_state:
						Em.char_state.GRD_STANDBY, Em.char_state.GRD_C_REC, \
								Em.char_state.AIR_STANDBY, Em.char_state.AIR_C_REC, \
								Em.char_state.GRD_STARTUP, Em.char_state.AIR_STARTUP, \
								Em.char_state.GRD_REC, Em.char_state.AIR_REC, \
								Em.char_state.GRD_D_REC, Em.char_state.AIR_D_REC, \
								Em.char_state.GRD_BLOCK, Em.char_state.AIR_BLOCK, \
								Em.char_state.GRD_ATK_STARTUP, Em.char_state.AIR_ATK_STARTUP:
									
							var flag := true
							match new_state:
								Em.char_state.GRD_STARTUP, Em.char_state.AIR_STARTUP:
									if !Settings.input_assist[master_ID]:
										flag = false
										continue
									if Animator.time > 1 or Animator.time == 0: # can only cancel from jump/dash on the first frame
										flag = false
										continue
									var transits := ["JumpTransit", "aJumpTransit", "DashTransit", "aDashTransit"]
									if "TRANSIT_SDASH" in UniqNPC:
										transits.append_array(UniqNPC.TRANSIT_SDASH) # for special types of dashes
									if !Animator.query_to_play(transits):
										flag = false # can only cancel from Transits for GRD_STARTUP/AIR_STARTUP
								Em.char_state.AIR_D_REC, Em.char_state.GRD_D_REC:
									if Animator.time < 2:
										flag = false # cannot cancel from 1st frame of dash
								Em.char_state.GRD_ATK_STARTUP, Em.char_state.AIR_ATK_STARTUP:
									if !Settings.input_assist[master_ID]:
										flag = false
										continue
									if Animator.time > 1 or Animator.time == 0: # can only cancel from attacks on the first frame
										flag = false
										continue
									if chain_combo != Em.chain_combo.RESET: # cannot cancel when chaining/whiffing
										flag = false
										continue
									if !is_normal_attack(get_move_name()): # only light/fierce can be cancelled
										flag = false
								Em.char_state.AIR_REC:
									if Animator.query_to_play(["SDash"]):
										flag = false # prevent SDashing from SDash
							if flag and (grounded or super_dash > 0):
								animate("SDashTransit")
								has_acted[0] = true
								keep = false
			

			_:
				# pass to process_buffered_input() in unique character node, it returns a bool of whether input should be kept
				# some special buttons can also add new buffered inputs, this are added at the end
				if !UniqNPC.process_buffered_input(new_state, buffered_input, input_to_add, has_acted):
					keep = false
				
		# remove expired
		buffered_input[1] -= 1
		if buffered_input[1] < 0:
			keep = false
			
		if !keep or has_acted[0]:
			clear_buffer = true
#			input_to_erase.append(buffered_input)
	
#	for input in input_to_erase:
#		input_buffer.erase(input)
	if clear_buffer:
		input_buffer = []
		
	input_buffer.append_array(input_to_add) # add the inputs added by special actions

# STATE DETECT ---------------------------------------------------------------------------------------------------

func animate(anim):

	var old_new_state: int = new_state
	
	if Animator.play(anim):
		new_state = state_detect(anim)
		
		if anim.ends_with("Active") and !Em.atk_attr.NO_HITCOUNT_RESET in UniqNPC.query_atk_attr(get_move_name()):
			atk_startup_resets() # need to do this here to work! resets hitcount and ignore list

		# when changing to a non-attacking state from attack startup, auto-buffer pressed attack buttons
		if Settings.input_assist[master_ID] and !startup_cancel_flag and !is_attacking():
			match old_new_state:
				Em.char_state.GRD_ATK_STARTUP, Em.char_state.AIR_ATK_STARTUP:
					rebuffer_actions()

			
func rebuffer_actions():
	
	if button_light in input_state.pressed:
		input_buffer.append([button_light, buffer_time()])
	if button_fierce in input_state.pressed:
		input_buffer.append([button_fierce, buffer_time()])
	if button_aux in input_state.pressed:
		input_buffer.append([button_aux, buffer_time()])
	
	UniqNPC.rebuffer_actions()
	

func query_state(query_states: Array):
	for x in query_states:
		if state == x or new_state == x:
			return true
	return false

func state_detect(anim) -> int:
	match anim:
		# universal animations
		"Idle", "RunTransit", "Run", "Brake":
			return Em.char_state.GRD_STANDBY
#		"CrouchTransit", "Crouch", "CrouchReturn":
#			return Em.char_state.CROUCHING
		"JumpTransit":
			return Em.char_state.GRD_STARTUP

		"BlockRec":
			return Em.char_state.GRD_REC
		"SoftLanding", "DashBrake", "WaveDashBrake", "BlockCRec", "HardLanding":
			return Em.char_state.GRD_C_REC
			
		"JumpTransit3","aJumpTransit3", "Jump", "FallTransit", "Fall", "FastFallTransit", "FastFall":
			return Em.char_state.AIR_STANDBY
		"aJumpTransit", "WallJumpTransit", "aJumpTransit2", "WallJumpTransit2", "aDashTransit", "JumpTransit2":
			# ground/air jumps have 1 frame of AIR_STARTUP after lift-off to delay actions like instant air dash/wavedashing
			return Em.char_state.AIR_STARTUP

		"aBlockRec":
			return Em.char_state.AIR_REC
		"aDashBrake", "aBlockCRec":
			return Em.char_state.AIR_C_REC
			
		"LaunchStop", "LaunchTransit", "Launch":
			return Em.char_state.LAUNCHED_HITSTUN
		
		"SeqFlinchAFreeze", "SeqFlinchBFreeze":
			return Em.char_state.SEQ_TARGET
		"SeqFlinchAStop", "SeqFlinchA", "SeqFlinchBStop", "SeqFlinchB":
			return Em.char_state.SEQ_TARGET
		"aSeqFlinchAFreeze", "aSeqFlinchBFreeze":
			return Em.char_state.SEQ_TARGET
		"aSeqFlinchAStop", "aSeqFlinchA", "aSeqFlinchBStop", "aSeqFlinchB":
			return Em.char_state.SEQ_TARGET
		"SeqLaunchFreeze":
			return Em.char_state.SEQ_TARGET
		"SeqLaunchStop", "SeqLaunchTransit", "SeqLaunch":
			return Em.char_state.SEQ_TARGET
			
		"BlockStartup", "TBlockStartup":
			return Em.char_state.GRD_BLOCK
		"aBlockStartup", "aTBlockStartup":
			return Em.char_state.AIR_BLOCK
		"Block", "BlockLanding":
			return Em.char_state.GRD_BLOCK
		"aBlock":
			return Em.char_state.AIR_BLOCK

			
		"SDash":
			return Em.char_state.AIR_REC
		"SDashTransit":
			return Em.char_state.AIR_STARTUP
			
		_: # unique animations
			return UniqNPC.state_detect(anim)
			
	
# ---------------------------------------------------------------------------------------------------

func get_seq_partner():
	if seq_partner_ID == null: return null
	var Partner
	if state == Em.char_state.SEQ_USER:
		Partner = Globals.Game.get_player_node(seq_partner_ID)
	else:
		return null # cannot be in Em.char_state.SEQ_TARGET
	if Partner == null:
		return null
	if Partner == self:
		return null
	return Partner
	
func get_target():
	return master_node.get_target()
			

# MODIFERS AND ENHANCE -----------------------------------------------------------------------------------------------------------------

func get_stat(stat: String) -> int:
	
	var to_return
	
	if stat in self:
		to_return = get(stat)
	elif stat in UniqNPC:
		to_return = UniqNPC.get_stat(stat)
		
	if Globals.survival_level != null:
		match stat:
			"SPEED":
				to_return = FMath.percent(to_return, Inventory.modifier(master_ID, Cards.effect_ref.SPEED))
				to_return = int(max(to_return, 10))
			"JUMP_SPEED":
				to_return = FMath.percent(to_return, Inventory.modifier(master_ID, Cards.effect_ref.JUMP_SPEED))
				to_return = int(max(to_return, 10))
			"GRAVITY_MOD":
				to_return = FMath.percent(to_return, Inventory.modifier(master_ID, Cards.effect_ref.GRAVITY_MOD))
				to_return = int(max(to_return, 10))
			"FRICTION":
				to_return = FMath.percent(to_return, Inventory.modifier(master_ID, Cards.effect_ref.FRICTION))
				to_return = int(max(to_return, 10))
				
			"MAX_AIR_JUMP":
				to_return += Inventory.modifier(master_ID, Cards.effect_ref.MAX_AIR_JUMP)
				to_return = int(max(to_return, 0))
			"MAX_AIR_DASH":
				to_return += Inventory.modifier(master_ID, Cards.effect_ref.MAX_AIR_DASH)
				to_return = int(max(to_return, 0))
			"MAX_SUPER_DASH":
				to_return += Inventory.modifier(master_ID, Cards.effect_ref.MAX_SUPER_DASH)
				to_return = int(max(to_return, 0))
				
			"GRD_DASH_SPEED":
				to_return = FMath.percent(to_return, Inventory.modifier(master_ID, Cards.effect_ref.GRD_DASH_SPEED))
				to_return = int(max(to_return, 10))
			"AIR_DASH_SPEED":
				to_return = FMath.percent(to_return, Inventory.modifier(master_ID, Cards.effect_ref.AIR_DASH_SPEED))
				to_return = int(max(to_return, 10))
			"SDASH_SPEED":
				to_return = FMath.percent(to_return, Inventory.modifier(master_ID, Cards.effect_ref.SDASH_SPEED))
				to_return = int(max(to_return, 10))

				
	return to_return
	
				
func has_trait(trait: int) -> bool:
	if trait in UniqNPC.query_traits():
		return true
		
	return false
					
		
func mod_damage(move_name):
	var mod := 100
	
	if Inventory.has_quirk(master_ID, Cards.effect_ref.REVENGE):
		var percent = master_node.get_damage_percent()
		if percent > 50:
			var weight = FMath.get_fraction_percent(percent - 50, 50)
			mod += FMath.f_lerp(100, 300, weight)
			
	if Inventory.has_quirk(master_ID, Cards.effect_ref.EX_RAISE_DMG):
		var weight = FMath.get_fraction_percent(master_node.current_ex_gauge, master_node.MAX_EX_GAUGE)
		mod += FMath.f_lerp(0, 100, weight)

	
	match UniqNPC.MOVE_DATABASE[move_name][Em.move.ATK_TYPE]:
		Em.atk_type.LIGHT:
			mod += Inventory.modifier(master_ID, Cards.effect_ref.LIGHT_DMG_MOD, true)
			if move_name.begins_with("a"):
				mod += Inventory.modifier(master_ID, Cards.effect_ref.AIR_NORMAL_DMG_MOD, true)
			else:
				mod += Inventory.modifier(master_ID, Cards.effect_ref.GRD_NORMAL_DMG_MOD, true)
				
		Em.atk_type.FIERCE:
			mod += Inventory.modifier(master_ID, Cards.effect_ref.FIERCE_DMG_MOD, true)
			if move_name.begins_with("a"):
				mod += Inventory.modifier(master_ID, Cards.effect_ref.AIR_NORMAL_DMG_MOD, true)
			else:
				mod += Inventory.modifier(master_ID, Cards.effect_ref.GRD_NORMAL_DMG_MOD, true)
				
		Em.atk_type.HEAVY:
			mod += Inventory.modifier(master_ID, Cards.effect_ref.HEAVY_DMG_MOD, true)
				
		Em.atk_type.SPECIAL, Em.atk_type.EX:
			mod += Inventory.modifier(master_ID, Cards.effect_ref.SPECIAL_DMG_MOD, true)
			
		Em.atk_type.SUPER:
			mod += Inventory.modifier(master_ID, Cards.effect_ref.SUPER_DMG_MOD, true)
			
	mod = int(max(mod, 0))
	return mod
	
		
# ---------------------------------------------------------------------------------------------------------------------
		
func face(in_dir):
	facing = in_dir
	sprite.scale.x = facing
	sfx_over.scale.x = facing
	sfx_under.scale.x = facing
	
func face_opponent():
	if facing != get_opponent_dir():
		face(-facing)
		
func get_opponent_dir():
	var target = get_target()
	if target.position.x == position.x: return facing
	else: return int(sign(target.position.x - position.x))
	
func reset_jumps():
	air_jump = get_stat("MAX_AIR_JUMP") # reset jump count on ground
	wall_jump = MAX_WALL_JUMP # reset wall jump count on ground
	air_dash = get_stat("MAX_AIR_DASH")
	super_dash = get_stat("MAX_SUPER_DASH")
	aerial_memory = []
	aerial_sp_memory = []
	
#func reset_jumps_except_walljumps():
#	air_jump = get_stat("MAX_AIR_JUMP") # reset jump count on wall
#	air_dash = get_stat("MAX_AIR_DASH")
	
func gain_one_air_jump(): # hitting with an unblocked aerial give you +1 air jump
	if UniqNPC.has_method("gain_one_air_jump"):
		UniqNPC.gain_one_air_jump() # overwrite
	if air_jump < get_stat("MAX_AIR_JUMP"): # cannot go over
		air_jump += 1
		
func lose_one_air_jump():
	if UniqNPC.has_method("lose_one_air_jump"):
		UniqNPC.lose_one_air_jump() # overwrite
	elif air_jump > 0: # cannot go under
		air_jump -= 1	
		
func check_enough_air_jumps() -> bool:
	if UniqNPC.has_method("check_enough_air_jumps"):
		return UniqNPC.check_enough_air_jumps() # overwrite
	elif air_jump > 0:
		return true
	return false
	
func gain_one_air_dash(): # hitting with an unblocked aerial give you +1 air jump
	if UniqNPC.has_method("gain_one_air_dash"):
		UniqNPC.gain_one_air_dash() # overwrite
	if air_dash < get_stat("MAX_AIR_DASH"): # cannot go over
		air_dash += 1
		
func lose_one_air_dash():
	if UniqNPC.has_method("lose_one_air_dash"):
		UniqNPC.lose_one_air_dash() # overwrite
	elif air_dash > 0: # cannot go under
		air_dash -= 1	
		
func check_enough_air_dashes() -> bool:
	if UniqNPC.has_method("check_enough_air_dashes"):
		return UniqNPC.check_enough_air_dashes() # overwrite
	elif air_dash > 0:
		return true
	return false
		
func is_too_high() -> bool:
	var mid_height = FMath.percent(floor_level - Globals.Game.stage_box.rect_global_position.y, 50) + \
			Globals.Game.stage_box.rect_global_position.y
	if position.y < mid_height:
		return true
	return false		

func get_modded_jump_speed() -> int: # for air jumps and wall jumps
	var modded_jump = get_stat("JUMP_SPEED")
	if is_too_high():
		modded_jump = FMath.percent(modded_jump, 50)
	return modded_jump
	
func reset_cancels(): # done whenever you use an attack, after startup frames finish and before active frames begin
	chain_combo = Em.chain_combo.WHIFF
	active_cancel = false
	
func check_wall_jump():
	var left_wall = Detection.detect_bool([$WallJumpLeftDBox], ["SolidPlatforms", "CSolidPlatforms", "SemiSolidWalls", "BlastWalls"])
	var right_wall = Detection.detect_bool([$WallJumpRightDBox], ["SolidPlatforms", "CSolidPlatforms", "SemiSolidWalls", "BlastWalls"])
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
	if seq_partner_ID != null: return # no checking during start of sequence
	match new_state:
		Em.char_state.AIR_STANDBY:
			animate("SoftLanding")
			
		Em.char_state.AIR_C_REC:
			animate("SoftLanding")
			
		Em.char_state.AIR_STARTUP:
			if Animator.query_to_play(["aJumpTransit", "aJumpTransit2", "WallTransit2"]):
				animate("SoftLanding")
				if Settings.input_assist[master_ID]:
					input_buffer.append([button_jump, buffer_time()])
			elif Animator.query_to_play(["aDashTransit"]):
				animate("SoftLanding")
				if Settings.input_assist[master_ID]:
					input_buffer.append([button_dash, buffer_time()])
				
		Em.char_state.AIR_ACTIVE:
			pass # AIR_ACTIVE not used for now
			
		Em.char_state.AIR_D_REC:
			if Animator.to_play_anim.begins_with("aDash"):
				if !Animator.to_play_anim.ends_with("DD"): # wave landing
					animate("WaveDashBrake")
					UniqNPC.dash_sound()
					Globals.Game.spawn_SFX("GroundDashDust", "DustClouds", get_feet_pos(), {"facing":facing, "grounded":true})
					if dir == facing:
						var speed_target = get_stat("GRD_DASH_SPEED")
						if "AWAY_SPEED_MOD" in UniqNPC:
							if facing != get_opponent_dir():
								speed_target = FMath.percent(speed_target, get_stat("AWAY_SPEED_MOD"))
						velocity.x = facing * FMath.percent(speed_target, get_stat("WAVE_DASH_SPEED_MOD"))
							
				else: # landing during AirDashDD
					animate("HardLanding")
			
		Em.char_state.AIR_REC:
			if Animator.query_to_play(["aBlockRec"]): # aBlockRecovery to BlockCRecovery
				Globals.Game.spawn_SFX("LandDust", "DustClouds", get_feet_pos(), {"grounded":true})
				animate("BlockRec")
				UniqNPC.landing_sound()
				
			elif Animator.query_to_play(["SDash"]): # no landing
				pass
			
		Em.char_state.AIR_ATK_STARTUP: # can land cancel on the 1st few frames (unless EX/Super), will auto-buffer pressed attacks
			var move_name = get_move_name()
			if move_name in UniqNPC.STARTERS and !is_ex_move(move_name) and !is_super(move_name) and \
				velocity_previous_frame.y > 0 and Animator.time <= AERIAL_STARTUP_LAND_CANCEL_TIME and Animator.time != 0:
				animate("HardLanding") # this makes landing and attacking instantly easier
				
			
		Em.char_state.LAUNCHED_HITSTUN: # land during launch_hitstun, can bounce or tech land
			# check using either velocity this frame or last frame
			var vector_to_check
			if velocity.is_longer_than_another(velocity_previous_frame):
				vector_to_check = velocity
			else:
				vector_to_check = velocity_previous_frame
			
			if !vector_to_check.is_longer_than(TECHLAND_THRESHOLD):
				animate("HardLanding")
				velocity.y = 0 # stop bouncing
				modulate_play("unflinch_flash")

			
		Em.char_state.AIR_BLOCK: # air block to ground block
			Globals.Game.spawn_SFX("LandDust", "DustClouds", get_feet_pos(), {"grounded":true})
			
			if Animator.query_to_play(["aBlockStartup", "aTBlockStartup"]): # if dropping during block startup
				play_audio("bling4", {"vol" : -10, "bus" : "PitchUp2"})
					
			animate("BlockLanding")

			
func check_drop(): # called when character becomes airborne while in a grounded state
	if anim_gravity_mod <= 0: return
	if seq_partner_ID != null: return # no checking during start of sequence
	match new_state:
		
		Em.char_state.GRD_STANDBY, Em.char_state.GRD_C_REC, \
				Em.char_state.GRD_D_REC:
			animate("FallTransit")
			
		Em.char_state.GRD_STARTUP:
			if Animator.query_to_play(["JumpTransit"]): # instantly jump if dropped during jump transit
				animate("JumpTransit2")
			else:
				animate("FallTransit")
				
		Em.char_state.GRD_ACTIVE:
			pass # GRD_ACTIVE not used for now

		Em.char_state.GRD_REC:
			if Animator.query_to_play(["BlockRec"]):
				animate("aBlockRec")
			else:
				animate("FallTransit")
				
		Em.char_state.GRD_ATK_STARTUP:
			animate("FallTransit")
				
		Em.char_state.GRD_ATK_ACTIVE, Em.char_state.GRD_ATK_REC:
			var move_name = get_move_name()
			if move_name in UniqNPC.MOVE_DATABASE and \
				Em.atk_attr.LEDGE_DROP in query_atk_attr(move_name):
				continue
			else:
				animate("FallTransit")
			
		Em.char_state.GRD_BLOCK:
			if Animator.query_to_play(["BlockStartup", "TBlockStartup"]):
				play_audio("bling4", {"vol" : -10, "bus" : "PitchUp2"})
			animate("aBlock")


func check_sdash_crash():
	if !is_on_ground():
		animate("aDashBrake")
	else:
		if !velocity.is_longer_than(FMath.percent(get_stat("SDASH_SPEED"), 50)):
			animate("HardLanding")
		else:
			var old_angle = velocity.angle()
			velocity.set_vector(get_stat("SDASH_SPEED"), 0)
			velocity.rotate(old_angle)

		
func check_fallthrough(): # during aerials, can drop through platforms if down is held
	if state == Em.char_state.SEQ_USER:
		return UniqNPC.sequence_fallthrough()
		
	if UniqNPC.check_fallthrough():
		return true
	else:
		if new_state == Em.char_state.AIR_D_REC:
			return false
		if new_state == Em.char_state.AIR_REC and Animator.query_to_play(["Dodge", "SDash"]):
			return true
			
		if !grounded and velocity.y > 0:
			if button_jump in input_state.pressed:
				return true
				
	return false
			
	
func check_semi_invuln():
	if UniqNPC.check_semi_invuln():
		return true
	else:
		match new_state:
			Em.char_state.AIR_REC:
				if Globals.survival_level != null:
					if Animator.query_to_play(["SDash"]):
						if Inventory.has_quirk(master_ID, Cards.effect_ref.SDASH_IFRAME):
							return true
			Em.char_state.GRD_D_REC, Em.char_state.AIR_D_REC:
				if Globals.survival_level != null:
					if Inventory.has_quirk(master_ID, Cards.effect_ref.DASH_IFRAME):
						return true
			Em.char_state.LAUNCHED_HITSTUN: # has iframes on launch
				return true
			
	return false	
	
func check_passthrough():
	if state == Em.char_state.SEQ_USER:
		return UniqNPC.sequence_passthrough() # for cinematic supers

	return false
	
func sequence_partner_passthrough():
	return UniqNPC.sequence_partner_passthrough()
		
# check if in place for a down-dash snap up landing, if so, snap up
func check_snap_up():
	if Detection.detect_bool([$DashLandDBox], ["SoftPlatforms"]) and \
		!Detection.detect_bool([$DashLandDBox2], ["SoftPlatforms"]):
		return true
	else:
		return false
		
func snap_up_wave_land_check():
#	if velocity.y <= 0:
#		print("A")
	if !button_jump in input_state.pressed and check_snap_up() and snap_up():
		if dir != 0: # if holding direction, dash towards it
			if facing != dir:
				face(dir)
			animate("WaveDashBrake")
			if dir == facing:
				var speed_target = get_stat("GRD_DASH_SPEED")
				if "AWAY_SPEED_MOD" in UniqNPC:
					if facing != get_opponent_dir():
						speed_target = FMath.percent(speed_target, get_stat("AWAY_SPEED_MOD"))
				velocity.x = facing * FMath.percent(speed_target, get_stat("WAVE_DASH_SPEED_MOD"))
#			velocity.x = dir * get_stat("GRD_DASH_SPEED")
			Globals.Game.spawn_SFX("GroundDashDust", "DustClouds", get_feet_pos(), {"facing":facing, "grounded":true})
			UniqNPC.dash_sound()
		else:
			animate("SoftLanding")
			UniqNPC.landing_sound()
		return true
	else:
		return false
		
func get_feet_pos(): # return global position of the point the character is standing on, for SFX emission
	return position + Vector2(0, $PlayerCollisionBox.rect_position.y + $PlayerCollisionBox.rect_size.y)
	
func get_pos_from_feet(feet_pos: Vector2):
	return feet_pos - Vector2(0, $PlayerCollisionBox.rect_position.y + $PlayerCollisionBox.rect_size.y)
	

# SPECIAL EFFECTS --------------------------------------------------------------------------------------------------

func bounce_dust(orig_dir):
	match orig_dir:
		Em.compass.N:
			Globals.Game.spawn_SFX("BounceDust", "DustClouds", position + Vector2(0, $PlayerCollisionBox.rect_position.y), {"rot":PI})
		Em.compass.E:
			Globals.Game.spawn_SFX("BounceDust", "DustClouds", position + Vector2($PlayerCollisionBox.rect_size.x / 2, 0), \
					{"facing": 1, "rot":-PI/2})
		Em.compass.S:
			Globals.Game.spawn_SFX("BounceDust", "DustClouds", get_feet_pos(), {"grounded":true})
		Em.compass.W:
			Globals.Game.spawn_SFX("BounceDust", "DustClouds", position - Vector2($PlayerCollisionBox.rect_size.x / 2, 0), \
					{"facing": -1, "rot":-PI/2})

func set_monochrome():
	if !monochrome:
		monochrome = true
		sprite.material = ShaderMaterial.new()
		sprite.material.shader = Loader.monochrome_shader

# particle emitter, visuals only, no need fixed-point
func particle(anim: String, loaded_sfx_ref: String, palette, interval, number, radius, v_mirror_rand := false, master_palette := false):
	if posmod(Globals.Game.frametime, interval) == 0:  # only spawn every X frames
		for x in number:
			var angle = Globals.Game.rng_generate(10) * PI/5.0
			var distance = Globals.Game.rng_generate(5) * radius/5.0
			var particle_pos = position + Vector2(distance, 0).rotated(angle)
			particle_pos.x = round(particle_pos.x)
			particle_pos.y = round(particle_pos.y)

			var aux_data = {"facing" : Globals.Game.rng_facing()}
			if v_mirror_rand:
				aux_data["v_mirror"] = Globals.Game.rng_bool()
			if master_palette:
				Globals.Game.spawn_SFX(anim, loaded_sfx_ref, particle_pos, aux_data, palette, NPC_ref)
			else:
				Globals.Game.spawn_SFX(anim, loaded_sfx_ref, particle_pos, aux_data, palette)
			
			
func flashes():
			
	if is_blocking():
		modulate_play("block")
		
	UniqNPC.unique_flash()
	
		
			
func process_afterimage_trail():# process afterimage trail
	# Character.afterimage_trail() can accept 2 parameters, 1st is the starting modulate, 2nd is the lifetime
	
	# afterimage trail for certain modulate animations with the key "afterimage_trail"
	if NSAnims.modulate_animations.has($ModulatePlayer.current_anim) and \
		NSAnims.modulate_animations[$ModulatePlayer.current_anim].has("afterimage_trail") and \
		$ModulatePlayer.is_playing():
		# basic afterimage trail for "afterimage_trail" = 0
		if NSAnims.modulate_animations[$ModulatePlayer.current_anim]["afterimage_trail"] == 0:
			afterimage_trail()
			return
			
	UniqNPC.afterimage_trail()
			
			
func afterimage_trail(color_modulate = null, starting_modulate_a = 0.5, lifetime: int = 10, \
		afterimage_shader = Em.afterimage_shader.MASTER): # one afterimage every 3 frames
			
	if afterimage_timer <= 0:
		afterimage_timer = 2

# warning-ignore:unassigned_variable
		var main_color_modulate: Color
		
		if color_modulate == null: # if no color_modulate provided, sfx_over and sfx_under afterimages will follow color_modulate of main sprite
			main_color_modulate.r = sprite.modulate.r
			main_color_modulate.g = sprite.modulate.g
			main_color_modulate.b = sprite.modulate.b
		else:
			main_color_modulate = color_modulate
			
		
		if sfx_under.visible:
			Globals.Game.spawn_afterimage(NPC_ID, Em.afterimage_type.NPC, sprite_texture_ref.sfx_under, sfx_under.get_path(), palette_ref, NPC_ref, \
					main_color_modulate, starting_modulate_a, lifetime, afterimage_shader)
			
		Globals.Game.spawn_afterimage(NPC_ID, Em.afterimage_type.NPC, sprite_texture_ref.sprite, sprite.get_path(), palette_ref, NPC_ref, \
				main_color_modulate, starting_modulate_a, lifetime, afterimage_shader)
		
		if sfx_over.visible:
			Globals.Game.spawn_afterimage(NPC_ID, Em.afterimage_type.NPC, sprite_texture_ref.sfx_over, sfx_over.get_path(), palette_ref, NPC_ref, \
					main_color_modulate, starting_modulate_a, lifetime, afterimage_shader)
					
	else:
		afterimage_timer -= 1
		
		
func afterimage_cancel(starting_modulate_a = 0.4, lifetime: int = 12): # no need color_modulate for now
	
	if sfx_under.visible:
		Globals.Game.spawn_afterimage(NPC_ID, Em.afterimage_type.NPC, sprite_texture_ref.sfx_under, sfx_under.get_path(), palette_ref, NPC_ref, null, \
			starting_modulate_a, lifetime)
		
	Globals.Game.spawn_afterimage(NPC_ID, Em.afterimage_type.NPC, sprite_texture_ref.sprite, sprite.get_path(), palette_ref, NPC_ref, null, \
		starting_modulate_a, lifetime)
	
	if sfx_over.visible:
		Globals.Game.spawn_afterimage(NPC_ID, Em.afterimage_type.NPC, sprite_texture_ref.sfx_over, sfx_over.get_path(), palette_ref, NPC_ref, null, \
			starting_modulate_a, lifetime)
	
	
# QUICK STATE CHECK ---------------------------------------------------------------------------------------------------
	
func get_move_name():
	var move_name = Animator.to_play_anim.trim_suffix("Startup")
	move_name = move_name.trim_suffix("Active")
	move_name = move_name.trim_suffix("Rec")
#	move_name = UniqNPC.refine_move_name(move_name)
	
	return move_name
	
func check_quick_turn():
	
	if UniqNPC.has_method("check_quick_turn"): # some unique character states cannot be quick turned
		if !UniqNPC.check_quick_turn():
			return false
	
	if quick_turn_used: return false
	
	var can_turn := false
	match state:
		Em.char_state.GRD_STARTUP:
			can_turn = true
		Em.char_state.AIR_STARTUP:
			can_turn =  true
	match new_state:
		Em.char_state.GRD_ATK_STARTUP, Em.char_state.AIR_ATK_STARTUP: # for attacks, can turn on 1st 6 startup frames
#			if new_state == Em.char_state.AIR_ATK_STARTUP and !grounded: continue
			if Animator.time <= 6 and Animator.time != 0:
				var move_name = get_move_name()
				if move_name == null or !move_name in UniqNPC.STARTERS:
					can_turn = false
				elif Em.atk_attr.NO_TURN in query_atk_attr(move_name):
					can_turn = false
				else: can_turn = true
#		Em.char_state.AIR_ATK_STARTUP: # for aerials, can only turn on the 1st 3 frames
#			if Animator.time <= 3 and Animator.time != 0:
#				var move_name = get_move_name()
#				if move_name == null or !move_name in UniqNPC.STARTERS:
#					can_turn = false
#				elif Em.atk_attr.NO_TURN in query_atk_attr(move_name):
#					can_turn = false
#				else: can_turn = true
		Em.char_state.GRD_BLOCK:
			if Animator.query(["BlockStartup"]):
				can_turn = true
		Em.char_state.AIR_BLOCK:
			if Animator.query(["aBlockStartup"]):
				can_turn = true

	return can_turn

	
func check_quick_cancel(attack_ref): # cannot quick cancel from EX/Supers
	var move_name = get_move_name()
	if move_name == null: return false
	
	var orig_move_name = Animator.to_play_anim.trim_suffix("Startup")
	if !orig_move_name in UniqNPC.STARTERS: return false
	
	var from_move_data = query_move_data(move_name)
	if Em.atk_attr.NO_QUICK_CANCEL in from_move_data[Em.move.ATK_ATTR]:
		return false
		
	var to_move_data = query_move_data(attack_ref)
	if from_move_rec and Em.atk_attr.NOT_FROM_MOVE_REC in to_move_data[Em.move.ATK_ATTR]:
		return false
		
	if Em.move.REKKA in from_move_data:
		if Em.move.REKKA in to_move_data and from_move_data[Em.move.REKKA] == to_move_data[Em.move.REKKA]:
			pass
		else:
			return false # rekka move can only QC into another rekka move from the same parent
	
	
	if Globals.atk_type_to_tier(from_move_data[Em.move.ATK_TYPE]) > \
			Globals.atk_type_to_tier(to_move_data[Em.move.ATK_TYPE]):
		return false # for none-EX moves, cannot quick cancel into moves of lower tiers
	
	if !grounded and (button_up in input_state.just_released or button_down in input_state.just_released):
		if Animator.time <= 5 and Animator.time != 0: # release up/down rebuffer has wider window if in the air
			return true
	elif (button_special in input_state.just_pressed or button_unique in input_state.just_pressed):
		# cancelling into special moves via button_special/button_unique presses have wider window
		if Animator.time <= 2 and Animator.time != 0:
			return true
	elif Animator.time <= 1 and Animator.time != 0:
		return true
		
	return false
	


func check_ledge_stop(): # some animations prevent you from dropping off
	if !grounded or new_state in [Em.char_state.AIR_ATK_STARTUP, Em.char_state.AIR_ATK_ACTIVE, \
		Em.char_state.AIR_ATK_REC, Em.char_state.AIR_C_REC]:
		return false
	if is_attacking():
		var move_name = get_move_name()
		# test if move has LEDGE_DROP, no ledge stop if so
		if new_state != Em.char_state.GRD_ATK_STARTUP:
			if Em.atk_attr.LEDGE_DROP in query_atk_attr(move_name):
				return false # even with LEDGE_DROP, startup animation will still stop you at the ledge
			else:
				return true # no LEDGE_DROP, will stop at ledge
		else: # during startup of ground attacks
			if dir == facing and move_name in UniqNPC.STARTERS and !is_ex_move(move_name) and !is_super(move_name):
				return false # when doing moves that are not EX moves and supers, can drop off ledge on startup if you are holding forward
			else:
				return true
	else:
		return false # not attacking
	
func is_blocking():
	match new_state:
		Em.char_state.GRD_BLOCK, Em.char_state.AIR_BLOCK:
			if Animator.query_to_play(["BlockStartup", "aBlockStartup"]) and Animator.time <= 1:
				return false
			return true
	return false
	
func is_hitstunned():
	match state: # use non-new state
		Em.char_state.LAUNCHED_HITSTUN:
			return true
	return false
	
	
func is_hitstunned_or_sequenced2():
	match new_state:
		Em.char_state.LAUNCHED_HITSTUN, Em.char_state.SEQ_USER, Em.char_state.SEQ_TARGET:
			return true
	return false
	
func is_attacking():
	match new_state:
		Em.char_state.GRD_ATK_STARTUP, Em.char_state.GRD_ATK_ACTIVE, Em.char_state.GRD_ATK_REC, \
			Em.char_state.AIR_ATK_STARTUP, Em.char_state.AIR_ATK_ACTIVE, Em.char_state.AIR_ATK_REC, \
			Em.char_state.SEQ_USER:
			return true
	return false
	
func is_aerial():
	match new_state:
		Em.char_state.AIR_ATK_STARTUP, Em.char_state.AIR_ATK_ACTIVE, Em.char_state.AIR_ATK_REC:
			return true
	return false
	
func is_atk_startup():
	match new_state:
		Em.char_state.GRD_ATK_STARTUP, Em.char_state.AIR_ATK_STARTUP:
			return true
	return false
	
func is_atk_active():
	match new_state:
		Em.char_state.GRD_ATK_ACTIVE, Em.char_state.AIR_ATK_ACTIVE:
			return true
	return false
	
func is_atk_recovery():
	match new_state:
		Em.char_state.GRD_ATK_REC, Em.char_state.AIR_ATK_REC:
			return true
	return false
	
func is_normal_or_heavy(move_name):
	match query_move_data(move_name)[Em.move.ATK_TYPE]:
		Em.atk_type.LIGHT, Em.atk_type.FIERCE, Em.atk_type.HEAVY:
			return true
	return false
	
func is_normal_attack(move_name):
	match query_move_data(move_name)[Em.move.ATK_TYPE]:
		Em.atk_type.LIGHT, Em.atk_type.FIERCE:
			return true
	return false
	
func is_heavy(move_name):
	match query_move_data(move_name)[Em.move.ATK_TYPE]:
		Em.atk_type.HEAVY:
			return true
	return false
	
func is_non_EX_special_move(move_name):
	match query_move_data(move_name)[Em.move.ATK_TYPE]:
		Em.atk_type.SPECIAL:
			return true
	return false
	
func is_special_move(move_name):
	match query_move_data(move_name)[Em.move.ATK_TYPE]:
		Em.atk_type.SPECIAL, Em.atk_type.EX:
			return true
	return false
	
func is_ex_move(move_name):
	match query_move_data(move_name)[Em.move.ATK_TYPE]:
		Em.atk_type.EX:
			return true
	return false
	
func is_super(move_name):
	match query_move_data(move_name)[Em.move.ATK_TYPE]:
		Em.atk_type.SUPER:
			return true
	return false

func can_air_strafe(move_data):
	if move_data[Em.move.ATK_TYPE] in [Em.atk_type.LIGHT, Em.atk_type.FIERCE, Em.atk_type.HEAVY]: # Normal
		if Em.atk_attr.NO_STRAFE_NORMAL in move_data[Em.move.ATK_ATTR]:
			return false # cannot strafe during some aerial normals
	else: # non-Normal
		if !Em.atk_attr.STRAFE_NON_NORMAL in move_data[Em.move.ATK_ATTR]:
			return false # can strafe during some aerial non-normals
	return true
	

func test_jumpsquat_cancel(attack_ref: String):
	match js_cancel_target:
		Em.js_cancel_target.ALL:
			return true
		Em.js_cancel_target.NONE:
			return false
		Em.js_cancel_target.SPECIALS:
			var move_data = query_move_data(attack_ref)
			match move_data[Em.move.ATK_TYPE]:
				Em.atk_type.SPECIAL, Em.atk_type.EX, Em.atk_type.SUPER:
					return true
	return false

func test_jump_cancel(): # during recovery
	
	if !grounded and air_jump == 0: return false # if in air, need >1 air jump left
	
	var move_name = get_move_name()
	var atk_attr = query_atk_attr(move_name)
	if Em.atk_attr.NO_REC_CANCEL in atk_attr : return false # Normals with NO_REC_CANCEL cannot be jump cancelled
	
	match chain_combo:
		Em.chain_combo.RESET, Em.chain_combo.NO_CHAIN:
			return false
		Em.chain_combo.WHIFF:
			if !Em.atk_attr.JUMP_CANCEL_ON_WHIFF in atk_attr:
				return false # some rare Specials can jump cancel on whiff
			else:
				js_cancel_target = Em.js_cancel_target.NONE
		Em.chain_combo.NORMAL: # can only jump cancel on Normal/Heavy hit
			js_cancel_target = Em.js_cancel_target.ALL
		Em.chain_combo.HEAVY:
			js_cancel_target = Em.js_cancel_target.SPECIALS
		_:
			if !Em.atk_attr.JUMP_CANCEL_ON_HIT in atk_attr:
				return false # some rare Specials can jump cancel on hit
			else:
				js_cancel_target = Em.js_cancel_target.NONE
	
	afterimage_cancel()
	return true
	
	
func test_jump_cancel_active():
	
	if !grounded and air_jump == 0: return false # if in air, need >1 air jump left
	if chain_combo in [Em.chain_combo.RESET, Em.chain_combo.NO_CHAIN, Em.chain_combo.WHIFF]:
		return false # on hit only
	
	var atk_attr = query_atk_attr(get_move_name())
	if Em.atk_attr.LATE_CHAIN in atk_attr:
			return false  # some moves cannot be chained from during active frames
	if active_cancel or Em.atk_attr.JUMP_CANCEL_ACTIVE in atk_attr:
		match chain_combo:
			Em.chain_combo.NORMAL:
				js_cancel_target = Em.js_cancel_target.ALL
			Em.chain_combo.HEAVY:
				js_cancel_target = Em.js_cancel_target.SPECIALS
			_:
				js_cancel_target = Em.js_cancel_target.NONE
		return true
		
	return false
	
func test_dash_cancel():
	if !chain_combo in [Em.chain_combo.NORMAL, Em.chain_combo.HEAVY]:
		return false # can only dash cancel on Normal/Heavy hit
		
	if !grounded and air_dash == 0: return false # if in air, need >1 air dash left
	
	var move_name = get_move_name()
	if Em.atk_attr.NO_REC_CANCEL in query_atk_attr(move_name) : return false # Normals with NO_REC_CANCEL cannot be dash cancelled
	
	afterimage_cancel()
	return true
	
	
func test_dash_cancel_active():
	var atk_attr = query_atk_attr(get_move_name())
	if !active_cancel:
		return false
	if is_atk_active() and Em.atk_attr.LATE_CHAIN in atk_attr:
		return false
		
	afterimage_cancel()
	return true
	
	
func test_sdash_cancel():
	
	var move_name = get_move_name()
	var move_data = UniqNPC.query_move_data(move_name)
	
	if Em.atk_attr.NO_REC_CANCEL in move_data[Em.move.ATK_ATTR]:
		return false
		
	if Em.atk_attr.NO_SDASH_CANCEL in move_data[Em.move.ATK_ATTR]:
		return false
		
	match move_data[Em.move.ATK_TYPE]:
		Em.atk_type.LIGHT, Em.atk_type.FIERCE, Em.atk_type.HEAVY:
			if !chain_combo in [Em.chain_combo.NORMAL, Em.chain_combo.HEAVY]:
				return false # can only s_dash cancel on Normal/Heavy hit
				
			if !grounded and super_dash == 0: return false
			if is_atk_active():
				if Em.atk_attr.LATE_CHAIN in move_data[Em.move.ATK_ATTR]:
					return false
				if !active_cancel:
					return false

		_:
			return false
			
	afterimage_cancel()
	return true

	
func test_fastfall_cancel():
	if grounded: return false
	if !chain_combo in [Em.chain_combo.NORMAL, Em.chain_combo.HEAVY]: return false # can only fastfall cancel on hit (not block)
	
	var move_name = get_move_name()
	if Em.atk_attr.NO_REC_CANCEL in query_atk_attr(move_name) : return false # Normals with NO_REC_CANCEL cannot be fastfall cancelled
	
	afterimage_cancel()
	return true


func progress_tap_and_release_memory(): # remove taps and releases that expired
	var to_erase = []
	for tap in tap_memory:
		tap[1] -= 1
		if tap[1] <= 0:
			to_erase.append(tap)
	if to_erase.size() > 0:
		for x in to_erase:
			tap_memory.erase(x)
			
	var to_erase2 = []
	for release in release_memory:
		release[1] -= 1
		if release[1] <= 0:
			to_erase2.append(release)
	if to_erase2.size() > 0:
		for x in to_erase2:
			release_memory.erase(x)
#
			

func sprite_shake(): # used for Break and lethal blows
	if posmod(Globals.Game.frametime, 2) == 0:  # only shake every 2 frames
		var random = Globals.Game.rng_generate(9) + 1
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
		Em.hit.RECT : null,
		Em.hit.HURTBOX : null,
		Em.hit.SDHURTBOX : null,
		Em.hit.HITBOX : null,
		Em.hit.SWEETBOX: null,
		Em.hit.KBORIGIN: null,
		Em.hit.VACPOINT : null,
	}
	
	if state != Em.char_state.DEAD and slowed >= 0:
		if is_attacking():
			if is_atk_active():
				if !$HitStopTimer.is_running(): # no hitbox during hitstop
					polygons_queried[Em.hit.HITBOX] = Animator.query_polygon("hitbox")
					polygons_queried[Em.hit.SWEETBOX] = Animator.query_polygon("sweetbox")
					polygons_queried[Em.hit.KBORIGIN] = Animator.query_point("kborigin")
					polygons_queried[Em.hit.VACPOINT] = Animator.query_point("vacpoint")
#			if Globals.survival_level == null: # no semi-disjoint mechanic in Survival
			polygons_queried[Em.hit.SDHURTBOX] = Animator.query_polygon("sdhurtbox")
			
		if is_hitstunned():
			pass  # no hurtbox during hitstun
		else:
			polygons_queried[Em.hit.HURTBOX] = Animator.query_polygon("hurtbox")
			
		if polygons_queried[Em.hit.HITBOX] != null or polygons_queried[Em.hit.HURTBOX] != null:
			polygons_queried[Em.hit.RECT] = get_sprite_rect()

	return polygons_queried
	
func get_sprite_rect():
	var sprite_rect = sprite.get_rect()
	return Rect2(sprite_rect.position + position, sprite_rect.size)
	
func get_hitbox():
	var hitbox = Animator.query_polygon("hitbox")
	return hitbox
	
func query_move_data_and_name(): # requested by main game node when doing hit detection
	
	if Animator.to_play_anim.ends_with("Active"):
		var move_name = Animator.to_play_anim.trim_suffix("Active")
		var refined_move_name = UniqNPC.refine_move_name(move_name)
		if UniqNPC.MOVE_DATABASE.has(refined_move_name):
			return {Em.hit.MOVE_DATA : UniqNPC.query_move_data(move_name), Em.hit.MOVE_NAME : refined_move_name}
		else:
			print("Error: " + move_name + " not found in MOVE_DATABASE for query_move_data_and_name().")
	else:
		print("Error: query_move_data_and_name() called by main game node outside of Active frames")
		return null
		
	
func test_aerial_memory(attack_ref): # attack_ref already has "a" added for aerial normals
	
	attack_ref = UniqNPC.get_root(attack_ref) # get the root attack
	if attack_ref in aerial_memory or attack_ref in aerial_sp_memory:
		return false
		
	return true
	
	
func test_dash_attack(attack_ref):
	
	match new_state: # need to be in attack active/recovery
		Em.char_state.GRD_D_REC, Em.char_state.AIR_D_REC:
			pass
		_:
			return true
			
	var root_attack_ref = UniqNPC.get_root(attack_ref)
	if root_attack_ref in chain_memory: return false # cannot chain into moves already done
	return true
	
	
func test_chain_combo(attack_ref): # attack_ref is the attack you want to chain to
	
	if chain_combo == Em.chain_combo.PARRIED or chain_combo == Em.chain_combo.NO_CHAIN: return false
	# cannot cancel into anything but Burst Counter if parried
	
	match state: # need to be in attack active/recovery
		Em.char_state.GRD_ATK_ACTIVE, Em.char_state.AIR_ATK_ACTIVE, \
				Em.char_state.GRD_ATK_REC, Em.char_state.AIR_ATK_REC:
			pass
		_:
			return false
			
	if !attack_ref in UniqNPC.STARTERS:
		return false
	
	var move_name = get_move_name()
	
	if UniqNPC.has_method("unique_chaining_rules") and UniqNPC.unique_chaining_rules(move_name, attack_ref):
		# will use Character.chain_combo, good for autocombos that triggers on hit/block and may/may not be on whiff
		afterimage_cancel()
		return true
	
	var from_move_data = query_move_data(move_name)
	var to_move_data = query_move_data(attack_ref)
	
	match from_move_data[Em.move.ATK_TYPE]:
		Em.atk_type.LIGHT: # Light Normals can chain cancel on whiff
			pass
		Em.atk_type.FIERCE: # Fierce Normals cannot chain into Lights on whiff/block
			if !chain_combo in [Em.chain_combo.NORMAL] and \
					to_move_data[Em.move.ATK_TYPE] == Em.atk_type.LIGHT:
				return false
		Em.atk_type.HEAVY: # Heavy Normals can only chain cancel into non-normals
			if !chain_combo in [Em.chain_combo.HEAVY]:
				return false
			if to_move_data[Em.move.ATK_TYPE] in [Em.atk_type.LIGHT, Em.atk_type.FIERCE]:
				return false
		Em.atk_type.SPECIAL:
			if Globals.survival_level != null and Inventory.has_quirk(master_ID, Cards.effect_ref.SPECIAL_CHAIN):
				pass
#				if is_special_move(attack_ref):
#					pass
#				else:
#					return false
			else:
#				pass
				return false
#		Em.atk_type.EX:
#			if Globals.survival_level != null and Inventory.has_quirk(master_ID, Cards.effect_ref.SPECIAL_CHAIN):
#				pass
#			else:
##				pass
#				return false
#		_:
#			return false
	
	if !chain_combo in [Em.chain_combo.NORMAL, Em.chain_combo.HEAVY, Em.chain_combo.SPECIAL, Em.chain_combo.BLOCKED]:
		if is_atk_active(): # cannot chain on active frames unless landed a hit
			return false
#		if !is_normal_attack(attack_ref): # cannot chain into non-Normals unless landed an unblocked/weakblocked hit
#			return false
	
	var root_attack_ref = UniqNPC.get_root(attack_ref)
	if root_attack_ref in chain_memory: return false # cannot chain into moves already done

	if Em.atk_attr.NO_CHAIN in from_move_data[Em.move.ATK_ATTR] or Em.atk_attr.CANNOT_CHAIN_INTO in to_move_data[Em.move.ATK_ATTR] or \
			Em.atk_attr.AUTOCHAIN in from_move_data[Em.move.ATK_ATTR]:
		return false # some moves cannnot be chained from, some moves cannot be chained into

	if Em.atk_attr.ONLY_CHAIN_ON_HIT in from_move_data[Em.move.ATK_ATTR] or Em.atk_attr.ONLY_CHAIN_INTO_ON_HIT in to_move_data[Em.move.ATK_ATTR]:
		# some attacks can only chain from on hit, some attacks can only be chained into on hit
		if !chain_combo in [Em.chain_combo.NORMAL, Em.chain_combo.HEAVY]:
			return false
		
	if is_atk_active():
#		if Em.atk_attr.AUTOCHAIN in from_move_data[Em.move.ATK_ATTR]:
#			return false
		if Em.atk_attr.LATE_CHAIN in from_move_data[Em.move.ATK_ATTR]:
			return false  # some moves cannot be chained from during active frames
		if Em.atk_attr.LATE_CHAIN_INTO in to_move_data[Em.move.ATK_ATTR]:
			return false # some moves cannot be chained into from other moves during their active frames
		
	afterimage_cancel()
	return true


func test_qc_chain_combo(attack_ref): # called during attack startup
	
	if !attack_ref in UniqNPC.STARTERS:
		return false
	
	if chain_memory.size() == 0: return true # not chaining, can QC into any valid move

#	if !chain_combo in [Em.chain_combo.NORMAL, Em.chain_combo.BLOCKED]:
#		if !is_normal_attack(attack_ref): # cannot chain into non-Normals unless landed an unblocked/weakblocked hit
#			return false

	# cannot qc jumpsquat from Active Cancel
#	if state in [Em.char_state.GRD_STARTUP, Em.char_state.AIR_STARTUP]:
#		if active_cancel:
#			return false
	
	# if chaining, cannot QC into moves with CANNOT_CHAIN_INTO
	var atk_attr = query_atk_attr(attack_ref)
	if Em.atk_attr.CANNOT_CHAIN_INTO in atk_attr:
		return false
	if Em.atk_attr.ONLY_CHAIN_INTO_ON_HIT in atk_attr:
		if !chain_combo in [Em.chain_combo.NORMAL, Em.chain_combo.HEAVY]:
			return false
	
	# if chaining, cannot QC into moves that go against chain_memory/aerial_memory/aerial_sp_memory rules
	attack_ref = UniqNPC.get_root(attack_ref)
	if attack_ref in chain_memory:
		return false # cannot quick cancel into moves already done
	if attack_ref in aerial_memory or attack_ref in aerial_sp_memory:
		return false # cannot quick cancel into aerials already done during that jump
				
	return true
	
	
func test_rekka(anim_name):
	match state: # use current
		Em.char_state.GRD_ATK_ACTIVE, Em.char_state.AIR_ATK_ACTIVE, Em.char_state.GRD_ATK_REC, Em.char_state.AIR_ATK_REC:
			if Animator.query_current([anim_name]):
				return true	
		Em.char_state.GRD_ATK_STARTUP, Em.char_state.GRD_ATK_STARTUP:
			var parent_name = anim_name.trim_suffix("Active")
			parent_name = parent_name.trim_suffix("Rec")
			var move_name = Animator.current_anim.trim_suffix("Startup")
			var move_data = query_move_data(move_name)
			if Em.move.REKKA in move_data and move_data[Em.move.REKKA] == parent_name:
				return true # this allow QCing between rekka moves
	return false
	
	
func get_atk_strength(move):
	match query_move_data(move)[Em.move.ATK_TYPE]:
		Em.atk_type.LIGHT:
			return 0
		Em.atk_type.FIERCE:
			return 1
		Em.atk_type.HEAVY:
			return 2
		Em.atk_type.SPECIAL:
			return 3
		Em.atk_type.EX:
			return 4
		Em.atk_type.SUPER:
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
	
	if recorded_hitcount >= move_data[Em.move.HITCOUNT]:
		return true
	else: return false
	
	
func is_hitcount_last_hit(in_ID, move_data):
	var recorded_hitcount = get_hitcount(in_ID)
	
	if recorded_hitcount >= move_data[Em.move.HITCOUNT] - 1:
		return true
	else: return false
	
	
func is_hitcount_first_hit(in_ID): # for multi-hit moves, only 1st hit affect Guard Gauge
	var recorded_hitcount = get_hitcount(in_ID)
	if recorded_hitcount == 0: return true
	else: return false
	
# IGNORE LIST ------------------------------------------------------------------------------------------------
	
func append_ignore_list(in_ID, ignore_time): # added if the move has Em.move.IGNORE_TIME
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
	

	
# QUERY UNIQUE CHARACTER DATA ---------------------------------------------------------------------------------------------- 
	
#func query_traits(): # may have certain conditions
#	return UniqNPC.query_traits()
	
func query_atk_attr(in_move_name = null):
	
	if in_move_name == null and !is_attacking(): return []
	
	var move_name = in_move_name
	if move_name == null:
		move_name = get_move_name()
	
	return UniqNPC.query_atk_attr(move_name)
	
	
func query_priority(in_move_name = null):
	var move_name = in_move_name
	if move_name == null:
		move_name = get_move_name()
	
	var move_data = UniqNPC.query_move_data(move_name)
	if !Em.move.ATK_TYPE in move_data: return 0 # just in case
	
	var priority: int
	match move_data[Em.move.ATK_TYPE]:
		Em.atk_type.LIGHT:
			if grounded:
				priority = Em.priority.gL
			else:
				priority = Em.priority.aL
		Em.atk_type.FIERCE:
			if grounded:
				priority = Em.priority.gF
			else:
				priority = Em.priority.aF
		Em.atk_type.HEAVY:
			if grounded:
				priority = Em.priority.gH
			else:
				priority = Em.priority.aH
		Em.atk_type.SPECIAL:
			if grounded:
				priority = Em.priority.gSp
			else:
				priority = Em.priority.aSp
		Em.atk_type.EX:
			if grounded:
				priority = Em.priority.gEX
			else:
				priority = Em.priority.aEX
		Em.atk_type.SUPER:
			priority = Em.priority.SUPER
				
	if Em.move.PRIORITY_ADD in move_data:
		return priority + move_data[Em.move.PRIORITY_ADD]
	else:
		return priority

			
	
func query_move_data(in_move_name = null):
	
	if in_move_name == null and !is_attacking(): return []
	
	var move_name = in_move_name
	if move_name == null:
		move_name = get_move_name()
	
	var move_data = UniqNPC.query_move_data(move_name)
	return move_data
	
	
# LANDING A HIT ---------------------------------------------------------------------------------------------- 
	
func landed_a_hit(hit_data): # called by main game node when landing a hit
	
	var defender
	var defender_ID2 : int  # depends if defender is player or NPC
	if Em.hit.NPC_DEFENDER_PATH in hit_data:
		defender = 	Globals.Game.get_node(hit_data[Em.hit.NPC_DEFENDER_PATH])
		defender_ID2 = defender.NPC_ID
	else:
		defender = 	Globals.Game.get_player_node(hit_data[Em.hit.DEFENDER_ID])
		defender_ID2 = defender.player_ID
		
	if defender == null:
		return # defender is deleted
	increment_hitcount(defender_ID2) # for measuring hitcount of attacks

	# ATTACKER HITSTOP ----------------------------------------------------------------------------------------------
		# hitstop is only set into HitStopTimer at end of frame
	
	if Em.move.FIXED_ATKER_HITSTOP in hit_data[Em.hit.MOVE_DATA]:
		# multi-hit special/super moves are done by having lower atker hitstop then defender hitstop, and high Em.move.HITCOUNT and ignore_time
		hitstop = hit_data[Em.hit.MOVE_DATA][Em.move.FIXED_ATKER_HITSTOP]
		
	elif hit_data[Em.hit.STUN]:
		if hitstop == null or hit_data[Em.hit.HITSTOP] > hitstop:
			hitstop = STUN_HITSTOP_ATTACKER # fixed hitstop for attacking for Break Hits
			
	elif hit_data[Em.hit.LETHAL_HIT]:
		if Globals.survival_level == null: # no screenfreeze for Survival Mode
			hitstop = null # no hitstop for attacker for lethal hit, screenfreeze already enough
		else: # follow hitstop of lethaled mob, which is lower
			hitstop = hit_data[Em.hit.HITSTOP]
		
	else:
		if hitstop == null or hit_data[Em.hit.HITSTOP] > hitstop: # need to do this to set consistent hitstop during clashes
			hitstop = hit_data[Em.hit.HITSTOP]

	
	# CANCELING ----------------------------------------------------------------------------------------------
		# only set chain_combo and dash_cancel to true if no Repeat Penalty
		
	if Em.hit.NPC_DEFENDER_PATH in hit_data:
		chain_combo = Em.chain_combo.RESET # no chain on NPC hits
		
	elif hit_data[Em.hit.DOUBLE_REPEAT] or Em.hit.SOUR_HIT in hit_data or Em.hit.MULTIHIT in hit_data or Em.hit.AUTOCHAIN in hit_data:
		chain_combo = Em.chain_combo.NO_CHAIN
	
	else:
		match hit_data[Em.hit.BLOCK_STATE]:
			
			Em.block_state.UNBLOCKED:
				match hit_data[Em.hit.MOVE_DATA][Em.move.ATK_TYPE]:
					Em.atk_type.LIGHT, Em.atk_type.FIERCE:
						chain_combo = Em.chain_combo.NORMAL
						if hit_data[Em.hit.SWEETSPOTTED] or hit_data[Em.hit.PUNISH_HIT]: # for sweetspotted/punish Normals, allow jump/dash cancel on active
							if !Em.atk_attr.NO_ACTIVE_CANCEL in hit_data[Em.hit.MOVE_DATA][Em.move.ATK_ATTR]:
								active_cancel = true
						if is_aerial() and !hit_data[Em.hit.REPEAT]:  # for unblocked aerial you regain 1 air jump
							gain_one_air_jump()
					Em.atk_type.HEAVY:
						chain_combo = Em.chain_combo.HEAVY
						if !Em.atk_attr.NO_ACTIVE_CANCEL in hit_data[Em.hit.MOVE_DATA][Em.move.ATK_ATTR]:
							active_cancel = true
						if is_aerial() and !hit_data[Em.hit.REPEAT]:  # for unblocked aerial you regain 1 air jump
							gain_one_air_jump()
					Em.atk_type.SPECIAL, Em.atk_type.EX:
						chain_combo = Em.chain_combo.SPECIAL
					Em.atk_type.SUPER:
						chain_combo = Em.chain_combo.SUPER
					
			Em.block_state.BLOCKED:
				chain_combo = Em.chain_combo.BLOCKED

			Em.block_state.PARRIED:
				chain_combo = Em.chain_combo.PARRIED
					
				
	# PUSHBACK ----------------------------------------------------------------------------------------------
		
	if Em.hit.NPC_DEFENDER_PATH in hit_data:
		pass
	elif Em.hit.MULTIHIT in hit_data or Em.hit.AUTOCHAIN in hit_data or !can_air_strafe(hit_data[Em.hit.MOVE_DATA]):
		pass # if an attack does not allow air strafing, it cannot be pushed back
	else:
		
		match hit_data[Em.hit.BLOCK_STATE]:
			Em.block_state.UNBLOCKED:
				
				if Globals.survival_level != null: # mob pushback when resisting or armoring
					if (Em.hit.RESISTED in hit_data or Em.hit.MOB_ARMORED in hit_data) and !Em.hit.MOB_BREAK in hit_data:
						var pushback_strength = RESIST_ATKER_PUSHBACK
						
						var pushback_dir_enum = Globals.split_angle(hit_data[Em.hit.ANGLE_TO_ATKER], Em.angle_split.SIX, facing)
						var pushback_dir = Globals.compass_to_angle(pushback_dir_enum)
						
						velocity.set_vector(pushback_strength, 0)
						velocity.rotate(pushback_dir)
							
				# if attacking at the corner unblocked, pushback depending on defender's Guard Gauge
				elif Em.hit.CORNERED in hit_data:
					var pushback_strength: int = CORNER_PUSHBACK
					if defender.current_guard_gauge > 0:
						pushback_strength = FMath.f_lerp(CORNER_PUSHBACK, FMath.percent(CORNER_PUSHBACK, 400), \
								defender.get_guard_gauge_percent_above())
					match Globals.split_angle(hit_data[Em.hit.ANGLE_TO_ATKER], Em.angle_split.TWO, facing):
						Em.compass.E:
							if defender.position.x < Globals.Game.left_corner:
								velocity.x += pushback_strength
						Em.compass.W:
							if defender.position.x > Globals.Game.right_corner:
								velocity.x -= pushback_strength
								
			Em.block_state.BLOCKED, Em.block_state.PARRIED:
				
				if Em.hit.SUPERARMORED in hit_data:
					continue
				
				var pushback_strength: = 0
				if hit_data[Em.hit.BLOCK_STATE] == Em.block_state.BLOCKED:
					pushback_strength = BLOCK_ATKER_PUSHBACK
				else:
					pushback_strength = PARRY_ATKER_PUSHBACK
				
				var pushback_dir_enum = Globals.split_angle(hit_data[Em.hit.ANGLE_TO_ATKER], Em.angle_split.SIX, facing) # this return an enum
				var pushback_dir = Globals.compass_to_angle(pushback_dir_enum) # pushback for weak/strong blocked hits in 6 directions only
				
				velocity.set_vector(pushback_strength, 0)  # reset momentum
				velocity.rotate(pushback_dir)

		

	# AUDIO ----------------------------------------------------------------------------------------------
		
	if (Globals.survival_level != null and !Em.hit.NO_HIT_SOUND_MOB in hit_data) or \
			(Globals.survival_level == null and hit_data[Em.hit.BLOCK_STATE] == Em.block_state.UNBLOCKED and Em.move.HIT_SOUND in hit_data[Em.hit.MOVE_DATA]):
		

		if !hit_data[Em.hit.MOVE_DATA][Em.move.HIT_SOUND] is Array:
			
			play_audio(hit_data[Em.hit.MOVE_DATA][Em.move.HIT_SOUND].ref, hit_data[Em.hit.MOVE_DATA][Em.move.HIT_SOUND].aux_data)
			
		else: # multiple sounds at once
			for sound in hit_data[Em.hit.MOVE_DATA][Em.move.HIT_SOUND]:
				play_audio(sound.ref, sound.aux_data)
				
	

# TAKING A HIT ---------------------------------------------------------------------------------------------- 	

func being_hit(hit_data): # called by main game node when taking a hit

	var attacker = Globals.Game.get_player_node(hit_data[Em.hit.ATKER_ID])
	
	var attacker_or_entity = attacker # cleaner code
	if Em.hit.ENTITY_PATH in hit_data:
		attacker_or_entity = get_node(hit_data[Em.hit.ENTITY_PATH])
	elif Em.hit.NPC_PATH in hit_data:
		attacker_or_entity = get_node(hit_data[Em.hit.NPC_PATH])
		
	if attacker_or_entity == null:
		hit_data[Em.hit.CANCELLED] = true
		return # attacked by something that is already deleted, return

	hit_data[Em.hit.ATKER] = attacker # for other functions
	hit_data[Em.hit.ATKER_OR_ENTITY] = attacker_or_entity
	hit_data[Em.hit.DEFENDER] = self # for hit_reactions
		
	
	$HitStopTimer.stop() # cancel pre-existing hitstop
	
	# get direction to attacker
	var vec_to_attacker: Vector2 = attacker_or_entity.position - position
	if vec_to_attacker.x == 0: # rare case of attacker directly on defender
		vec_to_attacker.x = -attacker_or_entity.facing
	var dir_to_attacker := int(sign(vec_to_attacker.x)) # for setting facing on defender
		
	var attacker_vec := FVector.new()
	attacker_vec.set_from_vec(vec_to_attacker)
	
	hit_data[Em.hit.ANGLE_TO_ATKER] = attacker_vec.angle()
	hit_data[Em.hit.LETHAL_HIT] = false
	hit_data[Em.hit.PUNISH_HIT] = false
	hit_data[Em.hit.STUN] = false
	hit_data[Em.hit.CRUSH] = false
	hit_data[Em.hit.BLOCK_STATE] = Em.block_state.UNBLOCKED
	hit_data[Em.hit.REPEAT] = false
	hit_data[Em.hit.DOUBLE_REPEAT] = false

	
	if Em.hit.ENTITY_PATH in hit_data and Em.move.PROJ_LVL in hit_data[Em.hit.MOVE_DATA] and hit_data[Em.hit.MOVE_DATA][Em.move.PROJ_LVL] < 3:
		hit_data[Em.hit.NON_STRONG_PROJ] = true
		
	if hit_data[Em.hit.MOVE_DATA][Em.move.ATK_TYPE] in [Em.atk_type.LIGHT, Em.atk_type.FIERCE] or Em.hit.NON_STRONG_PROJ in hit_data:
		hit_data[Em.hit.WEAKARMORABLE] = true
		
		
	if is_attacking():	
		hit_data[Em.hit.DEFENDER_ATTR] = query_atk_attr()
	else:
		hit_data[Em.hit.DEFENDER_ATTR] = []
		
		
	# CHECK BLOCK STATE ----------------------------------------------------------------------------------------------

	var crossed_up: bool = check_if_crossed_up(hit_data)

	if !Em.atk_attr.UNBLOCKABLE in hit_data[Em.hit.MOVE_DATA][Em.move.ATK_ATTR]:
		match new_state:
			
			# SUPERARMOR --------------------------------------------------------------------------------------------------
			
			# WEAK block_state
			# attacker can chain combo normally after hitting an armored defender
			
			Em.char_state.GRD_ATK_STARTUP, Em.char_state.AIR_ATK_STARTUP: # can sweetspot superarmor
				var defender_attr = hit_data[Em.hit.DEFENDER_ATTR]
				if crossed_up and !Em.atk_attr.BI_DIR_ARMOR in defender_attr:
					continue # armored moves only armor from front unless has BI_DIR_ARMOR
				if Em.atk_attr.SUPERARMOR_STARTUP in defender_attr or \
						(Em.atk_attr.WEAKARMOR_STARTUP in defender_attr and Em.hit.WEAKARMORABLE in hit_data):
					hit_data[Em.hit.BLOCK_STATE] = Em.block_state.BLOCKED
					hit_data[Em.hit.SUPERARMORED] = true
					
			Em.char_state.GRD_ATK_ACTIVE, Em.char_state.AIR_ATK_ACTIVE:
				var defender_attr = hit_data[Em.hit.DEFENDER_ATTR]
				if crossed_up and !Em.atk_attr.BI_DIR_ARMOR in defender_attr:
					continue # armored moves only armor from front unless has BI_DIR_ARMOR
				if Em.atk_attr.SUPERARMOR_ACTIVE in defender_attr or \
						(Em.atk_attr.WEAKARMOR_ACTIVE in defender_attr and Em.hit.WEAKARMORABLE in hit_data) or \
						(Em.atk_attr.PROJ_ARMOR_ACTIVE in defender_attr and Em.hit.ENTITY_PATH in hit_data):
					hit_data[Em.hit.BLOCK_STATE] = Em.block_state.BLOCKED
					hit_data[Em.hit.SUPERARMORED] = true
						
			Em.char_state.AIR_STARTUP:
				if Animator.query_to_play(["SDashTransit"]) and Em.hit.NON_STRONG_PROJ in hit_data:
					hit_data[Em.hit.BLOCK_STATE] = Em.block_state.BLOCKED
					hit_data[Em.hit.SUPERARMORED] = true
					hit_data[Em.hit.SDASH_ARMORED] = true
			Em.char_state.AIR_REC:
				 # air superdash has projectile superarmor against non-strong projectiles
				if Animator.query_to_play(["SDash"]) and Em.hit.NON_STRONG_PROJ in hit_data:
					hit_data[Em.hit.BLOCK_STATE] = Em.block_state.BLOCKED
					hit_data[Em.hit.SUPERARMORED] = true
					hit_data[Em.hit.SDASH_ARMORED] = true
				
	
		# BLOCKING --------------------------------------------------------------------------------------------------
		
		match state:
			Em.char_state.GRD_BLOCK, Em.char_state.AIR_BLOCK:
				match hit_data[Em.hit.MOVE_DATA][Em.move.ATK_TYPE]:
					Em.atk_type.ENTITY, Em.atk_type.EX_ENTITY, Em.atk_type.SUPER_ENTITY:
						hit_data[Em.hit.BLOCK_STATE] = Em.block_state.BLOCKED
					_:
						if crossed_up:
							hit_data[Em.hit.BLOCK_STATE] = Em.block_state.UNBLOCKED
						else:
							hit_data[Em.hit.BLOCK_STATE] = Em.block_state.BLOCKED
	
	
	# ZEROTH REACTION (before damage) ---------------------------------------------------------------------------------
	
	# unique reactions
	if Em.hit.ENTITY_PATH in hit_data:
		if attacker_or_entity.UniqEntity.has_method("landed_a_hit0"):
			attacker_or_entity.UniqEntity.landed_a_hit0(hit_data) # reaction, can change hit_data from there
	elif Em.hit.NPC_PATH in hit_data:
		if attacker_or_entity.UniqNPC.has_method("landed_a_hit0"):
			attacker_or_entity.UniqNPC.landed_a_hit0(hit_data) # reaction, can change hit_data from there
	elif attacker != null and attacker.UniqNPC.has_method("landed_a_hit0"):
		attacker.UniqNPC.landed_a_hit0(hit_data) # reaction, can change hit_data from there
	
	if UniqNPC.has_method("being_hit0"):	
		UniqNPC.being_hit0(hit_data) # reaction, can change hit_data from there
		# good for counter moves
		
	if Em.hit.CANCELLED in hit_data:
		return
		
	# FIRST REACTION (after damage) ---------------------------------------------------------------------------------
	
	# unique reactions
	if Em.hit.ENTITY_PATH in hit_data:
		if attacker_or_entity.UniqEntity.has_method("landed_a_hit"):
			attacker_or_entity.UniqEntity.landed_a_hit(hit_data) # reaction, can change hit_data from there
	elif Em.hit.NPC_PATH in hit_data:
		if attacker_or_entity.UniqNPC.has_method("landed_a_hit"):
			attacker_or_entity.UniqNPC.landed_a_hit(hit_data) # reaction, can change hit_data from there
	elif attacker != null and attacker.UniqNPC.has_method("landed_a_hit"):
		attacker.UniqNPC.landed_a_hit(hit_data) # reaction, can change hit_data from there
		# good for moves that have special effects on Sweetspot/Punish Hits
	
	if UniqNPC.has_method("being_hit"):	
		UniqNPC.being_hit(hit_data) # reaction, can change hit_data from there
		
	# ---------------------------------------------------------------------------------
	
	if Em.move.SEQ in hit_data[Em.hit.MOVE_DATA]:
		return # cannot grab NPCs

	# knockback
	var knockback_dir: int = calculate_knockback_dir(hit_data)
	hit_data[Em.hit.KB_ANGLE] = knockback_dir
	if hit_data[Em.hit.BLOCK_STATE] == Em.block_state.BLOCKED:
		hit_data[Em.hit.KB] = NPC_BLOCK_KB_STR
	else:
		hit_data[Em.hit.KB] = NPC_KB_STR

		
	# SPECIAL HIT EFFECTS ---------------------------------------------------------------------------------
	
	# for moves that automatically chain into more moves, will not cause lethal or break hits, will have fixed_hitstop and no KB boost


	if hit_data[Em.hit.BLOCK_STATE] != Em.block_state.UNBLOCKED:
		if Em.hit.SUPERARMORED in hit_data:
			modulate_play("armor_flash")
			play_audio("block3", {"vol" : -15})
		else:
			modulate_play("mob_armor_flash")
			play_audio("bling2", {"vol" : -5, "bus" : "PitchDown2"})
	else:
		modulate_play("punish_sweet_flash")
		play_audio("impact29", {"vol" : -18, "bus" : "LowPass"})
		
	$VarJumpTimer.stop()
	
	# HITSTUN -------------------------------------------------------------------------------------------
	
	if hit_data[Em.hit.BLOCK_STATE] == Em.block_state.UNBLOCKED:
		launchstun_rotate = 0 # used to calculation sprite rotation during launched state
	
	# HITSTOP ---------------------------------------------------------------------------------------------------
	
	if hit_data[Em.hit.BLOCK_STATE] == Em.block_state.BLOCKED:
		hitstop = NPC_BLOCK_HITSTOP
	else:
		hitstop = NPC_HITSTOP # fixed NPC hitstop
		
	hit_data[Em.hit.HITSTOP] = 0 # no hitstop for attacker
		
	if hitstop > 0: # will freeze in place if colliding 1 frame after hitstop, more if has ignore_time, to make multi-hit projectiles more consistent
		if Em.hit.MULTIHIT in hit_data and Em.move.IGNORE_TIME in hit_data[Em.hit.MOVE_DATA]:
			$NoCollideTimer.time = hit_data[Em.hit.MOVE_DATA][Em.move.IGNORE_TIME]
		else:
			$NoCollideTimer.time = 1
	
#	# SECOND REACTION (after knockback) ---------------------------------------------------------------------------------

	if Em.hit.ENTITY_PATH in hit_data:
		if attacker_or_entity.UniqEntity.has_method("landed_a_hit2"):
			attacker_or_entity.UniqEntity.landed_a_hit2(hit_data) # reaction, can change hit_data from there
	elif Em.hit.NPC_PATH in hit_data:
		if attacker_or_entity.UniqNPC.has_method("landed_a_hit2"):
			attacker_or_entity.UniqNPC.landed_a_hit2(hit_data) # reaction, can change hit_data from there
	elif attacker != null and attacker.UniqNPC.has_method("landed_a_hit2"):
		attacker.UniqNPC.landed_a_hit2(hit_data) # reaction, can change hit_data from there
	
	if UniqNPC.has_method("being_hit2"):	
		UniqNPC.being_hit2(hit_data) # reaction, can change hit_data from there
	
	# HITSPARK ---------------------------------------------------------------------------------------------------
	
	if hit_data[Em.hit.BLOCK_STATE] == Em.block_state.UNBLOCKED:
		generate_hitspark(hit_data)
	else:
		generate_blockspark(hit_data)
		
	# ---------------------------------------------------------------------------------------------------

	if hit_data[Em.hit.BLOCK_STATE] != Em.block_state.UNBLOCKED:
		if Em.hit.SUPERARMORED in hit_data:
			if grounded:
				var knock_dir := 0
				var segment = Globals.split_angle(hit_data[Em.hit.KB_ANGLE], Em.angle_split.FOUR, hit_data[Em.hit.ATK_FACING])
				match segment:
					Em.compass.E:
						knock_dir = 1
					Em.compass.W:
						knock_dir = -1
				if knock_dir != 0:
					move_amount(Vector2(knock_dir * 7, 0), true)
					set_true_position()
			return
		else:
			if !Em.hit.ENTITY_PATH in hit_data:
				face(dir_to_attacker) # blocking non-entities always turn towards attacker only

			else: # blocking entities turn against knockback_dir
				var segment = Globals.split_angle(hit_data[Em.hit.KB_ANGLE], Em.angle_split.TWO, -dir_to_attacker)
				match segment:
					Em.compass.E:
						face(-1) # face other way
					Em.compass.W:
						face(1)
						
	else:
		var segment = Globals.split_angle(hit_data[Em.hit.KB_ANGLE], Em.angle_split.EIGHT, dir_to_attacker)
		match segment:
			Em.compass.N:
				face(dir_to_attacker) # turn towards attacker
				if facing == 1:
					launch_starting_rot = PI/2
				else:
					launch_starting_rot = 3*PI/2
			Em.compass.NE:
				face(-1)
				launch_starting_rot = 7*PI/4
			Em.compass.E:
				face(-1)
				launch_starting_rot = 0
			Em.compass.SE:
				face(-1)
				launch_starting_rot = 9*PI/4
			Em.compass.S:
				face(dir_to_attacker) # turn towards attacker
				if facing == -1:
					launch_starting_rot = PI/2
				else:
					launch_starting_rot = 3*PI/2
			Em.compass.SW:
				face(1)
				launch_starting_rot = 7*PI/4
			Em.compass.W:
				face(1)
				launch_starting_rot = 0.0
			Em.compass.NW:
				face(1)
				launch_starting_rot = PI/4
		animate("LaunchStop")
	
	velocity.set_vector(hit_data[Em.hit.KB], 0)  # reset momentum
	velocity.rotate(hit_data[Em.hit.KB_ANGLE])
		
	if hit_data[Em.hit.BLOCK_STATE] != Em.block_state.UNBLOCKED and grounded:
		velocity.y = 0 # set to horizontal pushback on blocking defender

		
# HIT CALCULATION ---------------------------------------------------------------------------------------------------
	
func calculate_knockback_dir(hit_data) -> int:
	

	var knockback_dir := 0
	var knockback_type = hit_data[Em.hit.MOVE_DATA][Em.move.KB_TYPE]
	
	# for certain multi-hit attacks and autochain
	if Em.hit.MULTIHIT in hit_data or Em.hit.AUTOCHAIN in hit_data:
		
		if Em.atk_attr.DRAG_KB in hit_data[Em.hit.MOVE_DATA][Em.move.ATK_ATTR]: # can be drag KB till the last hit
			return hit_data[Em.hit.ATKER_OR_ENTITY].velocity.angle()
			
		elif Em.hit.VACPOINT in hit_data: # or vacuum towards VacPoint
			var vac_vector := FVector.new()
			vac_vector.set_from_vec(hit_data[Em.hit.VACPOINT] - hit_data[Em.hit.HIT_CENTER])
			return vac_vector.angle()
			
		elif Em.move.FIXED_KB_ANGLE_MULTI in hit_data[Em.hit.MOVE_DATA]: # or fixed angle till the last hit
			knockback_dir = hit_data[Em.hit.MOVE_DATA][Em.move.FIXED_KB_ANGLE_MULTI]
			if hit_data[Em.hit.ATK_FACING] < 0:
				knockback_dir = Globals.mirror_angle(knockback_dir) # mirror knockback angle horizontally if facing other way
			return knockback_dir
			
				
	var KBOrigin = null
	if Em.hit.KBORIGIN in hit_data:
		KBOrigin = hit_data[Em.hit.KBORIGIN] # becomes a Vector2
		
	var ref_vector := FVector.new() # vector from KBOrigin to hit_center
	if KBOrigin:
		ref_vector.set_from_vec(hit_data[Em.hit.HIT_CENTER] - KBOrigin)
	else:
		ref_vector.set_from_vec(hit_data[Em.hit.HIT_CENTER] - hit_data[Em.hit.ATKER_OR_ENTITY].position)
		
	if ref_vector.x <= FMath.S and ref_vector.x >= -FMath.S:
		ref_vector.x = 0 # reduce rounding errors when calculating hit center
	
	match knockback_type:
		Em.knockback_type.FIXED, Em.knockback_type.MIRRORED:

			if hit_data[Em.hit.ATK_FACING] > 0:
				knockback_dir = posmod(hit_data[Em.hit.MOVE_DATA][Em.move.KB_ANGLE], 360)
			else:
				knockback_dir = Globals.mirror_angle(hit_data[Em.hit.MOVE_DATA][Em.move.KB_ANGLE]) # mirror knockback angle horizontally if facing other way
				
			if knockback_type == Em.knockback_type.MIRRORED: # mirror it again if wrong way
#				if KBOrigin:
				var segment = Globals.split_angle(knockback_dir, Em.angle_split.TWO, hit_data[Em.hit.ATK_FACING])
				match segment:
					Em.compass.E:
						if ref_vector.x < 0:
							knockback_dir = Globals.mirror_angle(knockback_dir)
					Em.compass.W:
						if ref_vector.x > 0:
							knockback_dir = Globals.mirror_angle(knockback_dir)
#				else: print("Error: No KBOrigin found for knockback_type.MIRRORED")
				
		Em.knockback_type.VELOCITY: # in direction of attacker's velocity
			if hit_data[Em.hit.ATKER_OR_ENTITY].velocity.x == 0 and hit_data[Em.hit.ATKER_OR_ENTITY].velocity.y == 0:
				knockback_dir = -90
			else:
				knockback_dir = hit_data[Em.hit.ATKER_OR_ENTITY].velocity.angle()
				
		Em.knockback_type.RADIAL:
#			if KBOrigin:
			knockback_dir = ref_vector.angle(hit_data[Em.hit.ATK_FACING])
			if hit_data[Em.hit.ATK_FACING] > 0:
				knockback_dir += hit_data[Em.hit.MOVE_DATA][Em.move.KB_ANGLE] # KB_angle can rotate radial knockback some more
			else:
				knockback_dir -= hit_data[Em.hit.MOVE_DATA][Em.move.KB_ANGLE]
			knockback_dir = posmod(knockback_dir, 360)
#			else: print("Error: No KBOrigin found for knockback_type.RADIAL")
			
	# for grounded blocking defender, if the hit is towards left/right instead of up/down, level it
	if grounded and hit_data[Em.hit.BLOCK_STATE] != Em.block_state.UNBLOCKED:
		var segment = Globals.split_angle(knockback_dir, Em.angle_split.FOUR, hit_data[Em.hit.ATK_FACING])
		match segment:
			Em.compass.E:
				knockback_dir = 0
			Em.compass.W:
				knockback_dir = 180
				
	return knockback_dir

	
	
func check_if_crossed_up(hit_data):
	
	if Em.atk_attr.NO_CROSSUP in hit_data[Em.hit.MOVE_DATA][Em.move.ATK_ATTR]:
		return false
	
	if Globals.survival_level != null and Inventory.has_quirk(master_ID, Cards.effect_ref.NO_CROSSUP):
		return false
		
	var attacker = hit_data[Em.hit.ATKER_OR_ENTITY]
		
	if attacker.has_method("query_status_effect") and \
			(attacker.query_status_effect(Em.status_effect.NO_CROSSUP) or attacker.query_status_effect(Em.status_effect.SCANNED)):
		return false
	
# warning-ignore:narrowing_conversion
	var x_dist: int = abs(attacker.position.x - position.x)
	if x_dist <= CROSS_UP_MIN_DIST: return false
	
	var segment = Globals.split_angle(hit_data[Em.hit.ANGLE_TO_ATKER], Em.angle_split.EIGHT)
	if segment == Em.compass.N or segment == Em.compass.S:
		return false
	match segment:
		Em.compass.E, Em.compass.NE, Em.compass.SE:
			if facing == 1:
				return false
		Em.compass.W, Em.compass.NW, Em.compass.SW:
			if facing == -1:
				return false
	return true


func generate_hitspark(hit_data): # hitspark size determined by knockback power
	

	if !Em.move.HITSPARK_TYPE in hit_data[Em.hit.MOVE_DATA]:
		hit_data[Em.hit.MOVE_DATA][Em.move.HITSPARK_TYPE] = Em.hitspark_type.HIT
		if Em.hit.NPC_PATH in hit_data:
			if hit_data[Em.hit.ATKER_OR_ENTITY] != null and hit_data[Em.hit.ATKER_OR_ENTITY].has_method("get_default_hitspark_type"):
				hit_data[Em.hit.MOVE_DATA][Em.move.HITSPARK_TYPE] = hit_data[Em.hit.ATKER_OR_ENTITY].get_default_hitspark_type()
		elif hit_data[Em.hit.ATKER] != null and hit_data[Em.hit.ATKER].has_method("get_default_hitspark_type"):
			hit_data[Em.hit.MOVE_DATA][Em.move.HITSPARK_TYPE] = hit_data[Em.hit.ATKER].get_default_hitspark_type()
			
	if !Em.move.HITSPARK_PALETTE in hit_data[Em.hit.MOVE_DATA]:
		hit_data[Em.hit.MOVE_DATA][Em.move.HITSPARK_PALETTE] = "red"
		if Em.hit.NPC_PATH in hit_data:
			if hit_data[Em.hit.ATKER_OR_ENTITY] != null and hit_data[Em.hit.ATKER_OR_ENTITY].has_method("get_default_hitspark_palette"):
				hit_data[Em.hit.MOVE_DATA][Em.move.HITSPARK_PALETTE] = hit_data[Em.hit.ATKER_OR_ENTITY].get_default_hitspark_palette()
		elif hit_data[Em.hit.ATKER] != null and hit_data[Em.hit.ATKER].has_method("get_default_hitspark_palette"):
			hit_data[Em.hit.MOVE_DATA][Em.move.HITSPARK_PALETTE] = hit_data[Em.hit.ATKER].get_default_hitspark_palette()
			
		
	var hitspark = ""
	match hit_data[Em.hit.MOVE_DATA][Em.move.HITSPARK_TYPE]:
		Em.hitspark_type.HIT:
			hitspark = "HitsparkC"
		Em.hitspark_type.SLASH:
			hitspark = "SlashsparkC"

		Em.hitspark_type.CUSTOM:
			# WIP
			pass
					
	if hitspark != "":
		var rot_rad: float
		if hit_data[Em.hit.MOVE_DATA][Em.move.HITSPARK_TYPE] != Em.hitspark_type.SLASH:
			rot_rad = hit_data[Em.hit.KB_ANGLE] / 360.0 * (2 * PI) + PI # visuals only
		else: # slash hitspark randomize angle a bit
			var rand_degree := 0
			if Em.hit.MULTIHIT in hit_data or Em.hit.AUTOCHAIN in hit_data:
				rand_degree = Globals.Game.rng_generate(91) * Globals.Game.rng_facing()
			else:
				rand_degree = Globals.Game.rng_generate(46) * Globals.Game.rng_facing()
			rot_rad = (hit_data[Em.hit.KB_ANGLE] + rand_degree) / 360.0 * (2 * PI) + PI # visuals only
		if Em.hit.PULL in hit_data: rot_rad += PI # flip if pulling
		Globals.Game.spawn_SFX(hitspark, hitspark, hit_data[Em.hit.HIT_CENTER], {"rot": rot_rad, "v_mirror":Globals.Game.rng_bool()}, \
				hit_data[Em.hit.MOVE_DATA][Em.move.HITSPARK_PALETTE])
		
func get_default_hitspark_type():
	return get_stat("DEFAULT_HITSPARK_TYPE")
func get_default_hitspark_palette():
	if palette_ref in UniqNPC.PALETTE_TO_HITSPARK_PALETTE:
		return UniqNPC.PALETTE_TO_HITSPARK_PALETTE[palette_ref]
	return get_stat("DEFAULT_HITSPARK_PALETTE")
	
func generate_blockspark(hit_data):
	
	var blockspark
	if Em.hit.SUPERARMORED in hit_data:
		blockspark = "Superarmorspark"
	else:
		blockspark = "MobArmorspark"
		
	Globals.Game.spawn_SFX(blockspark, "Blocksparks", hit_data[Em.hit.HIT_CENTER], {"rot" : deg2rad(hit_data[Em.hit.ANGLE_TO_ATKER])})
	
	
# AUTO SEQUENCES ---------------------------------------------------------------------------------------------------

func simulate_sequence(): # cut into this during simulate2() during sequences
	
	test0()
	
	var Partner = get_seq_partner()
	if Partner == null and state in [Em.char_state.SEQ_TARGET, Em.char_state.SEQ_USER]:
		animate("Idle")
		return
	
	match state:
		Em.char_state.SEQ_TARGET: # being the target of an opponent's sequence will be moved around by them
			if Partner.state != Em.char_state.SEQ_USER:
				animate("Idle") # auto release if not released proberly, just in case
				return
		
		Em.char_state.SEQ_USER: # using a sequence, will follow the steps in UniqNPC.SEQUENCES[sequence_name]
			UniqNPC.simulate_sequence()
		
		_:
			pass
		
		
	if abs(velocity.x) < 5 * FMath.S:
		velocity.x = 0
	if abs(velocity.y) < 5 * FMath.S:
		velocity.y = 0
	
	velocity_previous_frame.x = velocity.x
	velocity_previous_frame.y = velocity.y
	
	var results = move(UniqNPC.sequence_ledgestop()) # [landing_check, collision_check, ledgedrop_check]
#	velocity.x = results[0].x
#	velocity.y = results[0].y
	
	if new_state == Em.char_state.SEQ_USER:
		UniqNPC.simulate_sequence_after() # move grabbed target after grabber has moved
	
	if results[0]: UniqNPC.end_sequence_step("ground") # hit the ground, no effect if simulate_sequence_after() broke grab and animated "Idle"
	if results[2]: UniqNPC.end_sequence_step("ledge") # stopped by ledge
	
	
		
func landed_a_sequence(hit_data):
	
	if new_state in [Em.char_state.SEQ_USER]:
		return # no sequencing if you are already grabbing another player

	var defender = Globals.Game.get_player_node(hit_data[Em.hit.DEFENDER_ID])
	
	if defender == null or defender.new_state in [Em.char_state.SEQ_TARGET]:
		return # no sequencing players that are already being grabbed
		
	if hit_data[Em.hit.DOUBLE_REPEAT] or Em.hit.SINGLE_REPEAT in hit_data: return
		
	if defender.new_state in [Em.char_state.SEQ_USER]:
		return
	
	seq_partner_ID = defender.player_ID
	defender.seq_partner_ID = NPC_ID
	defender.seq_partner_type = Em.seq_partner.NPC
	
	animate(hit_data[Em.hit.MOVE_DATA][Em.move.SEQ])
	defender.animate("aSeqFlinchAFreeze") # first pose to set defender's state

	chain_combo = Em.chain_combo.NO_CHAIN
	
	chain_memory.append(UniqNPC.get_root(hit_data[Em.hit.MOVE_NAME])) # add move to chain memory, have to do it here for sequences
				
	

# ANIMATION AND AUDIO PROCESSING ---------------------------------------------------------------------------------------------------
	
# universal actions
func _on_SpritePlayer_anim_finished(anim_name):
	
	if is_atk_startup():
		reset_cancels()
	
	match anim_name:
		"RunTransit":
			animate("Run")
		"HardLanding", "SoftLanding", "Brake":
			animate("Idle")
			
		"JumpTransit":
			animate("JumpTransit2")
		"JumpTransit2":
			animate("JumpTransit3")
		"aJumpTransit":
			animate("aJumpTransit2")
		"WallJumpTransit":
			animate("WallJumpTransit2")
		"aJumpTransit2", "WallJumpTransit2":
			animate("aJumpTransit3")
		"JumpTransit3", "aJumpTransit3":
			animate("Jump")
		"FallTransit":
			animate("Fall")
		"FastFallTransit":
			if !button_jump in input_state.pressed and is_button_tapped_in_last_X_frames(button_jump, 1) and \
					check_snap_up(): # do this here instead of _on_SpritePlayer_anim_started()
				snap_up()
				animate("SoftLanding")
			else:
				animate("FastFall")
				
		"DodgeTransit":
			animate("Dodge")
		"Dodge":
			animate("DodgeRec")
		"DodgeRec":
			animate("Fall")
			
		"FlinchAStop":
			animate("FlinchA")
		"FlinchBStop":
			animate("FlinchB")
		"FlinchAReturn", "FlinchBReturn":
			animate("Idle")
			
		"aFlinchAStop":
			animate("aFlinchA")
		"aFlinchBStop":
			animate("aFlinchB")
		"aFlinchAReturn", "aFlinchBReturn":
			animate("FallTransit")
			
		"LaunchStop":
			animate("LaunchTransit")
		"LaunchTransit":
			animate("Launch")
			
		"BlockStartup", "TBlockStartup":
			play_audio("bling4", {"vol" : -10, "bus" : "PitchUp2"})
			animate("Block")
		"BlockRec":
			animate("Idle")
		"BlockCRec":
			animate("Idle")
		"aBlockStartup", "aTBlockStartup":
			play_audio("bling4", {"vol" : -10, "bus" : "PitchUp2"})
			animate("aBlock")
		"aBlockRec":
			animate("FallTransit")
		"aBlockCRec":
			animate("FallTransit")
		"BlockLanding":
			animate("Block")
			
		"SDashTransit":
			animate("SDash")
		"SDash":
			if !grounded:
				animate("aDashBrake")
			else:
				animate("DashBrake")

	UniqNPC._on_SpritePlayer_anim_finished(anim_name)

	# do this at end of _on_SpritePlayer_anim_finished() as well
	if new_state in [Em.char_state.GRD_C_REC, Em.char_state.AIR_C_REC, \
			Em.char_state.GRD_REC, Em.char_state.AIR_REC] and !Animator.query_to_play(["SoftLanding"]):
		from_move_rec = true
		

func _on_SpritePlayer_anim_started(anim_name): # DO NOT START ANY ANIMATIONS HERE!
	
	state = state_detect(anim_name) # update state

	
	if new_state in [Em.char_state.GRD_C_REC, Em.char_state.AIR_C_REC, \
			Em.char_state.GRD_D_REC, Em.char_state.AIR_D_REC] and !Animator.query_to_play(["SoftLanding"]):
		from_move_rec = true
	elif !is_atk_startup():
		from_move_rec = false
	
	if is_atk_startup():
		var move_name = anim_name.trim_suffix("Startup")
				
		if dir != 0: # impulse
			match state:
				Em.char_state.GRD_ATK_STARTUP, Em.char_state.AIR_ATK_STARTUP:
					if state == Em.char_state.AIR_ATK_STARTUP and (!grounded or check_fallthrough()): continue
					
					if !impulse_used and move_name in UniqNPC.STARTERS and !Em.atk_attr.NO_IMPULSE in query_atk_attr(move_name):
						impulse_used = true
						var impulse: int = dir * FMath.percent(get_stat("SPEED"), get_stat("IMPULSE_MOD"))
#						if instant_dir != 0: # perfect impulse
#							impulse = FMath.percent(impulse, PERFECT_IMPULSE_MOD)
	#					if move_name in UniqNPC.MOVE_DATABASE and "impulse_mod" in UniqNPC.MOVE_DATABASE[move_name]:
	#						var impulse_mod: int = UniqNPC.query_move_data(move_name).impulse_mod
	#						impulse = FMath.percent(impulse, impulse_mod)
						velocity.x = int(clamp(velocity.x + impulse, -abs(impulse), abs(impulse)))
						Globals.Game.spawn_SFX("GroundDashDust", "DustClouds", get_feet_pos(), {"facing":dir, "grounded":true})
						
				Em.char_state.AIR_ATK_STARTUP:
					if strafe_lock_dir == 0 and move_name in UniqNPC.STARTERS:
						strafe_lock_dir = dir
						
		var atk_attr = query_atk_attr(move_name)
		if Em.atk_attr.WEAKARMOR_STARTUP in atk_attr or Em.atk_attr.SUPERARMOR_STARTUP in atk_attr:
			modulate_play("armor_flash")
						
	else:
		# Block Impulse
		if dir != 0 and !impulse_used and new_state == Em.char_state.GRD_BLOCK and anim_name == "BlockStartup":
			impulse_used = true
			var impulse: int = dir * FMath.percent(get_stat("SPEED"), get_stat("IMPULSE_MOD"))
			impulse = FMath.percent(impulse, 70) # reduce impulse for Block Impulse
#			if instant_dir != 0: # perfect impulse
#				impulse = FMath.percent(impulse, PERFECT_IMPULSE_MOD)
			velocity.x = int(clamp(velocity.x + impulse, -abs(impulse), abs(impulse)))
			Globals.Game.spawn_SFX("GroundDashDust", "DustClouds", get_feet_pos(), {"facing":dir, "grounded":true})
			
		elif new_state in [Em.char_state.GRD_D_REC, Em.char_state.AIR_D_REC] and !has_trait(Em.trait.DASH_IMPULSE):
			impulse_used = true  # no impulse if cancelling from dash
		else:
			impulse_used = false
			
		quick_turn_used = false
		strafe_lock_dir = 0
		
		if is_atk_active():
			var move_name = UniqNPC.get_root(anim_name.trim_suffix("Active"))
			
			chain_memory.append(move_name) # add move to chain memory
			
			if !grounded: # add move to aerial memory
				aerial_memory.append(move_name)
				if is_special_move(move_name) and !Em.atk_attr.AIR_REPEAT in query_atk_attr(move_name):
					aerial_sp_memory.append(move_name)
	
	anim_friction_mod = 100
	anim_gravity_mod = 100
	velocity_limiter = {"x" : null, "up" : null, "down" : null, "x_slow" : null, "y_slow" : null}
	if Animator.query_current(["LaunchStop"]):
		sprite.rotation = launch_starting_rot
	else:
		sprite.rotation = 0
	
	match anim_name:
		
		"JumpTransit2":
			if dir != 0:
				velocity.y = -FMath.percent(get_stat("JUMP_SPEED"), get_stat("DIR_JUMP_HEIGHT_MOD"))
				velocity.x += dir * FMath.percent(get_stat("SPEED"), get_stat("HORIZ_JUMP_BOOST_MOD"))
				if velocity.x > get_stat("SPEED"):
					velocity.x = FMath.f_lerp(velocity.x, get_stat("SPEED"), 70)
				elif velocity.x < -get_stat("SPEED"):
					velocity.x = FMath.f_lerp(velocity.x, -get_stat("SPEED"), 70)
				velocity.x = FMath.percent(velocity.x, get_stat("HORIZ_JUMP_SPEED_MOD"))
			else:
				velocity.y = -get_stat("JUMP_SPEED")
			$VarJumpTimer.time = get_stat("VAR_JUMP_TIME")
			Globals.Game.spawn_SFX("JumpDust", "DustClouds", get_feet_pos(), {"facing":facing, "grounded":true})
			
		"aJumpTransit2":
			aerial_memory = []
			if !check_wall_jump():
				air_jump -= 1
				# air jump directional boost
				if dir != 0:
					if dir * velocity.x < 0: # air jump change direction (no change in velocity if same direction)
						velocity.x += dir * FMath.percent(get_stat("SPEED"), get_stat("REVERSE_AIR_JUMP_MOD"))
					else:
						if velocity.x > get_stat("SPEED"):
							velocity.x = FMath.f_lerp(velocity.x, get_stat("SPEED"), 50)
						elif velocity.x < -get_stat("SPEED"):
							velocity.x = FMath.f_lerp(velocity.x, -get_stat("SPEED"), 50)
						velocity.x = FMath.percent(velocity.x, get_stat("AIR_HORIZ_JUMP_SPEED_MOD"))
					velocity.y = -FMath.percent(get_modded_jump_speed(), get_stat("AIR_JUMP_HEIGHT_MOD"))
					velocity.y = FMath.percent(velocity.y, get_stat("DIR_JUMP_HEIGHT_MOD"))
				else: # neutral air jump
					velocity.x = FMath.percent(velocity.x, 70)
					velocity.y = -FMath.percent(get_modded_jump_speed(), get_stat("AIR_JUMP_HEIGHT_MOD"))
				$VarJumpTimer.time = get_stat("VAR_JUMP_TIME")
				Globals.Game.spawn_SFX("AirJumpDust", "DustClouds", get_feet_pos(), {})
					
			else: # if next to wall when starting an air jump, do wall jump instead
				if wall_jump_dir != 0:
					velocity.x = wall_jump_dir * FMath.percent(get_stat("SPEED"), get_stat("WALL_AIR_JUMP_HORIZ_MOD"))
				else:
					velocity.x = 0 # walls on both side
					wall_jump_dir = facing # for the dash dust effect
#				velocity.y = -get_stat("JUMP_SPEED")
				velocity.y = -FMath.percent(get_modded_jump_speed(), get_stat("WALL_AIR_JUMP_VERT_MOD"))
				$VarJumpTimer.time = get_stat("VAR_JUMP_TIME")
				var wall_point = Detection.wall_finder(position - (wall_jump_dir * Vector2($PlayerCollisionBox.rect_size.x / 2, 0)), \
					-wall_jump_dir)
				if wall_point != null:
					Globals.Game.spawn_SFX("GroundDashDust", "DustClouds", wall_point, {"facing":wall_jump_dir, "rot":PI/2})
#				reset_jumps_except_walljumps()
		"WallJumpTransit2":
			aerial_memory = []
			if wall_jump_dir != 0:
				velocity.x = wall_jump_dir * FMath.percent(get_stat("SPEED"), get_stat("WALL_AIR_JUMP_HORIZ_MOD"))
			else:
				velocity.x = 0 # walls on both side
				wall_jump_dir = facing # for the dash dust effect
			velocity.y = -FMath.percent(get_modded_jump_speed(), get_stat("WALL_AIR_JUMP_VERT_MOD"))
			$VarJumpTimer.time = get_stat("VAR_JUMP_TIME")
			var wall_point = Detection.wall_finder(position - (wall_jump_dir * Vector2($PlayerCollisionBox.rect_size.x / 2, 0)), \
				-wall_jump_dir)
			if wall_point != null:
				Globals.Game.spawn_SFX("GroundDashDust", "DustClouds", wall_point, {"facing":wall_jump_dir, "rot":PI/2})
#			reset_jumps_except_walljumps()
		"HardLanding":
			Globals.Game.spawn_SFX("LandDust", "DustClouds", get_feet_pos(), {"grounded":true})
		"SoftLanding":
			Globals.Game.spawn_SFX("LandDust", "DustClouds", get_feet_pos(), {"grounded":true})
			
		"DodgeTransit":
			aerial_memory = []
			anim_gravity_mod = 0
			anim_friction_mod = 0
			velocity_limiter.x_slow = 10
			velocity_limiter.y_slow = 10
		"Dodge":
			face_opponent()
			var tech_angle: int
				
			if !grounded or soft_grounded:
				tech_angle = Globals.dir_to_angle(dir, v_dir, facing)
			else:
				if v_dir == -1:
					tech_angle = Globals.dir_to_angle(dir, -1, facing)
				else:
					tech_angle = Globals.dir_to_angle(dir, 0, facing)
						
			velocity.set_vector(get_stat("DODGE_SPEED"), 0)
			velocity.rotate(tech_angle)
			anim_gravity_mod = 0
			anim_friction_mod = 0
			velocity_limiter.x_slow = 12
			velocity_limiter.y_slow = 12
			afterimage_timer = 1 # sync afterimage trail
			modulate_play("dodge_flash")
		"DodgeRec", "DodgeCRec":
			anim_gravity_mod = 0
			anim_friction_mod = 0
			velocity_limiter.x_slow = 12
			velocity_limiter.y_slow = 12
			
		"SDashTransit":
			anim_gravity_mod = 0
			anim_friction_mod = 0
			velocity_limiter.x_slow = 10
			velocity_limiter.y_slow = 10
			afterimage_timer = 1 # sync afterimage trail
		"SDash":
			sdash_points = Animator.animations[Animator.current_anim].duration # refresh sdash_points
			aerial_memory = []
			if !grounded:
				super_dash = int(max(0, super_dash - 1))
			var sdash_angle: int

			var rs_dir := Vector2(0, 0)
			if button_rs_up in input_state.pressed:
				rs_dir.y -= 1
			if button_rs_down in input_state.pressed:
				rs_dir.y += 1
			if button_rs_left in input_state.pressed:
				rs_dir.x -= 1
			if button_rs_right in input_state.pressed:
				rs_dir.x += 1
				
			if rs_dir == Vector2(0, 0): # LS sdash
				if !grounded or soft_grounded:
					sdash_angle = Globals.dir_to_angle(dir, v_dir, facing)
				else:
					if v_dir == -1:
						sdash_angle = Globals.dir_to_angle(dir, -1, facing)
					else:
						sdash_angle = Globals.dir_to_angle(dir, 0, facing)
			else: # RS sdash
				if !grounded or soft_grounded:
# warning-ignore:narrowing_conversion
# warning-ignore:narrowing_conversion
					sdash_angle = Globals.dir_to_angle(rs_dir.x, rs_dir.y, facing)
				else:
					if rs_dir.y == -1:
# warning-ignore:narrowing_conversion
						sdash_angle = Globals.dir_to_angle(rs_dir.x, -1, facing)
					else:
# warning-ignore:narrowing_conversion
						sdash_angle = Globals.dir_to_angle(rs_dir.x, 0, facing)

			velocity.set_vector(get_stat("SDASH_SPEED"), 0)
			velocity.rotate(sdash_angle)
			anim_gravity_mod = 0
			anim_friction_mod = 0
			afterimage_timer = 1 # sync afterimage trail
			Globals.Game.spawn_SFX( "RingDust", "RingDust", position, {"rot":deg2rad(sdash_angle), "back":true})
			rotate_sprite(sdash_angle)
			
	UniqNPC._on_SpritePlayer_anim_started(anim_name)
	
	
func _on_SpritePlayer_frame_update(): # emitted after every frame update, useful for staggering audio
	UniqNPC.stagger_anim()

# return modulate to normal after ModulatePlayer finishes playing
# may do follow-up modulate animation
func _on_ModulatePlayer_anim_finished(anim_name):
	if NSAnims.modulate_animations[anim_name].has("followup"):
		reset_modulate()
		modulate_play(NSAnims.modulate_animations[anim_name]["followup"])
	else:
		reset_modulate()
	
func _on_ModulatePlayer_anim_started(anim_name):
	if NSAnims.modulate_animations[anim_name].has("monochrome"):
		set_monochrome()
	
func _on_FadePlayer_anim_finished(anim_name):
	if NSAnims.fade_animations[anim_name].has("followup"):
		reset_fade()
		$FadePlayer.play(NSAnims.fade_animations[anim_name]["followup"])
	else:
		reset_fade()
		
func rotate_sprite(angle: int):
	angle = posmod(angle, 360)
	match facing:
		1:
			if angle > 90 and angle < 270:
				face(-facing)
				sprite.rotation = deg2rad(posmod(angle + 180, 360))
			else:
				sprite.rotation = deg2rad(angle)
		-1:
			if angle < 90 or angle > 270:
				face(-facing)
				sprite.rotation = deg2rad(angle)
			else:
				sprite.rotation = deg2rad(posmod(angle + 180, 360))
		
func rotate_sprite_x_axis(angle: int): # use to rotate sprite without changing facing
	$Sprite.rotation += deg2rad(angle * facing)
		
func modulate_play(anim: String):
	if !$ModulatePlayer.playing:
		pass # always play if no animation playing
	elif anim == $ModulatePlayer.current_anim:
		$ModulatePlayer.sustain = true
		return # no playing if animation is already being played
	elif "priority" in $ModulatePlayer.animations[anim] and "priority" in $ModulatePlayer.animations[$ModulatePlayer.current_anim]:
		if $ModulatePlayer.animations[anim].priority <= $ModulatePlayer.animations[$ModulatePlayer.current_anim].priority:
			pass # only play effect if effect has higher priority than currently played animation, lower priority number = higher
		else:
			return
	$ModulatePlayer.play(anim)
		
		
func reset_modulate():
	palette()
	$ModulatePlayer.stop()
	$ModulatePlayer.current_anim = ""
	sprite.modulate.r = 1.0
	sprite.modulate.g = 1.0
	sprite.modulate.b = 1.0
	
func reset_fade():
	$FadePlayer.stop()
	$FadePlayer.current_anim = ""
	sprite.modulate.a = 1.0
	
	
# aux_data contain "vol", "bus" and "unique_path" (added by this function)
func play_audio(audio_ref: String, aux_data: Dictionary):
	Globals.Game.play_audio(audio_ref, aux_data)

		
# triggered by SpritePlayer at start of each animation
func _on_change_spritesheet(spritesheet_filename):
	sprite.texture = Loader.NPC_data[NPC_ref].spritesheet[spritesheet_filename]
	sprite_texture_ref.sprite = spritesheet_filename
	
func _on_change_SfxOver_spritesheet(SfxOver_spritesheet_filename):
	sfx_over.show()
	sfx_over.texture = Loader.NPC_data[NPC_ref].spritesheet[SfxOver_spritesheet_filename]
	sprite_texture_ref.sfx_over = SfxOver_spritesheet_filename
	
func hide_SfxOver():
	sfx_over.hide()
	
func _on_change_SfxUnder_spritesheet(SfxUnder_spritesheet_filename):
	sfx_under.show()
	sfx_under.texture = Loader.NPC_data[NPC_ref].spritesheet[SfxUnder_spritesheet_filename]
	sprite_texture_ref.sfx_under = SfxUnder_spritesheet_filename
	
func hide_SfxUnder():
	sfx_under.hide()


# SAVE/LOAD STATE --------------------------------------------------------------------------------------------------

func save_state():
	var state_data = {
			
		"free" : free,
		"NPC_ID" : NPC_ID,
		"master_ID" : master_ID,
		"palette_ref" : palette_ref,
		"NPC_ref" : NPC_ref,
			
		"position" : position,
		"air_jump" : air_jump,
		"wall_jump" : wall_jump,
		"air_dash" : air_dash,
		"super_dash" : super_dash,
		"state" : state,
		"new_state": new_state,
		"true_position_x" : true_position.x, # duplicate() does not work on classes! must save the variables inside separately!
		"true_position_y" : true_position.y,
		"velocity_x" : velocity.x,
		"velocity_y" : velocity.y,
		"facing" : facing,
		"velocity_previous_frame_x" : velocity_previous_frame.x,
		"velocity_previous_frame_y" : velocity_previous_frame.y,
		"anim_gravity_mod" : anim_gravity_mod,
		"anim_friction_mod" : anim_friction_mod,
		"velocity_limiter" : velocity_limiter,
		"input_buffer" : input_buffer,
		"afterimage_timer" : afterimage_timer,
		"launch_starting_rot" : launch_starting_rot,
		"launchstun_rotate" : launchstun_rotate,
		"chain_combo" : chain_combo,
		"chain_memory" : chain_memory,
		"active_cancel" : active_cancel,
		"seq_partner_ID" : seq_partner_ID,
		"impulse_used" : impulse_used,
		"quick_turn_used" : quick_turn_used,
		"strafe_lock_dir" : strafe_lock_dir,
		"last_dir": last_dir,
		"from_move_rec" : from_move_rec,
		"slowed" : slowed,
		"gravity_frame_mod" : gravity_frame_mod,
		"js_cancel_target" : js_cancel_target,
		"sdash_points" : sdash_points,
		
		"sprite_texture_ref" : sprite_texture_ref,
		
		"unique_data" : unique_data,
		"aerial_memory" : aerial_memory,
		"aerial_sp_memory" : aerial_sp_memory,
		"hitcount_record" : hitcount_record,
		"ignore_list" : ignore_list,
		"tap_memory" : tap_memory,
		"release_memory" : release_memory,
		
		"sprite_scale" : sprite.scale,
		"sprite_rotation" : sprite.rotation,
		"sfx_over_visible" : sfx_over.visible,
		"sfx_under_visible" : sfx_under.visible,
		"Sprites_visible" : $Sprites.visible,

		"SpritePlayer_data" : $SpritePlayer.save_state(),
		"ModulatePlayer_data" : $ModulatePlayer.save_state(),
		"FadePlayer_data" : $FadePlayer.save_state(),
		
		"VarJumpTimer_time" : $VarJumpTimer.time,
		"HitStopTimer_time" : $HitStopTimer.time,
		"NoCollideTimer_time" : $NoCollideTimer.time,
	}

	return state_data
	
	
func load_state(state_data):

	free = state_data.free
	NPC_ID = state_data.NPC_ID
	master_ID = state_data.master_ID
	palette_ref = state_data.palette_ref
	NPC_ref = state_data.NPC_ref
	load_NPC()
	
	position = state_data.position
	air_jump = state_data.air_jump
	wall_jump = state_data.wall_jump
	air_dash = state_data.air_dash
	super_dash = state_data.super_dash
	state = state_data.state
	new_state = state_data.new_state
	true_position.x = state_data.true_position_x
	true_position.y = state_data.true_position_y
	velocity.x = state_data.velocity_x
	velocity.y = state_data.velocity_y
	facing = state_data.facing
	velocity_previous_frame.x = state_data.velocity_previous_frame_x
	velocity_previous_frame.y = state_data.velocity_previous_frame_y
	anim_gravity_mod = state_data.anim_gravity_mod
	anim_friction_mod = state_data.anim_friction_mod
	velocity_limiter = state_data.velocity_limiter
	input_buffer = state_data.input_buffer
	afterimage_timer = state_data.afterimage_timer
	launch_starting_rot = state_data.launch_starting_rot
	launchstun_rotate = state_data.launchstun_rotate
	chain_combo = state_data.chain_combo
	chain_memory = state_data.chain_memory
	active_cancel = state_data.active_cancel
	seq_partner_ID = state_data.seq_partner_ID
	impulse_used = state_data.impulse_used
	quick_turn_used = state_data.quick_turn_used
	strafe_lock_dir = state_data.strafe_lock_dir
	last_dir = state_data.last_dir
	from_move_rec = state_data.from_move_rec
	slowed = state_data.slowed
	gravity_frame_mod = state_data.gravity_frame_mod
	js_cancel_target = state_data.js_cancel_target
	sdash_points = state_data.sdash_points
		
	sprite_texture_ref = state_data.sprite_texture_ref
	
	unique_data = state_data.unique_data
	
	aerial_memory = state_data.aerial_memory
	aerial_sp_memory = state_data.aerial_sp_memory
	hitcount_record = state_data.hitcount_record
	ignore_list = state_data.ignore_list
	tap_memory = state_data.tap_memory
	release_memory = state_data.release_memory
		
	sprite.scale = state_data.sprite_scale
	sprite.rotation = state_data.sprite_rotation
	sfx_over.visible = state_data.sfx_over_visible
	sfx_under.visible = state_data.sfx_under_visible
	$Sprites.visible = state_data.Sprites_visible
	
	$SpritePlayer.load_state(state_data.SpritePlayer_data)
	reset_modulate()
	$ModulatePlayer.load_state(state_data.ModulatePlayer_data)
	if $ModulatePlayer.current_anim in NSAnims.modulate_animations and \
			NSAnims.modulate_animations[$ModulatePlayer.current_anim].has("monochrome"): set_monochrome()
	reset_fade()
	$FadePlayer.load_state(state_data.FadePlayer_data)
	
	$VarJumpTimer.time = state_data.VarJumpTimer_time
	$HitStopTimer.time = state_data.HitStopTimer_time
	$NoCollideTimer.time = state_data.NoCollideTimer_time



	
#--------------------------------------------------------------------------------------------------


