extends "res://Scenes/Physics/Physics.gd"

#signal SFX (anim, loaded_sfx_ref, out_position, aux_data)
#signal afterimage (sprite_node_path, out_position, starting_modulate_a, lifetime)
#signal entity (master_path, entity_ref, out_position, aux_data)

# constants
const MOB = true
const GRAVITY = 70 * FMath.S # per frame
const PEAK_DAMPER_MOD = 60 # used to reduce gravity at jump peak
const PEAK_DAMPER_LIMIT = 400 * FMath.S # min velocity.y where jump peak gravity reduction kicks in
const TERMINAL_THRESHOLD = 150 # if velocity.y is over this during hitstun, no terminal velocity slowdown

const GUARD_GAUGE_FLOOR = -10000

const HITSTUN_TERMINAL_VELOCITY_MOD = 650
const AERIAL_STRAFE_MOD = 50 # reduction of air strafe speed and limit during aerials
const PLAYER_PUSH_SLOWDOWN = 95 # how much characters are slowed when they push against each other

const MIN_HITSTOP = 5
const MAX_HITSTOP = 13
const REPEAT_DMG_MOD = 50 # damage modifier on double_repeat
const HITSTUN_REDUCTION_AT_MAX_GG = 50 # reduction in hitstun when defender's Guard Gauge is at 100%

# old hitstun
#const ATK_LEVEL_TO_F_HITSTUN = [35, 40, 45, 50, 55, 60, 65, 70]
#const ATK_LEVEL_TO_L_HITSTUN = [55, 60, 65, 70, 75, 80, 85, 90]
#const ATK_LEVEL_TO_GDRAIN = [0, 1500, 1750, 2000, 2250, 2500, 2750, 3000]

# original character hitstun
#const ATK_LEVEL_TO_F_HITSTUN = [15, 20, 25, 30, 35, 40, 45, 50]
#const ATK_LEVEL_TO_L_HITSTUN = [25, 30, 35, 40, 45, 50, 55, 60]

#const ATK_LEVEL_TO_F_HITSTUN = [[25, 30, 35, 40, 45, 50, 55, 60], [21, 26, 31, 36, 41, 46, 51, 56], [17, 22, 27, 32, 37, 42, 47, 52]]
#const ATK_LEVEL_TO_L_HITSTUN = [[40, 45, 50, 55, 60, 65, 70, 75], [35, 40, 45, 50, 55, 60, 65, 70], [30, 35, 40, 45, 50, 55, 60, 65]]
const ATK_LEVEL_TO_F_HITSTUN = [33, 36, 39, 42, 45, 48, 51, 54]
const ATK_LEVEL_TO_L_HITSTUN = [48, 51, 54, 57, 60, 63, 66, 69]
const ATK_LEVEL_TO_F_HITSTUN_H = [15, 20, 25, 30, 35, 40, 45, 50]
const ATK_LEVEL_TO_L_HITSTUN_H = [25, 30, 35, 40, 45, 50, 55, 60]
const COMBO_LEVEL_TO_GUARD_SWELL_MOD = [300, 250, 200, 150, 100, 80, 60, 40]

const ATK_LEVEL_TO_GDRAIN = [0, 3000, 3500, 4000, 4500, 5000, 5500, 6000]

const MOB_LEVEL_TO_HP = [100, 125, 150, 200, 250, 300, 350, 400, 450]
const IDLE_CHANCE = [45, 40, 35, 22, 10, 0, 0, 0, 0]
const MOB_LEVEL_TO_DMG = [100, 110, 120, 130, 140, 150, 160, 170, 180]
const MOB_LEVEL_TO_SPEED = [80, 85, 90, 95, 100, 105, 110, 115, 120]

const HITSTUN_GRAV_MOD = 65  # gravity multiplier during hitstun
const HITSTUN_FRICTION = 15  # friction during hitstun
const HITSTUN_AIR_RES = 3 # air resistance during hitstun

const SWEETSPOT_KB_MOD = 115
const SWEETSPOT_DMG_MOD = 150 # damage modifier on sweetspotted hit
const SWEETSPOT_HITSTOP_MOD = 130 # sweetspotted hits has 30% more hitstop

const STUN_HITSTOP_ATTACKER = 15 # hitstop for attacker when causing Crush
const LETHAL_HITSTOP = 15
const MOB_BREAK_HITSTOP_MOD = 150 # increase hitstop when guardbreaking

const LAUNCH_THRESHOLD = 450 * FMath.S # max knockback strength before a flinch becomes a launch, also added knockback during a Break
const LAUNCH_BOOST = 250 * FMath.S # increased knockback strength when a flinch becomes a launch
const LAUNCH_ROT_SPEED = 5*PI # speed of sprite rotation when launched, don't need fixed-point as sprite rotation is only visuals
const TECHLAND_THRESHOLD = 300 * FMath.S # max velocity when hitting the ground to tech land

const WALL_SLAM_THRESHOLD = 100 * FMath.S # min velocity towards surface needed to do Wall Slams and release BounceDust when bouncing
const WALL_SLAM_VEL_LIMIT_MOD = 500
const WALL_SLAM_MIN_DAMAGE = 1
const WALL_SLAM_MAX_DAMAGE = 100
const HORIZ_WALL_SLAM_UP_BOOST = 500 * FMath.S # if bounce horizontally on ground, boost up a little

const LAUNCH_DUST_THRESHOLD = 1400 * FMath.S # velocity where launch dust increase in frequency

#const RageTimer_TIME = 300 # no passivity if got hit for a while
const LOOT_UNSCALED_SPEED_RANGE = [500, 1000]
const LOOT_ANGLE_RANGE = [225, 315]

const SPEED_MOD = 100

const LEARN_RATE = 20
const LongFailTimer_TIME = 60 # if failed a long range zone roll, will not roll again while timer is running

#const ResistTimer_TIME = 60 # if in Resisted Hitstun for a while, gain armor
const ARMOR_TIME = 30 # frames of special armor after recovering from hitstun
const ARMOR_DMG_MOD = 50 # % of damage taken when attacked during special armor
#const ARMOR_KNOCKBACK_MOD = 150 # % of knockback mob experience when attacked during special armor
#const RESISTED_KB_MOD = 200 # % of knockback mob experience

# variables used, don't touch these
var loaded_palette = null
onready var Animator = $SpritePlayer # clean code
onready var sprite = $Sprites/Sprite # clean code
onready var sfx_under = $Sprites/SfxUnder # clean code
onready var sfx_over = $Sprites/SfxOver # clean code
var UniqChar # unique character node

var spritesheet
var unique_audio
var entity_data
var sfx_data

var floor_level

var dir := 0
var grounded := true
var hitstop = null # holder to influct hitstop at end of frame
var status_effect_to_remove = [] # holder to remove status effects at end of frame
var status_effect_to_add = []


# character state, save these when saving and loading along with position, sprite frame and animation progress

var free := false
var mob_ref: String
var mob_level: int
var mob_variant: String
var mob_attr := {}
var palette_ref: String
var player_ID: int

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
					# each entry is an array with [0] being the move name and [1] being the player_ID

var target_ID = null # nodepath of the opponent, changes whenever you land a hit on an opponent or is attacked
var seq_partner_ID = null

var current_command: String = "start" # key to a COMMANDS dictionary on UniqChar
var command_timer := 0 # timer that counts up
var command_style : String # to mark some command variants
var strafe_style := 0 # 1 is towards opponent, -1 is away
var command_array_num := 0 # some commands have an array of animations to go through
var guardbroken := false # when GG is depleted, mob enters a guardbroken state where they no longer has superarmor till GG refills
var chaining := false
var air_dashed := false
var rand_time = null
var peak_flag = Globals.peak_flag.GROUNDED
var chain_memory := []
var rand_max_chain_size := 0
var combo_level := 0 # set when mob_break according to atk_level, determine Guard Swell Rate
#var proj_only_combo := false # set to true when mob_break via projectile, false if hit with physical attack during combo, increase armor time
var no_jump_chance := 0 # chance of removing all jumps from decision, increased if hit in air, decreased when hit on ground
var can_impulse := true # set to false when starting a MOVEMENT RECOVERY, set to true otherwise

var test := false # used to test specific player, set by main game scene to just one player
var test_num := 0


# SETUP CHARACTER --------------------------------------------------------------------------------------------------

# this is run after adding this node to the tree
func init(mob_name: String, level: int, variant: String, attr: Dictionary, start_position: Vector2, start_facing = null):
	
	set_player_ID()
	initial_targeting()
	face_opponent()
	
	mob_ref = mob_name
	mob_level = int(clamp(level, 0, 8))
	mob_variant = variant
	mob_attr = attr
	
	load_mob()
	
	# incoming start position points at the floor
	start_position.y -= $PlayerCollisionBox.rect_position.y + $PlayerCollisionBox.rect_size.y
	
	position = start_position
	set_true_position()
	
	if start_facing != null:
		face(start_facing)
	
#	Globals.Game.damage_update(self)
#	Globals.Game.guard_gauge_update(self)
	
	unique_data = UniqChar.UNIQUE_DATA_REF.duplicate(true)
	
	animate("Idle")
	$ArmorTimer.time = get_stat("ARMOR_TIME")
	
	Globals.Game.spawn_SFX("Respawn", "Respawn", position, {"back":true, "facing":Globals.Game.rng_facing(), \
			"v_mirror":Globals.Game.rng_bool()}, "white")
	play_audio("bling7", {"vol" : -30, "bus" : "LowPass"})
	play_audio("bling7", {"vol" : -12, "bus" : "PitchUp"})
	
	
func set_player_ID(): # each mob has a unique negative player_ID, set by order when they spawn during a level
	player_ID = Globals.Game.LevelControl.mob_ID_ref
	Globals.Game.LevelControl.mob_ID_ref -= 1
	
	
func load_mob():
	# remove test character node and add the real character node
#	var test_character = get_child(0) # test character node should be directly under this node
#	test_character.free()
	add_to_group("MobNodes")
	
	UniqChar = Loader.char_data[mob_ref].scene.instance()
	add_child(UniqChar)
	move_child(UniqChar, 0)
	
	spritesheet = Loader.char_data[mob_ref].spritesheet
	unique_audio = Loader.char_data[mob_ref].unique_audio
	entity_data = Loader.char_data[mob_ref].entity_data
	sfx_data = Loader.char_data[mob_ref].sfx_data
	
	UniqChar.sprite = sprite
	
	# set up animators
	UniqChar.Animator = $SpritePlayer
	# load frame data
	Animator.init_with_loaded_frame_data_array(sprite, sfx_over, sfx_under, Loader.char_data[mob_ref].frame_data_array)
	$ModulatePlayer.sprite = sprite
	$FadePlayer.sprite = sprite
	
	# overwrite default movement stats
	
	setup_boxes(UniqChar.get_node("DefaultCollisionBox"))
	
	floor_level = Globals.Game.middle_point.y # get floor level of stage
	
	palette()
	sfx_under.hide()
	sfx_over.hide()
	
#	$MobStats/Level.text = "Lvl " + str(mob_level + 1)
	
#	damage_update()
#	guard_gauge_update()
	
	
func setup_boxes(ref_rect): # set up detection boxes
	
	$PlayerCollisionBox.rect_position = ref_rect.rect_position
	$PlayerCollisionBox.rect_size = ref_rect.rect_size
	$PlayerCollisionBox.add_to_group("Mobs")
	$PlayerCollisionBox.add_to_group("Grounded")


# change palette and reset monochrome
func palette():
	
	monochrome = false
	
	UniqChar.load_palette()
#	loaded_palette set by UniqChar on loading based on Globals.Game.LevelControl.mob_data[mob_ref].variant
#	from Globals.Game.LevelControl.mob_data[mob_ref].palettes dictionary
	
	if loaded_palette == null:
		sprite.material = null
		sfx_over.material = null
		sfx_under.material = null
	else:
		sprite.material = ShaderMaterial.new()
		sprite.material.shader = Loader.loaded_palette_shader
		sprite.material.set_shader_param("swap", loaded_palette)
		sfx_over.material = ShaderMaterial.new()
		sfx_over.material.shader = Loader.loaded_palette_shader
		sfx_over.material.set_shader_param("swap", loaded_palette)
		sfx_under.material = ShaderMaterial.new()
		sfx_under.material.shader = Loader.loaded_palette_shader
		sfx_under.material.set_shader_param("swap", loaded_palette)
		

func initial_targeting(): # target closest player at start
	if Globals.player_count == 1:
		target_ID = 0
	else:
		var target_node = FMath.get_closest([Globals.Game.get_player_node(0), Globals.Game.get_player_node(1)], position)
		target_ID = target_node.player_ID
		return target_node
	
func get_seq_partner():
	var Partner = Globals.Game.get_player_node(seq_partner_ID)
	if Partner == null or Partner == self: return null
	if Partner.seq_partner_ID != player_ID: return null
	return Partner
	
func get_target():
	var target_node = Globals.Game.get_player_node(target_ID)
	
	if target_node.state == Globals.char_state.DEAD: # player is dead
		if Globals.player_count == 1:
			return self # no more players
		else: # target other player
			if target_ID == 0:
				target_ID = 1
				target_node = Globals.Game.get_player_node(target_ID)
				if target_node.state == Globals.char_state.DEAD:
					return self # no more players
				else:
					return target_node
			else:
				target_ID = 0
				target_node = Globals.Game.get_player_node(target_ID)
				if target_node.state == Globals.char_state.DEAD:
					return self # no more players
				else:
					return target_node
	else:
		return target_node

func guard_gauge_update():
# warning-ignore:integer_division
	var value = clamp(round((current_guard_gauge - GUARD_GAUGE_FLOOR)/500.0), 0, 20)
	$MobStats/GG.frame = value
	
func damage_update():
	var value = max(0, get_stat("DAMAGE_VALUE_LIMIT") - current_damage_value)
	$MobStats/HP.text = str(value)
	
# TESTING --------------------------------------------------------------------------------------------------

# for testing only
func test1():
	$TestNode2D/TestLabel.text = "old state: " + Globals.char_state_to_string(state) + \
		"\n" + Animator.current_animation + " > " + Animator.to_play_animation + "  time: " + str(Animator.time) + "\n"
	
func test2():
	$TestNode2D/TestLabel.text = $TestNode2D/TestLabel.text + "new state: " + Globals.char_state_to_string(state) + \
		"\n" + Animator.current_animation + " > " + Animator.to_play_animation + "  time: " + str(Animator.time) + \
		"\n" + str(velocity.y) + " " + str(velocity_previous_frame.y) + " " + str(guardbroken) + " " + str(target_ID) + \
		"\ngrounded: " + str(grounded) + " command: " + current_command + "\nchain_mem: " + str(chain_memory) + " " + str(seq_partner_ID)
			
			
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

#	if test:
	if Globals.debug_mode2:
		$TestNode2D.show()
	else:
		$TestNode2D.hide()
			
			
func simulate(_new_input_state):
	
# INDICATORS --------------------------------------------------------------------------------------------------

	if state == Globals.char_state.DEAD:
		$MobStats.hide()
	else:
		$MobStats.show()
		
		if current_damage_value > 0:
			$MobStats/HP.show()
			var dmg_percent = get_damage_percent()
			if dmg_percent < 25:
				$MobStats/HP.modulate = Color(1.0, 1.0, 1.0)
			elif dmg_percent < 50:
				$MobStats/HP.modulate = Color(1.0, 1.0, 0.5)
			elif dmg_percent < 75:
				$MobStats/HP.modulate = Color(1.0, 0.5, 0.2)
			else:
				$MobStats/HP.modulate = Color(1.0, 0.0, 0.0)
		else:
			$MobStats/HP.hide()
			
		if current_guard_gauge == 0:
			$MobStats/GG.hide()
		else:
			$MobStats/GG.show()
		
#	if !guardbroken:
#		$MobStats/GG.modulate = Color(1.0, 0.5, 0.0)
	if guardbroken:
		var value = posmod(Globals.Game.frametime, 10)
		if value < 5:
			$MobStats/GG.modulate = Color(0.9, 0.0, 0.0)
		elif value < 6:
			$MobStats/GG.modulate = Color(1.5, 1.5, 1.5)
		else:
			$MobStats/GG.modulate = Color(1.2, 0.65, 0.0)
	else:
		$MobStats/GG.modulate = Color(1.2, 0.65, 0.0)
			
# RESET NON-SAVEABLE VARIABLES --------------------------------------------------------------------------------------------------

	hitstop = null
	status_effect_to_remove = []
	status_effect_to_add = []
	dir = 0
	if is_on_ground($PlayerCollisionBox):
		grounded = true
	else:
		grounded = false

# FRAMESKIP DURING HITSTOP --------------------------------------------------------------------------------------------------
	# while buffering all inputs
	
	if Globals.Game.is_stage_paused() and Globals.Game.screenfreeze != player_ID: # screenfrozen
		return
	if free: return
	
	$HitStopTimer.simulate() # advancing the hitstop timer at start of frame allow for one frame of knockback before hitstop
	# will be needed for multi-hit moves
	
	if !$HitStopTimer.is_running():
		simulate2()
		
func simulate2(): # only ran if not in hitstop
	
# START OF FRAME --------------------------------------------------------------------------------------------------
		
	ignore_list_progress_timer()
	process_status_effects_timer() # remove expired status effects before running hit detection since that can add effects
	
	# clearing repeat memory
	if !is_hitstunned_or_sequenced():
		repeat_memory = []
		combo_level = 0
		
	if !new_state in [Globals.char_state.SEQUENCE_TARGET, Globals.char_state.SEQUENCE_USER]:
		seq_partner_ID = null
		
	if !is_attacking():
		chain_memory = []
		
	# GG Swell during guardbroken state
	if !$HitStopTimer.is_running() and !state in [Globals.char_state.SEQUENCE_TARGET] and get_damage_percent() < 100:
		if guardbroken:
			current_guard_gauge = int(min(0, current_guard_gauge + get_stat("GUARD_GAUGE_SWELL_RATE")))
			if !$HitStunTimer.is_running(): # guardbroken and out of hitstun, instantly gain back all Guard Gauge
				reset_guard_gauge()
				guardbroken = false
#				if !proj_only_combo:
				$ArmorTimer.time = get_stat("ARMOR_TIME")
#				else:
#					$ArmorTimer.time = FMath.percent(get_stat("ARMOR_TIME"), 400)
#					proj_only_combo = false
				play_audio("bling7", {"vol" : -2, "bus" : "LowPass"})
				Globals.Game.spawn_SFX("Reset", "Shines", position, {"facing":Globals.Game.rng_facing(), \
					"v_mirror":Globals.Game.rng_bool()}, "red")
			else:
				if current_guard_gauge == 0: # instantly recover from hitstun if GG swell back to max
					$HitStunTimer.stop()
					guardbroken = false
#					if !proj_only_combo:
					$ArmorTimer.time = get_stat("ARMOR_TIME")
#					else:
#						$ArmorTimer.time = FMath.percent(get_stat("ARMOR_TIME"), 200)
#						proj_only_combo = false
					play_audio("bling7", {"vol" : -2, "bus" : "LowPass"})
					Globals.Game.spawn_SFX("Reset", "Shines", position, {"facing":Globals.Game.rng_facing(), \
						"v_mirror":Globals.Game.rng_bool()}, "red")
				
			guard_gauge_update()
		else:
			if current_guard_gauge < 0:
				var guard_gauge_regen: int = get_stat("GG_REGEN_AMOUNT")
				current_guard_gauge = int(min(0, current_guard_gauge + guard_gauge_regen))
				guard_gauge_update()
		
		
	if state in [Globals.char_state.SEQUENCE_USER, Globals.char_state.SEQUENCE_TARGET]:
		simulate_sequence()
		return
	
	if $ArmorTimer.time == 1:
		if !grounded: # only runs out of armor on ground
			$ArmorTimer.time += 1
	
#	if !$ResistTimer.is_running(): # out of resist timer, recover automatically
#		if state in [Globals.char_state.GROUND_RECOVERY, Globals.char_state.AIR_RECOVERY] and \
#				Animator.query_current(["ResistA", "ResistB", "aResistA", "aResistB"]):
#			if grounded:
#				animate("Idle")
#			else:
#				animate("FallTransit")
#			$ArmorTimer.time = get_stat("ARMOR_TIME")
#	else: # if no longer in Resisted Hitstun, set the timer to zero
#		if state in [Globals.char_state.GROUND_RECOVERY, Globals.char_state.AIR_RECOVERY] and \
#				Animator.query_current(["ResistA", "ResistB", "aResistA", "aResistB"]):
#			pass
#		else:
#			$ResistTimer.stop()
	
	
	if grounded:
		air_dashed = false
		
	if status_effects.size() > 0:
		timed_status()
	
	process_command()
	if $ZoneDrawer.visible:
		$ZoneDrawer.activate()
	
	match new_state: # quick turn
		Globals.char_state.GROUND_ATK_STARTUP:
			if Animator.time <= 6:
				face_opponent()
		Globals.char_state.AIR_ATK_STARTUP:
			if Animator.time <= 6:
				face_opponent()
	
	# air strafing
	if !grounded and new_state in [Globals.char_state.AIR_STANDBY, Globals.char_state.AIR_ATK_STARTUP, Globals.char_state.AIR_ATK_ACTIVE]:
					
		var valid := true
		match new_state:
			Globals.char_state.AIR_ATK_ACTIVE:
				var move_data = query_move_data()
				if !can_air_strafe(move_data):
					valid = false # some attacks cannot be air strafed
			Globals.char_state.AIR_STANDBY:
				if strafe_style == Globals.strafe_style.NONE:
					valid = false
					
		if strafe_style == Globals.strafe_style.AWAY_ON_DESCEND and velocity.y < 0:
			valid = false # some style prevent strafing while going up
					
		if valid:
			var strafe_dir: int = get_opponent_dir()
			if strafe_style in [Globals.strafe_style.AWAY, Globals.strafe_style.AWAY_ON_DESCEND]:
				strafe_dir = -strafe_dir
				
			var air_strafe_speed_temp: int = FMath.percent(get_stat("SPEED"), get_stat("AIR_STRAFE_SPEED_MOD"))
			var air_strafe_limit_temp: int = FMath.percent(air_strafe_speed_temp, get_stat("AIR_STRAFE_LIMIT_MOD"))
			
			if state != Globals.char_state.AIR_STANDBY:
				air_strafe_speed_temp = FMath.percent(air_strafe_speed_temp, AERIAL_STRAFE_MOD)
				air_strafe_limit_temp = FMath.percent(air_strafe_limit_temp, AERIAL_STRAFE_MOD)
			else:
				face_opponent()
			
			if abs(velocity.x + (strafe_dir * air_strafe_speed_temp)) > abs(velocity.x): # if speeding up
				if abs(velocity.x) < air_strafe_limit_temp: # only allow strafing if below speed limit
					velocity.x = int(clamp(velocity.x + strafe_dir * air_strafe_speed_temp, -air_strafe_limit_temp, air_strafe_limit_temp))
			else: # slowing down
				velocity.x += strafe_dir * air_strafe_speed_temp
	
# CHECK DROPS AND LANDING ---------------------------------------------------------------------------------------------------
	
	if !grounded:
		match new_state:
			Globals.char_state.GROUND_STANDBY, Globals.char_state.CROUCHING, Globals.char_state.GROUND_C_RECOVERY, \
				Globals.char_state.GROUND_STARTUP, Globals.char_state.GROUND_ACTIVE, Globals.char_state.GROUND_RECOVERY, \
				Globals.char_state.GROUND_ATK_STARTUP, Globals.char_state.GROUND_ATK_ACTIVE, Globals.char_state.GROUND_ATK_RECOVERY, \
				Globals.char_state.GROUND_FLINCH_HITSTUN, Globals.char_state.GROUND_BLOCK:
				check_drop()
	else: # just in case, normally called when physics.gd runs into a floor
		match new_state:
			Globals.char_state.AIR_STANDBY, Globals.char_state.AIR_STARTUP, \
				Globals.char_state.AIR_ACTIVE, Globals.char_state.AIR_RECOVERY, Globals.char_state.AIR_ATK_STARTUP, \
				Globals.char_state.AIR_ATK_ACTIVE, Globals.char_state.AIR_ATK_RECOVERY, Globals.char_state.AIR_FLINCH_HITSTUN, \
				Globals.char_state.LAUNCHED_HITSTUN:
				check_landing()

# GRAVITY --------------------------------------------------------------------------------------------------

	var gravity_temp: int = FMath.percent(GRAVITY, get_stat("GRAVITY_MOD"))
		
	if is_hitstunned(): # fix and lower gravity during hitstun
		gravity_temp = FMath.percent(GRAVITY, HITSTUN_GRAV_MOD)
	else:
		gravity_temp = FMath.percent(GRAVITY, get_stat("GRAVITY_MOD")) # each character are affected by gravity differently out of hitstun
		
	if anim_gravity_mod != 100:
		gravity_temp = FMath.percent(GRAVITY, anim_gravity_mod) # anim_gravity_mod is based off current animation

	if !grounded and (abs(velocity.y) < PEAK_DAMPER_LIMIT): # reduce gravity at peak of jump
# warning-ignore:narrowing_conversion
		var weight: int = FMath.get_fraction_percent(PEAK_DAMPER_LIMIT - abs(velocity.y), PEAK_DAMPER_LIMIT)
		gravity_temp = FMath.f_lerp(gravity_temp, FMath.percent(gravity_temp, PEAK_DAMPER_MOD), weight)
		# transit from jump to fall animation
		if new_state == Globals.char_state.AIR_STANDBY and Animator.query_to_play(["Jump"]): # don't use query() for this one
			animate("FallTransit")

	if !grounded: # gravity only pulls you if you are in the air
		
		if is_hitstunned():
			pass
		else:
			if velocity.y > 0: # some mobs may fall at different speed compared to going up
				gravity_temp = FMath.percent(gravity_temp, get_stat("FALL_GRAV_MOD"))
				
		velocity.y += gravity_temp
		
	# terminal velocity downwards
	var terminal: int
	
	var has_terminal := true

	if new_state == Globals.char_state.DEAD:
		has_terminal = false

#	if is_atk_startup():
#		if Globals.atk_attr.NO_TERMINAL_VEL_STARTUP in query_atk_attr():
#			 has_terminal = false
	if is_atk_active():
		if Globals.atk_attr.NO_TERMINAL_VEL_ACTIVE in query_atk_attr():
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
	
	if !is_hitstunned():
		friction_this_frame = get_stat("FRICTION")
		air_res_this_frame = get_stat("AIR_RESISTANCE")
	else:
		friction_this_frame = HITSTUN_FRICTION # 15
		air_res_this_frame = HITSTUN_AIR_RES # 3
	
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
	
		Globals.char_state.AIR_STARTUP, Globals.char_state.AIR_D_RECOVERY, Globals.char_state.AIR_RECOVERY:
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
				modulate_play("unflinch_flash")
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
				modulate_play("unflinch_flash")
		
		Globals.char_state.LAUNCHED_HITSTUN:
			# when out of hitstun, recover
			if !$HitStunTimer.is_running() and Animator.query_to_play(["Launch", "LaunchTransit"]):
				animate("FallTransit")
#				modulate_play("unlaunch_flash")
#				play_audio("bling4", {"vol" : -15, "bus" : "PitchDown"})
			friction_this_frame = FMath.percent(friction_this_frame, 25) # lower friction during launch hitstun
							
	
# APPLY FRICTION/AIR RESISTANCE --------------------------------------------------------------------------------------------------

	if grounded: # apply friction if on ground
		if anim_friction_mod != 100:
			friction_this_frame = FMath.percent(friction_this_frame, anim_friction_mod)
		velocity.x = FMath.f_lerp(velocity.x, 0, friction_this_frame)

	else: # apply air resistance if in air
		velocity.x = FMath.f_lerp(velocity.x, 0, air_res_this_frame)
	
# --------------------------------------------------------------------------------------------------

	UniqChar.simulate() 

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
	
	if !$HitStopTimer.is_running() and $HitStunTimer.is_running() and state == Globals.char_state.LAUNCHED_HITSTUN:
		launch_trail() # do launch trail before moving
		
#	if grounded and abs(velocity.x) < 30 * FMath.S:
#		velocity.x = 0  # this reduces slippiness by canceling grounded horizontal velocity when moving less than 0.5 pixels per frame

	velocity_previous_frame.x = velocity.x
	velocity_previous_frame.y = velocity.y
	
	var orig_pos = position
	var results = move($PlayerCollisionBox, $PlayerCollisionBox, true) # [landing_check, collision_check, ledgedrop_check]
	
#	if results[0]: check_landing()

	if results[1]:
		if $NoCollideTimer.is_running(): # if collide during 1st/Xth frame after hitstop, will return to position before moving
			position = orig_pos
			set_true_position()
			velocity.x = velocity_previous_frame.x
			velocity.y = velocity_previous_frame.y
		else:
			if results[0]: check_landing()
			
			if new_state == Globals.char_state.LAUNCHED_HITSTUN:
				bounce(results[0])
		
	

func simulate_after(): # called by game scene after hit detection to finish up the frame
	
	test1()
	
	match peak_flag:
		Globals.peak_flag.GROUNDED:
			if !grounded:
				peak_flag = Globals.peak_flag.JUMPING
		Globals.peak_flag.JUMPING:
			if grounded:
				peak_flag = Globals.peak_flag.GROUNDED
			else:
				if velocity.y > 0:
					 peak_flag = Globals.peak_flag.PEAK
		Globals.peak_flag.PEAK, Globals.peak_flag.PEAK_SPENT:
			if grounded:
				peak_flag = Globals.peak_flag.GROUNDED
				
	advance_command()
	
	
	for effect in status_effect_to_remove: # remove certain status effects at end of frame after hit detection
										   # useful for status effects that are removed after being hit
		remove_status_effect(effect)
	for effect in status_effect_to_add:
		add_status_effect(effect)
		
	if Globals.Game.is_stage_paused() and Globals.Game.screenfreeze != player_ID:
		hitstop = null
		return
	if free: return
	
	
	process_status_effects_visual()
	flashes()
	
	if !$HitStopTimer.is_running():
		
		process_afterimage_trail() 	# do afterimage trails
		
		# render the next frame, this update the time!
		$SpritePlayer.simulate()
		$FadePlayer.simulate() # ModulatePlayer ignore hitstop but FadePlayer doesn't
		
		if !hitstop: # timers do not run on exact frame hitstop starts
			$HitStunTimer.simulate()
			$NoCollideTimer.simulate()
			$ArmorTimer.simulate()
#			$ResistTimer.simulate()

#		if !$HitStunTimer.is_running():
#			$RageTimer.simulate()

		if state == Globals.char_state.DEAD:
			death_anim()
		
		# spin character during launch, be sure to do this after SpritePlayer since rotation is reset at start of each animation
		if state == Globals.char_state.LAUNCHED_HITSTUN and Animator.query_current(["LaunchTransit", "Launch"]):
			sprite.rotation = launch_starting_rot - facing * launchstun_rotate * LAUNCH_ROT_SPEED * Globals.FRAME
			launchstun_rotate += 1
	
	# start hitstop timer at end of frame after SpritePlayer.simulate() by setting hitstop to a number other than null for the frame
	# new hitstops override old ones
	if hitstop:
		$HitStopTimer.time = hitstop
		
	$ModulatePlayer.simulate() # modulate animations continue even in hitstop
	$LongFailTimer.simulate()
	
	test2()
		
		
# AI COMMANDS --------------------------------------------------------------------------------------------------	
		
func process_command():
	
#	return
# warning-ignore:unreachable_code

	if get_damage_percent() >= 100 or get_target() == self: return

	if $HitStunTimer.is_running():
		if grounded:
			current_command = "standby"
		else:
			current_command = "option_air"
		return
	
	if  is_atk_recovery() and command_array_num > 0 and current_command in UniqChar.COMMANDS and \
			"anim" in UniqChar.COMMANDS[current_command] and UniqChar.COMMANDS[current_command].anim is Array:
		pass # chain series
	elif !new_state in [Globals.char_state.GROUND_STANDBY, Globals.char_state.AIR_STANDBY, Globals.char_state.GROUND_C_RECOVERY, \
			Globals.char_state.AIR_C_RECOVERY, Globals.char_state.GROUND_D_RECOVERY, Globals.char_state.AIR_D_RECOVERY]:
		return
	
	if !current_command in UniqChar.COMMANDS: # standby
		if current_command == "start":
			UniqChar.decision("start")
		else:
			UniqChar.decision()
			
	else:
		if "triggers" in UniqChar.COMMANDS[current_command]:
			
			if $ZoneDrawer.visible:
				for trigger in UniqChar.COMMANDS[current_command].triggers:
					if trigger.type == "zone":
						if "long" in trigger:
							if $LongFailTimer.is_running():	
								continue
						$ZoneDrawer.drawer(trigger.origin, trigger.size, trigger.decision)
					
			for trigger in UniqChar.COMMANDS[current_command].triggers:
				var active_trigger = null
				match trigger.type:
					"peak":
						if peak_flag == Globals.peak_flag.PEAK:
							active_trigger = trigger
							peak_flag = Globals.peak_flag.PEAK_SPENT
					"zone":
						if "long" in trigger:
							if $LongFailTimer.is_running():
								continue
						if velocity.y < 0: # when ascending
							if "downward" in trigger: # some triggers only activate when not going upwards in air
								continue
							if floor_level - position.y < 50:
								continue # no zone trigger if too low while going up
							elif floor_level - position.y < 100 and !"low_height" in trigger:
								continue
						if are_players_in_box(trigger.origin, trigger.size):
							active_trigger = trigger
							
				if active_trigger != null:
					if "next" in active_trigger:
						start_command(active_trigger.next)
						break
					elif "decision" in active_trigger:
						if UniqChar.decision(active_trigger.decision):
							break
				
		if current_command in UniqChar.COMMANDS:
			match UniqChar.COMMANDS[current_command].action:
						
				"idle":
					if !new_state in [Globals.char_state.GROUND_C_RECOVERY, Globals.char_state.GROUND_D_RECOVERY]:
						face_opponent()
							
				"option": # see if activate triggers for 1 frame, then do "next" or "decision"
					if new_state in [Globals.char_state.GROUND_C_RECOVERY, Globals.char_state.AIR_C_RECOVERY, \
							Globals.char_state.GROUND_D_RECOVERY, Globals.char_state.AIR_D_RECOVERY]:
						return # maintain option during recovery states
					if grounded:
						if "next" in UniqChar.COMMANDS[current_command]:
							start_command(UniqChar.COMMANDS[current_command].next)
						elif "decision" in UniqChar.COMMANDS[current_command]:
							if !UniqChar.decision(UniqChar.COMMANDS[current_command].decision):
								UniqChar.decision()
						else:
							UniqChar.decision()
						
				"run":
					if new_state == Globals.char_state.GROUND_STANDBY:
						if "dir" in UniqChar.COMMANDS[current_command]:
							match UniqChar.COMMANDS[current_command].dir:
								1, -1:
									dir = UniqChar.COMMANDS[current_command].dir
						else: # towards targeted player
							dir = get_opponent_dir()
									
						if dir != facing: # flipping over
							face(dir)
							animate("RunTransit") # restart run animation
						if !Animator.query(["Run", "RunTransit"]): # if not in run animation, do run animation
							animate("RunTransit")	
						velocity.x = FMath.f_lerp(velocity.x, dir * get_stat("SPEED"), get_stat("ACCELERATION"))
						
				"anim":
					var anim: = ""
					var is_array := false
					if !UniqChar.COMMANDS[current_command].anim is Array:
						anim = UniqChar.COMMANDS[current_command].anim
					else:
						if command_array_num >= UniqChar.COMMANDS[current_command].anim.size():
							print("Error: command_array_num overshot current command array.")
						else:
							anim = UniqChar.COMMANDS[current_command].anim[command_array_num]
							is_array = true
							
						# break out of combo if opponent is too high above
#						if command_array_num > 0 and is_opponent_crossing_mob() and !"anti_air_dash" in UniqChar.COMMANDS[current_command]:
						if command_array_num > 0 and is_opponent_crossing_mob():
							UniqChar.decision()
							return
							
					if is_ground_anim(anim):
						if !grounded: return # if in air while trying to do a ground animation, wait till grounded then do it
						
						match new_state:
							Globals.char_state.GROUND_ATK_RECOVERY: # chaining
								if command_array_num == 0: return
								else: chaining = true
							Globals.char_state.GROUND_D_RECOVERY:
								if command_array_num == 0 and \
										("no_c_rec" in UniqChar.COMMANDS[current_command] or "no_move_rec" in UniqChar.COMMANDS[current_command]):
									return # some animations cannot be done during MOVE RECOVERY
							Globals.char_state.GROUND_C_RECOVERY:
								if command_array_num == 0 and "no_c_rec" in UniqChar.COMMANDS[current_command]:
									return # some animations cannot be done during C_RECOVERY
							
					else: # animation is in the air
						if grounded: # attempted to do air animation on ground, default decision
							UniqChar.decision()
							return
							
						match new_state:
							Globals.char_state.AIR_ATK_RECOVERY: # chaining
								if command_array_num == 0: return
								else: chaining = true
							Globals.char_state.AIR_D_RECOVERY:
								if command_array_num == 0 and \
										("no_c_rec" in UniqChar.COMMANDS[current_command] or "no_move_rec" in UniqChar.COMMANDS[current_command]):
									return # some animations cannot be done during MOVE RECOVERY
							Globals.char_state.AIR_C_RECOVERY:
								if command_array_num == 0 and "no_c_rec" in UniqChar.COMMANDS[current_command]:
									return # some animations cannot be done during C_RECOVERY
					
					if !chaining:
						if "dir" in UniqChar.COMMANDS[current_command]:
							match UniqChar.COMMANDS[current_command].dir:
								1, -1:
									face(UniqChar.COMMANDS[current_command].dir)
								"retreat":
									face(-get_opponent_dir())
						else: # towards targeted player
							face_opponent()
					else:
						afterimage_cancel()
							
					if anim != "":
						animate(anim)
					if is_array:
						command_array_num += 1
						if command_array_num >= UniqChar.COMMANDS[current_command].anim.size():
							pass # next command
						else:
							return
							
					if "next" in UniqChar.COMMANDS[current_command]:
						start_command(UniqChar.COMMANDS[current_command].next)
					elif "decision" in UniqChar.COMMANDS[current_command]:
						if !UniqChar.decision(UniqChar.COMMANDS[current_command].decision):
							UniqChar.decision()
					else:
						UniqChar.decision()
							
						
func is_ground_anim(anim): # for AI commands
	match state_detect(anim):
		Globals.char_state.GROUND_ATK_STARTUP, Globals.char_state.GROUND_STARTUP:
			return true
	return false
		
func is_passive():
	if Globals.difficulty == 3: return false
#	if !$RageTimer.is_running() and !Globals.mob_attr.RAGE in mob_attr:
	if !Globals.mob_attr.RAGE in mob_attr:
		var target = get_target()
		if target == self or target.get_target() != self:
			if Globals.Game.LevelControl.get_living_player_count() > 1 and \
					Globals.Game.get_player_node(0).target_ID == Globals.Game.get_player_node(1).target_ID:
				return false # if both players target the same mob, no passivity
			return true
	return false
	
		
func start_command(command: String):
	
	if is_passive():
		if get_target().is_hitstunned_or_sequenced():
			command = "idle" # will not attack if target is not attacking it and is in hitstun
		if command in UniqChar.COMMANDS and UniqChar.COMMANDS[command].action == "run":
			if Globals.Game.rng_generate(100) < 80:
				command = "idle"
		elif Globals.Game.rng_generate(100) < 50:
			command = "idle"
			
			
	current_command = command
	command_timer = 0
	command_array_num = 0
	if current_command in UniqChar.COMMANDS:
		if "style" in UniqChar.COMMANDS[current_command]:
			command_style = UniqChar.COMMANDS[current_command].style
		if "strafe" in UniqChar.COMMANDS[current_command]:
			strafe_style = UniqChar.COMMANDS[current_command].strafe
		
	# set rand_time
	if current_command in UniqChar.COMMANDS and "rand_time" in UniqChar.COMMANDS[current_command]:
		if rand_time == null:
			var time_range = UniqChar.COMMANDS[current_command].rand_time[1] - UniqChar.COMMANDS[current_command].rand_time[0]
			rand_time = Globals.Game.rng_generate(time_range) + UniqChar.COMMANDS[current_command].rand_time[0]
	else:
		rand_time = null
		
		
func advance_command():
	if !is_attacking() and rand_time != null and current_command in UniqChar.COMMANDS and "rand_time" in UniqChar.COMMANDS[current_command]:
		command_timer += 1
		if command_timer >= rand_time:
			if "next" in UniqChar.COMMANDS[current_command]:
				start_command(UniqChar.COMMANDS[current_command].next)
			elif "decision" in UniqChar.COMMANDS[current_command]:
				if !UniqChar.decision(UniqChar.COMMANDS[current_command].decision):
					UniqChar.decision()
			else:
				UniqChar.decision()
			command_timer = 0

func learn():
	if is_atk_recovery():
		return
	if grounded:
		no_jump_chance -= LEARN_RATE
	else:
		no_jump_chance += LEARN_RATE
		
	no_jump_chance = int(clamp(no_jump_chance, 0, 100))
	
func long_fail():
	$LongFailTimer.time = LongFailTimer_TIME

# STAT MODS --------------------------------------------------------------------------------------------------	

func mob_level_to_tier():
	match mob_level:
		0, 1, 2:
			return 0
		3, 4, 5:
			return 1
		6, 7, 8:
			return 2
			
func hp_left_to_tier():
	var dmg_percent = get_damage_percent()
	if dmg_percent < 25:
		return 0
	elif dmg_percent < 50:
		return 1
	elif dmg_percent < 75:
		return 2
	else:
		return 3

func modify_stat(to_return, attr: int, values: Array):
	return FMath.percent(to_return, values[int(clamp(mob_attr[attr], 0, values.size() - 1))])
	
func get_stat(stat):
	var to_return
	
	if stat in self:
		to_return = get(stat)
	elif stat in UniqChar:
		to_return = UniqChar.get_stat(stat)
		
	if stat == "SPEED": to_return = FMath.percent(to_return, get_stat("SPEED_MOD"))
	
	match stat: # status effects
		"SPEED_MOD":
			var mod = query_status_effect_aux(Globals.status_effect.CHILL)
			if mod != null:
				to_return = FMath.percent(to_return, mod)
		"GRAVITY_MOD":
			var mod = query_status_effect_aux(Globals.status_effect.GRAVITIZE)
			if mod != null:
				to_return = FMath.percent(to_return, mod)
		
	match stat: # increase stats as level raise
		"SPEED_MOD":
			if Globals.difficulty == 3:
				to_return = FMath.percent(to_return, MOB_LEVEL_TO_SPEED[8] + 20)
			else:
				to_return = FMath.percent(to_return, MOB_LEVEL_TO_SPEED[mob_level])
		"DAMAGE_VALUE_LIMIT":
			to_return = FMath.percent(to_return, MOB_LEVEL_TO_HP[mob_level])
		"GUARD_GAUGE_SWELL_RATE":
			if Globals.difficulty == 3:
				to_return = FMath.percent(to_return, 175)
			else:
				var mob_level_values = [100, 125, 150]
				to_return = FMath.percent(to_return, mob_level_values[mob_level_to_tier()])
			
			var hp_left_values = [125, 100, 75, 50] # remaining HP affects Guard Swell
			to_return = FMath.percent(to_return, hp_left_values[hp_left_to_tier()])
			
			# combo level affects Guard Swell
			to_return = FMath.percent(to_return, COMBO_LEVEL_TO_GUARD_SWELL_MOD[combo_level])
		"GUARD_DRAIN_MOD":
			if Globals.difficulty == 3:
				to_return = FMath.percent(to_return, 50)
			else:		
				var mob_level_values = [125, 100, 75]
				to_return = FMath.percent(to_return, mob_level_values[mob_level_to_tier()])
		
	if Globals.difficulty == 3: # increased stats for hardest mode
		match stat:
			"GUARD_DRAIN_MOD":
				to_return = FMath.percent(to_return, 70)
#			"DAMAGE_VALUE_LIMIT", "GUARD_GAUGE_SWELL_RATE":
#				to_return = FMath.percent(to_return, 150)
			"ARMOR_TIME":
				to_return = FMath.percent(to_return, 300)
			"DAMAGE_VALUE_LIMIT":
				to_return = FMath.percent(to_return, 130)
			"GG_REGEN_AMOUNT":
				to_return = FMath.percent(to_return, 125)
			
	if Globals.player_count > 1: # increased stats for 2 players
		match stat:
			"GUARD_DRAIN_MOD":
				to_return = FMath.percent(to_return, 70)
#			"DAMAGE_VALUE_LIMIT", "GUARD_GAUGE_SWELL_RATE":
#				to_return = FMath.percent(to_return, 150)
			"ARMOR_TIME":
				to_return = FMath.percent(to_return, 300)
			"DAMAGE_VALUE_LIMIT":
				to_return = FMath.percent(to_return, 175)
	
	if Globals.mob_attr.TOUGH in mob_attr:
		match stat:
			"GUARD_GAUGE_SWELL_RATE":
				to_return = modify_stat(to_return, Globals.mob_attr.TOUGH, [50, 75, 115, 130, 145, 160])
			"ARMOR_TIME":
				to_return = modify_stat(to_return, Globals.mob_attr.TOUGH, [50, 75, 125, 150, 175, 200])
			"ARMOR_DMG_MOD":
				to_return = modify_stat(to_return, Globals.mob_attr.TOUGH, [150, 125, 75, 50, 25, 1])
			"GUARD_DRAIN_MOD":
				to_return = modify_stat(to_return, Globals.mob_attr.TOUGH, [140, 120, 90, 80, 70, 60])
			"GG_REGEN_AMOUNT":
				to_return = modify_stat(to_return, Globals.mob_attr.TOUGH, [0, 50, 110, 120, 130, 140])
#			"ARMOR_KNOCKBACK_MOD":
#				to_return = modify_stat(to_return, Globals.mob_attr.TOUGH, [75, 50, 25, 1])
	if Globals.mob_attr.SPEED in mob_attr:
		match stat:
			"SPEED_MOD":
				to_return = modify_stat(to_return, Globals.mob_attr.SPEED, [60, 80, 120, 140, 160, 180, 200])
	if Globals.mob_attr.HP in mob_attr:
		match stat:
			"DAMAGE_VALUE_LIMIT":
				if mob_attr[Globals.mob_attr.HP] == 0:
					return 1
				to_return = modify_stat(to_return, Globals.mob_attr.HP, [1, 50, 150, 200, 250, 300])
#	if Globals.mob_attr.GDRAIN in mob_attr:
#		match stat:
#			"GUARD_DRAIN_MOD":
#				to_return = modify_stat(to_return, Globals.mob_attr.GDRAIN, [999, 130, 120, 110, 90, 80, 70])
#
#	match stat: # limits
#		"SPEED_MOD":
#			to_return = int(max(to_return, 50))
				
	return to_return
	
func has_trait(trait: int) -> bool:
	if trait in UniqChar.query_traits():
		return true
		
	return false
	
	

func loot_drop():
	if Globals.difficulty == 3: return
	
	var loot_array = UniqChar.generate_loot()
	
	if Globals.mob_attr.COIN in mob_attr:
		for x in min(mob_attr[Globals.mob_attr.COIN], Globals.Game.LevelControl.ITEM_LIMIT):
			loot_array.append("Coin")
	
	if target_ID >= 0:
		var coin_change = Inventory.modifier(target_ID, Cards.effect_ref.COIN_GAIN)
		if coin_change > 0:
			for x in coin_change:
				loot_array.append("Coin")
	
	var angle_segment = int((LOOT_ANGLE_RANGE[1] - LOOT_ANGLE_RANGE[0]) / (loot_array.size() + 1))
	var angle = LOOT_ANGLE_RANGE[0] + angle_segment
	
	for loot in loot_array:
		var speed = Globals.Game.rng_range(LOOT_UNSCALED_SPEED_RANGE[0], LOOT_UNSCALED_SPEED_RANGE[1]) * FMath.S
				
#		var angle = LOOT_ANGLE_RANGE[0] + Globals.Game.rng_generate(LOOT_ANGLE_RANGE[1] - LOOT_ANGLE_RANGE[0])
		Globals.Game.LevelControl.spawn_item(loot, position, {"vel_array" : [speed, angle]})
		angle += angle_segment
		

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
		"JumpTransit", "DashTransit":
			return Globals.char_state.GROUND_STARTUP
		"Dash":
			return Globals.char_state.GROUND_D_RECOVERY
		"SoftLanding":
			return Globals.char_state.GROUND_RECOVERY
		"DashBrake":
			return Globals.char_state.GROUND_C_RECOVERY
			
		"JumpTransit3", "Jump", "FallTransit", "Fall":
			return Globals.char_state.AIR_STANDBY
		"JumpTransit2", "aDashTransit":
			return Globals.char_state.AIR_STARTUP
			
		"aDash", "aDashD", "aDashU", "aDashDD", "aDashUU":
			return Globals.char_state.AIR_D_RECOVERY
		"aDashBrake":
			return Globals.char_state.AIR_C_RECOVERY
			
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
			
		"ResistA", "ResistB":
			return Globals.char_state.GROUND_RESISTED_HITSTUN
		"aResistA", "aResistB":
			return Globals.char_state.AIR_RESISTED_HITSTUN
		
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
			
		"Death":
			return Globals.char_state.DEAD
			
			
		_: # unique animations
			return UniqChar.state_detect(anim)
			
	
# ---------------------------------------------------------------------------------------------------

#func on_kill():
#
#	if UniqChar.has_method("on_kill"): # for unique_data changes on death
#		UniqChar.on_kill()
			
func face(in_dir):
	facing = in_dir
	sprite.scale.x = facing
	sfx_over.scale.x = facing
	sfx_under.scale.x = facing
	
func face_opponent():
	if facing != get_opponent_dir():
		face(-facing)
		
func face_away_from_opponent():
	if facing == get_opponent_dir():
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
	
	
func is_opponent_crossing_mob():
	if get_opponent_v_dir() == -1 and get_opponent_y_dist() > 64 and get_opponent_x_dist() < 64:
		return true
	return false
	
	
func target_closest():
	if Globals.player_count > 1:
		var alive_players := []
		
		var player_1 = Globals.Game.get_player_node(0)
		if player_1.state != Globals.char_state.DEAD:
			alive_players.append(player_1)
		var player_2 = Globals.Game.get_player_node(1)
		if player_2.state != Globals.char_state.DEAD:
			alive_players.append(player_2)
			
		if alive_players.size() == 0:
			target_ID = player_ID
		elif alive_players.size() == 1:
			target_ID = alive_players[0].player_ID
		else:
			if abs(player_1.position.x - position.x) < abs(player_2.position.x - position.x):
				target_ID = 0
			else:
				target_ID = 1
				
	
func is_at_corners():
	var dir_to_target = get_opponent_dir()
	match dir_to_target:
		1: # target on right side
			if position.x < Globals.Game.left_corner:
				return true
		-1:
			if position.x > Globals.Game.right_corner:
				return true
	return false
	
func are_players_in_box(origin: Vector2, size:Vector2) -> bool:
	origin.x = origin.x * facing
	origin = position + origin
	var left_bound = origin.x - int(size.x/2)
	var right_bound = origin.x + int(size.x/2)
	var top_bound = origin.y - int(size.y/2)
	var bottom_bound = origin.y + int(size.y/2)

	for player in get_alive_players():
		if player.position.x >= left_bound and player.position.x <= right_bound and \
				player.position.y <= bottom_bound and player.position.y >= top_bound:
			return true
	return false
	
			
func get_alive_players() -> Array:
	var players = []
	var player_1 = Globals.Game.get_player_node(0)
	if player_1.state != Globals.char_state.DEAD:
		players.append(player_1)
	if Globals.player_count == 2:
		var player_2 = Globals.Game.get_player_node(1)
		if player_2.state != Globals.char_state.DEAD:
			players.append(player_2)
	return players
	
	
func check_drop():
	if seq_partner_ID != null: return # no checking during start of sequence
	match new_state:
		Globals.char_state.GROUND_FLINCH_HITSTUN:
			match Animator.to_play_animation:
				"FlinchAStop", "FlinchA":
					animate("aFlinchA")
				"FlinchBStop", "FlinchB":
					animate("aFlinchB")
		Globals.char_state.GROUND_RESISTED_HITSTUN:
			match Animator.to_play_animation:
				"ResistA":
					animate("aResistA")
				"ResistB":
					animate("aResistB")
		_:
			animate("FallTransit")
	
func check_landing(): # called by physics.gd when character stopped by floor
	if seq_partner_ID != null: return # no checking during start of sequence
	match new_state:
		Globals.char_state.AIR_STANDBY:
			animate("SoftLanding")
			
		Globals.char_state.AIR_RESISTED_HITSTUN:
			match Animator.to_play_animation:
				"aResistA":
					animate("ResistA")
				"aResistB":
					animate("ResistB")
			if velocity_previous_frame.y > 300 * FMath.S:
				UniqChar.landing_sound() # only make landing sound if landed fast enough, or very annoying

		Globals.char_state.AIR_FLINCH_HITSTUN: # land during hitstun
			Globals.Game.spawn_SFX("LandDust", "DustClouds", get_feet_pos(), {"facing":facing, "grounded":true})
			match Animator.to_play_animation:
				"aFlinchAStop", "aFlinchA":
					animate("FlinchA")
				"aFlinchBStop", "aFlinchB":
					animate("FlinchB")
			if velocity_previous_frame.y > 300 * FMath.S:
				UniqChar.landing_sound() # only make landing sound if landed fast enough, or very annoying
			
		Globals.char_state.LAUNCHED_HITSTUN: # land during launch_hitstun, can bounce or tech land
			if new_state == Globals.char_state.LAUNCHED_HITSTUN:
				# need to use new_state to prevent an issue with grounded Break state causing HardLanding on flinch
				# check using either velocity this frame or last frame
					
				var vector_to_check
				if velocity.is_longer_than_another(velocity_previous_frame):
					vector_to_check = velocity
				else:
					vector_to_check = velocity_previous_frame
				
				if !vector_to_check.is_longer_than(TECHLAND_THRESHOLD):
					animate("SoftLanding")
					$HitStunTimer.stop()
					velocity.y = 0 # stop bouncing
#					modulate_play("unflinch_flash")
#					play_audio("bling4", {"vol" : -15, "bus" : "PitchDown"})
			


func check_collidable(): # called by Physics.gd
	match new_state:
		Globals.char_state.DEAD, Globals.char_state.SEQUENCE_TARGET, Globals.char_state.SEQUENCE_USER:
			return false
			
	return UniqChar.check_collidable()
	
func check_fallthrough(): # during aerials, can drop through platforms if down is held
	return false
	
func check_semi_invuln():
	return false	
	
func check_passthrough():
	if state == Globals.char_state.SEQUENCE_USER:
		return UniqChar.sequence_passthrough() # for cinematic supers
	elif state == Globals.char_state.SEQUENCE_TARGET:
		return get_target().sequence_partner_passthrough() # get passthrough state from the one grabbing you
	return false
		
func sequence_partner_passthrough():
	return UniqChar.sequence_partner_passthrough()
		
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
		sprite.material.shader = Loader.monochrome_shader

# particle emitter, visuals only, no need fixed-point
func particle(anim: String, sfx_ref: String, palette: String, interval, number, radius, v_mirror_rand = false):
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
			Globals.Game.spawn_SFX(anim, sfx_ref, particle_pos, aux_data, palette)
		
		
func flashes():
	if $ArmorTimer.is_running():
		modulate_play("mob_armor_time")

	if Globals.mob_attr.PASSIVE_ARMOR in mob_attr and get_guard_gauge_percent_below() >= 75:
		modulate_play("passive_armor")

	UniqChar.unique_flash()
				
		
#func get_spritesheet():
#	pass
			
func process_afterimage_trail():# process afterimage trail
	# Character.afterimage_trail() can accept 2 parameters, 1st is the starting modulate, 2nd is the lifetime
	
	# afterimage trail for certain modulate animations with the key "afterimage_trail"
	if NSAnims.modulate_animations.has($ModulatePlayer.current_animation) and \
		NSAnims.modulate_animations[$ModulatePlayer.current_animation].has("afterimage_trail") and \
		$ModulatePlayer.is_playing():
		# basic afterimage trail for "afterimage_trail" = 0
		if NSAnims.modulate_animations[$ModulatePlayer.current_animation]["afterimage_trail"] == 0:
			afterimage_trail()
			return
			
	UniqChar.afterimage_trail()
			
			
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
		
#func spawn_afterimage(master_ID: int, is_entity: bool, master_ref: String, spritesheet_ref: String, sprite_node_path: NodePath, palette_ref, color_modulate = null, \
#		starting_modulate_a = 0.5, lifetime = 10, afterimage_shader = Globals.afterimage_shader.MASTER):
		
		if sfx_under.visible:
			Globals.Game.spawn_afterimage(player_ID, false, mob_ref, sprite_texture_ref.sfx_under, sfx_under.get_path(), palette_ref, \
					main_color_modulate, starting_modulate_a, lifetime, afterimage_shader)

		Globals.Game.spawn_afterimage(player_ID, false, mob_ref, sprite_texture_ref.sprite, sprite.get_path(), palette_ref, \
				main_color_modulate, starting_modulate_a, lifetime, afterimage_shader)
		
		if sfx_over.visible:
			Globals.Game.spawn_afterimage(player_ID, false, mob_ref, sprite_texture_ref.sfx_over, sfx_over.get_path(), palette_ref, \
					main_color_modulate, starting_modulate_a, lifetime, afterimage_shader)
					
	else:
		afterimage_timer -= 1
		
		
func afterimage_cancel(starting_modulate_a = 0.5, lifetime: int = 12): # no need color_modulate for now
	
	if sfx_under.visible:
		Globals.Game.spawn_afterimage(player_ID, false, mob_ref, sprite_texture_ref.sfx_under, sfx_under.get_path(), palette_ref, null, \
				starting_modulate_a, lifetime, Globals.afterimage_shader.MASTER)
		
	Globals.Game.spawn_afterimage(player_ID, false, mob_ref, sprite_texture_ref.sprite, sprite.get_path(), palette_ref, null, \
			starting_modulate_a, lifetime, Globals.afterimage_shader.MASTER)
	
	if sfx_over.visible:
		Globals.Game.spawn_afterimage(player_ID, false, mob_ref, sprite_texture_ref.sfx_over, sfx_over.get_path(), palette_ref, null, \
				starting_modulate_a, lifetime, Globals.afterimage_shader.MASTER)
	
		
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
		
func death_anim():
	modulate_play("crush")
	if Animator.time > 9:
		if posmod(Globals.Game.frametime, 5) == 0:
			play_audio("kill2", {"vol": -5, "bus": "LowPass"})
		particle("Killburst", "Particles", "red", 5, 1, 35, true)
	sprite_shake()
			
	
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
	
func is_hitstunned_or_sequenced():
	match state: # use non-new state
		Globals.char_state.AIR_FLINCH_HITSTUN, Globals.char_state.GROUND_FLINCH_HITSTUN, Globals.char_state.LAUNCHED_HITSTUN, \
				Globals.char_state.SEQUENCE_TARGET:
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
			
func is_special_move(move_name):
	match query_move_data(move_name).atk_type:
		Globals.atk_type.SPECIAL, Globals.atk_type.SUPER, Globals.atk_type.EX:
			return true
	return false

func can_air_strafe(move_data):
	if move_data.atk_type in [Globals.atk_type.LIGHT, Globals.atk_type.FIERCE, Globals.atk_type.HEAVY]: # Normal
		if Globals.atk_attr.NO_STRAFE_NORMAL in move_data.atk_attr:
			return false # cannot strafe during some aerial normals
	else: # non-Normal
		if !Globals.atk_attr.STRAFE_NON_NORMAL in move_data.atk_attr:
			return false # can strafe during some aerial non-normals
	return true

# STATUS EFFECTS ---------------------------------------------------------------------------------------------------
	# rule: status_effect is array contain [effect, lifetime], effect can be a Globals.status_effect enum or a string
	
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
			_:
				pass

		
func new_status_effect(effect): # run on frame the status effect is inflicted/state is loaded, for visual effects
	match effect:
		Globals.status_effect.LETHAL:
			Globals.Game.lethalfreeze(get_path())
		
func continue_visual_effect_of_status(effect): # run every frame, will not add visual effect if there is already one of higher priority
	match effect:
		Globals.status_effect.POISON:
			modulate_play("poison")
			particle("Mote", "Particles", "purple", 4, 1, 25)
		Globals.status_effect.CHILL:
			modulate_play("freeze")
			particle("Mote", "Particles", "blue", 4, 1, 25)
		Globals.status_effect.IGNITE:
			modulate_play("ignite")
			particle("Mote", "Particles", "yellow", 4, 1, 25)
		Globals.status_effect.GRAVITIZE:
			modulate_play("gravitize")
		Globals.status_effect.ENFEEBLE:
			modulate_play("enfeeble")
#		Globals.status_effect.LETHAL:
#			if !$ModulatePlayer.playing or !$ModulatePlayer.query(["lethal", "lethal_flash"]):
#				modulate_play("lethal")
#			set_monochrome()
#			sprite_shake()
#		Globals.status_effect.CRUSH:
#			if !$ModulatePlayer.playing or !$ModulatePlayer.query(["crush", "stun_flash"]):
#				modulate_play("crush")
#			particle("Sparkle", "Particles", "red", 4, 1, 25)
#			set_monochrome() # you want to do shaders here instead of new_status_effect() since shaders can be changed
#			sprite_shake()

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
	status_effect_to_remove.append(Globals.status_effect.POISON)
#	status_effect_to_remove.append(Globals.status_effect.CHILL)
	status_effect_to_remove.append(Globals.status_effect.IGNITE)
#	status_effect_to_remove.append(Globals.status_effect.GRAVITIZE)
	
func remove_status_effect_on_taking_hit():
	pass
		
func clear_visual_effect_of_status(effect): # must run this when removing status effects to remove the visual effect
	match effect:
		_:
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
				
func timed_status():
	for status_effect in status_effects:
		match status_effect[0]:
			
			Globals.status_effect.POISON:
				if posmod(status_effect[1], 30) == 1:
					var damage = int(min(status_effect[2], get_stat("DAMAGE_VALUE_LIMIT") - current_damage_value - 1))
					if damage > 0:
						take_damage(damage)
						Globals.Game.spawn_damage_number(damage, position, Globals.dmg_num_col.GRAY)
						
			Globals.status_effect.IGNITE:
				if posmod(status_effect[1], 30) == 15:
					var damage = int(min(status_effect[2], get_stat("DAMAGE_VALUE_LIMIT") - current_damage_value - 1))
					if damage > 0:
						take_damage(damage)
						Globals.Game.spawn_damage_number(damage, position, Globals.dmg_num_col.GRAY)
	
# HIT DETECTION AND PROCESSING ---------------------------------------------------------------------------------------------------

func query_polygons(): # requested by main game node when doing hit detection
	
	var polygons_queried = {
		"rect" : null,
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
#			polygons_queried.sdhurtbox = Animator.query_polygon("sdhurtbox")
			
#		if query_status_effect(Globals.status_effect.RESPAWN_GRACE):
#			pass  # no hurtbox during respawn grace or after a strongblock/parry
#		else:
		polygons_queried.hurtbox = Animator.query_polygon("hurtbox")
		polygons_queried.rect = get_sprite_rect()

	return polygons_queried
	
func get_sprite_rect():
	var sprite_rect = sprite.get_rect()
	return Rect2(sprite_rect.position + position, sprite_rect.size)
	
func query_move_data_and_name(): # requested by main game node when doing hit detection
	
	if Animator.to_play_animation.ends_with("Active"):
		var move_name = Animator.to_play_animation.trim_suffix("Active")
		move_name = UniqChar.refine_move_name(move_name)
		if UniqChar.MOVE_DATABASE.has(move_name):
			return {"move_data" : UniqChar.query_move_data(move_name), "move_name" : move_name}
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
	return FMath.get_fraction_percent(current_damage_value, get_stat("DAMAGE_VALUE_LIMIT"))
	
func get_guard_gauge_percent_below() -> int:
	if current_guard_gauge <= GUARD_GAUGE_FLOOR:
		return 0
	elif current_guard_gauge < 0:
		return 100 - FMath.get_fraction_percent(current_guard_gauge, GUARD_GAUGE_FLOOR)
	else: return 100
		
func take_damage(damage: int): # called by attacker
	current_damage_value += damage
#	current_damage_value = int(clamp(current_damage_value, 0, 9999)) # cannot go under zero (take_damage is also used for healing)
	damage_update()
	
func change_guard_gauge(guard_gauge_change: int): # called by attacker
	current_guard_gauge += guard_gauge_change
	current_guard_gauge = int(clamp(current_guard_gauge, GUARD_GAUGE_FLOOR, 0))
	guard_gauge_update()
	
func reset_guard_gauge():
	current_guard_gauge = 0
	guard_gauge_update()
	

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
	var move_name = Animator.current_animation.trim_suffix("Startup")
	move_name = move_name.trim_suffix("Active")
	move_name = move_name.trim_suffix("Rec")
	return UniqChar.query_atk_attr(move_name)
	
	
func query_priority(in_move_name = null):
	var move_name = in_move_name
	if move_name == null:
		move_name = get_move_name()
	
	var move_data = UniqChar.query_move_data(move_name)
	if !"atk_type" in move_data: return 0 # just in case
	
	var priority: int
	match move_data.atk_type:
		Globals.atk_type.LIGHT:
			if grounded:
				priority = Globals.priority.gL
			else:
				priority = Globals.priority.aL
		Globals.atk_type.FIERCE:
			if grounded:
				priority = Globals.priority.gF
			else:
				priority = Globals.priority.aF
		Globals.atk_type.HEAVY:
			if grounded:
				priority = Globals.priority.gH
			else:
				priority = Globals.priority.aH
		Globals.atk_type.SPECIAL:
			if grounded:
				priority = Globals.priority.gSp
			else:
				priority = Globals.priority.aSp
		Globals.atk_type.EX:
			if grounded:
				priority = Globals.priority.gEX
			else:
				priority = Globals.priority.aEX
		Globals.atk_type.SUPER:
			priority = Globals.priority.SUPER
				
	if "priority_add" in move_data:
		return priority + move_data.priority_add
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
	
	var defender = Globals.Game.get_player_node(hit_data.defender_ID)
	if defender == null:
		return # defender is deleted
	increment_hitcount(hit_data.defender_ID) # for measuring hitcount of attacks
	
	match hit_data.block_state:
		Globals.block_state.UNBLOCKED:
			remove_status_effect_on_landing_hit()
	
	# ATTACKER HITSTOP ----------------------------------------------------------------------------------------------
		# hitstop is only set into HitStopTimer at end of frame
	
	if "fixed_atker_hitstop" in hit_data.move_data:
		# multi-hit special/super moves are done by having lower atker hitstop then defender hitstop, and high "hitcount" and ignore_time
		hitstop = hit_data.move_data.fixed_atker_hitstop
		
	elif hit_data.stun:
		if hitstop == null or hit_data.hitstop > hitstop:
			hitstop = STUN_HITSTOP_ATTACKER # fixed hitstop for attacking for Break Hits
			
	elif hit_data.lethal_hit:
		hitstop = null # no hitstop for mob attacker for lethal hit, screenfreeze already enough
		
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

	var attacker = Globals.Game.get_player_node(hit_data.attacker_ID)
#	var defender = get_node(hit_data.defender_nodepath)
	
	var attacker_or_entity = attacker # cleaner code
	if "entity_nodepath" in hit_data:
		attacker_or_entity = get_node(hit_data.entity_nodepath)

	if attacker_or_entity == null:
		hit_data["cancelled"] = true
		return # attacked by something that is already deleted, return

	hit_data["attacker"] = attacker # for other functions
	hit_data["attacker_or_entity"] = attacker_or_entity

	attacker.target_ID = player_ID # attacker target defender
	target_ID = attacker.player_ID # target opponent who last attacked you
	
	remove_status_effect(Globals.status_effect.CRUSH)
	$HitStopTimer.stop() # cancel pre-existing hitstop
#	$RageTimer.time = RageTimer_TIME
	
	# get direction to attacker
	var vec_to_attacker: Vector2 = attacker_or_entity.position - position
	if vec_to_attacker.x == 0: # rare case of attacker directly on defender
		vec_to_attacker.x = -attacker_or_entity.facing
	var dir_to_attacker := int(sign(vec_to_attacker.x)) # for setting facing on defender
		
	var attacker_vec := FVector.new()
	attacker_vec.set_from_vec(vec_to_attacker)
	
	hit_data["angle_to_atker"] = attacker_vec.angle()
	hit_data["lethal_hit"] = false
	hit_data["punish_hit"] = false
	hit_data["stun"] = false
	hit_data["crush"] = false
	hit_data["block_state"] = Globals.block_state.UNBLOCKED
	hit_data["repeat"] = false
	hit_data["double_repeat"] = false
	
	if !attacker_or_entity.is_hitcount_last_hit(player_ID, hit_data.move_data):
		hit_data["multihit"] = true
		if attacker_or_entity.is_hitcount_first_hit(player_ID):
			hit_data["first_hit"] = true
	if Globals.atk_attr.AUTOCHAIN in hit_data.move_data.atk_attr:
		hit_data["autochain"] = true
	if Globals.atk_attr.FOLLOW_UP in hit_data.move_data.atk_attr:
		hit_data["follow_up"] = true
		
	if "entity_nodepath" in hit_data and "proj_level" in hit_data.move_data and hit_data.move_data.proj_level != 3:
		hit_data["non_strong_proj"] = true
		
	if hit_data.move_data.atk_type in [Globals.atk_type.LIGHT, Globals.atk_type.FIERCE] or "non_strong_proj" in hit_data:
		hit_data["normalarmorable"] = true
	
	# some multi-hit moves only hit once every few frames, done via an ignore list on the attacker/entity
	if "multihit" in hit_data and "ignore_time" in hit_data.move_data:
		attacker_or_entity.append_ignore_list(player_ID, hit_data.move_data.ignore_time)
		
	if hit_data.move_data.atk_type in [Globals.atk_type.EX, Globals.atk_type.SUPER] or \
			("proj_level" in hit_data.move_data and hit_data.move_data.proj_level >= 3):
		hit_data["ignore_resist"] = true
	
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
		
		if !Inventory.has_quirk(hit_data.attacker_ID, Cards.effect_ref.CAN_REPEAT):
		
			for array in repeat_memory:
				if array[0] == hit_data.attacker_ID and array[1] == root_move_name:
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
				repeat_memory.append([attacker.player_ID, root_move_name])
	
	
	
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


	if !Globals.atk_attr.UNBLOCKABLE in hit_data.move_data.atk_attr:
		match new_state:
			
			# SUPERARMOR --------------------------------------------------------------------------------------------------
			
			# WEAK block_state
			# attacker can chain combo normally after hitting an armored defender
			
			Globals.char_state.GROUND_ATK_STARTUP, Globals.char_state.AIR_ATK_STARTUP: # can sweetspot superarmor
				if Globals.atk_attr.SUPERARMOR_STARTUP in query_atk_attr() or \
						(Globals.atk_attr.NORMALARMOR_STARTUP in query_atk_attr() and "normalarmorable" in hit_data):
#					hit_data.block_state = Globals.block_state.WEAK
					hit_data["superarmored"] = true
					
			Globals.char_state.GROUND_ATK_ACTIVE, Globals.char_state.AIR_ATK_ACTIVE:
				if Globals.atk_attr.SUPERARMOR_ACTIVE in query_atk_attr() or \
						(Globals.atk_attr.NORMALARMOR_ACTIVE in query_atk_attr() and "normalarmorable" in hit_data) or \
						(Globals.atk_attr.PROJ_ARMOR_ACTIVE in query_atk_attr() and "entity_nodepath" in hit_data):
#					hit_data.block_state = Globals.block_state.WEAK
					hit_data["superarmored"] = true
						
						
			Globals.char_state.AIR_RECOVERY:
				 # air superdash has projectile superarmor against non-strong projectiles
				if Animator.query_current(["SDash"]) and "non_strong_proj" in hit_data:
#					hit_data.block_state = Globals.block_state.WEAK
					hit_data["superarmored"] = true
					
		if !is_hitstunned_or_sequenced():
			if Globals.mob_attr.PASSIVE_ARMOR in mob_attr:
				if current_guard_gauge >= 0:
#					hit_data.block_state = Globals.block_state.WEAK
					hit_data["superarmored"] = true
					
	# RESISTED HIT ----------------------------------------------------------------------------------------------
	
	if "superarmored" in hit_data:
		hit_data["resisted"] = true
	elif "ignore_resist" in hit_data:
		pass # true hitstun
	elif current_guard_gauge == GUARD_GAUGE_FLOOR:
		pass # true hitstun
	elif $ArmorTimer.is_running() or $HitStunTimer.is_running():
		pass # mob_armored or already in hitstun
	elif is_atk_active() or is_atk_recovery():
		pass # true hitstun
	elif Globals.mob_attr.TOUGH in mob_attr and mob_attr[Globals.mob_attr.TOUGH] <= 1:
		pass # true hitstun
	elif "atk_level" in hit_data and hit_data.move_data.atk_level <= 1:
		pass # no hitstun
	else:
		hit_data["resisted"] = true
#		if !"multihit" in hit_data and !"autochain" in hit_data and \
#				state in [Globals.char_state.GROUND_RECOVERY, Globals.char_state.AIR_RECOVERY] and \
#				Animator.query_current(["ResistA", "ResistB", "aResistA", "aResistB"]):
#			$ArmorTimer.time = ARMOR_TIME # gain armor if hit during Resisted Hitstun
##				else:
##					$ResistTimer.time = ResistTimer_TIME
		
	# ZEROTH REACTION (before damage) ---------------------------------------------------------------------------------
	
	# unique reactions
	if "entity_nodepath" in hit_data:
		if attacker_or_entity.UniqEntity.has_method("landed_a_hit0"):
			attacker_or_entity.UniqEntity.landed_a_hit0(hit_data) # reaction, can change hit_data from there
	elif attacker.UniqChar.has_method("landed_a_hit0"):
		attacker.UniqChar.landed_a_hit0(hit_data) # reaction, can change hit_data from there
	
	if UniqChar.has_method("being_hit0"):	
		UniqChar.being_hit0(hit_data) # reaction, can change hit_data from there
			
	# DAMAGE AND GUARD DRAIN/GAIN CALCULATION ------------------------------------------------------------------
	
	# attack level
	var adjusted_atk_level: int = 1
	
	if !"sequence" in hit_data.move_data:
		adjusted_atk_level = adjusted_atk_level(hit_data)
		hit_data["adjusted_atk_level"] = adjusted_atk_level
		
		if !guardbroken:
			change_guard_gauge(calculate_guard_gauge_change(hit_data)) # do GG calculation
			if get_guard_gauge_percent_below() == 0:
				hit_data["mob_break"] = true
				hit_data.erase("superarmored")
				$ArmorTimer.time = 0
				guardbroken = true
#				repeat_memory = [] # reset move memory for getting a Break
				play_audio("rock2", {"vol" : -10}) # do these here for hitgrabs
				Globals.Game.spawn_SFX("Crushspark", "Stunspark", hit_data.hit_center, {"facing":Globals.Game.rng_facing(), \
						"v_mirror":Globals.Game.rng_bool()})
		
		var damage = calculate_damage(hit_data)
		take_damage(damage) # do damage calculation
		hit_data["dealt_damage"] = damage
		if damage > 0:
			if guardbroken:
				if hit_data.double_repeat or adjusted_atk_level == 1:
					Globals.Game.spawn_damage_number(damage, position, Globals.dmg_num_col.GRAY)
				else:
					Globals.Game.spawn_damage_number(damage, hit_data.hit_center)
			else:
				Globals.Game.spawn_damage_number(damage, position, Globals.dmg_num_col.GRAY)
		
		if get_damage_percent() >= 100:
			hit_data.lethal_hit = true
			

	# FIRST REACTION ---------------------------------------------------------------------------------
	
	if has_trait(Globals.trait.NO_LAUNCH) or $ArmorTimer.is_running() or ("resisted" in hit_data and !guardbroken):
		hit_data["tough_mob"] = true
	
#	if !(Globals.mob_attr.GDRAIN in mob_attr and mob_attr[Globals.mob_attr.GDRAIN] == 0):
#		if !guardbroken: # not guardbroken mobs, hitgrabs can still connect if the hit guardbreaks them
#			if !"sequence" in hit_data.move_data:
#				hit_data["tough_mob"] = true
#			elif get_guard_gauge_percent_below() >= 50: # natural command grabs can still grab them if they have below 50% GG
#				hit_data["tough_mob"] = true

	# unique reactions
	if "entity_nodepath" in hit_data:
		if attacker_or_entity.UniqEntity.has_method("landed_a_hit"):
			attacker_or_entity.UniqEntity.landed_a_hit(hit_data) # reaction, can change hit_data from there
	elif attacker.UniqChar.has_method("landed_a_hit"):
		attacker.UniqChar.landed_a_hit(hit_data) # reaction, can change hit_data from there
	
	if UniqChar.has_method("being_hit"):	
		UniqChar.being_hit(hit_data) # reaction, can change hit_data from there
	
	# ---------------------------------------------------------------------------------
	
	if !is_hitstunned():
		learn()
		
	if adjusted_atk_level > 1 and guardbroken:
		remove_status_effect_on_taking_hit()
	
#	if "sequence" in hit_data.move_data: # hitgrabs and sweetgrabs will add sequence to move_data on sweetspot/non double repeat
#		if !hit_data.double_repeat and !"tough_mob" in hit_data:
#			attacker_or_entity.landed_a_sequence(hit_data)
#		return
		
	if "sequence" in hit_data.move_data: # hitgrabs and sweetgrabs will add sequence to move_data on sweetspot/non double repeat
		if "tough_mob" in hit_data or hit_data.double_repeat:
			return
		if Globals.atk_attr.QUICK_GRAB in hit_data.move_data.atk_attr and new_state in [Globals.char_state.GROUND_STARTUP, \
				Globals.char_state.AIR_STARTUP]:
			return # quick grabs fail if target is in movement startup
		if is_atk_startup() and Globals.atk_attr.GRAB_INVULN_STARTUP in query_atk_attr():
			return # grabs fail if target is in attack startup with an attack with GRAB_INVULN_STARTUP atk attr
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

#	if !is_hitstunned(): # first hit
#		if "entity_nodepath" in hit_data:
#			proj_only_combo = true
#		else:
#			proj_only_combo = false
#	else: # additional hits turn off proj_only_combo if not a projectile
#		if proj_only_combo and !"entity_nodepath" in hit_data:
#			proj_only_combo = false

		
	if hit_data.double_repeat:
		modulate_play("repeat")
#		add_status_effect(Globals.status_effect.REPEAT, 10)
	
	elif hit_data.lethal_hit:
		Globals.Game.set_screenshake()
		play_audio("lethal1", {"vol" : -5, "bus" : "Reverb"})
		modulate_play("stun_flash")
		if !$HitStunTimer.is_running(): # death from chip damage
			play_audio("rock2", {"vol" : -10}) # do these here for hitgrabs as well
			Globals.Game.spawn_SFX("Crushspark", "Stunspark", hit_data.hit_center, {"facing":Globals.Game.rng_facing(), \
					"v_mirror":Globals.Game.rng_bool()})
		
	elif "mob_break" in hit_data:
		modulate_play("punish_sweet_flash")
		combo_level = adjusted_atk_level - 1
		combo_level += Inventory.modifier(attacker.player_ID, Cards.effect_ref.COMBO_LEVEL)
		combo_level = int(clamp(combo_level, 0, 7))
		
	elif "superarmored" in hit_data:
		modulate_play("armor_flash")
		play_audio("block3", {"vol" : -15})
		
	elif "resisted" in hit_data:
		modulate_play("weakblock_flash")
		play_audio("block3", {"vol" : -15})
		hit_data["no_hit_sound"] = true
		
	elif !guardbroken:
		modulate_play("mob_armor_flash")
		play_audio("bling2", {"vol" : -5, "bus" : "PitchDown2"})
		hit_data["no_hit_sound"] = true
		
	elif hit_data.sweetspotted:
		modulate_play("punish_sweet_flash")
		play_audio("break2", {"vol" : -15})
		
	else:
		modulate_play("mob_hit_flash")
		
	if Globals.atk_attr.SCREEN_SHAKE in hit_data.move_data.atk_attr:
		Globals.Game.set_screenshake()
			
	
	# HITSTUN -------------------------------------------------------------------------------------------
	
	if guardbroken:
		if !hit_data.double_repeat and adjusted_atk_level <= 1 and $HitStunTimer.is_running():
			# for atk level 1 hits on hitstunned opponent, add their hitstun to existing hitstun
			$HitStunTimer.time = $HitStunTimer.time + calculate_hitstun(hit_data)
		else:
			$HitStunTimer.time = calculate_hitstun(hit_data)
			launchstun_rotate = 0 # used to calculation sprite rotation during launched state
		if $HitStunTimer.time > 0:
			start_command("standby")
	
	# HITSTOP ---------------------------------------------------------------------------------------------------
	
	if !hit_data.lethal_hit:
		hitstop = calculate_hitstop(hit_data, knockback_strength)
	else:
		hitstop = LETHAL_HITSTOP # set for defender, attacker has no hitstop during LETHAL_HITSTOP
								# screenfreeze for everyone but the defender till their hitstop is over
		
	if !hit_data.lethal_hit and "mob_break" in hit_data:
		hitstop = FMath.percent(hitstop, MOB_BREAK_HITSTOP_MOD)
		
	hit_data["hitstop"] = hitstop # send this to attacker as well
#	if !guardbroken and !hit_data.lethal_hit and !hit_data.weak_hit and !"autochain" in hit_data:
#		hitstop += 10 # extra hitstop just for defender on guarded hit
#		if "entity_nodepath" in hit_data: # for projectiles as well
#			hit_data.hitstop = hitstop

	if !hit_data.lethal_hit and "resisted" in hit_data and !guardbroken and !"entity_nodepath" in hit_data and !hit_data.weak_hit:
#		if "superarmored" in hit_data:
#			hitstop += 15
#		else:
			hitstop += 10
		
	if guardbroken and !"entity_nodepath" in hit_data and !hit_data.weak_hit and !"autochain" in hit_data:
		hitstop += Inventory.modifier(hit_data.attacker_ID, Cards.effect_ref.EXTRA_HITSTOP)
		
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
	
	if UniqChar.has_method("being_hit2"):	
		UniqChar.being_hit2(hit_data) # reaction, can change hit_data from there
	
	# HITSPARK ---------------------------------------------------------------------------------------------------
	
	if !guardbroken:
		if "superarmored" in hit_data:
			Globals.Game.spawn_SFX("Superarmorspark", "Blocksparks", hit_data.hit_center, {"rot" : deg2rad(hit_data.angle_to_atker)})
		elif "resisted" in hit_data:
			Globals.Game.spawn_SFX("WBlockspark2", "Blocksparks", hit_data.hit_center, {"rot" : deg2rad(hit_data.angle_to_atker)})
		else:
			Globals.Game.spawn_SFX("MobArmorspark", "Blocksparks", hit_data.hit_center, {"rot" : deg2rad(hit_data.angle_to_atker)})
	else:
		generate_hitspark(hit_data)
	
	# ---------------------------------------------------------------------------------------------------
			
#	var knockback_unit_vec := Vector2(1, 0).rotated(knockback_dir)

	var no_impact_and_vel_change := false
	
	if "superarmored" in hit_data and !hit_data.lethal_hit:
		if grounded:
			var knock_dir := 0
			var segment = Globals.split_angle(knockback_dir, Globals.angle_split.FOUR, hit_data.attack_facing)
			match segment:
				Globals.compass.E:
					knock_dir = 1
				Globals.compass.W:
					knock_dir = -1
			if knock_dir != 0:
				move_amount(Vector2(knock_dir * 7, 0), $PlayerCollisionBox, $PlayerCollisionBox, true)
				set_true_position()
		return

	if guardbroken:
			
		# if knockback_strength is high enough, get launched, else get flinched
		if has_trait(Globals.trait.NO_LAUNCH) or knockback_strength < LAUNCH_THRESHOLD or adjusted_atk_level <= 1:

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
									
	else: # not guardbroken
		if "resisted" in hit_data and hit_data.move_data.atk_level > 1:
			
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
			
			if hit_data.hit_center.y >= position.y: # A/B depending on height hit
				if grounded:
					animate("ResistA")
				else:
					animate("aResistA")
			else:
				if grounded:
					animate("ResistB")
				else:
					animate("aResistB")
					
		else:
			hit_data["mob_armored"] = true # for attacker knockback
			if (is_atk_startup() or is_atk_active()) and is_special_move(get_move_name()):
				no_impact_and_vel_change = true # no KB if mob is doing a special move
					
					
	if !no_impact_and_vel_change:
		velocity.set_vector(knockback_strength, 0)  # reset momentum
		velocity.rotate(knockback_dir)
		
		if !guardbroken and grounded and !hit_data.lethal_hit:
			velocity.y = 0 # set to horizontal pushback on non-guardbroken grounded defender
			
	if hit_data.lethal_hit:				
		animate("Death")
		var angle: int
		if velocity.y > 0 and !grounded:
			angle = -26 # go backwards, other side
		else:
			angle = 26
		velocity.set_vector(-500 * FMath.S * facing, 0)
		velocity.rotate(angle * facing)

		
# HIT CALCULATION ---------------------------------------------------------------------------------------------------
		
func calculate_damage(hit_data) -> int:
	
	var scaled_damage: int = hit_data.move_data.damage * FMath.S
	if scaled_damage == 0: return 0
	
	if hit_data.double_repeat:
		scaled_damage = FMath.percent(scaled_damage, REPEAT_DMG_MOD)
	else:
		if hit_data.sweetspotted:
			scaled_damage = FMath.percent(scaled_damage, SWEETSPOT_DMG_MOD)
			
	if !guardbroken and !Inventory.has_quirk(hit_data.attacker_ID, Cards.effect_ref.ARMOR_PIERCE):
		scaled_damage = FMath.percent(scaled_damage, get_stat("ARMOR_DMG_MOD"))

	return int(max(FMath.round_and_descale(scaled_damage), 1)) # minimum 1 damage
	

func calculate_guard_gauge_change(hit_data) -> int:
	
	if (hit_data.move_data.hitcount > 1 and !"first_hit" in hit_data) or "follow_up" in hit_data:  
	# for multi-hit/autochain moves, only first hit affect GG
		return 0

	if guardbroken: # if guardbroken, no Guard Drain
		return 0
		
#	if "superarmored" in hit_data:
#		return 0
		
#	if "superarmored" in hit_data or ($ArmorTimer.is_running() and !"ignore_armor" in hit_data): # halves GDrain on armored
	if "superarmored" in hit_data or $ArmorTimer.is_running(): # halves GDrain on armored
		var guard_drain = -ATK_LEVEL_TO_GDRAIN[hit_data.adjusted_atk_level - 1]
		guard_drain = FMath.percent(guard_drain, get_stat("GUARD_DRAIN_MOD"))
		guard_drain = FMath.percent(guard_drain, Inventory.modifier(hit_data.attacker_ID, Cards.effect_ref.GUARD_DRAIN_MOD))
		guard_drain = FMath.percent(guard_drain, 50)
		return guard_drain
		
#	if state in [Globals.char_state.GROUND_STANDBY, Globals.char_state.AIR_STANDBY, 
#			Globals.char_state.GROUND_STARTUP, Globals.char_state.AIR_STARTUP, 
#			Globals.char_state.GROUND_RECOVERY, Globals.char_state.AIR_RECOVERY, 
#			Globals.char_state.GROUND_ATK_STARTUP, Globals.char_state.AIR_ATK_STARTUP]:
#		return 0

	if "resisted" in hit_data:
		var guard_drain = -ATK_LEVEL_TO_GDRAIN[hit_data.adjusted_atk_level - 1]
		guard_drain = FMath.percent(guard_drain, get_stat("GUARD_DRAIN_MOD"))
		guard_drain = FMath.percent(guard_drain, Inventory.modifier(hit_data.attacker_ID, Cards.effect_ref.GUARD_DRAIN_MOD))
		return guard_drain
		
	return GUARD_GAUGE_FLOOR

#	var guard_drain = -ATK_LEVEL_TO_GDRAIN[hit_data.adjusted_atk_level - 1]
#	guard_drain = FMath.percent(guard_drain, get_stat("GUARD_DRAIN_MOD"))
#
#	return guard_drain # Guard Drain on 1st hit of the combo depends on Attack Level
	
	
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
		
	# for rekkas and combo-type moves/supers, no KB boost for non-finishers
	if "autochain" in hit_data or "multihit" in hit_data:
		return knockback_strength
#	elif !guardbroken: # KB for non-guardbreak
#		knockback_strength = FMath.percent(knockback_strength, get_stat("ARMOR_KNOCKBACK_MOD"))
			
#	if "resisted" in hit_data and !guardbroken:
#		knockback_strength = FMath.percent(knockback_strength, get_stat("RESISTED_KB_MOD"))
##		if grounded:
##			knockback_strength = FMath.percent(knockback_strength, 200)
#	elif $ArmorTimer.is_running():
#		knockback_strength = FMath.percent(knockback_strength, get_stat("ARMOR_KNOCKBACK_MOD"))
#		if grounded:
#			knockback_strength = FMath.percent(knockback_strength, 200)


	if guardbroken and !hit_data.weak_hit:  # no GG KB boost for multi-hit attacks (weak hits) till the last hit
		var weight = get_guard_gauge_percent_below()
		if weight > 50:
			weight = FMath.get_fraction_percent((weight - 50), 50)
			knockback_strength = FMath.f_lerp(knockback_strength, FMath.percent(knockback_strength, get_stat("KB_BOOST_AT_MAX_GG")), \
					weight)

	if "MOB_WEIGHT_KB_MOD" in UniqChar: # mobs can have different weights
		knockback_strength = FMath.percent(knockback_strength, get_stat("MOB_WEIGHT_KB_MOD"))
	
	return knockback_strength
	
	
func calculate_knockback_dir(hit_data) -> int:
	
	var knockback_dir := 0
	var knockback_type = hit_data.move_data.knockback_type
	
	# for certain multi-hit attacks and autochain
	if "multihit" in hit_data or "autochain" in hit_data:
		
		if Globals.atk_attr.DRAG_KB in hit_data.move_data.atk_attr: # can be drag KB till the last hit
			return hit_data.attacker_or_entity.velocity.angle()
			
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
		ref_vector.set_from_vec(hit_data.hit_center - hit_data.attacker_or_entity.position)
		
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

#	if "superarmored" in hit_data:
#		return 1
	if hit_data.double_repeat:
		return 1 # double repeat is forced attack level 1
		
	var atk_level: int = hit_data.move_data.atk_level
	
	if hit_data.sweetspotted and !Globals.atk_attr.NO_SS_ATK_LVL_BOOST in hit_data.move_data.atk_attr: # sweetspotted give more hitstun
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
	if has_trait(Globals.trait.NO_LAUNCH) or hit_data.knockback_strength < LAUNCH_THRESHOLD:
#		scaled_hitstun = ATK_LEVEL_TO_F_HITSTUN[mob_level_to_tier()][hit_data.adjusted_atk_level - 1] * FMath.S
		if Globals.difficulty == 3:
			scaled_hitstun = ATK_LEVEL_TO_F_HITSTUN_H[hit_data.adjusted_atk_level - 1] * FMath.S
		else: scaled_hitstun = ATK_LEVEL_TO_F_HITSTUN[hit_data.adjusted_atk_level - 1] * FMath.S
	else:
#		scaled_hitstun = ATK_LEVEL_TO_L_HITSTUN[mob_level_to_tier()][hit_data.adjusted_atk_level - 1] * FMath.S
		if Globals.difficulty == 3:
			scaled_hitstun = ATK_LEVEL_TO_L_HITSTUN_H[hit_data.adjusted_atk_level - 1] * FMath.S
		else: scaled_hitstun = ATK_LEVEL_TO_L_HITSTUN[hit_data.adjusted_atk_level - 1] * FMath.S
		
	if guardbroken: # start scaling down when over 50% guard gauge
		var weight = get_guard_gauge_percent_below()
		if weight > 50:
			weight = FMath.get_fraction_percent((weight - 50), 50)
			scaled_hitstun = FMath.f_lerp(scaled_hitstun, FMath.percent(scaled_hitstun, HITSTUN_REDUCTION_AT_MAX_GG), weight)

#	if "mob_break" in hit_data and "entity_nodepath" in hit_data: # reduce hitstun of projectile starters
#		scaled_hitstun = FMath.percent(scaled_hitstun, 70)

	return FMath.round_and_descale(scaled_hitstun)


func calculate_hitstop(hit_data, knockback_strength: int) -> int: # hitstop determined by knockback power
		
	if "superarmored" in hit_data:
		return 7
		
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
	elif hit_data.lethal_hit or "mob_break" in hit_data:
		hitspark_level = 5 # max size for Lethal and Break
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

			
	if !"hitspark_type" in hit_data.move_data:
#		if hit_data.attacker_or_entity.has_method("get_default_hitspark_type"):
#			hit_data.move_data["hitspark_type"] = hit_data.attacker_or_entity.get_default_hitspark_type()
		if hit_data.attacker != null and hit_data.attacker.has_method("get_default_hitspark_type"):
			hit_data.move_data["hitspark_type"] = hit_data.attacker.get_default_hitspark_type()
		else:
			hit_data.move_data["hitspark_type"] = Globals.hitspark_type.HIT
			
	if !"hitspark_palette" in hit_data.move_data:
#		if hit_data.attacker_or_entity.has_method("get_default_hitspark_palette"):
#			hit_data.move_data["hitspark_palette"] = hit_data.attacker_or_entity.get_default_hitspark_palette()
		if hit_data.attacker != null and hit_data.attacker.has_method("get_default_hitspark_palette"):
			hit_data.move_data["hitspark_palette"] = hit_data.attacker.get_default_hitspark_palette()
		else:
			hit_data.move_data["hitspark_palette"] = "red"
		
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
		var rot_rad: float
		if hit_data.move_data.hitspark_type != Globals.hitspark_type.SLASH:
			rot_rad = hit_data.knockback_dir / 360.0 * (2 * PI) + PI # visuals only
		else: # slash hitspark randomize angle a bit
			var rand_degree := 0
			if "multihit" in hit_data or "autochain" in hit_data:
				rand_degree = Globals.Game.rng_generate(91) * Globals.Game.rng_facing()
			else:
				rand_degree = Globals.Game.rng_generate(46) * Globals.Game.rng_facing()
			rot_rad = (hit_data.knockback_dir + rand_degree) / 360.0 * (2 * PI) + PI # visuals only
		if "pull" in hit_data: rot_rad += PI # flip if pulling
		Globals.Game.spawn_SFX(hitspark, hitspark, hit_data.hit_center, {"rot": rot_rad, "v_mirror":Globals.Game.rng_bool()}, \
				hit_data.move_data["hitspark_palette"])
		
func get_default_hitspark_type():
	return get_stat("DEFAULT_HITSPARK_TYPE")
func get_default_hitspark_palette():
	return get_stat("DEFAULT_HITSPARK_PALETTE")
	
	
# AUTO SEQUENCES ---------------------------------------------------------------------------------------------------

func simulate_sequence(): # cut into this during simulate2() during sequences
	
	var Partner = get_seq_partner()
	if Partner == null and new_state in [Globals.char_state.SEQUENCE_TARGET, Globals.char_state.SEQUENCE_USER]:
		animate("Idle")
		return
	
	if new_state == Globals.char_state.SEQUENCE_TARGET: # being the target of an opponent's sequence will be moved around by them
		if Partner.new_state != Globals.char_state.SEQUENCE_USER:
			animate("Idle") # auto release if not released proberly, just in case
		
	elif new_state == Globals.char_state.SEQUENCE_USER: # using a sequence, will follow the steps in UniqChar.SEQUENCES[sequence_name]
		UniqChar.simulate_sequence()
		
		
	if abs(velocity.x) < 5 * FMath.S:
		velocity.x = 0
	if abs(velocity.y) < 5 * FMath.S:
		velocity.y = 0
	
	velocity_previous_frame.x = velocity.x
	velocity_previous_frame.y = velocity.y
	
	var results = move($PlayerCollisionBox, $PlayerCollisionBox, UniqChar.sequence_ledgestop()) # [landing_check, collision_check, ledgedrop_check]
#	velocity.x = results[0].x
#	velocity.y = results[0].y
	
	if new_state == Globals.char_state.SEQUENCE_USER:
		UniqChar.simulate_sequence_after() # move grabbed target after grabber has moved
	
	if results[0]: UniqChar.end_sequence_step("ground") # hit the ground, no effect if simulate_sequence_after() broke grab and animated "Idle"
	
		
func landed_a_sequence(hit_data):
	
	if new_state in [Globals.char_state.SEQUENCE_USER]:
		return # no sequencing if you are already grabbing another player

	var defender = Globals.Game.get_player_node(hit_data.defender_ID)
	
	if defender == null or defender.new_state in [Globals.char_state.SEQUENCE_TARGET]:
		return # no sequencing players that are already being grabbed
		
	if defender.new_state in [Globals.char_state.SEQUENCE_USER]: # both players grab each other at the same time, break grabs
		animate("Idle")
		defender.animate("Idle")
		return
	
	if "attacked_this_frame" in defender:
		defender.attacked_this_frame = true
		
	seq_partner_ID = defender.player_ID
	defender.seq_partner_ID = player_ID
		
	animate(hit_data.move_data.sequence)
#	UniqChar.start_sequence_step()
	
	remove_status_effect_on_landing_hit()
	
#	defender.status_effect_to_remove.append(Globals.status_effect.POS_FLOW)	# defender lose positive flow

	
func take_seq_damage(base_damage: int) -> bool: # return true if lethal

	var scaled_damage: int = base_damage * FMath.S
	if scaled_damage == 0: return false
	
	var damage: int = int(max(FMath.round_and_descale(scaled_damage), 1)) # minimum damage is 1
	
	take_damage(damage)
	if damage > 0:
		Globals.Game.spawn_damage_number(damage, position)
	if get_damage_percent() >= 100:
		return true # return true if lethal
	return false
	
	
func sequence_hit(hit_key: int): # most auto sequences deal damage during the sequence outside of the launch
	
	var seq_user = get_seq_partner()
	if seq_user == null:
		animate("Idle")
		return
		
	var seq_hit_data = seq_user.UniqChar.get_seq_hit_data(hit_key)
	var lethal = take_seq_damage(seq_hit_data.damage)
	
	if "hitstop" in seq_hit_data and !"weak" in seq_hit_data: # if weak, no lethal effect, place it for non-final hits
		if lethal:
			hitstop = LETHAL_HITSTOP
			seq_user.hitstop = hitstop
			Globals.Game.set_screenshake()
			play_audio("lethal1", {"vol" : -5, "bus" : "Reverb"})
		else:
			hitstop = seq_hit_data.hitstop
			seq_user.hitstop = hitstop


func sequence_launch():
	
	start_command("standby")
	
	var seq_user = get_seq_partner()
	if seq_user == null:
		animate("Idle")
		return
		
	var dir_to_attacker = sign(position.x - seq_user.position.x)
	if dir_to_attacker == 0: dir_to_attacker = facing
	
	if !seq_user.Animator.to_play_animation in seq_user.UniqChar.MOVE_DATABASE:
		print("Error: " + Animator.to_play_animation + " auto-sequence not found in database.")
	var seq_data = seq_user.UniqChar.get_seq_launch_data()
	
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
		
	if !guardbroken and !"weak" in seq_data:
		
		change_guard_gauge(GUARD_GAUGE_FLOOR)
		
		if get_guard_gauge_percent_below() == 0:
			guardbroken = true
#			repeat_memory = [] # reset move memory for getting a Break
			modulate_play("punish_sweet_flash")
			play_audio("rock2", {"vol" : -10})
			start_command("standby")
			Globals.Game.spawn_SFX("Crushspark", "Stunspark", position, {"facing":Globals.Game.rng_facing(), \
				"v_mirror":Globals.Game.rng_bool()})
		
			combo_level = seq_data.atk_level - 1
			combo_level += Inventory.modifier(seq_user.player_ID, Cards.effect_ref.COMBO_LEVEL)
			combo_level = int(clamp(combo_level, 0, 7))
			
#	proj_only_combo = false
		
	# HITSTUN
	var hitstun: int
	if "fixed_hitstun" in seq_data:
		hitstun = seq_data.fixed_hitstun
	else:
#		var scaled_hitstun: int = ATK_LEVEL_TO_L_HITSTUN[mob_level_to_tier()][seq_data.atk_level - 1] * FMath.S
		var scaled_hitstun: int
		if Globals.difficulty == 3:
			scaled_hitstun = ATK_LEVEL_TO_L_HITSTUN_H[seq_data.atk_level - 1] * FMath.S
		else: scaled_hitstun = ATK_LEVEL_TO_L_HITSTUN[seq_data.atk_level - 1] * FMath.S
		var weight = get_guard_gauge_percent_below()
		if weight > 50:
			weight = FMath.get_fraction_percent((weight - 50), 50)
			scaled_hitstun = FMath.f_lerp(scaled_hitstun, FMath.percent(scaled_hitstun, HITSTUN_REDUCTION_AT_MAX_GG), weight)
		hitstun = FMath.round_and_descale(scaled_hitstun)
	$HitStunTimer.time = hitstun
	launchstun_rotate = 0 # used to calculation sprite rotation during launched state
		
	# LAUNCH POWER
	var launch_power = seq_data.launch_power # scaled
	launch_power = FMath.f_lerp(launch_power, FMath.percent(launch_power, get_stat("KB_BOOST_AT_MAX_GG")), \
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
			
	if !has_trait(Globals.trait.NO_LAUNCH):
		animate("LaunchStop")
	else:
		animate("aFlinchAStop") # error, just in case, mobs with NO_LAUNCH are not supposed to be vulnerable to sequence and has no LaunchStop
	
	velocity.set_vector(launch_power, 0)  # reset momentum
	velocity.rotate(launch_angle)
	
	if get_damage_percent() >= 100:				
		animate("Death")
		if launch_power == 0:
			velocity.set_vector(-500 * FMath.S * facing, 0)
			velocity.rotate(26 * facing)
		else:
			velocity.set_vector(500 * FMath.S, 0) # don't add facing here
			velocity.rotate(launch_angle)
	
		
# ANIMATION AND AUDIO PROCESSING ---------------------------------------------------------------------------------------------------
	
# universal actions
func _on_SpritePlayer_anim_finished(anim_name):
	
	match anim_name:
		"Death":
			loot_drop()
			if target_ID >= 0:
				if Inventory.has_quirk(target_ID, Cards.effect_ref.HEAL_ON_KILL):
					var killer = Globals.Game.get_player_node(target_ID)
					var healed = killer.take_damage(-FMath.percent(get_stat("DAMAGE_VALUE_LIMIT"), Cards.KILL_HEAL_PERCENT))
					if healed != null and healed > 0:
						Globals.Game.spawn_damage_number(healed, killer.position, Globals.dmg_num_col.GREEN)
						
			Globals.Game.spawn_afterimage(player_ID, false, mob_ref, sprite_texture_ref.sprite, sprite.get_path(), palette_ref, null, \
					1.0, 20, Globals.afterimage_shader.WHITE)
			Globals.Game.spawn_SFX("Killspark", "Killspark", position, {"facing":Globals.Game.rng_facing(), \
					"v_mirror":Globals.Game.rng_bool()})
			play_audio("kill2", {})
			free = true
		
		"RunTransit":
			animate("Run")
		"SoftLanding", "Brake":
			animate("Idle")
			
		"JumpTransit":
			animate("JumpTransit2")
		"JumpTransit2":
			animate("JumpTransit3")
		"JumpTransit3":
			animate("Jump")
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
			
		"ResistA", "ResistB":
			animate("Idle")
		"aResistA", "aResistB":
			animate("FallTransit")

	UniqChar._on_SpritePlayer_anim_finished(anim_name)


func _on_SpritePlayer_anim_started(anim_name):
	
	state = state_detect(Animator.current_animation) # update state
	
	anim_friction_mod = 100
	anim_gravity_mod = 100
	velocity_limiter = {"x" : null, "up" : null, "down" : null, "x_slow" : null, "y_slow" : null}
	if Animator.query_current(["LaunchStop"]):
		sprite.rotation = launch_starting_rot
	else:
		sprite.rotation = 0
		
	if is_atk_startup():
		var atk_attr = query_atk_attr()
		if Globals.atk_attr.NORMALARMOR_STARTUP in atk_attr or Globals.atk_attr.SUPERARMOR_STARTUP in atk_attr:
			modulate_play("armor_flash")
	
	match anim_name:
		"Death":
			face_opponent()
			anim_gravity_mod = 0
			anim_friction_mod = 0
			velocity_limiter.x_slow = 10
			velocity_limiter.y_slow = 10
		"Run":
			Globals.Game.spawn_SFX("RunDust", "DustClouds", get_feet_pos(), {"facing":facing, "grounded":true})
		"SoftLanding":
			Globals.Game.spawn_SFX("LandDust", "DustClouds", get_feet_pos(), {"facing":facing, "grounded":true})
		"JumpTransit2":
			UniqChar.jump_style_check()

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
		
func modulate_play(anim: String):
	if !$ModulatePlayer.playing:
		pass # always play if no animation playing
	elif anim == $ModulatePlayer.current_animation:
		$ModulatePlayer.sustain = true
		return # no playing if animation is already being played
	elif "priority" in $ModulatePlayer.animations[anim] and "priority" in $ModulatePlayer.animations[$ModulatePlayer.current_animation]:
		if $ModulatePlayer.animations[anim].priority <= $ModulatePlayer.animations[$ModulatePlayer.current_animation].priority:
			pass # only play effect if effect has higher priority than currently played animation, lower priority number = higher
		else:
			return
	$ModulatePlayer.play(anim)
		
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
	
	if !audio_ref in Loader.audio: # custom audio, have the audioplayer search this node's unique_audio dictionary
		aux_data["mob_ref"] = mob_ref # add a new key to aux_data
		
	Globals.Game.play_audio(audio_ref, aux_data)

		

# triggered by SpritePlayer at start of each animation
func _on_change_spritesheet(spritesheet_filename):
	sprite.texture = spritesheet[spritesheet_filename]
	sprite_texture_ref.sprite = spritesheet_filename
	
func _on_change_SfxOver_spritesheet(SfxOver_spritesheet_filename):
	sfx_over.show()
	sfx_over.texture = spritesheet[SfxOver_spritesheet_filename]
	sprite_texture_ref.sfx_over = SfxOver_spritesheet_filename
	
func hide_SfxOver():
	sfx_over.hide()
	
func _on_change_SfxUnder_spritesheet(SfxUnder_spritesheet_filename):
	sfx_under.show()
	sfx_under.texture = spritesheet[SfxUnder_spritesheet_filename]
	sprite_texture_ref.sfx_under = SfxUnder_spritesheet_filename
	
func hide_SfxUnder():
	sfx_under.hide()


# SAVE/LOAD STATE --------------------------------------------------------------------------------------------------

func save_state():
	var state_data = {
		
		"free" : free,
		"mob_ref" : mob_ref,
		"mob_level" : mob_level,
		"mob_variant" : mob_variant,
		"mob_attr" : mob_attr,
		"palette_ref" : palette_ref,
		"player_ID" : player_ID,
			
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
		"target_ID" : target_ID,
		"seq_partner_ID" : seq_partner_ID,
		
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
#		"RageTimer_time" : $RageTimer.time,
		"ArmorTimer_time" : $ArmorTimer.time,
		"LongFailTimer_time" : $LongFailTimer.time,
#		"ResistTimer_time" : $ResistTimer.time,
		
		"current_command" : current_command,
		"command_timer" : command_timer,
		"command_style" : command_style,
		"strafe_style" : strafe_style,
		"command_array_num" : command_array_num,
		"guardbroken" : guardbroken,
		"chaining" : chaining,
		"air_dashed" : air_dashed,
		"rand_time" : rand_time,
		"peak_flag" : peak_flag,
		"chain_memory" : chain_memory,
		"rand_max_chain_size" : rand_max_chain_size,
		"combo_level" : combo_level,
#		"proj_only_combo" : proj_only_combo,
		"no_jump_chance" : no_jump_chance,
		"can_impulse" : can_impulse,
		
	}

	return state_data
	
func load_state(state_data):
	
	free = state_data.free
	mob_ref = state_data.mob_ref
	mob_level = state_data.mob_level
	mob_variant = state_data.mob_variant
	mob_attr = state_data.mob_attr
	palette_ref = state_data.palette_ref
	player_ID = state_data.player_ID
	load_mob()
	
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
	target_ID = state_data.target_ID
	seq_partner_ID = state_data.seq_partner_ID
	
	sprite_texture_ref = state_data.sprite_texture_ref
	
	current_damage_value = state_data.current_damage_value
	current_guard_gauge = state_data.current_guard_gauge
	damage_update()
	guard_gauge_update()
	
	unique_data = state_data.unique_data
#	if UniqChar.has_method("update_uniqueHUD"): UniqChar.update_uniqueHUD()
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
	if $ModulatePlayer.current_animation in NSAnims.modulate_animations and \
			NSAnims.modulate_animations[$ModulatePlayer.current_animation].has("monochrome"): set_monochrome()
	reset_fade()
	$FadePlayer.load_state(state_data.FadePlayer_data)
	
	$HitStunTimer.time = state_data.HitStunTimer_time
	$HitStopTimer.time = state_data.HitStopTimer_time
	$NoCollideTimer.time = state_data.NoCollideTimer_time
#	$RageTimer.time = state_data.RageTimer_time
	$ArmorTimer.time = state_data.ArmorTimer_time
	$LongFailTimer.time = state_data.LongFailTimer_time
#	$ResistTimer.time = state_data.ResistTimer_time

	current_command = state_data.current_command
	command_timer = state_data.command_timer
	guardbroken = state_data.guardbroken
	command_style = state_data.command_style
	strafe_style = state_data.strafe_style
	command_array_num = state_data.command_array_num
	chaining = state_data.chaining
	air_dashed = state_data.air_dashed
	rand_time = state_data.rand_time
	peak_flag = state_data.peak_flag
	chain_memory = state_data.chain_memory
	rand_max_chain_size = state_data.rand_max_chain_size
	combo_level = state_data.combo_level
#	proj_only_combo = state_data.proj_only_combo
	no_jump_chance = state_data.no_jump_chance
	can_impulse = state_data.can_impulse

	
#--------------------------------------------------------------------------------------------------


