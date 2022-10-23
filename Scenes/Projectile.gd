extends "res://Scenes/Physics/Physics.gd"

onready var Animator = $SpritePlayer

const STRONG_HIT_AUDIO_BOOST = 3
const WEAK_HIT_AUDIO_NERF = -9

# to save:
var free := false
var loaded_proj_ref

var facing := 1
var v_facing := 1
var palette_ref = null

var owner_ID: int
var move_data := {}

var velocity := Vector2.ZERO
var lifespan = null
var absorption_value := 1

var hitcount_record = [] # record number of hits for current attack for each player, cannot do anymore hits if maxed out
var ignore_list = [] # some moves has ignore_time, after hitting will ignore that player for a number of frames, used for multi-hit specials


# not saved
var hitstop = null


# for common projectiles, in_loaded_proj_ref is a string pointing to loaded sfx in LoadedSFX.gb
# for unique projectiles, in_loaded_proj_ref will be a NodePath leading to the sfx's loaded FrameData .tres file and loaded spritesheet
func init(in_owner_ID, in_loaded_proj_ref, in_move_data: Dictionary, in_position: Vector2, aux_data: Dictionary):
	
	owner_ID = in_owner_ID
	
	loaded_proj_ref = in_loaded_proj_ref
	load_proj_ref() # load frame data and spritesheet
	
	move_data = in_move_data # not changing it, no need for duplicate
	
	position = in_position
	
	# for sprites:
	if "facing" in aux_data:
		facing = aux_data.facing
		scale.x = aux_data.facing
	if "v_mirror" in aux_data and aux_data.v_mirror: # mirror vertically, for hitsparks
		v_facing = -1
		scale.y = -1
	if "rot" in aux_data:
		rotation = aux_data.rot * scale.x
		
	if "starting_anim" in move_data:
		$SpritePlayer.play(move_data.starting_anim)
	else:
		$SpritePlayer.play("Default")
	
	velocity = Vector2(move_data.starting_velocity, 0).rotated(move_data.starting_rot)
	
	if "lifespan" in move_data:
		lifespan = move_data.lifespan
		
	load_move_data()
	
		
func load_move_data():
	
	if "collision_box_size" in move_data:
		$ProjCollisionBox.rect_size = move_data.collision_box_size
		# center it
		$ProjCollisionBox.rect_position = Vector2($ProjCollisionBox.rect_size.x / 2.0, $ProjCollisionBox.rect_position.rect_size.y / 2.0)
		if "grounded" in move_data:
			$ProjCollisionBox.add_to_group("Grounded")
			$ProjCollisionBox.rect_position.y -= $ProjCollisionBox.rect_position.rect_size.y / 2.0 # ground the collision box
	else: # no collision
		$ProjCollisionBox.free()

	if "palette" in move_data:
		palette_ref = move_data.palette
		palette()
	
	
func load_proj_ref(): # load frame data and spritesheet
	
	if !loaded_proj_ref is NodePath: # loaded_proj_ref is a string pointing to loaded loaded_proj_ref in LoadedSFX.gb
		# this is only used for universal projectiles like Burst
		$Sprite.texture = LoadedSFX.loaded_sfx[loaded_proj_ref]["loaded_spritesheet"]
		$SpritePlayer.init_with_loaded_frame_data($Sprite, LoadedSFX.loaded_sfx[loaded_proj_ref]["loaded_frame_data"])
		
	else: # loaded_proj_ref is a NodePath leading to the projectile's loaded FrameData .tres file and loaded spritesheet 
		  # in their main character node in the loaded_entities dictionary
		# WIP
		pass


func palette():
	if palette_ref in LoadedSFX.loaded_sfx_palette:
		$Sprite.material = ShaderMaterial.new()
		$Sprite.material.shader = Globals.loaded_palette_shader
		$Sprite.material.set_shader_param("swap", LoadedSFX.loaded_sfx_palette[palette_ref])
		

func stimulate():
	
	hitstop = null
	$HitStopTimer.stimulate() # advancing the hitstop timer at start of frame allow for one frame of knockback before hitstop
	# will be needed for multi-hit moves
	
	if !$HitStopTimer.is_running():
		stimulate2()


func stimulate2(): # only ran if not in hitstop
	ignore_list_progress_timer()
	
	velocity.x = round(velocity.x) # makes it more consistent, may reduce rounding errors across platforms hopefully?
	velocity.y = round(velocity.y)
	
	if abs(velocity.x) < 5.0:
		velocity.x = 0.0
	if abs(velocity.y) < 5.0:
		velocity.y = 0.0
	
	# WIP
#	velocity = character_move($PlayerCollisionBox, $SoftPlatformDBox, velocity, check_ledge_stop())
	
#	stimulate_after() # WIP, testing
	
	
func stimulate_after(): # do this after hit detection
	
	if !$HitStopTimer.is_running():
		$SpritePlayer.stimulate()
		
		if lifespan != null:
			lifespan -= 1
			if lifespan == 0:
				free = true
				
	# start hitstop timer at end of frame after SpritePlayer.stimulate() by setting hitstop to a number other than null for the frame
	# new hitstops override old ones
	if hitstop:
		$HitStopTimer.time = hitstop
		

func query_polygons(): # requested by main game node when doing hit detection

	var polygons_queried = {
		"hitbox" : null,
		"sweetbox": null,
		"kborigin": null,
	}

	if !$HitStopTimer.is_running(): # no hitbox during hitstop
		polygons_queried.hitbox = Animator.query_polygon("hitbox")
		polygons_queried.sweetbox = Animator.query_polygon("sweetbox")
		polygons_queried.kborigin = Animator.query_point("kborigin")

	return polygons_queried


func query_move_data(): # requested by main game node when doing hit detection
	return move_data


func landed_a_hit(hit_data): # called by main game node when landing a hit

	var attacker = get_node(hit_data.attacker_nodepath)

#	attacker.UniqueCharacter.landed_a_hit(hit_data) # reaction, nothing here yet, can change hit_data from there

	var defender = get_node(hit_data.defender_nodepath)
	increment_hitcount(defender.player_ID) # for measuring hitcount of attacks
	attacker.targeted_opponent = defender.player_ID # target last attacked opponent

	# no positive flow for projectiles

	# EX GAIN ----------------------------------------------------------------------------------------------

	match hit_data.block_state:
		Globals.block_state.UNBLOCKED:
			if !hit_data.repeat_penalty:
				attacker.change_ex_gauge(hit_data.move_data.EX_gain)
		Globals.block_state.AIR_WRONG, Globals.block_state.GROUND_WRONG:
			if !hit_data.repeat_penalty:
				attacker.change_ex_gauge(hit_data.move_data.EX_gain)
		Globals.block_state.AIR_PERFECT, Globals.block_state.GROUND_PERFECT:
			defender.change_ex_gauge(hit_data.move_data.EX_gain)
		_:  # normal block
			if !hit_data.repeat_penalty:
				attacker.change_ex_gauge(hit_data.move_data.EX_gain * 0.5)
			defender.change_ex_gauge(hit_data.move_data.EX_gain * 0.5)

	# PROJECTILE HITSTOP ----------------------------------------------------------------------------------------------
		# hitstop is only set into HitStopTimer at end of frame

	if "fixed_proj_hitstop" in hit_data.move_data:
		# multi-hit special/super moves are done by having lower atker hitstop then defender hitstop, and high "hitcount" and ignore_time
		hitstop = hit_data.move_data.fixed_proj_hitstop
	else:
		if hitstop == null or hit_data.hitstop > hitstop: # need to do this to set consistent hitstop during clashes
			hitstop = hit_data.hitstop
			

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
		elif hit_data.move_data.attack_level <= 1 or hit_data.repeat_penalty or hit_data.semi_disjoint: # last for VULN_LIMBS
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
	
func is_hitcount_maxed(in_ID, in_move_data):  # called by main game node
	var recorded_hitcount = get_hitcount(in_ID)
	
	if recorded_hitcount >= in_move_data.hitcount:
		return true
	else: return false
	
	
func is_hitcount_last_hit(in_ID, in_move_data):
	var recorded_hitcount = get_hitcount(in_ID)
	
	if recorded_hitcount >= in_move_data.hitcount - 1:
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
	

# ANIMATION AND AUDIO PROCESSING ---------------------------------------------------------------------------------------------------

func _on_SpritePlayer_anim_finished(anim_name):
	match anim_name:
		"Kill":
			free = true # don't use queue_free!

func play_audio(audio_ref: String, aux_data: Dictionary):
	var new_audio = Globals.loaded_audio_scene.instance()
	Globals.Game.get_node("AudioPlayers").add_child(new_audio)
	
	if audio_ref in LoadedSFX.loaded_audio: # common audio
		new_audio.init(audio_ref, aux_data)
	else: # custom audio, have the audioplayer search this node's owner's unique_audio dictionary in their main character node
		aux_data["unique_path"] = loaded_proj_ref # add a new key to aux_data
		new_audio.init(audio_ref, aux_data)

# SAVE/LOAD STATE --------------------------------------------------------------------------------------------------

func save_state():
	var state_data = {
		"position" : position,
		"facing" : facing,
		"v_facing" : v_facing,
		"rotation" : rotation,
		
		"loaded_proj_ref" : loaded_proj_ref,
		"SpritePlayer_data" : $SpritePlayer.save_state(),
		
		"free" : free,
		"owner_ID" : owner_ID,
		"move_data" : move_data,
		"velocity" : velocity,
		"lifespan" : lifespan,
		"absorption_value" : absorption_value,
		"hitcount_record" : hitcount_record,
		"ignore_list" : ignore_list,
		"HitStopTimer_time" : $HitStopTimer.time,
	}
	return state_data

func load_state(state_data):
	position = state_data.position
	facing = state_data.facing
	scale.x = facing
	v_facing = state_data.v_facing
	scale.y = v_facing
	rotation = state_data.rotation

	loaded_proj_ref = state_data.loaded_proj_ref
	load_proj_ref()

	$SpritePlayer.load_state(state_data.SpritePlayer_data)
	
	free = state_data.free
	owner_ID = state_data.owner_ID
	move_data = state_data.move_data
	velocity = state_data.velocity
	lifespan = state_data.lifespan
	absorption_value = state_data.absorption_value
	hitcount_record = state_data.hitcount_record
	ignore_list = state_data.ignore_list
	$HitStopTimer.time = state_data.HitStopTimer_time
	
	load_move_data()
		
#--------------------------------------------------------------------------------------------------
