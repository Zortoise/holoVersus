extends "res://Scenes/Physics/Physics.gd"

var UniqueEntity
onready var Animator = $SpritePlayer

const STRONG_HIT_AUDIO_BOOST = 3
const WEAK_HIT_AUDIO_NERF = -9

# to save:
var free := false
var entity_ref
var facing := 1
var v_facing := 1
var master_path: NodePath
#var master_ID: int
var true_position := Vector2.ZERO # int*1000 instead of int, needed for slow and precise movement
var velocity := Vector2.ZERO
var lifetime := 0
var lifespan = null
var absorption_value = null
var life_point = null # loses 1 on each hit, cannot depend on hitcount (piercing projectiles hit each player only once, for instance)
var hitcount_record = [] # record number of hits for current attack for each player, cannot do anymore hits if maxed out
var ignore_list = [] # some moves has ignore_time, after hitting will ignore that player for a number of frames, used for multi-hit specials
var unique_data = {} # data unique for the entity, stored as a dictionary

# not saved
var hitstop = null


# for common entities, aux_data contain "common", loaded scene stored in Globals.common_entity_data
func init(in_master_path: NodePath, in_entity_ref: String, in_position: Vector2, aux_data: Dictionary):
	
	master_path = in_master_path
#	master_ID = get_node(master_path).player_ID
	entity_ref = in_entity_ref
	position = in_position
	set_true_position()
	
	facing = get_node(master_path).facing # face in same direction as master
	$Sprite.scale.x = facing
	
	# for sprites:
#	if "facing" in aux_data:
#		facing = aux_data.facing
#		scale.x = aux_data.facing
#	if "v_mirror" in aux_data and aux_data.v_mirror: # mirror vertically, for hitsparks
#		v_facing = -1
#		scale.y = -1
#	if "rot" in aux_data:
#		rotation = aux_data.rot * scale.x
		
	var test_entity = get_child(0) # test entity node should be directly under this node
	test_entity.free()
	
	load_entity()
		
	UniqueEntity.init(aux_data)

		
func load_entity():

	var is_common = entity_ref in Globals.common_entity_data # check if UniqueEntity scene is common or character-unique
	
	if is_common: # common entity with loaded data stored in Globals.gb
		UniqueEntity = Globals.common_entity_data[entity_ref].scene.instance() # load UniqueEntity scene
		$SpritePlayer.init_with_loaded_frame_data($Sprite, Globals.common_entity_data[entity_ref].frame_data) # load frame data
		$Sprite.texture = Globals.common_entity_data[entity_ref].spritesheet # load spritesheet
		
	else: # character-unique entity with loaded data stored in master's node
		var entity_data = get_node(master_path).entity_data[entity_ref]
		UniqueEntity = entity_data.scene.instance() # load UniqueEntity scene
		$SpritePlayer.init_with_loaded_frame_data($Sprite, entity_data.frame_data) # load frame data
		$Sprite.texture = entity_data.spritesheet # load spritesheet
		
	add_child(UniqueEntity)
	move_child(UniqueEntity, 0)
	UniqueEntity.sprite = $Sprite
	UniqueEntity.Animator = $SpritePlayer
	
	# set up collision box dimensions
	if UniqueEntity.has_node("DefaultCollisionBox"):
		var ref_rect = UniqueEntity.get_node("DefaultCollisionBox")
		$EntityCollisionBox.rect_position = ref_rect.rect_position
		$EntityCollisionBox.rect_size = ref_rect.rect_size
		$EntityCollisionBox.add_to_group("Entities")
		
		if Globals.entity_trait.GROUNDED in UniqueEntity.TRAITS:
			$EntityCollisionBox.add_to_group("Grounded")
			$SoftPlatformDBox.rect_position.x = ref_rect.rect_position.x
			$SoftPlatformDBox.rect_position.y = ref_rect.rect_position.y + ref_rect.rect_size.y - 1
			$SoftPlatformDBox.rect_size.x = ref_rect.rect_size.x
			$SoftPlatformDBox.rect_size.y = 1
		else:
			$SoftPlatformDBox.free()
			
	else: # no collision, delete EntityCollisionBox
		$EntityCollisionBox.free()
		$SoftPlatformDBox.free()
		
	if UniqueEntity.has_node("DefaultSpriteBox"): # for an entity to go offstage, the entire sprite must be offstage
		var ref_rect = UniqueEntity.get_node("DefaultSpriteBox")
		$EntitySpriteBox.rect_position = ref_rect.rect_position
		$EntitySpriteBox.rect_size = ref_rect.rect_size
	else:
		$EntitySpriteBox.free()
		
	if "PALETTE" in UniqueEntity: # load palette
		if is_common: # common palette stored in LoadedSFX.loaded_sfx_palette
			if UniqueEntity.PALETTE in LoadedSFX.loaded_sfx_palette:
				$Sprite.material = ShaderMaterial.new()
				$Sprite.material.shader = Globals.loaded_palette_shader
				$Sprite.material.set_shader_param("swap", LoadedSFX.loaded_sfx_palette[UniqueEntity.PALETTE])
				
		elif get_node(master_path).loaded_palette != null: # same palette as master, just set UniqueEntity.PALETTE to null
			$Sprite.material = ShaderMaterial.new()
			$Sprite.material.shader = Globals.loaded_palette_shader
			$Sprite.material.set_shader_param("swap", get_node(master_path).loaded_palette)
				

func stimulate():
	
	hitstop = null
	$HitStopTimer.stimulate() # advancing the hitstop timer at start of frame allow for one frame of knockback before hitstop
	# will be needed for multi-hit moves
	
	if !$HitStopTimer.is_running():
		stimulate2()


func stimulate2(): # only ran if not in hitstop
	
	if abs(velocity.x) < 5.0: # do this at the start too
		velocity.x = 0.0
	if abs(velocity.y) < 5.0:
		velocity.y = 0.0
		
	# clashing projectiles, clash with their EntityCollisionBoxes
	if absorption_value != null and absorption_value > 0 and has_node("EntityCollisionBox"):
		var interact_array = Detection.detect_return([$EntityCollisionBox], ["Entities"])
		if interact_array.size() > 0: # detected other entities
			var interact_array2 = []
			for x in interact_array: # filter out entities with no absorption value or about to be killed or share this entity's master
				if x.absorption_value != null and absorption_value > 0 and \
						x.get_node(master_path).player_ID != get_node(master_path).player_ID:
					interact_array2.append(x)
			if interact_array2.size() > 0:
				var lowest_AV = absorption_value # find lowest absorption_value
				for x in interact_array2:
					if x.absorption_value < lowest_AV:
						lowest_AV = x.absorption_value
						
				absorption_value -= lowest_AV # reduce AV of all entities detected, kill all with 0 AV
				if absorption_value <= 0:
					UniqueEntity.kill()
				for x in interact_array2:
					x.absorption_value -= lowest_AV
					if x.absorption_value <= 0:
						x.UniqueEntity.kill()
		
				
			
	UniqueEntity.stimulate()
	
	ignore_list_progress_timer()
	
	velocity.x = round(velocity.x) # makes it more consistent, may reduce rounding errors across platforms hopefully?
	velocity.y = round(velocity.y)
	
	if abs(velocity.x) < 5.0:
		velocity.x = 0.0
	if abs(velocity.y) < 5.0:
		velocity.y = 0.0
	

	# movement
	if has_node("EntityCollisionBox"):
	
		var results # [in_velocity, landing_check, collision_check, ledgedrop_check]
		if Globals.entity_trait.GROUNDED in UniqueEntity.TRAITS:
			results = move($EntityCollisionBox, $SoftPlatformDBox, velocity, Globals.entity_trait.LEDGE_STOP in UniqueEntity.TRAITS)
		else: # for non-grounded entities, their SoftPlatformDBox is their EntityCollisionBox
			results = move($EntityCollisionBox, $EntityCollisionBox, velocity)
			
		velocity = results[0]
		
		if UniqueEntity.has_method("collision"): # entity can collide with solid platforms
			if is_in_wall($EntityCollisionBox): # if spawned inside solid platform, kill it
				UniqueEntity.kill()
			elif results[2] == true: # if colliding with a solid platform, runs collision() which can kill it or bounce it
				UniqueEntity.collision()
		if Globals.entity_trait.GROUNDED in UniqueEntity.TRAITS and UniqueEntity.has_method("ledge_stop"):
			if !is_on_ground($SoftPlatformDBox, velocity): # spawned in the air, kill it
				UniqueEntity.kill()
			elif (results[3] == true): # reached a ledge
				UniqueEntity.ledge_stop()
		
	else: # no collision with platforms
		position += velocity
	
	
func stimulate_after(): # do this after hit detection
	
	if !$HitStopTimer.is_running():
		$SpritePlayer.stimulate()
		
		lifetime += 1
		if lifespan != null and lifetime >= lifespan:
			UniqueEntity.kill()
				
	# start hitstop timer at end of frame after SpritePlayer.stimulate() by setting hitstop to a number other than null for the frame
	# new hitstops override old ones
	if hitstop:
		$HitStopTimer.time = hitstop
		
		
# TRUE POSITION --------------------------------------------------------------------------------------------------	
	# record the position to 0.001 of a pixel as integers, needed for slow and precise movements
	# to move an object, first do move_true_position(), then get_true_position()
	# round off the results and compare it to integer position to get move_amount and plug it in move_amount()
	# on collision, or anything that manipulate position directly (fallthrough, moving platforms), reset true_position to integer position
		
func set_true_position():
	true_position.x = round(position.x * 1000)
	true_position.y = round(position.y * 1000)
	
func get_true_position():
# warning-ignore:unassigned_variable
	var float_position: Vector2
	float_position.x = true_position.x / 1000
	float_position.y = true_position.y / 1000
	return float_position
	
func move_true_position(in_velocity):
	true_position.x = round(true_position.x + (in_velocity.x * Globals.FRAME * 1000 ))
	true_position.y = round(true_position.y + (in_velocity.y * Globals.FRAME * 1000))
	
# --------------------------------------------------------------------------------------------------
		
func check_fallthrough(): # return true if entity falls through soft platforms
	if UniqueEntity.has_method("check_fallthrough"): # some entities may interact with soft platforms
		return UniqueEntity.check_fallthrough
	else:
		return true

func on_offstage(): # what to do if entity leaves stage
	if UniqueEntity.has_method("on_offstage"):
		UniqueEntity.on_offstage()

func query_polygons(): # requested by main game node when doing hit detection

	var polygons_queried = {
		"hitbox" : null,
		"sweetbox": null,
		"kborigin": null,
		"vacpoint": null,
	}

	if !$HitStopTimer.is_running(): # no hitbox during hitstop
		polygons_queried.hitbox = Animator.query_polygon("hitbox")
		polygons_queried.sweetbox = Animator.query_polygon("sweetbox")
		polygons_queried.kborigin = Animator.query_point("kborigin")
		polygons_queried.vacpoint = Animator.query_point("vacpoint")

	return polygons_queried


func query_move_data(): # requested by main game node when doing hit detection
	if UniqueEntity.has_method("query_move_data"):
		return UniqueEntity.query_move_data()
	elif Animator.current_animation in UniqueEntity.MOVE_DATABASE:
		return UniqueEntity.MOVE_DATABASE[Animator.current_animation]
	return null

func query_atk_attr(in_move_name = null): # may have certain conditions, if no move name passed in, check current attack
	
	if in_move_name == null:
		in_move_name = Animator.current_animation
	
	if UniqueEntity.has_method("query_atk_attr"):
		return UniqueEntity.query_atk_attr(in_move_name)
	elif in_move_name in UniqueEntity.MOVE_DATABASE:
		return UniqueEntity.MOVE_DATABASE[in_move_name].atk_attr
	return []
	

func landed_a_hit(hit_data): # called by main game node when landing a hit
	
	var attacker = get_node(hit_data.attacker_nodepath) # will be this entity's master

#	attacker.UniqueCharacter.landed_a_hit(hit_data) # reaction, nothing here yet, can change hit_data from there

	var defender = get_node(hit_data.defender_nodepath)
	increment_hitcount(defender.player_ID) # for measuring hitcount of attacks
	attacker.targeted_opponent = defender.player_ID # target last attacked opponent

	# no positive flow for entities

	# EX GAIN ----------------------------------------------------------------------------------------------

	match hit_data.block_state:
		Globals.block_state.UNBLOCKED:
			if !hit_data.double_repeat:
				attacker.change_ex_gauge(hit_data.move_data.EX_gain)
			defender.change_ex_gauge(hit_data.move_data.EX_gain * 0.25)
		Globals.block_state.AIR_WRONG, Globals.block_state.GROUND_WRONG:
			if !hit_data.double_repeat:
				attacker.change_ex_gauge(hit_data.move_data.EX_gain)
		Globals.block_state.AIR_PERFECT, Globals.block_state.GROUND_PERFECT:
			defender.change_ex_gauge(hit_data.move_data.EX_gain)
		_:  # normal block
			if !hit_data.double_repeat:
				attacker.change_ex_gauge(hit_data.move_data.EX_gain * 0.5)
			defender.change_ex_gauge(hit_data.move_data.EX_gain * 0.5)

	# ENTITY HITSTOP ----------------------------------------------------------------------------------------------
		# hitstop is only set into HitStopTimer at end of frame

	if "fixed_entity_hitstop" in hit_data.move_data:
		# multi-hit special/super moves are done by having lower atker hitstop then defender hitstop, and high "hitcount" and ignore_time
		hitstop = hit_data.move_data.fixed_entity_hitstop
	else:
		if hitstop == null or hit_data.hitstop > hitstop: # need to do this to set consistent hitstop during clashes
			hitstop = hit_data.hitstop
			
	# WIP, change to screen freeze later
	if hit_data.lethal_hit: # on lethal hit, hitstop this entity's master as well
		get_node(master_path).get_node("HitStopTimer").time = hit_data.hitstop
			

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
				
	if UniqueEntity.has_method("landed_a_hit"):
		UniqueEntity.landed_a_hit(hit_data) # reaction
	
	
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
	
func append_ignore_list(in_ID, ignore_time): # added if the move has "ignore_time", called by the defender
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
	
	if anim_name.ends_with("Kill"):
		free = true # don't use queue_free!
		
#	match anim_name:
#		"Kill":
#			free = true # don't use queue_free!
			
	UniqueEntity._on_SpritePlayer_anim_finished(anim_name)
	
func _on_SpritePlayer_anim_started(anim_name):
#	match anim_name:
#		_:
#			pass
			
	UniqueEntity._on_SpritePlayer_anim_started(anim_name)
	

func play_audio(audio_ref: String, aux_data: Dictionary):
	var new_audio = Globals.loaded_audio_scene.instance()
	Globals.Game.get_node("AudioPlayers").add_child(new_audio)
	
	if audio_ref in LoadedSFX.loaded_audio: # common audio
		new_audio.init(audio_ref, aux_data)
	else: # custom audio, have the audioplayer search this node's owner's unique_audio dictionary in their main character node
		aux_data["unique_path"] = master_path # add a new key to aux_data
		new_audio.init(audio_ref, aux_data)

# SAVE/LOAD STATE --------------------------------------------------------------------------------------------------

func save_state():
	var state_data = {
		"position" : position,
		"facing" : facing,
		"v_facing" : v_facing,
		"rotation" : rotation,
		
		"entity_ref" : entity_ref,
		"SpritePlayer_data" : $SpritePlayer.save_state(),
		
		"free" : free,
		"master_path" : master_path,
		"true_position" : true_position,
		"velocity" : velocity,
		"lifetime" : lifetime,
		"lifespan" : lifespan,
		"absorption_value" : absorption_value,
		"life_point" : life_point,
		"hitcount_record" : hitcount_record,
		"ignore_list" : ignore_list,
		"unique_data" : unique_data,
		
		"HitStopTimer_time" : $HitStopTimer.time,
	}
	return state_data

func load_state(state_data):
	position = state_data.position
	facing = state_data.facing
	$Sprite.scale.x = facing
	v_facing = state_data.v_facing
	$Sprite.scale.y = v_facing
	rotation = state_data.rotation

	entity_ref = state_data.entity_ref
	master_path = state_data.master_path
	load_entity()

	$SpritePlayer.load_state(state_data.SpritePlayer_data)
	
	free = state_data.free
	true_position = state_data.true_position
	velocity = state_data.velocity
	lifetime = state_data.lifetime
	lifespan = state_data.lifespan
	absorption_value = state_data.absorption_value
	life_point = state_data.life_point
	hitcount_record = state_data.hitcount_record
	ignore_list = state_data.ignore_list
	unique_data = state_data.unique_data
	
	$HitStopTimer.time = state_data.HitStopTimer_time

		
#--------------------------------------------------------------------------------------------------
