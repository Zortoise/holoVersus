extends "res://Scenes/Physics/Physics.gd"

#signal SFX (anim, loaded_sfx_ref, out_position, aux_data)
#signal afterimage (sprite_node_path, out_position, starting_modulate_a, lifetime)
#signal entity (master_path, entity_ref, out_position, aux_data)

# constants
const MOB = true
const GRAVITY = 70 * FMath.S # per frame

const GUARD_GAUGE_FLOOR = -10000
const GUARD_GAUGE_SWELL_RATE = 100 # exact GG gain per frame during hitstun

const PLAYER_PUSH_SLOWDOWN = 95 # how much characters are slowed when they push against each other

const MIN_HITSTOP = 5
const MAX_HITSTOP = 13
const REPEAT_DMG_MOD = 50 # damage modifier on double_repeat
const HITSTUN_REDUCTION_AT_MAX_GG = 70 # max reduction in hitstun when defender's Guard Gauge is at 200%
#const L_HITSTUN_REDUCTION_AT_MAX_GG = 80 # max reduction in launch hitstun when defender's Guard Gauge is at 200%
#const KB_BOOST_AT_MAX_GG = 300 # max increase of knockback when defender's Guard Gauge is at 200%
const DMG_REDUCTION_AT_MAX_GG = 50 # max reduction in damage when defender's Guard Gauge is at 200%
#const FIRST_HIT_GUARD_DRAIN_MOD = 150 # % of listed Guard Drain on 1st hit of combo or stray hits
const POS_FLOW_REGEN = 140 #  # exact GG gain per frame during Positive Flow
const ATK_LEVEL_TO_F_HITSTUN = [15, 20, 25, 30, 35, 40, 45, 50]
const ATK_LEVEL_TO_L_HITSTUN = [25, 30, 35, 40, 45, 50, 55, 60]
const ATK_LEVEL_TO_GDRAIN = [0, 1500, 1750, 2000, 2250, 2500, 2750, 3000]

const SWEETSPOT_KB_MOD = 115
const SWEETSPOT_DMG_MOD = 150 # damage modifier on sweetspotted hit
const SWEETSPOT_HITSTOP_MOD = 130 # sweetspotted hits has 30% more hitstop

const CRUSH_HITSTOP_ATTACKER = 15 # hitstop for attacker when causing Crush
const LETHAL_HITSTOP = 25
const CRUSH_TIME = 40 # number of frames stun time last for Crush

const GUARDED_KNOCKBACK_MOD = 100 # % of knockback mob experience when attacked outside Guardbroken state

const LAUNCH_THRESHOLD = 450 * FMath.S # max knockback strength before a flinch becomes a launch, also added knockback during a Break
const LAUNCH_BOOST = 250 * FMath.S # increased knockback strength when a flinch becomes a launch
const LAUNCH_ROT_SPEED = 5*PI # speed of sprite rotation when launched, don't need fixed-point as sprite rotation is only visuals
const UNLAUNCH_THRESHOLD = 450 * FMath.S # max velocity when hitting the ground to tech land

const WALL_SLAM_THRESHOLD = 100 * FMath.S # min velocity towards surface needed to do Wall Slams and release BounceDust when bouncing
const WALL_SLAM_VEL_LIMIT_MOD = 500
const WALL_SLAM_MIN_DAMAGE = 1
const WALL_SLAM_MAX_DAMAGE = 100
const HORIZ_WALL_SLAM_UP_BOOST = 500 * FMath.S # if bounce horizontally on ground, boost up a little

const LAUNCH_DUST_THRESHOLD = 1400 * FMath.S # velocity where launch dust increase in frequency


# variables used, don't touch these
var loaded_palette = null
onready var Animator = $SpritePlayer # clean code
onready var sprite = $Sprites/Sprite # clean code
onready var sfx_under = $Sprites/SfxUnder # clean code
onready var sfx_over = $Sprites/SfxOver # clean code
var UniqMob # unique character node
var directory_name
var palette_number

var spritesheets
var unique_audio
var entity_data
var sfx_data

var floor_level

var grounded := true
var hitstop = null # holder to influct hitstop at end of frame
var status_effect_to_remove = [] # holder to remove status effects at end of frame

var mob_ID: int # player number controlling this character, 0 for P1, 1 for P2


# character state, save these when saving and loading along with position, sprite frame and animation progress

var state = Globals.char_state.GROUND_STANDBY
var new_state = Globals.char_state.GROUND_STANDBY
var true_position := FVector.new() # scaled int vector, needed for slow and precise movement
var velocity := FVector.new()
var facing := 1 # 1 for facing right, -1 for facing left
var velocity_previous_frame := FVector.new() # needed to check for landings
var anim_gravity_mod := 100 # set to percent during certain special states, like air dashing
var anim_friction_mod := 100 # set to percent during certain special states, like ground dashing
var velocity_limiter = { # as % of speed, some animations limit max velocity in a certain direction, if null means no limit
	"x" : null, "up" : null, "down" : null, "x_slow" : null, "y_slow" : null
	}

var afterimage_timer := 0 # for use by unique character node
var monochrome := false

var sprite_texture_ref = { # used for afterimages
	"sprite" : null,
	"sfx_over" : null,
	"sfx_under" : null
}

onready var current_damage_value: int = 0
onready var current_guard_gauge: int = 0

var hitcount_record = [] # record number of hits for current attack for each player, cannot do anymore hits if maxed out
var ignore_list = [] # some moves has ignore_time, after hitting will ignore that player for a number of frames, used for multi-hit specials

var launch_starting_rot := 0.0 # starting rotation when being launched, current rotation calculated using hitstun timer and this, can leave as float
var launchstun_rotate := 0 # used to set rotation when being launched, use to count up during hitstun
var unique_data = {} # data unique for the character, stored as a dictionary
var status_effects = [] # an Array of arrays, in each Array store a enum of the status effect and a duration, can have a third data as well

var repeat_memory = [] # appended whenever hit by a move, cleared whenever you recover from hitstun, to incur Repeat Penalty on attacker
					# each entry is an array with [0] being the move name and [1] being the mob_ID

var targeted_opponent_path: NodePath # nodepath of the opponent, changes whenever you land a hit on an opponent or is attacked


var current_command: String # key to a COMMANDS dictionary on UniqMob
var command_timer := 0 # timer that counts up
var guardbroken := false # when GG is depleted, mob enters a guardbroken state where they no longer has superarmor till GG refills


var test := false # used to test specific player, set by main game scene to just one player
var test_num := 0


# SETUP CHARACTER --------------------------------------------------------------------------------------------------

# this is run after adding this node to the tree
func init(in_mob, start_position, start_facing, in_palette_number):
	
	set_mob_id()
	
	# remove test character node and add the real character node
	var test_character = get_child(0) # test character node should be directly under this node
	test_character.free()
	
	UniqMob = in_mob
	add_child(UniqMob)
	move_child(UniqMob, 0)
	directory_name = "res://Mobs/" + UniqMob.NAME + "/"
	
	spritesheets = Globals.Game.LevelControl.spritesheets
	unique_audio = Globals.Game.LevelControl.unique_audio
	entity_data = Globals.Game.LevelControl.entity_data
	sfx_data = Globals.Game.LevelControl.sfx_data
	
	UniqMob.sprite = sprite
	sprite.texture = spritesheets["BaseSprite"]
	
	# set up animators
	UniqMob.Animator = $SpritePlayer
	Animator.init(sprite, sfx_over, sfx_under, directory_name + "FrameData/")
	animate("Idle")
	$ModulatePlayer.sprite = sprite
	$FadePlayer.sprite = sprite
	
	# overwrite default movement stats
	
	setup_boxes(UniqMob.get_node("DefaultCollisionBox"))
	
	# incoming start position points at the floor
	start_position.y -= $PlayerCollisionBox.rect_position.y + $PlayerCollisionBox.rect_size.y
	
	position = start_position
	set_true_position()
	floor_level = Globals.Game.middle_point.y # get floor level of stage
	
	if facing != start_facing:
		face(start_facing)
		
	palette_number = in_palette_number
	if palette_number > 1:
		loaded_palette = ResourceLoader.load(directory_name + "Palettes/" + str(palette_number) + ".png")
	palette()
	sfx_under.hide()
	sfx_over.hide()
	
#	Globals.Game.damage_update(self)
#	Globals.Game.guard_gauge_update(self)
	
	unique_data = UniqMob.UNIQUE_DATA_REF.duplicate(true)
	
	
func set_mob_id(): # each mob has a unique mob_id, set by order when they spawn during a level
	Globals.Game.current_mob_number += 1
	mob_ID = Globals.Game.current_mob_number


func setup_boxes(ref_rect): # set up detection boxes
	
	$PlayerCollisionBox.rect_position = ref_rect.rect_position
	$PlayerCollisionBox.rect_size = ref_rect.rect_size
	$PlayerCollisionBox.add_to_group("Players")
	$PlayerCollisionBox.add_to_group("Grounded")


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
		

func initial_targeting(): # target random players at start, cannot do in init() since need all players to be added first
	# target a random opponent
	var player_IDs = []
	for x in Globals.player_count:
		player_IDs.append(x)
	targeted_opponent_path = Globals.Game.get_player_node(player_IDs[Globals.Game.rng_generate(player_IDs.size())]).get_path()
	

	
# TESTING --------------------------------------------------------------------------------------------------

# for testing only
func test1():
	$TestNode2D/TestLabel.text = $TestNode2D/TestLabel.text + "old state: " + Globals.char_state_to_string(state) + \
		"\n" + Animator.current_animation + " > " + Animator.to_play_animation + "  time: " + str(Animator.time) + "\n"
	
func test2():
	$TestNode2D/TestLabel.text = $TestNode2D/TestLabel.text + "new state: " + Globals.char_state_to_string(state) + \
		"\n" + Animator.current_animation + " > " + Animator.to_play_animation + "  time: " + str(Animator.time) + \
		"\n" + str(velocity.x) + "  grounded: " + str(grounded)
			
			
func _process(_delta):
	if Globals.debug_mode:
		$PlayerCollisionBox.show()
	else:
		$PlayerCollisionBox.hide()

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
			
			
func simulate(_new_input_state):

# FRAMESKIP DURING HITSTOP --------------------------------------------------------------------------------------------------
	# while buffering all inputs
	
	hitstop = null
	status_effect_to_remove = []
	
	if Globals.Game.is_stage_paused() and Globals.Game.screenfreeze != mob_ID: # screenfrozen
		return
	
	$HitStopTimer.simulate() # advancing the hitstop timer at start of frame allow for one frame of knockback before hitstop
	# will be needed for multi-hit moves
	
	if !$HitStopTimer.is_running():
		simulate2()
		

func simulate2(): # only ran if not in hitstop
	
# START OF FRAME --------------------------------------------------------------------------------------------------
		
	if is_on_ground($PlayerCollisionBox):
		grounded = true
	else:
		grounded = false
		
	ignore_list_progress_timer()
	process_status_effects_timer() # remove expired status effects before running hit detection since that can add effects
	
	# clearing repeat memory
	if !is_hitstunned() and !state in [Globals.char_state.SEQUENCE_TARGET]:
		repeat_memory = []
		
	# GG Swell during guardbroken state
	if !$HitStopTimer.is_running() and !state in [Globals.char_state.SEQUENCE_TARGET]:
		if guardbroken:
			current_guard_gauge = int(min(0, current_guard_gauge + GUARD_GAUGE_SWELL_RATE))
			if current_guard_gauge == 0:
				guardbroken = false
	#		Globals.Game.guard_gauge_update(self)
		else:
			if current_guard_gauge < 0:
				var guard_gauge_regen: int = 0
				guard_gauge_regen = UniqMob.get_stat("GUARD_GAUGE_REGEN_AMOUNT")
				current_guard_gauge = int(min(0, current_guard_gauge + guard_gauge_regen))
	#			Globals.Game.guard_gauge_update(self)
		
	if state in [Globals.char_state.SEQUENCE_USER, Globals.char_state.SEQUENCE_TARGET]:
		simulate_sequence()
		return
		
# AI COMMANDS --------------------------------------------------------------------------------------------------
		
	if current_command != "":
		command_timer += 1
		
# MOVEMENT --------------------------------------------------------------------------------------------------

	var dir: = 0

	if UniqMob.COMMANDS.current_command.action == "Run":
		dir = UniqMob.COMMANDS.current_command.dir
		match state:
			
	# GROUND MOVEMENT --------------------------------------------------------------------------------------------------
	
			Globals.char_state.GROUND_STANDBY:
				if dir != facing: # flipping over
					face(dir)
					animate("RunTransit") # restart run animation
				 # if not in run animation, do run animation
				if !Animator.query(["Run", "RunTransit"]):
					animate("RunTransit")
						
				velocity.x = FMath.f_lerp(velocity.x, dir * UniqMob.get_stat("SPEED"), UniqMob.get_stat("ACCELERATION"))

			

# CHECK DROPS AND LANDING ---------------------------------------------------------------------------------------------------
	
	if !grounded:
		pass
	else: # just in case, normally called when physics.gd runs into a floor
		match new_state:
			Globals.char_state.AIR_STANDBY, Globals.char_state.AIR_STARTUP, \
				Globals.char_state.AIR_ACTIVE, Globals.char_state.AIR_RECOVERY, Globals.char_state.AIR_ATK_STARTUP, \
				Globals.char_state.AIR_ATK_ACTIVE, Globals.char_state.AIR_ATK_RECOVERY, Globals.char_state.AIR_FLINCH_HITSTUN, \
				Globals.char_state.LAUNCHED_HITSTUN:
				check_landing()

# GRAVITY --------------------------------------------------------------------------------------------------

	var gravity_temp: int = FMath.percent(GRAVITY, UniqMob.get_stat("GRAVITY_MOD"))
		
	if anim_gravity_mod != 100:
		gravity_temp = FMath.percent(GRAVITY, anim_gravity_mod) # anim_gravity_mod is based off current animation

	if !grounded: # gravity only pulls you if you are in the air
		
		if is_hitstunned():
			pass
		else:
			if velocity.y > 0: # some mobs may fall at different speed compared to going up
				gravity_temp = FMath.percent(gravity_temp, UniqMob.get_stat("FALL_GRAV_MOD"))
				
		velocity.y += gravity_temp
		
	# terminal velocity downwards
	var terminal: int
	
	var has_terminal := true

#	if is_atk_startup():
#		if Globals.atk_attr.NO_TERMINAL_VEL_STARTUP in query_atk_attr():
#			 has_terminal = false
	if is_atk_active():
		if Globals.atk_attr.NO_TERMINAL_VEL_ACTIVE in query_atk_attr():
			 has_terminal = false

	if has_terminal:
		terminal = FMath.percent(GRAVITY, UniqMob.get_stat("TERMINAL_VELOCITY_MOD"))

		if velocity.y > terminal:
			velocity.y = FMath.f_lerp(velocity.y, terminal, 75)
		

# FRICTION/AIR RESISTANCE AND TRIGGERED ANIMATION CHANGES ----------------------------------------------------------
	# place this at end of frame later
	# for triggered animation changes, use query_to_play() instead
	# query() check animation at either start/end of frame, query_to_play() only check final animation
	
	var friction_this_frame: int # 15
	var air_res_this_frame: int
	
	friction_this_frame = UniqMob.get_stat("FRICTION")
	air_res_this_frame = UniqMob.get_stat("AIR_RESISTANCE")
	
	match state:
		Globals.char_state.GROUND_STANDBY:
			if dir == 0: # if not moving
				# if in run animation, do brake animation
				if Animator.query_to_play(["Run", "RunTransit"]):
					animate("Brake")
			else: # no friction when moving
				friction_this_frame = 0
	
		Globals.char_state.GROUND_STARTUP:
			friction_this_frame = 0 # no friction when starting a ground jump/dash

		Globals.char_state.AIR_STANDBY:
			# just in case, fall animation if falling downwards without slowing down
			if velocity.y > 0 and Animator.query_to_play(["Jump"]):
				animate("FallTransit")
	
		Globals.char_state.AIR_STARTUP, Globals.char_state.AIR_RECOVERY:
			air_res_this_frame = 0

		Globals.char_state.AIR_ATK_STARTUP:
			air_res_this_frame = 0
			
		Globals.char_state.AIR_ATK_ACTIVE:
			air_res_this_frame = 0
			
		Globals.char_state.GROUND_FLINCH_HITSTUN:
			# when out of hitstun, recover
			if !$HitStunTimer.is_running():
				if Animator.query_to_play(["FlinchA"]):
					animate("FlinchAReturn")
				elif Animator.query_to_play(["FlinchB"]):
					animate("FlinchBReturn")
				$ModulatePlayer.play("unflinch_flash")
			else:
				friction_this_frame = FMath.percent(friction_this_frame, 50) # lower friction during flinch hitstun
					
		Globals.char_state.AIR_FLINCH_HITSTUN:
			# when out of hitstun, recover
#			if velocity.y > HITSTUN_FALL_THRESHOLD and position.y > floor_level:
#				velocity.y = HITSTUN_FALL_THRESHOLD # limit downward velocity during air flinch
			if !$HitStunTimer.is_running():
				if Animator.query_to_play(["aFlinchA"]):
					animate("aFlinchAReturn")
				elif Animator.query_to_play(["aFlinchB"]):
					animate("aFlinchBReturn")
				$ModulatePlayer.play("unflinch_flash")
		
		Globals.char_state.LAUNCHED_HITSTUN:
			# when out of hitstun, recover
			if !$HitStunTimer.is_running() and Animator.query_to_play(["Launch", "LaunchTransit"]):
				animate("FallTransit")
				$ModulatePlayer.play("unlaunch_flash")
				play_audio("bling4", {"vol" : -15, "bus" : "PitchDown"})
			friction_this_frame = FMath.percent(friction_this_frame, 25) # lower friction during launch hitstun
							
	
# APPLY FRICTION/AIR RESISTANCE --------------------------------------------------------------------------------------------------

	if grounded: # apply friction if on ground
		if anim_friction_mod != 100:
			friction_this_frame = FMath.percent(friction_this_frame, anim_friction_mod)
		velocity.x = FMath.f_lerp(velocity.x, 0, friction_this_frame)

	else: # apply air resistance if in air
		velocity.x = FMath.f_lerp(velocity.x, 0, air_res_this_frame)
	
# --------------------------------------------------------------------------------------------------

	UniqMob.simulate() 

# --------------------------------------------------------------------------------------------------
	
	# finally move the damn thing

	# limit velocity if velocity limiter is not null, "if velocity_limiter.x" will not pass if it is zero!
	if velocity_limiter.x != null:
		var limit: int = FMath.percent(UniqMob.get_stat("SPEED"), velocity_limiter.x)
		velocity.x = int(clamp(velocity.x, -limit, limit))
	if velocity_limiter.up != null and velocity.y < -FMath.percent(UniqMob.get_stat("SPEED"), velocity_limiter.up):
		velocity.y = -FMath.percent(UniqMob.get_stat("SPEED"), velocity_limiter.up)
	if velocity_limiter.down != null and velocity.y > FMath.percent(UniqMob.get_stat("SPEED"), velocity_limiter.down):
		velocity.y = FMath.percent(UniqMob.get_stat("SPEED"), velocity_limiter.down)
	if velocity_limiter.x_slow != null:
		velocity.x = FMath.f_lerp(velocity.x, 0, velocity_limiter.x_slow)
	if velocity_limiter.y_slow != null:
		velocity.y = FMath.f_lerp(velocity.y, 0, velocity_limiter.y_slow)
	
	if !$HitStopTimer.is_running() and $HitStunTimer.is_running() and state == Globals.char_state.LAUNCHED_HITSTUN:
		launch_trail() # do launch trail before moving
		
	if grounded and abs(velocity.x) < 30 * FMath.S:
		velocity.x = 0  # this reduces slippiness by canceling grounded horizontal velocity when moving less than 0.5 pixels per frame

	velocity_previous_frame.x = velocity.x
	velocity_previous_frame.y = velocity.y
	
	var orig_pos = position
	var results = move($PlayerCollisionBox, $SoftPlatformDBox, true) # [landing_check, collision_check, ledgedrop_check]
	
#	if results[0]: check_landing()

	if results[1]:
		if $NoCollideTimer.is_running(): # if collide during 1st/Xth frame after hitstop, will return to position before moving
			position = orig_pos
			set_true_position()
			velocity.x = velocity_previous_frame.x
			velocity.y = velocity_previous_frame.y
		else:
			if results[0]: check_landing()
			
			elif new_state == Globals.char_state.LAUNCHED_HITSTUN:
				bounce(results[0])
		
	

func simulate_after(): # called by game scene after hit detection to finish up the frame
	
	test1()
	
	for effect in status_effect_to_remove: # remove certain status effects at end of frame after hit detection
										   # useful for status effects that are removed after being hit
		remove_status_effect(effect)
		
	if Globals.Game.is_stage_paused() and Globals.Game.screenfreeze != mob_ID:
		hitstop = null
		return
	
	
	process_status_effects_visual()
	
	if !$HitStopTimer.is_running():
		
		# render the next frame, this update the time!
		$SpritePlayer.simulate()
		$FadePlayer.simulate() # ModulatePlayer ignore hitstop but FadePlayer doesn't
		
		if !hitstop: # timers do not run on exact frame hitstop starts
			$HitStunTimer.simulate()
			$NoCollideTimer.simulate()

		UniqMob.unique_flash()
		process_afterimage_trail() 	# do afterimage trails
		
		# spin character during launch, be sure to do this after SpritePlayer since rotation is reset at start of each animation
		if state == Globals.char_state.LAUNCHED_HITSTUN and Animator.query_current(["LaunchTransit", "Launch"]):
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
	if is_against_wall($PlayerCollisionBox, $PlayerCollisionBox, sign(velocity_previous_frame.x)):
		if grounded:
			velocity.y = -HORIZ_WALL_SLAM_UP_BOOST
		velocity.x = -FMath.percent(velocity_previous_frame.x, 75)
		if abs(velocity.x) > WALL_SLAM_THRESHOLD: # release bounce dust if fast enough
			if sign(velocity_previous_frame.x) > 0:
				bounce_dust(Globals.compass.E)
			else:
				bounce_dust(Globals.compass.W)
			play_audio("rock3", {"vol" : -10,})
			
				
	elif is_against_ceiling($PlayerCollisionBox, $PlayerCollisionBox):
		velocity.y = -FMath.percent(velocity_previous_frame.y, 50)
		if abs(velocity.y) > WALL_SLAM_THRESHOLD: # release bounce dust if fast enough
			bounce_dust(Globals.compass.N)
			play_audio("rock3", {"vol" : -10,})
			
				
	elif against_ground:
		velocity.y = -FMath.percent(velocity_previous_frame.y, 90)
		if abs(velocity.y) > WALL_SLAM_THRESHOLD: # release bounce dust if fast enough towards ground
			bounce_dust(Globals.compass.S)
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
	

# STATE DETECT ---------------------------------------------------------------------------------------------------

func animate(anim):
	
	Animator.play(anim)
	new_state = state_detect(anim)
	
	if anim.ends_with("Active"):
		atk_startup_resets() # need to do this here to work! resets hitcount and ignore list

	
func query_state(query_states: Array):
	for x in query_states:
		if state == x or new_state == x:
			return true
	return false

func state_detect(anim):
	match anim:
		# universal animations
		"Idle", "RunTransit", "Run", "Brake", "TurnTransit":
			return Globals.char_state.GROUND_STANDBY
		"Landing":
			return Globals.char_state.GROUND_RECOVERY
		"FallTransit", "Fall":
			return Globals.char_state.AIR_STANDBY
			
		"FlinchAStop", "FlinchA", "FlinchBStop", "FlinchB":
			return Globals.char_state.GROUND_FLINCH_HITSTUN
		"FlinchAReturn", "FlinchBReturn":
			return Globals.char_state.GROUND_C_RECOVERY
		"aFlinchAStop", "aFlinchA", "aFlinchBStop", "aFlinchB":
			return Globals.char_state.AIR_FLINCH_HITSTUN
		"aFlinchAReturn", "aFlinchBReturn":
			return Globals.char_state.AIR_C_RECOVERY
		"LaunchStop", "LaunchTransit", "Launch":
			return Globals.char_state.LAUNCHED_HITSTUN
		
		"SeqFlinchAFreeze", "SeqFlinchBFreeze":
			return Globals.char_state.SEQUENCE_TARGET
		"SeqFlinchAStop", "SeqFlinchA", "SeqFlinchBStop", "SeqFlinchB":
			return Globals.char_state.SEQUENCE_TARGET
		"aSeqFlinchAFreeze", "aSeqFlinchBFreeze":
			return Globals.char_state.SEQUENCE_TARGET
		"aSeqFlinchAStop", "aSeqFlinchA", "aSeqFlinchBStop", "aSeqFlinchB":
			return Globals.char_state.SEQUENCE_TARGET
		"SeqLaunchFreeze":
			return Globals.char_state.SEQUENCE_TARGET
		"SeqLaunchStop", "SeqLaunchTransit", "SeqLaunch":
			return Globals.char_state.SEQUENCE_TARGET
			
			
		_: # unique animations
			return UniqMob.state_detect(anim)
			
	
# ---------------------------------------------------------------------------------------------------

func on_kill():

	if UniqMob.has_method("on_kill"): # for unique_data changes on death
		UniqMob.on_kill()
			
func face(in_dir):
	facing = in_dir
	sprite.scale.x = facing
	sfx_over.scale.x = facing
	sfx_under.scale.x = facing
	
func face_opponent():
	if get_node(targeted_opponent_path).position.x - position.x != 0 and \
			sign(get_node(targeted_opponent_path).position.x - position.x) != facing:
		face(-facing)
	
func check_landing(): # called by physics.gd when character stopped by floor
	match new_state:
		Globals.char_state.AIR_STANDBY, Globals.char_state.AIR_RECOVERY:
			animate("Landing")

		Globals.char_state.AIR_FLINCH_HITSTUN: # land during hitstun
			Globals.Game.spawn_SFX("LandDust", "DustClouds", get_feet_pos(), {"facing":facing, "grounded":true})
			match Animator.to_play_animation:
				"aFlinchAStop", "aFlinchA":
					animate("FlinchA")
				"aFlinchBStop", "aFlinchB":
					animate("FlinchB")
			if velocity_previous_frame.y > 300 * FMath.S:
				UniqMob.landing_sound() # only make landing sound if landed fast enough, or very annoying
			
		Globals.char_state.LAUNCHED_HITSTUN: # land during launch_hitstun, can bounce or tech land
			if new_state == Globals.char_state.LAUNCHED_HITSTUN:
				# need to use new_state to prevent an issue with grounded Break state causing HardLanding on flinch
				# check using either velocity this frame or last frame
					
				var vector_to_check
				if velocity.is_longer_than_another(velocity_previous_frame):
					vector_to_check = velocity
				else:
					vector_to_check = velocity_previous_frame
				
				if !vector_to_check.is_longer_than(UNLAUNCH_THRESHOLD):
					animate("Landing")
					$HitStunTimer.stop()
					velocity.y = 0 # stop bouncing
					$ModulatePlayer.play("unlaunch_flash")
					play_audio("bling4", {"vol" : -15, "bus" : "PitchDown"})
			


func check_collidable(): # called by Physics.gd
	match new_state:
		Globals.char_state.SEQUENCE_TARGET, Globals.char_state.SEQUENCE_USER:
			return false
			
	return UniqMob.check_collidable()
	
func check_fallthrough(): # during aerials, can drop through platforms if down is held
	return false
	
func check_semi_invuln():
	return false	
	
func check_passthrough():
	if state == Globals.char_state.SEQUENCE_USER:
		return UniqMob.sequence_passthrough() # for cinematic supers
	elif state == Globals.char_state.SEQUENCE_TARGET:
		return get_node(targeted_opponent_path).check_passthrough() # copy passthrough state of the one grabbing you
	return false
		
func get_feet_pos(): # return global position of the point the character is standing on, for SFX emission
	return position + Vector2(0, $PlayerCollisionBox.rect_position.y + $PlayerCollisionBox.rect_size.y)


# SPECIAL EFFECTS --------------------------------------------------------------------------------------------------

func bounce_dust(orig_dir):
	match orig_dir:
		Globals.compass.N:
			Globals.Game.spawn_SFX("BounceDust", "DustClouds", position + Vector2(0, $PlayerCollisionBox.rect_position.y), {"rot":PI})
		Globals.compass.E:
			Globals.Game.spawn_SFX("BounceDust", "DustClouds", position + Vector2($PlayerCollisionBox.rect_size.x / 2, 0), \
				{"facing": 1, "rot":-PI/2})
		Globals.compass.S:
			Globals.Game.spawn_SFX("BounceDust", "DustClouds", get_feet_pos(), {"grounded":true})
		Globals.compass.W:
			Globals.Game.spawn_SFX("BounceDust", "DustClouds", position - Vector2($PlayerCollisionBox.rect_size.x / 2, 0), \
				{"facing": -1, "rot":-PI/2})

func set_monochrome():
	if !monochrome:
		monochrome = true
		sprite.material = ShaderMaterial.new()
		sprite.material.shader = Globals.monochrome_shader

# particle emitter, visuals only, no need fixed-point
func particle(anim: String, loaded_sfx_ref: String, palette: String, interval, number, radius, v_mirror_rand = false):
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
			if palette != "":
				aux_data["palette"] = palette
			Globals.Game.spawn_SFX(anim, loaded_sfx_ref, particle_pos, aux_data)
		
#func get_spritesheets():
#	pass
			
func process_afterimage_trail():# process afterimage trail
	# Character.afterimage_trail() can accept 2 parameters, 1st is the starting modulate, 2nd is the lifetime
	
	# afterimage trail for certain modulate animations with the key "afterimage_trail"
	if LoadedSFX.modulate_animations.has($ModulatePlayer.current_animation) and \
		LoadedSFX.modulate_animations[$ModulatePlayer.current_animation].has("afterimage_trail") and \
		$ModulatePlayer.is_playing():
		# basic afterimage trail for "afterimage_trail" = 0
		if LoadedSFX.modulate_animations[$ModulatePlayer.current_animation]["afterimage_trail"] == 0:
			afterimage_trail()
			return
			
	UniqMob.afterimage_trail()
			
			
func afterimage_trail(color_modulate = null, starting_modulate_a = 0.6, lifetime: int = 10, \
		afterimage_shader = Globals.afterimage_shader.MASTER): # one afterimage every 3 frames
			
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
			Globals.Game.spawn_afterimage(get_path(), sprite_texture_ref.sfx_under, sfx_under.get_path(), main_color_modulate, \
				starting_modulate_a, lifetime, afterimage_shader)
			
		Globals.Game.spawn_afterimage(get_path(), sprite_texture_ref.sprite, sprite.get_path(), main_color_modulate, \
			starting_modulate_a, lifetime, afterimage_shader)
#		spawn_afterimage(master_path, spritesheet_ref, sprite_node_path, color_modulate = null, starting_modulate_a = 0.5, lifetime = 10.0)
		
		if sfx_over.visible:
			Globals.Game.spawn_afterimage(get_path(), sprite_texture_ref.sfx_over, sfx_over.get_path(), main_color_modulate, \
				starting_modulate_a, lifetime, afterimage_shader)
	else:
		afterimage_timer -= 1
		
		
func afterimage_cancel(starting_modulate_a = 0.5, lifetime: int = 12): # no need color_modulate for now
	
	if sfx_under.visible:
		Globals.Game.spawn_afterimage(get_path(), sprite_texture_ref.sfx_under, sfx_under.get_path(), null, \
			starting_modulate_a, lifetime)
		
	Globals.Game.spawn_afterimage(get_path(), sprite_texture_ref.sprite, sprite.get_path(), null, \
		starting_modulate_a, lifetime)
	
	if sfx_over.visible:
		Globals.Game.spawn_afterimage(get_path(), sprite_texture_ref.sfx_over, sfx_over.get_path(), null, \
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
			Globals.Game.spawn_SFX("DragRocks", "DustClouds", get_feet_pos(), {"facing":Globals.Game.rng_facing(), "grounded":true})
			
	
# QUICK STATE CHECK ---------------------------------------------------------------------------------------------------
	
func get_move_name():
	var move_name = Animator.to_play_animation.trim_suffix("Startup")
	move_name = move_name.trim_suffix("Active")
	move_name = move_name.trim_suffix("Rec")
	return move_name
	
func is_hitstunned():
	match state: # use non-new state
		Globals.char_state.AIR_FLINCH_HITSTUN, Globals.char_state.GROUND_FLINCH_HITSTUN, Globals.char_state.LAUNCHED_HITSTUN:
			return true
	return false
	
func is_attacking():
	match new_state:
		Globals.char_state.GROUND_ATK_STARTUP, Globals.char_state.GROUND_ATK_ACTIVE, Globals.char_state.GROUND_ATK_RECOVERY, \
			Globals.char_state.AIR_ATK_STARTUP, Globals.char_state.AIR_ATK_ACTIVE, Globals.char_state.AIR_ATK_RECOVERY, \
			Globals.char_state.SEQUENCE_USER:
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
	
func load_status_effects(): # loading game state, reapply all one-time visual changes from status_effects
	for status_effect in status_effects:
		new_status_effect(status_effect[0])

func query_status_effect(effect):
	for status_effect in status_effects:
		if status_effect[0] == effect:
			return true
	return false
	
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
			Globals.status_effect.STUN_RECOVER: # when recovering from a combo where a Stun occur, restore Guard Gauge to 50%
				if !is_hitstunned():
					status_effect_to_remove.append(status_effect[0])
					if current_guard_gauge < -5000:
						current_guard_gauge = -5000
						Globals.Game.guard_gauge_update(self)
			Globals.status_effect.POS_FLOW: # positive flow ends if guard gauge returns to 0
				if current_guard_gauge >= 0:
					status_effect_to_remove.append(status_effect[0])
			
#	for status_effect in effect_to_erase:
#		status_effects.erase(status_effect)
#		clear_visual_effect_of_status(status_effect[0])
		
func new_status_effect(effect): # run on frame the status effect is inflicted/state is loaded, for visual effects
	match effect:
		Globals.status_effect.POS_FLOW:
			Globals.Game.HUD.get_node("P" + str(mob_ID + 1) + "_HUDRect/GaugesUnder/GuardGauge1").texture_progress = \
				Globals.loaded_guard_gauge_pos
		Globals.status_effect.LETHAL:
			Globals.Game.lethalfreeze(get_path())
		
func continue_visual_effect_of_status(effect): # run every frame, will not add visual effect if there is already one of higher priority
	match effect:
		Globals.status_effect.LETHAL:
			if !$ModulatePlayer.playing or !$ModulatePlayer.query(["lethal", "lethal_flash"]):
				$ModulatePlayer.play("lethal")
			set_monochrome()
			sprite_shake()
		Globals.status_effect.STUN:
			if !$ModulatePlayer.playing or !$ModulatePlayer.query(["stun", "stun_flash"]):
				$ModulatePlayer.play("stun")
			particle("Sparkle", "Particles", "yellow", 4, 1, 25)
			set_monochrome() # you want to do shaders here instead of new_status_effect() since shaders can be changed
			sprite_shake()
		Globals.status_effect.CRUSH:
			if !$ModulatePlayer.playing or !$ModulatePlayer.query(["crush", "stun_flash"]):
				$ModulatePlayer.play("crush")
			particle("Sparkle", "Particles", "red", 4, 1, 25)
			set_monochrome() # you want to do shaders here instead of new_status_effect() since shaders can be changed
			sprite_shake()
		Globals.status_effect.RESPAWN_GRACE:
			if !$ModulatePlayer.playing or !$ModulatePlayer.query(["respawn_grace"]):
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
		Globals.status_effect.LETHAL:
			Globals.Game.lethalfreeze("unfreeze")
			continue
		Globals.status_effect.LETHAL, Globals.status_effect.STUN, Globals.status_effect.CRUSH:
			if $ModulatePlayer.query_current(["lethal", "stun", "crush"]):
				reset_modulate()
				sprite.position = Vector2.ZERO
#		Globals.status_effect.REPEAT:
#			if monochrome:
#				reset_modulate()
		Globals.status_effect.RESPAWN_GRACE:
			if $ModulatePlayer.query_current(["respawn_grace"]):
				reset_modulate()
		Globals.status_effect.POS_FLOW:
			Globals.Game.HUD.get_node("P" + str(mob_ID + 1) + "_HUDRect/GaugesUnder/GuardGauge1").texture_progress = \
				Globals.loaded_guard_gauge
				
func test_status_visual_effect_priority():
	# visual effects of status effects like Poison has lower priority over effects like EX
	pass
	
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
		"hurtbox" : null,
		"sdhurtbox" : null,
		"hitbox" : null,
		"sweetbox": null,
		"kborigin": null,
		"vacpoint" : null,
	}
	
	if state != Globals.char_state.DEAD:
		if is_attacking():
			if is_atk_active():
				if !$HitStopTimer.is_running(): # no hitbox during hitstop
					polygons_queried.hitbox = Animator.query_polygon("hitbox")
					polygons_queried.sweetbox = Animator.query_polygon("sweetbox")
					polygons_queried.kborigin = Animator.query_point("kborigin")
					polygons_queried.vacpoint = Animator.query_point("vacpoint")
			polygons_queried.sdhurtbox = Animator.query_polygon("sdhurtbox")
			
		if query_status_effect(Globals.status_effect.RESPAWN_GRACE) or query_status_effect(Globals.status_effect.INVULN):
			pass  # no hurtbox during respawn grace or after a strongblock/parry
		else:
			polygons_queried.hurtbox = Animator.query_polygon("hurtbox")

	return polygons_queried
	
	
func query_move_data_and_name(): # requested by main game node when doing hit detection
	
	if Animator.to_play_animation.ends_with("Active"):
		var move_name = Animator.to_play_animation.trim_suffix("Active")
		move_name = UniqMob.refine_move_name(move_name)
		if UniqMob.MOVE_DATABASE.has(move_name):
			return {"move_data" : UniqMob.query_move_data(move_name), "move_name" : move_name}
		else:
			print("Error: " + move_name + " not found in MOVE_DATABASE for query_move_data_and_name().")
	else:
		print("Error: query_move_data_and_name() called by main game node outside of Active frames")
		return null


func get_atk_strength(_move):
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
	
# GAUGES -----------------------------------------------------------------------------------------------------------------------------
	
func get_damage_percent() -> int:
	return FMath.get_fraction_percent(current_damage_value, UniqMob.get_stat("DAMAGE_VALUE_LIMIT"))
	
func get_guard_gauge_percent_below() -> int:
	if current_guard_gauge <= GUARD_GAUGE_FLOOR:
		return 0
	elif current_guard_gauge < 0:
		return 100 - FMath.get_fraction_percent(current_guard_gauge, GUARD_GAUGE_FLOOR)
	else: return 100
		
func take_damage(damage: int): # called by attacker
	current_damage_value += damage
	current_damage_value = int(clamp(current_damage_value, 0, 9999)) # cannot go under zero (take_damage is also used for healing)
	Globals.Game.damage_update(self, damage)
	
func change_guard_gauge(guard_gauge_change: int): # called by attacker
	current_guard_gauge += guard_gauge_change
	current_guard_gauge = int(clamp(current_guard_gauge, GUARD_GAUGE_FLOOR, 0))
	Globals.Game.guard_gauge_update(self)
	
func reset_guard_gauge():
	current_guard_gauge = 0
	Globals.Game.guard_gauge_update(self)
	

# QUERY UNIQUE CHARACTER DATA ---------------------------------------------------------------------------------------------- 
	
func query_traits(): # may have certain conditions
	return UniqMob.query_traits()
	

func query_atk_attr(in_move_name = null):
	
	if in_move_name == null and !is_attacking(): return []
	
	var move_name = in_move_name
	if move_name == null:
		move_name = get_move_name()
	
	return UniqMob.query_atk_attr(move_name)
	
	
func query_atk_attr_current(): # used for the FrameViewer only
	if !is_attacking(): return []
	var move_name = Animator.current_animation.trim_suffix("Startup")
	move_name = move_name.trim_suffix("Active")
	move_name = move_name.trim_suffix("Rec")
	return UniqMob.query_atk_attr(move_name)
	
	
func query_priority(_in_move_name):
	return 0
	
	
func query_move_data(in_move_name = null):
	
	if in_move_name == null and !is_attacking(): return []
	
	var move_name = in_move_name
	if move_name == null:
		move_name = get_move_name()
	
	var move_data = UniqMob.query_move_data(move_name)
	return move_data
	
	
# LANDING A HIT ---------------------------------------------------------------------------------------------- 
	
func landed_a_hit(hit_data): # called by main game node when landing a hit
	
	var defender = get_node(hit_data.defender_nodepath)
	increment_hitcount(defender.mob_ID) # for measuring hitcount of attacks
	targeted_opponent_path = hit_data.defender_nodepath # target last attacked opponent
	
	# ATTACKER HITSTOP ----------------------------------------------------------------------------------------------
		# hitstop is only set into HitStopTimer at end of frame
	
	if "fixed_atker_hitstop" in hit_data.move_data:
		# multi-hit special/super moves are done by having lower atker hitstop then defender hitstop, and high "hitcount" and ignore_time
		hitstop = hit_data.move_data.fixed_atker_hitstop
		
	elif hit_data.stun:
		if hitstop == null or hit_data.hitstop > hitstop:
			hitstop = CRUSH_HITSTOP_ATTACKER # fixed hitstop for attacking for Guardbreaks
			
	elif hit_data.lethal_hit:
		hitstop = null # no hitstop for attacker for lethal hit, screenfreeze already enough
		
	else:
		if hitstop == null or hit_data.hitstop > hitstop: # need to do this to set consistent hitstop during clashes
			hitstop = hit_data.hitstop


	# AUDIO ----------------------------------------------------------------------------------------------
		
	if "hit_sound" in hit_data.move_data:
		
		if !hit_data.move_data.hit_sound is Array:
			play_audio(hit_data.move_data.hit_sound.ref, hit_data.move_data.hit_sound.aux_data)
		else: # multiple sounds at once
			for sound in hit_data.move_data.hit_sound:
				play_audio(sound.ref, sound.aux_data)
	

# TAKING A HIT ---------------------------------------------------------------------------------------------- 	

func being_hit(hit_data): # called by main game node when taking a hit

	var attacker = get_node(hit_data.attacker_nodepath)
#	var defender = get_node(hit_data.defender_nodepath)
	
	var attacker_or_entity = attacker # cleaner code
	if "entity_nodepath" in hit_data:
		attacker_or_entity = get_node(hit_data.entity_nodepath)

	targeted_opponent_path = hit_data.attacker_nodepath # target opponent who last attacked you
	
	remove_status_effect(Globals.status_effect.STUN)
	$HitStopTimer.stop() # cancel pre-existing hitstop
	
	# get direction to attacker
	var vec_to_attacker: Vector2 = attacker_or_entity.position - position
	if vec_to_attacker.x == 0: # rare case of attacker directly on defender
		vec_to_attacker.x = -attacker.facing
	var dir_to_attacker := int(sign(vec_to_attacker.x)) # for setting facing on defender
		
	var attacker_vec := FVector.new()
	attacker_vec.set_from_vec(vec_to_attacker)
	
	hit_data["angle_to_atker"] = attacker_vec.angle()
	hit_data["lethal_hit"] = false
	hit_data["stun"] = false
	hit_data["repeat"] = false
	hit_data["double_repeat"] = false
	
	if !attacker_or_entity.is_hitcount_last_hit(mob_ID, hit_data.move_data):
		hit_data["multihit"] = true
	if Globals.atk_attr.AUTOCHAIN in hit_data.move_data.atk_attr:
		hit_data["autochain"] = true
	
	# some multi-hit moves only hit once every few frames, done via an ignore list on the attacker/entity
	if "multihit" in hit_data and "ignore_time" in hit_data.move_data:
		attacker_or_entity.append_ignore_list(mob_ID, hit_data.move_data.ignore_time)
	
	# REPEAT PENALTY AND WEAK HITS ----------------------------------------------------------------------------------------------
		
	var double_repeat := false
	var root_move_name # for move variations
	if !"entity_nodepath" in hit_data:
		root_move_name = attacker.UniqChar.get_root(hit_data.move_name)
	elif "root" in hit_data.move_data: # is entity, most has a root in move_data
		root_move_name = hit_data.move_data.root
	else:
		root_move_name = hit_data.move_name
	
	if !Globals.atk_attr.REPEATABLE in hit_data.move_data.atk_attr:
		for array in repeat_memory:
			if array[0] == attacker.mob_ID and array[1] == root_move_name:
				if !hit_data.repeat:
					hit_data.repeat = true # found a repeat
					if hit_data.move_data.atk_type in [Globals.atk_type.SPECIAL, Globals.atk_type.EX, Globals.atk_type.SUPER] or \
							Globals.atk_attr.NO_REPEAT_MOVE in hit_data.move_data.atk_attr:
						double_repeat = true # if attack is non-projectile non-normal or a no repeat move, can only repeat once
						hit_data["double_repeat"] = true
						break
				elif !double_repeat:
					double_repeat = true
					hit_data["double_repeat"] = true # found multiple repeats
					break
					
	# add to repeat memory
	if !double_repeat and !"multihit" in hit_data: # for multi-hit move, only the last hit add to repeat_memory
		repeat_memory.append([attacker.mob_ID, root_move_name])
	
	
	# WEAK HIT ----------------------------------------------------------------------------------------------
	
	# a Weak Hit is:
	#		one with atk_level of 1
	#		a move nerfed by Repeat Penalty
	#		a move that only hits the SDHurtbox of the target
	#		the non-final hit of a multi-hit move
	# Weak Hits cannot cause Lethal Hit, cannot cause Stun, cannot cause Sweetspotted Hits, cannot cause Punish Hits
	
	var weak_hit := false
	if ("atk_level" in hit_data and hit_data.move_data.atk_level <= 1) or hit_data.double_repeat or \
		"multihit" in hit_data:
		weak_hit = true
		hit_data.sweetspotted = false
		
	hit_data["weak_hit"] = weak_hit

		
	# ZEROTH REACTION (before damage) ---------------------------------------------------------------------------------
	
	if !guardbroken or Globals.trait.NO_LAUNCH in query_traits():
		hit_data["tough_mob"] = true # mobs are rarely vulnerable to hitgrabs and grabs
	
	# unique reactions
	if "entity_nodepath" in hit_data:
		if attacker_or_entity.UniqEntity.has_method("landed_a_hit0"):
			attacker_or_entity.UniqEntity.landed_a_hit0(hit_data) # reaction, can change hit_data from there
	elif attacker.UniqChar.has_method("landed_a_hit0"):
		attacker.UniqChar.landed_a_hit0(hit_data) # reaction, can change hit_data from there
	
	if UniqMob.has_method("being_hit0"):	
		UniqMob.being_hit0(hit_data) # reaction, can change hit_data from there
			
	# DAMAGE AND GUARD DRAIN/GAIN CALCULATION ------------------------------------------------------------------
	
	# attack level
	var adjusted_atk_level: int = 1
	
	if !"sequence" in hit_data.move_data:
		adjusted_atk_level = adjusted_atk_level(hit_data)
		hit_data["adjusted_atk_level"] = adjusted_atk_level
		
		if !guardbroken:
			change_guard_gauge(calculate_guard_gauge_change(hit_data)) # do GG calculation
			if get_guard_gauge_percent_below() == 0:
				hit_data.stun = true
		
		take_damage(calculate_damage(hit_data)) # do damage calculation
		if get_damage_percent() >= 100:
			hit_data.lethal = true
			

	# FIRST REACTION ---------------------------------------------------------------------------------
	
	# unique reactions
	if "entity_nodepath" in hit_data:
		if attacker_or_entity.UniqEntity.has_method("landed_a_hit"):
			attacker_or_entity.UniqEntity.landed_a_hit(hit_data) # reaction, can change hit_data from there
	elif attacker.UniqChar.has_method("landed_a_hit"):
		attacker.UniqChar.landed_a_hit(hit_data) # reaction, can change hit_data from there
	
	if UniqMob.has_method("being_hit"):	
		UniqMob.being_hit(hit_data) # reaction, can change hit_data from there
	
	# ---------------------------------------------------------------------------------
	
	if "sequence" in hit_data.move_data: # hitgrabs and sweetgrabs will add sequence to move_data on sweetspot/non double repeat
		if !hit_data.double_repeat and !"tough_mob" in hit_data:
			attacker_or_entity.landed_a_sequence(hit_data)
		return
		

	if !"entity_nodepath" in hit_data:
		Globals.Game.get_node("Players").move_child(attacker, 0) # move attacker to bottom layer to see defender easier
	

	# knockback
	var knockback_dir: int = calculate_knockback_dir(hit_data)
	hit_data["knockback_dir"] = knockback_dir
	var knockback_strength: int = calculate_knockback_strength(hit_data)
	hit_data["knockback_strength"] = knockback_strength
	

	# SPECIAL HIT EFFECTS ---------------------------------------------------------------------------------
	
	# for moves that automatically chain into more moves, will not cause lethal or break hits, will have fixed_hitstop and no KB boost

		
	if hit_data.double_repeat:
		$ModulatePlayer.play("repeat")
#		add_status_effect(Globals.status_effect.REPEAT, 10)
	
	elif hit_data.lethal_hit:
		Globals.Game.set_screenshake()
		play_audio("lethal1", {"vol" : -5, "bus" : "Reverb"})
		
	elif hit_data.stun:
		guardbroken = true
		add_status_effect(Globals.status_effect.CRUSH, 0)
		repeat_memory = [] # reset move memory for getting a Break
		$ModulatePlayer.play("stun_flash")
		play_audio("rock2", {"vol" : -5})
			
	elif hit_data.sweetspotted:
		$ModulatePlayer.play("sweet_flash")
		play_audio("break2", {"vol" : -15})
		
	if Globals.atk_attr.SCREEN_SHAKE in hit_data.move_data.atk_attr:
		Globals.Game.set_screenshake()
			
	
	# HITSTUN -------------------------------------------------------------------------------------------
	
	if hit_data.block_state == Globals.block_state.UNBLOCKED:
		if adjusted_atk_level <= 1 and $HitStunTimer.is_running(): # for atk level 1 hits on hitstunned opponent, add their hitstun to existing hitstun
			$HitStunTimer.time = $HitStunTimer.time + calculate_hitstun(hit_data)
		else:
			$HitStunTimer.time = calculate_hitstun(hit_data)
			launchstun_rotate = 0 # used to calculation sprite rotation during launched state
	
	# HITSTOP ---------------------------------------------------------------------------------------------------
	
	if !hit_data.lethal_hit:
		hitstop = calculate_hitstop(hit_data, knockback_strength)
	else:
		hitstop = LETHAL_HITSTOP # set for defender, attacker has no hitstop during LETHAL_HITSTOP
								# screenfreeze for everyone but the defender till their hitstop is over
		
	hit_data["hitstop"] = hitstop # send this to attacker as well

	if hit_data.stun:
		hitstop = CRUSH_TIME
		
	if hitstop > 0: # will freeze in place if colliding 1 frame after hitstop, more if has ignore_time, to make multi-hit projectiles more consistent
		if "multihit" in hit_data and "ignore_time" in hit_data.move_data:
			$NoCollideTimer.time = hit_data.move_data.ignore_time
		else:
			$NoCollideTimer.time = 1
		
#	# SECOND REACTION (after knockback) ---------------------------------------------------------------------------------

	if "entity_nodepath" in hit_data:
		if attacker_or_entity.UniqEntity.has_method("landed_a_hit2"):
			attacker_or_entity.UniqEntity.landed_a_hit2(hit_data) # reaction, can change hit_data from there
	elif attacker.UniqChar.has_method("landed_a_hit2"):
		attacker.UniqChar.landed_a_hit2(hit_data) # reaction, can change hit_data from there
	
	if UniqMob.has_method("being_hit2"):	
		UniqMob.being_hit2(hit_data) # reaction, can change hit_data from there
	
	# HITSPARK ---------------------------------------------------------------------------------------------------
	
	generate_hitspark(hit_data)

	if hit_data.stun: # stunspark is on top of regular hitspark
		Globals.Game.spawn_SFX("Crushspark", "Stunspark", hit_data.hit_center, {"facing":Globals.Game.rng_facing(), \
				"v_mirror":Globals.Game.rng_bool()})
	
	# ---------------------------------------------------------------------------------------------------
			
#	var knockback_unit_vec := Vector2(1, 0).rotated(knockback_dir)

	var no_impact_and_vel_change := false

	if guardbroken:
			
		# if knockback_strength is high enough, get launched, else get flinched
		if Globals.trait.NO_LAUNCH in query_traits() or knockback_strength < LAUNCH_THRESHOLD or adjusted_atk_level <= 1:

			var no_impact := false
			
			if adjusted_atk_level <= 1: # for attack level 1 attacks
				
				if $HitStunTimer.is_running(): # for hitstunned defender
					if state == Globals.char_state.LAUNCHED_HITSTUN:
						no_impact_and_vel_change = true
						# if defender is hit by atk level 1 attack while in launched state, no impact/velocity change (just added hitstun)
						# if they are flinched, will enter new flinch animation with added hitstun and has velocity change
						
				# for atk level 1 attack on non-passive state, just push them back, no turn
				# if is in passive state, will enter impact animation but 0 hitstun
				elif !state in [Globals.char_state.GROUND_STANDBY, Globals.char_state.GROUND_RECOVERY, \
					Globals.char_state.GROUND_C_RECOVERY, Globals.char_state.AIR_STANDBY, Globals.char_state.AIR_RECOVERY, \
					Globals.char_state.AIR_C_RECOVERY]:
					no_impact = true
						
			if !no_impact and !no_impact_and_vel_change:
				var segment = Globals.split_angle(knockback_dir, Globals.angle_split.TWO, -dir_to_attacker)
				if !"pull" in hit_data:
					match segment:
						Globals.compass.E:
							face(-1) # face other way
						Globals.compass.W:
							face(1)
				else: # flip facing direction if pulling attack on flinch
					match segment:
						Globals.compass.E:
							face(1)
						Globals.compass.W:
							face(-1)

				var alternate_flag := false # alternate hitstun for multi-hit flinch during hitstop
				if state == Globals.char_state.AIR_FLINCH_HITSTUN:
					if Animator.query_current(["aFlinchAStop"]):
						animate("aFlinchBStop")
						alternate_flag = true
					elif Animator.query_current(["aFlinchBStop"]):
						animate("aFlinchAStop")
						alternate_flag = true
				elif state == Globals.char_state.GROUND_FLINCH_HITSTUN:
					if Animator.query_current(["FlinchAStop"]):
						animate("FlinchBStop")
						alternate_flag = true
					elif Animator.query_current(["FlinchBStop"]):
						animate("FlinchAStop")
						alternate_flag = true
				
				if !alternate_flag:
					if hit_data.hit_center.y >= position.y: # A/B depending on height hit
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
			
			knockback_strength += LAUNCH_BOOST
			var segment = Globals.split_angle(knockback_dir, Globals.angle_split.EIGHT, dir_to_attacker)
			match segment:
				Globals.compass.N:
					face(dir_to_attacker) # turn towards attacker
					if facing == 1:
						launch_starting_rot = PI/2
					else:
						launch_starting_rot = 3*PI/2
				Globals.compass.NE:
					face(-1)
					launch_starting_rot = 7*PI/4
				Globals.compass.E:
					face(-1)
					launch_starting_rot = 0
				Globals.compass.SE:
					face(-1)
					launch_starting_rot = 9*PI/4
				Globals.compass.S:
					face(dir_to_attacker) # turn towards attacker
					if facing == -1:
						launch_starting_rot = PI/2
					else:
						launch_starting_rot = 3*PI/2
				Globals.compass.SW:
					face(1)
					launch_starting_rot = 7*PI/4
				Globals.compass.W:
					face(1)
					launch_starting_rot = 0.0
				Globals.compass.NW:
					face(1)
					launch_starting_rot = PI/4
			animate("LaunchStop")
							
					
	if !no_impact_and_vel_change:
		velocity.set_vector(knockback_strength, 0)  # reset momentum
		velocity.rotate(knockback_dir)
		
		if !guardbroken and grounded:
			velocity.y = 0 # set to horizontal pushback on non-guardbroken defender

		
# HIT CALCULATION ---------------------------------------------------------------------------------------------------
		
func calculate_damage(hit_data) -> int:
	
	var scaled_damage: int = hit_data.move_data.damage * FMath.S
	if scaled_damage == 0: return 0
	
	if hit_data.double_repeat:
		scaled_damage = FMath.percent(scaled_damage, REPEAT_DMG_MOD)
	else:
		if hit_data.sweetspotted:
			scaled_damage = FMath.percent(scaled_damage, SWEETSPOT_DMG_MOD)

	return int(max(FMath.round_and_descale(scaled_damage), 1)) # minimum 1 damage
	

func calculate_guard_gauge_change(hit_data) -> int:
	
	if "multihit" in hit_data or "autochain" in hit_data:  # for multi-hit/autochain moves, only last hit affect GG
		return 0

	if guardbroken: # if guardbroken, no Guard Drain
		return 0
		
	return -ATK_LEVEL_TO_GDRAIN[hit_data.adjusted_atk_level - 1] # Guard Drain on 1st hit of the combo depends on Attack Level

	
	
func calculate_knockback_strength(hit_data) -> int:

	var knockback_strength: int = hit_data.move_data.knockback # scaled by FMath.S
	
	if Globals.atk_attr.FIXED_KNOCKBACK_STR in hit_data.move_data.atk_attr:
		return knockback_strength
	
	# for certain multi-hit attacks (not autochain), can be fixed KB till the last hit
	if "multihit" in hit_data:
		if "fixed_knockback_multi" in hit_data.move_data:
			knockback_strength = hit_data.move_data.fixed_knockback_multi # scaled by FMath.S
	
	if hit_data.sweetspotted:
		knockback_strength = FMath.percent(knockback_strength, SWEETSPOT_KB_MOD)
		
	if !guardbroken:
		knockback_strength = FMath.percent(knockback_strength, GUARDED_KNOCKBACK_MOD) # KB for non-guardbreal

	# for rekkas and combo-type moves/supers, no KB boost for non-finishers
	if "autochain" in hit_data or "multihit" in hit_data:
		return knockback_strength

	if guardbroken and !hit_data.weak_hit:  # no GG KB boost for multi-hit attacks (weak hits) till the last hit
		knockback_strength = FMath.f_lerp(knockback_strength, FMath.percent(knockback_strength, UniqMob.get_stat("KB_BOOST_AT_MAX_GG")), \
				get_guard_gauge_percent_below())

	if "MOB_WEIGHT_KB_MOD" in UniqMob: # mobs can have different weights
		knockback_strength = FMath.percent(knockback_strength, UniqMob.get_stat("MOB_WEIGHT_KB_MOD"))
	
	return knockback_strength
	
	
func calculate_knockback_dir(hit_data) -> int:
	
	var attacker = get_node(hit_data.attacker_nodepath)

	var attacker_or_entity = attacker # cleaner code
	if "entity_nodepath" in hit_data:
		attacker_or_entity = get_node(hit_data.entity_nodepath)
#
	
	var knockback_dir := 0
	var knockback_type = hit_data.move_data.knockback_type
	
	# for certain multi-hit attacks and autochain
	if "multihit" in hit_data or "autochain" in hit_data:
		
		if Globals.atk_attr.DRAG_KB in hit_data.move_data.atk_attr: # can be drag KB till the last hit
			return attacker_or_entity.velocity.angle()
			
		elif "vacpoint" in hit_data: # or vacuum towards VacPoint
			var vac_vector := FVector.new()
			vac_vector.set_from_vec(hit_data.vacpoint - hit_data.hit_center)
			return vac_vector.angle()
			
		elif "fixed_knockback_dir_multi" in hit_data.move_data: # or fixed angle till the last hit
			knockback_dir = hit_data.move_data.fixed_knockback_dir_multi
			if hit_data.attack_facing < 0:
				knockback_dir = posmod(180 - knockback_dir, 360) # mirror knockback angle horizontally if facing other way
			return knockback_dir
			
				
	var KBOrigin = null
	if "kborigin" in hit_data:
		KBOrigin = hit_data.kborigin # becomes a Vector2
		
	var ref_vector := FVector.new() # vector from KBOrigin to hit_center
	if KBOrigin:
		ref_vector.set_from_vec(hit_data.hit_center - KBOrigin)
	else:
		ref_vector.set_from_vec(hit_data.hit_center - attacker_or_entity.position)
		
	if ref_vector.x <= FMath.S and ref_vector.x >= -FMath.S:
		ref_vector.x = 0 # reduce rounding errors when calculating hit center
	
	match knockback_type:
		Globals.knockback_type.FIXED, Globals.knockback_type.MIRRORED:

			if hit_data.attack_facing > 0:
				knockback_dir = posmod(hit_data.move_data.KB_angle, 360)
			else:
				knockback_dir = posmod(180 - hit_data.move_data.KB_angle, 360) # mirror knockback angle horizontally if facing other way
				
			if knockback_type == Globals.knockback_type.MIRRORED: # mirror it again if wrong way
#				if KBOrigin:
				var segment = Globals.split_angle(knockback_dir, Globals.angle_split.TWO, hit_data.attack_facing)
				match segment:
					Globals.compass.E:
						if ref_vector.x < 0:
							knockback_dir = posmod(180 - knockback_dir, 360)
					Globals.compass.W:
						if ref_vector.x > 0:
							knockback_dir = posmod(180 - knockback_dir, 360)
#				else: print("Error: No KBOrigin found for knockback_type.MIRRORED")
				
		Globals.knockback_type.RADIAL:
#			if KBOrigin:
			knockback_dir = ref_vector.angle(hit_data.attack_facing)
			if hit_data.attack_facing > 0:
				knockback_dir += hit_data.move_data.KB_angle # KB_angle can rotate radial knockback some more
			else:
				knockback_dir -= hit_data.move_data.KB_angle
			knockback_dir = posmod(knockback_dir, 360)
#			else: print("Error: No KBOrigin found for knockback_type.RADIAL")
			
	# for weak hit/non-guardbroken and grounded mob, if the hit is towards left/right instead of up/down, level it
	if grounded and (!guardbroken or hit_data.weak_hit or hit_data.adjusted_atk_level <= 1):
		var segment = Globals.split_angle(knockback_dir, Globals.angle_split.FOUR, hit_data.attack_facing)
		match segment:
			Globals.compass.E:
				knockback_dir = 0
			Globals.compass.W:
				knockback_dir = 180
				
	return knockback_dir


func adjusted_atk_level(hit_data) -> int: # mostly for hitstun
	# atk_level = 1 are weak hits and cannot do a lot of stuff, cannot cause hitstun

	if hit_data.double_repeat:
		return 1 # double repeat is forced attack level 1
	
	var atk_level: int = hit_data.move_data.atk_level
	if hit_data.sweetspotted: # sweetspotted give more hitstun
		atk_level += 2
		atk_level = int(clamp(atk_level, 1, 8))
		
	return atk_level
	
	
func calculate_hitstun(hit_data) -> int: # hitstun determined by attack level and defender's Guard Gauge
	
	if "fixed_hitstun" in hit_data.move_data and !hit_data.double_repeat:
		return hit_data.move_data.fixed_hitstun
		
	if hit_data.adjusted_atk_level <= 1 and !is_hitstunned():
		return 0 # weak hit on opponent not in hitstun
		
	if hit_data.double_repeat:
		return 0

	var scaled_hitstun := 0
	if Globals.trait.NO_LAUNCH in query_traits() or hit_data.knockback_strength < LAUNCH_THRESHOLD:
		scaled_hitstun = ATK_LEVEL_TO_F_HITSTUN[hit_data.adjusted_atk_level - 1] * FMath.S
	else:
		scaled_hitstun = ATK_LEVEL_TO_L_HITSTUN[hit_data.adjusted_atk_level - 1] * FMath.S
		
	if guardbroken:
		scaled_hitstun = FMath.f_lerp(scaled_hitstun, FMath.percent(scaled_hitstun, HITSTUN_REDUCTION_AT_MAX_GG), \
			get_guard_gauge_percent_below())

	return FMath.round_and_descale(scaled_hitstun)


func calculate_hitstop(hit_data, knockback_strength: int) -> int: # hitstop determined by knockback power
		
	if !guardbroken:
		if hit_data.sweetspotted:
			if "fixed_ss_hitstop" in hit_data.move_data:
				return hit_data.move_data.fixed_ss_hitstop # for Normal hitpulls
			else:
				return 10
		else:
			return 5

	# some moves have predetermined hitstop
	if "fixed_hitstop" in hit_data.move_data:
		return hit_data.move_data.fixed_hitstop
	
# warning-ignore:integer_division
	var hitstop_temp: int = 2 * FMath.S + int(knockback_strength / 100) # scaled, +1 frame of hitstop for each 100 scaled knockback
	
	if hit_data.sweetspotted: # sweetspotted hits has 30% more hitstop
		if "fixed_ss_hitstop" in hit_data.move_data:
			return hit_data.move_data.fixed_ss_hitstop # for Normal hitpulls
		hitstop_temp = FMath.percent(hitstop_temp, SWEETSPOT_HITSTOP_MOD)
		
	hitstop_temp = FMath.round_and_descale(hitstop_temp) # descale it
	hitstop_temp = int(clamp(hitstop_temp, MIN_HITSTOP, MAX_HITSTOP)) # max hitstop is 13, min hitstop is 5
			
#	print(hitstop_temp)
	return hitstop_temp
	

func generate_hitspark(hit_data): # hitspark size determined by knockback power
	

	var hitspark_level: int
	
	if hit_data.adjusted_atk_level <= 1:
		hitspark_level = 0
	elif "burst" in hit_data.move_data:
		hitspark_level = 5
	elif hit_data.stun:
		hitspark_level = 5 # max size for Break
	else:
		if hit_data.knockback_strength <= FMath.percent(LAUNCH_THRESHOLD, 40):
			hitspark_level = 1
		elif hit_data.knockback_strength < LAUNCH_THRESHOLD:
			hitspark_level = 2
		elif hit_data.knockback_strength <= FMath.percent(LAUNCH_THRESHOLD, 170):
			hitspark_level = 3
		elif hit_data.knockback_strength <= FMath.percent(LAUNCH_THRESHOLD, 200):
			hitspark_level = 4
		else:
			hitspark_level = 5
		
		if hit_data.sweetspotted: # if sweetspotted, hitspark level increased by 1
			hitspark_level = int(clamp(hitspark_level + 1, 1, 5)) # max is 5
		
	var hitspark = ""
		
	match hit_data.move_data.hitspark_type:
		Globals.hitspark_type.HIT:
			match hitspark_level:
				0:
					hitspark = "HitsparkA"
				1, 2:
					hitspark = "HitsparkB"
				3, 4:
					hitspark = "HitsparkC"
				5:
					hitspark = "HitsparkD"
		Globals.hitspark_type.SLASH:
			match hitspark_level:
				0:
					hitspark = "SlashsparkA"
				1, 2:
					hitspark = "SlashsparkB"
				3, 4:
					hitspark = "SlashsparkC"
				5:
					hitspark = "SlashsparkD"
		Globals.hitspark_type.CUSTOM:
			# WIP
			pass
					
	if hitspark != "":
		var rot_rad : float = hit_data.knockback_dir / 360.0 * (2 * PI) + PI # visuals only
		if "pull" in hit_data: rot_rad += PI # flip if pulling
		var aux_data = {"rot": rot_rad, "v_mirror":Globals.Game.rng_bool()}
		if hit_data.move_data["hitspark_palette"] != "red":
			aux_data["palette"] = hit_data.move_data["hitspark_palette"]
		Globals.Game.spawn_SFX(hitspark, hitspark, hit_data.hit_center, aux_data)
		
	
	
# AUTO SEQUENCES ---------------------------------------------------------------------------------------------------

func simulate_sequence(): # cut into this during simulate2() during sequences
	
	if state == Globals.char_state.SEQUENCE_TARGET: # being the target of an opponent's sequence will be moved around by them
		if get_node(targeted_opponent_path).state != Globals.char_state.SEQUENCE_USER:
			animate("Idle") # auto release if not released proberly, just in case
		
	elif state == Globals.char_state.SEQUENCE_USER: # using a sequence, will follow the steps in UniqMob.SEQUENCES[sequence_name]
		UniqMob.simulate_sequence()
		
		
	if abs(velocity.x) < 5 * FMath.S:
		velocity.x = 0
	if abs(velocity.y) < 5 * FMath.S:
		velocity.y = 0
	
	velocity_previous_frame.x = velocity.x
	velocity_previous_frame.y = velocity.y
	
	var results = move($PlayerCollisionBox, $SoftPlatformDBox, UniqMob.sequence_ledgestop()) # [landing_check, collision_check, ledgedrop_check]
#	velocity.x = results[0].x
#	velocity.y = results[0].y
	
	if state == Globals.char_state.SEQUENCE_USER:
		UniqMob.simulate_sequence_after() # move grabbed target after grabber has moved
	
	if results[0]: UniqMob.end_sequence_step("ground") # hit the ground, no effect if simulate_sequence_after() broke grab and animated "Idle"
	
		
func landed_a_sequence(hit_data):

	var defender = get_node(hit_data.defender_nodepath)
	
	animate(hit_data.move_data.sequence)
	UniqMob.start_sequence_step()
	
	defender.status_effect_to_remove.append(Globals.status_effect.POS_FLOW)	# defender lose positive flow

	
func take_seq_damage(base_damage: int) -> bool: # return true if lethal

	var scaled_damage: int = base_damage * FMath.S
	if scaled_damage == 0: return false
	
	var damage: int = int(max(FMath.round_and_descale(scaled_damage), 1)) # minimum damage is 1
	
	take_damage(damage)
	if get_damage_percent() >= 100:
		return true # return true if lethal
	return false
	
	
func sequence_hit(hit_key: int): # most auto sequences deal damage during the sequence outside of the launch
	var seq_user = get_node(targeted_opponent_path)
	var seq_hit_data = seq_user.UniqMob.MOVE_DATABASE[seq_user.Animator.to_play_animation].sequence_hits[hit_key]
	var lethal = take_seq_damage(seq_hit_data.damage)
	
	if "hitstop" in seq_hit_data and !"weak" in seq_hit_data: # if weak, no lethal effect, place it for non-final hits
		if lethal:
			hitstop = LETHAL_HITSTOP
			Globals.Game.set_screenshake()
			play_audio("lethal1", {"vol" : -5, "bus" : "Reverb"})
		else:
			hitstop = seq_hit_data.hitstop
			seq_user.hitstop = hitstop


func sequence_launch():
	var seq_user = get_node(targeted_opponent_path)
	var dir_to_attacker = sign(position.x - seq_user.position.x)
	if dir_to_attacker == 0: dir_to_attacker = facing
	
	if !seq_user.Animator.to_play_animation in seq_user.UniqMob.MOVE_DATABASE:
		print("Error: " + Animator.to_play_animation + " auto-sequence not found in database.")
	var seq_data = seq_user.UniqMob.MOVE_DATABASE[seq_user.Animator.to_play_animation].sequence_launch
	
#		"sequence_launch" : { # for final hit of sequence
#			"damage" : 0,
#			"hitstop" : 0,
#			"guard_gain" : 3500,
#			"launch_power" : 700 * FMath.S,
#			"launch_angle" : -82,
#			"atk_level" : 6,
#		}

	# DAMAGE
	var damage = seq_data.damage
	var lethal = take_seq_damage(damage)
	if damage > 0 and seq_data.hitstop > 0: # launch is a hit (rare)
		if lethal and !"weak" in seq_data:
			hitstop = LETHAL_HITSTOP
			Globals.Game.set_screenshake()
			play_audio("lethal1", {"vol" : -5, "bus" : "Reverb"})
		else:
			hitstop = seq_data.hitstop
			seq_user.hitstop = hitstop
		
#	sequence can only be done on guardbroken enemies, thus no guard drain!
#	if !guardbroken and !"weak" in seq_data:
#		var guard_drain = -ATK_LEVEL_TO_GDRAIN[seq_data.atk_level - 1]
#		change_guard_gauge(guard_drain)
		
	# HITSTUN
	var hitstun: int
	if "fixed_hitstun" in seq_data:
		hitstun = seq_data.fixed_hitstun
	else:
		var scaled_hitstun: int = ATK_LEVEL_TO_L_HITSTUN[seq_data.atk_level - 1] * FMath.S
		hitstun = FMath.round_and_descale(scaled_hitstun)
	$HitStunTimer.time = hitstun
	launchstun_rotate = 0 # used to calculation sprite rotation during launched state
		
	# LAUNCH POWER
	var launch_power = seq_data.launch_power # scaled
	launch_power = FMath.f_lerp(launch_power, FMath.percent(launch_power, UniqMob.get_stat("KB_BOOST_AT_MAX_GG")), \
			get_guard_gauge_percent_below())
		
	# LAUNCH ANGLE
	var launch_angle: int
	if seq_user.facing > 0:
		launch_angle = posmod(seq_data.launch_angle, 360)
	else:
		launch_angle = posmod(180 - seq_data.launch_angle, 360) # if mirrored
		
	# LAUNCHING
	sprite.rotation = 0
	var segment = Globals.split_angle(launch_angle, Globals.angle_split.EIGHT, dir_to_attacker)
	match segment:
		Globals.compass.N:
			face(-dir_to_attacker) # turn towards attacker
			if facing == 1:
				launch_starting_rot = PI/2
			else:
				launch_starting_rot = 3*PI/2
		Globals.compass.NE:
			face(-1)
			launch_starting_rot = 7*PI/4
		Globals.compass.E:
			face(-1)
			launch_starting_rot = 0
		Globals.compass.SE:
			face(-1)
			launch_starting_rot = 9*PI/4
		Globals.compass.S:
			face(-dir_to_attacker) # turn towards attacker
			if facing == -1:
				launch_starting_rot = PI/2
			else:
				launch_starting_rot = 3*PI/2
		Globals.compass.SW:
			face(1)
			launch_starting_rot = 7*PI/4
		Globals.compass.W:
			face(1)
			launch_starting_rot = 0.0
		Globals.compass.NW:
			face(1)
			launch_starting_rot = PI/4
			
	if !Globals.trait.NO_LAUNCH in query_traits():
		animate("LaunchStop")
	else:
		animate("aFlinchAStop") # error, just in case, mobs with NO_LAUNCH are not supposed to be vulnerable to sequence and has no LaunchStop
	
	velocity.set_vector(launch_power, 0)  # reset momentum
	velocity.rotate(launch_angle)
	
		
# ANIMATION AND AUDIO PROCESSING ---------------------------------------------------------------------------------------------------
	
# universal actions
func _on_SpritePlayer_anim_finished(anim_name):
	
	match anim_name:
		"RunTransit":
			animate("Run")
		"Landing", "Brake":
			animate("Idle")
			
		"FallTransit":
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

	UniqMob._on_SpritePlayer_anim_finished(anim_name)


func _on_SpritePlayer_anim_started(anim_name):
	
	state = state_detect(Animator.current_animation) # update state
	
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
		"Landing":
			Globals.Game.spawn_SFX("LandDust", "DustClouds", get_feet_pos(), {"facing":facing, "grounded":true})

	UniqMob._on_SpritePlayer_anim_started(anim_name)
	
	
func _on_SpritePlayer_frame_update(): # emitted after every frame update, useful for staggering audio
	UniqMob.stagger_anim()

# return modulate to normal after ModulatePlayer finishes playing
# may do follow-up modulate animation
func _on_ModulatePlayer_anim_finished(anim_name):
	if LoadedSFX.modulate_animations[anim_name].has("followup"):
		$ModulatePlayer.play(LoadedSFX.modulate_animations[anim_name]["followup"])
	else:
		reset_modulate()
	
func _on_ModulatePlayer_anim_started(anim_name):
	if LoadedSFX.modulate_animations[anim_name].has("monochrome"):
		set_monochrome()
	
func _on_FadePlayer_anim_finished(anim_name):
	if LoadedSFX.fade_animations[anim_name].has("followup"):
		$FadePlayer.play(LoadedSFX.fade_animations[anim_name]["followup"])
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
		
func reset_modulate():
	palette()
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
	
	if !audio_ref in LoadedSFX.loaded_audio: # custom audio, have the audioplayer search this node's unique_audio dictionary
		aux_data["unique_path"] = get_path() # add a new key to aux_data
		
	Globals.Game.play_audio(audio_ref, aux_data)

		

# triggered by SpritePlayer at start of each animation
func _on_change_spritesheet(spritesheet_filename):
	sprite.texture = spritesheets[spritesheet_filename]
	sprite_texture_ref.sprite = spritesheet_filename
	
func _on_change_SfxOver_spritesheet(SfxOver_spritesheet_filename):
	sfx_over.show()
	sfx_over.texture = spritesheets[SfxOver_spritesheet_filename]
	sprite_texture_ref.sfx_over = SfxOver_spritesheet_filename
	
func hide_SfxOver():
	sfx_over.hide()
	
func _on_change_SfxUnder_spritesheet(SfxUnder_spritesheet_filename):
	sfx_under.show()
	sfx_under.texture = spritesheets[SfxUnder_spritesheet_filename]
	sprite_texture_ref.sfx_under = SfxUnder_spritesheet_filename
	
func hide_SfxUnder():
	sfx_under.hide()


# SAVE/LOAD STATE --------------------------------------------------------------------------------------------------

func save_state():
	var state_data = {
			
		"position" : position,
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
		"afterimage_timer" : afterimage_timer,
		"launch_starting_rot" : launch_starting_rot,
		"launchstun_rotate" : launchstun_rotate,
		"targeted_opponent_path" : targeted_opponent_path,
		
		"sprite_texture_ref" : sprite_texture_ref,
		
		"current_damage_value" : current_damage_value,
		"current_guard_gauge" : current_guard_gauge,
		
		"unique_data" : unique_data,
		"repeat_memory" : repeat_memory,
		"status_effects" : status_effects,
		"hitcount_record" : hitcount_record,
		"ignore_list" : ignore_list,
		
		"sprite_scale" : sprite.scale,
		"sprite_rotation" : sprite.rotation,
		"sfx_over_visible" : sfx_over.visible,
		"sfx_under_visible" : sfx_under.visible,
		"Sprites_visible" : $Sprites.visible,

		"SpritePlayer_data" : $SpritePlayer.save_state(),
		"ModulatePlayer_data" : $ModulatePlayer.save_state(),
		"FadePlayer_data" : $FadePlayer.save_state(),
		
		"HitStunTimer_time" : $HitStunTimer.time,
		"HitStopTimer_time" : $HitStopTimer.time,
		"NoCollideTimer_time" : $NoCollideTimer.time,
		
		"current_command" : current_command,
		"command_timer" : command_timer,
		"guardbroken" : guardbroken,
		
	}

	return state_data
	
func load_state(state_data):
	
	position = state_data.position
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
	afterimage_timer = state_data.afterimage_timer
	launch_starting_rot = state_data.launch_starting_rot
	launchstun_rotate = state_data.launchstun_rotate
	targeted_opponent_path = state_data.targeted_opponent_path
	
	sprite_texture_ref = state_data.sprite_texture_ref
	
	current_damage_value = state_data.current_damage_value
	current_guard_gauge = state_data.current_guard_gauge
#	Globals.Game.damage_update(self)
#	Globals.Game.guard_gauge_update(self)
	
	unique_data = state_data.unique_data
#	if UniqMob.has_method("update_uniqueHUD"): UniqMob.update_uniqueHUD()
	repeat_memory = state_data.repeat_memory
	remove_all_status_effects()
	status_effects = state_data.status_effects
	load_status_effects()
	hitcount_record = state_data.hitcount_record
	ignore_list = state_data.ignore_list
		
	sprite.scale = state_data.sprite_scale
	sprite.rotation = state_data.sprite_rotation
	sfx_over.visible = state_data.sfx_over_visible
	sfx_under.visible = state_data.sfx_under_visible
	$Sprites.visible = state_data.Sprites_visible
	
	$SpritePlayer.load_state(state_data.SpritePlayer_data)
	reset_modulate()
	$ModulatePlayer.load_state(state_data.ModulatePlayer_data)
	if $ModulatePlayer.current_animation in LoadedSFX.modulate_animations and \
			LoadedSFX.modulate_animations[$ModulatePlayer.current_animation].has("monochrome"): set_monochrome()
	reset_fade()
	$FadePlayer.load_state(state_data.FadePlayer_data)
#	palette()
	
	$HitStunTimer.time = state_data.HitStunTimer_time
	$HitStopTimer.time = state_data.HitStopTimer_time
	$NoCollideTimer.time = state_data.NoCollideTimer_time

	current_command = state_data.current_command
	command_timer = state_data.command_timer
	guardbroken = state_data.guardbroken

	
#--------------------------------------------------------------------------------------------------


