extends "res://Scenes/Physics/Physics.gd"

#signal SFX (anim, loaded_sfx_ref, out_position, aux_data)
#signal afterimage (sprite_node_path, out_position, starting_modulate_a, lifetime)
#signal entity (master_path, entity_ref, out_position, aux_data)

# constants
const GRAVITY = 70 * FMath.S # per frame
const PEAK_DAMPER_MOD = 60 # used to reduce gravity at jump peak
const PEAK_DAMPER_LIMIT = 400 * FMath.S # min velocity.y where jump peak gravity reduction kicks in
const TERMINAL_THRESHOLD = 150 # if velocity.y is over this during hitstun, no terminal velocity slowdown
const VAR_JUMP_GRAV_MOD = 20 # gravity multiplier during Variable Jump time
const DashLandDBox_HEIGHT = 15 # allow snapping up to dash land easier on soft platforms
const WallJumpDBox_WIDTH = 10 # for detecting walls for walljumping
const TAP_MEMORY_DURATION = 20
#const HitStunGraceTimer_TIME = 10 # number of frames that repeat_memory will be cleared after hitstun/blockstun ends
const ShorthopTimer_TIME = 15 # frames after shorthopping where you cannot block

const MAX_EX_GAUGE = 30000
const EX_LEVEL = 10000
const BASE_EX_SEAL_TIME = 30 # min number of frames to seal EX Gain for after using it, some moves give more

const GUARD_GAUGE_FLOOR = -10000
const GUARD_GAUGE_CEIL = 10000
const GUARD_GAUGE_SWELL_RATE = 100 # exact GG gain per frame during hitstun
const GUARD_GAUGE_DEGEN_AMOUNT = 150 # exact GG degened per frame when GG > 100% out of hitstun

const RESET_EX_COST = 5000
const BURSTCOUNTER_EX_COST = 10000
const BURSTESCAPE_GG_COST = 5000
#const ALPHARESET_EX_COST = 5000
const EX_MOVE_COST = 10000 # 10000

const AIRBLOCK_GRAV_MOD = 50 # multiply to GRAVITY to get gravity during air blocking
const AIRBLOCK_TERMINAL_MOD = 70 # multiply to get terminal velocity during air blocking
const MAX_WALL_JUMP = 2
const HITSTUN_TERMINAL_VELOCITY_MOD = 650 # multiply to GRAVITY to get terminal velocity during hitstun
const PERFECT_IMPULSE_MOD = 140 # multiply by get_stat("SPEED") and get_stat("IMPULSE MOD") to get perfect impulse velocity
const AERIAL_STRAFE_MOD = 50 # reduction of air strafe speed and limit during aerials (non-active frames) and air cancellable recovery
#const GRAVITY_UP_STRAFE_MOD = 0.9 # can reduce gravity if holding up during aerial startup/active
#const GRAVITY_DOWN_STRAFE_MOD = 1.3 # can increase gravity if holding down during aerial startup/active
#const HITSTUN_FALL_THRESHOLD = 400 * FMath.S  # if falling too fast during hitstun will help out
const PLAYER_PUSH_SLOWDOWN = 95 # how much characters are slowed when they push against each other
const RESPAWN_GRACE_DURATION = 60 # how long invincibility last when respawning
#const CROUCH_REDUCTION_MOD = 50 # reduce knockback and hitstun if opponent is crouching
const AERIAL_STARTUP_LAND_CANCEL_TIME = 3 # number of frames when aerials can land cancel their startup and auto-buffer pressed attacks
const BurstLockTimer_TIME = 3 # number of frames you cannot use Burst Escape after being hit
const AC_BurstLockTimer_TIME = 10 # number of frames you cannot use Burst Escape after being hit with an autochain move
#const PosFlowSealTimer_TIME = 30 # min number of frames to seal Postive Flow for after setting pos_flow_seal = true
const TrainingRegenTimer_TIME = 50 # number of frames before GG/Damage Value start regening
const CROSS_UP_MIN_DIST = 10 # characters must be at least a certain number of pixels away horizontally to count as a cross-up
const CORNER_PUSHBACK = 200 * FMath.S # attacker is pushed back when attacking at the corner towards the corner
#const CORNER_GUARD_DRAIN_MOD = 150 # blocker take extra Guard Drain when blocking at the corners
#const DODGE_SEMI_IFRAMES = 10 # frames of semi-invuln while dodging

const MIN_HITSTOP = 5
const MAX_HITSTOP = 13
const REPEAT_DMG_MOD = 50 # damage modifier on double_repeat
const DMG_VAL_KB_LIMIT = 300 # max damage percent before knockback stop increasing
const KB_BOOST_AT_DMG_VAL_LIMIT = 150 # knockback power when damage percent is at 100%, goes pass it when damage percent goes >100%
const HITSTUN_REDUCTION_AT_MAX_GG = 70 # max reduction in hitstun when defender's Guard Gauge is at 200%
#const L_HITSTUN_REDUCTION_AT_MAX_GG = 80 # max reduction in launch hitstun when defender's Guard Gauge is at 200%
#const KB_BOOST_AT_MAX_GG = 300 # max increase of knockback when defender's Guard Gauge is at 200%
const DMG_REDUCTION_AT_MAX_GG = 50 # max reduction in damage when defender's Guard Gauge is at 200%
#const FIRST_HIT_GUARD_DRAIN_MOD = 150 # % of listed Guard Drain on 1st hit of combo or stray hits
const POS_FLOW_REGEN = 140 #  # exact GG gain per frame during Positive Flow
const ATK_LEVEL_TO_F_HITSTUN = [15, 20, 25, 30, 35, 40, 45, 50]
const ATK_LEVEL_TO_L_HITSTUN = [25, 30, 35, 40, 45, 50, 55, 60]
const ATK_LEVEL_TO_GDRAIN = [0, 1500, 1750, 2000, 2250, 2500, 2750, 3000]

const HITSTUN_GRAV_MOD = 65  # gravity multiplier during hitstun
const HITSTUN_FRICTION = 15  # friction during hitstun
const HITSTUN_AIR_RES = 3 # air resistance during hitstun

const LETHAL_KB_MOD = 150 # multiply knockback strength when defender is at Damage Value Limit
const LETHAL_HITSTOP = 25
const LETHAL_HITSTUN_MOD = 150 # multiply hitstun when defender is at Damage Value Limit

const SD_KNOCKBACK_LIMIT = 300 * FMath.S # knockback strength limit of a semi-disjoint hit
const SD_HIT_GUARD_DRAIN_MOD = 150 # Guard Drain on semi-disjoint hits

const SWEETSPOT_KB_MOD = 115
const SWEETSPOT_DMG_MOD = 150 # damage modifier on sweetspotted hit
const SWEETSPOT_HITSTOP_MOD = 130 # sweetspotted hits has 30% more hitstop

const PUNISH_DMG_MOD = 150 # damage modifier on punish_hit
const PUNISH_HITSTOP_MOD = 130 # punish hits has 30% more hitstop

const STUN_DMG_MOD = 150 # damage modifier on stun
const STUN_TIME = 100 # number of frames stun time last for Stun
const STUN_HITSTOP_ATTACKER = 15 # hitstop for attacker when causing Stun
const CRUSH_TIME = 40 # number of frames stun time last for Crush

const WEAKBLOCK_HITSTOP = 5
const WEAKBLOCK_ATKER_PUSHBACK = 800 * FMath.S # how much the attacker is pushed away when wrongblocked, fixed
const WEAKBLOCK_KNOCKBACK_MOD = 200 # % of knockback defender experience when wrongblocking
const STRONGBLOCK_HITSTOP = 7
const STRONGBLOCK_ATKER_PUSHBACK = 800 * FMath.S # how much the attacker is pushed away when strongblocked, fixed
const STRONGBLOCK_KNOCKBACK_MOD = 0 # % of knockback defender experience when strongblocking
#const STRONGBLOCK_RANGE = 50 * FMath.S # radius that a physical Light/Fierce can be strongblocked
const MOBBLOCK_ATKER_PUSHBACK = 300 * FMath.S # how much the attacker is pushed away when resisted by mobs, fixed

const SPECIAL_GDRAIN_MOD = 200 # extra GDrain when blocking heavy/special/ex moves
#const SPECIAL_BLOCK_KNOCKBACK_MOD = 200 # extra KB when blocking heavy/special/ex/super moves
const SDASH_ARMOR_GDRAIN_MOD = 200 # extra GDrain when SDashing through projectiles

const AUTOCHAIN_HITSTOP = 7
const WEAK_HIT_HITSTOP = 6

#const SUPERARMOR_CHIP_DMG_MOD = 50
#const SUPERARMOR_GUARD_DRAIN_MOD = 150


const LAUNCH_THRESHOLD = 450 * FMath.S # max knockback strength before a flinch becomes a launch, also added knockback during a Break
const LAUNCH_BOOST = 250 * FMath.S # increased knockback strength when a flinch becomes a launch
const LAUNCH_ROT_SPEED = 5*PI # speed of sprite rotation when launched, don't need fixed-point as sprite rotation is only visuals
const TECHLAND_THRESHOLD = 300 * FMath.S # max velocity when hitting the ground to tech land

const STRONG_HIT_AUDIO_BOOST = 3
const WEAK_HIT_AUDIO_NERF = -9

const WALL_SLAM_THRESHOLD = 100 * FMath.S # min velocity towards surface needed to do Wall Slams and release BounceDust when bouncing
const WALL_SLAM_VEL_LIMIT_MOD = 1000
const WALL_SLAM_MIN_DAMAGE = 50
const WALL_SLAM_MAX_DAMAGE = 200
const HORIZ_WALL_SLAM_UP_BOOST = 500 * FMath.S # if bounce horizontally on ground, boost up a little

const KILL_VEL_THRESHOLD = 900 * FMath.S

const LAUNCH_DUST_THRESHOLD = 1400 * FMath.S # velocity where launch dust increase in frequency

const DDI_SIDE_MAX = 30 * FMath.S # horizontal Drift DI speed at 200% Guard Gauge
const MAX_DDI_SIDE_SPEED = 300 * FMath.S # max horizontal Drift DI speed
const GDI_UP_MAX = 80 # gravity decrease upward Gravity DI at 200% Guard Gauge
const GDI_DOWN_MAX = 130 # gravity increase downward Gravity DI at 200% Guard Gauge
const VDI_MAX = 30 # change in knockback vector when using Vector DI at 200% Guard Gauge
#const DI_MIN_MOD = 0 # percent of max DI at 100% Guard Gauge

const SURVIVAL_HITSTOP = 15
#const MOB_GRACE_DURATION = 30 # how long invincibility last after being hit by a mob
#const SURV_BASE_DMG = 70

# variables used, don't touch these
#var loaded_palette = null
onready var Animator = $SpritePlayer # clean code
onready var sprite = $Sprites/Sprite # clean code
onready var sfx_under = $Sprites/SfxUnder # clean code
onready var sfx_over = $Sprites/SfxOver # clean code
var UniqChar # unique character node
var directory_name
var palette_number
#var spritesheet = { # filled up at initialization via set_up_spritesheet()
##	"Base" : load("res://Characters/___/Spritesheets/Base.png") # example
#	}
##var unique_audio = { # filled up at initialization
###	"example" : load("res://Characters/___/UniqueAudio/example.wav") # example
##}
#var entity_data = { # filled up at initialization
##	"TridentProj" : { # example
##		"scene" : load("res://Characters/Gura/Entities/TridentProj.tscn"),
##		"frame_data" : load("res://Characters/Gura/Entities/FrameData/TridentProj.tres"),
##		"spritesheet" : ResourceLoader.load("res://Characters/Gura/Entities/Spritesheets/TridentProjSprite.png")
##	},
#}
#var sfx_data = { # filled up at initialization
##	"WaterJet" : { # example
##		"frame_data" : load("res://Characters/Gura/SFX/FrameData/WaterJet.tres"),
##		"spritesheet" : ResourceLoader.load("res://Characters/Gura/SFX/Spritesheets/WaterJetSprite.png")
##	},
#}
var floor_level
#var left_ledge
#var right_ledge
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
var hitstop = null # holder to influct hitstop at end of frame
var status_effect_to_remove = [] # holder to remove status effects at end of frame
var status_effect_to_add = [] # holder to add status effects at end of frame after removal
var startup_cancel_flag := false # allow cancelling of startup frames without rebuffering
var instant_actions_temp := [] # used to transfer instant actions captured this frame into instant_actions array after stored ones are processed
#var alt_block := false # neutral dash can be used to block as well
#var attacked_this_frame := false

var player_ID: int # player number controlling this character, 0 for P1, 1 for P2


# character state, save these when saving and loading along with position, sprite frame and animation progress
var air_jump := 0
var wall_jump := 0
var air_dash := 0
var air_dodge := 0
var super_dash := 0
var state = Em.char_state.GROUND_STANDBY
var new_state = Em.char_state.GROUND_STANDBY
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

onready var current_damage_value: int = 0
onready var current_guard_gauge: int = 0
onready var current_ex_gauge: int = 10000
onready var super_ex_lock = null # starting EXSealTimer time
onready var install_time = null
onready var burst_token = Em.burst.AVAILABLE
var stock_points_left: int
var coin_count := 0

var hitcount_record = [] # record number of hits for current attack for each player, cannot do anymore hits if maxed out
var ignore_list = [] # some moves has ignore_time, after hitting will ignore that player for a number of frames, used for multi-hit specials

var launch_starting_rot := 0.0 # starting rotation when being launched, current rotation calculated using hitstun timer and this, can leave as float
var launchstun_rotate := 0 # used to set rotation when being launched, use to count up during hitstun
var unique_data = {} # data unique for the character, stored as a dictionary
var status_effects = [] # an Array of arrays, in each Array store a enum of the status effect and a duration, can have a third aux data as well
var chain_combo = Em.chain_combo.RESET # set to Em.chain_combo
var chain_memory = [] # appended whenever you attack, reset when not attacking or in air/ground startup
var active_cancel := false # set to true when landing a Sweetspotted Normal or certain Launchers, set to false when starting any attack
#var perfect_chain := false # set to true when doing a 1 frame cancel, set to false when not in active frames
var repeat_memory = [] # appended whenever hit by a move, cleared whenever you recover from hitstun, to incur Repeat Penalty on attacker
					# each entry is an array with [0] being the move name and [1] being the player_ID
var aerial_memory = [] # appended whenever an air normal attack is made, cannot do the same air normal twice in a jump
					   # reset on landing or air jump
var aerial_sp_memory = [] # appended whenever an air normal attack is made, cannot do the same air normal twice before landing
						  # reset on landing
var success_block = Em.success_block.NONE # set to true after blocking an attack, allow block recovery to be cancellable, reset on block startup
var success_dodge := false # set to true after iframing through an attack, turn later part of dodge cancellable, reset outside dodge
var target_ID = null # ID of the opponent, changes whenever you land a hit on an opponent or is attacked
var seq_partner_ID = null # not always target_ID during Mimic Raid
var tap_memory = []
var release_memory = []
var impulse_used := false
var quick_turn_used := false # can only quick turn once per attack
var strafe_lock_dir := 0 # when pressing left/right when doing an aerial, lock the air strafe direction during startup
var DI_seal := false # some moves (multi-hit, autochain) will lock DI throughout the duration of BurstLockTimer, also lock GG Swell
var instant_actions := [] # when an instant action is inputed it is stored here for 1 frame, only process next frame
						 # this allows for quick cancels and triggering entities
#var ex_seal := false # usage of EX Gauge locks EX Gain till targeted opponent's HitStunGraceTimer is over
var last_dir := 0 # dir last frame
var GG_swell_flag := false # set to true after 1st attack taken during a combo
var first_hit_flag := false # will not swell GG during hitstun of 1st attack taken during combo
var lethal_flag := false # flag the hitstun as a lethal hit, can only kill during lethal hitstun
var from_move_rec := false # to prevent QCing into NOT_FROM_MOVE_REC moves
var enhance_cooldowns := {} # each key contain the cooldown
var enhance_data := {} # like unique_data
var slowed := 0
var spent_special := false # used a move that requires Special to be held, releasing Special will not trigger EX moves
var spent_unique := false # used a move that requires Unique to be held, releasing Special will not trigger EX moves
var wall_slammed = Em.wall_slam.CANNOT_SLAM
var delayed_hit_effect := [] # store things like Em.hit.SWEETSPOTTED and Em.hit.PUNISH_HIT for autochain and multi-hit moves

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

var test := false # used to test specific player, set by main game scene to just one player
var test_num := 0


# SETUP CHARACTER --------------------------------------------------------------------------------------------------

# this is run after adding this node to the tree
func init(in_player_ID, in_character, start_position, start_facing, in_palette_number):
	add_to_group("PlayerNodes")
	
	set_player_id(in_player_ID)
	
	# remove test character node and add the real character node
#	var test_character = get_child(0) # test character node should be directly under this node
#	test_character.free()
	
	UniqChar = in_character
	add_child(UniqChar)
	move_child(UniqChar, 0)
	directory_name = "res://Characters/" + UniqChar.NAME + "/"
	
	# setup load_data
	if !UniqChar.NAME in Loader.char_data:
		Loader.char_data[UniqChar.NAME] = {
	#		"scene" : load("res://Characters/Gura/Gura.tscn"),
			"frame_data_array" : [
			],
			"spritesheet" : {
			},
			"palettes" : {
			}
		}
		set_up_spritesheet() # scan all .png files within Spritesheet folder and add them to "spritesheet" dictionary in char_data in Loader
		set_up_unique_audio() # scan all .wav files within Audio folder and add them to "Loader.audio" dictionary
		set_up_entities() # scan all .tscn files within Entities folder and add them to "entities_data" dictionary
		set_up_sfx() # scan all .tres files within SFX/FrameData folder and add them to "sfx_data" dictionary
	
	
	UniqChar.sprite = sprite
#	sprite.texture = spritesheet["BaseSprite"]
	
	# set up animators
	UniqChar.Animator = $SpritePlayer
	Animator.init(sprite, sfx_over, sfx_under, directory_name + "FrameData/")
	animate("Idle")
	$ModulatePlayer.sprite = sprite
	$FadePlayer.sprite = sprite
	
	# overwrite default movement stats
	
	setup_boxes(UniqChar.get_node("DefaultCollisionBox"))
	reset_jumps()
	
	# incoming start position points at the floor
	start_position.y -= $PlayerCollisionBox.rect_position.y + $PlayerCollisionBox.rect_size.y
	
	position = start_position
	set_true_position()
	floor_level = Globals.Game.middle_point.y # get floor level of stage
#	left_ledge = Globals.Game.left_ledge_point.x
#	right_ledge = Globals.Game.right_ledge_point.x
	
	if facing != start_facing:
		face(start_facing)
		
	palette_number = in_palette_number
	if palette_number > 1:
#		loaded_palette = ResourceLoader.load(directory_name + "Palettes/" + str(palette_number) + ".png")
		Loader.add_loaded(Loader.char_data[UniqChar.NAME]["palettes"], palette_number, \
				ResourceLoader.load(directory_name + "Palettes/" + str(palette_number) + ".png"))
		
	palette()
	sfx_under.hide()
	sfx_over.hide()
	
	if palette_number in UniqChar.PALETTE_TO_PORTRAIT:
		Globals.Game.HUD.get_node("P" + str(player_ID + 1) + "_HUDRect/Portrait").self_modulate = \
			UniqChar.PALETTE_TO_PORTRAIT[palette_number]
	
	if Globals.training_mode:
		stock_points_left = 10000
		burst_token = Em.burst.AVAILABLE
	else:
		stock_points_left = Globals.Game.starting_stock_pts
		
	if Globals.survival_level != null:
		burst_token = Em.burst.CONSUMED
		coin_count = Globals.Game.LevelControl.starting_coin

	unique_data = UniqChar.UNIQUE_DATA_REF.duplicate(true)
	
	yield(get_tree(),"idle_frame") # wait after GameViewport finished setup
#	Globals.Game.damage_limit_update(self)
	Globals.Game.damage_update(self)
	Globals.Game.guard_gauge_update(self)
	Globals.Game.ex_gauge_update(self)
	Globals.Game.stock_points_update(self)
	Globals.Game.burst_update(self)
	if Globals.survival_level != null:
		Globals.Game.coin_update(self)
	
	
func set_player_id(in_player_ID): # can use this to change player you are controlling during training mode
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
	button_rs_up = Globals.INPUTS[player_ID].rs_up[1]
	button_rs_down = Globals.INPUTS[player_ID].rs_down[1]
	button_rs_left = Globals.INPUTS[player_ID].rs_left[1]
	button_rs_right = Globals.INPUTS[player_ID].rs_right[1]

func setup_boxes(ref_rect): # set up detection boxes
	
	$PlayerCollisionBox.rect_position = ref_rect.rect_position
	$PlayerCollisionBox.rect_size = ref_rect.rect_size
	$PlayerCollisionBox.add_to_group("Players")
	$PlayerCollisionBox.add_to_group("Grounded")

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
		sprite.material.shader = Loader.loaded_palette_shader
		sprite.material.set_shader_param("swap", Loader.char_data[UniqChar.NAME].palettes[palette_number])
		sfx_over.material = ShaderMaterial.new()
		sfx_over.material.shader = Loader.loaded_palette_shader
		sfx_over.material.set_shader_param("swap", Loader.char_data[UniqChar.NAME].palettes[palette_number])
		sfx_under.material = ShaderMaterial.new()
		sfx_under.material.shader = Loader.loaded_palette_shader
		sfx_under.material.set_shader_param("swap", Loader.char_data[UniqChar.NAME].palettes[palette_number])
		
		
func get_palette(): # called by other functions
	return Loader.char_data[UniqChar.NAME].palettes[palette_number]
		
		
# fill up the "spritesheet" dictionary with spritesheets in the "Spritesheets" folder loaded and ready
func set_up_spritesheet():
	# open the Spritesheet folder and get the filenames of all files in it
	var directory = Directory.new()
	if directory.open(directory_name + "Spritesheets/") == OK:
		directory.list_dir_begin(true)
		var file_name = directory.get_next()
		while file_name != "":
			# load all needed files and add them to the dictionary
			if file_name.ends_with(".png.import"):
				var file_name2 = file_name.get_file().trim_suffix(".png.import")
#				spritesheet[file_name2] = ResourceLoader.load(directory_name + "Spritesheets/" + file_name2 + ".png")
				Loader.add_loaded(Loader.char_data[UniqChar.NAME].spritesheet, file_name2, \
						ResourceLoader.load(directory_name + "Spritesheets/" + file_name2 + ".png"))
			file_name = directory.get_next()
	else: print("Error: Cannot open Spritesheets folder for character")
	
	
func set_up_unique_audio():
	var directory = Directory.new()
	if directory.open(directory_name + "UniqueAudio/") == OK:
		directory.list_dir_begin(true)
		var file_name = directory.get_next()
		while file_name != "":
			# load all needed files and add them to the dictionary
			if file_name.ends_with(".wav.import"):
				var file_name2 = file_name.get_file().trim_suffix(".wav.import")
				Loader.add_loaded(Loader.audio, file_name2, ResourceLoader.load(directory_name + "UniqueAudio/" + file_name2 + ".wav"))
#				unique_audio[file_name2] = \
#					ResourceLoader.load(directory_name + "UniqueAudio/" + file_name2 + ".wav")
			file_name = directory.get_next()
	else: print("Error: Cannot open UniqueAudio folder for character")
	
	
func set_up_entities(): # scan all .tscn files within Entities folder and add them to "entities_data" dictionary
#	var entity_data = {
#	#	"TridentProj" : { # example
#	#		"scene" : load("res://Characters/Gura/Entities/TridentProj.tscn"),
#	#		"frame_data" : ResourceLoader.load("res://Characters/Gura/Entities/FrameData/TridentProj.tres"),
#	#		"spritesheet" : ResourceLoader.load("res://Characters/Gura/Entities/Spritesheets/TridentProjSprite.png")
#	#	},
#	}
	var directory = Directory.new()
	if directory.open(directory_name + "Entities") == OK:
		directory.list_dir_begin(true)
		var file_name = directory.get_next()
		while file_name != "":
			# load all needed files and add them to the dictionary
			if file_name.ends_with(".tscn"):
				var file_name2 = file_name.get_file().trim_suffix(".tscn")	
				if !file_name2 in Loader.entity_data:
					var entity_data = {}
					entity_data["scene"] = \
						load(directory_name + "Entities/" + file_name)
					entity_data["frame_data"] = \
						ResourceLoader.load(directory_name + "Entities/FrameData/" + file_name2 + ".tres")
					entity_data["spritesheet"] = \
						ResourceLoader.load(directory_name + "Entities/Spritesheets/" + file_name2 + "Sprite.png")
					Loader.add_loaded(Loader.entity_data, file_name2, entity_data)
					
			file_name = directory.get_next()
	else: print("Error: Cannot open Entities folder for character")
	
	
func set_up_sfx(): # scan all .tres files within SFX/FrameData folder and add them to "sfx_data" dictionary
#	var sfx_data = {
#	#	"WaterJet" : { # example
#	#		"frame_data" : load("res://Characters/Gura/SFX/FrameData/WaterJet.tres"),
#	#		"spritesheet" : ResourceLoader.load("res://Characters/Gura/SFX/Spritesheets/WaterJetSprite.png")
#	#	},
#	}
	var directory = Directory.new()
	if directory.open(directory_name + "SFX/FrameData/") == OK:
		directory.list_dir_begin(true)
		var file_name = directory.get_next()
		while file_name != "":
			# load all needed files and add them to the dictionary
			if file_name.ends_with(".tres"):
				var file_name2 = file_name.get_file().trim_suffix(".tres")
				if !file_name2 in Loader.sfx:
					var sfx_data = {}
					sfx_data["frame_data"] = \
						ResourceLoader.load(directory_name + "SFX/FrameData/" + file_name)
					sfx_data["spritesheet"] = \
						ResourceLoader.load(directory_name + "SFX/Spritesheets/" + file_name2 + "Sprite.png")
					Loader.add_loaded(Loader.sfx, file_name2, sfx_data)
				
			file_name = directory.get_next()
	else: print("Error: Cannot open SFX folder for character")
	
	
func initial_targeting(): # target random players at start, cannot do in init() since need all players to be added first
	# target a random opponent
	if Globals.survival_level == null:
		var player_IDs = []
		for x in Globals.player_count:
			if x != player_ID:
				player_IDs.append(x)
		target_ID = player_IDs[Globals.Game.rng_generate(player_IDs.size())]
	else:
		target_ID = player_ID
	
	
# TESTING --------------------------------------------------------------------------------------------------

# for testing only
func test1():
	if Globals.debug_mode2:
		if $HitStopTimer.is_running() or $RespawnTimer.is_running():
			test0()
		$TestNode2D/TestLabel.text = $TestNode2D/TestLabel.text + "old state: " + Globals.char_state_to_string(state) + \
			"\n" + Animator.current_anim + " > " + Animator.to_play_anim + "  time: " + str(Animator.time) + "\n"
	else:
		$TestNode2D/TestLabel.text = ""
			
func test0():
	if Globals.debug_mode2:
		var string_input_buffer = []
		for buffered_input in input_buffer:
			var string_buffered_input = [Globals.input_to_string(buffered_input[0], player_ID), buffered_input[1]]
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
			str(input_buffer) + "\n" + str(input_state) + " " + str(GG_swell_flag)
	else:
		$TestNode2D/TestLabel.text = ""
			
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
			
	elif Globals.training_mode:
		if Globals.training_settings.hitbox_viewer == 1:
			$PlayerCollisionBox.show()
		else:
			$PlayerCollisionBox.hide()

	if test:
		if Globals.debug_mode2:
			$TestNode2D.show()
		else:
			$TestNode2D.hide()
			
			
func simulate(new_input_state):
		
	input_state = new_input_state # so that I can use it in other functions
			
	if Globals.editor:
		if Input.is_action_just_pressed("sound_test") and test:
#		modulate_play("red_burst")
#
##		var test_pt = Detection.ground_finder(position, facing, Vector2(100, 50), Vector2(100, 100))
##		if test_pt: Globals.Game.spawn_SFX("HitsparkB", "HitsparkB", test_pt, {})
#
#		match test_num % 3:
#			0:
#				play_audio("kill1", {"vol" : -10})
#			1:
#				play_audio("kill2", {"vol" : -12})
#			2:
#				play_audio("kill3", {"vol" : -12, "bus" : "Reverb"})
#
#		test_num += 1
#			change_ex_gauge(-MAX_EX_GAUGE)
#			$EXSealTimer.time = 120
#			super_ex_lock = 120
#			change_burst_token(1)
#			if super_test(true):
#				super_cost(120, true)
#			Globals.Game.get_player_node(target_ID).change_guard_gauge(-8000)
#			unique_data.nibbler_count = 3
#			UniqChar.update_uniqueHUD()
			
#			Globals.Game.LevelControl.spawn_mob("TestMobBase", Vector2.ZERO)
#			enhance_card(Globals.Game.LevelControl.effect_ref.SHARK)
#			if !Inventory.shop_open:
#				Globals.Game.card_menu.open_shop()
	
#			get_target().add_status_effect([Em.status_effect.SLOWED, 60, 3])
#			var field_id = Globals.Game.spawn_field(player_ID, "TimeBubbleE", position, {}).entity_ID
#			Globals.Game.spawn_SFX("TimeBubbleTop", "TimeBubbleTop", position, {"field": true, "sticky_ID": field_id, "sticky_entity" : true})
#			if "rewind" in enhance_data:
#				var to_loaded_state = enhance_data.rewind.saved_state.duplicate(true)
#				load_state(to_loaded_state, true)
#			for x in 50:
#				Globals.Game.spawn_entity(player_ID, "PhoenixFeatherE", position + Vector2(25 * facing, -x * 5), {}, null, UniqChar.NAME)
#			super_cost(60, 30, 180)
#			var random = Globals.Game.rng_generate(4)
#			var rand_facing = Globals.Game.rng_facing()
#			if random == 0:
#				Globals.Game.spawn_entity(player_ID, "TakoGateE", get_target().position + Vector2(0, -100), \
#						{"facing":rand_facing, "alt1":true})
#			elif random == 1:
#				Globals.Game.spawn_entity(player_ID, "TakoGateE", get_target().position + Vector2(70 * -rand_facing, -50), \
#						{"facing":rand_facing, "alt2":true})
#			elif random == 2:
#				Globals.Game.spawn_entity(player_ID, "TakoGateE", get_target().position + Vector2(100 * -rand_facing, 0), \
#						{"facing":rand_facing, "alt3":true})
#			else:
#				Globals.Game.spawn_entity(player_ID, "TakoGateE", get_target().position + Vector2(0, 70), \
#						{"facing":rand_facing, "alt4":true})
#			Globals.Game.spawn_entity(player_ID, "NousagiE", position, {})
#			enhance_card(Cards.effect_ref.REWIND, true)

	
			pass

		
		if button_aux in input_state.just_pressed and button_unique in input_state.pressed:
			pass
#			Globals.Game.superfreeze(get_path())
#			Globals.Game.set_screenstop()
#			Globals.Game.set_screenshake()
	
# PAUSING --------------------------------------------------------------------------------------------------
		
	if button_pause in input_state.just_pressed:
		Globals.pausing = true
	elif button_pause in input_state.just_released:
		Globals.pausing = false


# SET NON-SAVEABLE DATA --------------------------------------------------------------------------------------------------
# reset even on hitstop and respawning
# variables that are reseted right before being used don't need to be reset here

	dir = 0
	instant_dir = 0
	v_dir = 0
	
	hitstop = null
	status_effect_to_remove = []
	status_effect_to_add = []
#	attacked_this_frame = false
	startup_cancel_flag = false # to cancel startup without incurring auto-buffer

	if is_on_ground($SoftPlatformDBox):
		grounded = true
	else:
		grounded = false
		
	if is_on_soft_ground($SoftPlatformDBox):
		soft_grounded = true
	else:
		soft_grounded = false


# FRAMESKIP DURING HITSTOP --------------------------------------------------------------------------------------------------
	# while buffering all inputs
	
	
	if Globals.Game.is_stage_paused() and Globals.Game.screenfreeze != player_ID: # screenfrozen
		return
		
	var slow_amount = query_status_effect_aux(Em.status_effect.SLOWED)
	if slow_amount != null: slowed = slow_amount
	if slowed != 0 and (slowed < 0 or posmod(Globals.Game.frametime, slowed) != 0):
		buffer_actions()
		return
	
	$HitStopTimer.simulate() # advancing the hitstop timer at start of frame allow for one frame of knockback before hitstop
	# will be needed for multi-hit moves
	
	if stock_points_left > 0:
		$RespawnTimer.simulate()
	
	if !$RespawnTimer.is_running():
		if !$HitStopTimer.is_running():
			simulate2()
		else:
			buffer_actions() # can still buffer buttons during hitstop
		


func simulate2(): # only ran if not in hitstop
	
# START OF FRAME --------------------------------------------------------------------------------------------------

	if state == Em.char_state.DEAD:
#	 and Globals.survival_level == null:
		respawn()
	
#	if abs(velocity.x) < 5.0: # do this at start too
#		velocity.x = 0.0
#	if abs(velocity.y) < 5.0:
#		velocity.y = 0.0
		
	if grounded:
		reset_jumps()
		
#	if is_on_ground($SoftPlatformDBox):
#		grounded = true
#		reset_jumps() # reset air jumps and air dashes here
#	else:
#		grounded = false
#
#	if is_on_soft_ground($SoftPlatformDBox):
#		soft_grounded = true
#	else:
#		soft_grounded = false
		
	ignore_list_progress_timer()
	process_status_effects_timer() # remove expired status effects
	
	# clearing repeat memory
	if !is_hitstunned_or_sequenced():
		repeat_memory = []
		first_hit_flag = false
		GG_swell_flag = false
		$BurstLockTimer.stop()
		DI_seal = false
		lethal_flag = false
		wall_slammed = Em.wall_slam.CANNOT_SLAM
		delayed_hit_effect = []
		
	if !new_state in [Em.char_state.SEQUENCE_TARGET, Em.char_state.SEQUENCE_USER]:
		seq_partner_ID = null
		
	if Globals.survival_level != null and Globals.difficulty != 3:
		if Globals.Game.LevelControl.wave_standby_timer > 0:
			if Globals.Game.LevelControl.wave_standby_timer == 1:
				current_damage_value = 0
				Globals.Game.damage_update(self)
			else:
				take_damage(-20) # heal between waves
		
#		if !is_hitstunned() and query_status_effect(Em.status_effect.SURVIVAL_GRACE):
#			remove_status_effect(Em.status_effect.SURVIVAL_GRACE)
		
	if success_dodge and (new_state != Em.char_state.AIR_REC or !Animator.query_to_play(["DodgeTransit", "Dodge"])):
		success_dodge = false # reset success_dodge outside dodge
		
	# GG Swell during hitstun
	if !$HitStopTimer.is_running() and is_hitstunned() and GG_swell_flag and !first_hit_flag and \
			!state in [Em.char_state.SEQUENCE_TARGET, Em.char_state.SEQUENCE_USER] and \
			!(DI_seal and $BurstLockTimer.is_running()):
			current_guard_gauge = int(min(GUARD_GAUGE_CEIL, current_guard_gauge + GUARD_GAUGE_SWELL_RATE))
			Globals.Game.guard_gauge_update(self)

	# regen/degen GG
	elif !is_hitstunned_or_sequenced():
		
		if !Globals.training_mode or (player_ID == 1 and Globals.training_settings.gganchor == 5):
			if current_guard_gauge < 0 and !is_blocking(): # regen GG when GG is under 100%
				var guard_gauge_regen: int = 0
				if query_status_effect(Em.status_effect.POS_FLOW):
					guard_gauge_regen = POS_FLOW_REGEN # increased regen during positive flow
				else:
					guard_gauge_regen = get_stat("GG_REGEN_AMOUNT")
				current_guard_gauge = int(min(0, current_guard_gauge + guard_gauge_regen)) # don't use change_guard_gauge() since it stops at 0
				Globals.Game.guard_gauge_update(self)
				
			elif current_guard_gauge > 0: # degen GG when GG is over 100%
				current_guard_gauge = int(max(0, current_guard_gauge - GUARD_GAUGE_DEGEN_AMOUNT))
				Globals.Game.guard_gauge_update(self)
		
		else: # training mode
			if current_guard_gauge > 0:
				current_guard_gauge = int(max(0, current_guard_gauge - GUARD_GAUGE_DEGEN_AMOUNT))
				Globals.Game.guard_gauge_update(self)
			else:
				if player_ID == 0: # player 1 rapidly regen GG when GG < 0 during training mode
					if current_guard_gauge < 0 and !is_blocking():
						current_guard_gauge = int(min(0, current_guard_gauge + 200))
						Globals.Game.guard_gauge_update(self)
				if player_ID == 1:
					if !$TrainingRegenTimer.is_running(): # training mode regen GG for player 2 only after a while of not being hit
						var target: int = 0
						match Globals.training_settings.gganchor:
							0: pass
							1: target = -2500
							2: target = -5000
							3: target = -7500
							4: target = -10000
						if current_guard_gauge < target:
							current_guard_gauge = int(min(target, current_guard_gauge + 200))
						elif current_guard_gauge > target:
							current_guard_gauge = int(max(target, current_guard_gauge - 200))
						Globals.Game.guard_gauge_update(self)
	
		
	# regen EX Gauge
	if !Globals.training_mode:
		
		if !Globals.Game.input_lock and current_ex_gauge < MAX_EX_GAUGE and state != Em.char_state.DEAD:
			var ex_change := get_stat("BASE_EX_REGEN") * FMath.S
			if is_hitstunned():
				ex_change = FMath.percent(ex_change, get_stat("HITSTUN_EX_REGEN_MOD"))
			else:
				match chain_combo:
					Em.chain_combo.NORMAL, Em.chain_combo.HEAVY, Em.chain_combo.SPECIAL: # landed an attack on opponent
						ex_change = FMath.percent(ex_change, get_stat("LANDED_EX_REGEN_MOD"))
					Em.chain_combo.WEAKBLOCKED, Em.chain_combo.STRONGBLOCKED: # landed an attack on blocking opponent
						ex_change = FMath.percent(ex_change, get_stat("BLOCKED_EX_REGEN_MOD"))
					_:
						if Globals.survival_level != null:
							continue # no whiff EX Gain for Survival
						if is_attacking() and new_state != Em.char_state.SEQUENCE_USER:
							var move_data = query_move_data()
							if !Em.move.DMG in move_data:
								ex_change = FMath.percent(ex_change, get_stat("NON_ATTACK_EX_REGEN_MOD")) # for non-attacks, reduce EX regen
							else:
								ex_change = FMath.percent(ex_change, get_stat("ATTACK_EX_REGEN_MOD")) # physical attack, raise EX regen

			if Globals.survival_level != null:
				if ex_change == get_stat("BASE_EX_REGEN") * FMath.S:
					# no passive EX Gain for Survival unless with cards
					ex_change = Inventory.modifier(player_ID, Cards.effect_ref.PASSIVE_EX_REGEN)
					if ex_change != 0:
						change_ex_gauge(ex_change)
				else:
					ex_change = FMath.percent(ex_change, 60) # EX Gain for survival mode
					change_ex_gauge(FMath.round_and_descale(ex_change))
			else:
				change_ex_gauge(FMath.round_and_descale(ex_change))
			
			
	else: # training mode regen EX Gauge
		if current_ex_gauge < MAX_EX_GAUGE:
			change_ex_gauge(600)
		if Globals.training_settings.regen == 1 and !$TrainingRegenTimer.is_running() and current_damage_value > 0:
			take_damage(-30) # regen damage
		
	if !$InstallTimer.is_running():
		if install_time != null:
			install_time = null
			if UniqChar.has_method("install_over"): UniqChar.install_over()
			
		if !$EXSealTimer.is_running():
			super_ex_lock = null
		elif super_ex_lock != null:
			Globals.Game.ex_gauge_update(self)
	elif install_time != null:
		Globals.Game.ex_gauge_update(self)
	
	# drain EX Gauge when air blocking
#	if !grounded and is_blocking():
#		var ex_gauge_drain = round(UniqChar.AIR_BLOCK_DRAIN_RATE * Globals.FRAME)
#		change_ex_gauge(-ex_gauge_drain)
#		if current_ex_gauge <= 0.0:
#			match Animator.current_anim:
#				"aBlock":
#					animate("FallTransit")
#	elif $ModulatePlayer.is_playing() and $ModulatePlayer.query_current(["EX_block_flash", "EX_block_flash2"]):
#		reset_modulate()
		
	if !is_attacking() and !new_state in [Em.char_state.AIR_STARTUP, Em.char_state.GROUND_STARTUP, \
			Em.char_state.AIR_REC, Em.char_state.GROUND_REC]:
		reset_cancels()
		chain_memory = []
		
	if Globals.survival_level != null and get_tree().get_nodes_in_group("MobNodes").size() > 0:
		timed_enhance()
		
	if status_effects.size() > 0:
		timed_status()
	
#	if pos_flow_seal and !$PosFlowSealTimer.is_running():
#		if !get_node(targeted_opponent_path).get_node("HitStunTimer").is_running():
#			pos_flow_seal = false


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
	
#	if Globals.survival_level != null and Inventory.shop_open:
#		dir = 0
#		v_dir = 0
#		instant_dir = 0
		

#	if button_right in input_state.just_pressed:
#		if button_left in input_state.just_pressed:
#			dir = 0
#		else:
#			dir = 1
#	elif button_left in input_state.just_pressed:
#		dir = -1
		
	if state in [Em.char_state.SEQUENCE_USER, Em.char_state.SEQUENCE_TARGET]:
		simulate_sequence()
		return
		
# LEFT/RIGHT BUTTON --------------------------------------------------------------------------------------------------

	if dir != 0:
		match state:
			
	# GROUND MOVEMENT --------------------------------------------------------------------------------------------------
	
			Em.char_state.GROUND_STANDBY:
				if dir != facing: # flipping over
					face(dir)
					animate("RunTransit") # restart run animation
				 # if not in run animation, do run animation
				if !Animator.query(["Run", "RunTransit"]):
					animate("RunTransit")
						
				velocity.x = FMath.f_lerp(velocity.x, dir * get_stat("SPEED"), get_stat("ACCELERATION"))
	
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
		#					if move_data[Em.move.ATK_TYPE] in [Em.atk_type.LIGHT, Em.atk_type.FIERCE, Em.atk_type.HEAVY]: # Normal
		#						if Em.atk_attr.NO_STRAFE_NORMAL in move_data[Em.move.ATK_ATTR]:
		#							continue # cannot strafe during some aerial normals
		#					else: # non-Normal
		#						if !Em.atk_attr.STRAFE_NON_NORMAL in move_data[Em.move.ATK_ATTR]:
		#							continue # can strafe during some aerial non-normals
						Em.char_state.AIR_STANDBY:
							face(strafe_dir) # turning in air
					
#					if state == Em.char_state.AIR_STANDBY and strafe_dir != facing: # flipping over
##						if (button_light in input_state.pressed or button_fierce in input_state.pressed or \
##								button_aux in input_state.pressed) and button_dash in input_state.pressed:
##							pass # if pressing attack + dash in the air, will not turn
##						else:
#						face(strafe_dir)

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
					
	# LEFT/RIGHT DI --------------------------------------------------------------------------------------------------
					
			_:
				if is_hitstunned() and can_DI():# no changing facing
					
					# DDI speed and speed limit depends on guard gauge
					var DDI_speed: int
					var DDI_speed_limit: int
					
					if Globals.survival_level == null:
						DDI_speed = FMath.f_lerp(0, DDI_SIDE_MAX, get_guard_gauge_percent_above())
						DDI_speed_limit = FMath.f_lerp(0, MAX_DDI_SIDE_SPEED, get_guard_gauge_percent_above())
					else:
#						DDI_speed = FMath.f_lerp(0, DDI_SIDE_MAX, get_guard_gauge_percent_true())
#						DDI_speed_limit = FMath.f_lerp(0, MAX_DDI_SIDE_SPEED, get_guard_gauge_percent_true())
						DDI_speed = DDI_SIDE_MAX
						DDI_speed_limit = MAX_DDI_SIDE_SPEED
					
					if abs(velocity.x + (dir * DDI_speed)) > abs(velocity.x): # if speeding up
						if abs(velocity.x) < DDI_speed_limit: # only allow DIing if below speed limit (can scale speed limit to guard gauge?)
							velocity.x = int(clamp(velocity.x + dir * DDI_speed, -DDI_speed_limit, DDI_speed_limit))
					else: # slowing down
						velocity.x += dir * DDI_speed
			
			
	# TURN AT START OF CERTAIN MOVES --------------------------------------------------------------------------------------------------
						
		if facing != dir:
				
			if check_quick_turn():
				if !grounded:
					quick_turn_used = true
				face(dir)
				
		if Settings.input_assist[player_ID]:
			# quick impulse
			match state:
				Em.char_state.GROUND_ATK_STARTUP:
					if !impulse_used and Animator.time <= 1:
						var move_name = Animator.to_play_anim.trim_suffix("Startup")
						if move_name in UniqChar.STARTERS:
							if !Em.atk_attr.NO_IMPULSE in query_atk_attr(move_name): # ground impulse
								impulse_used = true
								var impulse: int = dir * FMath.percent(get_stat("SPEED"), get_stat("IMPULSE_MOD"))
								# some moves have their own impulse mod
			#					if move_name in UniqChar.MOVE_DATABASE and "impulse_mod" in UniqChar.MOVE_DATABASE[move_name]:
			#						var impulse_mod: int = UniqChar.query_move_data(move_name).impulse_mod
			#						impulse = FMath.percent(impulse, impulse_mod)
								velocity.x = int(clamp(velocity.x + impulse, -abs(impulse), abs(impulse)))
								Globals.Game.spawn_SFX("GroundDashDust", "DustClouds", get_feet_pos(), {"facing":dir, "grounded":true})
				
			# quick strafe-lock
				Em.char_state.AIR_ATK_STARTUP:
					if strafe_lock_dir == 0 and Animator.time <= 1:
						var move_name = Animator.to_play_anim.trim_suffix("Startup")
						if move_name in UniqChar.STARTERS:
							strafe_lock_dir = dir


#	if instant_dir != 0 and facing != instant_dir: # this allow for quick turns when you tap a direction while holding another direction
#		match state:
#			Em.char_state.GROUND_STANDBY:
#				face(instant_dir)
#			Em.char_state.AIR_STANDBY:
#				if (button_light in input_state.pressed or button_fierce in input_state.pressed or button_aux in input_state.pressed) and \
#						button_dash in input_state.pressed:
#					pass  # if pressing attack + dash in the air, will not turn
#				else:
#					face(instant_dir)
#			_:
#				if check_quick_turn():
#					face(instant_dir)
				

	# IMPULSE --------------------------------------------------------------------------------------------------
	
#	if button_left in input_state.pressed or button_right in input_state.pressed: # don't use dir for this one...
#		if new_state == Em.char_state.GROUND_ATK_STARTUP and Animator.time == QUICK_CANCEL_TIME: # only possible on frame 1
#			var move_name = Animator.to_play_anim.trim_suffix("Startup")
#			if move_name in UniqChar.MOVE_DATABASE and \
#					!Em.atk_attr.NO_IMPULSE in query_atk_attr(move_name): # ground impulse
#				if button_left in input_state.just_pressed or button_right in input_state.just_pressed:
#					velocity.x = facing * UniqChar.get_speed() * PERFECT_IMPULSE_MOD
#					Globals.Game.spawn_SFX("SpecialDust", "DustClouds", get_feet_pos(), {"facing":facing, "grounded":true})
#				else:
#					velocity.x = facing * UniqChar.get_speed() * IMPULSE_MOD
#					Globals.Game.spawn_SFX("GroundDashDust", "DustClouds", get_feet_pos(), {"facing":facing, "grounded":true})


# DOWN BUTTON --------------------------------------------------------------------------------------------------
	
	if button_down in input_state.pressed and !button_unique in input_state.pressed:
		if Globals.survival_level != null and Inventory.shop_open:
			pass
		else:
		
			match state:
				
			# TO CROUCH --------------------------------------------------------------------------------------------------
			
				Em.char_state.GROUND_STANDBY:
					animate("CrouchTransit")
					
			# CROUCH CANCELS FOR CHAINDASHING --------------------------------------------------------------------------------------------------
				# crouch to cancel ground dash recovery
		
				Em.char_state.GROUND_C_REC:
					if Animator.query_to_play(["SoftLanding", "HardLanding"]):
						animate("Crouch")
					elif Animator.query_to_play(["DashBrake", "WaveDashBrake"]):
						pass
	#					if Em.trait.CHAIN_DASH in query_traits():
	#						animate("CrouchTransit")
					else:
						animate("CrouchTransit")

			# FASTFALL --------------------------------------------------------------------------------------------------
				# cannot fastfall right after jumping
				
	#		if Settings.dj_fastfall[player_ID] == 0 and (button_special in input_state.pressed or button_unique in input_state.pressed):
	#
	#			# if normal fastfall, cannot fastfall when button_special/button_unique are held down
	#			# this makes aerial EX move down-tilts not fastfall too easily
	#
	#			pass
	#		else:
				
				Em.char_state.AIR_STANDBY:
					if !Animator.query_to_play(["JumpTransit2", "JumpTransit3", "FastFallTransit", "FastFall"]):


						if Settings.dj_fastfall[player_ID] == 0 or \
							(Settings.dj_fastfall[player_ID] == 1 and button_jump in input_state.pressed):
								
							animate("FastFallTransit")
							
	#						if Settings.dt_fastfall[player_ID] == 1:
	##							tap_memory.append([button_down, 2]) # allow you to double tap then hold down
	#						velocity.y = FMath.f_lerp(velocity.y, FMath.percent(FMath.percent(GRAVITY, get_stat("TERMINAL_VELOCITY_MOD")), \
	#							get_stat("FASTFALL_MOD")), 30)
	#						if Animator.query(["FallTransit"]): # go straight to fall animation
	#							animate("Fall")
					
					elif Animator.query_to_play(["FastFall"]): # hold down while in fastfall animation to fast fall
	#					velocity.y = FMath.f_lerp(velocity.y, FMath.percent(FMath.percent(GRAVITY, get_stat("TERMINAL_VELOCITY_MOD")), \
	#						get_stat("FASTFALL_MOD")), 30)
						velocity.y = FMath.percent(FMath.percent(GRAVITY, get_stat("TERMINAL_VELOCITY_MOD")), get_stat("FASTFALL_MOD"))
						# fastfall reduce horizontal speed limit
						var ff_speed_limit: int = FMath.percent(get_stat("SPEED"), 70)
						if velocity.x < -ff_speed_limit:
							velocity.x = FMath.f_lerp(velocity.x, -ff_speed_limit, 50)
						elif velocity.x > ff_speed_limit:
							velocity.x = FMath.f_lerp(velocity.x, ff_speed_limit, 50)
								
				Em.char_state.AIR_STARTUP: # can cancel air jump startup to fastfall
					if Settings.dj_fastfall[player_ID] == 0 or \
						(Settings.dj_fastfall[player_ID] == 1 and button_jump in input_state.pressed):
							
						if Animator.query_to_play(["aJumpTransit"]):
							animate("FastFallTransit")
						
							
				Em.char_state.GROUND_ATK_REC, Em.char_state.AIR_ATK_REC: # fastfall cancel from aerial hits
					if Settings.dj_fastfall[player_ID] == 0 or \
						(Settings.dj_fastfall[player_ID] == 1 and button_jump in input_state.pressed):
							
						if test_fastfall_cancel():
							animate("FastFallTransit")

# BLOCK BUTTON --------------------------------------------------------------------------------------------------	
	
#	alt_block = false
#	if !button_up in input_state.pressed and !button_down in input_state.pressed and \
#		!button_left in input_state.pressed and !button_right in input_state.pressed:
#		if button_dash in input_state.pressed:
#			alt_block = true
#		if button_dash in input_state.just_pressed and button_aux in input_state.pressed:
#			input_buffer.append(["Burst", buffer_time()])
			
	if button_block in input_state.pressed and !button_aux in input_state.pressed and !button_jump in input_state.pressed:
		if Globals.survival_level != null and Inventory.shop_open:
			pass
		elif $ShorthopTimer.is_running():
			pass # no blocking after shorthopping for a while
		elif current_guard_gauge >= FMath.percent(GUARD_GAUGE_FLOOR, 75): # need at least 25% left to block
			match state:
				
			# ground blocking
	#			Em.char_state.GROUND_STARTUP: # can block on 1st frame of ground dash
	#				if Animator.query_current(["DashTransit"]):
	#					animate("BlockStartup")
				Em.char_state.GROUND_STANDBY:
					animate("BlockStartup")
#				Em.char_state.GROUND_C_REC:
##					if Animator.query(["BurstCRec"]): # cannot block out of BurstRevoke
##						continue
#					if Animator.query_to_play(["WaveDashBrake"]): # cannot block out of ground dash unless you have the DASH_BLOCK trait
#						if has_trait(Em.trait.WAVE_DASH_BLOCK):
#							animate("BlockStartup")
#					elif Animator.query_to_play(["HardLanding"]):
#						pass # cannot block on hardlanding
#					else:
#	#					continue
#						animate("BlockStartup")
						
				Em.char_state.GROUND_ATK_REC: # block cancelling
					if chain_combo in [Em.chain_combo.NORMAL, Em.chain_combo.HEAVY]:
						afterimage_cancel()
						animate("BlockStartup")
					elif Globals.survival_level != null and Inventory.has_quirk(player_ID, Cards.effect_ref.BLOCK_CANCEL):
						afterimage_cancel()
						animate("BlockStartup")
						
			# air blocking
	#		if current_guard_gauge + GUARD_GAUGE_CEIL >= -get_stat("AIR_BLOCK_GG_COST"):

	#			Em.char_state.AIR_STARTUP: # can air block on 1st frame of air dash
	#				if Animator.query_current(["aDashTransit"]):
	#					animate("aBlockStartup")
	#					$VarJumpTimer.stop()
				Em.char_state.AIR_STANDBY:
	#				if current_ex_gauge >= UniqChar.AIR_BLOCK_DRAIN_RATE * 0.5:
					animate("aBlockStartup")
					$VarJumpTimer.stop()
					
#				Em.char_state.AIR_C_REC:
#					if Animator.query_to_play(["aDashBrake"]): # cannot air block out of air dash unless you have the AIR_DASH_BLOCK trait
#						if has_trait(Em.trait.AIR_DASH_BLOCK): # only heavyweights can block out of air dashes
#							animate("aBlockStartup")
#							$VarJumpTimer.stop()
#					else:
#						animate("aBlockStartup")
#						$VarJumpTimer.stop()
			
				Em.char_state.AIR_ATK_REC: # block cancelling
					if chain_combo in [Em.chain_combo.NORMAL, Em.chain_combo.HEAVY]:
						afterimage_cancel()
						animate("aBlockStartup")
					elif Globals.survival_level != null and Inventory.has_quirk(player_ID, Cards.effect_ref.BLOCK_CANCEL):
						afterimage_cancel()
						animate("aBlockStartup")

# CHECK DROPS AND LANDING ---------------------------------------------------------------------------------------------------
	
	if !grounded:
		match new_state:
			Em.char_state.GROUND_STANDBY, Em.char_state.CROUCHING, Em.char_state.GROUND_C_REC, \
				Em.char_state.GROUND_STARTUP, Em.char_state.GROUND_ACTIVE, Em.char_state.GROUND_REC, \
				Em.char_state.GROUND_ATK_STARTUP, Em.char_state.GROUND_ATK_ACTIVE, Em.char_state.GROUND_ATK_REC, \
				Em.char_state.GROUND_FLINCH_HITSTUN, Em.char_state.GROUND_BLOCK:
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

	if !grounded and (abs(velocity.y) < PEAK_DAMPER_LIMIT): # reduce gravity at peak of jump
# warning-ignore:narrowing_conversion
		var weight: int = FMath.get_fraction_percent(PEAK_DAMPER_LIMIT - abs(velocity.y), PEAK_DAMPER_LIMIT)
		gravity_temp = FMath.f_lerp(gravity_temp, FMath.percent(gravity_temp, PEAK_DAMPER_MOD), weight)
		# transit from jump to fall animation
		if new_state == Em.char_state.AIR_STANDBY and Animator.query_to_play(["Jump"]): # don't use query() for this one
			animate("FallTransit")

	if !grounded: # gravity only pulls you if you are in the air
		
		if is_hitstunned():
			if can_DI(): # up/down DI, depends on Guard Gauge
				if Globals.survival_level == null:
					if v_dir == -1: # DIing upward
						gravity_temp = FMath.f_lerp(gravity_temp, FMath.percent(gravity_temp, GDI_UP_MAX), get_guard_gauge_percent_above())
					elif v_dir == 1: # DIing downward
						gravity_temp = FMath.f_lerp(gravity_temp, FMath.percent(gravity_temp, GDI_DOWN_MAX), get_guard_gauge_percent_above())
				else:
					if v_dir == -1: # DIing upward
#						gravity_temp = FMath.f_lerp(gravity_temp, FMath.percent(gravity_temp, GDI_UP_MAX), get_guard_gauge_percent_true())
						gravity_temp = FMath.percent(gravity_temp, GDI_UP_MAX)
					elif v_dir == 1: # DIing downward
#						gravity_temp = FMath.f_lerp(gravity_temp, FMath.percent(gravity_temp, GDI_DOWN_MAX), get_guard_gauge_percent_true())
						gravity_temp = FMath.percent(gravity_temp, GDI_DOWN_MAX)
		else:
			if velocity.y > 0: # some characters may fall at different speed compared to going up
				gravity_temp = FMath.percent(gravity_temp, get_stat("FALL_GRAV_MOD"))
				if state == Em.char_state.AIR_BLOCK: # air blocking reduce gravity
					gravity_temp = FMath.percent(gravity_temp, AIRBLOCK_GRAV_MOD)

#			# during aerial startup and active, can control gravity a little as well by pressing up/down
#			if state in [Em.char_state.AIR_ATK_STARTUP, Em.char_state.AIR_ATK_ACTIVE]:
#				if v_dir == -1:
#					gravity_temp *= GRAVITY_UP_STRAFE_MOD
#				elif v_dir == 1:
#					gravity_temp *= GRAVITY_DOWN_STRAFE_MOD
				
		velocity.y += gravity_temp
		
	# terminal velocity downwards
	var terminal: int
	
	var has_terminal := true
	
	if new_state == Em.char_state.AIR_REC and Animator.query_to_play(["Dodge", "DodgeRec", "DodgeCRec"]):
		has_terminal = false
	
#	if is_atk_startup():
#		if Em.atk_attr.NO_TERMINAL_VEL_STARTUP in query_atk_attr():
#			 has_terminal = false
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
				if Settings.dj_fastfall[player_ID] == 0 or (Settings.dj_fastfall[player_ID] == 1 and button_jump in input_state.pressed):
					terminal = FMath.percent(terminal, get_stat("FASTFALL_MOD")) # increase terminal velocity when fastfalling
			if state == Em.char_state.AIR_BLOCK: # air blocking reduce terminal velocity
				terminal = FMath.percent(terminal, AIRBLOCK_TERMINAL_MOD)

			if velocity.y > terminal:
				velocity.y = FMath.f_lerp(velocity.y, terminal, 75)
				
	if velocity.y < 0 and $VarJumpTimer.is_running() and !grounded and abs(velocity.y) > PEAK_DAMPER_LIMIT:
		if (button_jump in input_state.pressed or button_up in input_state.pressed):
			if $VarJumpTimer.time <= get_stat("VAR_JUMP_SLOW_POINT"):
				velocity.y = FMath.f_lerp(velocity.y, PEAK_DAMPER_LIMIT, get_stat("HIGH_JUMP_SLOW"))
		else:
			velocity.y = FMath.f_lerp(velocity.y, PEAK_DAMPER_LIMIT, get_stat("SHORT_JUMP_SLOW"))
		

# FRICTION/AIR RESISTANCE AND TRIGGERED ANIMATION CHANGES ----------------------------------------------------------
	# place this at end of frame later
	# for triggered animation changes, use query_to_play() instead
	# query() check animation at either start/end of frame, query_to_play() only check final animation
	
	var friction_this_frame: int # 15
	var air_res_this_frame: int
	
	if !is_hitstunned():
		friction_this_frame = get_stat("FRICTION")
		air_res_this_frame = get_stat("AIR_RESISTANCE")
	else:
		friction_this_frame = HITSTUN_FRICTION # 15
		air_res_this_frame = HITSTUN_AIR_RES # 3
	
	match state:
		Em.char_state.GROUND_STANDBY:
			if dir == 0: # if not moving
				# if in run animation, do brake animation
				if Animator.query_to_play(["Run", "RunTransit"]):
					animate("Brake")
			else: # no friction when moving
				friction_this_frame = 0
			
		Em.char_state.CROUCHING:
			if !button_down in input_state.pressed and Animator.query_to_play(["Crouch"]):
				animate("CrouchReturn") # stand up
	
		Em.char_state.GROUND_STARTUP:
			friction_this_frame = 0 # no friction when starting a ground jump/dash
				
		Em.char_state.GROUND_C_REC:
			if Animator.query(["HardLanding"]): # lower friction when hardlanding?
				friction_this_frame = FMath.percent(friction_this_frame, 50)

		Em.char_state.AIR_STANDBY:
			# just in case, fall animation if falling downwards without slowing down
			if velocity.y > 0 and Animator.query_to_play(["Jump"]):
				animate("FallTransit")
				
			if Animator.query_to_play(["FastFallTransit", "FastFall"]) and !button_down in input_state.pressed:
				animate("Fall")
	
		Em.char_state.AIR_D_REC:
			air_res_this_frame = 0
			# air dash into wall/ceiling, stop instantly
			var stopped := false
			if Animator.query_to_play(["aDash", "aDashD", "aDashU"]) and is_against_wall($PlayerCollisionBox, $SoftPlatformDBox, facing):
				stopped = true
			elif Animator.query_to_play(["aDashU"]) and is_against_ceiling($PlayerCollisionBox, $SoftPlatformDBox):
				stopped = true
			if stopped:
				animate("aDashBrake")
				if Animator.current_anim == "aDashTransit": # to fix a bug when touching a wall during aDashTransit > aDash
					UniqChar.consume_one_air_dash() # reduce air_dash count by 1
					
	
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
					if grounded and posmod(Globals.Game.frametime, 5) == 0: # drag rocks on ground
						Globals.Game.spawn_SFX("DragRocks", "DustClouds", get_feet_pos(), {"facing":Globals.Game.rng_facing(), "grounded":true})
						
					var vel_angle = velocity.angle() # rotation and navigation
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
					
						
			elif Animator.query_current(["Dodge"]):
				if get_target().position.x - position.x != 0 and \
						sign(get_target().position.x - position.x) != facing:
					face(-facing) # face opponent
						
					
		Em.char_state.GROUND_BLOCK:
			if !button_block in input_state.pressed and !button_dash in input_state.pressed and Animator.query_current(["Block"]):
				if success_block == Em.success_block.SBLOCKED:
					animate("BlockCRec")
				else:
					animate("BlockRec")
#			elif !success_block:
			change_guard_gauge(-get_stat("GROUND_BLOCK_GG_COST"))
			if current_guard_gauge <= GUARD_GAUGE_FLOOR:
				animate("BlockRec")
			
#		Em.char_state.GROUND_BLOCKSTUN:
#			if !$BlockStunTimer.is_running():
#				animate("BlockstunReturn")
			
		Em.char_state.AIR_BLOCK:
			if !button_block in input_state.pressed and !button_dash in input_state.pressed and Animator.query_current(["aBlock"]): # don't use to_play
				if success_block == Em.success_block.SBLOCKED:
					animate("aBlockCRec")
				else:
					animate("aBlockRec")
#			elif !success_block:
			change_guard_gauge(-get_stat("AIR_BLOCK_GG_COST"))
			if current_guard_gauge <= GUARD_GAUGE_FLOOR:
				animate("aBlockRec")
					
			air_res_this_frame = 5
			
#			else:
#				if !button_dash in input_state.pressed and Animator.query_to_play(["aBlock"]):
#					if !success_block:
#						animate("aBlockRec")
#					else:
#						animate("aBlockCRec")
#				air_res_this_frame *= 1.5
			
#		Em.char_state.AIR_BLOCKSTUN:
#			if !$BlockStunTimer.is_running():
#				if !guardtech():
#					animate("aBlockstunReturn")
#
#			air_res_this_frame = 5

		Em.char_state.AIR_ATK_STARTUP:
			if anim_gravity_mod == 0:
				air_res_this_frame = 0
			friction_this_frame = FMath.percent(friction_this_frame, 75) # lower friction when landing while doing an aerial
			
		Em.char_state.AIR_ATK_ACTIVE:
			if anim_gravity_mod == 0:
				air_res_this_frame = 0
			
		Em.char_state.GROUND_FLINCH_HITSTUN:
			# when out of hitstun, recover
			if !$HitStunTimer.is_running():
				if !tech():
					if Animator.query_to_play(["FlinchA"]):
						animate("FlinchAReturn")
					elif Animator.query_to_play(["FlinchB"]):
						animate("FlinchBReturn")
					modulate_play("unflinch_flash")
			else:
				friction_this_frame = FMath.percent(friction_this_frame, 50) # lower friction during flinch hitstun
					
		Em.char_state.AIR_FLINCH_HITSTUN:
			# when out of hitstun, recover
#			if velocity.y > HITSTUN_FALL_THRESHOLD and position.y > floor_level:
#				velocity.y = HITSTUN_FALL_THRESHOLD # limit downward velocity during air flinch
			if !$HitStunTimer.is_running():
				if !tech():
					if Animator.query_to_play(["aFlinchA"]):
						animate("aFlinchAReturn")
					elif Animator.query_to_play(["aFlinchB"]):
						animate("aFlinchBReturn")
					modulate_play("unflinch_flash")
		
		Em.char_state.LAUNCHED_HITSTUN:
			# when out of hitstun, recover
			if $HitStunTimer.time == 1:
				modulate_play("unlaunch_flash")
				play_audio("bling4", {"vol" : -15, "bus" : "PitchDown"})
			elif !$HitStunTimer.is_running():
				if !tech():
					if Globals.survival_level != null and Inventory.has_quirk(player_ID, Cards.effect_ref.AUTO_TECH):
						animate("FallTransit")
#					animate("FallTransit")]
#					modulate_play("unlaunch_flash")
#					play_audio("bling4", {"vol" : -15, "bus" : "PitchDown"})
			friction_this_frame = FMath.percent(friction_this_frame, 25) # lower friction during launch hitstun
							
	
# APPLY FRICTION/AIR RESISTANCE --------------------------------------------------------------------------------------------------

	if grounded: # apply friction if on ground
		if anim_friction_mod != 100:
			friction_this_frame = FMath.percent(friction_this_frame, anim_friction_mod)
		velocity.x = FMath.f_lerp(velocity.x, 0, friction_this_frame)

	else: # apply air resistance if in air
		velocity.x = FMath.f_lerp(velocity.x, 0, air_res_this_frame)
	
# --------------------------------------------------------------------------------------------------

	buffer_actions()
	UniqChar.simulate() # some holdable buttons can have effect unique to the character
	
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
	
	process_VDI()
	
	if !$HitStopTimer.is_running() and $HitStunTimer.is_running() and state == Em.char_state.LAUNCHED_HITSTUN:
		launch_trail() # do launch trail before moving
		
	if grounded and dir == 0 and abs(velocity.x) < 2 * FMath.S * get_stat("FRICTION"):
		velocity.x = 0  # this reduces slippiness by canceling grounded horizontal velocity when moving less than 0.5 pixels per frame

	
	velocity_previous_frame.x = velocity.x
	velocity_previous_frame.y = velocity.y
	
	var orig_pos = position
	var results = move($PlayerCollisionBox, $SoftPlatformDBox, check_ledge_stop()) # [landing_check, collision_check, ledgedrop_check]
	
#	if results[0]: check_landing()

	if results[1]:
		if $NoCollideTimer.is_running(): # if collide during 1st/Xth frame after hitstop, will return to position before moving
			position = orig_pos
			set_true_position()
			velocity.x = velocity_previous_frame.x
			velocity.y = velocity_previous_frame.y
		else:
			if results[0]: check_landing()
			
			if new_state == Em.char_state.AIR_REC and Animator.query_to_play(["SDash"]):
				check_sdash_crash()
			elif new_state == Em.char_state.LAUNCHED_HITSTUN:
				bounce(results[0])
			
			
	# get overlapping characters, all grounded overlapping characters above you get sent to the back
	var overlapping = Detection.detect_return([$PlayerCollisionBox], ["Players"])
	if overlapping.size() > 0:
		for overlapper in overlapping:
			if overlapper.grounded and overlapper.get_position_in_parent() > get_position_in_parent() and \
				overlapper.get_feet_pos().y < get_feet_pos().y:
				Globals.Game.get_node("Players").move_child(overlapper, 0)
		
	# must process hitbox/hurtboxes after calculation (since need to use to_play_anim after it is calculated)
	# however, must process before running the animation and advancing the time counter
	# must process after moving the character as well or will misalign
	
	# ends here, process hit detection in game scene, afterwards game scene will call simulate_after() to finish up
	

func simulate_after(): # called by game scene after hit detection to finish up the frame
	
	test1()
	
	progress_tap_and_release_memory()
	
	for effect in status_effect_to_remove: # remove certain status effects at end of frame after hit detection
										   # useful for status effects that are removed after being hit
		remove_status_effect(effect)
		
	for effect in status_effect_to_add:
		add_status_effect(effect)
		
	if Globals.Game.is_stage_paused() and Globals.Game.screenfreeze != player_ID:
		hitstop = null
		return
	if slowed != 0 and (slowed < 0 or posmod(Globals.Game.frametime, slowed) != 0):
		slowed = 0
		$HitStopTimer.stop()
		return
	slowed = 0
	
	capture_and_process_instant_actions() # can do instant actions during hitstop, but not screenfreeze
	
	if !$RespawnTimer.is_running():

		process_status_effects_visual()
		flashes()
		
		if !$HitStopTimer.is_running():
			
			process_afterimage_trail() 	# do afterimage trails
			
			# render the next frame, this update the time!
			$SpritePlayer.simulate()
			$FadePlayer.simulate() # ModulatePlayer ignore hitstop but FadePlayer doesn't
			
			if !hitstop: # timers do not run on exact frame hitstop starts
				$VarJumpTimer.simulate()
				$ShorthopTimer.simulate()
				$HitStunTimer.simulate()
				$BurstLockTimer.simulate()
				$NoCollideTimer.simulate()
				$InstallTimer.simulate()
				if super_ex_lock == null: # EX Seal from using meter normally, no gaining meter for rest of combo
					if !get_target().is_hitstunned_or_sequenced():
						# no counting down EX Seal if opponent is hitstunned or sequenced
						$EXSealTimer.simulate()
				else: # EX Seal from using super, count down during opponent hitstun as well
					if $InstallTimer.is_running() or (is_attacking() and is_super(get_move_name())): # no counting down EX Seal during Super animation
						pass
					else:
						$EXSealTimer.simulate()
				if !is_hitstunned_or_sequenced():
#					$HitStunGraceTimer.simulate()
					if Globals.training_mode:
						$TrainingRegenTimer.simulate()
			
			# spin character during launch, be sure to do this after SpritePlayer since rotation is reset at start of each animation
			if state == Em.char_state.LAUNCHED_HITSTUN and Animator.query_current(["LaunchTransit", "Launch"]):
				sprite.rotation = launch_starting_rot - facing * launchstun_rotate * LAUNCH_ROT_SPEED * Globals.FRAME
				launchstun_rotate += 1
		
		# start hitstop timer at end of frame after SpritePlayer.simulate() by setting hitstop to a number other than null for the frame
		# new hitstops override old ones
		if hitstop:
			$HitStopTimer.time = hitstop
			
		$ModulatePlayer.simulate() # modulate animations continue even in hitstop
		
		if Globals.survival_level != null and enhance_cooldowns.size() > 0:
			enhance_cooldown()
	
	test2()
		

# BOUNCE --------------------------------------------------------------------------------------------------	

func bounce(against_ground: bool):
	if is_against_wall($PlayerCollisionBox, $SoftPlatformDBox, sign(velocity_previous_frame.x)):
		if grounded:
			velocity.y = -HORIZ_WALL_SLAM_UP_BOOST
		velocity.x = -FMath.percent(velocity_previous_frame.x, 75)
		if abs(velocity.x) > WALL_SLAM_THRESHOLD: # release bounce dust if fast enough
			
			# if bounce off hard enough, take damage scaled to velocity and guard gauge
			if wall_slammed == Em.wall_slam.CAN_SLAM and current_guard_gauge > 0 and \
					abs(velocity_previous_frame.x) > abs(velocity_previous_frame.y) and \
					Detection.detect_bool([$PlayerCollisionBox], ["BlastWalls"], Vector2(sign(velocity_previous_frame.x), 0)):
				var scaled_damage = wall_slam(velocity.x)
				
				if scaled_damage >= WALL_SLAM_MIN_DAMAGE:
					wall_slammed = Em.wall_slam.HAS_SLAMMED
					take_damage(scaled_damage)
					if Globals.survival_level == null:
						Globals.Game.spawn_damage_number(scaled_damage, position)
					else: Globals.Game.spawn_damage_number(scaled_damage, position, Em.dmg_num_col.RED)
					
					var slam_level := 0
					if scaled_damage >= 100:
						if scaled_damage < 150:
							hitstop = 12
							slam_level = 1
							play_audio("break3", {"vol" : -14,})
							modulate_play("punish_sweet_flash")
							Globals.Game.set_screenshake()
							change_guard_gauge(FMath.percent(GUARD_GAUGE_FLOOR, 25))
						else:
							hitstop = 15
							slam_level = 2
							play_audio("break3", {"vol" : -10,})
							modulate_play("punish_sweet_flash")
							Globals.Game.set_screenshake()
							change_guard_gauge(FMath.percent(GUARD_GAUGE_FLOOR, 50))
					else:
						hitstop = 9
						play_audio("break3", {"vol" : -18,})
						modulate_play("punish_flash")
						
					if sign(velocity_previous_frame.x) > 0:
						bounce_dust(Em.compass.E, slam_level)
					else:
						bounce_dust(Em.compass.W, slam_level)
					return
				
			
			if sign(velocity_previous_frame.x) > 0:
				bounce_dust(Em.compass.E)
			else:
				bounce_dust(Em.compass.W)
			play_audio("rock3", {"vol" : -10,})
				
				
	elif is_against_ceiling($PlayerCollisionBox, $SoftPlatformDBox):
		velocity.y = -FMath.percent(velocity_previous_frame.y, 50)
		if abs(velocity.y) > WALL_SLAM_THRESHOLD: # release bounce dust if fast enough
			
			# if bounce off hard enough, take damage scaled to velocity and guard gauge
			if wall_slammed == Em.wall_slam.CAN_SLAM and current_guard_gauge > 0 and \
					abs(velocity_previous_frame.y) > abs(velocity_previous_frame.x) and \
					Detection.detect_bool([$PlayerCollisionBox], ["BlastCeiling"], Vector2.UP):
				var scaled_damage = wall_slam(velocity.y)
				
				if scaled_damage >= WALL_SLAM_MIN_DAMAGE:
					wall_slammed = Em.wall_slam.HAS_SLAMMED
					take_damage(scaled_damage)
					if Globals.survival_level == null:
						Globals.Game.spawn_damage_number(scaled_damage, position)
					else: Globals.Game.spawn_damage_number(scaled_damage, position, Em.dmg_num_col.RED)
					
					var slam_level := 0
					if scaled_damage >= 100:
						if scaled_damage < 150:
							hitstop = 12
							slam_level = 1
							play_audio("break3", {"vol" : -14,})
							modulate_play("punish_sweet_flash")
							Globals.Game.set_screenshake()
							change_guard_gauge(FMath.percent(GUARD_GAUGE_FLOOR, 25))
						else:
							hitstop = 15
							slam_level = 2
							play_audio("break3", {"vol" : -10,})
							modulate_play("punish_sweet_flash")
							Globals.Game.set_screenshake()
							change_guard_gauge(FMath.percent(GUARD_GAUGE_FLOOR, 50))
					else:
						hitstop = 9
						play_audio("break3", {"vol" : -18,})
						modulate_play("punish_flash")

					bounce_dust(Em.compass.N, slam_level)
					return
				
			bounce_dust(Em.compass.N)
			play_audio("rock3", {"vol" : -10,})
				
				
	elif against_ground:
		if $HitStunTimer.is_running():
			velocity.y = -FMath.percent(velocity_previous_frame.y, 90)
		else:
			velocity.y = -FMath.percent(velocity_previous_frame.y, 50) # shorter bounce if techable
		if abs(velocity.y) > WALL_SLAM_THRESHOLD: # release bounce dust if fast enough towards ground
			bounce_dust(Em.compass.S)
			play_audio("rock3", {"vol" : -10,})
			
			
func wall_slam(vel) -> int:
	var weight: int = FMath.get_fraction_percent(int(abs(vel)) - WALL_SLAM_THRESHOLD, \
			FMath.percent(WALL_SLAM_THRESHOLD, WALL_SLAM_VEL_LIMIT_MOD))
	var scaled_damage = FMath.f_lerp(0, WALL_SLAM_MAX_DAMAGE, weight)
	return scaled_damage
		
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
#	if Settings.hard_mode[player_ID]:
#		return 0
	return Settings.input_buffer_time[player_ID]
	
#func tap_memory_duration():
#	if Settings.hard_mode[player_ID]:
#		return 0
#	return TAP_MEMORY_DURATION
	
func buffer_actions():

	if Globals.survival_level != null and Inventory.shop_open:
		return

	if button_left in input_state.just_released:
		release_memory.append([button_left, TAP_MEMORY_DURATION])
	if button_right in input_state.just_released:
		release_memory.append([button_right, TAP_MEMORY_DURATION])
		
	if button_up in input_state.just_pressed:
		if !button_unique in input_state.pressed and Settings.tap_jump[player_ID] == 1:
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
	if Settings.input_assist[player_ID] and (button_up in input_state.just_released or button_down in input_state.just_released):
		match new_state:
			Em.char_state.GROUND_ATK_STARTUP:
				if Animator.time <= 1 and Animator.time != 0:
					rebuffer_actions()
					UniqChar.rebuffer_EX()
			Em.char_state.AIR_ATK_STARTUP:
				if Animator.time <= 5 and Animator.time != 0:
					rebuffer_actions()
					UniqChar.rebuffer_EX()
					
	if button_rs_up in input_state.just_pressed or button_rs_down in input_state.just_pressed or button_rs_left in input_state.just_pressed or \
			button_rs_right in input_state.just_pressed:
		input_buffer.append(["Dodge", buffer_time()])
		
	if spent_special:
		if button_special in input_state.just_pressed or (!button_special in input_state.pressed and \
				!is_button_released_in_last_X_frames(button_special, 7)):
			spent_special = false
	if spent_unique:
		if button_unique in input_state.just_pressed or (!button_unique in input_state.pressed and \
				!is_button_released_in_last_X_frames(button_unique, 7)):
			spent_unique = false
		
		
# SPECIAL ACTIONS --------------------------------------------------------------------------------------------------
		
func capture_combinations():
	
	# instant air dash, place at back
	if Settings.input_assist[player_ID]:
		combination(button_jump, button_dash, "InstaAirDash")
	combination(button_aux, button_dash, "Dodge")
	combination(button_block, button_dash, "SDash")
	
	if !button_unique in input_state.pressed: # this allows you to use Unique + Aux command when blocking without doing a Burst
		combination(button_block, button_aux, "Burst")
#		if button_aux in input_state.just_pressed and alt_block == true:
#			input_buffer.append(["Burst", buffer_time()])
			
#		combination(button_dash, button_aux, "Tech")
		
#	combination(button_block, button_special, "Burst") # place this here since button_special is never buffered
		
	if !button_unique in input_state.pressed:
		UniqChar.capture_combinations()
	else:
		UniqChar.capture_unique_combinations()


#func combination_single(button1, action, back = false): # useful for Special/EX/Super Moves
#	if button1 in input_state.just_pressed:
#		if !back:
#			input_buffer.push_front([action, buffer_time()])
#		else:
#			input_buffer.append([action, buffer_time()])

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
			
			
func ex_rebuffer(button_ex, button1, action, back = false):
	if button1 in input_state.pressed and is_button_released_in_last_X_frames(button_ex, 7):
#		spend_button(button_ex)
		if !back:
			input_buffer.push_front([action, buffer_time()])
		else:
			input_buffer.append([action, buffer_time()])
#
#func ex_rebuffer_trio(button_ex, button1, button2, action, back = false):
#	if button1 in input_state.pressed and button2 in input_state.pressed and is_button_released(button_ex):
#		if !back:
#			input_buffer.push_front([action, buffer_time()])
#		else:
#			input_buffer.append([action, buffer_time()])
			
#func spend_button(button):
#	match button:
#		button_special:
#			spent_special = true
#		button_unique:
#			spent_unique = true

func combination(button1, button2, action, back = false, instant = false):
	if (button1 in input_state.just_pressed and is_button_pressed(button2)) or \
		(button2 in input_state.just_pressed and is_button_pressed(button1)):
#		spend_button(button1)
		if !instant:
			if !back:
				input_buffer.push_front([action, buffer_time()])
			else:
				input_buffer.append([action, buffer_time()])
		else:
			instant_actions_temp.append(action)
		return true
	return false
				
func combination_trio(button1, button2, button3, action, back = false, instant = false):
	if (button1 in input_state.just_pressed and is_button_pressed(button2) and is_button_pressed(button3)) or \
		(button2 in input_state.just_pressed and is_button_pressed(button1) and is_button_pressed(button3)) or \
		(button3 in input_state.just_pressed and is_button_pressed(button1) and is_button_pressed(button2)):
#		spend_button(button1)
		if !instant:
			if !back:
				input_buffer.push_front([action, buffer_time()])
			else:
				input_buffer.append([action, buffer_time()])
		else:
			instant_actions_temp.append(action)
		return true
	return false
	
	
func doubletap_combination(button_ex, button1, action, back = false, instant = false):
	if count_tap(button_ex, 20) >= 2:
		ex_combination(button_ex, button1, action, back, instant)
		
func doubletap_combination_trio(button_ex, button1, button2, action, back = false, instant = false):
	if count_tap(button_ex, 20) >= 2:
		ex_combination_trio(button_ex, button1, button2, action, back, instant)
			
			
func ex_combination(button_ex, button1, action, back = false, instant = false):

	match button_ex:
		button_special:
			if spent_special: return
		button_unique:
			if spent_unique: return

	# for neutral ex move, cannot do it if pressed up/down a few frames before, helps prevent accidental "option selects"
	# like doing ex up-special but it is in aerial_sp_memory, so you end up doing ex neutral-special
	# for ex moves without the light+fierce input, cannot perform if both light and fierce are pressed
	var exclude_buttons = [button_up, button_down]
	if button1 == button_light: exclude_buttons.append(button_fierce)
	elif button1 == button_fierce: exclude_buttons.append(button_light)
	
	for button in exclude_buttons:
		if is_button_tapped_in_last_X_frames(button, 4):
			return
			
	if are_inputs_too_close(): # if last pressed button_ex is too close to last pressed attack button, cannot perform EX
		return
			
	if (button1 in input_state.just_pressed and is_button_released_in_last_X_frames(button_ex, 7)) or \
		(button_ex in input_state.just_released and is_button_pressed(button1)):
		if !instant:
			if !back:
				input_buffer.push_front([action, buffer_time()])
			else:
				input_buffer.append([action, buffer_time()])
		else:
			instant_actions_temp.append(action)

				
func ex_combination_trio(button_ex, button1, button2, action, back = false, instant = false):
	
	match button_ex:
		button_special:
			if spent_special: return
		button_unique:
			if spent_unique: return
	
	if are_inputs_too_close(): # if last pressed button_ex is too close to last pressed attack button, cannot perform EX
		return
	
	if (button1 in input_state.just_pressed and is_button_pressed(button2) and is_button_released_in_last_X_frames(button_ex, 7)) or \
		(button2 in input_state.just_pressed and is_button_pressed(button1) and is_button_released_in_last_X_frames(button_ex, 7)) or \
		(button_ex in input_state.just_released and is_button_pressed(button1) and is_button_pressed(button2)):
		if !instant:
			if !back:
				input_buffer.push_front([action, buffer_time()])
			else:
				input_buffer.append([action, buffer_time()])
		else:
			instant_actions_temp.append(action)
			
func is_button_pressed(button):
#	if Settings.hard_mode[player_ID]:
#		if button in input_state.just_pressed:
#			return true
#		else:
#			return false
			
	if button in [button_light, button_fierce, button_aux]: # for attack buttons, only considered "pressed" a few frame after being tapped
		# so you cannot hold attack and press down to do down-tilts, for instance. Have to hold down and press attack
		if is_button_tapped_in_last_X_frames(button, 7):
			return true
#	elif button == button_up:
#		if Settings.tap_jump[player_ID] == 0: # tap jump off
#			if button in input_state.pressed:
#				return true
#		else: # tap jump on, can only use up-tilts within a few frames of pressing up
#			for tap in tap_memory:
#				if tap[0] == button:
#					return true
#	elif button == button_down:
#		if grounded or Settings.dj_fastfall[player_ID] == 1:
#			if button in input_state.pressed:
#				return true
#		else: # when in air, can only use down-tilts within a few frames of pressing down, unless down+jump fastfall is on
#			for tap in tap_memory:
#				if tap[0] == button:
#					return true
	else:
		if button in input_state.pressed:
			return true
	return false
		
#func is_button_released(button):
#	for release in release_memory:
#		if release[0] == button:
#			return true
#	return false
	
func is_button_released_in_last_X_frames(button, x_time):
	if !Settings.input_assist[player_ID]:
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
	
func are_inputs_too_close():
	var time_of_last_special_or_unique_tap = null
	var time_of_last_attack_tap = null
	
	for x in tap_memory.size():
		var tap = tap_memory[-x-1]
		if tap[1] < TAP_MEMORY_DURATION - 7:
			break
		if tap[0] in [button_special, button_unique]:
			time_of_last_special_or_unique_tap = tap[1]
		elif tap[0] in [button_light, button_fierce, button_aux]:
			time_of_last_attack_tap = tap[1]
			
	if time_of_last_special_or_unique_tap == null or time_of_last_attack_tap == null:
		return false
	elif abs(time_of_last_special_or_unique_tap - time_of_last_attack_tap) <= 1:
		return true
	return false
	
#func get_last_tapped_dir(): # called by entities
#	var left_time = 0
#	var right_time = 0
#	for tap in tap_memory:
#		if tap[0] == button_left and tap[1] > left_time:
#			left_time = tap[1]
#		if tap[0] == button_right and tap[1] > right_time:
#			right_time = tap[1]
#	if left_time < right_time:
#		return 1
#	elif left_time > right_time:
#		return -1
#	else:
#		return 0
	
func capture_and_process_instant_actions(): # capture instant actions after directional keys are read
	instant_actions_temp = [] # clear captured instant actions last frame
	if button_unique in input_state.pressed:
		if Globals.survival_level != null and Inventory.shop_open:
			pass
		else:
			UniqChar.capture_instant_actions() # scan for instant actions and add to instant_actions_temp
	UniqChar.process_instant_actions() # process stored instant actions in instant_actions array last frame
	instant_actions = [] # stored instant_actions last frame are removed
	instant_actions.append_array(instant_actions_temp) # store instant actions captured this frame into instant_actions array
	
# to quick cancel instant actions, some instant actions captured within capture_instant_actions() will cancel certain instant actions that are
# 	stored in instant_actions array
# capturing up/down tilt instant actions will erase neutral instant actions in instant_actions array
# releasing up/down will erase up-tilt/down-tilt instant actions instant_actions array and capture a neutral one

func instant_action_tilt_combination(attack_button, neutral_action, down_tilt_action, up_tilt_action):
	
	if !attack_button in input_state.pressed: return
	
	var down_tilted := false
	var up_tilted := false
	
	if down_tilt_action != null:
		down_tilted = combination_trio(button_unique, button_down, attack_button, down_tilt_action, false, true)
	if !down_tilted and up_tilt_action != null:
		up_tilted = combination_trio(button_unique, button_up, attack_button, up_tilt_action, false, true)
	if !down_tilted and !up_tilted:
		combination(button_unique, attack_button, neutral_action, false, true)
	else:
		if Settings.input_assist[player_ID]:
			instant_actions.erase(neutral_action) # a down_tilt or up_tilt has been captured, erase neutral action captured last frame
	
	if Settings.input_assist[player_ID]:
		# releasing up/down will erase up-tilt/down-tilt instant actions instant_actions array and capture a neutral one
		if down_tilt_action != null and button_down in input_state.just_released and down_tilt_action in instant_actions:
			instant_actions.erase(down_tilt_action)
			instant_actions_temp.append(neutral_action)
		elif up_tilt_action != null and button_up in input_state.just_released and up_tilt_action in instant_actions:
			instant_actions.erase(up_tilt_action)
			instant_actions_temp.append(neutral_action)
		
func cancel_action(button_ex = null): # called from UniqChar for character-unique action cancelling
	if button_ex != null:
		match button_ex: # prevent special/unique from triggering EX moves
			button_special:
				spent_special = true
			button_unique:
				spent_unique = true
	input_buffer = []
	startup_cancel_flag = true
	afterimage_cancel()
	if grounded:
		animate("Idle")
	else:
		animate("FallTransit")
	
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
				if Animator.query(["JumpTransit", "aJumpTransit"]): # consume buffered jumps during jump transits
					keep = false
					continue
				if !has_acted[0]:
					match new_state:
						
						# JUMPING ON GROUND --------------------------------------------------------------------------------------------------
						
						Em.char_state.GROUND_STANDBY, Em.char_state.CROUCHING, Em.char_state.GROUND_C_REC:
							if button_down in input_state.pressed and soft_grounded:
			#							!Character.button_left in Character.input_state.pressed and \f
			#							!Character.button_right in Character.input_state.pressed: # don't use dir
								
								# fallthrough
#								if new_state in [Em.char_state.GROUND_STANDBY, Em.char_state.CROUCHING, \
#										Em.char_state.GROUND_C_REC]:
								position.y += 2 # 1 will cause issues with downward moving platforms
								set_true_position()
								animate("FallTransit")
								grounded = false # need to do this since moving outside of the end of simulate2()
								keep = false
									
							if keep:
								animate("JumpTransit") # ground jump
								if button_dash in input_state.pressed: # for wavedash alternate input
									input_buffer.append([button_dash, buffer_time()])
									
								keep = false
								
						Em.char_state.GROUND_BLOCK:
							if Settings.input_assist[player_ID] and Animator.time <= 1:
								animate("JumpTransit") 
								keep = false
							
						# BUFFERING AN INSTANT AIRDASH ---------------------------------------------------------------------------------
							
						Em.char_state.GROUND_D_REC:
							if Settings.input_assist[player_ID] and Animator.time == 0:
								animate("JumpTransit")
								input_to_add.append([button_dash, buffer_time()])
								has_acted[0] = true
								keep = false
								
						# AIR JUMPS  --------------------------------------------------------------------------------------------------
			
						Em.char_state.AIR_STANDBY, Em.char_state.AIR_C_REC:
#							if grounded:
#								animate("JumpTransit") # ground jump
#								keep = false
#								continue
							
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
#								input_to_add.append([button_dash, buffer_time()])
#								keep = false
								
						# AIR JUMPS  --------------------------------------------------------------------------------------------------
								
							elif air_jump > 0 and !button_dash in input_state.pressed: # no dash for easier wavedashing
								animate("aJumpTransit")
								keep = false
								
						# AERIAL AIR JUMP CANCEL ---------------------------------------------------------------------------------
							
						Em.char_state.AIR_ATK_REC:
							if Settings.dj_fastfall[player_ID] == 1 and button_down in input_state.pressed:
								continue
								
							if test_jump_cancel():
								animate("aJumpTransit")
								keep = false
								
						Em.char_state.AIR_ATK_ACTIVE: # some attacks can jump cancel on active frames
							if active_cancel:
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
								
						Em.char_state.GROUND_ATK_REC:
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
						
						Em.char_state.GROUND_ATK_ACTIVE: # some attacks can jump cancel on active frames
							if active_cancel:
								afterimage_cancel()
								animate("JumpTransit")
								keep = false
								
						Em.char_state.GROUND_ATK_STARTUP: # can quick jump cancel the 1st few frame of ground attacks, helps with instant aerials
							if !Settings.input_assist[player_ID]:
								continue
							if chain_memory.size() != 0:
								continue # cannot quick jump cancel attacks in chains
							var move_name = get_move_name()
							if move_name in UniqChar.STARTERS and !is_ex_move(move_name) and !is_super(move_name):
								if Animator.time <= 1 and Animator.time != 0:
									animate("JumpTransit")
									rebuffer_actions() # this buffers the attack buttons currently being pressed

									
			# FOR NON_JUMP ACTIONS --------------------------------------------------------------------------------------------------
		
			"Burst":
				if Animator.current_anim.begins_with("Burst"):
					keep = false
				else:
					match state: # not new state
						Em.char_state.GROUND_STANDBY, Em.char_state.CROUCHING, Em.char_state.GROUND_C_REC, \
							Em.char_state.AIR_STANDBY, Em.char_state.AIR_C_REC, \
							Em.char_state.GROUND_BLOCK, Em.char_state.AIR_BLOCK, \
							Em.char_state.GROUND_REC, Em.char_state.AIR_REC, \
							Em.char_state.GROUND_D_REC, Em.char_state.AIR_D_REC:
#							if state in [Em.char_state.GROUND_BLOCK, Em.char_state.AIR_BLOCK] and \
#									button_dash in input_state.pressed:
#								continue # to make fdashing out of block easier
							if burst_counter_check():
								animate("BurstCounterStartup")
								has_acted[0] = true
								keep = false
								
#						Em.char_state.AIR_REC: # can Burst Counter during teching
#							if Animator.query_current(["Tech"]):
#								if burst_counter_check():
#									animate("BurstCounterStartup")
#									has_acted[0] = true
#									keep = false
								
						Em.char_state.GROUND_FLINCH_HITSTUN, Em.char_state.AIR_FLINCH_HITSTUN, Em.char_state.LAUNCHED_HITSTUN:
							if burst_escape_check():
								animate("BurstEscapeStartup")
								has_acted[0] = true
								keep = false
								
						# can Burst Counter if attack is blocked
						Em.char_state.GROUND_ATK_REC, Em.char_state.AIR_ATK_REC:
							if chain_combo in [Em.chain_combo.NORMAL, Em.chain_combo.WEAKBLOCKED, \
									Em.chain_combo.STRONGBLOCKED] and burst_counter_check():
								animate("BurstCounterStartup")
								has_acted[0] = true
								keep = false
							else: continue

#						Em.char_state.GROUND_ATK_STARTUP, Em.char_state.AIR_ATK_STARTUP, \
#								Em.char_state.GROUND_ATK_REC, Em.char_state.AIR_ATK_REC, \
#								Em.char_state.GROUND_ATK_ACTIVE, Em.char_state.AIR_ATK_ACTIVE:
#							if is_attacking(): # new state must not be standby
#								var move_name = get_move_name()
#								if burst_extend_check(move_name):
#									animate("BurstExtend")
#									has_acted[0] = true
#									keep = false
									
			"SDash":
				if is_attacking(): # new state must not be standby
					match state:
#						Em.char_state.GROUND_ATK_STARTUP, Em.char_state.AIR_ATK_STARTUP, \
#								Em.char_state.GROUND_ATK_REC, Em.char_state.AIR_ATK_REC, \
#								Em.char_state.GROUND_ATK_ACTIVE, Em.char_state.AIR_ATK_ACTIVE:
#								var move_name = get_move_name()
#								if a_reset_check(move_name):
#									animate("AReset")
#									has_acted[0] = true
#									keep = false
#								else:
#									continue
						Em.char_state.GROUND_ATK_STARTUP, Em.char_state.AIR_ATK_STARTUP, \
								Em.char_state.GROUND_ATK_ACTIVE, Em.char_state.AIR_ATK_ACTIVE, \
								Em.char_state.GROUND_ATK_REC, Em.char_state.AIR_ATK_REC:
							if test_sdash_cancel():
								animate("SDashTransit")
								has_acted[0] = true
								keep = false
								
				if keep:
					match new_state:
						Em.char_state.GROUND_STANDBY, Em.char_state.CROUCHING, Em.char_state.GROUND_C_REC, \
								Em.char_state.AIR_STANDBY, Em.char_state.AIR_C_REC, \
								Em.char_state.GROUND_STARTUP, Em.char_state.AIR_STARTUP, \
								Em.char_state.GROUND_REC, Em.char_state.AIR_REC, \
								Em.char_state.GROUND_D_REC, Em.char_state.AIR_D_REC, \
								Em.char_state.GROUND_BLOCK, Em.char_state.AIR_BLOCK:
							if new_state in [Em.char_state.GROUND_STARTUP, Em.char_state.AIR_STARTUP]:
								if !Settings.input_assist[player_ID]:
									continue
								if !Animator.query_to_play(["JumpTransit", "aJumpTransit", "DashTransit", "aDashTransit"]):
									continue # can only cancel from Transits for GROUND_STARTUP/AIR_STARTUP
							if new_state in [Em.char_state.GROUND_REC, Em.char_state.AIR_REC]:
								if !Animator.query_to_play(["BlockRec", "aBlockRec"]):
									continue # can only cancel from certain non-attack recovery frames
							if grounded or super_dash > 0:
								animate("SDashTransit")
								has_acted[0] = true
								keep = false
									
									
			"Dodge":
				match new_state:
					Em.char_state.GROUND_STANDBY, Em.char_state.CROUCHING, Em.char_state.GROUND_C_REC, \
							Em.char_state.AIR_STANDBY, Em.char_state.AIR_C_REC, \
							Em.char_state.GROUND_STARTUP, Em.char_state.AIR_STARTUP, \
							Em.char_state.GROUND_BLOCK, Em.char_state.AIR_BLOCK, Em.char_state.GROUND_D_REC:
						if new_state in [Em.char_state.GROUND_STARTUP, Em.char_state.AIR_STARTUP]:
							if !Settings.input_assist[player_ID]:
								continue
							if !Animator.query_to_play(["JumpTransit", "aJumpTransit", "DashTransit", "aDashTransit"]):
								continue # can only cancel from Transits for GROUND_STARTUP/AIR_STARTUP
						if new_state == Em.char_state.GROUND_D_REC:
							if !Settings.input_assist[player_ID]:
								continue
							if Animator.time > 0:
								continue # can cancel from 1st frame of ground dash
						if new_state in [Em.char_state.GROUND_BLOCK, Em.char_state.AIR_BLOCK]:
							if !Settings.input_assist[player_ID]:
								continue
							if !Animator.query_to_play(["BlockStartup", "aBlockStartup"]):
								continue # can only cancel from block startup for GROUND_BLOCK/AIR_BLOCK	
						if dodge_check():
							animate("DodgeTransit")
							has_acted[0] = true
							keep = false
							
					Em.char_state.GROUND_ATK_REC, Em.char_state.AIR_ATK_REC:
						if test_dodge_cancel() and dodge_check():
							animate("DodgeTransit")
							has_acted[0] = true
							keep = false
							
#			"FDash":
#				match new_state:
#					Em.char_state.GROUND_STANDBY, Em.char_state.CROUCHING, Em.char_state.GROUND_C_REC, \
#							Em.char_state.AIR_STANDBY, Em.char_state.AIR_C_REC, \
#							Em.char_state.GROUND_STARTUP, Em.char_state.AIR_STARTUP, \
#							Em.char_state.GROUND_REC, Em.char_state.AIR_REC, \
#							Em.char_state.GROUND_BLOCK, Em.char_state.AIR_BLOCK:
#						if new_state in [Em.char_state.GROUND_STARTUP, Em.char_state.AIR_STARTUP] and \
#								!Animator.query_to_play(["JumpTransit", "aJumpTransit", "DashTransit", "aDashTransit"]):
#							continue # can only cancel from Transits for GROUND_STARTUP/AIR_STARTUP
#						if new_state in [Em.char_state.GROUND_REC, Em.char_state.AIR_REC] and \
#								!Animator.query_to_play(["BlockRec", "aBlockRec", "Dash", "aDash"]):
#							continue # can only cancel from certain non-attack recovery frames
#						if flying_dash > 0:
#							animate("FDashTransit")
#							has_acted[0] = true
#							keep = false

						
			_:
				# pass to process_buffered_input() in unique character node, it returns a bool of whether input should be kept
				# some special buttons can also add new buffered inputs, this are added at the end
				if !UniqChar.process_buffered_input(new_state, buffered_input, input_to_add, has_acted):
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

	var old_new_state = new_state
	
	Animator.play(anim)
	new_state = state_detect(anim)
	
	if anim.ends_with("Active"):
		atk_startup_resets() # need to do this here to work! resets hitcount and ignore list

	# when changing to a non-attacking state from attack startup, auto-buffer pressed attack buttons
	if Settings.input_assist[player_ID] and !startup_cancel_flag and !is_attacking():
		match old_new_state:
			Em.char_state.GROUND_ATK_STARTUP, Em.char_state.AIR_ATK_STARTUP:
				rebuffer_actions()

			
func rebuffer_actions():
	
	if button_light in input_state.pressed:
		input_buffer.append([button_light, buffer_time()])
	if button_fierce in input_state.pressed:
		input_buffer.append([button_fierce, buffer_time()])
	if button_aux in input_state.pressed:
		input_buffer.append([button_aux, buffer_time()])
	
	UniqChar.rebuffer_actions()
	

func query_state(query_states: Array):
	for x in query_states:
		if state == x or new_state == x:
			return true
	return false

func state_detect(anim):
	match anim:
		# universal animations
		"Idle", "RunTransit", "Run", "Brake":
			return Em.char_state.GROUND_STANDBY
		"CrouchTransit", "Crouch", "CrouchReturn":
			return Em.char_state.CROUCHING
		"JumpTransit", "DashTransit":
			return Em.char_state.GROUND_STARTUP
		"Dash", "Dash2":
			return Em.char_state.GROUND_D_REC
		"BlockRec":
			return Em.char_state.GROUND_REC
		"SoftLanding", "DashBrake", "WaveDashBrake", "BlockCRec", "HardLanding":
			return Em.char_state.GROUND_C_REC
			
		"JumpTransit3","aJumpTransit3", "Jump", "FallTransit", "Fall", "FastFallTransit", "FastFall":
			return Em.char_state.AIR_STANDBY
		"aJumpTransit", "WallJumpTransit", "aJumpTransit2", "WallJumpTransit2", "aDashTransit", "JumpTransit2", "DodgeTransit":
			# ground/air jumps have 1 frame of AIR_STARTUP after lift-off to delay actions like instant air dash/wavedashing
			return Em.char_state.AIR_STARTUP
		"aDash", "aDashD", "aDashU", "aDashDD", "aDashUU":
			return Em.char_state.AIR_D_REC
		"aBlockRec", "Dodge", "DodgeRec":
			return Em.char_state.AIR_REC
		"aDashBrake", "aBlockCRec", "DodgeCRec":
			return Em.char_state.AIR_C_REC
			
		"FlinchAStop", "FlinchA", "FlinchBStop", "FlinchB":
			return Em.char_state.GROUND_FLINCH_HITSTUN
		"FlinchAReturn", "FlinchBReturn":
			return Em.char_state.GROUND_C_REC
		"aFlinchAStop", "aFlinchA", "aFlinchBStop", "aFlinchB":
			return Em.char_state.AIR_FLINCH_HITSTUN
		"aFlinchAReturn", "aFlinchBReturn":
			return Em.char_state.AIR_C_REC
		"LaunchStop", "LaunchTransit", "Launch":
			return Em.char_state.LAUNCHED_HITSTUN
		
		"SeqFlinchAFreeze", "SeqFlinchBFreeze":
			return Em.char_state.SEQUENCE_TARGET
		"SeqFlinchAStop", "SeqFlinchA", "SeqFlinchBStop", "SeqFlinchB":
			return Em.char_state.SEQUENCE_TARGET
		"aSeqFlinchAFreeze", "aSeqFlinchBFreeze":
			return Em.char_state.SEQUENCE_TARGET
		"aSeqFlinchAStop", "aSeqFlinchA", "aSeqFlinchBStop", "aSeqFlinchB":
			return Em.char_state.SEQUENCE_TARGET
		"SeqLaunchFreeze":
			return Em.char_state.SEQUENCE_TARGET
		"SeqLaunchStop", "SeqLaunchTransit", "SeqLaunch":
			return Em.char_state.SEQUENCE_TARGET
			
		"BlockStartup":
			return Em.char_state.GROUND_BLOCK
		"aBlockStartup":
			return Em.char_state.AIR_BLOCK
		"Block", "BlockLanding":
			return Em.char_state.GROUND_BLOCK
		"aBlock":
			return Em.char_state.AIR_BLOCK
			
		"BurstCounterStartup", "BurstEscapeStartup":
			return Em.char_state.AIR_STARTUP
		"BurstCounter", "BurstEscape", "BurstAwakening":
			return Em.char_state.AIR_REC
		"BurstRec":
			return Em.char_state.AIR_REC
		"BurstCRec":
			return Em.char_state.AIR_C_REC
			
		"SDash":
			return Em.char_state.AIR_REC
		"SDashTransit":
			return Em.char_state.AIR_STARTUP
			
		_: # unique animations
			return UniqChar.state_detect(anim)
			
	
# ---------------------------------------------------------------------------------------------------

func get_seq_partner():
	var Partner = Globals.Game.get_player_node(seq_partner_ID)
	if Partner == null or Partner == self: return null
	if Partner.seq_partner_ID != player_ID: return null
	return Partner
	
func get_target():
	if Globals.survival_level == null:
		var target = Globals.Game.get_player_node(target_ID)
		if target.state == Em.char_state.DEAD:
			return self
		else:
			return target
			
	else: # get targeted mob
		if target_ID != null and target_ID != player_ID:
			var target_node = Globals.Game.get_player_node(target_ID)
			if target_node != null and target_node.state != Em.char_state.DEAD:
				return target_node
				
		# not yet target a mob, or targeted mob is dead
		if Globals.Game.get_node("Players").get_children().size() == Globals.player_count:
			target_ID = player_ID
			return self # no mobs, target self
		else: # find closest alive mob
			var targets = get_tree().get_nodes_in_group("MobNodes")
			for target in targets:
				if target.state == Em.char_state.DEAD:
					targets.erase(target)
			if targets.size() == 0:
				return self # no mobs, target self
			else:
				var target_node = FMath.get_closest(targets, position)
				target_ID = target_node.player_ID
				return target_node
			
			
#func get_surv_stat(stat: String):
#	var to_return = get(stat)
#
#	match stat:
#		_:
#			pass
#
#	return to_return

# MODIFERS AND ENHANCE -----------------------------------------------------------------------------------------------------------------

func get_stat(stat: String) -> int:
	
	var to_return
	
	if stat in self:
		to_return = get(stat)
	elif stat in UniqChar:
		to_return = UniqChar.get_stat(stat)
		
	if Globals.survival_level != null:
		match stat:
			"SPECIAL_GDRAIN_MOD":
				to_return = FMath.percent(to_return, 150) # increased GDrain on specials during Survival
				if Inventory.has_quirk(player_ID, Cards.effect_ref.BETTER_BLOCK):
					to_return = FMath.percent(to_return, 50)
			"DAMAGE_VALUE_LIMIT":
#				var hp_mod_array = [55, 60, 65, 70, 75, 80, 85, 90, 95, 100] 
#				to_return = FMath.percent(to_return, hp_mod_array[Globals.Game.LevelControl.wave_ID - 1])
#				if Globals.survival_level != null: to_return = FMath.percent(to_return, 60)
				to_return = FMath.percent(to_return, Inventory.modifier(player_ID, Cards.effect_ref.HP))
#				to_return = 99999
				to_return = int(max(to_return, 1))
		
			"SPEED":
#				if Globals.survival_level != null: to_return = FMath.percent(to_return, 90)
				to_return = FMath.percent(to_return, Inventory.modifier(player_ID, Cards.effect_ref.SPEED))
				to_return = int(max(to_return, 10))
			"JUMP_SPEED":
#				if Globals.survival_level != null: to_return = FMath.percent(to_return, 90)
				to_return = FMath.percent(to_return, Inventory.modifier(player_ID, Cards.effect_ref.JUMP_SPEED))
				to_return = int(max(to_return, 10))
			"GRAVITY_MOD":
				to_return = FMath.percent(to_return, Inventory.modifier(player_ID, Cards.effect_ref.GRAVITY_MOD))
				to_return = int(max(to_return, 10))
			"FRICTION":
				to_return = FMath.percent(to_return, Inventory.modifier(player_ID, Cards.effect_ref.FRICTION))
				to_return = int(max(to_return, 10))
				
			"MAX_AIR_JUMP":
#				if Globals.survival_level != null: to_return = int(max(to_return - 1, 1))
				to_return += Inventory.modifier(player_ID, Cards.effect_ref.MAX_AIR_JUMP)
				to_return = int(max(to_return, 0))
			"MAX_AIR_DASH":
#				if Globals.survival_level != null: to_return = int(max(to_return - 1, 1))
				to_return += Inventory.modifier(player_ID, Cards.effect_ref.MAX_AIR_DASH)
				to_return = int(max(to_return, 0))
			"MAX_AIR_DODGE":
#				if Globals.survival_level != null: to_return = int(max(to_return - 1, 1))
				to_return += Inventory.modifier(player_ID, Cards.effect_ref.MAX_AIR_DODGE)
				to_return = int(max(to_return, 0))
			"MAX_SUPER_DASH":
#				if Globals.survival_level != null: to_return = int(max(to_return - 1, 1))
				to_return += Inventory.modifier(player_ID, Cards.effect_ref.MAX_SUPER_DASH)
				to_return = int(max(to_return, 0))
				
			"GROUND_DASH_SPEED":
#				if Globals.survival_level != null: to_return = FMath.percent(to_return, 90)
				to_return = FMath.percent(to_return, Inventory.modifier(player_ID, Cards.effect_ref.GROUND_DASH_SPEED))
				to_return = int(max(to_return, 10))
			"AIR_DASH_SPEED":
#				if Globals.survival_level != null: to_return = FMath.percent(to_return, 90)
				to_return = FMath.percent(to_return, Inventory.modifier(player_ID, Cards.effect_ref.AIR_DASH_SPEED))
				to_return = int(max(to_return, 10))
			"SDASH_SPEED":
#				if Globals.survival_level != null: to_return = FMath.percent(to_return, 90)
				to_return = FMath.percent(to_return, Inventory.modifier(player_ID, Cards.effect_ref.SDASH_SPEED))
				to_return = int(max(to_return, 10))
#			"SDASH_TURN_RATE":
#				if Globals.survival_level != null: to_return = int(max(to_return - 4, 1))
#				to_return += Inventory.modifier(player_ID, Cards.effect_ref.SDASH_TURN_RATE)
			"DODGE_GG_COST":
#				if Globals.survival_level != null: to_return = FMath.percent(to_return, 120)
#				to_return = FMath.percent(to_return, Inventory.modifier(player_ID, Cards.effect_ref.DODGE_GG_COST))
#				to_return = int(max(to_return, 0))
				if Inventory.has_quirk(player_ID, Cards.effect_ref.NO_DODGE_COST):
					to_return = 0
			"DODGE_SPEED":
#				if Globals.survival_level != null: to_return = FMath.percent(to_return, 90)
				to_return = FMath.percent(to_return, Inventory.modifier(player_ID, Cards.effect_ref.DODGE_SPEED))
				to_return = int(max(to_return, 10))
	
#			"GG_REGEN_AMOUNT":
##				if Globals.survival_level != null: to_return = FMath.percent(to_return, 60)
#				if Inventory.has_quirk(player_ID, Cards.effect_ref.BETTER_BLOCK):
#					to_return = FMath.percent(to_return, 200)
				
			"GROUND_BLOCK_GG_COST", "AIR_BLOCK_GG_COST":
#				if Globals.survival_level != null: to_return = FMath.percent(to_return, 120)
#				to_return = FMath.percent(to_return, Inventory.modifier(player_ID, Cards.effect_ref.BLOCK_GG_COST))
#				to_return = int(max(to_return, 0))
				if Inventory.has_quirk(player_ID, Cards.effect_ref.NO_BLOCK_COST):
					to_return = 0
			"WEAKBLOCK_CHIP_DMG_MOD":
#				if Globals.survival_level != null: to_return = FMath.percent(to_return, 120)
#				to_return = FMath.percent(to_return, Inventory.modifier(player_ID, Cards.effect_ref.WEAKBLOCK_CHIP_DMG_MOD))
#				to_return = int(max(to_return, 0))
				if Inventory.has_quirk(player_ID, Cards.effect_ref.NO_CHIP_DMG):
					to_return = 0
					
			"LANDED_EX_REGEN_MOD":
				to_return = FMath.percent(to_return, Inventory.modifier(player_ID, Cards.effect_ref.LANDED_EX_REGEN))
			"HITSTUN_EX_REGEN_MOD":
				to_return = FMath.percent(to_return, Inventory.modifier(player_ID, Cards.effect_ref.HITSTUN_EX_REGEN))
				
	return to_return
	
				
func has_trait(trait: int) -> bool:
	if trait in UniqChar.query_traits():
		return true
		
	return false
					
		
func mod_damage(move_name):
	var mod := 100
	
	if Inventory.has_quirk(player_ID, Cards.effect_ref.REVENGE):
		var percent = get_damage_percent()
		if percent > 50:
			var weight = FMath.get_fraction_percent(percent - 50, 50)
			mod += FMath.f_lerp(100, 300, weight)
			
	if Inventory.has_quirk(player_ID, Cards.effect_ref.EX_RAISE_DMG):
		var weight = FMath.get_fraction_percent(current_ex_gauge, MAX_EX_GAUGE)
		mod += FMath.f_lerp(0, 100, weight)

	
	match UniqChar.MOVE_DATABASE[move_name][Em.move.ATK_TYPE]:
		Em.atk_type.LIGHT:
			mod += Inventory.modifier(player_ID, Cards.effect_ref.LIGHT_DMG_MOD, true)
			if move_name.begins_with("a"):
				mod += Inventory.modifier(player_ID, Cards.effect_ref.AIR_NORMAL_DMG_MOD, true)
			else:
				mod += Inventory.modifier(player_ID, Cards.effect_ref.GROUND_NORMAL_DMG_MOD, true)
				
		Em.atk_type.FIERCE:
			mod += Inventory.modifier(player_ID, Cards.effect_ref.FIERCE_DMG_MOD, true)
			if move_name.begins_with("a"):
				mod += Inventory.modifier(player_ID, Cards.effect_ref.AIR_NORMAL_DMG_MOD, true)
			else:
				mod += Inventory.modifier(player_ID, Cards.effect_ref.GROUND_NORMAL_DMG_MOD, true)
				
		Em.atk_type.HEAVY:
			mod += Inventory.modifier(player_ID, Cards.effect_ref.HEAVY_DMG_MOD, true)
				
		Em.atk_type.SPECIAL, Em.atk_type.EX:
			mod += Inventory.modifier(player_ID, Cards.effect_ref.SPECIAL_DMG_MOD, true)
			
		Em.atk_type.SUPER:
			mod += Inventory.modifier(player_ID, Cards.effect_ref.SUPER_DMG_MOD, true)
			
	mod = int(max(mod, 0))
	return mod
	
	
func enhance_cooldown():
	for cooldown in enhance_cooldowns.keys():
		enhance_cooldowns[cooldown] -= 1
		if enhance_cooldowns[cooldown] <= 0:
# warning-ignore:return_value_discarded
			enhance_cooldowns.erase(cooldown)
	
func enhance_card(effect_ref: int, skip_cooldown = false):
	match effect_ref:
		Cards.effect_ref.SUMMON_SHARK:
			if !Cards.effect_ref.SUMMON_SHARK in enhance_cooldowns:
				var spawn_point = position
				spawn_point = Detection.ground_finder(spawn_point, facing, Vector2(0, 150), Vector2(10, 300), 1)
				if spawn_point != null:
#					func spawn_entity(master_ID: int, entity_ref: String, out_position, aux_data: Dictionary, palette_ref = null, master_ref = null):
					Globals.Game.spawn_entity(player_ID, "NibblerSpawnE", spawn_point, {})
					play_audio("water15", {})
					if !skip_cooldown:
						enhance_cooldowns[Cards.effect_ref.SUMMON_SHARK] = Cards.SHARK_COOLDOWN
		Cards.effect_ref.SUMMON_HORROR:
			if !Cards.effect_ref.SUMMON_HORROR in enhance_cooldowns:
				var target = get_target()
				if target != null and target != self:
					Globals.Game.spawn_entity(player_ID, "HorrorE", get_target().position, {})
					if !skip_cooldown:
						enhance_cooldowns[Cards.effect_ref.SUMMON_HORROR] = Cards.HORROR_COOLDOWN
		Cards.effect_ref.KERIS_PROJ:
			if !Cards.effect_ref.KERIS_PROJ in enhance_cooldowns:
				Globals.Game.spawn_entity(player_ID, "KerisE", position + Vector2(50, -50), {})
				Globals.Game.spawn_entity(player_ID, "KerisE", position + Vector2(-50, -50), {})
				play_audio("bling5", {"vol" : -10})
				if !skip_cooldown:
					enhance_cooldowns[Cards.effect_ref.KERIS_PROJ] = Cards.KERIS_COOLDOWN
		Cards.effect_ref.SCYTHE_PROJ:
			if !Cards.effect_ref.SCYTHE_PROJ in enhance_cooldowns:
				Globals.Game.spawn_entity(player_ID, "ScytheE", position, {})
				play_audio("whoosh7", {"vol" : -10})
				if !skip_cooldown:
					enhance_cooldowns[Cards.effect_ref.SCYTHE_PROJ] = Cards.SCYTHE_COOLDOWN
		Cards.effect_ref.PHOENIX_PROJ:
			if !Cards.effect_ref.PHOENIX_PROJ in enhance_cooldowns:
				if grounded:
					Globals.Game.spawn_entity(player_ID, "PhoenixFeatherE", position + Vector2(25 * facing, 0), {})
					Globals.Game.spawn_entity(player_ID, "PhoenixFeatherE", position + Vector2(23 * facing, -8), {"ground2":true})
					Globals.Game.spawn_entity(player_ID, "PhoenixFeatherE", position + Vector2(21 * facing, -15), {"ground3":true})
				else:
					Globals.Game.spawn_entity(player_ID, "PhoenixFeatherE", position + Vector2(25 * facing, 0), {})
					Globals.Game.spawn_entity(player_ID, "PhoenixFeatherE", position + Vector2(25 * facing, 10), {"air2":true})
					Globals.Game.spawn_entity(player_ID, "PhoenixFeatherE", position + Vector2(25 * facing, -10), {"air3":true})
				if !skip_cooldown:
					enhance_cooldowns[Cards.effect_ref.PHOENIX_PROJ] = Cards.PHOENIX_COOLDOWN
		Cards.effect_ref.PEACOCK_PROJ:
			if !Cards.effect_ref.PEACOCK_PROJ in enhance_cooldowns:
				Globals.Game.spawn_entity(player_ID, "PeacockFeatherE", position + Vector2(40 * facing, 0), {})
				Globals.Game.spawn_entity(player_ID, "PeacockFeatherE", position + Vector2(-40 * facing, 0), {"alt":true})
				Globals.Game.spawn_entity(player_ID, "PeacockFeatherE", position + Vector2(25 * facing, -35), {"alt":true})
				Globals.Game.spawn_entity(player_ID, "PeacockFeatherE", position + Vector2(-25 * facing, -35), {})
				play_audio("bling5", {"vol" : -10})
				if !skip_cooldown:
					enhance_cooldowns[Cards.effect_ref.PEACOCK_PROJ] = Cards.PEACOCK_COOLDOWN
		Cards.effect_ref.RAIN_PROJ:
			Globals.Game.spawn_entity(player_ID, "WaterBulletE", get_feet_pos(), {})
		Cards.effect_ref.TIME_BUBBLE:
			if !Cards.effect_ref.TIME_BUBBLE in enhance_cooldowns:
				var field_id = Globals.Game.spawn_field(player_ID, "TimeBubbleE", position, {}).entity_ID
				Globals.Game.spawn_SFX("TimeBubbleTop", "TimeBubbleTop", position, {"field": true, "sticky_ID": field_id, "sticky_entity" : true})
				if !skip_cooldown:
					enhance_cooldowns[Cards.effect_ref.TIME_BUBBLE] = Cards.TIME_BUBBLE_COOLDOWN
		Cards.effect_ref.VORTEX:
			if !Cards.effect_ref.VORTEX in enhance_cooldowns:
				Globals.Game.spawn_field(player_ID, "VortexE", get_target().position, {})
				if !skip_cooldown:
					enhance_cooldowns[Cards.effect_ref.VORTEX] = Cards.VORTEX_COOLDOWN
		Cards.effect_ref.REWIND:
			if !Cards.effect_ref.REWIND in enhance_cooldowns:
				if "rewind" in enhance_data and Globals.Game.frametime - enhance_data.rewind.frametime <= Cards.REWIND_RANGE:
					Globals.Game.spawn_SFX("RewindEffect", "RewindEffect", position, {})
					var to_loaded_state = enhance_data.rewind.saved_state.duplicate(true)
					load_state(to_loaded_state, true)
# warning-ignore:return_value_discarded
					enhance_data.erase("rewind")
					Globals.Game.spawn_SFX("RewindEffect", "RewindEffect", position, {})
					play_audio("shutter1", {"vol" : -3})
					if !skip_cooldown:
						enhance_cooldowns[Cards.effect_ref.REWIND] = Cards.REWIND_COOLDOWN
		Cards.effect_ref.SUMMON_TAKO:
			if !Cards.effect_ref.SUMMON_TAKO in enhance_cooldowns:
				var random = Globals.Game.rng_generate(4)
				var rand_facing = Globals.Game.rng_facing()
				if random == 0:
					Globals.Game.spawn_entity(player_ID, "TakoGateE", get_target().position + Vector2(0, -100), \
							{"facing":rand_facing, "alt1":true})
				elif random == 1:
					Globals.Game.spawn_entity(player_ID, "TakoGateE", get_target().position + Vector2(70 * -rand_facing, -50), \
							{"facing":rand_facing, "alt2":true})
				elif random == 2:
					Globals.Game.spawn_entity(player_ID, "TakoGateE", get_target().position + Vector2(100 * -rand_facing, 0), \
							{"facing":rand_facing, "alt3":true})
				else:
					Globals.Game.spawn_entity(player_ID, "TakoGateE", get_target().position + Vector2(0, 70), \
							{"facing":rand_facing, "alt4":true})
				if !skip_cooldown:
					enhance_cooldowns[Cards.effect_ref.SUMMON_TAKO] = Cards.TAKO_COOLDOWN
					
		Cards.effect_ref.TBLOCK_PROJ:
			if !Cards.effect_ref.TBLOCK_PROJ in enhance_cooldowns:
				Globals.Game.spawn_entity(player_ID, "TBlockE", get_target().position + Vector2(0, -100), {})
				play_audio("bling5", {"vol" : -10})
				if !skip_cooldown:
					enhance_cooldowns[Cards.effect_ref.TBLOCK_PROJ] = Cards.TBLOCK_COOLDOWN
				
		Cards.effect_ref.FLASK_PROJ:
			if !Cards.effect_ref.FLASK_PROJ in enhance_cooldowns:
				Globals.Game.spawn_entity(player_ID, "FlaskE", position, {})
				play_audio("bling5", {"vol" : -10})
				if !skip_cooldown:
					enhance_cooldowns[Cards.effect_ref.FLASK_PROJ] = Cards.FLASK_COOLDOWN
					
		Cards.effect_ref.SUMMON_SSRB:
			if !Cards.effect_ref.SUMMON_SSRB in enhance_cooldowns:
				Globals.Game.spawn_entity(player_ID, "SsrbE", position, {})
				play_audio("bling5", {"vol" : -10})
				if !skip_cooldown:
					enhance_cooldowns[Cards.effect_ref.SUMMON_SSRB] = Cards.SSRB_COOLDOWN
					
		Cards.effect_ref.SUMMON_NOUSAGI:
			if !Cards.effect_ref.SUMMON_NOUSAGI in enhance_cooldowns:
				Globals.Game.spawn_entity(player_ID, "NousagiE", position, {})
				play_audio("bling5", {"vol" : -10})
				if !skip_cooldown:
					enhance_cooldowns[Cards.effect_ref.SUMMON_NOUSAGI] = Cards.NOUSAGI_COOLDOWN
				
func timed_enhance():
	if Inventory.has_quirk(player_ID, Cards.effect_ref.SUMMON_SHARK):
		enhance_card(Cards.effect_ref.SUMMON_SHARK)
		
	if Inventory.has_quirk(player_ID, Cards.effect_ref.SUMMON_TAKO):
		enhance_card(Cards.effect_ref.SUMMON_TAKO)
	
	if Inventory.has_quirk(player_ID, Cards.effect_ref.REWIND):
		if !is_hitstunned_or_sequenced2():
			if !"rewind" in enhance_data:
				enhance_data["rewind"] = {
					"frametime" : Globals.Game.frametime,
					"saved_state" : save_state().duplicate(true)
				}
			else:
				if Globals.Game.frametime - enhance_data.rewind.frametime >= Cards.REWIND_RANGE:
# warning-ignore:return_value_discarded
					enhance_data.erase("rewind")
					enhance_data["rewind"] = {
						"frametime" : Globals.Game.frametime,
						"saved_state" : save_state().duplicate(true)
					}
	
		
func being_hit_enhance():
	if Inventory.has_quirk(player_ID, Cards.effect_ref.SUMMON_HORROR):
		enhance_card(Cards.effect_ref.SUMMON_HORROR)
	if Inventory.has_quirk(player_ID, Cards.effect_ref.REWIND):
		enhance_card(Cards.effect_ref.REWIND)
		
func attack_enhance(atk_type: int):
	match atk_type:
		Em.atk_type.LIGHT:
			if Inventory.has_quirk(player_ID, Cards.effect_ref.KERIS_PROJ):
				enhance_card(Cards.effect_ref.KERIS_PROJ)
			if Inventory.has_quirk(player_ID, Cards.effect_ref.SUMMON_NOUSAGI):
				enhance_card(Cards.effect_ref.SUMMON_NOUSAGI)
		Em.atk_type.FIERCE:
			if Inventory.has_quirk(player_ID, Cards.effect_ref.PHOENIX_PROJ):
				enhance_card(Cards.effect_ref.PHOENIX_PROJ)
			if Inventory.has_quirk(player_ID, Cards.effect_ref.TBLOCK_PROJ):
				enhance_card(Cards.effect_ref.TBLOCK_PROJ)
		Em.atk_type.HEAVY:
			if Inventory.has_quirk(player_ID, Cards.effect_ref.SCYTHE_PROJ):
				enhance_card(Cards.effect_ref.SCYTHE_PROJ)
			if Inventory.has_quirk(player_ID, Cards.effect_ref.SUMMON_SSRB):
				enhance_card(Cards.effect_ref.SUMMON_SSRB)
		Em.atk_type.SPECIAL, Em.atk_type.EX:
			pass
			
func landed_enhance(atk_type: int):
	match atk_type:
		Em.atk_type.LIGHT:
			pass
		Em.atk_type.FIERCE:
			pass
		Em.atk_type.HEAVY:
			if Inventory.has_quirk(player_ID, Cards.effect_ref.VORTEX):
				enhance_card(Cards.effect_ref.VORTEX)
		Em.atk_type.SPECIAL, Em.atk_type.EX:
			pass
		
func air_jump_enhance():
	if Inventory.has_quirk(player_ID, Cards.effect_ref.RAIN_PROJ):
		enhance_card(Cards.effect_ref.RAIN_PROJ)
		
func block_enhance():
	if Inventory.has_quirk(player_ID, Cards.effect_ref.PEACOCK_PROJ):
		enhance_card(Cards.effect_ref.PEACOCK_PROJ)
	if Inventory.has_quirk(player_ID, Cards.effect_ref.FLASK_PROJ):
		enhance_card(Cards.effect_ref.FLASK_PROJ)
		
func ground_dash_enhance():
	if Inventory.has_quirk(player_ID, Cards.effect_ref.CAN_TRIP) and Globals.Game.rng_generate(100) < Cards.TRIP_CHANCE:
		trip()
		return false

	return true
	
func dodge_enhance():
	if Inventory.has_quirk(player_ID, Cards.effect_ref.TIME_BUBBLE):
		enhance_card(Cards.effect_ref.TIME_BUBBLE)
	
func trip():
	face(-facing)
	animate("LaunchStop")
	velocity.x = get_stat("GROUND_DASH_SPEED") * -facing
	velocity.y = -FMath.percent(get_stat("JUMP_SPEED"), 50)
	launch_starting_rot = 0
	launchstun_rotate = 0
#	$HitStunTimer.time = 30
	play_audio("whoosh11", {"vol" : -25})
	Globals.Game.spawn_SFX("GroundDashDust", "DustClouds", get_feet_pos(), {"facing":dir, "grounded":true})
		
# ---------------------------------------------------------------------------------------------------------------------
		
		
func is_killable(vel_value):
	if new_state in [Em.char_state.SEQUENCE_TARGET, Em.char_state.SEQUENCE_USER]:
		return false
	if !lethal_flag: # must be in lethal hitstun off a lethal hit
		return false
	if abs(vel_value) > KILL_VEL_THRESHOLD: # must be fast enough
		return true
	if get_damage_percent() > 150: # if not fast enough, over 150% damage is also acceptable
		return true
	return false

func on_kill():
	if state != Em.char_state.DEAD:
		play_audio("kill1", {"vol" : -2})
		var sfx_facing: int = Globals.Game.rng_facing()
		var rot = Globals.Game.get_killblast_angle_and_screenshake(position) * -sfx_facing # can be a float, effect is visual
		var palette
		match player_ID:
			0:
				palette = "red"
			1:
				palette = "blue"
		Globals.Game.spawn_SFX("KillBlast", "KillBlast", position, {"facing" : sfx_facing, "rot" : rot}, palette)
		
		$VarJumpTimer.stop()
		$HitStunTimer.stop()
		$HitStopTimer.stop()
		
		super_ex_lock = null
		$EXSealTimer.stop()
		$InstallTimer.stop()
		install_time = null
		if UniqChar.has_method("install_over"): UniqChar.install_over()
		
		$Sprites.hide()
		state = Em.char_state.DEAD
		velocity.set_vector(0, 0)
		repeat_memory = []
		input_buffer = []
		hitcount_record = []
		ignore_list = []
		delayed_hit_effect = []
		remove_all_status_effects()
		reset_modulate()
		reset_jumps()
		
		if Globals.survival_level == null:
			var opponent = get_target()
			if opponent.state != Em.char_state.DEAD:
				
				if opponent.burst_token == Em.burst.EXHAUSTED:
					opponent.change_burst_token(Em.burst.AVAILABLE) # your targeted opponent gain burst token if exhausted
				
				if opponent.current_damage_value > opponent.UniqChar.DAMAGE_VALUE_LIMIT: # heal off any negative HP
					opponent.current_damage_value = opponent.UniqChar.DAMAGE_VALUE_LIMIT
				
				if current_damage_value > UniqChar.DAMAGE_VALUE_LIMIT: # targeted opponent heals Damage Value equal to overkill damage
					opponent.take_damage(-(current_damage_value - UniqChar.DAMAGE_VALUE_LIMIT))
					
				Globals.Game.damage_update(opponent)

		change_stock_points(-1)
		$RespawnTimer.time = Globals.RespawnTimer_WAIT_TIME
		
		if UniqChar.has_method("on_kill"): # for unique_data changes on death
			UniqChar.on_kill()
			
	
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
			
	set_true_position()
			
	current_damage_value = 0
	current_guard_gauge = 0
	if Globals.survival_level == null:
		change_burst_token(Em.burst.AVAILABLE) # gain Burst on death
	else:
		if Inventory.has_quirk(player_ID, Cards.effect_ref.RESPAWN_POWER):
			current_ex_gauge = MAX_EX_GAUGE
		
	Globals.Game.damage_update(self)
	Globals.Game.guard_gauge_update(self)
	Globals.Game.ex_gauge_update(self)
	Globals.Game.stock_points_update(self)
	
	$Sprites.show()
	animate("Idle")
	state = Em.char_state.GROUND_STANDBY
	add_status_effect([Em.status_effect.RESPAWN_GRACE, RESPAWN_GRACE_DURATION])
	
	var palette
	match player_ID:
		0:
			palette = "red"
		1:
			palette = "blue"
	
	Globals.Game.spawn_SFX("Respawn", "Respawn", position, {"back":true, "facing":Globals.Game.rng_facing(), \
			"v_mirror":Globals.Game.rng_bool()}, palette)
	play_audio("bling7", {"vol" : -25, "bus" : "HighPass"})
	play_audio("bling7", {"vol" : -7, "bus" : "PitchUp2"})

		
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
	air_dodge = get_stat("MAX_AIR_DODGE")
	super_dash = get_stat("MAX_SUPER_DASH")
	aerial_memory = []
	aerial_sp_memory = []
	
func reset_jumps_except_walljumps():
	air_jump = get_stat("MAX_AIR_JUMP") # reset jump count on wall
	air_dash = get_stat("MAX_AIR_DASH")
	
func gain_one_air_jump(): # hitting with an aerial (not block unless wrongblock) give you +1 air jump
	if air_jump < get_stat("MAX_AIR_JUMP"): # cannot go over
		air_jump += 1
	
func reset_cancels(): # done whenever you use an attack, after startup frames finish and before active frames begin
	chain_combo = Em.chain_combo.RESET
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
			if Animator.query_to_play(["DodgeCRec"]):
				pass
			else:
				animate("SoftLanding")
			
		Em.char_state.AIR_STARTUP:
			if Animator.query_to_play(["aJumpTransit"]):
				animate("SoftLanding")
				if Settings.input_assist[player_ID]:
					input_buffer.append([button_jump, buffer_time()])
			elif Animator.query_to_play(["aDashTransit"]):
				animate("SoftLanding")
				if Settings.input_assist[player_ID]:
					input_buffer.append([button_dash, buffer_time()])
				
		Em.char_state.AIR_ACTIVE:
			pass # AIR_ACTIVE not used for now
			
		Em.char_state.AIR_D_REC:
			if !Animator.to_play_anim.ends_with("DD"): # wave landing
				if Globals.survival_level != null and !ground_dash_enhance():
					pass
				else:
					animate("WaveDashBrake")
					UniqChar.dash_sound()
					Globals.Game.spawn_SFX("GroundDashDust", "DustClouds", get_feet_pos(), {"facing":facing, "grounded":true})
					if dir == facing:
						velocity.x = facing * FMath.percent(get_stat("GROUND_DASH_SPEED"), get_stat("WAVE_DASH_SPEED_MOD"))
			
			
		Em.char_state.AIR_REC:
			if Animator.query_to_play(["aBlockRec"]): # aBlockRecovery to BlockCRecovery
				Globals.Game.spawn_SFX("LandDust", "DustClouds", get_feet_pos(), {"grounded":true})
				animate("BlockRec")
				UniqChar.landing_sound()
				
			elif Animator.query_to_play(["DodgeTransit", "Dodge", "DodgeRec", "SDash"]) or \
					Animator.to_play_anim.begins_with("Burst"): # no landing
				pass
				
			else: # landing during AirDashDD
				animate("HardLanding")
			
		Em.char_state.AIR_ATK_STARTUP: # can land cancel on the 1st few frames (unless EX/Super), will auto-buffer pressed attacks
			var move_name = get_move_name()
			if move_name in UniqChar.STARTERS and !is_ex_move(move_name) and !is_super(move_name) and \
				velocity_previous_frame.y > 0 and Animator.time <= AERIAL_STARTUP_LAND_CANCEL_TIME and Animator.time != 0:
				animate("HardLanding") # this makes landing and attacking instantly easier

		Em.char_state.AIR_FLINCH_HITSTUN: # land during hitstun
			Globals.Game.spawn_SFX("LandDust", "DustClouds", get_feet_pos(), {"grounded":true})
			match Animator.to_play_anim:
				"aFlinchAStop", "aFlinchA":
					animate("FlinchA")
				"aFlinchBStop", "aFlinchB":
					animate("FlinchB")
			if velocity_previous_frame.y > 300 * FMath.S:
				UniqChar.landing_sound() # only make landing sound if landed fast enough, or very annoying
			
		Em.char_state.LAUNCHED_HITSTUN: # land during launch_hitstun, can bounce or tech land
			if new_state == Em.char_state.LAUNCHED_HITSTUN:
				# need to use new_state to prevent an issue with grounded Break state causing HardLanding on flinch
				# check using either velocity this frame or last frame
					
				var vector_to_check
				if velocity.is_longer_than_another(velocity_previous_frame):
					vector_to_check = velocity
				else:
					vector_to_check = velocity_previous_frame
				
				if !vector_to_check.is_longer_than(TECHLAND_THRESHOLD):
					if !tech():
						animate("HardLanding")
						$HitStunTimer.stop()
						velocity.y = 0 # stop bouncing
						modulate_play("unflinch_flash")
#						play_audio("bling4", {"vol" : -15, "bus" : "PitchDown"})
			
		Em.char_state.AIR_BLOCK: # air block to ground block
			Globals.Game.spawn_SFX("LandDust", "DustClouds", get_feet_pos(), {"grounded":true})
			
			if Animator.query_to_play(["aBlockStartup"]): # if dropping during block startup
				change_guard_gauge(-get_stat("GROUND_BLOCK_GG_COST") * 10)
				play_audio("bling4", {"vol" : -10, "bus" : "PitchUp2"})
#				if Globals.survival_level == null:
#				remove_status_effect(Em.status_effect.POS_FLOW)
					
			animate("BlockLanding")

			
func check_drop(): # called when character becomes airborne while in a grounded state
	if anim_gravity_mod <= 0: return
	if seq_partner_ID != null: return # no checking during start of sequence
	match new_state:
		
		Em.char_state.GROUND_STANDBY, Em.char_state.CROUCHING, Em.char_state.GROUND_C_REC, \
				Em.char_state.GROUND_D_REC:
			animate("FallTransit")
			
		Em.char_state.GROUND_STARTUP:
			if Animator.query_to_play(["JumpTransit"]): # instantly jump if dropped during jump transit
				animate("JumpTransit2")
			else:
				animate("FallTransit")
				
		Em.char_state.GROUND_ACTIVE:
			pass # GROUND_ACTIVE not used for now

		Em.char_state.GROUND_REC:
			if Animator.query_to_play(["BlockRec"]):
				animate("aBlockRec")
			else:
				animate("FallTransit")
				
		Em.char_state.GROUND_ATK_STARTUP:
			animate("FallTransit")
				
		Em.char_state.GROUND_ATK_ACTIVE, Em.char_state.GROUND_ATK_REC:
			var move_name = get_move_name()
			if move_name in UniqChar.MOVE_DATABASE and \
				Em.atk_attr.LEDGE_DROP in query_atk_attr(move_name):
				continue
			else:
				animate("FallTransit")
			
		Em.char_state.GROUND_FLINCH_HITSTUN:
			match Animator.to_play_anim:
				"FlinchAStop", "FlinchA":
					animate("aFlinchA")
				"FlinchBStop", "FlinchB":
					animate("aFlinchB")
			
		Em.char_state.GROUND_BLOCK:
			if Animator.query_to_play(["BlockStartup"]):
				change_guard_gauge(-get_stat("AIR_BLOCK_GG_COST") * 10)
				play_audio("bling4", {"vol" : -10, "bus" : "PitchUp2"})
#				if Globals.survival_level == null:
#				remove_status_effect(Em.status_effect.POS_FLOW)
			animate("aBlock")


func check_sdash_crash():
	if !is_on_ground($SoftPlatformDBox):
		animate("aDashBrake")
	else:
		if !velocity.is_longer_than(FMath.percent(get_stat("SDASH_SPEED"), 50)):
			animate("HardLanding")
		else:
			var old_angle = velocity.angle()
			velocity.set_vector(get_stat("SDASH_SPEED"), 0)
			velocity.rotate(old_angle)

func check_collidable(): # called by Physics.gd
	if slowed < 0: return false
	match new_state:
		Em.char_state.LAUNCHED_HITSTUN:
			return false
		Em.char_state.SEQUENCE_TARGET, Em.char_state.SEQUENCE_USER:
			return false
#		Em.char_state.GROUND_ATK_STARTUP: # crossover attack
#			if button_dash in input_state.pressed:
##					and chain_memory.size() == 0:
#				return false
		Em.char_state.AIR_STARTUP:
			if Animator.query_to_play(["BurstCounterStartup", "BurstEscapeStartup"]):
				return false
		Em.char_state.AIR_REC:
			if Animator.query_to_play(["Dodge"]):
				return false
			if Globals.survival_level != null:
				if Animator.query_to_play(["SDash"]):
					if Inventory.has_quirk(player_ID, Cards.effect_ref.SDASH_IFRAME):
						return false
		Em.char_state.GROUND_D_REC, Em.char_state.AIR_D_REC:
			if Globals.survival_level != null:
				if Inventory.has_quirk(player_ID, Cards.effect_ref.DASH_IFRAME):
					return false
			
	return UniqChar.check_collidable()
	
		
func check_fallthrough(): # during aerials, can drop through platforms if down is held
	if state == Em.char_state.SEQUENCE_USER:
		return UniqChar.sequence_fallthrough()
	elif state == Em.char_state.SEQUENCE_TARGET:
		return true # when being grabbed, always fall through soft platforms
#		return get_node(targeted_opponent_path).check_fallthrough() # copy fallthrough state of the one grabbing you
	elif new_state == Em.char_state.AIR_REC and Animator.query_to_play(["Dodge", "SDash"]):
		return true
	elif !grounded and is_attacking():
		if button_down in input_state.pressed:
			return true
	return false
	
func check_semi_invuln():
	if UniqChar.check_semi_invuln():
		return true
	else:
		match new_state:
			Em.char_state.GROUND_ATK_STARTUP, Em.char_state.AIR_ATK_STARTUP:
				if is_super(get_move_name()):
					return true
				elif Em.atk_attr.SEMI_INVUL_STARTUP in query_atk_attr():
					return true
			Em.char_state.AIR_STARTUP:
				if Animator.query_to_play(["BurstCounterStartup", "BurstEscapeStartup"]):
					return true
			Em.char_state.AIR_REC:
				if Animator.query_to_play(["DodgeTransit", "Dodge"]):
#					and Animator.time <= DODGE_SEMI_IFRAMES:
					return true
				if Globals.survival_level != null:
					if Animator.query_to_play(["SDash"]):
						if Inventory.has_quirk(player_ID, Cards.effect_ref.SDASH_IFRAME):
							return true
			Em.char_state.GROUND_D_REC, Em.char_state.AIR_D_REC:
				if Globals.survival_level != null:
					if Inventory.has_quirk(player_ID, Cards.effect_ref.DASH_IFRAME):
						return true
			Em.char_state.LAUNCHED_HITSTUN:
				if Globals.survival_level != null:
					if !$HitStunTimer.is_running() and Inventory.has_quirk(player_ID, Cards.effect_ref.CAN_TRIP):
						return true
			
	return false	
	
func check_passthrough():
	if state == Em.char_state.SEQUENCE_USER:
		return UniqChar.sequence_passthrough() # for cinematic supers
	elif state == Em.char_state.SEQUENCE_TARGET:
		return get_target().sequence_partner_passthrough() # get passthrough state from the one grabbing you
	return false
	
func sequence_partner_passthrough():
	return UniqChar.sequence_partner_passthrough()
		
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
	if !button_jump in input_state.pressed and check_snap_up() and snap_up($PlayerCollisionBox, $DashLandDBox):
		if dir != 0: # if holding direction, dash towards it
			if facing != dir:
				face(dir)
			animate("WaveDashBrake")
			velocity.x = dir * get_stat("GROUND_DASH_SPEED")
			Globals.Game.spawn_SFX("GroundDashDust", "DustClouds", get_feet_pos(), {"facing":facing, "grounded":true})
			UniqChar.dash_sound()
		else:
			animate("SoftLanding")
#			Globals.Game.spawn_SFX("LandDust", "DustClouds", get_feet_pos(), {"facing":facing, "grounded":true})
			UniqChar.landing_sound()
		return true
	else:
		return false
		
func get_feet_pos(): # return global position of the point the character is standing on, for SFX emission
	return position + Vector2(0, $PlayerCollisionBox.rect_position.y + $PlayerCollisionBox.rect_size.y)
	
func get_pos_from_feet(feet_pos: Vector2):
	return feet_pos - Vector2(0, $PlayerCollisionBox.rect_position.y + $PlayerCollisionBox.rect_size.y)
	
#func rng_generate(upper_limit: int): # will return a number from 0 to (upper_limit - 1)
#	if Globals.Game.has_method("rng_generate"):
#		return Globals.Game.rng_generate(upper_limit)
#	else: return null
	
func can_DI(): # already checked for HitStunTimer
	if Globals.survival_level == null and current_guard_gauge <= 0:
		return false
	if get_damage_percent() >= 100:
		return false
	if DI_seal and $BurstLockTimer.is_running():
		return false
	return true

func process_VDI():
	# to be able to DI, must be entering knockback animation and has a directional key pressed

	if Globals.survival_level == null:
		if current_guard_gauge <= 0: return
	
	if (dir != 0 or v_dir != 0) and !DI_seal and get_damage_percent() < 100 and \
		((state == Em.char_state.LAUNCHED_HITSTUN and Animator.query_to_play(["LaunchTransit"]) and \
		!Animator.query_current(["LaunchTransit"])) or \
		(state == Em.char_state.GROUND_FLINCH_HITSTUN and Animator.query_to_play(["FlinchA", "FlinchB"]) and \
		!Animator.query_current(["FlinchA", "FlinchB"])) or \
		(state == Em.char_state.AIR_FLINCH_HITSTUN and Animator.query_to_play(["aFlinchA", "aFlinchB"]) and \
		!Animator.query_current(["aFlinchA", "aFlinchB"]))):
		var velocity_length: int = velocity.length()
		var VDI_amount_max: int = FMath.percent(velocity_length, VDI_MAX)
		var VDI_amount: int
		
		if Globals.survival_level == null:
			VDI_amount = FMath.f_lerp(0, VDI_amount_max, get_guard_gauge_percent_above()) # adjust according to Guard Gauge
		else:
#			VDI_amount = FMath.f_lerp(0, VDI_amount_max, get_guard_gauge_percent_true()) # adjust according to Guard Gauge
			VDI_amount = VDI_amount_max
		
		if dir != 0 and v_dir != 0: # diagonal, multiply by 0.71
			VDI_amount = FMath.percent(VDI_amount, 71)
			
		velocity.x += dir * VDI_amount
		velocity.y += v_dir * VDI_amount
		

# SPECIAL EFFECTS --------------------------------------------------------------------------------------------------

func bounce_dust(orig_dir, slam = null):
	match orig_dir:
		Em.compass.N:
			Globals.Game.spawn_SFX("BounceDust", "DustClouds", position + Vector2(0, $PlayerCollisionBox.rect_position.y), {"rot":PI})
			if slam != null:
				match slam:
					0:
						Globals.Game.spawn_SFX("WallSlam", "WallSlam", position + Vector2(0, $PlayerCollisionBox.rect_position.y), {"rot":PI})
					1:
						Globals.Game.spawn_SFX("WallSlam2", "WallSlam", position + Vector2(0, $PlayerCollisionBox.rect_position.y), {"rot":PI})
					2:
						Globals.Game.spawn_SFX("WallSlam3", "WallSlam", position + Vector2(0, $PlayerCollisionBox.rect_position.y), {"rot":PI})
		Em.compass.E:
			Globals.Game.spawn_SFX("BounceDust", "DustClouds", position + Vector2($PlayerCollisionBox.rect_size.x / 2, 0), \
					{"facing": 1, "rot":-PI/2})
			if slam != null:
				match slam:
					0:
						Globals.Game.spawn_SFX("WallSlam", "WallSlam", position + Vector2($PlayerCollisionBox.rect_size.x / 2, 0), \
							{"facing": 1, "rot":-PI/2})
					1:
						Globals.Game.spawn_SFX("WallSlam2", "WallSlam", position + Vector2($PlayerCollisionBox.rect_size.x / 2, 0), \
							{"facing": 1, "rot":-PI/2})
					2:
						Globals.Game.spawn_SFX("WallSlam3", "WallSlam", position + Vector2($PlayerCollisionBox.rect_size.x / 2, 0), \
							{"facing": 1, "rot":-PI/2})
		Em.compass.S:
			Globals.Game.spawn_SFX("BounceDust", "DustClouds", get_feet_pos(), {"grounded":true})
			if slam != null:
				match slam:
					0:
						Globals.Game.spawn_SFX("WallSlam", "WallSlam", get_feet_pos(), {"grounded":true})
					1:
						Globals.Game.spawn_SFX("WallSlam2", "WallSlam", get_feet_pos(), {"grounded":true})
					2:
						Globals.Game.spawn_SFX("WallSlam3", "WallSlam", get_feet_pos(), {"grounded":true})
		Em.compass.W:
			Globals.Game.spawn_SFX("BounceDust", "DustClouds", position - Vector2($PlayerCollisionBox.rect_size.x / 2, 0), \
					{"facing": -1, "rot":-PI/2})
			if slam != null:
				match slam:
					0:
						Globals.Game.spawn_SFX("WallSlam", "WallSlam", position - Vector2($PlayerCollisionBox.rect_size.x / 2, 0), \
							{"facing": -1, "rot":-PI/2})
					1:
						Globals.Game.spawn_SFX("WallSlam2", "WallSlam", position - Vector2($PlayerCollisionBox.rect_size.x / 2, 0), \
							{"facing": -1, "rot":-PI/2})
					2:
						Globals.Game.spawn_SFX("WallSlam3", "WallSlam", position - Vector2($PlayerCollisionBox.rect_size.x / 2, 0), \
							{"facing": -1, "rot":-PI/2})

func set_monochrome():
	if !monochrome:
		monochrome = true
		sprite.material = ShaderMaterial.new()
		sprite.material.shader = Loader.monochrome_shader

# particle emitter, visuals only, no need fixed-point
func particle(anim: String, loaded_sfx_ref: String, palette, interval, number, radius, v_mirror_rand := false, master_palette := false):
	if Globals.Game.frametime % interval == 0:  # only shake every X frames
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
				Globals.Game.spawn_SFX(anim, loaded_sfx_ref, particle_pos, aux_data, palette, UniqChar.NAME)
			else:
				Globals.Game.spawn_SFX(anim, loaded_sfx_ref, particle_pos, aux_data, palette)
			
			
func flashes():
	# process ex flash
	if is_attacking(): 	# if current movename in UniqChar.EX_FLASH_ANIM, will ex flash during startup/active/recovery
		if get_move_name() in UniqChar.EX_FLASH_ANIM:
			modulate_play("EX_flash2")
			
	if is_blocking():
		modulate_play("block")
		
#	if Globals.survival_level != null and Inventory.has_quirk(player_ID, Cards.effect_ref.PASSIVE_ARMOR) and current_guard_gauge == 0:
#		modulate_play("passive_armor")
		
	UniqChar.unique_flash()
	
		
#func get_spritesheet():
#	pass
			
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
			
	UniqChar.afterimage_trail()
			
			
func afterimage_trail(color_modulate = null, starting_modulate_a = 0.6, lifetime: int = 10, \
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
		
#func spawn_afterimage(master_ID: int, is_entity: bool, master_ref: String, spritesheet_ref: String, sprite_node_path: NodePath, palette_ref, color_modulate = null, \
#		starting_modulate_a = 0.5, lifetime = 10, afterimage_shader = Em.afterimage_shader.MASTER):
		
		if sfx_under.visible:
			Globals.Game.spawn_afterimage(player_ID, false, sprite_texture_ref.sfx_under, sfx_under.get_path(), UniqChar.NAME, palette_number, \
					main_color_modulate, starting_modulate_a, lifetime, afterimage_shader)
			
		Globals.Game.spawn_afterimage(player_ID, false, sprite_texture_ref.sprite, sprite.get_path(), UniqChar.NAME, palette_number, \
				main_color_modulate, starting_modulate_a, lifetime, afterimage_shader)
		
		if sfx_over.visible:
			Globals.Game.spawn_afterimage(player_ID, false, sprite_texture_ref.sfx_over, sfx_over.get_path(), UniqChar.NAME, palette_number, \
					main_color_modulate, starting_modulate_a, lifetime, afterimage_shader)
					
	else:
		afterimage_timer -= 1
		
		
func afterimage_cancel(starting_modulate_a = 0.5, lifetime: int = 12): # no need color_modulate for now
	
	if sfx_under.visible:
		Globals.Game.spawn_afterimage(player_ID, false, sprite_texture_ref.sfx_under, sfx_under.get_path(), UniqChar.NAME, palette_number, null, \
			starting_modulate_a, lifetime)
		
	Globals.Game.spawn_afterimage(player_ID, false, sprite_texture_ref.sprite, sprite.get_path(), UniqChar.NAME, palette_number, null, \
		starting_modulate_a, lifetime)
	
	if sfx_over.visible:
		Globals.Game.spawn_afterimage(player_ID, false, sprite_texture_ref.sfx_over, sfx_over.get_path(), UniqChar.NAME, palette_number, null, \
			starting_modulate_a, lifetime)
		
		
func launch_trail():
	var frequency: int
	if !velocity.is_longer_than(FMath.percent(LAUNCH_DUST_THRESHOLD, 50)):
		frequency = 4
	elif !velocity.is_longer_than(LAUNCH_DUST_THRESHOLD): # the faster you go the more frequent the launch dust
		frequency = 3
	elif !velocity.is_longer_than(FMath.percent(LAUNCH_DUST_THRESHOLD, 200)):
		frequency = 2
	else:
		frequency = 1
		
	if posmod($HitStunTimer.time, frequency) == 0:
		
		if !grounded:
			Globals.Game.spawn_SFX("LaunchDust", "DustClouds", position, {"back":true, "facing":Globals.Game.rng_facing(), \
					"v_mirror":Globals.Game.rng_bool()})
		else:
			Globals.Game.spawn_SFX("DragRocks", "DustClouds", get_feet_pos(), {"back":true, "facing":Globals.Game.rng_facing(), "grounded":true})
			
	
# QUICK STATE CHECK ---------------------------------------------------------------------------------------------------
	
func get_move_name():
	var move_name = Animator.to_play_anim.trim_suffix("Startup")
	move_name = move_name.trim_suffix("Active")
	move_name = move_name.trim_suffix("Rec")
	return move_name
	
func check_quick_turn():
	if quick_turn_used: return false
	
	var can_turn := false
	
	match state:
		Em.char_state.GROUND_STARTUP:
			can_turn = true
		Em.char_state.AIR_STARTUP:
#			if (button_light in input_state.pressed or button_fierce in input_state.pressed or button_aux in input_state.pressed) and \
#				button_dash in input_state.pressed:
#				return false  # if attacking + holding dash, will not turn on 1st frame
			if Animator.to_play_anim.begins_with("Burst"):
				can_turn = false
			else:
				can_turn =  true
	match new_state:
		Em.char_state.GROUND_ATK_STARTUP: # for grounded attacks, can turn on 1st 6 startup frames
			if Animator.time <= 6 and Animator.time != 0:
				var move_name = get_move_name()
				if move_name == null or !move_name in UniqChar.STARTERS:
					can_turn = false
				elif Em.atk_attr.NO_TURN in query_atk_attr(move_name):
					can_turn = false
#				if Em.atk_attr.QUICK_TURN_LIMIT in query_atk_attr(move_name): # some moves lock quick turn after a few (3) frames
#					if Animator.time > 3:
#						return false
				else: can_turn = true
		Em.char_state.AIR_ATK_STARTUP: # for aerials, can only turn on the 1st 3 frames
			if Animator.time <= 3 and Animator.time != 0:
#				 and !button_dash in input_state.pressed:
				var move_name = get_move_name()
				if move_name == null or !move_name in UniqChar.STARTERS:
					can_turn = false
				elif Em.atk_attr.NO_TURN in query_atk_attr(move_name):
					can_turn = false
				else: can_turn = true
		Em.char_state.GROUND_BLOCK:
			if Animator.query(["BlockStartup"]):
				can_turn = true
		Em.char_state.AIR_BLOCK:
			if Animator.query(["aBlockStartup"]):
				can_turn = true

	return can_turn

	
func check_quick_cancel(attack_ref): # cannot quick cancel from EX/Supers
	var move_name = get_move_name()
	if move_name == null: return false
	if !move_name in UniqChar.STARTERS or is_super(move_name): return false
	
	if Em.atk_attr.NO_QUICK_CANCEL in query_atk_attr(move_name):
		return false
		
	if from_move_rec and Em.atk_attr.NOT_FROM_MOVE_REC in query_atk_attr(attack_ref):
		return false
	
	if is_ex_move(move_name): # cancelling from ex move, only other ex moves are possible
		if is_ex_move(attack_ref): # cancelling into another ex move
			if Animator.time <= 2 and Animator.time != 0:
				return true # EX and Supers have a wider window to quick cancel into
	else: # cancelling from a normal move
		if is_ex_move(attack_ref): # cancelling into an ex move from normal move has wider window
			# attack buttons must be pressed as well so tapping special + attack together too fast will not quick cancel into EX move
			if (button_light in input_state.pressed or button_fierce in input_state.pressed or button_aux in input_state.pressed):
				if !are_inputs_too_close():
					if Animator.time <= 5 and Animator.time != 0:
						return true
		else:
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
	

	
#func is_static(): # for command grabs to prevent impulses on ground
##	if !grounded: return true
#	if dir != 0: return false
#
#	for release in release_memory:
#		if release[0] in [button_left, button_right]:
#			return false
#
#	return true

	
#func check_quick_cancel(turning = false): # return true if you can change direction or cancel into a combination action currently
#	match state: # use current state instead of new_state
#		Em.char_state.GROUND_STARTUP, Em.char_state.AIR_STARTUP:
#			if turning:
#				return true
#			elif Animator.time <= QUICK_CANCEL_TIME and Animator.time != 0:
#				return true
#		Em.char_state.GROUND_ATK_STARTUP:
#			if turning and new_state == Em.char_state.GROUND_ATK_STARTUP:
#				var move_name = get_move_name()
#				if move_name == null: return false # if name at name of animation not found in database
#				if !Em.atk_attr.NO_TURN in query_atk_attr():
#					return true
#			else: continue
#		Em.char_state.GROUND_ATK_STARTUP, Em.char_state.AIR_ATK_STARTUP:
#			if !turning:
#				if Animator.time <= QUICK_CANCEL_TIME and Animator.time != 0:
#					# when time = 0 state is still in the previous one, since state only update when a new animation begins
#					return true
#			else: # for turning, the QUICK_CANCEL_TIME is 1 frame lower, min is 1 frame
#				if Animator.time <= max(QUICK_CANCEL_TIME - 1, 1) and Animator.time != 0:
#					return true
#		Em.char_state.GROUND_BLOCK:
#			if Animator.query(["BlockStartup"]):
#				return true
#		Em.char_state.AIR_BLOCK:
#			if Animator.query(["aBlockStartup"]):
#				return true
#	return false
		
func check_ledge_stop(): # some animations prevent you from dropping off
	if !grounded or new_state in [Em.char_state.AIR_ATK_STARTUP, Em.char_state.AIR_ATK_ACTIVE, \
		Em.char_state.AIR_ATK_REC, Em.char_state.AIR_C_REC]:
		return false
	if is_attacking():
		var move_name = get_move_name()
		# test if move has LEDGE_DROP, no ledge stop if so
		if new_state != Em.char_state.GROUND_ATK_STARTUP:
			if Em.atk_attr.LEDGE_DROP in query_atk_attr(move_name):
				return false # even with LEDGE_DROP, startup animation will still stop you at the ledge
			else:
				return true # no LEDGE_DROP, will stop at ledge
		else: # during startup of ground attacks
			if dir == facing and move_name in UniqChar.STARTERS and !is_ex_move(move_name) and !is_super(move_name):
				return false # when doing moves that are not EX moves and supers, can drop off ledge on startup if you are holding forward
			else:
				return true
	else:
		return false # not attacking
	
func is_blocking():
	match new_state:
		Em.char_state.GROUND_BLOCK, Em.char_state.AIR_BLOCK:
			return true
	return false
	
func is_hitstunned():
	match state: # use non-new state
		Em.char_state.AIR_FLINCH_HITSTUN, Em.char_state.GROUND_FLINCH_HITSTUN, Em.char_state.LAUNCHED_HITSTUN:
			return true
	return false
	
func is_hitstunned_or_sequenced():
	match state: # use non-new state
		Em.char_state.AIR_FLINCH_HITSTUN, Em.char_state.GROUND_FLINCH_HITSTUN, Em.char_state.LAUNCHED_HITSTUN, \
				Em.char_state.SEQUENCE_TARGET:
			return true
	return false
	
func is_hitstunned_or_sequenced2():
	match new_state:
		Em.char_state.AIR_FLINCH_HITSTUN, Em.char_state.GROUND_FLINCH_HITSTUN, Em.char_state.LAUNCHED_HITSTUN, \
				Em.char_state.SEQUENCE_USER, Em.char_state.SEQUENCE_TARGET:
			return true
	return false
	
func is_attacking():
	match new_state:
		Em.char_state.GROUND_ATK_STARTUP, Em.char_state.GROUND_ATK_ACTIVE, Em.char_state.GROUND_ATK_REC, \
			Em.char_state.AIR_ATK_STARTUP, Em.char_state.AIR_ATK_ACTIVE, Em.char_state.AIR_ATK_REC, \
			Em.char_state.SEQUENCE_USER:
			return true
	return false
	
func is_aerial():
	match new_state:
		Em.char_state.AIR_ATK_STARTUP, Em.char_state.AIR_ATK_ACTIVE, Em.char_state.AIR_ATK_REC:
			return true
	return false
	
func is_atk_startup():
	match new_state:
		Em.char_state.GROUND_ATK_STARTUP, Em.char_state.AIR_ATK_STARTUP:
			return true
	return false
	
func is_atk_active():
	match new_state:
		Em.char_state.GROUND_ATK_ACTIVE, Em.char_state.AIR_ATK_ACTIVE:
			return true
	return false
	
func is_atk_recovery():
	match new_state:
		Em.char_state.GROUND_ATK_REC, Em.char_state.AIR_ATK_REC:
			return true
	return false
	
#func is_normal_attack(move_name):
#	match query_move_data(move_name)[Em.move.ATK_TYPE]:
#		Em.atk_type.LIGHT, Em.atk_type.FIERCE, Em.atk_type.HEAVY: # can only chain combo into a Normal
#			return true
#	return false
	
func is_normal_attack(move_name):
	match query_move_data(move_name)[Em.move.ATK_TYPE]:
		Em.atk_type.LIGHT, Em.atk_type.FIERCE: # can only chain combo into a Normal
			return true
	return false
	
func is_heavy(move_name):
	match query_move_data(move_name)[Em.move.ATK_TYPE]:
		Em.atk_type.HEAVY: # can only chain combo into a Normal
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
	
# called by unique character to check if there is an EX version and if it is valid
func is_ex_valid(attack_ref, quick_cancel = false): # don't put this condition with any other conditions!
	if !attack_ref in UniqChar.STARTERS or !is_ex_move(attack_ref): return true # not ex move or starter, allowed to pass
	
	# has an EX Move, only pass if valid
	if !quick_cancel: # not quick cancelling, must afford it
		if current_ex_gauge >= EX_MOVE_COST:
			change_ex_gauge(-EX_MOVE_COST)
			play_audio("bling7", {"vol" : -10, "bus" : "PitchUp2"}) # EX chime
			Globals.Game.spawn_SFX("EXFlash", "Shines", position - Vector2(0, get_stat("EYE_LEVEL")), {}, "pink")
			modulate_play("EX_flash")
			return true
		else:
			return false
	else:
		if is_ex_move(get_move_name()): # can quick cancel from 1 EX move to another, no cost and no chime if so
			return true
		elif current_ex_gauge >= EX_MOVE_COST: # quick cancel from non-ex move to EX move, must afford the cost
			change_ex_gauge(-EX_MOVE_COST)
			play_audio("bling7", {"vol" : -10, "bus" : "PitchUp2"}) # EX chime
			Globals.Game.spawn_SFX("EXFlash", "Shines", position - Vector2(0, get_stat("EYE_LEVEL")), {}, "pink")
			modulate_play("EX_flash")
			return true
		else:
			return false

func super_test():
	if $EXSealTimer.is_running() or $InstallTimer.is_running():
		return false
	return true
#	if current_ex_gauge != MAX_EX_GAUGE:
#		return false
#	if cost_burst and burst_token != Em.burst.AVAILABLE:
#		return false
#	return true
	
		
func super_cost(lock_time_per_lvl, base_lock_time := 0, in_install_time := 0):
	var total_lock_time: int = lock_time_per_lvl * (3 - get_ex_level()) + base_lock_time
	
	$EXSealTimer.time += total_lock_time
	super_ex_lock = $EXSealTimer.time
	
	if in_install_time > 0:
		install_time = in_install_time
		$InstallTimer.time = in_install_time
	
	change_ex_gauge(-MAX_EX_GAUGE)
#	if cost_burst:
#		change_burst_token(Em.burst.CONSUMED)
	
func tech():
	if button_dash in input_state.pressed:
		if dir != 0 or v_dir != 0:
			if button_block in input_state.pressed:
				animate("SDashTransit")
#				modulate_play("unlaunch_flash")
#				play_audio("bling4", {"vol" : -15, "bus" : "PitchDown"})
				return true
			elif button_aux in input_state.pressed:
				animate("DodgeTransit")
				if current_guard_gauge > 0:
					reset_guard_gauge()
				return true
				
	if button_rs_up in input_state.pressed or button_rs_down in input_state.pressed or button_rs_left in input_state.pressed or \
		button_rs_right in input_state.pressed:
		animate("DodgeTransit")
		if current_guard_gauge > 0:
			reset_guard_gauge()
		return true
		
	return false
	
func dodge_check():
	if current_guard_gauge + GUARD_GAUGE_CEIL < get_stat("DODGE_GG_COST"):
		return false
	if !grounded and air_dodge <= 0:
		return false
		
	if current_guard_gauge > 0:
		reset_guard_gauge()
	else:
		change_guard_gauge(-get_stat("DODGE_GG_COST"))
		
	if Globals.survival_level != null:
		dodge_enhance()
		
	return true
	
func perfect_dodge(): # called from Game.gd
	if new_state == Em.char_state.AIR_REC and Animator.query_to_play(["DodgeTransit", "Dodge"]):
		success_dodge = true
#		if Globals.survival_level != null:
#			p_dodge_enhance()
	
#func guardtech():
#	if success_block and button_dash in input_state.pressed:
#		if dir != 0 or v_dir != 0:
#			animate("GuardTech")
#			return true
#	return false
	
#func is_burst(move_name):
#	if move_name.begins_with("Burst"):
#		return true
#	return false
	
func burst_counter_check(): # check if have resources to do it, then take away those resources and return a bool
	
	var cost = BURSTCOUNTER_EX_COST
	if Globals.survival_level != null and Inventory.has_quirk(player_ID, Cards.effect_ref.REDUCE_BURST_COST):
		cost = FMath.percent(cost, 50)
	
	if current_ex_gauge < cost:
		return false # not enough EX Gauge to use it
		
	change_ex_gauge(-cost)
	return true
	
	
func burst_escape_check(): # check if have resources to do it, then take away those resources and return a bool
	if $BurstLockTimer.is_running():
		return false
	if get_damage_percent() >= 100: # cannot Burst Escape at lethal range
		return false
		
	if Globals.survival_level == null:
		
		if current_guard_gauge >= GUARD_GAUGE_CEIL:
			change_guard_gauge(-10000) # higher cost if GG is full, but cost no Burst Token
			return true
		if burst_token != Em.burst.AVAILABLE or current_guard_gauge <= 0:
			return false # not enough resouces to use it
		
		change_guard_gauge(-BURSTESCAPE_GG_COST)
		change_burst_token(Em.burst.EXHAUSTED)
		return true
	
	else: # during Survival Burst Escape cost 1 bar of EX Gauge
		var cost = BURSTCOUNTER_EX_COST
		if Inventory.has_quirk(player_ID, Cards.effect_ref.REDUCE_BURST_COST):
			cost = FMath.percent(cost, 50)
			
		if current_ex_gauge < cost:
			return false # not enough EX Gauge to use it
			
		change_ex_gauge(-cost)
		return true
	
#func burst_extend_check(move_name): # check if have resources to do it, then take away those resources and return a bool
#	if !is_atk_active(): # active frames only
#		return false
#	if !burst_token or !chain_combo in [Em.chain_combo.NORMAL, Em.chain_combo.SPECIAL]:
#		return false
#	if UniqChar.query_move_data(move_name)[Em.move.ATK_TYPE] in [Em.atk_type.EX, Em.atk_type.SUPER]:
#		return false
#	change_burst_token(false)
#	return true
	
	
#func a_reset_check(move_name):
#
#	var move_data = UniqChar.query_move_data(move_name)
#	var cost = ALPHARESET_EX_COST
#	if Globals.survival_level != null and Inventory.has_quirk(player_ID, Cards.effect_ref.REDUCE_BURST_COST):
#		cost = 0
#
#	if !chain_combo in [Em.chain_combo.RESET]: # can only be used on whiff
#		return false
#
#	if current_ex_gauge < cost:
#		return false # not enough EX Gauge to use it
#
#	var filter := false
#
#	match move_data[Em.move.ATK_TYPE]:
#		Em.atk_type.LIGHT, Em.atk_type.FIERCE, Em.atk_type.HEAVY:
#			if is_atk_startup():
#				filter = true
#		Em.atk_type.SPECIAL:
#			if !"reset_type" in move_data: # cannot reset
#				filter = false
#			else:
#				match move_data.reset_type:
#					Globals.reset_type.STARTUP_RESET: # can only reset during startup
#						if is_atk_startup():
#							filter = true
##					Globals.reset_type.EARLY_RESET: # can only reset during first 3 frames of active frames
##						if is_atk_active() and Animator.time > 0 and Animator.time <= 3:
##							filter = true
#					Globals.reset_type.ACTIVE_RESET: # can only reset during active frames
#						if Em.move.DMG in move_data:
#							if is_atk_active() and Animator.time > 0:
#								filter = true
#						else: # for non-attacks, can only reset during active frames if targeted opponent not in hit
#							if is_atk_active() and Animator.time > 1: # not on frame 1
#								if !get_target().get_node("HitStunTimer").is_running():
#									filter = true
#
#	if filter == false: return false
#
#	change_ex_gauge(-cost)
#	afterimage_cancel()
#	return true

	
func test_jump_cancel():
	
	if !chain_combo in [Em.chain_combo.NORMAL, Em.chain_combo.HEAVY]:
		return false # can only dash cancel on Normal/Heavy hit
	
	if !grounded and air_jump == 0: return false # if in air, need >1 air jump left
		
	var move_name = get_move_name()
	if Em.atk_attr.NO_REC_CANCEL in query_atk_attr(move_name) : return false # Normals with NO_REC_CANCEL cannot be jump cancelled
	
	afterimage_cancel()
	return true
	
	
func test_dash_cancel():
	if !chain_combo in [Em.chain_combo.NORMAL, Em.chain_combo.HEAVY]:
		return false # can only dash cancel on Normal/Heavy hit
		
	if !grounded and air_dash == 0: return false # if in air, need >1 air dash left
	
	var move_name = get_move_name()
	if Em.atk_attr.NO_REC_CANCEL in query_atk_attr(move_name) : return false # Normals with NO_REC_CANCEL cannot be dash cancelled
	
	afterimage_cancel()
	return true
	
	
func test_dodge_cancel():
	
	if Globals.survival_level != null and Inventory.has_quirk(player_ID, Cards.effect_ref.DODGE_CANCEL):
		pass
	elif !chain_combo in [Em.chain_combo.NORMAL, Em.chain_combo.HEAVY]:
		return false # can only dodge cancel on Normal/Heavy hit
		
	var move_name = get_move_name()
	if Em.atk_attr.NO_REC_CANCEL in query_atk_attr(move_name) : return false # Normals with NO_REC_CANCEL cannot be dash cancelled
	
	afterimage_cancel()
	return true
	
	
func test_sdash_cancel():
	
#	if !chain_combo in [Em.chain_combo.NORMAL, Em.chain_combo.HEAVY, Em.chain_combo.SPECIAL]:
#		return false # can only s_dash cancel on Normal hit/Special hit
	
	var move_name = get_move_name()
	var move_data = UniqChar.query_move_data(move_name)
	
	if Em.atk_attr.NO_REC_CANCEL in move_data[Em.move.ATK_ATTR]:
		return false
		
	if Em.atk_attr.NO_SDASH_CANCEL in move_data[Em.move.ATK_ATTR]:
		return false
		
#	if is_atk_startup():
#		if Em.atk_attr.SDASH_STARTUP_CANCEL in move_data[Em.move.ATK_ATTR]:
#			afterimage_cancel()
#			return true
#		else:
#			return false
		
	match move_data[Em.move.ATK_TYPE]:
		Em.atk_type.LIGHT, Em.atk_type.FIERCE, Em.atk_type.HEAVY:
			if !chain_combo in [Em.chain_combo.NORMAL, Em.chain_combo.HEAVY]:
				return false # can only s_dash cancel on Normal/Heavy hit
				
			if !grounded and super_dash == 0: return false
			if is_atk_active():
				if !active_cancel:
					return false
					
		Em.atk_type.SPECIAL:
			if !is_atk_active():
				if is_atk_recovery() and Em.atk_attr.CAN_SDC_DURING_REC in move_data[Em.move.ATK_ATTR]:
					pass
				else:
					return false
			elif Em.atk_attr.NO_SDC_DURING_ACTIVE in move_data[Em.move.ATK_ATTR]:
				return false
				
			var can_reset_on_whiff := false
			if !Em.move.DMG in move_data or Em.atk_attr.WHIFF_SDASH_CANCEL in move_data[Em.move.ATK_ATTR]: # some attacks/projectiles can be sdashed on whiff
				if Animator.time > 1: # not on frame 1
					can_reset_on_whiff = true
#			elif !Em.move.DMG in move_data:
#				if Animator.time > 1: # for non-attacks, can only sdash cancel if opponent is in hitstun
##					if get_target().get_node("HitStunTimer").is_running():
#					can_reset_on_whiff = true
#			else:
#				if Em.atk_attr.WHIFF_SDASH_CANCEL in move_data[Em.move.ATK_ATTR]:
#					can_reset_on_whiff = true
			
			if !chain_combo in [Em.chain_combo.SPECIAL]:
				if chain_combo in [Em.chain_combo.RESET] and can_reset_on_whiff:
					pass # some attacks can s_dash cancel on whiffed hits
				else:
					return false # can only s_dash cancel on SPECIAL hit
				
			var cost = RESET_EX_COST
			if Globals.survival_level != null and Inventory.has_quirk(player_ID, Cards.effect_ref.REDUCE_BURST_COST):
				cost = 0
				
			if current_ex_gauge < cost:
				return false
			change_ex_gauge(-cost)
			play_audio("bling7", {"vol" : -10, "bus" : "PitchUp"})
			Globals.Game.spawn_SFX("Reset", "Shines", position, {"facing":Globals.Game.rng_facing(), \
					"v_mirror":Globals.Game.rng_bool(), "sticky_ID":player_ID}, "blue")
			modulate_play("blue_reset")
			
				
		_:
			return false
			
	afterimage_cancel()
	return true
		
#	if is_normal_attack(move_name): # normal attacks can be sdashed on recovery on hit
#		if !grounded and super_dash == 0: return false
#		if is_atk_active(): #  some normals can be sdashed on active frames, but only with active_cancel == true
#			if !active_cancel:
#				return false
#
#	elif is_atk_active() and is_non_EX_special_move(move_name):
#		var cost = RESET_EX_COST
#		if Globals.survival_level != null and Inventory.has_quirk(player_ID, Cards.effect_ref.REDUCE_BURST_COST):
#			cost = 0
#
#		if current_ex_gauge < cost:
#			return false
#		change_ex_gauge(-cost)
#
#		play_audio("bling7", {"vol" : -10, "bus" : "PitchUp"})
#		Globals.Game.spawn_SFX("Reset", "Shines", position, {"facing":Globals.Game.rng_facing(), \
#				"v_mirror":Globals.Game.rng_bool(), "sticky_ID":player_ID}, "blue")
#		modulate_play("blue_reset")
#	else:
#		return false	
#
#	afterimage_cancel()
#	return true

	
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
#func test_doubletap(button):
#	for tap in tap_memory:
#		if tap[0] == button:
#			return true
#	return false
			

# STATUS EFFECTS ---------------------------------------------------------------------------------------------------
	# rule: status_effect is array contain [effect, lifetime], effect can be a Em.status_effect enum or a string
	
func add_status_effect(status_effect: Array):
	
	var effect = status_effect[0]
	var lifetime = status_effect[1]
	
	for status_effect in status_effects: # look to see if already inflicted with the same one, if so, overwrite its lifetime if new one last longer
		if status_effect[0] == effect: # found effect already inflicted
			if lifetime != null and (status_effect[1] == null or status_effect[1] < lifetime):
				status_effect[1] = lifetime # overwrite effect if new effect last longer
			return # return after finding effect already inflicted regardless of whether you overwrite it
			
	status_effects.append(status_effect)
	new_status_effect(effect)
	
func load_status_effects(): # loading game state, reapply all one-time visual changes from status_effects
	for status_effect in status_effects:
		new_status_effect(status_effect[0])

func query_status_effect(effect):
	for status_effect in status_effects:
		if status_effect[0] == effect:
			return true
	return false
	
func query_status_effect_aux(effect):
	for status_effect in status_effects:
		if status_effect[0] == effect:
			if status_effect.size() > 2:
				return status_effect[2]
	return null
	
func process_status_effects_visual(): # called during hitstop as well
	for status_effect in status_effects:
		continue_visual_effect_of_status(status_effect[0])

func process_status_effects_timer(): # reduce lifetime and remove expired status effects (at end of frame)
#	var effect_to_erase = []
	
	for status_effect in status_effects:
		
		if status_effect[1] != null: # a lifetime of "null" means no duration
			status_effect[1] -= 1
			if status_effect[1] < 0:
				status_effect_to_remove.append(status_effect[0])
				
		match status_effect[0]:
			Em.status_effect.STUN_RECOVER: # when recovering from a combo where a Stun occur, restore Guard Gauge to 50%
				if !is_hitstunned_or_sequenced():
					status_effect_to_remove.append(status_effect[0])
					if current_guard_gauge < -5000:
						current_guard_gauge = -5000
						Globals.Game.guard_gauge_update(self)
			Em.status_effect.POS_FLOW: # positive flow ends if guard gauge returns to 0
				if current_guard_gauge >= 0:
					status_effect_to_remove.append(status_effect[0])

		
func new_status_effect(effect): # run on frame the status effect is inflicted/state is loaded, for visual effects
	match effect:
		Em.status_effect.POS_FLOW:
			Globals.Game.HUD.get_node("P" + str(player_ID + 1) + "_HUDRect/GaugesUnder/GuardGauge1").texture_progress = \
				Loader.loaded_guard_gauge_pos
		Em.status_effect.LETHAL:
			Globals.Game.lethalfreeze(get_path())
	
		
func continue_visual_effect_of_status(effect): # run every frame, will not add visual effect if there is already one of higher priority
	match effect:
		Em.status_effect.LETHAL:
			modulate_play("lethal")
			set_monochrome()
			sprite_shake()
		Em.status_effect.STUN:
			modulate_play("stun")
			particle("Sparkle", "Particles", "yellow", 4, 1, 25)
			set_monochrome() # you want to do shaders here instead of new_status_effect() since shaders can be changed
			sprite_shake()
		Em.status_effect.CRUSH:
			modulate_play("crush")
			particle("Sparkle", "Particles", "red", 4, 1, 25)
			set_monochrome()
			sprite_shake()
		Em.status_effect.RESPAWN_GRACE:
			modulate_play("respawn_grace")
		Em.status_effect.POISON:
			modulate_play("poison")

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
	
func remove_status_effect_on_landing_hit():
	status_effect_to_remove.append(Em.status_effect.POISON)
	
func remove_status_effect_on_taking_hit():
	status_effect_to_remove.append(Em.status_effect.POS_FLOW)
		
func clear_visual_effect_of_status(effect): # must run this when removing status effects to remove the visual effect
	match effect:
		Em.status_effect.LETHAL:
			Globals.Game.lethalfreeze("unfreeze")
			continue
		Em.status_effect.LETHAL, Em.status_effect.STUN, Em.status_effect.CRUSH:
			sprite.position = Vector2.ZERO
		Em.status_effect.POS_FLOW:
			Globals.Game.HUD.get_node("P" + str(player_ID + 1) + "_HUDRect/GaugesUnder/GuardGauge1").texture_progress = \
				Loader.loaded_guard_gauge

	
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
				
	
func timed_status():
	for status_effect in status_effects:
		match status_effect[0]:
			
			Em.status_effect.POISON:
				if posmod(status_effect[1], 30) == 1:
					take_DOT(status_effect[2])
					
func take_DOT(amount):
	var damage = int(min(amount, get_stat("DAMAGE_VALUE_LIMIT") - current_damage_value - 1))
	if damage > 0:
		take_damage(damage)
		Globals.Game.spawn_damage_number(damage, position, Em.dmg_num_col.GRAY)
					
	
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
			if Globals.survival_level == null: # no semi-disjoint mechanic in Survival
				polygons_queried[Em.hit.SDHURTBOX] = Animator.query_polygon("sdhurtbox")
			
		if query_status_effect(Em.status_effect.RESPAWN_GRACE):
			pass  # no hurtbox during respawn grace
		else:
			polygons_queried[Em.hit.HURTBOX] = Animator.query_polygon("hurtbox")
			
		if polygons_queried[Em.hit.HITBOX] != null or polygons_queried[Em.hit.HURTBOX] != null:
			polygons_queried[Em.hit.RECT] = get_sprite_rect()

	return polygons_queried
	
func get_sprite_rect():
	var sprite_rect = sprite.get_rect()
	return Rect2(sprite_rect.position + position, sprite_rect.size)
	
func query_move_data_and_name(): # requested by main game node when doing hit detection
	
	if Animator.to_play_anim.ends_with("Active"):
		var move_name = Animator.to_play_anim.trim_suffix("Active")
		move_name = UniqChar.refine_move_name(move_name)
		if UniqChar.MOVE_DATABASE.has(move_name):
			return {Em.hit.MOVE_DATA : UniqChar.query_move_data(move_name), Em.hit.MOVE_NAME : move_name}
		else:
			print("Error: " + move_name + " not found in MOVE_DATABASE for query_move_data_and_name().")
	else:
		print("Error: query_move_data_and_name() called by main game node outside of Active frames")
		return null
		
	
func test_aerial_memory(attack_ref): # attack_ref already has "a" added for aerial normals
	
	attack_ref = UniqChar.get_root(attack_ref) # get the root attack
	if attack_ref in aerial_memory or attack_ref in aerial_sp_memory:
		return false
		
	return true
	
	
func test_chain_combo(attack_ref): # attack_ref is the attack you want to chain to
	
	match state: # need to be in attack active/recovery
		Em.char_state.GROUND_ATK_ACTIVE, Em.char_state.AIR_ATK_ACTIVE, \
				Em.char_state.GROUND_ATK_REC, Em.char_state.AIR_ATK_REC:
			pass
		_:
			return false
			
	if !attack_ref in UniqChar.STARTERS:
		return false
	
	var move_name = Animator.current_anim.trim_suffix("Active")
	move_name = move_name.trim_suffix("Rec")
	
	if UniqChar.has_method("unique_chaining_rules") and UniqChar.unique_chaining_rules(move_name, attack_ref):
		# will use Character.chain_combo, good for autocombos that triggers on hit/block and may/may not be on whiff
		afterimage_cancel()
		return true
		
	if chain_combo == Em.chain_combo.STRONGBLOCKED: return false # cannot cancel into anything but Burst Counter if strongblockeda
	
	match query_move_data(move_name)[Em.move.ATK_TYPE]:
		Em.atk_type.LIGHT: # Light Normals can chain cancel on whiff
			pass
		Em.atk_type.FIERCE: # Fierce Normals cannot chain into Lights on whiff
			if !chain_combo in [Em.chain_combo.NORMAL, Em.chain_combo.WEAKBLOCKED] and \
					query_move_data(attack_ref)[Em.move.ATK_TYPE] == Em.atk_type.LIGHT:
				return false
		Em.atk_type.HEAVY: # Heavy Normals can only chain cancel into non-normals
			if !chain_combo in [Em.chain_combo.HEAVY]:
				return false
			if is_normal_attack(attack_ref):
				return false
		Em.atk_type.SPECIAL:
			if Globals.survival_level != null and Inventory.has_quirk(player_ID, Cards.effect_ref.SPECIAL_CHAIN):
				pass
#				if is_special_move(attack_ref):
#					pass
#				else:
#					return false
			else:
#				pass
				return false
		Em.atk_type.EX:
			if Globals.survival_level != null and Inventory.has_quirk(player_ID, Cards.effect_ref.SPECIAL_CHAIN):
				pass
			else:
#				pass
				return false
		_:
			return false
	
	if !chain_combo in [Em.chain_combo.NORMAL, Em.chain_combo.HEAVY, Em.chain_combo.SPECIAL, Em.chain_combo.WEAKBLOCKED]:
		if is_atk_active(): # cannot chain on active frames unless landed an unblocked/weakblocked hit
			return false
#		if !is_normal_attack(attack_ref): # cannot chain into non-Normals unless landed an unblocked/weakblocked hit
#			return false
	
	var root_attack_ref = UniqChar.get_root(attack_ref)
	if root_attack_ref in chain_memory: return false # cannot chain into moves already done

	if Em.atk_attr.NO_CHAIN in query_atk_attr(move_name) or Em.atk_attr.CANNOT_CHAIN_INTO in query_atk_attr(attack_ref):
		return false # some moves cannnot be chained from, some moves cannot be chained into
		
	if Em.atk_attr.ONLY_CHAIN_ON_HIT in query_atk_attr(move_name): # some attacks can only chain from on hit
		if !chain_combo in [Em.chain_combo.NORMAL]:
			return false
		
	if is_atk_active():
		if Em.atk_attr.LATE_CHAIN in query_atk_attr(move_name):
			return false  # some moves cannot be chained from during active frames
		if Em.atk_attr.LATE_CHAIN_INTO in query_atk_attr(attack_ref):
			return false # some moves cannot be chained into from other moves during their active frames
		
	afterimage_cancel()
	return true


func test_qc_chain_combo(attack_ref): # called during attack startup
	
	if !attack_ref in UniqChar.STARTERS:
		return false
	
	if chain_memory.size() == 0: return true # not chaining, can QC into any valid move

#	if !chain_combo in [Em.chain_combo.NORMAL, Em.chain_combo.WEAKBLOCKED]:
#		if !is_normal_attack(attack_ref): # cannot chain into non-Normals unless landed an unblocked/weakblocked hit
#			return false

	# cannot qc jumpsquat from Active Cancel
	if state in [Em.char_state.GROUND_STARTUP, Em.char_state.AIR_STARTUP]:
		if active_cancel:
			return false
	
	# if chaining, cannot QC into moves with CANNOT_CHAIN_INTO
	if Em.atk_attr.CANNOT_CHAIN_INTO in query_atk_attr(attack_ref):
		return false
	
	# if chaining, cannot QC into moves that go against chain_memory/aerial_memory/aerial_sp_memory rules
	attack_ref = UniqChar.get_root(attack_ref)
	if attack_ref in chain_memory:
		return false # cannot quick cancel into moves already done
	if attack_ref in aerial_memory or attack_ref in aerial_sp_memory:
		return false # cannot quick cancel into aerials already done during that jump
				
	return true
	
	
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
	
# GAUGES -----------------------------------------------------------------------------------------------------------------------------
	
func get_damage_percent() -> int:
	return FMath.get_fraction_percent(current_damage_value, get_stat("DAMAGE_VALUE_LIMIT"))
	
func get_guard_gauge_percent_below() -> int:
	if current_guard_gauge <= GUARD_GAUGE_FLOOR:
		return 0
	elif current_guard_gauge < 0:
		return 100 - FMath.get_fraction_percent(current_guard_gauge, GUARD_GAUGE_FLOOR)
	else: return 100
	
func get_guard_gauge_percent_above() -> int:
	if current_guard_gauge >= GUARD_GAUGE_CEIL:
		return 100
	elif current_guard_gauge > 0:
		return FMath.get_fraction_percent(current_guard_gauge, GUARD_GAUGE_CEIL)
	else: return 0
	
func get_guard_gauge_percent_true(): # from 0 to 100
	var value = current_guard_gauge - GUARD_GAUGE_FLOOR
	return FMath.get_fraction_percent(value, GUARD_GAUGE_CEIL - GUARD_GAUGE_FLOOR)
		
func take_damage(damage: int): # called by attacker
	var orig_damage_value = current_damage_value
	current_damage_value += damage
	current_damage_value = int(clamp(current_damage_value, 0, get_stat("DAMAGE_VALUE_LIMIT") + 9999))
	# cannot go under zero (take_damage is also used for healing)
	Globals.Game.damage_update(self, damage)
	
	if damage < 0: # for healing
		return orig_damage_value - current_damage_value
	
func change_guard_gauge(guard_gauge_change: int): # called by attacker
	current_guard_gauge += guard_gauge_change
	current_guard_gauge = int(clamp(current_guard_gauge, GUARD_GAUGE_FLOOR, GUARD_GAUGE_CEIL))
	Globals.Game.guard_gauge_update(self)
	
func reset_guard_gauge():
	current_guard_gauge = 0
	Globals.Game.guard_gauge_update(self)
	
#func change_guard_gauge_percent(guard_gauge_change_percent):
#	var guard_gauge_change = GUARD_GAUGE_CEIL * guard_gauge_change_percent
#	change_guard_gauge(guard_gauge_change)
	
#func change_guard_gauge_percent(guard_gauge_change_percent):
#	var guard_gauge_change := 0.0
#
#	if guard_gauge_change_percent < 0: # reduce GG
#		if current_guard_gauge > 0:
#
#			var GG_above_percent = get_guard_gauge_percent_above()
#			if GG_above_percent >= abs(guard_gauge_change_percent): # if enough, substract normally
#				guard_gauge_change = guard_gauge_change_percent * abs(GUARD_GAUGE_CEIL)
#
#			else: # not enough, must go under 0
#				guard_gauge_change_percent += GG_above_percent # get leftovers
#				guard_gauge_change = -current_guard_gauge # lower to 0 1st
#				guard_gauge_change += guard_gauge_change_percent * abs(GUARD_GAUGE_FLOOR) # reduce below 0
#
#		else: # GG below 0, substract normally
#			guard_gauge_change = guard_gauge_change_percent * abs(GUARD_GAUGE_FLOOR)
#
#	elif guard_gauge_change_percent > 0: # increase GG
#		if current_guard_gauge < 0:
#
#			var GG_below_percent = get_guard_gauge_percent_below()
#			if GG_below_percent <= abs(guard_gauge_change_percent): # if low enough, increase normally
#				guard_gauge_change = guard_gauge_change_percent * abs(GUARD_GAUGE_FLOOR)
#
#			else: # will go above 0
#				guard_gauge_change_percent -= 1.0 - GG_below_percent # get leftovers
#				guard_gauge_change = -current_guard_gauge # raise to 0 1st
#				guard_gauge_change += guard_gauge_change_percent * abs(GUARD_GAUGE_CEIL) # raise above 0
#
#		else: # over 0, increase normally
#			guard_gauge_change = guard_gauge_change_percent * abs(GUARD_GAUGE_CEIL)
#
#	change_guard_gauge(guard_gauge_change)
	
func get_ex_level():
	if current_ex_gauge < EX_LEVEL:
		return 0
	elif current_ex_gauge < EX_LEVEL * 2:
		return 1
	elif current_ex_gauge < MAX_EX_GAUGE:
		return 2
	else:
		return 3
	
func change_ex_gauge(ex_gauge_change: int, forced := false):
#	current_ex_gauge += ex_gauge_change * 3 # boosted for testing
	if !forced and $EXSealTimer.is_running() and ex_gauge_change > 0: # no gain in EX Gauge when sealed
		return
	current_ex_gauge += ex_gauge_change
	current_ex_gauge = int(clamp(current_ex_gauge, 0, MAX_EX_GAUGE))
	Globals.Game.ex_gauge_update(self)
	if ex_gauge_change < 0: # any usage of EX gauge seals it
		if $EXSealTimer.time < BASE_EX_SEAL_TIME:
			$EXSealTimer.time = BASE_EX_SEAL_TIME

func change_stock_points(stock_points_change: int):
	if !Globals.training_mode:
		stock_points_left += stock_points_change
		stock_points_left = int(max(stock_points_left, 0))
	Globals.Game.stock_points_update(self)
	
func change_burst_token(new_burst_token: int):
	if !Globals.training_mode:
		burst_token = new_burst_token
		Globals.Game.burst_update(self)
		
func gain_coin(to_gain: int):
	if Globals.survival_level != null:
#		to_gain = FMath.percent(to_gain, Inventory.modifier(player_ID, Cards.effect_ref.COIN_GAIN))
		coin_count += to_gain
		Globals.Game.coin_update(self)
		change_ex_gauge(3000)
	
	
# QUERY UNIQUE CHARACTER DATA ---------------------------------------------------------------------------------------------- 
	
#func query_traits(): # may have certain conditions
#	return UniqChar.query_traits()
	
func query_atk_attr(in_move_name = null):
	
	if in_move_name == null and !is_attacking(): return []
	
	var move_name = in_move_name
	if move_name == null:
		move_name = get_move_name()
	
	return UniqChar.query_atk_attr(move_name)
	
	
func query_atk_attr_current(): # used for the FrameViewer only
	if !is_attacking(): return []
	var move_name = Animator.current_anim.trim_suffix("Startup")
	move_name = move_name.trim_suffix("Active")
	move_name = move_name.trim_suffix("Rec")
	return UniqChar.query_atk_attr(move_name)
	
	
func query_priority(in_move_name = null):
	var move_name = in_move_name
	if move_name == null:
		move_name = get_move_name()
	
	var move_data = UniqChar.query_move_data(move_name)
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
	
	var move_data = UniqChar.query_move_data(move_name)
	return move_data
	
	
# LANDING A HIT ---------------------------------------------------------------------------------------------- 
	
func landed_a_hit(hit_data): # called by main game node when landing a hit
	
	var defender = Globals.Game.get_player_node(hit_data[Em.hit.DEFENDER_ID])
	if defender == null:
		return # defender is deleted
	increment_hitcount(hit_data[Em.hit.DEFENDER_ID]) # for measuring hitcount of attacks
#	targeted_opponent_path = hit_data.defender_nodepath # target last attacked opponent
	
	match hit_data[Em.hit.BLOCK_STATE]: # gain Positive Flow if unblocked, GG is under 100%, atk_level > 1, or semi-disjoint hit
		Em.block_state.UNBLOCKED:
			if current_guard_gauge < 0 and ((!hit_data[Em.hit.WEAK_HIT] and hit_data[Em.hit.ADJUSTED_ATK_LVL] > 1) or hit_data[Em.hit.SEMI_DISJOINT]):
				add_status_effect([Em.status_effect.POS_FLOW, null])

			remove_status_effect_on_landing_hit()
			
	if Globals.survival_level != null: # special effects on hit from cards
		if Inventory.has_quirk(player_ID, Cards.effect_ref.POISON_ATK):
			defender.status_effect_to_add.append([Em.status_effect.POISON, Cards.POISON_DURATION, Cards.POISON_DMG])
		if Inventory.has_quirk(player_ID, Cards.effect_ref.CHILLING_ATK):
			defender.status_effect_to_add.append([Em.status_effect.CHILL, Cards.CHILL_DURATION, Cards.CHILL_SLOW])
		if Inventory.has_quirk(player_ID, Cards.effect_ref.IGNITION_ATK):
			defender.status_effect_to_add.append([Em.status_effect.IGNITE, Cards.IGNITE_DURATION, Cards.IGNITE_DMG])
#		if Inventory.has_quirk(player_ID, Cards.effect_ref.GRAVITIZING_ATK):
#			defender.status_effect_to_add.append([Em.status_effect.GRAVITIZE, Cards.GRAVITIZE_DURATION, Cards.GRAVITIZE_DEGREE])
		if Inventory.has_quirk(player_ID, Cards.effect_ref.ENFEEBLING_ATK):
			defender.status_effect_to_add.append([Em.status_effect.ENFEEBLE, Cards.ENFEEBLE_DURATION, Cards.ENFEEBLE_DEGREE])

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
		
	if hit_data[Em.hit.DOUBLE_REPEAT]:
		chain_combo = Em.chain_combo.NO_CHAIN
	
	else:
		match hit_data[Em.hit.BLOCK_STATE]:
			
			Em.block_state.UNBLOCKED:
				match hit_data[Em.hit.MOVE_DATA][Em.move.ATK_TYPE]:
					Em.atk_type.LIGHT, Em.atk_type.FIERCE:
						chain_combo = Em.chain_combo.NORMAL
						if !Em.hit.MULTIHIT in hit_data and !Em.hit.AUTOCHAIN in hit_data:
							if hit_data[Em.hit.SWEETSPOTTED] or hit_data[Em.hit.PUNISH_HIT]: # for sweetspotted/punish Normals, allow jump/dash cancel on active
								active_cancel = true
							if is_aerial():  # for unblocked aerial you regain 1 air jump
								gain_one_air_jump()
					Em.atk_type.HEAVY:
						chain_combo = Em.chain_combo.HEAVY
						if !Em.hit.MULTIHIT in hit_data and !Em.hit.AUTOCHAIN in hit_data:
							active_cancel = true
							if is_aerial():  # for unblocked aerial you regain 1 air jump
								gain_one_air_jump()
					Em.atk_type.SPECIAL, Em.atk_type.EX:
						chain_combo = Em.chain_combo.SPECIAL
					Em.atk_type.SUPER:
						chain_combo = Em.chain_combo.SUPER
						
#				if Em.atk_attr.ACTIVE_CANCEL in hit_data[Em.hit.MOVE_DATA][Em.move.ATK_ATTR]: # for ACTIVE_CANCEL atk attr, allow certain cancels on active
#					active_cancel = true

					
			Em.block_state.WEAK:
				chain_combo = Em.chain_combo.WEAKBLOCKED
#				match hit_data[Em.hit.MOVE_DATA][Em.move.ATK_TYPE]:
#					Em.atk_type.LIGHT, Em.atk_type.FIERCE:
#						chain_combo = Em.chain_combo.WEAKBLOCKED
##						if Em.atk_attr.NO_CHAIN_ON_WEAKBLOCK in hit_data[Em.hit.MOVE_DATA][Em.move.ATK_ATTR]:
##							chain_combo = Em.chain_combo.NO_CHAIN
#					Em.atk_type.HEAVY:
#						chain_combo = Em.chain_combo.WEAKBLOCKED
#					Em.atk_type.SPECIAL, Em.atk_type.EX:
#						chain_combo = Em.chain_combo.WEAKBLOCKED
#					Em.atk_type.SUPER:
#						chain_combo = Em.chain_combo.WEAKBLOCKED
				
			Em.block_state.STRONG:
				chain_combo = Em.chain_combo.STRONGBLOCKED
#				match hit_data[Em.hit.MOVE_DATA][Em.move.ATK_TYPE]:
#					Em.atk_type.LIGHT, Em.atk_type.FIERCE:
#						chain_combo = Em.chain_combo.STRONGBLOCKED
#					Em.atk_type.HEAVY:
#						chain_combo = Em.chain_combo.HEAVY
#					Em.atk_type.SPECIAL, Em.atk_type.EX:
#						chain_combo = Em.chain_combo.SPECIAL
#					Em.atk_type.SUPER:
#						chain_combo = Em.chain_combo.SUPER
					
				
	# PUSHBACK ----------------------------------------------------------------------------------------------
		
	if Em.hit.MULTIHIT in hit_data or Em.hit.AUTOCHAIN in hit_data or !can_air_strafe(hit_data[Em.hit.MOVE_DATA]):
		pass # if an attack does not allow air strafing, it cannot be pushed back
	else:
		
		match hit_data[Em.hit.BLOCK_STATE]:
			Em.block_state.UNBLOCKED:
				
				if Globals.survival_level != null: # mob pushback when resisting or armoring
					if (Em.hit.RESISTED in hit_data or Em.hit.MOB_ARMORED in hit_data) and !Em.hit.MOB_BREAK in hit_data:
						var pushback_strength = MOBBLOCK_ATKER_PUSHBACK
						
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
								
			Em.block_state.WEAK, Em.block_state.STRONG:
				
				if Em.hit.SUPERARMORED in hit_data:
					continue
				
				var pushback_strength: = 0
				if hit_data[Em.hit.BLOCK_STATE] == Em.block_state.WEAK:
					pushback_strength = WEAKBLOCK_ATKER_PUSHBACK
				else:
					pushback_strength = STRONGBLOCK_ATKER_PUSHBACK
				
				var pushback_dir_enum = Globals.split_angle(hit_data[Em.hit.ANGLE_TO_ATKER], Em.angle_split.SIX, facing) # this return an enum
				var pushback_dir = Globals.compass_to_angle(pushback_dir_enum) # pushback for weak/strong blocked hits in 6 directions only
				
				velocity.set_vector(pushback_strength, 0)  # reset momentum
				velocity.rotate(pushback_dir)

		

	# AUDIO ----------------------------------------------------------------------------------------------
		
	if (Globals.survival_level != null and !"no_hit_sound" in hit_data) or \
			(Globals.survival_level == null and hit_data[Em.hit.BLOCK_STATE] == Em.block_state.UNBLOCKED and Em.move.HIT_SOUND in hit_data[Em.hit.MOVE_DATA]):
		
		var volume_change = 0
		if hit_data[Em.hit.LETHAL_HIT] or hit_data[Em.hit.STUN] or hit_data[Em.hit.CRUSH] or hit_data[Em.hit.SWEETSPOTTED]:
			volume_change += STRONG_HIT_AUDIO_BOOST
		elif hit_data[Em.hit.DOUBLE_REPEAT]:
			volume_change += WEAK_HIT_AUDIO_NERF # WEAK_HIT_AUDIO_NERF is negative
			
		if !hit_data[Em.hit.MOVE_DATA][Em.move.HIT_SOUND] is Array:
			
			var aux_data = hit_data[Em.hit.MOVE_DATA][Em.move.HIT_SOUND].aux_data.duplicate(true)
			if "vol" in aux_data:
				aux_data["vol"] = min(aux_data["vol"] + volume_change, 0) # max is 0
			elif volume_change < 0:
				aux_data["vol"] = volume_change
			play_audio(hit_data[Em.hit.MOVE_DATA][Em.move.HIT_SOUND].ref, aux_data)
			
		else: # multiple sounds at once
			for sound in hit_data[Em.hit.MOVE_DATA][Em.move.HIT_SOUND]:
				var aux_data = sound.aux_data.duplicate(true)
				if "vol" in aux_data:
					aux_data["vol"] = min(aux_data["vol"] + volume_change, 0) # max is 0
				elif volume_change < 0:
					aux_data["vol"] = volume_change
				play_audio(sound.ref, aux_data)
				
# ----------------------------------------------------------------------------------------------

	if Globals.survival_level != null:
		if Em.hit.DEALT_DMG in hit_data:
			var heal = FMath.percent(hit_data[Em.hit.DEALT_DMG], Inventory.modifier(player_ID, Cards.effect_ref.LIFESTEAL_RATE, true))
			if heal > 0:
				var healed = take_damage(-heal)
				if healed != null and healed > 0:
					Globals.Game.spawn_damage_number(healed, position, Em.dmg_num_col.GREEN)
					
		landed_enhance(hit_data[Em.hit.MOVE_DATA][Em.move.ATK_TYPE])
	

# TAKING A HIT ---------------------------------------------------------------------------------------------- 	

func being_hit(hit_data): # called by main game node when taking a hit
	
#	if Globals.survival_level != null and attacked_this_frame:
#		hit_data[Em.hit.CANCELLED] = true
#		return # cannot be attacked twice during survival mode
	
	if Globals.training_mode:
		$TrainingRegenTimer.time = TrainingRegenTimer_TIME

	var attacker = Globals.Game.get_player_node(hit_data[Em.hit.ATKER_ID])
#	var defender = get_node(hit_data.defender_nodepath)
	
	var attacker_or_entity = attacker # cleaner code
	if Em.hit.ENTITY_PATH in hit_data:
		attacker_or_entity = get_node(hit_data[Em.hit.ENTITY_PATH])
#		print(attacker_or_entity.entity_ID)
		
	if attacker_or_entity == null:
		hit_data[Em.hit.CANCELLED] = true
		return # attacked by something that is already deleted, return

	hit_data[Em.hit.ATKER] = attacker # for other functions
	hit_data[Em.hit.ATKER_OR_ENTITY] = attacker_or_entity
	hit_data[Em.hit.DEFENDER] = self # for hit_reactions
		
	if attacker != null:	
		attacker.target_ID = player_ID # attacker target defender
	if Globals.survival_level == null:
		target_ID = hit_data[Em.hit.ATKER_ID] # if not survival mode, target attacking opponent
	
	remove_status_effect(Em.status_effect.STUN)
	remove_status_effect(Em.status_effect.CRUSH)
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
	hit_data[Em.hit.CRUSH] = false
	hit_data[Em.hit.STUN] = false
	hit_data[Em.hit.BLOCK_STATE] = Em.block_state.UNBLOCKED
	hit_data[Em.hit.REPEAT] = false
	hit_data[Em.hit.DOUBLE_REPEAT] = false
	
	if hit_data[Em.hit.MOVE_DATA][Em.move.HITCOUNT] > 1:
		if !attacker_or_entity.is_hitcount_last_hit(player_ID, hit_data[Em.hit.MOVE_DATA]):
			hit_data[Em.hit.MULTIHIT] = true
			if attacker_or_entity.is_hitcount_first_hit(player_ID):
				hit_data[Em.hit.FIRST_HIT] = true
		else:
			hit_data[Em.hit.LAST_HIT] = true
		if !Em.hit.FIRST_HIT in hit_data:
			hit_data[Em.hit.SECONDARY_HIT] = true
	if Em.atk_attr.AUTOCHAIN in hit_data[Em.hit.MOVE_DATA][Em.move.ATK_ATTR]:
		hit_data[Em.hit.AUTOCHAIN] = true
	if Em.atk_attr.FOLLOW_UP in hit_data[Em.hit.MOVE_DATA][Em.move.ATK_ATTR]:
		hit_data[Em.hit.FOLLOW_UP] = true
		hit_data[Em.hit.SECONDARY_HIT] = true
		if !Em.hit.AUTOCHAIN in hit_data:
			hit_data[Em.hit.LAST_HIT] = true
	
	
	if Em.hit.ENTITY_PATH in hit_data and Em.move.PROJ_LVL in hit_data[Em.hit.MOVE_DATA] and hit_data[Em.hit.MOVE_DATA][Em.move.PROJ_LVL] < 3:
		hit_data[Em.hit.NON_STRONG_PROJ] = true
		
	if hit_data[Em.hit.MOVE_DATA][Em.move.ATK_TYPE] in [Em.atk_type.LIGHT, Em.atk_type.FIERCE] or Em.hit.NON_STRONG_PROJ in hit_data:
		hit_data[Em.hit.NORMALARMORABLE] = true
		
	match dir_to_attacker:
		1:
			if position.x < Globals.Game.left_corner:
				hit_data[Em.hit.CORNERED] = true
		-1:
			if position.x > Globals.Game.right_corner:
				hit_data[Em.hit.CORNERED] = true
		
	# some multi-hit moves only hit once every few frames, done via an ignore list on the attacker/entity
	if Em.hit.MULTIHIT in hit_data and Em.move.IGNORE_TIME in hit_data[Em.hit.MOVE_DATA]:
		attacker_or_entity.append_ignore_list(player_ID, hit_data[Em.hit.MOVE_DATA][Em.move.IGNORE_TIME])
		
	if !Em.hit.SECONDARY_HIT in hit_data:
		delayed_hit_effect = []
		
	if hit_data[Em.hit.SWEETSPOTTED]:
		if Em.hit.MULTIHIT in hit_data or Em.hit.AUTOCHAIN in hit_data:
			hit_data[Em.hit.SWEETSPOTTED] = false
			if !Em.hit.SWEETSPOTTED in delayed_hit_effect:
				delayed_hit_effect.append(Em.hit.SWEETSPOTTED)
				
	elif Em.hit.LAST_HIT in hit_data and Em.hit.SWEETSPOTTED in delayed_hit_effect:
		hit_data[Em.hit.SWEETSPOTTED] = true
			
	
	# REPEAT PENALTY AND WEAK HITS ----------------------------------------------------------------------------------------------
		
	if Globals.survival_level == null:
		var double_repeat := false
		var root_move_name # for move variations
		if !Em.hit.ENTITY_PATH in hit_data:
			root_move_name = attacker.UniqChar.get_root(hit_data[Em.hit.MOVE_NAME])
		elif Em.move.ROOT in hit_data[Em.hit.MOVE_DATA]: # is entity, most has a root in move_data
			root_move_name = hit_data[Em.hit.MOVE_DATA][Em.move.ROOT]
		else:
			root_move_name = hit_data[Em.hit.MOVE_NAME]
		
		if !Em.atk_attr.REPEATABLE in hit_data[Em.hit.MOVE_DATA][Em.move.ATK_ATTR]:
			for array in repeat_memory:
				if array[0] == hit_data[Em.hit.ATKER_ID] and array[1] == root_move_name:
					if !hit_data[Em.hit.REPEAT]:
						hit_data[Em.hit.REPEAT] = true # found a repeat
						if hit_data[Em.hit.MOVE_DATA][Em.move.ATK_TYPE] in [Em.atk_type.SPECIAL, Em.atk_type.EX, Em.atk_type.SUPER] or \
								Em.atk_attr.NO_REPEAT_MOVE in hit_data[Em.hit.MOVE_DATA][Em.move.ATK_ATTR]:
							double_repeat = true # if attack is non-projectile non-normal or a no repeat move, can only repeat once
							hit_data[Em.hit.DOUBLE_REPEAT] = true
							break
					elif !double_repeat:
						double_repeat = true
						hit_data[Em.hit.DOUBLE_REPEAT] = true # found multiple repeats
						break
					
			# add to repeat memory
			if !double_repeat and !Em.hit.MULTIHIT in hit_data: # for multi-hit move, only the last hit add to repeat_memory
				repeat_memory.append([attacker.player_ID, root_move_name])
		
	
	# WEAK HIT ----------------------------------------------------------------------------------------------
	
	# a Weak Hit is:
	#		one with atk_level of 1
	#		a move nerfed by Repeat Penalty
	#		a move that only hits the SDHurtbox of the target
	#		the non-final hit of a multi-hit move
	# Weak Hits cannot cause Lethal Hit, cannot cause Stun, cannot cause Sweetspotted Hits, cannot cause Punish Hits
	
	var weak_hit := false
	if (Em.move.ATK_LVL in hit_data[Em.hit.MOVE_DATA] and hit_data[Em.hit.MOVE_DATA][Em.move.ATK_LVL] <= 1) or hit_data[Em.hit.DOUBLE_REPEAT] or hit_data[Em.hit.SEMI_DISJOINT] or \
		Em.hit.MULTIHIT in hit_data:
		weak_hit = true
		hit_data[Em.hit.SWEETSPOTTED] = false
		
	hit_data[Em.hit.WEAK_HIT] = weak_hit
		
		
	# CHECK BLOCK STATE ----------------------------------------------------------------------------------------------

	if !Em.atk_attr.UNBLOCKABLE in hit_data[Em.hit.MOVE_DATA][Em.move.ATK_ATTR]:
		match new_state:
			
			# SUPERARMOR --------------------------------------------------------------------------------------------------
			
			# WEAK block_state
			# attacker can chain combo normally after hitting an armored defender
			
			Em.char_state.GROUND_ATK_STARTUP, Em.char_state.AIR_ATK_STARTUP: # can sweetspot superarmor
				if Em.atk_attr.SUPERARMOR_STARTUP in query_atk_attr() or \
						(Em.atk_attr.NORMALARMOR_STARTUP in query_atk_attr() and Em.hit.NORMALARMORABLE in hit_data):
					hit_data[Em.hit.BLOCK_STATE] = Em.block_state.WEAK
					hit_data[Em.hit.SUPERARMORED] = true
					
			Em.char_state.GROUND_ATK_ACTIVE, Em.char_state.AIR_ATK_ACTIVE:
				if Em.atk_attr.SUPERARMOR_ACTIVE in query_atk_attr() or \
						(Em.atk_attr.NORMALARMOR_ACTIVE in query_atk_attr() and Em.hit.NORMALARMORABLE in hit_data) or \
						(Em.atk_attr.PROJ_ARMOR_ACTIVE in query_atk_attr() and Em.hit.ENTITY_PATH in hit_data):
					hit_data[Em.hit.BLOCK_STATE] = Em.block_state.WEAK
					hit_data[Em.hit.SUPERARMORED] = true
						
			Em.char_state.AIR_STARTUP:
				if Animator.query_to_play(["SDashTransit"]) and Em.hit.NON_STRONG_PROJ in hit_data:
					hit_data[Em.hit.BLOCK_STATE] = Em.block_state.WEAK
					hit_data[Em.hit.SUPERARMORED] = true
					hit_data[Em.hit.SDASH_ARMORED] = true
			Em.char_state.AIR_REC:
				 # air superdash has projectile superarmor against non-strong projectiles
				if Animator.query_to_play(["SDash"]) and Em.hit.NON_STRONG_PROJ in hit_data:
					hit_data[Em.hit.BLOCK_STATE] = Em.block_state.WEAK
					hit_data[Em.hit.SUPERARMORED] = true
					hit_data[Em.hit.SDASH_ARMORED] = true
				
				
		if !is_hitstunned_or_sequenced() and !is_blocking():
			if Globals.survival_level != null and Inventory.has_quirk(player_ID, Cards.effect_ref.PASSIVE_ARMOR):
				if current_guard_gauge >= 0:
					hit_data[Em.hit.BLOCK_STATE] = Em.block_state.WEAK
					hit_data[Em.hit.SUPERARMORED] = true
			
			if has_trait(Em.trait.PERMA_SUPERARMOR):
				hit_data[Em.hit.BLOCK_STATE] = Em.block_state.WEAK
				hit_data[Em.hit.SUPERARMORED] = true
			elif has_trait(Em.trait.PASSIVE_NORMALARMOR):
				if current_guard_gauge >= 0 and Em.hit.NORMALARMORABLE in hit_data:
					var can_armor := false
					match new_state:
						Em.char_state.GROUND_ATK_STARTUP, Em.char_state.AIR_ATK_STARTUP:
							can_armor = true
						Em.char_state.GROUND_STARTUP, Em.char_state.AIR_STARTUP:
							if Animator.query_to_play(["aDashTransit", "DashTransit", "SDashTransit"]):
								can_armor = true
						Em.char_state.GROUND_D_REC, Em.char_state.AIR_D_REC:
							can_armor = true
					if can_armor:
						hit_data[Em.hit.BLOCK_STATE] = Em.block_state.WEAK
						hit_data[Em.hit.SUPERARMORED] = true
			
				
		# BLOCKING --------------------------------------------------------------------------------------------------
		
	match state:
		Em.char_state.GROUND_BLOCK, Em.char_state.AIR_BLOCK:

			hit_data[Em.hit.SWEETSPOTTED] = false # blocking will not cause sweetspot hits
			
			if Em.atk_attr.ANTI_AIR in hit_data[Em.hit.MOVE_DATA][Em.move.ATK_ATTR] and !grounded:
				hit_data[Em.hit.ANTI_AIRED] = true

			match hit_data[Em.hit.MOVE_DATA][Em.move.ATK_TYPE]:
				
				Em.atk_type.LIGHT, Em.atk_type.FIERCE:
					if attacker != null and check_if_crossed_up(attacker, hit_data[Em.hit.ANGLE_TO_ATKER]):
						hit_data[Em.hit.BLOCK_STATE] = Em.block_state.UNBLOCKED
					else:
						# to strongblock a physical attack, you need to either perfect block them or
						# block at close range, but the later is not allowed during Survival Mode
						
#						var close_enough = !attacker_vec.is_longer_than(STRONGBLOCK_RANGE)
#						if Globals.survival_level != null and close_enough:
##							if !Inventory.has_quirk(player_ID, Cards.effect_ref.PROXIMITY_PARRY):
#							close_enough = false

						if Animator.query_current(["BlockStartup", "aBlockStartup"]):
#							if Globals.survival_level != null:
#								hit_data[Em.hit.BLOCK_STATE] = Em.block_state.WEAK # no proximity parry for Survival Mode
							if Em.hit.ANTI_AIRED in hit_data:
								hit_data[Em.hit.BLOCK_STATE] = Em.block_state.WEAK # anti-air normals force weakblock on airblockers
							else:
								# if perfect blocked or blocking attacker close enough, a Strongblock occurs
								# attacker is pushed back, and cannot chain into anything except Burst Counter
								hit_data[Em.hit.BLOCK_STATE] = Em.block_state.STRONG
						elif success_block == Em.success_block.SBLOCKED:
							hit_data[Em.hit.BLOCK_STATE] = Em.block_state.STRONG
						else:
							hit_data[Em.hit.BLOCK_STATE] = Em.block_state.WEAK

				Em.atk_type.HEAVY, Em.atk_type.SPECIAL, Em.atk_type.EX: # can weakblock heavy/special/EX at high GG cost
					if attacker != null and check_if_crossed_up(attacker, hit_data[Em.hit.ANGLE_TO_ATKER]):
						hit_data[Em.hit.BLOCK_STATE] = Em.block_state.UNBLOCKED
					else:
						hit_data[Em.hit.BLOCK_STATE] = Em.block_state.WEAK
					
				Em.atk_type.SUPER: # can weakblock super
					if attacker != null and check_if_crossed_up(attacker, hit_data[Em.hit.ANGLE_TO_ATKER]):
						hit_data[Em.hit.BLOCK_STATE] = Em.block_state.UNBLOCKED
					else:
						hit_data[Em.hit.BLOCK_STATE] = Em.block_state.WEAK
					
				Em.atk_type.ENTITY, Em.atk_type.SUPER_ENTITY: # projectiles always cause Weakblock, but some projectiles are UNBLOCKABLE
#					if check_if_crossed_up(attacker_or_entity, hit_data[Em.hit.ANGLE_TO_ATKER]):
#						hit_data[Em.hit.BLOCK_STATE] = Em.block_state.UNBLOCKED
					if Em.atk_attr.UNBLOCKABLE in hit_data[Em.hit.MOVE_DATA][Em.move.ATK_ATTR]:
						hit_data[Em.hit.BLOCK_STATE] = Em.block_state.UNBLOCKED
					else:
						if !check_if_crossed_up(attacker_or_entity, hit_data[Em.hit.ANGLE_TO_ATKER]):
							if success_block == Em.success_block.SBLOCKED or Animator.query_current(["BlockStartup", "aBlockStartup"]): # can perfect block projectiles
								hit_data[Em.hit.BLOCK_STATE] = Em.block_state.STRONG
							elif Globals.survival_level != null and Inventory.has_quirk(player_ID, Cards.effect_ref.AUTO_PBLOCK_PROJ):
								hit_data[Em.hit.BLOCK_STATE] = Em.block_state.STRONG
							else:
								hit_data[Em.hit.BLOCK_STATE] = Em.block_state.WEAK
						else:
							hit_data[Em.hit.BLOCK_STATE] = Em.block_state.WEAK
				
			
	# CHECK PUNISH HIT ----------------------------------------------------------------------------------------------
	
	var punish_hit := false
	if (!hit_data[Em.hit.WEAK_HIT] or Em.hit.MULTIHIT in hit_data) and (!Em.hit.NON_STRONG_PROJ in hit_data or \
			Em.atk_attr.PUNISH_ENTITY in hit_data[Em.hit.MOVE_DATA][Em.move.ATK_ATTR]) and \
			(Em.move.DMG in hit_data[Em.hit.MOVE_DATA] and hit_data[Em.hit.MOVE_DATA][Em.move.DMG] > 0) and \
			!Em.hit.SUPERARMORED in hit_data:
		# cannot Punish Hit for weak hits, non-strong projectiles and non-damaging moves like Burst
		# remember that multi-hit moves cannot do punish hits
		match new_state:
			Em.char_state.GROUND_ATK_STARTUP, Em.char_state.AIR_ATK_STARTUP:
				if Em.atk_attr.CRUSH in hit_data[Em.hit.MOVE_DATA][Em.move.ATK_ATTR]:
					punish_hit = true
			Em.char_state.GROUND_ATK_ACTIVE, Em.char_state.GROUND_ATK_REC, \
				Em.char_state.AIR_ATK_ACTIVE, Em.char_state.AIR_ATK_REC:
				punish_hit = true
			# check for Punish Hits for dashes
			Em.char_state.GROUND_STARTUP:
				if has_trait(Em.trait.VULN_GRD_DASH): # fast characters have VULN_GRD_DASH
					if Animator.query_to_play(["DashTransit"]):
						punish_hit = true
			Em.char_state.GROUND_D_REC:
				if has_trait(Em.trait.VULN_GRD_DASH): # fast characters have VULN_GRD_DASH
					punish_hit = true
			Em.char_state.AIR_STARTUP:
				if has_trait(Em.trait.VULN_AIR_DASH): # most characters except heavyweights have VULN_AIR_DASH
					if Animator.query_to_play(["aDashTransit", "SDashTransit"]):
						punish_hit = true
			Em.char_state.AIR_REC:
				if Animator.query_to_play(["DodgeRec", "SDash"]):
					punish_hit = true
			Em.char_state.AIR_D_REC:
				if has_trait(Em.trait.VULN_AIR_DASH): # most characters except heavyweights have VULN_AIR_DASH
					punish_hit = true
			Em.char_state.AIR_C_REC:
				if Animator.query_to_play(["DodgeCRec"]):
					punish_hit = true
			
	if punish_hit:
		if Em.hit.MULTIHIT in hit_data or Em.hit.AUTOCHAIN in hit_data:
			if !Em.hit.PUNISH_HIT in delayed_hit_effect:
				delayed_hit_effect.append(Em.hit.PUNISH_HIT)
		else:
			hit_data[Em.hit.PUNISH_HIT] = true
			
	elif Em.hit.LAST_HIT in hit_data and Em.hit.PUNISH_HIT in delayed_hit_effect:
		hit_data[Em.hit.PUNISH_HIT] = true
						
	if hit_data[Em.hit.PUNISH_HIT] and Em.atk_attr.CRUSH in hit_data[Em.hit.MOVE_DATA][Em.move.ATK_ATTR]:
		hit_data[Em.hit.CRUSH] = true
			
	# GUARD SWELL ---------------------------------------------------------------------------------
					
#	if Globals.survival_level == null:	
	if (hit_data[Em.hit.MOVE_DATA][Em.move.HITCOUNT] > 1 and !Em.hit.FIRST_HIT in hit_data) or Em.hit.FOLLOW_UP in hit_data:
		pass # multi-hit moves not the first hit and autochain follow-ups do not proc Guard Swell
	else:
		if GG_swell_flag == false: # start GG swell if not started yet and hit with most attacks
			GG_swell_flag = true
			first_hit_flag = true
		else: # hit after GG swell started, turn off first_hit_flag to gaining GG
			first_hit_flag = false
	
	# ZEROTH REACTION (before damage) ---------------------------------------------------------------------------------
	
	# unique reactions
	if Em.hit.ENTITY_PATH in hit_data:
		if attacker_or_entity.UniqEntity.has_method("landed_a_hit0"):
			attacker_or_entity.UniqEntity.landed_a_hit0(hit_data) # reaction, can change hit_data from there
	elif attacker != null and attacker.UniqChar.has_method("landed_a_hit0"):
		attacker.UniqChar.landed_a_hit0(hit_data) # reaction, can change hit_data from there
	
	if UniqChar.has_method("being_hit0"):	
		UniqChar.being_hit0(hit_data) # reaction, can change hit_data from there
		
	if Em.hit.CANCELLED in hit_data:
		return
	
	# DAMAGE AND GUARD DRAIN/GAIN CALCULATION ------------------------------------------------------------------
	
	# attack level
	var adjusted_atk_level: int = 1
	
	if !Em.move.SEQ in hit_data[Em.hit.MOVE_DATA]:
		
		if !Em.move.ATK_LVL in hit_data[Em.hit.MOVE_DATA]:
			hit_data[Em.hit.CANCELLED] = true
			return # just in case
		
		adjusted_atk_level = adjusted_atk_level(hit_data)
		hit_data[Em.hit.ADJUSTED_ATK_LVL] = adjusted_atk_level
		
		change_guard_gauge(calculate_guard_gauge_change(hit_data)) # do GG calculation
		if can_stun(hit_data):
			hit_data[Em.hit.STUN] = true
			hit_data[Em.hit.BLOCK_STATE] = Em.block_state.UNBLOCKED
			hit_data.erase(Em.hit.SUPERARMORED)
		elif get_guard_gauge_percent_below() == 0:
			hit_data[Em.hit.BLOCK_STATE] = Em.block_state.UNBLOCKED
			hit_data.erase(Em.hit.SUPERARMORED)
		
		var damage = calculate_damage(hit_data)
		take_damage(damage) # do damage calculation
		hit_data[Em.hit.DEALT_DMG] = damage
		if damage > 0:
			if Globals.survival_level == null:
				if hit_data[Em.hit.DOUBLE_REPEAT] or adjusted_atk_level == 1 or hit_data[Em.hit.BLOCK_STATE] != Em.block_state.UNBLOCKED:
					Globals.Game.spawn_damage_number(damage, position, Em.dmg_num_col.GRAY)
				else:
					Globals.Game.spawn_damage_number(damage, hit_data[Em.hit.HIT_CENTER])
			else:
				Globals.Game.spawn_damage_number(damage, position, Em.dmg_num_col.RED)

			
	# FIRST REACTION (after damage) ---------------------------------------------------------------------------------
	
	# unique reactions
	if Em.hit.ENTITY_PATH in hit_data:
		if attacker_or_entity.UniqEntity.has_method("landed_a_hit"):
			attacker_or_entity.UniqEntity.landed_a_hit(hit_data) # reaction, can change hit_data from there
	elif attacker != null and attacker.UniqChar.has_method("landed_a_hit"):
		attacker.UniqChar.landed_a_hit(hit_data) # reaction, can change hit_data from there
	
	if UniqChar.has_method("being_hit"):	
		UniqChar.being_hit(hit_data) # reaction, can change hit_data from there
	
	# ---------------------------------------------------------------------------------
	
	if adjusted_atk_level > 1 and hit_data[Em.hit.BLOCK_STATE] == Em.block_state.UNBLOCKED:
		remove_status_effect_on_taking_hit()
	
	if Em.move.SEQ in hit_data[Em.hit.MOVE_DATA]: # hitgrabs and sweetgrabs will add sequence to move_data on sweetspot/non double repeat
		if hit_data[Em.hit.SEMI_DISJOINT] or hit_data[Em.hit.DOUBLE_REPEAT]:
			return
		if Em.atk_attr.QUICK_GRAB in hit_data[Em.hit.MOVE_DATA][Em.move.ATK_ATTR] and new_state in [Em.char_state.GROUND_STARTUP, \
				Em.char_state.AIR_STARTUP]:
			return # quick grabs fail if target is in movement startup
		if is_atk_startup() and Em.atk_attr.GRAB_INVULN_STARTUP in query_atk_attr():
			return # grabs fail if target is in attack startup with an attack with GRAB_INVULN_STARTUP atk attr
		attacker_or_entity.landed_a_sequence(hit_data)
		return
		
	if !Em.hit.ENTITY_PATH in hit_data and attacker != null:
		Globals.Game.get_node("Players").move_child(attacker, 0) # move attacker to bottom layer to see defender easier
	

	# knockback
	var knockback_dir: int = calculate_knockback_dir(hit_data)
	hit_data[Em.hit.KB_ANGLE] = knockback_dir
	var knockback_strength: int = calculate_knockback_strength(hit_data)
	hit_data[Em.hit.KB] = knockback_strength

	# lethal hit, must have enough launch power to trigger it
	if can_lethal(hit_data): # check for lethal
		if hit_data[Em.hit.BLOCK_STATE] in [Em.block_state.UNBLOCKED]:
			hit_data[Em.hit.LETHAL_HIT] = true
			knockback_strength = lethal_knockback(hit_data, knockback_strength)
				
	if !hit_data[Em.hit.LETHAL_HIT]:
		lethal_flag = false
	else:
		lethal_flag = true
		
	if Em.move.BURST in hit_data[Em.hit.MOVE_DATA] and !hit_data[Em.hit.DOUBLE_REPEAT] and attacker != null:
		if hit_data[Em.hit.MOVE_DATA][Em.move.BURST] == "BurstCounter":
			attacker.reset_jumps()
			attacker.change_ex_gauge(FMath.percent(attacker.get("BURSTCOUNTER_EX_COST"), 50), true)
			# Burst Counter grants attacker Positive Flow
			if attacker.current_guard_gauge < 0:
#				attacker.add_status_effect(Em.status_effect.POS_FLOW, null)
				attacker.status_effect_to_add.append([Em.status_effect.POS_FLOW, null])
				
		elif hit_data[Em.hit.MOVE_DATA][Em.move.BURST] == "BurstEscape":
			attacker.reset_jumps()
			
#		elif hit_data[Em.hit.MOVE_DATA].burst == "BurstExtend":
#			if hit_data[Em.hit.BLOCK_STATE] == Em.block_state.UNBLOCKED:
#				attacker.reset_jumps()
#				current_guard_gauge = 0
#				Globals.Game.guard_gauge_update(self)
#				hit_data[Em.hit.CRUSH] = true
				
		
		
	# SPECIAL HIT EFFECTS ---------------------------------------------------------------------------------
	
	# for moves that automatically chain into more moves, will not cause lethal or break hits, will have fixed_hitstop and no KB boost

	# gain POS_FLOW on strongblock
	if hit_data[Em.hit.BLOCK_STATE] == Em.block_state.STRONG and current_guard_gauge < 0:
		add_status_effect([Em.status_effect.POS_FLOW, null])

	if hit_data[Em.hit.DOUBLE_REPEAT]:
		modulate_play("repeat")
#		add_status_effect(Em.status_effect.REPEAT, 10)

	elif hit_data[Em.hit.SEMI_DISJOINT] and !Em.atk_attr.VULN_LIMBS in query_atk_attr(): # SD Hit sound
		play_audio("bling3", {"bus" : "LowPass"})
		
	elif hit_data[Em.hit.STUN]:
#		add_status_effect(Em.status_effect.STUN, 0)
		status_effect_to_add.append([Em.status_effect.STUN, 0])
		status_effect_to_add.append([Em.status_effect.STUN_RECOVER, null])
#		add_status_effect(Em.status_effect.STUN_RECOVER, null) # null means no duration
		repeat_memory = [] # reset move memory for getting a Break
		Globals.Game.set_screenshake() # screenshake
		modulate_play("stun_flash")
		play_audio("break1", {"vol" : -18})
		
	elif hit_data[Em.hit.LETHAL_HIT]:
#		add_status_effect(Em.status_effect.LETHAL, 0)
		status_effect_to_add.append([Em.status_effect.LETHAL, 0])
		Globals.Game.set_screenshake()
		modulate_play("lethal_flash")
		play_audio("lethal1", {"vol" : -5, "bus" : "Reverb"})
#		if Globals.survival_level != null:
##			add_status_effect(Em.status_effect.SURVIVAL_GRACE, null)
#			status_effect_to_add.append([Em.status_effect.SURVIVAL_GRACE, null])
		
	elif hit_data[Em.hit.CRUSH]:
#		add_status_effect(Em.status_effect.CRUSH, 0)
		status_effect_to_add.append([Em.status_effect.CRUSH, 0])
		modulate_play("stun_flash")
		play_audio("rock2", {"vol" : -7})
		
	elif hit_data[Em.hit.PUNISH_HIT] and hit_data[Em.hit.SWEETSPOTTED]:
		modulate_play("punish_sweet_flash")
		play_audio("break2", {"vol" : -15})
		play_audio("impact29", {"vol" : -18, "bus" : "LowPass"})
		
	elif hit_data[Em.hit.PUNISH_HIT]:
		modulate_play("punish_flash")
		play_audio("impact29", {"vol" : -18, "bus" : "LowPass"})
		
	elif hit_data[Em.hit.SWEETSPOTTED]:
		modulate_play("sweet_flash")
		play_audio("break2", {"vol" : -15})
		
	elif hit_data[Em.hit.BLOCK_STATE] != Em.block_state.UNBLOCKED:
		match hit_data[Em.hit.BLOCK_STATE]:
			Em.block_state.WEAK:
				if Em.hit.SUPERARMORED in hit_data:
					modulate_play("armor_flash")
					play_audio("block3", {"vol" : -15})
				elif hit_data[Em.hit.MOVE_DATA][Em.move.ATK_TYPE] in [Em.atk_type.SPECIAL, Em.atk_type.EX, \
						Em.atk_type.SUPER, Em.atk_type.SUPER_ENTITY]:
					modulate_play("weakblock_flash")
					play_audio("block3", {"vol" : -15})
				else:
					modulate_play("weakblock_flash")
					play_audio("block1", {"vol" : -10, "bus" : "LowPass"})
			Em.block_state.STRONG:
				modulate_play("strongblock_flash")
				play_audio("bling2", {"vol" : -8, "bus" : "PitchDown"})


	elif Globals.survival_level != null and !hit_data[Em.hit.WEAK_HIT] and !Em.hit.AUTOCHAIN in hit_data:
#		add_status_effect(Em.status_effect.SURVIVAL_GRACE, null)
#		status_effect_to_add.append([Em.status_effect.SURVIVAL_GRACE, null])
		modulate_play("punish_sweet_flash")
		play_audio("impact29", {"vol" : -10, "bus" : "LowPass"})
				
	if !hit_data[Em.hit.STUN] and !hit_data[Em.hit.LETHAL_HIT] and Em.atk_attr.SCREEN_SHAKE in hit_data[Em.hit.MOVE_DATA][Em.move.ATK_ATTR]:
		Globals.Game.set_screenshake()
	
			
	# -------------------------------------------------------------------------------------------
	
#	if adjusted_atk_level > 1:
##		if Globals.survival_level == null:
##			if !hit_data[Em.hit.BLOCK_STATE] in [Em.block_state.STRONG]:
##				 # loses Positive Flow for atk_level > 1 if not strongblocked
##				status_effect_to_remove.append(Em.status_effect.POS_FLOW)
##				# remove it at end of frame, this way both players loses positive flow during clashes
##
##		else: # for Survival Mode, do not lose POS_FLOW when blocking attacks
#		if hit_data[Em.hit.BLOCK_STATE] == Em.block_state.UNBLOCKED:
#			status_effect_to_remove.append(Em.status_effect.POS_FLOW)
		
	$VarJumpTimer.stop()
	
	# HITSTUN -------------------------------------------------------------------------------------------
	
	if hit_data[Em.hit.BLOCK_STATE] == Em.block_state.UNBLOCKED:
		if !hit_data[Em.hit.DOUBLE_REPEAT] and adjusted_atk_level <= 1 and $HitStunTimer.is_running():
			# for atk level 1 hits on hitstunned opponent, add their hitstun to existing hitstun
			$HitStunTimer.time = $HitStunTimer.time + calculate_hitstun(hit_data)
		else:
			$HitStunTimer.time = calculate_hitstun(hit_data)
			launchstun_rotate = 0 # used to calculation sprite rotation during launched state
	
	# HITSTOP ---------------------------------------------------------------------------------------------------
	
	if !hit_data[Em.hit.LETHAL_HIT]:
		hitstop = calculate_hitstop(hit_data, knockback_strength)
	else:
		hitstop = LETHAL_HITSTOP # set for defender, attacker has no hitstop during LETHAL_HITSTOP
								# screenfreeze for everyone but the defender till their hitstop is over
		
	hit_data[Em.hit.HITSTOP] = hitstop # send this to attacker as well
	
#	if hit_data[Em.hit.BLOCK_STATE] == Em.block_state.WEAK and \
#			hit_data[Em.hit.MOVE_DATA][Em.move.ATK_TYPE] in [Em.atk_type.HEAVY, Em.atk_type.SPECIAL, Em.atk_type.EX, \
#			Em.atk_type.SUPER, Em.atk_type.SUPER_ENTITY]:
#		hitstop += 10 # extra hitstop when blocking heavy/special/ex/super

	if hit_data[Em.hit.STUN]:
		hitstop = STUN_TIME # overwrite fixed hitstop for stun time when Stunned
	elif hit_data[Em.hit.CRUSH]:
		hitstop = CRUSH_TIME
		
	if hitstop > 0: # will freeze in place if colliding 1 frame after hitstop, more if has ignore_time, to make multi-hit projectiles more consistent
		if Em.hit.MULTIHIT in hit_data and Em.move.IGNORE_TIME in hit_data[Em.hit.MOVE_DATA]:
			$NoCollideTimer.time = hit_data[Em.hit.MOVE_DATA][Em.move.IGNORE_TIME]
		else:
			$NoCollideTimer.time = 1
	
	if !hit_data[Em.hit.DOUBLE_REPEAT]: # lock Burst Escape for a few frames afterwards, some moves like Autochain moves lock for more
		if Em.move.BURSTLOCK in hit_data[Em.hit.MOVE_DATA]:
			$BurstLockTimer.time = hit_data[Em.hit.MOVE_DATA][Em.move.BURSTLOCK]
		elif Em.hit.AUTOCHAIN in hit_data: # autochain moves will lock Burst/DI for 10 frames minimum
			$BurstLockTimer.time = AC_BurstLockTimer_TIME
		elif Em.hit.MULTIHIT in hit_data and Em.move.IGNORE_TIME in hit_data[Em.hit.MOVE_DATA] and hit_data[Em.hit.MOVE_DATA][Em.move.IGNORE_TIME] > BurstLockTimer_TIME:
			$BurstLockTimer.time = hit_data[Em.hit.MOVE_DATA][Em.move.IGNORE_TIME]
		else:
			$BurstLockTimer.time = BurstLockTimer_TIME
			
	if Em.hit.AUTOCHAIN in hit_data or Em.hit.MULTIHIT in hit_data:
		DI_seal = true
	else:
		DI_seal = false
		
	if Em.atk_attr.DI_MANUAL_SEAL in hit_data[Em.hit.MOVE_DATA][Em.move.ATK_ATTR]:
		$BurstLockTimer.time = 9999
		DI_seal = true
	
#	# SECOND REACTION (after knockback) ---------------------------------------------------------------------------------

	if Em.hit.ENTITY_PATH in hit_data:
		if attacker_or_entity.UniqEntity.has_method("landed_a_hit2"):
			attacker_or_entity.UniqEntity.landed_a_hit2(hit_data) # reaction, can change hit_data from there
	elif attacker != null and attacker.UniqChar.has_method("landed_a_hit2"):
		attacker.UniqChar.landed_a_hit2(hit_data) # reaction, can change hit_data from there
	
	if UniqChar.has_method("being_hit2"):	
		UniqChar.being_hit2(hit_data) # reaction, can change hit_data from there
	
	# HITSPARK ---------------------------------------------------------------------------------------------------
	
	if hit_data[Em.hit.BLOCK_STATE] == Em.block_state.UNBLOCKED:
		generate_hitspark(hit_data)
	else:
		generate_blockspark(hit_data)
		
	if hit_data[Em.hit.STUN]: # stunspark is on top of regular hitspark
		Globals.Game.spawn_SFX("Stunspark", "Stunspark", hit_data[Em.hit.HIT_CENTER], {"facing":Globals.Game.rng_facing(), \
				"v_mirror":Globals.Game.rng_bool()})
	elif hit_data[Em.hit.CRUSH]:
		Globals.Game.spawn_SFX("Crushspark", "Stunspark", hit_data[Em.hit.HIT_CENTER], {"facing":Globals.Game.rng_facing(), \
				"v_mirror":Globals.Game.rng_bool()})
	
	# ---------------------------------------------------------------------------------------------------
			
#	var knockback_unit_vec := Vector2(1, 0).rotated(knockback_dir)

	var no_impact_and_vel_change := false
	
	if Em.hit.SUPERARMORED in hit_data:
		if grounded:
			var knock_dir := 0
			var segment = Globals.split_angle(knockback_dir, Em.angle_split.FOUR, hit_data[Em.hit.ATK_FACING])
			match segment:
				Em.compass.E:
					knock_dir = 1
				Em.compass.W:
					knock_dir = -1
			if knock_dir != 0:
				move_amount(Vector2(knock_dir * 7, 0), $PlayerCollisionBox, $SoftPlatformDBox, create_checklist(), true)
				set_true_position()
		return


	if hit_data[Em.hit.BLOCK_STATE] == Em.block_state.UNBLOCKED:
			
		# if knockback_strength is high enough, get launched, else get flinched
		if Globals.survival_level == null and (knockback_strength < LAUNCH_THRESHOLD or adjusted_atk_level <= 1):

#			if !Em.hit.ENTITY_PATH in hit_data:
#				face(dir_to_attacker) # turn towards attacker
#			else:
#				if attacker_or_entity.velocity.x == 0:
#					face(dir_to_attacker) # face towards entity if it is not moving horizontally
#				else:
#					face(-attacker_or_entity.velocity.x) # face same direction as entity if it is moving horizontally

			var no_impact := false
			
			if adjusted_atk_level <= 1: # for attack level 1 attacks
#				if knockback_strength > LAUNCH_THRESHOLD: knockback_strength = LAUNCH_THRESHOLD - FMath.S # just in case
				
				if $HitStunTimer.is_running(): # for hitstunned defender
					if state == Em.char_state.LAUNCHED_HITSTUN:
						no_impact_and_vel_change = true
						# if defender is hit by atk level 1 attack while in launched state, no impact/velocity change (just added hitstun)
						# if they are flinched, will enter new flinch animation with added hitstun and has velocity change
						
				# for atk level 1 attack on non-passive state, just push them back, no turn
				# if is in passive state, will enter impact animation but 0 hitstun
				elif !state in [Em.char_state.GROUND_STANDBY, Em.char_state.GROUND_REC, \
					Em.char_state.GROUND_C_REC, Em.char_state.AIR_STANDBY, Em.char_state.AIR_REC, \
					Em.char_state.AIR_C_REC]:
					no_impact = true
						
			if !no_impact and !no_impact_and_vel_change:
				if !Em.hit.PULL in hit_data:
					var segment = Globals.split_angle(knockback_dir, Em.angle_split.TWO, -dir_to_attacker)
					match segment:
						Em.compass.E:
							face(-1) # face other way
						Em.compass.W:
							face(1)
				else:
					face(dir_to_attacker)
#					match segment:
#						Em.compass.E:
#							face(1)
#						Em.compass.W:
#							face(-1)
				
#				if knockback_dir == 90 or knockback_dir == 270:
#					face(dir_to_attacker) # turn towards attacker/entity if hit straight up/down
#				else:
#					face(-sign(knockback_unit_vec.x))

				var alternate_flag := false # alternate hitstun for multi-hit flinch during hitstop
				if state == Em.char_state.AIR_FLINCH_HITSTUN:
					if Animator.query_current(["aFlinchAStop"]):
						animate("aFlinchBStop")
						alternate_flag = true
					elif Animator.query_current(["aFlinchBStop"]):
						animate("aFlinchAStop")
						alternate_flag = true
				elif state == Em.char_state.GROUND_FLINCH_HITSTUN:
					if Animator.query_current(["FlinchAStop"]):
						animate("FlinchBStop")
						alternate_flag = true
					elif Animator.query_current(["FlinchBStop"]):
						animate("FlinchAStop")
						alternate_flag = true
				
				if !alternate_flag:
					if hit_data[Em.hit.HIT_CENTER].y >= position.y: # A/B depending on height hit
						if grounded:
							animate("FlinchAStop")
						else:
							animate("aFlinchAStop")
					else:
						if grounded:
							animate("FlinchBStop")
						else:
							animate("aFlinchBStop")
					
		else: # launch
			
			if wall_slammed != Em.wall_slam.HAS_SLAMMED:
				if !Em.hit.AUTOCHAIN in hit_data and !Em.hit.MULTIHIT in hit_data:
					wall_slammed = Em.wall_slam.CAN_SLAM
				else:
					wall_slammed = Em.wall_slam.CANNOT_SLAM
			
			knockback_strength += LAUNCH_BOOST
			var segment = Globals.split_angle(knockback_dir, Em.angle_split.EIGHT, dir_to_attacker)
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
					
	else: # blocking
			
		if !Em.hit.ENTITY_PATH in hit_data:
			
			face(dir_to_attacker) # blocking non-entities always turn towards attacker only

		else: # blocking entities turn against knockback_dir
			
			var segment = Globals.split_angle(knockback_dir, Em.angle_split.TWO, -dir_to_attacker)
			match segment:
				Em.compass.E:
					face(-1) # face other way
				Em.compass.W:
					face(1)
		
		match hit_data[Em.hit.BLOCK_STATE]:
			Em.block_state.STRONG:
				success_block = Em.success_block.SBLOCKED # can cancel block recovery
			Em.block_state.WEAK:
				success_block = Em.success_block.WBLOCKED # cannot cancel block recovery
			_:
				success_block = Em.success_block.NONE
					
					
	if !no_impact_and_vel_change:
		velocity.set_vector(knockback_strength, 0)  # reset momentum
		velocity.rotate(knockback_dir)
		
		if hit_data[Em.hit.BLOCK_STATE] != Em.block_state.UNBLOCKED and grounded:
			velocity.y = 0 # set to horizontal pushback on blocking defender
			
			
	if Globals.survival_level != null and get_tree().get_nodes_in_group("MobNodes").size() > 0:
		being_hit_enhance()
			
#	if Globals.survival_level != null and $HitStunTimer.is_running():
#		attacked_this_frame = true
		
#	print(knockback_dir)
#	print(velocity.x)
#	print(velocity.y)	
	
#	var knockback_velocity = knockback_unit_vec * knockback_strength
#
#	if hit_data[Em.hit.BLOCK_STATE] != Em.block_state.UNBLOCKED and grounded:
#		knockback_velocity.y = 0 # set to horizontal pushback on blocking defender
#
#	velocity = knockback_velocity

		
# HIT CALCULATION ---------------------------------------------------------------------------------------------------
	
func can_lethal(hit_data): # only strong hits can Guardbreak and Lethal Hit (but all moves except non-strong proj can Punish Hit)
	if get_damage_percent() < 100:
		return false
	if hit_data[Em.hit.WEAK_HIT] or Em.hit.AUTOCHAIN in hit_data or hit_data[Em.hit.MOVE_DATA][Em.move.DMG] <= 0:
		return false
	if "MOB" in hit_data[Em.hit.ATKER_OR_ENTITY] or "MOB_ENTITY" in hit_data[Em.hit.ATKER_OR_ENTITY]:
		return true
	if hit_data[Em.hit.KB] < LAUNCH_THRESHOLD:
		return false
	if hit_data[Em.hit.SWEETSPOTTED]:
		return true
		# non-strong hits that become strong hits via Sweetspotting may still not give lethal hits if knockback is lacking
	if get_damage_percent() < 150:
		if Em.hit.NON_STRONG_PROJ in hit_data:
			return false
		if hit_data[Em.hit.MOVE_DATA][Em.move.ATK_TYPE] in [Em.atk_type.LIGHT, Em.atk_type.FIERCE]:
			return false
	return true
	# at 150% damage, any non-strong hits with high enough knockback will lethal, and any attack can Guardbreak on unblock/Base Block
	
func can_stun(hit_data):
	if get_guard_gauge_percent_below() > 1:
		return false # setting to 0.01 instead of 0 allow multi-hit moves to cause Stun on the last attack
	if query_status_effect(Em.status_effect.STUN_RECOVER):
		return false
	if hit_data[Em.hit.WEAK_HIT] or Em.hit.AUTOCHAIN in hit_data or hit_data[Em.hit.MOVE_DATA][Em.move.DMG] <= 0:
		return false # autochain moves will not stun, only the autochain finisher can
	if Em.hit.NON_STRONG_PROJ in hit_data:
		return false
	if "MOB" in hit_data[Em.hit.ATKER_OR_ENTITY] or "MOB_ENTITY" in hit_data[Em.hit.ATKER_OR_ENTITY]:
		return true
	if hit_data[Em.hit.MOVE_DATA][Em.move.ATK_TYPE] in [Em.atk_type.LIGHT]:# Lights cannot Stun, but Fierce can
		return false
	return true
		
func calculate_damage(hit_data) -> int:
	
#	var attacker_or_entity = get_node(hit_data.attacker_nodepath) # cleaner code
#	if Em.hit.ENTITY_PATH in hit_data:
#		attacker_or_entity = get_node(hit_data[Em.hit.ENTITY_PATH])
#
#	var defender = get_node(hit_data.defender_nodepath)
	
	var scaled_damage: int = hit_data[Em.hit.MOVE_DATA][Em.move.DMG] * FMath.S
	if scaled_damage == 0: return 0
	
	if hit_data[Em.hit.SEMI_DISJOINT]:
		if Em.atk_attr.VULN_LIMBS in query_atk_attr():
			pass # VULN_LIMBS trait cause SD hits to do damage
#			scaled_damage = FMath.percent(scaled_damage, 100)
		else:
			return 0
	elif hit_data[Em.hit.DOUBLE_REPEAT]:
		scaled_damage = FMath.percent(scaled_damage, REPEAT_DMG_MOD)
	else:
		if hit_data[Em.hit.STUN]:
			scaled_damage = FMath.percent(scaled_damage, STUN_DMG_MOD)
		if hit_data[Em.hit.SWEETSPOTTED]:
			scaled_damage = FMath.percent(scaled_damage, SWEETSPOT_DMG_MOD)
		if hit_data[Em.hit.PUNISH_HIT]:
			scaled_damage = FMath.percent(scaled_damage, PUNISH_DMG_MOD)

	if current_guard_gauge > 0: # damage is reduced by defender's Guard Gauge when it is > 100%
		scaled_damage = FMath.f_lerp(scaled_damage, FMath.percent(scaled_damage, DMG_REDUCTION_AT_MAX_GG), get_guard_gauge_percent_above())

	if hit_data[Em.hit.BLOCK_STATE] != Em.block_state.UNBLOCKED:
		if hit_data[Em.hit.BLOCK_STATE] == Em.block_state.WEAK:
			# each character take different amount of chip damage
#			if Em.hit.SUPERARMORED in hit_data:
#				scaled_damage = FMath.percent(scaled_damage, SUPERARMOR_CHIP_DMG_MOD)
#			else:
			scaled_damage = FMath.percent(scaled_damage, get_stat("WEAKBLOCK_CHIP_DMG_MOD"))
		else:
			return 0

	if Globals.survival_level != null and hit_data[Em.hit.ATKER] != null:
		var mod = hit_data[Em.hit.ATKER].query_status_effect_aux(Em.status_effect.ENFEEBLE)
		if mod != null:
			scaled_damage = FMath.percent(scaled_damage, mod)

	return int(max(FMath.round_and_descale(scaled_damage), 1)) # minimum 1 damage
	

func calculate_guard_gauge_change(hit_data) -> int:
	
	if hit_data[Em.hit.MOVE_DATA][Em.move.ATK_TYPE] in [Em.atk_type.SUPER]: # no Guard Drain for Supers
		return 0
	
	if (hit_data[Em.hit.MOVE_DATA][Em.move.HITCOUNT] > 1 and !Em.hit.FIRST_HIT in hit_data) or Em.hit.FOLLOW_UP in hit_data:  
	# for multi-hit/autochain moves, only first hit affect GG
		return 0
	
	if is_hitstunned() and GG_swell_flag and !first_hit_flag: # if Guard Swell is active, no Guard Drain
		return 0
	
#	var guard_drain = -ATK_LEVEL_TO_GDRAIN[hit_data[Em.hit.ADJUSTED_ATK_LVL] - 1]

	var guard_drain = -ATK_LEVEL_TO_GDRAIN[hit_data[Em.hit.ADJUSTED_ATK_LVL] - 1]
	
	match hit_data[Em.hit.BLOCK_STATE]:
		Em.block_state.STRONG:
			return 0
		
		Em.block_state.WEAK: # no Guard Drain on blocking normals
			if hit_data[Em.hit.MOVE_DATA][Em.move.ATK_TYPE] in [Em.atk_type.HEAVY, Em.atk_type.SPECIAL, Em.atk_type.EX]:
				guard_drain = FMath.percent(guard_drain, get_stat("SPECIAL_GDRAIN_MOD")) # double guard drain when blocking heavy/special/ex
			else:
				if !Em.hit.SUPERARMORED in hit_data: # superarmoring through attacks still drain GG
					return 0
				elif Em.hit.SDASH_ARMORED in hit_data:
					guard_drain = FMath.percent(guard_drain, SDASH_ARMOR_GDRAIN_MOD)
					
		Em.block_state.UNBLOCKED:
			if Globals.survival_level != null and Inventory.has_quirk(player_ID, Cards.effect_ref.LESS_GUARD_DRAIN):
				guard_drain = FMath.percent(guard_drain, 10)

	return guard_drain # Guard Drain on 1st hit of the combo depends on Attack Level

	
	
func calculate_knockback_strength(hit_data) -> int:

	var knockback_strength: int = hit_data[Em.hit.MOVE_DATA][Em.move.KB] # scaled by FMath.S
	
	if hit_data[Em.hit.BLOCK_STATE] == Em.block_state.UNBLOCKED and Em.atk_attr.FIXED_KNOCKBACK_STR in hit_data[Em.hit.MOVE_DATA][Em.move.ATK_ATTR]:
		return knockback_strength
	
	# for certain multi-hit attacks (not autochain), can be fixed KB till the last hit
	if Em.hit.MULTIHIT in hit_data:
		if Em.move.FIXED_KB_MULTI in hit_data[Em.hit.MOVE_DATA]:
			return hit_data[Em.hit.MOVE_DATA][Em.move.FIXED_KB_MULTI] # scaled by FMath.S
		else:
			return knockback_strength
			
	if  Em.hit.AUTOCHAIN in hit_data:
		return knockback_strength
	
	if hit_data[Em.hit.SEMI_DISJOINT]:
		return int(clamp(knockback_strength, 0, SD_KNOCKBACK_LIMIT))
		
	if hit_data[Em.hit.SWEETSPOTTED]:
		knockback_strength = FMath.percent(knockback_strength, SWEETSPOT_KB_MOD)
	
	if hit_data[Em.hit.STUN]:
		knockback_strength += LAUNCH_THRESHOLD # increased knockback on a Break hit
		
	if hit_data[Em.hit.BLOCK_STATE] != Em.block_state.UNBLOCKED:
		match hit_data[Em.hit.BLOCK_STATE]:
			Em.block_state.WEAK:
				knockback_strength = FMath.percent(knockback_strength, WEAKBLOCK_KNOCKBACK_MOD) # KB for weakblock
#				if  hit_data[Em.hit.MOVE_DATA][Em.move.ATK_TYPE] in [Em.atk_type.HEAVY, Em.atk_type.SPECIAL, Em.atk_type.EX, \
#						Em.atk_type.SUPER, Em.atk_type.SUPER_ENTITY]:
#					knockback_strength = FMath.percent(knockback_strength, SPECIAL_BLOCK_KNOCKBACK_MOD)
#					# increased KB when blocking heavy/special/ex/super
			Em.block_state.STRONG:
				knockback_strength = FMath.percent(knockback_strength, STRONGBLOCK_KNOCKBACK_MOD) # KB for strongblock
#			Em.block_state.PARRY:
#				knockback_strength = 0 # no KB for strongblock and parry

	if !hit_data[Em.hit.WEAK_HIT]:  # no GG KB boost for multi-hit attacks (weak hits) till the last hit
		if current_guard_gauge > 0: # knockback is increased by defender's Guard Gauge when it is > 100%
			knockback_strength = FMath.f_lerp(knockback_strength, FMath.percent(knockback_strength, get_stat("KB_BOOST_AT_MAX_GG")), \
				get_guard_gauge_percent_above())
				
		if get_guard_gauge_percent_above() == 100: # all attacks will Launch at 100% GG
			knockback_strength = int(max(knockback_strength, LAUNCH_THRESHOLD))
	
	if Globals.survival_level != null and !hit_data[Em.hit.WEAK_HIT]: # all attacks will Launch during Survival Mode
		knockback_strength = int(max(knockback_strength, LAUNCH_THRESHOLD))
		
	
	return knockback_strength
	
	
func lethal_knockback(hit_data, knockback_strength):
	if !hit_data[Em.hit.STUN]:
		knockback_strength += LAUNCH_THRESHOLD
	knockback_strength = FMath.percent(knockback_strength, LETHAL_KB_MOD)

	if get_damage_percent() >= 100: # knockback is increased by defender's Damage Value when it is > 100%
#			var dmg_val_boost = min((defender.get_damage_percent() - 1.0) / 0.125 * 0.5 + 2.0 \
#				, DMG_VAL_KB_LIMIT)
		var weight: int = int(min(FMath.get_fraction_percent(get_damage_percent() - 100, 50), 100))
		#	0 percent damage over is x1.5 knockback
		# 	50 percent damage over is x3.0 knockback
		knockback_strength = FMath.f_lerp(FMath.percent(knockback_strength, 150), \
			FMath.percent(knockback_strength, DMG_VAL_KB_LIMIT), weight)
	
	return knockback_strength # lethal knockback is around 2000
	
	
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
				knockback_dir = posmod(180 - knockback_dir, 360) # mirror knockback angle horizontally if facing other way
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
				knockback_dir = posmod(180 - hit_data[Em.hit.MOVE_DATA][Em.move.KB_ANGLE], 360) # mirror knockback angle horizontally if facing other way
				
			if knockback_type == Em.knockback_type.MIRRORED: # mirror it again if wrong way
#				if KBOrigin:
				var segment = Globals.split_angle(knockback_dir, Em.angle_split.TWO, hit_data[Em.hit.ATK_FACING])
				match segment:
					Em.compass.E:
						if ref_vector.x < 0:
							knockback_dir = posmod(180 - knockback_dir, 360)
					Em.compass.W:
						if ref_vector.x > 0:
							knockback_dir = posmod(180 - knockback_dir, 360)
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
			
	# for weak hit and grounded defender, or grounded blocking defender, if the hit is towards left/right instead of up/down, level it
	if grounded and (hit_data[Em.hit.WEAK_HIT] or hit_data[Em.hit.ADJUSTED_ATK_LVL] <= 1 or \
		hit_data[Em.hit.BLOCK_STATE] != Em.block_state.UNBLOCKED):
		var segment = Globals.split_angle(knockback_dir, Em.angle_split.FOUR, hit_data[Em.hit.ATK_FACING])
		match segment:
			Em.compass.E:
				knockback_dir = 0
			Em.compass.W:
				knockback_dir = 180
				
	return knockback_dir


func adjusted_atk_level(hit_data) -> int: # mostly for hitstun
	# atk_level = 1 are weak hits and cannot do a lot of stuff, cannot cause hitstun

#	if Em.hit.SUPERARMORED in hit_data:
#		return 1
	if hit_data[Em.hit.DOUBLE_REPEAT]:
		return 1 # double repeat is forced attack level 1
	
	var atk_level: int = hit_data[Em.hit.MOVE_DATA][Em.move.ATK_LVL]
	if hit_data[Em.hit.SEMI_DISJOINT]: # semi-disjoint hits limit hitstun
		atk_level -= 1 # atk lvl 2 become weak hit
		atk_level = int(clamp(atk_level, 1, 2))
	else: # sweetspotted and Punish Hits give more hitstun
		if hit_data[Em.hit.SWEETSPOTTED] and !Em.atk_attr.NO_SS_ATK_LVL_BOOST in hit_data[Em.hit.MOVE_DATA][Em.move.ATK_ATTR]:
			atk_level += 3
			atk_level = int(clamp(atk_level, 1, 8))
		if hit_data[Em.hit.PUNISH_HIT]:
			atk_level += 3
			atk_level = int(clamp(atk_level, 1, 8))
		
	return atk_level
	
	
func calculate_hitstun(hit_data) -> int: # hitstun determined by attack level and defender's Guard Gauge
	
	if Em.move.FIXED_HITSTUN in hit_data[Em.hit.MOVE_DATA] and !hit_data[Em.hit.DOUBLE_REPEAT]:
		return hit_data[Em.hit.MOVE_DATA][Em.move.FIXED_HITSTUN]
		
	if hit_data[Em.hit.ADJUSTED_ATK_LVL] <= 1 and !is_hitstunned():
		return 0 # weak hit on opponent not in hitstun
		
	if hit_data[Em.hit.DOUBLE_REPEAT]:
		return 0

	var scaled_hitstun := 0
	if hit_data[Em.hit.KB] < LAUNCH_THRESHOLD:
		scaled_hitstun = ATK_LEVEL_TO_F_HITSTUN[hit_data[Em.hit.ADJUSTED_ATK_LVL] - 1] * FMath.S
	else:
		scaled_hitstun = ATK_LEVEL_TO_L_HITSTUN[hit_data[Em.hit.ADJUSTED_ATK_LVL] - 1] * FMath.S
		
#	if Globals.survival_level != null and !hit_data[Em.hit.WEAK_HIT] and !Em.hit.AUTOCHAIN in hit_data:
#		return int(min(scaled_hitstun, MOB_GRACE_DURATION)) # limited hitstun for mob attack

	if Globals.survival_level != null and !hit_data[Em.hit.LETHAL_HIT] and !Em.hit.MULTIHIT in hit_data and !Em.hit.AUTOCHAIN in hit_data:
		scaled_hitstun = FMath.percent(scaled_hitstun, Inventory.modifier(player_ID, Cards.effect_ref.HITSTUN_TAKEN))
		scaled_hitstun = int(max(scaled_hitstun, 0))
		
	if hit_data[Em.hit.LETHAL_HIT]:
		# increased hitstun on a lethal hit and no reduction from high Guard Gauge
		scaled_hitstun = FMath.percent(scaled_hitstun, LETHAL_HITSTUN_MOD)
		if get_damage_percent() > 1.0:
			scaled_hitstun = FMath.percent(scaled_hitstun, get_damage_percent())
	else:
		if current_guard_gauge > 0: # hitstun is reduced by defender's Guard Gauge when it is > 100%
#				if hit_data[Em.hit.KB] < LAUNCH_THRESHOLD:
			scaled_hitstun = FMath.f_lerp(scaled_hitstun, FMath.percent(scaled_hitstun, HITSTUN_REDUCTION_AT_MAX_GG), \
				get_guard_gauge_percent_above())
#			else:
#				scaled_hitstun = FMath.f_lerp(scaled_hitstun, FMath.percent(scaled_hitstun, L_HITSTUN_REDUCTION_AT_MAX_GG), \
#					get_guard_gauge_percent_above())

	return FMath.round_and_descale(scaled_hitstun)

	
	
func check_if_crossed_up(attacker, angle_to_atker: int):
	
	if success_block != Em.success_block.NONE:
		return false
	
	if Globals.survival_level != null and Inventory.has_quirk(player_ID, Cards.effect_ref.NO_CROSSUP):
		return false
	
# warning-ignore:narrowing_conversion
	var x_dist: int = abs(attacker.position.x - position.x)
	if x_dist <= CROSS_UP_MIN_DIST: return false
	
	var segment = Globals.split_angle(angle_to_atker, Em.angle_split.FOUR)
	if segment == Em.compass.N or segment == Em.compass.S:
		return false
	match segment:
		Em.compass.E:
			if facing == 1:
				return false
		Em.compass.W:
			if facing == -1:
				return false
	return true


func calculate_hitstop(hit_data, knockback_strength: int) -> int: # hitstop determined by knockback power
		
	if Em.hit.SUPERARMORED in hit_data:
		return STRONGBLOCK_HITSTOP
		
	if hit_data[Em.hit.BLOCK_STATE] != Em.block_state.UNBLOCKED:
		if Em.hit.MULTIHIT in hit_data: return 5 # blocked multihit attack has less blockstop
		match hit_data[Em.hit.BLOCK_STATE]:
			Em.block_state.WEAK:
				if Em.hit.ENTITY_PATH in hit_data:
					return 5 # hitstop on blocking projectile has less blockstop
				else:
					return WEAKBLOCK_HITSTOP
			Em.block_state.STRONG:
				return STRONGBLOCK_HITSTOP
#			Em.block_state.PARRY:
#				return PARRY_HITSTOP

	# some moves have predetermined hitstop
	if Em.move.FIXED_HITSTOP in hit_data[Em.hit.MOVE_DATA]:
		return hit_data[Em.hit.MOVE_DATA][Em.move.FIXED_HITSTOP]
		
	if Globals.survival_level != null and !hit_data[Em.hit.WEAK_HIT] and !Em.hit.AUTOCHAIN in hit_data:
		return SURVIVAL_HITSTOP
		
	if Em.hit.AUTOCHAIN in hit_data:
		return AUTOCHAIN_HITSTOP
	if hit_data[Em.hit.WEAK_HIT]:
		return WEAK_HIT_HITSTOP
		
# warning-ignore:integer_division
	var hitstop_temp: int = 3 * FMath.S + int(knockback_strength / 90) # scaled, +1 frame of hitstop for each 100 scaled knockback
	
	if hit_data[Em.hit.SEMI_DISJOINT]: # on semi-disjoint hits, lowest hitstop
		return MIN_HITSTOP
	else:
		if hit_data[Em.hit.SWEETSPOTTED]: # sweetspotted hits has 30% more hitstop
			if Em.move.FIXED_SS_HITSTOP in hit_data[Em.hit.MOVE_DATA]:
				return hit_data[Em.hit.MOVE_DATA][Em.move.FIXED_SS_HITSTOP] # for Normal hitpulls
			hitstop_temp = FMath.percent(hitstop_temp, SWEETSPOT_HITSTOP_MOD)
		if hit_data[Em.hit.PUNISH_HIT]: # punish hits has 30% more hitstop
			hitstop_temp = FMath.percent(hitstop_temp, PUNISH_HITSTOP_MOD)
		
	hitstop_temp = FMath.round_and_descale(hitstop_temp) # descale it
	hitstop_temp = int(clamp(hitstop_temp, MIN_HITSTOP, MAX_HITSTOP)) # max hitstop is 13, min hitstop is 5
			
			
#	print(hitstop_temp)
	return hitstop_temp
	

func generate_hitspark(hit_data): # hitspark size determined by knockback power
	
	# SD hits have special hitspark, unless has VULN_LIMBS
	if hit_data[Em.hit.SEMI_DISJOINT] and !Em.atk_attr.VULN_LIMBS in query_atk_attr():
#		var aux_data = {"facing":Globals.Game.rng_facing(), "v_mirror":Globals.Game.rng_bool()}
#		if UniqChar.SDHitspark_COLOR != "red":
#			aux_data["palette"] = UniqChar.SDHitspark_COLOR
		Globals.Game.spawn_SFX("SDHitspark", "SDHitspark", hit_data[Em.hit.HIT_CENTER], {"facing":Globals.Game.rng_facing(), \
				"v_mirror":Globals.Game.rng_bool()}, UniqChar.SDHitspark_COLOR)
		return
	
	var hitspark_level: int
	
	if Globals.survival_level != null and !hit_data[Em.hit.WEAK_HIT] and !Em.hit.AUTOCHAIN in hit_data:
		hitspark_level = 5 # Survival Mode
	
	elif hit_data[Em.hit.ADJUSTED_ATK_LVL] <= 1:
		hitspark_level = 0
	elif Em.move.BURST in hit_data[Em.hit.MOVE_DATA]:
		hitspark_level = 5
	elif hit_data[Em.hit.STUN] or hit_data[Em.hit.CRUSH]:
		hitspark_level = 5 # max size for Break
	else:
		if hit_data[Em.hit.KB] <= FMath.percent(LAUNCH_THRESHOLD, 40):
			hitspark_level = 1
		elif hit_data[Em.hit.KB] < LAUNCH_THRESHOLD:
			hitspark_level = 2
		elif hit_data[Em.hit.KB] <= FMath.percent(LAUNCH_THRESHOLD, 170):
			hitspark_level = 3
		elif hit_data[Em.hit.KB] <= FMath.percent(LAUNCH_THRESHOLD, 200):
			hitspark_level = 4
		else:
			hitspark_level = 5
		
		if hit_data[Em.hit.SWEETSPOTTED] or hit_data[Em.hit.PUNISH_HIT]: # if sweetspotted/punish hit, hitspark level increased by 1
			hitspark_level = int(clamp(hitspark_level + 1, 1, 5)) # max is 5
		
		
	if !Em.move.HITSPARK_TYPE in hit_data[Em.hit.MOVE_DATA]:
#		if hit_data[Em.hit.ATKER_OR_ENTITY].has_method("get_default_hitspark_type"):
#			hit_data[Em.hit.MOVE_DATA][Em.move.HITSPARK_TYPE] = hit_data[Em.hit.ATKER_OR_ENTITY].get_default_hitspark_type()
		if hit_data[Em.hit.ATKER] != null and hit_data[Em.hit.ATKER].has_method("get_default_hitspark_type"):
			hit_data[Em.hit.MOVE_DATA][Em.move.HITSPARK_TYPE] = hit_data[Em.hit.ATKER].get_default_hitspark_type()
		else:
			hit_data[Em.hit.MOVE_DATA][Em.move.HITSPARK_TYPE] = Em.hitspark_type.HIT
			
	if !Em.move.HITSPARK_PALETTE in hit_data[Em.hit.MOVE_DATA]:
#		if hit_data[Em.hit.ATKER_OR_ENTITY].has_method("get_default_hitspark_palette"):
#			hit_data[Em.hit.MOVE_DATA][Em.move.HITSPARK_PALETTE] = hit_data[Em.hit.ATKER_OR_ENTITY].get_default_hitspark_palette()
		if hit_data[Em.hit.ATKER] != null and hit_data[Em.hit.ATKER].has_method("get_default_hitspark_palette"):
			hit_data[Em.hit.MOVE_DATA][Em.move.HITSPARK_PALETTE] = hit_data[Em.hit.ATKER].get_default_hitspark_palette()
		else:
			hit_data[Em.hit.MOVE_DATA][Em.move.HITSPARK_PALETTE] = "red"
		
	var hitspark = ""
	match hit_data[Em.hit.MOVE_DATA][Em.move.HITSPARK_TYPE]:
		Em.hitspark_type.HIT:
			match hitspark_level:
				0:
					hitspark = "HitsparkA"
				1, 2:
					hitspark = "HitsparkB"
				3, 4:
					hitspark = "HitsparkC"
				5:
					hitspark = "HitsparkD"
		Em.hitspark_type.SLASH:
			match hitspark_level:
				0:
					hitspark = "SlashsparkA"
				1, 2:
					hitspark = "SlashsparkB"
				3, 4:
					hitspark = "SlashsparkC"
				5:
					hitspark = "SlashsparkD"
			
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
#		var aux_data = {"rot": rot_rad, "v_mirror":Globals.Game.rng_bool()}
#		if hit_data[Em.hit.MOVE_DATA][Em.move.HITSPARK_PALETTE] != "red":
#			aux_data["palette"] = hit_data[Em.hit.MOVE_DATA][Em.move.HITSPARK_PALETTE]
		Globals.Game.spawn_SFX(hitspark, hitspark, hit_data[Em.hit.HIT_CENTER], {"rot": rot_rad, "v_mirror":Globals.Game.rng_bool()}, \
				hit_data[Em.hit.MOVE_DATA][Em.move.HITSPARK_PALETTE])
		
func get_default_hitspark_type():
	return get_stat("DEFAULT_HITSPARK_TYPE")
func get_default_hitspark_palette():
	if palette_number in UniqChar.PALETTE_TO_HITSPARK_PALETTE:
		return UniqChar.PALETTE_TO_HITSPARK_PALETTE[palette_number]
	return get_stat("DEFAULT_HITSPARK_PALETTE")
	
func generate_blockspark(hit_data):
	
	var blockspark
	
	match hit_data[Em.hit.BLOCK_STATE]:
		Em.block_state.WEAK:
			if Em.hit.SUPERARMORED in hit_data:
				blockspark = "Superarmorspark"
			elif hit_data[Em.hit.MOVE_DATA][Em.move.ATK_TYPE] in [Em.atk_type.HEAVY, Em.atk_type.SPECIAL, Em.atk_type.EX, \
					Em.atk_type.SUPER, Em.atk_type.SUPER_ENTITY]:
				blockspark = "WBlockspark2"
			else:
				blockspark = "WBlockspark"
		Em.block_state.STRONG:
			blockspark = "SBlockspark"
#		Em.block_state.PARRY:
#			blockspark = "Parryspark"
		
	Globals.Game.spawn_SFX(blockspark, "Blocksparks", hit_data[Em.hit.HIT_CENTER], {"rot" : deg2rad(hit_data[Em.hit.ANGLE_TO_ATKER])})
	
	
# AUTO SEQUENCES ---------------------------------------------------------------------------------------------------

func simulate_sequence(): # cut into this during simulate2() during sequences
	
	test0()
	
	var Partner = get_seq_partner()
	if Partner == null and new_state in [Em.char_state.SEQUENCE_TARGET, Em.char_state.SEQUENCE_USER]:
		animate("Idle")
		return
	
	if new_state == Em.char_state.SEQUENCE_TARGET: # being the target of an opponent's sequence will be moved around by them
		if Partner.new_state != Em.char_state.SEQUENCE_USER:
			animate("Idle") # auto release if not released proberly, just in case
		
	elif new_state == Em.char_state.SEQUENCE_USER: # using a sequence, will follow the steps in UniqChar.SEQUENCES[sequence_name]
		UniqChar.simulate_sequence()
		
		
	if abs(velocity.x) < 5 * FMath.S:
		velocity.x = 0
	if abs(velocity.y) < 5 * FMath.S:
		velocity.y = 0
	
	velocity_previous_frame.x = velocity.x
	velocity_previous_frame.y = velocity.y
	
	var results = move($PlayerCollisionBox, $SoftPlatformDBox, UniqChar.sequence_ledgestop()) # [landing_check, collision_check, ledgedrop_check]
#	velocity.x = results[0].x
#	velocity.y = results[0].y
	
	if new_state == Em.char_state.SEQUENCE_USER:
		UniqChar.simulate_sequence_after() # move grabbed target after grabber has moved
	
	if results[0]: UniqChar.end_sequence_step("ground") # hit the ground, no effect if simulate_sequence_after() broke grab and animated "Idle"
	if results[2]: UniqChar.end_sequence_step("ledge") # stopped by ledge
	
		
func landed_a_sequence(hit_data):
	
	if new_state in [Em.char_state.SEQUENCE_USER]:
		return # no sequencing if you are already grabbing another player

	var defender = Globals.Game.get_player_node(hit_data[Em.hit.DEFENDER_ID])
	
	if defender == null or defender.new_state in [Em.char_state.SEQUENCE_TARGET]:
		return # no sequencing players that are already being grabbed
		
	if defender.new_state in [Em.char_state.SEQUENCE_USER]: # both players grab each other at the same time, break grabs
		animate("Idle")
		defender.animate("Idle")
		return
		
	if hit_data[Em.hit.DOUBLE_REPEAT] == true: return # repeat penalty, cannot grab if repeated
	
	seq_partner_ID = defender.player_ID
	defender.seq_partner_ID = player_ID
	
#	if Globals.survival_level != null and "attacked_this_frame" in defender:
#		defender.attacked_this_frame = true
	animate(hit_data[Em.hit.MOVE_DATA][Em.move.SEQ])
#	UniqChar.start_sequence_step()
	
	if current_guard_gauge < 0: # gain positive flow
#		add_status_effect(Em.status_effect.POS_FLOW, null)
		status_effect_to_add.append([Em.status_effect.POS_FLOW, null])
		
	chain_combo = Em.chain_combo.NO_CHAIN
#	defender.status_effect_to_remove.append(Em.status_effect.POS_FLOW)	# defender lose positive flow
				
				
#func being_sequenced(hit_data):
#	targeted_opponent_path = hit_data.attacker_nodepath # target opponent who last attacked you
#	status_effect_to_remove.append(Em.status_effect.POS_FLOW)	# lose positive flow
	
	
func take_seq_damage(base_damage: int) -> bool: # return true if lethal
	
#	$HitStunGraceTimer.time = HitStunGraceTimer_TIME # reset HitStunGraceTimer which only ticks down out of hitstun
	if Globals.training_mode:
		$TrainingRegenTimer.time = TrainingRegenTimer_TIME
	
	var scaled_damage: int = base_damage * FMath.S
	if scaled_damage == 0: return false
	
	if current_guard_gauge > 0: # damage is reduced by Guard Gauge when it is > 100%
		scaled_damage = FMath.f_lerp(scaled_damage, FMath.percent(scaled_damage, DMG_REDUCTION_AT_MAX_GG), get_guard_gauge_percent_above())
		
	var seq_user = get_seq_partner()
	if Globals.survival_level != null and seq_user != null:
		var mod = seq_user.query_status_effect_aux(Em.status_effect.ENFEEBLE)
		if mod != null:
			scaled_damage = FMath.percent(scaled_damage, mod)
		
	var damage: int = int(max(FMath.round_and_descale(scaled_damage), 1)) # minimum damage is 1
	
	take_damage(damage)
	if damage > 0:
		if Globals.survival_level == null:
			Globals.Game.spawn_damage_number(damage, position)
		else:
			Globals.Game.spawn_damage_number(damage, position, Em.dmg_num_col.RED)
	if get_damage_percent() >= 100:
		return true # return true if lethal
	return false
	
	
func sequence_hit(hit_key: int): # most auto sequences deal damage during the sequence outside of the launch
	
	var seq_user = get_seq_partner()
	if seq_user == null:
		animate("Idle")
		return
	
	var seq_hit_data = seq_user.UniqChar.get_seq_hit_data(hit_key)
	var lethal = take_seq_damage(seq_hit_data[Em.move.DMG])
	
	if Em.move.SEQ_HITSTOP in seq_hit_data and !Em.move.SEQ_WEAK in    seq_hit_data: # if weak, no lethal effect, place it for non-final hits
		if lethal:
			hitstop = LETHAL_HITSTOP
#			add_status_effect(Em.status_effect.LETHAL, 0) # this applies lethal freeze to all others, remove when hitstop ends
			status_effect_to_add.append([Em.status_effect.LETHAL, 0])
			Globals.Game.set_screenshake()
			modulate_play("lethal_flash")
			play_audio("lethal1", {"vol" : -5, "bus" : "Reverb"})
		else:
			hitstop = seq_hit_data[Em.move.SEQ_HITSTOP]
			seq_user.hitstop = hitstop


func sequence_launch():
	
	var seq_user = get_seq_partner()
	if seq_user == null:
		animate("Idle")
		return
		
	var dir_to_attacker = sign(position.x - seq_user.position.x)
	if dir_to_attacker == 0: dir_to_attacker = facing
	
	if !seq_user.Animator.to_play_anim in seq_user.UniqChar.MOVE_DATABASE:
		print("Error: " + Animator.to_play_anim + " auto-sequence not found in database.")
	var seq_data = seq_user.UniqChar.get_seq_launch_data()
	
#		Em.move.SEQ_LAUNCH : { # for final hit of sequence
#			Em.move.DMG : 0,
#			Em.move.SEQ_HITSTOP : 0,
#			"guard_gain" : 3500,
#			Em.move.KB : 700 * FMath.S,
#			Em.move.KB_ANGLE : -82,
#			Em.move.ATK_LVL : 6,
#		}

	# DAMAGE
	var damage = seq_data[Em.move.DMG]
	var lethal = take_seq_damage(damage)
	if damage > 0 and seq_data[Em.move.SEQ_HITSTOP] > 0: # launch is a hit (rare)
		if lethal and !Em.move.SEQ_WEAK in seq_data:
			hitstop = LETHAL_HITSTOP
#			add_status_effect(Em.status_effect.LETHAL, 0) # this applies lethal freeze to all others, remove when hitstop ends
			status_effect_to_add.append([Em.status_effect.LETHAL, 0])
			Globals.Game.set_screenshake()
			modulate_play("lethal_flash")
			play_audio("lethal1", {"vol" : -5, "bus" : "Reverb"})
		else:
			hitstop = seq_data[Em.move.SEQ_HITSTOP]
			seq_user.hitstop = hitstop
		
#	if GG_swell_flag == false: # start GG swell if not started yet and hit with non-multihit/non-autochain move
#		GG_swell_flag = true
#		first_hit_flag = true
#	else: # hit after GG swell started, turn off first_hit_flag to gaining GG
#		first_hit_flag = false
	
	$BurstLockTimer.time = BurstLockTimer_TIME
	DI_seal = false
	
	# GUARD DRAIN ON FIRST HIT
	if !Em.move.SEQ_WEAK in seq_data and !(GG_swell_flag and !first_hit_flag):
		var guard_drain = -ATK_LEVEL_TO_GDRAIN[seq_data[Em.move.ATK_LVL] - 1]
		change_guard_gauge(guard_drain)
		
	# HITSTUN
	var hitstun: int
	if Em.move.FIXED_HITSTUN in seq_data:
		hitstun = seq_data.fixed_hitstun
	else:
		var scaled_hitstun: int = ATK_LEVEL_TO_L_HITSTUN[seq_data[Em.move.ATK_LVL] - 1] * FMath.S
		if get_damage_percent() >= 100:
			scaled_hitstun = FMath.percent(scaled_hitstun, LETHAL_HITSTUN_MOD)
			scaled_hitstun = FMath.percent(scaled_hitstun, get_damage_percent())
		else:
			if current_guard_gauge > 0: # hitstun is reduced by defender's Guard Gauge when it is > 100%
				scaled_hitstun = FMath.f_lerp(scaled_hitstun, FMath.percent(scaled_hitstun, HITSTUN_REDUCTION_AT_MAX_GG), \
					get_guard_gauge_percent_above())
		hitstun = FMath.round_and_descale(scaled_hitstun)
	$HitStunTimer.time = hitstun
	launchstun_rotate = 0 # used to calculation sprite rotation during launched state
	
#	if Globals.survival_level != null and !Em.move.SEQ_WEAK in seq_data:
#		status_effect_to_add.append([Em.status_effect.SURVIVAL_GRACE, null])
		
	# LAUNCH POWER
	var launch_power = seq_data[Em.move.KB] # scaled
	
	if get_damage_percent() >= 100 and !Em.move.SEQ_WEAK in seq_data: # knockback is increased when Damage is over Damage Value Limit
		lethal_flag = true
		launch_power += LAUNCH_THRESHOLD
		launch_power = FMath.percent(launch_power, LETHAL_KB_MOD)
		var weight: int = int(min(FMath.get_fraction_percent(get_damage_percent() - 100, 25), 100))
		#	0 percent damage over is x2.0 knockback
		# 	25 percent damage over is x3.0 knockback
		launch_power = FMath.f_lerp(FMath.percent(launch_power, 200), FMath.percent(launch_power, DMG_VAL_KB_LIMIT), weight)
	else:
		lethal_flag = false
		
	if current_guard_gauge > 0: # knockback is increased by Guard Gauge when it is > 100%
		launch_power = FMath.f_lerp(launch_power, FMath.percent(launch_power, get_stat("KB_BOOST_AT_MAX_GG")), \
			get_guard_gauge_percent_above())
		
	# LAUNCH ANGLE
	var launch_angle: int
	if seq_user.facing > 0:
		launch_angle = posmod(seq_data[Em.move.KB_ANGLE], 360)
	else:
		launch_angle = posmod(180 - seq_data[Em.move.KB_ANGLE], 360) # if mirrored
		
	# LAUNCHING
	sprite.rotation = 0
	var segment = Globals.split_angle(launch_angle, Em.angle_split.EIGHT, dir_to_attacker)
	match segment:
		Em.compass.N:
			face(-dir_to_attacker) # turn towards attacker
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
			face(-dir_to_attacker) # turn towards attacker
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
	
	velocity.set_vector(launch_power, 0)  # reset momentum
	velocity.rotate(launch_angle)
	
	if wall_slammed != Em.wall_slam.HAS_SLAMMED:
		wall_slammed = Em.wall_slam.CAN_SLAM
	
	
		
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
				snap_up($PlayerCollisionBox, $DashLandDBox)
				animate("SoftLanding")
			else:
				animate("FastFall")
		"DodgeTransit":
			animate("Dodge")
		"Dodge":
			if success_dodge:
				animate("DodgeCRec")
			else:
				animate("DodgeRec")
		"DodgeRec":
			animate("Fall")
		"DodgeCRec":
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
			
		"BlockStartup":
			change_guard_gauge(-get_stat("GROUND_BLOCK_GG_COST") * 10)
			play_audio("bling4", {"vol" : -10, "bus" : "PitchUp2"})
#			if Globals.survival_level == null:
#			remove_status_effect(Em.status_effect.POS_FLOW) # don't use status_effect_to_remove for this as this take place later
			animate("Block")
		"BlockRec":
			animate("Idle")
		"BlockCRec":
			animate("Idle")
		"aBlockStartup":
			change_guard_gauge(-get_stat("AIR_BLOCK_GG_COST") * 10)
			play_audio("bling4", {"vol" : -10, "bus" : "PitchUp2"})
#			if Globals.survival_level == null:
#			remove_status_effect(Em.status_effect.POS_FLOW)
			animate("aBlock")
		"aBlockRec":
			animate("FallTransit")
		"aBlockCRec":
			animate("FallTransit")
		"BlockLanding":
			animate("Block")
			
		"BurstCounterStartup":
			if held_version(button_aux) and held_version(button_block) and burst_token == Em.burst.AVAILABLE:
				animate("BurstAwakening")
			else:
				animate("BurstCounter")
		"BurstCounter":
			animate("BurstRec")
		"BurstAwakening":
			animate("BurstRec")
		"BurstEscapeStartup":
			animate("BurstEscape")
		"BurstEscape":
			animate("BurstRec")
#		"BurstExtend":
#			animate("BurstCRec")
		"BurstRec":
			animate("FallTransit")
#		"BurstCRec":
#			animate("FallTransit")
			
		"SDashTransit":
			animate("SDash")
		"SDash":
			if !grounded:
				animate("aDashBrake")
			else:
				animate("DashBrake")
			
		"SeqFlinchAStop":
			animate("SeqFlinchA")
		"SeqFlinchBStop":
			animate("SeqFlinchB")	
		"aSeqFlinchAStop":
			animate("aSeqFlinchA")
		"aSeqFlinchBStop":
			animate("aSeqFlinchB")	
		"SeqLaunchStop":
			animate("SeqLaunchTransit")
		"SeqLaunchTransit":
			animate("SeqLaunch")

	UniqChar._on_SpritePlayer_anim_finished(anim_name)

	# do this at end of _on_SpritePlayer_anim_finished() as well
	if new_state in [Em.char_state.GROUND_C_REC, Em.char_state.AIR_C_REC, \
			Em.char_state.GROUND_REC, Em.char_state.AIR_REC]:
		from_move_rec = true
		

func _on_SpritePlayer_anim_started(anim_name):
	
	state = state_detect(Animator.current_anim) # update state
	
	if new_state in [Em.char_state.GROUND_C_REC, Em.char_state.AIR_C_REC, \
			Em.char_state.GROUND_D_REC, Em.char_state.AIR_D_REC]:
		from_move_rec = true
	elif !is_atk_startup():
		from_move_rec = false
	
	if is_atk_startup():
		var move_name = anim_name.trim_suffix("Startup")
				
		if dir != 0: # impulse
			match state:
				Em.char_state.GROUND_ATK_STARTUP:
					if !impulse_used and move_name in UniqChar.STARTERS and !Em.atk_attr.NO_IMPULSE in query_atk_attr(move_name):
						impulse_used = true
						var impulse: int = dir * FMath.percent(get_stat("SPEED"), get_stat("IMPULSE_MOD"))
						if instant_dir != 0: # perfect impulse
							impulse = FMath.percent(impulse, PERFECT_IMPULSE_MOD)
	#					if move_name in UniqChar.MOVE_DATABASE and "impulse_mod" in UniqChar.MOVE_DATABASE[move_name]:
	#						var impulse_mod: int = UniqChar.query_move_data(move_name).impulse_mod
	#						impulse = FMath.percent(impulse, impulse_mod)
						velocity.x = int(clamp(velocity.x + impulse, -abs(impulse), abs(impulse)))
						Globals.Game.spawn_SFX("GroundDashDust", "DustClouds", get_feet_pos(), {"facing":dir, "grounded":true})
						
				Em.char_state.AIR_ATK_STARTUP:
					if strafe_lock_dir == 0 and move_name in UniqChar.STARTERS:
						strafe_lock_dir = dir
						
		var atk_attr = query_atk_attr(move_name)
		if Em.atk_attr.NORMALARMOR_STARTUP in atk_attr or Em.atk_attr.SUPERARMOR_STARTUP in atk_attr:
			modulate_play("armor_flash")
						
	else:
		if new_state in [Em.char_state.GROUND_D_REC, Em.char_state.AIR_D_REC]:
			impulse_used = true  # no impulse if cancelling from dash
		else:
			impulse_used = false
			
		quick_turn_used = false
		strafe_lock_dir = 0
		
		if is_atk_active():
			var move_name = UniqChar.get_root(anim_name.trim_suffix("Active"))
			
			chain_memory.append(move_name) # add move to chain memory
			
			if !grounded: # add move to aerial memory
#				if is_normal_attack(move_name) or is_heavy(move_name):
#					aerial_memory.append(move_name)
#				elif is_special_move(move_name):
#					aerial_sp_memory.append(move_name)
				aerial_memory.append(move_name)
				if is_special_move(move_name) and !Em.atk_attr.AIR_REPEAT in query_atk_attr(move_name):
					aerial_sp_memory.append(move_name)
					
			if Globals.survival_level != null and move_name in UniqChar.STARTERS:
				attack_enhance(query_move_data()[Em.move.ATK_TYPE])
					
#		else:
#			perfect_chain = false # change to false if neither startup nor active
	
	anim_friction_mod = 100
	anim_gravity_mod = 100
	velocity_limiter = {"x" : null, "up" : null, "down" : null, "x_slow" : null, "y_slow" : null}
	if Animator.query_current(["LaunchStop"]):
		sprite.rotation = launch_starting_rot
	else:
		sprite.rotation = 0
	
	match anim_name:
		"Run":
			Globals.Game.spawn_SFX("RunDust", "DustClouds", get_feet_pos(), {"facing":facing, "grounded":true})
		
		"Dash":
			if Globals.survival_level != null and !ground_dash_enhance():
				return
			
		"JumpTransit2":
#			if button_jump in input_state.pressed and (button_down in input_state.pressed or button_block in input_state.pressed):
#				# block and jump to shorthop
#				$ShorthopTimer.time = ShorthopTimer_TIME
#				velocity.y = -FMath.percent(get_stat("JUMP_SPEED"), get_stat("HOP_JUMP_MOD"))
#				if dir != 0: # when hopping can press left/right for a long hop
#					var boost: int = dir * FMath.percent(get_stat("SPEED"), get_stat("LONG_HOP_JUMP_MOD"))
#					velocity.x += boost
#					velocity.x = int(clamp(velocity.x, -abs(boost), abs(boost)))
#					var sfx_point = get_feet_pos()
#					sfx_point.x -= dir * 5 # spawn the dust behind slightly
#					Globals.Game.spawn_SFX("GroundDashDust", "DustClouds", sfx_point, {"facing":dir, "grounded":true})
#				else:
#					Globals.Game.spawn_SFX("JumpDust", "DustClouds", get_feet_pos(), {"facing":facing, "grounded":true})
#			elif button_up in input_state.pressed and button_jump in input_state.pressed: # up and jump to super jump, cannot adjust height
#				velocity.y = -FMath.percent(UniqChar.JUMP_SPEED, UniqChar.SUPER_JUMP_MOD)
#				velocity.x = 0
#			else:
#			velocity.y = -get_stat("JUMP_SPEED")
			if dir != 0:
				velocity.y = -FMath.percent(get_stat("JUMP_SPEED"), get_stat("DIR_JUMP_HEIGHT_MOD"))
				velocity.x += dir * FMath.percent(get_stat("SPEED"), get_stat("HORIZ_JUMP_BOOST_MOD"))
				if velocity.x > get_stat("SPEED"):
					velocity.x = FMath.f_lerp(velocity.x, get_stat("SPEED"), 50)
				elif velocity.x < -get_stat("SPEED"):
					velocity.x = FMath.f_lerp(velocity.x, -get_stat("SPEED"), 50)
				velocity.x = FMath.percent(velocity.x, get_stat("HORIZ_JUMP_SPEED_MOD"))
			else:
				velocity.y = -get_stat("JUMP_SPEED")
			$VarJumpTimer.time = get_stat("VAR_JUMP_TIME")
#			if dir != 0: # when jumping can press left/right for a long jump
#				if abs(velocity.x) < get_stat("SPEED"): # cannot surpass SPEED
#					velocity.x += dir * get_stat("JUMP_HORIZONTAL_SPEED")
#					velocity.x = int(clamp(velocity.x, -get_stat("SPEED"), get_stat("SPEED")))
#					velocity.y += abs(velocity.x - old_horizontal_vel) # reduce vertical speed if so
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
						
#						velocity.x = FMath.percent(velocity.x, 90) # air jump is slower horizontally since no friction
					velocity.y = -FMath.percent(get_stat("JUMP_SPEED"), get_stat("AIR_JUMP_HEIGHT_MOD"))
					velocity.y = FMath.percent(velocity.y, get_stat("DIR_JUMP_HEIGHT_MOD"))
				else: # neutral air jump
					velocity.x = FMath.percent(velocity.x, 70)
					velocity.y = -FMath.percent(get_stat("JUMP_SPEED"), get_stat("AIR_JUMP_HEIGHT_MOD"))
				$VarJumpTimer.time = get_stat("VAR_JUMP_TIME")
				Globals.Game.spawn_SFX("AirJumpDust", "DustClouds", get_feet_pos(), {})
				
				if Globals.survival_level != null:
					air_jump_enhance()
					
			else: # if next to wall when starting an air jump, do wall jump instead
				if wall_jump_dir != 0:
					velocity.x = wall_jump_dir * FMath.percent(get_stat("SPEED"), get_stat("WALL_AIR_JUMP_HORIZ_MOD"))
				else:
					velocity.x = 0 # walls on both side
					wall_jump_dir = facing # for the dash dust effect
#				velocity.y = -get_stat("JUMP_SPEED")
				velocity.y = -FMath.percent(get_stat("JUMP_SPEED"), get_stat("WALL_AIR_JUMP_VERT_MOD"))
				$VarJumpTimer.time = get_stat("VAR_JUMP_TIME")
				var wall_point = Detection.wall_finder(position - (wall_jump_dir * Vector2($PlayerCollisionBox.rect_size.x / 2, 0)), \
					-wall_jump_dir)
				if wall_point != null:
					Globals.Game.spawn_SFX("GroundDashDust", "DustClouds", wall_point, {"facing":wall_jump_dir, "rot":PI/2})
#				else:
#					Globals.Game.spawn_SFX("AirJumpDust", "DustClouds", get_feet_pos(), {})
				reset_jumps_except_walljumps()
		"WallJumpTransit2":
			aerial_memory = []
			if wall_jump_dir != 0:
				velocity.x = wall_jump_dir * FMath.percent(get_stat("SPEED"), get_stat("WALL_AIR_JUMP_HORIZ_MOD"))
			else:
				velocity.x = 0 # walls on both side
				wall_jump_dir = facing # for the dash dust effect
#			velocity.y = -get_stat("JUMP_SPEED")
			velocity.y = -FMath.percent(get_stat("JUMP_SPEED"), get_stat("WALL_AIR_JUMP_VERT_MOD"))
			$VarJumpTimer.time = get_stat("VAR_JUMP_TIME")
			var wall_point = Detection.wall_finder(position - (wall_jump_dir * Vector2($PlayerCollisionBox.rect_size.x / 2, 0)), \
				-wall_jump_dir)
			if wall_point != null:
				Globals.Game.spawn_SFX("GroundDashDust", "DustClouds", wall_point, {"facing":wall_jump_dir, "rot":PI/2})
#			else:
#				Globals.Game.spawn_SFX("AirJumpDust", "DustClouds", get_feet_pos(), {})
			reset_jumps_except_walljumps()
		"HardLanding":
			Globals.Game.spawn_SFX("LandDust", "DustClouds", get_feet_pos(), {"grounded":true})
		"SoftLanding":
			Globals.Game.spawn_SFX("LandDust", "DustClouds", get_feet_pos(), {"grounded":true})
			
		"BlockStartup", "aBlockStartup":
			success_block = Em.success_block.NONE
			if Globals.survival_level != null:
				block_enhance()
			
		"DodgeTransit":
			aerial_memory = []
			air_dodge -= 1
			anim_gravity_mod = 0
			anim_friction_mod = 0
			velocity_limiter.x_slow = 10
			velocity_limiter.y_slow = 10
		"Dodge":
			face_opponent()
			var tech_angle: int
				
			var rs_dir := Vector2(0, 0)
			if button_rs_up in input_state.pressed:
				rs_dir.y -= 1
			if button_rs_down in input_state.pressed:
				rs_dir.y += 1
			if button_rs_left in input_state.pressed:
				rs_dir.x -= 1
			if button_rs_right in input_state.pressed:
				rs_dir.x += 1
				
			if rs_dir == Vector2(0, 0): # LS dodge
				if !grounded or soft_grounded:
					tech_angle = Globals.dir_to_angle(dir, v_dir, facing)
				else:
					if v_dir == -1:
						tech_angle = Globals.dir_to_angle(dir, -1, facing)
					else:
						tech_angle = Globals.dir_to_angle(dir, 0, facing)
			else: # RS dodge
				if !grounded or soft_grounded:
# warning-ignore:narrowing_conversion
# warning-ignore:narrowing_conversion
					tech_angle = Globals.dir_to_angle(rs_dir.x, rs_dir.y, facing)
				else:
					if rs_dir.y == -1:
# warning-ignore:narrowing_conversion
						tech_angle = Globals.dir_to_angle(rs_dir.x, -1, facing)
					else:
# warning-ignore:narrowing_conversion
						tech_angle = Globals.dir_to_angle(rs_dir.x, 0, facing)
						
			velocity.set_vector(get_stat("DODGE_SPEED"), 0)
			velocity.rotate(tech_angle)
			anim_gravity_mod = 0
			anim_friction_mod = 0
			velocity_limiter.x_slow = 12
			velocity_limiter.y_slow = 12
			afterimage_timer = 1 # sync afterimage trail
#			Globals.Game.spawn_SFX( "AirDashDust", "DustClouds", position, {})
			modulate_play("dodge_flash")
			play_audio("bling1", {"vol" : -15, "bus": "PitchDown"})
		"DodgeRec", "DodgeCRec":
			anim_gravity_mod = 0
			anim_friction_mod = 0
			velocity_limiter.x_slow = 12
			velocity_limiter.y_slow = 12
			
		"BurstCounterStartup", "BurstEscapeStartup":
			velocity_limiter.x_slow = 20
			velocity_limiter.y_slow = 20
			anim_gravity_mod = 0
			if anim_name == "BurstCounterStartup":
				modulate_play("yellow_burst")
			else:
				modulate_play("blue_burst")
			play_audio("faller1", {"vol" : -10, "bus" : "PitchUp"})
		"BurstCounter", "BurstEscape", "BurstAwakening":
#			chain_combo = 0
			velocity.set_vector(0, 0)
			velocity_limiter.x = 0
			anim_gravity_mod = 0
#			var burst_facing = 1
#			if rng_generate(2) == 0:
#				burst_facing = -1
			if anim_name == "BurstCounter":
				Globals.Game.spawn_entity(player_ID, "BurstCounter", position, {})
			elif anim_name == "BurstEscape":
				Globals.Game.spawn_entity(player_ID, "BurstEscape", position, {})
				$HitStunTimer.stop()
			else:
				Globals.Game.spawn_entity(player_ID, "BurstAwakening", position, {})
				modulate_play("white_burst")
				play_audio("bling7", {"vol" : -10, "bus" : "PitchUp2"})
				$EXSealTimer.stop()
				change_ex_gauge(MAX_EX_GAUGE)
				reset_jumps()
				if current_guard_gauge < 0: # gain positive flow
					add_status_effect([Em.status_effect.POS_FLOW, null])
				change_burst_token(Em.burst.CONSUMED)
			play_audio("blast1", {"vol" : -18,})
		"BurstCRec":
			anim_gravity_mod = 0
			
#		"AReset":
#			anim_gravity_mod = 0
#			anim_friction_mod = 0
#			play_audio("bling7", {"vol" : -10, "bus" : "PitchUp"})
#			Globals.Game.spawn_SFX("Reset", "Shines", position, {"facing":Globals.Game.rng_facing(), \
#				"v_mirror":Globals.Game.rng_bool()}, "pink")
#			modulate_play("pink_reset")
#		"AResetCRec":
#			anim_gravity_mod = 0
#			anim_friction_mod = 0
		"SDashTransit":
			anim_gravity_mod = 0
			anim_friction_mod = 0
			velocity_limiter.x_slow = 10
			velocity_limiter.y_slow = 10
			afterimage_timer = 1 # sync afterimage trail
		"SDash":
#			remove_status_effect(Em.status_effect.POS_FLOW)
			aerial_memory = []
			if !grounded:
				super_dash = int(max(0, super_dash - 1))
			var sdash_angle: int
			if !grounded or soft_grounded:
				sdash_angle = Globals.dir_to_angle(dir, v_dir, facing)
			else:
				if v_dir == -1:
					sdash_angle = Globals.dir_to_angle(dir, -1, facing)
				else:
					sdash_angle = Globals.dir_to_angle(dir, 0, facing)
			velocity.set_vector(get_stat("SDASH_SPEED"), 0)
			velocity.rotate(sdash_angle)
			anim_gravity_mod = 0
			anim_friction_mod = 0
			afterimage_timer = 1 # sync afterimage trail
			Globals.Game.spawn_SFX( "RingDust", "RingDust", position, {"rot":deg2rad(sdash_angle), "back":true})
			rotate_sprite(sdash_angle)
#		"SDash":
#			anim_gravity_mod = 0
#			anim_friction_mod = 0
#			afterimage_timer = 1 # sync afterimage trail
			
	UniqChar._on_SpritePlayer_anim_started(anim_name)
	
	
func _on_SpritePlayer_frame_update(): # emitted after every frame update, useful for staggering audio
	UniqChar.stagger_anim()

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
	
#	if !Loader.audio: # custom audio, have the audioplayer search this node's unique_audio dictionary
#		aux_data["unique_path"] = get_path() # add a new key to aux_data
		
	Globals.Game.play_audio(audio_ref, aux_data)

		

# triggered by SpritePlayer at start of each animation
func _on_change_spritesheet(spritesheet_filename):
	sprite.texture = Loader.char_data[UniqChar.NAME].spritesheet[spritesheet_filename]
	sprite_texture_ref.sprite = spritesheet_filename
	
func _on_change_SfxOver_spritesheet(SfxOver_spritesheet_filename):
	sfx_over.show()
	sfx_over.texture = Loader.char_data[UniqChar.NAME].spritesheet[SfxOver_spritesheet_filename]
	sprite_texture_ref.sfx_over = SfxOver_spritesheet_filename
	
func hide_SfxOver():
	sfx_over.hide()
	
func _on_change_SfxUnder_spritesheet(SfxUnder_spritesheet_filename):
	sfx_under.show()
	sfx_under.texture = Loader.char_data[UniqChar.NAME].spritesheet[SfxUnder_spritesheet_filename]
	sprite_texture_ref.sfx_under = SfxUnder_spritesheet_filename
	
func hide_SfxUnder():
	sfx_under.hide()


# SAVE/LOAD STATE --------------------------------------------------------------------------------------------------

func save_state():
	var state_data = {
			
		"position" : position,
		"air_jump" : air_jump,
		"wall_jump" : wall_jump,
		"air_dash" : air_dash,
		"air_dodge" : air_dodge,
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
		"success_block" : success_block,
		"success_dodge" : success_dodge,
		"target_ID" : target_ID,
		"seq_partner_ID" : seq_partner_ID,
		"burst_token": burst_token,
		"impulse_used" : impulse_used,
		"quick_turn_used" : quick_turn_used,
		"strafe_lock_dir" : strafe_lock_dir,
		"DI_seal" : DI_seal,
		"last_dir": last_dir,
		"first_hit_flag" : first_hit_flag,
		"GG_swell_flag" : GG_swell_flag,
		"lethal_flag" : lethal_flag,
		"from_move_rec" : from_move_rec,
		"slowed" : slowed,
		"spent_special" : spent_special,
		"spent_unique" : spent_unique,
		"wall_slammed" : wall_slammed,
		"delayed_hit_effect" : delayed_hit_effect,
		
		"sprite_texture_ref" : sprite_texture_ref,
		
		"current_damage_value" : current_damage_value,
		"current_guard_gauge" : current_guard_gauge,
		"current_ex_gauge" : current_ex_gauge,
		"super_ex_lock" : super_ex_lock,
		"stock_points_left" : stock_points_left,
		"coin_count" : coin_count,
		
		"unique_data" : unique_data,
		"repeat_memory" : repeat_memory,
		"aerial_memory" : aerial_memory,
		"aerial_sp_memory" : aerial_sp_memory,
		"status_effects" : status_effects,
		"hitcount_record" : hitcount_record,
		"ignore_list" : ignore_list,
		"tap_memory" : tap_memory,
		"release_memory" : release_memory,
		"instant_actions" : instant_actions,
		
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
		"HitStopTimer_time" : $HitStopTimer.time,
		"RespawnTimer_time" : $RespawnTimer.time,
		"BurstLockTimer_time" : $BurstLockTimer.time,
		"EXSealTimer_time" : $EXSealTimer.time,
		"InstallTimer_time" : $InstallTimer.time,
		"ShorthopTimer_time" : $ShorthopTimer.time,
		"NoCollideTimer_time" : $NoCollideTimer.time,
	}
	
	if Globals.training_mode:
		state_data["TrainingRegenTimer_time"] = $TrainingRegenTimer.time
		
	if Globals.survival_level != null:
		state_data["enhance_cooldowns"] = enhance_cooldowns
		state_data["enhance_data"] = enhance_data

	return state_data
	
func load_state(state_data, command_rewind := false):
	
	position = state_data.position
	air_jump = state_data.air_jump
	wall_jump = state_data.wall_jump
	air_dash = state_data.air_dash
	air_dodge = state_data.air_dodge
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
	success_block = state_data.success_block
	success_dodge = state_data.success_dodge
	target_ID = state_data.target_ID
	seq_partner_ID = state_data.seq_partner_ID
	burst_token = state_data.burst_token
	impulse_used = state_data.impulse_used
	quick_turn_used = state_data.quick_turn_used
	strafe_lock_dir = state_data.strafe_lock_dir
	DI_seal = state_data.DI_seal
	last_dir = state_data.last_dir
	first_hit_flag = state_data.first_hit_flag
	GG_swell_flag = state_data.GG_swell_flag
	lethal_flag = state_data.lethal_flag
	from_move_rec = state_data.from_move_rec
	slowed = state_data.slowed
	spent_special = state_data.spent_special
	spent_unique = state_data.spent_unique
	wall_slammed = state_data.wall_slammed
	delayed_hit_effect = state_data.delayed_hit_effect
	if Globals.survival_level != null and !command_rewind:
		enhance_cooldowns = state_data.enhance_cooldowns
		enhance_data = state_data.enhance_data
		
	sprite_texture_ref = state_data.sprite_texture_ref
	
	current_damage_value = state_data.current_damage_value
	current_guard_gauge = state_data.current_guard_gauge
	current_ex_gauge = state_data.current_ex_gauge
	super_ex_lock = state_data.super_ex_lock
	stock_points_left = state_data.stock_points_left
	coin_count = state_data.coin_count
	Globals.Game.damage_update(self)
	Globals.Game.guard_gauge_update(self)
	Globals.Game.ex_gauge_update(self)
	Globals.Game.stock_points_update(self)
	Globals.Game.burst_update(self)
	if Globals.survival_level != null:
		Globals.Game.coin_update(self)
	
	unique_data = state_data.unique_data
	if UniqChar.has_method("update_uniqueHUD"): UniqChar.update_uniqueHUD()
	repeat_memory = state_data.repeat_memory
	aerial_memory = state_data.aerial_memory
	aerial_sp_memory = state_data.aerial_sp_memory
	remove_all_status_effects()
	status_effects = state_data.status_effects
	load_status_effects()
	hitcount_record = state_data.hitcount_record
	ignore_list = state_data.ignore_list
	tap_memory = state_data.tap_memory
	release_memory = state_data.release_memory
	instant_actions = state_data.instant_actions
		
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
#	palette()
	
	$VarJumpTimer.time = state_data.VarJumpTimer_time
	$HitStunTimer.time = state_data.HitStunTimer_time
	$HitStopTimer.time = state_data.HitStopTimer_time
	$RespawnTimer.time = state_data.RespawnTimer_time
	$BurstLockTimer.time = state_data.BurstLockTimer_time
	$EXSealTimer.time = state_data.EXSealTimer_time
	$InstallTimer.time = state_data.InstallTimer_time
	$ShorthopTimer.time = state_data.ShorthopTimer_time
	$NoCollideTimer.time = state_data.NoCollideTimer_time
	
	if Globals.training_mode:
		$TrainingRegenTimer.time = state_data.TrainingRegenTimer_time


	
#--------------------------------------------------------------------------------------------------


