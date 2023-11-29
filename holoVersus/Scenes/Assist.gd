extends "res://Scenes/Physics/Physics.gd"


# constants
const GRAVITY = 70 * FMath.S # per frame
const PEAK_DAMPER_MOD = 60 # used to reduce gravity at jump peak
const PEAK_DAMPER_LIMIT = 400 * FMath.S # min velocity.y where jump peak gravity reduction kicks in
const TERMINAL_THRESHOLD = 150 # if velocity.y is over this during hitstun, no terminal velocity slowdown

const HITSTUN_TERMINAL_VELOCITY_MOD = 650 # multiply to GRAVITY to get terminal velocity during hitstun

const HITSTUN_GRAV_MOD = 65  # gravity multiplier during hitstun
const HITSTUN_FRICTION = 15  # friction during hitstun
const HITSTUN_AIR_RES = 3 # air resistance during hitstun

const CROSS_UP_MIN_DIST = 10 # characters must be at least a certain number of pixels away horizontally to count as a cross-up

const STUN_HITSTOP_ATTACKER = 15 # hitstop for attacker when causing Stun

const NPC_KB_STR = 1000 * FMath.S # knockback strength is fixed
const NPC_HITSTOP = 10 # fixed hitstop, for NPC defender only, attacker take no hitstop
const NPC_BLOCK_HITSTOP = 5

const LAUNCH_ROT_SPEED = 5*PI # speed of sprite rotation when launched, don't need fixed-point as sprite rotation is only visuals
const TECHLAND_THRESHOLD = 300 * FMath.S # max velocity when hitting the ground to tech land

const WALL_SLAM_THRESHOLD = 100 * FMath.S # min velocity towards surface needed to do release BounceDust when bouncing

const BLACK_REPLACER = 0.8 # for black_replace shader

# variables used, don't touch these
#var loaded_palette = null
onready var Animator = $SpritePlayer # clean code
onready var sprite = $Sprites/Sprite # clean code
onready var sfx_under = $Sprites/SfxUnder # clean code
onready var sfx_over = $Sprites/SfxOver # clean code
var UniqNPC # unique character node

var master_node

var floor_level

var grounded := true
var soft_grounded := false
var hitstop = null # holder to inflict hitstop at end of frame


# character state, save these when saving and loading along with position, sprite frame and animation progress

var free := false
var NPC_ID: int # based on Globals.Game.entity_ID_ref
var master_ID : int # player_ID of owner

var palette_ref
var NPC_ref : String

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
#var afterimage_timer := 0 # for use by unique character node
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

var autochain_landed := false # set to true after any autochain hit, no more RES drain if true

var seq_partner_ID = null # not always target_ID during Survival Mode

var slowed := 0
var gravity_frame_mod := 100 # modify gravity this frame


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

	palette() # set up palette
	sfx_under.hide()
	sfx_over.hide()
	
	floor_level = Globals.Game.middle_point.y # get floor level of stage
	
	
# this is run after adding this node to the tree and not when loading state
func init(in_master_ID, in_NPC_ref, start_position, start_facing, in_palette_ref, atk_ID: = 0):
	
	NPC_ID = Globals.Game.entity_ID_ref
	Globals.Game.entity_ID_ref += 1
	
	master_ID = in_master_ID
	palette_ref = in_palette_ref
	NPC_ref = in_NPC_ref
	
	load_NPC()


	# incoming start position points at the floor
	start_position.y -= $PlayerCollisionBox.rect_position.y + $PlayerCollisionBox.rect_size.y
	
	position = start_position
	set_true_position()

	if facing != start_facing:
		face(start_facing)


	var soft_dbox = get_soft_dbox(get_collision_box())
	if is_on_ground(soft_dbox):
		grounded = true
	else:
		grounded = false
	UniqNPC.start_attack(atk_ID)
	

	unique_data = UniqNPC.UNIQUE_DATA_REF.duplicate(true)
	
	
func set_master_id(in_master_ID):
	master_ID = in_master_ID
	master_node = Globals.Game.get_player_node(master_ID)
	

func setup_boxes(ref_rect): # set up detection boxes
	$PlayerCollisionBox.rect_position = ref_rect.rect_position
	$PlayerCollisionBox.rect_size = ref_rect.rect_size
	$PlayerCollisionBox.add_to_group("NPCBoxes")
	$PlayerCollisionBox.add_to_group("Grounded")


# change palette and reset monochrome
func palette():
	
	monochrome = false
	
	if palette_ref is String and palette_ref == "black_replace":
		var replace = null
		match master_ID:
			0:
				replace = Color(BLACK_REPLACER, 0.0, 0.0)
			1:
				replace = Color(0.0, 0.0, BLACK_REPLACER)

		if replace != null:
			sprite.material = ShaderMaterial.new()
			sprite.material.shader = Loader.black_replace_shader
			sprite.material.set_shader_param("replace_r", replace.r)
			sprite.material.set_shader_param("replace_g", replace.g)
			sprite.material.set_shader_param("replace_b", replace.b)
	
	elif palette_ref in Loader.NPC_data[NPC_ref].palettes:
		sprite.material = ShaderMaterial.new()
		sprite.material.shader = Loader.loaded_palette_shader
		sprite.material.set_shader_param("swap", Loader.NPC_data[NPC_ref].palettes[palette_ref])
		sfx_over.material = ShaderMaterial.new()
		sfx_over.material.shader = Loader.loaded_palette_shader
		sfx_over.material.set_shader_param("swap", Loader.NPC_data[NPC_ref].palettes[palette_ref])
		sfx_under.material = ShaderMaterial.new()
		sfx_under.material.shader = Loader.loaded_palette_shader
		sfx_under.material.set_shader_param("swap", Loader.NPC_data[NPC_ref].palettes[palette_ref])
		
		
func unsummon(assist_attacked := false):
	free = true
	if UniqNPC.has_method("unsummon"):
		UniqNPC.unsummon(assist_attacked)
	
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
	$TestNode2D/TestLabel.text = ""
			
func test2():
	if Globals.debug_mode2:
		$TestNode2D/TestLabel.text = $TestNode2D/TestLabel.text + "new state: " + Globals.char_state_to_string(state) + \
			"\n" + Animator.current_anim + " > " + Animator.to_play_anim + "  time: " + str(Animator.time) + \
			"\n" + str(velocity.y) + "  grounded: " + str(grounded)
	else:
		$TestNode2D/TestLabel.text = ""
			
func _process(_delta):

	if master_node.test:
		if Globals.debug_mode2:
			$TestNode2D.show()
		else:
			$TestNode2D.hide()
			
			
func simulate():


# SET NON-SAVEABLE DATA --------------------------------------------------------------------------------------------------
# reset even on hitstop and respawning
# variables that are reseted right before being used don't need to be reset here
	
	hitstop = null

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
		return
	
	$HitStopTimer.simulate() # advancing the hitstop timer at start of frame allow for one frame of knockback before hitstop
	# will be needed for multi-hit moves
	
	if !$HitStopTimer.is_running():
		simulate2()


func simulate2(): # only ran if not in hitstop
	
# START OF FRAME --------------------------------------------------------------------------------------------------

	ignore_list_progress_timer()
		
	if !new_state in [Em.char_state.SEQ_TARGET, Em.char_state.SEQ_USER]:
		seq_partner_ID = null
		
		
	if !is_attacking():
		hitcount_record = []
		ignore_list = []
		
	elif is_atk_active():
		var refined_move = UniqNPC.refine_move_name(get_move_name())
		if Em.move.MULTI_HIT_REFRESH in UniqNPC.MOVE_DATABASE[refined_move]:
			if Animator.time in UniqNPC.MOVE_DATABASE[refined_move][Em.move.MULTI_HIT_REFRESH]:
				ignore_list = []
				
		
	if new_state in [Em.char_state.SEQ_USER, Em.char_state.SEQ_TARGET]:
		simulate_sequence()
		return
		
# CHECK DROPS AND LANDING ---------------------------------------------------------------------------------------------------

	if !grounded:
		match new_state:
			Em.char_state.GRD_STANDBY, Em.char_state.GRD_ATK_STARTUP, Em.char_state.GRD_ATK_ACTIVE, Em.char_state.GRD_ATK_REC:
				unsummon()
				
	elif velocity.y >= 0: # just in case, normally called when physics.gd runs into a floor
		match new_state:
			Em.char_state.LAUNCHED_HITSTUN:
				check_landing()

				
# GRAVITY --------------------------------------------------------------------------------------------------

	var gravity_temp: int
	
	if is_hitstunned(): # fix and lower gravity during hitstun
		gravity_temp = FMath.percent(GRAVITY, HITSTUN_GRAV_MOD)
	else:
		gravity_temp = FMath.percent(GRAVITY, get_stat("GRAVITY_MOD")) # each character are affected by gravity differently out of hitstun
	

	if anim_gravity_mod != 100:
		gravity_temp = FMath.percent(GRAVITY, anim_gravity_mod) # anim_gravity_mod is based off current animation
		
	if gravity_frame_mod != 100: # for temp gravity changes
		gravity_temp = FMath.percent(GRAVITY, gravity_frame_mod)
		gravity_frame_mod = 100

	if !grounded and (abs(velocity.y) < PEAK_DAMPER_LIMIT): # reduce gravity at peak of jump
# warning-ignore:narrowing_conversion
		var weight: int = FMath.get_fraction_percent(PEAK_DAMPER_LIMIT - abs(velocity.y), PEAK_DAMPER_LIMIT)
		gravity_temp = FMath.f_lerp(gravity_temp, FMath.percent(gravity_temp, PEAK_DAMPER_MOD), weight)

	if !grounded: # gravity only pulls you if you are in the air
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
		
			if velocity.y > terminal:
				velocity.y = FMath.f_lerp(velocity.y, terminal, 75)
		

# FRICTION/AIR RESISTANCE AND TRIGGERED ANIMATION CHANGES ----------------------------------------------------------
	# place this at end of frame later
	# for triggered animation changes, use query_to_play() instead
	# query() check animation at either start/end of frame, query_to_play() only check final animation
	
	var friction_this_frame: int # 15
	var air_res_this_frame: int
		
	if is_hitstunned():
		friction_this_frame = HITSTUN_FRICTION # 15
		air_res_this_frame = HITSTUN_AIR_RES # 3
	else:
		friction_this_frame = get_stat("FRICTION")
		air_res_this_frame = get_stat("AIR_RESISTANCE")
	
	match state:

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
	
# --------------------------------------------------------------------------------------------------

	UniqNPC.simulate() # some holdable buttons can have effect unique to the character
	
	test0()
	

# --------------------------------------------------------------------------------------------------

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
				
				if new_state == Em.char_state.LAUNCHED_HITSTUN:
					bounce(results[0])


func simulate_after(): # called by game scene after hit detection to finish up the frame
	
	test1()
	
	if Globals.Game.is_stage_paused():
		hitstop = null
		return
	if slowed != 0 and (slowed < 0 or posmod(Globals.Game.frametime, slowed) != 0):
		slowed = 0
		$HitStopTimer.stop()
		return
	slowed = 0
	
	flashes()
	
	if !$HitStopTimer.is_running() and !free:
		
		process_afterimage_trail() 	# do afterimage trails
		
		# render the next frame, this update the time!
		$SpritePlayer.simulate()
		$FadePlayer.simulate() # ModulatePlayer ignore hitstop but FadePlayer doesn't
		
		if !hitstop: # timers do not run on exact frame hitstop starts
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
	
	

# STATE DETECT ---------------------------------------------------------------------------------------------------

func animate(anim):

#	var old_new_state: int = new_state
	
	if Animator.play(anim):
		new_state = state_detect(anim)
		
		if anim.ends_with("Active") and !Em.atk_attr.NO_HITCOUNT_RESET in UniqNPC.query_atk_attr(get_move_name()):
			atk_startup_resets() # need to do this here to work! resets hitcount and ignore list



func query_state(query_states: Array):
	for x in query_states:
		if state == x or new_state == x:
			return true
	return false

func state_detect(anim) -> int:
	match anim:
		# universal animations

		"LaunchStop", "LaunchTransit", "Launch":
			return Em.char_state.LAUNCHED_HITSTUN
			
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
				
	return to_return
	
				
func has_trait(trait: int) -> bool:
	if trait in UniqNPC.query_traits():
		return true
		
	return false
					
		
func mod_damage(_move_name):
	var mod := 100
	
	mod += Inventory.modifier(master_ID, Cards.effect_ref.ASSIST_DMG_MOD, true)
			
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
	
func get_opponent_v_dir():
	var target = get_target()
	if target.position.y == position.y: return 0
	else: return int(sign(target.position.y - position.y)) # if +1, target is under, if -1, target is above
	
func get_opponent_x_dist():
	var target = get_target()
	return int(abs(target.position.x - position.x))
	
func get_opponent_y_dist():
	var target = get_target()
	return int(abs(target.position.y - position.y))
	
func get_opponent_angle_seg(angle_split):
	var target = get_target()
	var vec_to_opponent = FVector.new()
	vec_to_opponent.set_from_vec(target.position - position)
	return Globals.split_angle(vec_to_opponent.angle(), angle_split)

func is_opponent_in_box(origin: Vector2, size:Vector2) -> bool:
	origin.x = origin.x * facing
	origin = position + origin
	var left_bound = origin.x - int(size.x/2)
	var right_bound = origin.x + int(size.x/2)
	var top_bound = origin.y - int(size.y/2)
	var bottom_bound = origin.y + int(size.y/2)

	var target = get_target()
	if target.position.x >= left_bound and target.position.x <= right_bound and \
			target.position.y <= bottom_bound and target.position.y >= top_bound:
		return true
	return false
	
	
func check_landing(): # called by physics.gd when character stopped by floor
	if seq_partner_ID != null: return # no checking during start of sequence
	match new_state:
		Em.char_state.LAUNCHED_HITSTUN: # land during launch_hitstun, can bounce or tech land
			# check using either velocity this frame or last frame
			var vector_to_check
			if velocity.is_longer_than_another(velocity_previous_frame):
				vector_to_check = velocity
			else:
				vector_to_check = velocity_previous_frame
			
			if !vector_to_check.is_longer_than(TECHLAND_THRESHOLD):
				unsummon(true) # longer cooldown

		
func check_fallthrough(): # during aerials, can drop through platforms if down is held
	if state == Em.char_state.SEQ_USER:
		return UniqNPC.sequence_fallthrough()

	return UniqNPC.check_fallthrough()
	
	
func check_semi_invuln():
	if UniqNPC.check_semi_invuln():
		return true
	else:
		match new_state:
			Em.char_state.LAUNCHED_HITSTUN: # has iframes on launch
				return true
			
	return false	
	
func check_passthrough():
	if state == Em.char_state.SEQ_USER:
		return UniqNPC.sequence_passthrough() # for cinematic supers

	return false
	
func sequence_partner_passthrough():
	return UniqNPC.sequence_partner_passthrough()
		

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
			
	if posmod(Globals.Game.frametime, 3) == 0:

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
					
#	else:
#		afterimage_timer -= 1
		
		
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
			return true
	else:
		return false # not attacking
	

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
		
	
#func get_atk_strength(_move):
#	return 3 # same strength as non-EX Specials

	
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
	
	
func is_hitcount_first_hit(in_ID): # for multi-hit moves, only 1st hit affect RES Gauge
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
	if grounded:
		priority = Em.priority.gSp
	else:
		priority = Em.priority.aSp
		
				
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
	
	if Em.atk_attr.AUTOCHAIN in hit_data[Em.hit.MOVE_DATA][Em.move.ATK_ATTR]:
		autochain_landed = true # no more RES drain

	# ATTACKER HITSTOP ----------------------------------------------------------------------------------------------
		# hitstop is only set into HitStopTimer at end of frame
	
	if Em.hit.MULTIHIT in hit_data and Em.move.FIXED_ATKER_HITSTOP_MULTI in hit_data[Em.hit.MOVE_DATA]:
		hitstop = hit_data[Em.hit.MOVE_DATA][Em.move.FIXED_ATKER_HITSTOP_MULTI]
	
	elif Em.move.FIXED_ATKER_HITSTOP in hit_data[Em.hit.MOVE_DATA]:
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
		
#	var attacker_vec := FVector.new()
#	attacker_vec.set_from_vec(vec_to_attacker)
#
#	hit_data[Em.hit.ANGLE_TO_ATKER] = attacker_vec.angle()
	hit_data[Em.hit.LETHAL_HIT] = false
	hit_data[Em.hit.PUNISH_HIT] = false
	hit_data[Em.hit.STUN] = false
	hit_data[Em.hit.CRUSH] = false
	hit_data[Em.hit.BLOCK_STATE] = Em.block_state.UNBLOCKED
	hit_data[Em.hit.REPEAT] = false
	hit_data[Em.hit.DOUBLE_REPEAT] = false

	
	if Em.hit.ENTITY_PATH in hit_data and Em.move.PROJ_LVL in hit_data[Em.hit.MOVE_DATA] and hit_data[Em.hit.MOVE_DATA][Em.move.PROJ_LVL] < 2:
		hit_data[Em.hit.NON_STRONG_PROJ] = true
		
	if hit_data[Em.hit.MOVE_DATA][Em.move.ATK_TYPE] in [Em.atk_type.LIGHT, Em.atk_type.FIERCE] or Em.hit.NON_STRONG_PROJ in hit_data:
		hit_data[Em.hit.WEAKARMORABLE] = true
		
		
	if is_attacking():	
		hit_data[Em.hit.DEFENDER_ATTR] = query_atk_attr()
	else:
		hit_data[Em.hit.DEFENDER_ATTR] = []
		
		
	# CHECK BLOCK STATE ----------------------------------------------------------------------------------------------

#	var crossed_up: bool = check_if_crossed_up(hit_data)

	if !Em.atk_attr.UNBLOCKABLE in hit_data[Em.hit.MOVE_DATA][Em.move.ATK_ATTR]:
		match new_state:
			
			# SUPERARMOR --------------------------------------------------------------------------------------------------
			
			# WEAK block_state
			# attacker can chain combo normally after hitting an armored defender
			
			Em.char_state.GRD_ATK_STARTUP, Em.char_state.AIR_ATK_STARTUP: # can sweetspot superarmor
				var defender_attr = hit_data[Em.hit.DEFENDER_ATTR]
				if hit_data[Em.hit.CROSSED_UP]:
					continue # armored moves only armor from front unless has BI_DIR_ARMOR
				if Em.atk_attr.SUPERARMOR_STARTUP in defender_attr or \
						(Em.atk_attr.WEAKARMOR_STARTUP in defender_attr and Em.hit.WEAKARMORABLE in hit_data):
					hit_data[Em.hit.BLOCK_STATE] = Em.block_state.BLOCKED
					hit_data[Em.hit.SUPERARMORED] = true
					
			Em.char_state.GRD_ATK_ACTIVE, Em.char_state.AIR_ATK_ACTIVE:
				var defender_attr = hit_data[Em.hit.DEFENDER_ATTR]
				if hit_data[Em.hit.CROSSED_UP]:
					continue # armored moves only armor from front unless has BI_DIR_ARMOR
				if Em.atk_attr.SUPERARMOR_ACTIVE in defender_attr or \
						(Em.atk_attr.WEAKARMOR_ACTIVE in defender_attr and Em.hit.WEAKARMORABLE in hit_data) or \
						(Em.atk_attr.PROJ_ARMOR_ACTIVE in defender_attr and Em.hit.ENTITY_PATH in hit_data):
					hit_data[Em.hit.BLOCK_STATE] = Em.block_state.BLOCKED
					hit_data[Em.hit.SUPERARMORED] = true
						

	
	
	# ZEROTH REACTION (before damage) ---------------------------------------------------------------------------------
	
	# unique reactions
	if Em.hit.ENTITY_PATH in hit_data:
		if attacker_or_entity.UniqEntity.has_method("landed_a_hit0"):
			attacker_or_entity.UniqEntity.landed_a_hit0(hit_data) # reaction, can change hit_data from there
	elif Em.hit.NPC_PATH in hit_data:
		if attacker_or_entity.UniqNPC.has_method("landed_a_hit0"):
			attacker_or_entity.UniqNPC.landed_a_hit0(hit_data) # reaction, can change hit_data from there
	elif attacker != null and attacker.UniqChar.has_method("landed_a_hit0"):
		attacker.UniqChar.landed_a_hit0(hit_data) # reaction, can change hit_data from there
	
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
	elif attacker != null and attacker.UniqChar.has_method("landed_a_hit"):
		attacker.UniqChar.landed_a_hit(hit_data) # reaction, can change hit_data from there
		# good for moves that have special effects on Sweetspot/Punish Hits
	
	if UniqNPC.has_method("being_hit"):	
		UniqNPC.being_hit(hit_data) # reaction, can change hit_data from there
		
	# ---------------------------------------------------------------------------------
	
	if Em.move.SEQ in hit_data[Em.hit.MOVE_DATA]:
		return # cannot grab NPCs

	# knockback
	var knockback_dir: int = calculate_knockback_dir(hit_data)
	hit_data[Em.hit.KB_ANGLE] = knockback_dir
	hit_data[Em.hit.KB] = NPC_KB_STR

		
	# SPECIAL HIT EFFECTS ---------------------------------------------------------------------------------
	
	# for moves that automatically chain into more moves, will not cause lethal or break hits, will have fixed_hitstop and no KB boost


	if hit_data[Em.hit.BLOCK_STATE] != Em.block_state.UNBLOCKED:
		modulate_play("armor_flash")
		play_audio("block3", {"vol" : -15})

	else:
		modulate_play("punish_sweet_flash")
		play_audio("impact29", {"vol" : -18, "bus" : "LowPass"})
		
		
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
	elif attacker != null and attacker.UniqChar.has_method("landed_a_hit2"):
		attacker.UniqChar.landed_a_hit2(hit_data) # reaction, can change hit_data from there
	
	if UniqNPC.has_method("being_hit2"):	
		UniqNPC.being_hit2(hit_data) # reaction, can change hit_data from there
	
	# HITSPARK ---------------------------------------------------------------------------------------------------
	
	if hit_data[Em.hit.BLOCK_STATE] == Em.block_state.UNBLOCKED:
		generate_hitspark(hit_data)
	else:
		generate_blockspark(hit_data)
		
	# ---------------------------------------------------------------------------------------------------

	if hit_data[Em.hit.BLOCK_STATE] != Em.block_state.UNBLOCKED:
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

	
	
func check_if_crossed_up(attacker_or_entity, angle_to_atker, atker_move_data):
	
	if Em.atk_attr.NO_CROSSUP in atker_move_data[Em.move.ATK_ATTR]:
		return false
	
	if attacker_or_entity.has_method("query_status_effect") and \
			(attacker_or_entity.query_status_effect(Em.status_effect.NO_CROSSUP) or attacker_or_entity.query_status_effect(Em.status_effect.SCANNED)):
		return false
		
	if is_atk_startup() or is_atk_active():
		var defender_move_data = query_move_data()
		if Em.atk_attr.CROSSUP_PROTECTION in defender_move_data[Em.move.ATK_ATTR]:
			return false
	
# warning-ignore:narrowing_conversion
	var x_dist: int = abs(attacker_or_entity.position.x - position.x)
	if x_dist <= CROSS_UP_MIN_DIST: return false
	
	var segment = Globals.split_angle(angle_to_atker, Em.angle_split.EIGHT)
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
	Globals.Game.spawn_SFX("Superarmorspark", "Blocksparks", hit_data[Em.hit.HIT_CENTER], {"rot" : deg2rad(hit_data[Em.hit.ANGLE_TO_ATKER])})
	
	
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
				
	

# ANIMATION AND AUDIO PROCESSING ---------------------------------------------------------------------------------------------------
	
# universal actions
func _on_SpritePlayer_anim_finished(anim_name):
	
	match anim_name:

		"LaunchStop":
			animate("LaunchTransit")
		"LaunchTransit":
			animate("Launch")

	UniqNPC._on_SpritePlayer_anim_finished(anim_name)



func _on_SpritePlayer_anim_started(anim_name): # DO NOT START ANY ANIMATIONS HERE!
	
	state = state_detect(anim_name) # update state

	
	if is_atk_startup():
		var move_name = anim_name.trim_suffix("Startup")
					
		var atk_attr = query_atk_attr(move_name)
		if Em.atk_attr.WEAKARMOR_STARTUP in atk_attr or Em.atk_attr.SUPERARMOR_STARTUP in atk_attr:
			modulate_play("armor_flash")
						

	anim_friction_mod = 100
	anim_gravity_mod = 100
	velocity_limiter = {"x" : null, "up" : null, "down" : null, "x_slow" : null, "y_slow" : null}
	if Animator.query_current(["LaunchStop"]):
		sprite.rotation = launch_starting_rot
	else:
		sprite.rotation = 0


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
#		"afterimage_timer" : afterimage_timer,
		"launch_starting_rot" : launch_starting_rot,
		"launchstun_rotate" : launchstun_rotate,
		"seq_partner_ID" : seq_partner_ID,
		"slowed" : slowed,
		"gravity_frame_mod" : gravity_frame_mod,
		"autochain_landed" : autochain_landed,
		
		"sprite_texture_ref" : sprite_texture_ref,
		
		"unique_data" : unique_data,
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
#	afterimage_timer = state_data.afterimage_timer
	launch_starting_rot = state_data.launch_starting_rot
	launchstun_rotate = state_data.launchstun_rotate
	seq_partner_ID = state_data.seq_partner_ID
	slowed = state_data.slowed
	gravity_frame_mod = state_data.gravity_frame_mod
	autochain_landed = state_data.autochain_landed
		
	sprite_texture_ref = state_data.sprite_texture_ref
	
	unique_data = state_data.unique_data
	
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
	if $ModulatePlayer.current_anim in NSAnims.modulate_animations and \
			NSAnims.modulate_animations[$ModulatePlayer.current_anim].has("monochrome"): set_monochrome()
	reset_fade()
	$FadePlayer.load_state(state_data.FadePlayer_data)
	
	$HitStopTimer.time = state_data.HitStopTimer_time
	$NoCollideTimer.time = state_data.NoCollideTimer_time



	
#--------------------------------------------------------------------------------------------------


