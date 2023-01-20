extends "res://Scenes/Physics/Physics.gd"

var UniqEntity
onready var Animator = $SpritePlayer

const STRONG_HIT_AUDIO_BOOST = 3
const WEAK_HIT_AUDIO_NERF = -9

# to save:
var free := false
var entity_ref
var facing := 1
var v_facing := 1
var master_path: NodePath
var creator_path: NodePath
#var master_ID: int
var true_position := FVector.new() # scaled int vector, needed for slow and precise movement
var velocity := FVector.new()
var lifetime := 0
var lifespan = null
var absorption_value = null
var life_point = null # loses 1 on each hit, cannot depend on hitcount (piercing projectiles hit each player only once, for instance)
var hitcount_record = [] # record number of hits for current attack for each player, cannot do anymore hits if maxed out
var ignore_list = [] # some moves has ignore_time, after hitting will ignore that player for a number of frames, used for multi-hit specials
var unique_data = {} # data unique for the entity, stored as a dictionary

# not saved
var hitstop = null


func init(in_master_path: NodePath, in_entity_ref: String, in_position: Vector2, aux_data: Dictionary):
	
	master_path = in_master_path
	creator_path = in_master_path
#	master_ID = get_node(master_path).player_ID
	entity_ref = in_entity_ref
	position = in_position
	set_true_position()
	
	if !"facing" in aux_data:
		face(get_node(master_path).facing) # face in same direction as master
	elif aux_data.facing != 0: # just in case
		face(aux_data.facing)
	
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
		
	if "UNIQUE_DATA_REF" in UniqEntity:
		unique_data = UniqEntity.UNIQUE_DATA_REF.duplicate(true)
		
	UniqEntity.init(aux_data)
	
		
func load_entity():

	var is_common = entity_ref in Globals.common_entity_data # check if UniqEntity scene is common or character-unique
	
	if is_common: # common entity with loaded data stored in Globals.gb
		UniqEntity = Globals.common_entity_data[entity_ref].scene.instance() # load UniqEntity scene
		$SpritePlayer.init_with_loaded_frame_data($Sprite, Globals.common_entity_data[entity_ref].frame_data) # load frame data
		$Sprite.texture = Globals.common_entity_data[entity_ref].spritesheet # load spritesheet
		
	else: # character-unique entity with loaded data stored in master's node
		var entity_data = get_node(creator_path).entity_data[entity_ref]
		UniqEntity = entity_data.scene.instance() # load UniqEntity scene
		$SpritePlayer.init_with_loaded_frame_data($Sprite, entity_data.frame_data) # load frame data
		$Sprite.texture = entity_data.spritesheet # load spritesheet
		
	add_child(UniqEntity)
	move_child(UniqEntity, 0)
	UniqEntity.sprite = $Sprite
	UniqEntity.Animator = $SpritePlayer
	
	# set up collision box dimensions
	if UniqEntity.has_node("DefaultCollisionBox"):
		var ref_rect = UniqEntity.get_node("DefaultCollisionBox")
		$EntityCollisionBox.rect_position = ref_rect.rect_position
		$EntityCollisionBox.rect_size = ref_rect.rect_size
		$EntityCollisionBox.add_to_group("Entities")
		
		if Globals.entity_trait.GROUNDED in UniqEntity.TRAITS:
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
		
	if UniqEntity.has_node("DefaultSpriteBox"): # for an entity to go offstage, the entire sprite must be offstage
		var ref_rect = UniqEntity.get_node("DefaultSpriteBox")
		$EntitySpriteBox.rect_position = ref_rect.rect_position
		$EntitySpriteBox.rect_size = ref_rect.rect_size
	else:
		$EntitySpriteBox.free()
		
	if "PALETTE" in UniqEntity: # load palette
		if is_common: # common palette stored in LoadedSFX.loaded_sfx_palette
			if UniqEntity.PALETTE in LoadedSFX.loaded_sfx_palette:
				$Sprite.material = ShaderMaterial.new()
				$Sprite.material.shader = Globals.loaded_palette_shader
				$Sprite.material.set_shader_param("swap", LoadedSFX.loaded_sfx_palette[UniqEntity.PALETTE])
				
		elif get_node(creator_path).loaded_palette != null: # same palette as creator, just set UniqEntity.PALETTE to null
			$Sprite.material = ShaderMaterial.new()
			$Sprite.material.shader = Globals.loaded_palette_shader
			$Sprite.material.set_shader_param("swap", get_node(creator_path).loaded_palette)
				

func simulate():
	if Globals.Game.is_stage_paused(): return
	
	hitstop = null
	$HitStopTimer.simulate() # advancing the hitstop timer at start of frame allow for one frame of knockback before hitstop
	# will be needed for multi-hit moves
	
	if !$HitStopTimer.is_running():
		simulate2()


func simulate2(): # only ran if not in hitstop
	
#	if abs(velocity.x) < 5.0: # do this at the start too
#		velocity.x = 0.0
#	if abs(velocity.y) < 5.0:
#		velocity.y = 0.0
		
	# clashing projectiles, clash with their EntityCollisionBoxes
	if absorption_value != null and absorption_value > 0 and has_node("EntityCollisionBox"):
		var interact_array = Detection.detect_return([$EntityCollisionBox], ["Entities"])
		if interact_array.size() > 0: # detected other entities
			var interact_array2 = []
			for x in interact_array: # filter out entities with no absorption value or about to be killed or share this entity's master
				if x.absorption_value != null and x.absorption_value > 0 and \
						x.get_node(master_path).player_ID != get_node(x.master_path).player_ID:
					interact_array2.append(x)
			if interact_array2.size() > 0:
				var lowest_AV = absorption_value # find lowest absorption_value
				for x in interact_array2:
					if x.absorption_value < lowest_AV:
						lowest_AV = x.absorption_value
						
				absorption_value -= lowest_AV # reduce AV of all entities detected, kill all with 0 AV
				if absorption_value <= 0:
					UniqEntity.kill()
				for x in interact_array2:
					x.absorption_value -= lowest_AV
					if x.absorption_value <= 0:
						x.UniqEntity.kill()
		
				
			
	UniqEntity.simulate()
	
	ignore_list_progress_timer()
	
	if free:
		$Sprite.hide()
		return
	
#	velocity.x = round(velocity.x) # makes it more consistent, may reduce rounding errors across platforms hopefully?
#	velocity.y = round(velocity.y)
	
	if abs(velocity.x) < 5 * FMath.S:
		velocity.x = 0
	if abs(velocity.y) < 5 * FMath.S:
		velocity.y = 0
	
	# movement
	if has_node("EntityCollisionBox"):
	
		var results #  # [landing_check, collision_check, ledgedrop_check]
		if Globals.entity_trait.GROUNDED in UniqEntity.TRAITS:
			results = move($EntityCollisionBox, $SoftPlatformDBox, Globals.entity_trait.LEDGE_STOP in UniqEntity.TRAITS)
		else: # for non-grounded entities, their SoftPlatformDBox is their EntityCollisionBox
			results = move($EntityCollisionBox, $EntityCollisionBox)
		
		if UniqEntity.has_method("collision"): # entity can collide with solid platforms
			if is_in_wall($EntityCollisionBox): # if spawned inside solid platform, kill it
				UniqEntity.kill()
			elif results[1]: # if colliding with a solid platform, runs collision() which can kill it or bounce it
				UniqEntity.collision()
		if Globals.entity_trait.GROUNDED in UniqEntity.TRAITS and UniqEntity.has_method("ledge_stop"):
			if !is_on_ground($SoftPlatformDBox): # spawned in the air, kill it
				UniqEntity.kill()
			elif results[2]: # reached a ledge
				UniqEntity.ledge_stop()
		
	else: # no collision with platforms
		position += velocity.convert_to_vec()
	
	
func simulate_after(): # do this after hit detection
	if Globals.Game.is_stage_paused(): return
	
	if !$HitStopTimer.is_running():
		$SpritePlayer.simulate()
		
		lifetime += 1
		if lifespan != null and lifetime >= lifespan:
			UniqEntity.kill()
				
	# start hitstop timer at end of frame after SpritePlayer.simulate() by setting hitstop to a number other than null for the frame
	# new hitstops override old ones
	if hitstop:
		$HitStopTimer.time = hitstop
		
		
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
	
# --------------------------------------------------------------------------------------------------
		
func face(in_dir):
	if in_dir != 0:
		facing = in_dir
		$Sprite.scale.x = facing
		
func v_face(in_dir):
	if in_dir != 0:
		v_facing = in_dir
		$Sprite.scale.y = v_facing
		
func check_fallthrough(): # return true if entity falls through soft platforms
	if UniqEntity.has_method("check_fallthrough"): # some entities may interact with soft platforms
		return UniqEntity.check_fallthrough()
	else:
		return true
		
func check_passthrough(): # return true if entity ignore walls/floors
	if UniqEntity.has_method("check_passthrough"):
		return UniqEntity.check_passthrough()
	else:
		return false


func on_offstage(): # what to do if entity leaves stage
	if UniqEntity.has_method("on_offstage"):
		UniqEntity.on_offstage()

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

	
func query_move_data_and_name(): # requested by main game node when doing hit detection
	if UniqEntity.has_method("query_move_data"):
		return {"move_data" : UniqEntity.query_move_data(Animator.to_play_animation), "move_name" : Animator.to_play_animation}
#	elif Animator.to_play_animation in UniqEntity.MOVE_DATABASE:
#		return {"move_data" : UniqEntity.MOVE_DATABASE[Animator.to_play_animation], "move_name" : Animator.to_play_animation}
	print("Error: " + Animator.to_play_animation + " not found in MOVE_DATABASE for query_move_data_and_name().")


func query_atk_attr(in_move_name = null): # may have certain conditions, if no move name passed in, check current attack
	
	if in_move_name == null:
		in_move_name = Animator.to_play_animation
	
	if UniqEntity.has_method("query_atk_attr"):
		return UniqEntity.query_atk_attr(in_move_name)
	return []
	
func query_move_data(in_move_name = null):
	
	if in_move_name == null:
		in_move_name = Animator.to_play_animation
		
	var move_data = UniqEntity.query_move_data(in_move_name)
	return move_data
	
	
# LANDING A HIT ---------------------------------------------------------------------------------------------- 

func landed_a_hit(hit_data): # called by main game node when landing a hit
	
	var attacker = get_node(hit_data.attacker_nodepath) # will be this entity's master

#	attacker.UniqueCharacter.landed_a_hit(hit_data) # reaction, nothing here yet, can change hit_data from there

	var defender = get_node(hit_data.defender_nodepath)
	increment_hitcount(defender.player_ID) # for measuring hitcount of attacks
	attacker.targeted_opponent_path = hit_data.defender_nodepath # target last attacked opponent

	# no positive flow for entities

	# EX GAIN ----------------------------------------------------------------------------------------------

	match hit_data.block_state:
		Globals.block_state.UNBLOCKED:
			if !hit_data.double_repeat:
				attacker.change_ex_gauge(hit_data.move_data.EX_gain)
			defender.change_ex_gauge(FMath.percent(hit_data.move_data.EX_gain, 25))
		Globals.block_state.AIR_WRONG, Globals.block_state.GROUND_WRONG:
			if !hit_data.double_repeat:
				attacker.change_ex_gauge(hit_data.move_data.EX_gain)
		Globals.block_state.AIR_PERFECT, Globals.block_state.GROUND_PERFECT:
			defender.change_ex_gauge(hit_data.move_data.EX_gain)
		_:  # normal block
			if !hit_data.double_repeat:
				attacker.change_ex_gauge(FMath.percent(hit_data.move_data.EX_gain, 50))
			defender.change_ex_gauge(FMath.percent(hit_data.move_data.EX_gain, 50))

	# ENTITY HITSTOP ----------------------------------------------------------------------------------------------
		# hitstop is only set into HitStopTimer at end of frame

	if "fixed_entity_hitstop" in hit_data.move_data:
		# multi-hit special/super moves are done by having lower atker hitstop then defender hitstop, and high "hitcount" and ignore_time
		hitstop = hit_data.move_data.fixed_entity_hitstop
	else:
		if hitstop == null or hit_data.hitstop > hitstop: # need to do this to set consistent hitstop during clashes
			hitstop = hit_data.hitstop
			
#	# WIP, change to screen freeze later
#	if hit_data.lethal_hit: # on lethal hit, hitstop this entity's master as well
#		get_node(master_path).get_node("HitStopTimer").time = hit_data.hitstop
			

	# AUDIO ----------------------------------------------------------------------------------------------

	if hit_data.block_state != Globals.block_state.UNBLOCKED: # block sound
		match hit_data.block_state:
			Globals.block_state.AIR_WRONG, Globals.block_state.GROUND_WRONG:
				play_audio("block3", {"vol" : -15})
			Globals.block_state.AIR_PERFECT, Globals.block_state.GROUND_PERFECT:
				play_audio("bling2", {"vol" : -3, "bus" : "PitchDown"})
			_: # normal block
				play_audio("block1", {"vol" : -10, "bus" : "LowPass"})

	elif hit_data.semi_disjoint and !Globals.atk_attr.VULN_LIMBS in defender.query_atk_attr(): # SD Hit sound
		play_audio("bling3", {"bus" : "LowPass"})

	elif "hit_sound" in hit_data.move_data:

		var volume_change = 0
		if hit_data.lethal_hit or hit_data.break_hit or hit_data.sweetspotted:
			volume_change += STRONG_HIT_AUDIO_BOOST
#		elif hit_data.adjusted_atk_level <= 1 or hit_data.double_repeat or hit_data.semi_disjoint: # last for VULN_LIMBS
		elif hit_data.double_repeat:
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
				
	if UniqEntity.has_method("landed_a_hit"):
		UniqEntity.landed_a_hit(hit_data) # reaction
	
	
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
			
	UniqEntity._on_SpritePlayer_anim_finished(anim_name)
	
func _on_SpritePlayer_anim_started(anim_name):
#	match anim_name:
#		_:
#			pass
			
	UniqEntity._on_SpritePlayer_anim_started(anim_name)
	

func play_audio(audio_ref: String, aux_data: Dictionary):
	
	if !audio_ref in LoadedSFX.loaded_audio: # custom audio, have the audioplayer search this node's unique_audio dictionary
		aux_data["unique_path"] = creator_path # add a new key to aux_data
		
	Globals.Game.play_audio(audio_ref, aux_data)

# SAVE/LOAD STATE --------------------------------------------------------------------------------------------------

func save_state():
	var state_data = {
		"position" : position,
		"facing" : facing,
		"v_facing" : v_facing,
		"rotation" : $Sprite.rotation,
		
		"entity_ref" : entity_ref,
		"SpritePlayer_data" : $SpritePlayer.save_state(),
		
		"free" : free,
		"master_path" : master_path,
		"creator_path" : creator_path,
		"true_position_x" : true_position.x,
		"true_position_y" : true_position.y,
		"velocity_x" : velocity.x,
		"velocity_y" : velocity.y,
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
	$Sprite.rotation = state_data.rotation

	entity_ref = state_data.entity_ref
	master_path = state_data.master_path
	creator_path = state_data.creator_path
	load_entity()

	$SpritePlayer.load_state(state_data.SpritePlayer_data)
	
	free = state_data.free
	true_position.x = state_data.true_position_x
	true_position.y = state_data.true_position_y
	velocity.x = state_data.velocity_x
	velocity.y = state_data.velocity_y
	lifetime = state_data.lifetime
	lifespan = state_data.lifespan
	absorption_value = state_data.absorption_value
	life_point = state_data.life_point
	hitcount_record = state_data.hitcount_record
	ignore_list = state_data.ignore_list
	unique_data = state_data.unique_data
	
	$HitStopTimer.time = state_data.HitStopTimer_time

		
#--------------------------------------------------------------------------------------------------
