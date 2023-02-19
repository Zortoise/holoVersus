extends Node2D

#const STYLE = 0

# Steps to add an attack:
# 1. Add it in MOVE_DATABASE and STARTERS, also in EX_MOVES/SUPERS, and in UP_TILTS if needed (even for EX Moves)
# 2. Add it in state_detect()
# 3. Add it in _on_SpritePlayer_anim_finished() to set the transitions
# 4. Add it in _on_SpritePlayer_anim_started() to set up entity/sfx spawning and other physics modifying Characteristics
# 6. Add it in capture_combinations() if it is a special action
# 5. Add it in process_buffered_input() for inputs
# 7. Add any startup/recovery animations not in MOVE_DATABASE to refine_move_name()
# 8. Add any active frame versions not in MOVE_DATABASE in get_root() for aerial and chain memory
	
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
	
# --------------------------------------------------------------------------------------------------

# shortening code, set by main Character node
onready var Character = get_parent()
var Animator
var sprite
var uniqueHUD


const NAME = "Gura"

# Character movement stats, use to overwrite
const SPEED = 340 * FMath.S # ground speed
const GRAVITY_MOD = 65 # make sure variable's a float
const TERMINAL_VELOCITY_MOD = 650 # affect terminal velocity downward
const FRICTION = 15 # between 0.0 and 1.0
const ACCELERATION = 15 # between 0.0 and 1.0
const AIR_RESISTANCE = 3 # between 0.0 and 1.0
const FALL_GRAV_MOD = 100 # reduced gravity when going down

const KB_BOOST_AT_MAX_GG = 200 # max increase of knockback when Character's Guard Gauge is at 100%, light Characters have higher

const DAMAGE_VALUE_LIMIT = 9999

const GUARD_DRAIN_MOD = 500
const GUARD_GAUGE_REGEN_AMOUNT = 10 # exact GG regened per frame when GG < 100%
const GUARD_GAUGE_SWELL_RATE = 100

const TRAITS = []

const SDHitspark_COLOR = "blue"

const UNIQUE_DATA_REF = {
}


const MOVE_DATABASE = {
	"F1" : {
		"atk_type" : Globals.atk_type.FIERCE, # light/fierce/heavy/special/ex/super
		"hitcount" : 1,
		"damage" : 60, # chip damage is a certain % of damage, Chipper Attribute can increase chip
		"knockback" : 350 * FMath.S,  # knockback strength, block pushback (% of knockback strength), affect hitspark size and hitstop
		"knockback_type": Globals.knockback_type.MIRRORED,
		"atk_level" : 3, # 1~8, affect hitstun and blockstun
		"priority": 4, # aL < L < aF < F < aH < H < Specials (depend on move) < EX (depend on move), Super, but some moves are different
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : -36, # in degrees, 0 means straight ahead to the right, positive means rotating downward
		# some moves uses KBOrigin to determine KB_angle, has special data instead
		"atk_attr" : [], # enums
		"move_sound" : { ref = "whoosh13", aux_data = {"vol" : -12,} },
		# played when move is used, aux_data carry volume and bus
		"hit_sound" : { ref = "impact16", aux_data = {"vol" : -15} },
	},
}


const COMMANDS = {
		"idle": {
			"action": "idle",
#			"no_turn": true,
			"timeout" : [30, "seek"],
			"triggers" : [
				{"type" : "zone", "origin" : Vector2.ZERO, "size" : Vector2(180, 100),
				"next" : "turn_backswing",},
			]
		},
		"seek": {
			"action": "run",
			"timeout" : [60, null],
			"triggers" : [
				{"type" : "zone", "origin" : Vector2(60, 0), "size" : Vector2(120, 100),
				"next" : "backswing",},
				{"type" : "cross",
				"next" : "turn_backswing",}
			]
		},
		"backswing": {
			"action": "ground_attack",
			"dir" : "facing", # if no "dir", towards target
			"anim" : "F1Startup",
		},
		"turn_backswing": {
			"action": "ground_attack",
			"anim" : "F1Startup",
		}
	}
	
func decision(decision_id = null):
	match decision_id:
		null:
			if Character.grounded:
#				var branches = ["idle", "seek", "backswing", "turn_backswing"]
				var branches = ["idle", "seek"]
				Character.current_command = Globals.Game.rng_array(branches)


func _ready():
	get_node("TestSprite").free() # test sprite is for sizing collision box
	
	decision()


func load_palette():
	var palette_ref = null
	match Globals.Game.LevelControl.mob_data[Character.mob_ref].variant:
		"Base":
			palette_ref = "Red"
			
	if palette_ref != null:
		Character.loaded_palette = Globals.Game.LevelControl.mob_data[Character.mob_ref].palettes[palette_ref]
	
# STATE_DETECT --------------------------------------------------------------------------------------------------

func state_detect(anim): # for unique animations, continued from state_detect() of main Character node
	match anim:
		
		"F1Startup":
			return Globals.char_state.GROUND_ATK_STARTUP
		"F1Active":
			return Globals.char_state.GROUND_ATK_ACTIVE
		"F1Rec":
			return Globals.char_state.GROUND_ATK_RECOVERY
			
		
	print("Error: " + anim + " not found.")
		
func check_collidable():  # some Characters have move that can pass through other Characters
	match Animator.to_play_animation:
		_:
			pass
	return true
	
func check_semi_invuln():
	return false

# UNIQUE INPUT CAPTURE --------------------------------------------------------------------------------------------------
# some holdable buttons can have effect unique to the Character
	
func simulate():
	
	pass



func afterimage_trail():# process afterimage trail
	match Animator.to_play_animation:
#		"Dash", "aDash", "aDashD", "aDashU", "SDashTransit", "SDash", "aSDash":
#			Character.afterimage_trail()
#		"Dodge":
#			Character.afterimage_trail(null, 0.6, 10, Globals.afterimage_shader.WHITE)
		_:
			pass

			
func unique_flash():
	match Animator.to_play_animation:
		_:
			pass
			
# GET DATA --------------------------------------------------------------------------------------------------

func get_stat(stat: String): # later can have effects that changes stats
	return get(stat)
	
func query_traits(): # may have special conditions
	return TRAITS
			
func get_root(move_name): # for aerial and chain memory, only needed for versions with active frames not in MOVE_DATABASE
	
	if move_name in MOVE_DATABASE and "root" in MOVE_DATABASE[move_name]:
		return MOVE_DATABASE[move_name].root
		
	match move_name:
		_:
			pass
	
	return move_name
		
			
func refine_move_name(move_name):
		
	match move_name:
		_:
			pass
			
	return move_name
			
			
func query_move_data(move_name) -> Dictionary: # can change under conditions
	
	var orig_move_name = move_name
	move_name = refine_move_name(move_name)
	
	if !move_name in MOVE_DATABASE:
		print("Error: Cannot retrieve move_data for " + move_name)
		return {}
	
	var move_data = MOVE_DATABASE[move_name].duplicate(true)
	move_data["atk_attr"] = query_atk_attr(orig_move_name)
	
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
		_:
			pass
			

func being_hit(hit_data):
	
	match hit_data.move_name:
		_:
			pass
		
	
# AUTO SEQUENCES --------------------------------------------------------------------------------------------------

func simulate_sequence(): # this is ran on every frame during a sequence
#	var Partner = Character.get_target()
	
	match Animator.to_play_animation:
		_:
			pass
						
func simulate_sequence_after(): # called after moving and animating every frame, grab_point and grab_rot_dir are only updated then
#	var Partner = Character.get_target()
#	var grab_point = Animator.query_point("grabpoint")
	
	match Animator.to_play_animation:
		_:
			pass
						

			
						
func start_sequence_step(): # this is ran at the start of every sequence_step
#	var Partner = Character.get_target()

	match Animator.to_play_animation:
		_:
			pass
			
							
func end_sequence_step(_trigger = null): # this is ran at the end of certain sequence_step, or to end a trigger sequence_step
	# return true if sequence_step ended
#	var Partner = Character.get_target()
#
#	if trigger == "break": # grab break
#		Character.animate("Idle")
#		Partner.animate("Idle")
#		return true
	
	match Animator.to_play_animation:
		_:
			pass
			
	return false
			
			
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
	
	var Partner = Character.get_target()
	var results = Partner.move_sequence_player_to(new_position) # [landing_check, collision_check, ledgedrop_check]
	
	if results[0]: # Grabbed hit the ground, ends sequence step if it is triggered by Grabbed being grounded
		if end_sequence_step("target_ground"):
			return
			
	if results[1]: # Grabbed hit the wall/ceiling/ground outside ground trigger, reposition Grabber
		var reposition = Partner.position + (Character.position - Animator.query_point("grabpoint"))
		var reposition_results = Character.move_sequence_player_to(reposition) # [landing_check, collision_check, ledgedrop_check]
		if reposition_results[1]: # fail to reposition properly
			end_sequence_step("break") # break grab
			
			
func sequence_fallthrough(): # which step in sequence ignore soft platforms
	return false
	
func sequence_ledgestop(): # which step in sequence are stopped by ledges
	return false
	
func sequence_passthrough(): # which step in sequence ignore all platforms (for cinematic supers)
	return false
	
func sequence_partner_passthrough(): # which step in sequence has partner ignore all platforms
	return false
	
func sequence_passfloor(): # which step in sequence ignore hard floor
	return false
	
	
# CODE FOR CERTAIN MOVES ---------------------------------------------------------------------------------------------------



# ANIMATION AND AUDIO PROCESSING ---------------------------------------------------------------------------------------------------
# these are ran by main Character node when it gets the signals so that the order is easier to control

func _on_SpritePlayer_anim_finished(anim_name):
	
	match anim_name:
			
		"F1Startup":
			Character.animate("F1Active")
		"F1Active":
			Character.animate("F1Rec")
		"F1Rec":
			Character.animate("Idle")
			

func _on_SpritePlayer_anim_started(anim_name):
	match anim_name:
		"F1Startup":
			Character.velocity.x += Character.facing * FMath.percent(get_stat("SPEED"), 25)
		"F1Active":
			Character.velocity.x += Character.facing * FMath.percent(get_stat("SPEED"), 50)
			
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
			_:
				pass
	
	match anim_name:
		"JumpTransit2", "WallJumpTransit2":
			Character.play_audio("jump1", {"bus":"PitchDown"})
		"aJumpTransit2":
			Character.play_audio("jump1", {"vol":-2})
		"SoftLanding":
			landing_sound()
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
					
					
