extends "res://Scenes/Physics/Physics.gd"

const MOB_ENTITY = true
var UniqEntity
onready var Animator = $SpritePlayer

const MOB_LEVEL_TO_DMG = [100, 110, 120, 130, 140, 150, 160, 170, 180]

# to save:
var free := false
var facing := 1
var v_facing := 1
var reflected := false

var master_ID: int # for special cases where an entity has a special effect that affects its master
var entity_ref: String
var creator_mob_ref: String # name of creator, so can look up mob_data in LevelControl under entity_ref
var mob_level: int
var mob_attr: Dictionary
var palette_ref: String

var true_position := FVector.new() # scaled int vector, needed for slow and precise movement
var velocity := FVector.new()
var lifetime := 0
var lifespan = null
var absorption_value = null
var life_point = null # loses 1 on each hit, cannot depend on hitcount (piercing projectiles hit each player only once, for instance)
var hitcount_record = [] # record number of hits for current attack for each player, cannot do anymore hits if maxed out
var ignore_list = [] # some moves has ignore_time, after hitting will ignore that player for a number of frames, used for multi-hit specials
var unique_data = {} # data unique for the entity, stored as a dictionary
var entity_ID := 0
var birth_time := 0
var slowed := 0

# not saved
var hitstop = null


func init(in_master_ID: int, in_entity_ref: String, in_position: Vector2, aux_data: Dictionary, \
		in_mob_level: int, in_mob_attr: Dictionary, in_palette_ref = null, in_creator_mob_ref = null):
	
	set_entity_ID()
	
	birth_time = Globals.Game.frametime
	
	master_ID = in_master_ID
	creator_mob_ref = in_creator_mob_ref
	entity_ref = in_entity_ref
	mob_level = in_mob_level
	mob_attr = in_mob_attr
	if in_palette_ref != null:
		palette_ref = in_palette_ref
	
	position = in_position
	set_true_position()
	
	if aux_data.facing != 0: # just in case
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
		
#	var test_entity = get_child(0) # test entity node should be directly under this node
#	test_entity.free()
	
	load_entity()
		
	if "UNIQUE_DATA_REF" in UniqEntity:
		unique_data = UniqEntity.UNIQUE_DATA_REF.duplicate(true)
		
	UniqEntity.init(aux_data)
	
	
func set_entity_ID(): # each mob has a unique negative entity_ID, set by order when they spawn during a level
	entity_ID = Globals.Game.LevelControl.mob_entity_ID_ref
	Globals.Game.LevelControl.mob_entity_ID_ref -= 1
		
		
func load_entity():

	add_to_group("MobEntityNodes")

	 # character-unique entity with loaded data stored in Globals.Game.LevelControl.mob_data
	var entity_data = Loader.entity_data[entity_ref]
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
		
		if Em.entity_trait.GROUNDED in UniqEntity.TRAITS:
			$EntityCollisionBox.add_to_group("Grounded")

	else: # no collision, delete EntityCollisionBox
		$EntityCollisionBox.free()
		
	if UniqEntity.has_node("DefaultSpriteBox"): # for an entity to go offstage, the entire sprite must be offstage
		var ref_rect = UniqEntity.get_node("DefaultSpriteBox")
		$EntitySpriteBox.rect_position = ref_rect.rect_position
		$EntitySpriteBox.rect_size = ref_rect.rect_size
	else:
		$EntitySpriteBox.free()
		
#	if "PALETTE" in UniqEntity: # load palette
##		if is_common: # common palette stored in Loader.sfx_palettes
#		if UniqEntity.PALETTE in Loader.sfx_palettes:
#			$Sprite.material = ShaderMaterial.new()
#			$Sprite.material.shader = Loader.loaded_palette_shader
#			$Sprite.material.set_shader_param("swap", Loader.sfx_palettes[UniqEntity.PALETTE])
#
#		elif palette_ref != "" and palette_ref in Globals.Game.LevelControl.mob_data[creator_mob_ref].palettes:
#			$Sprite.material = ShaderMaterial.new()
#			$Sprite.material.shader = Loader.loaded_palette_shader
#			$Sprite.material.set_shader_param("swap", Globals.Game.LevelControl.mob_data[creator_mob_ref].palettes[palette_ref])
			
	if "PALETTE" in UniqEntity: # set palette
		if UniqEntity.PALETTE == null: # no palette
			pass
		else:
			if UniqEntity.PALETTE in Loader.sfx_palettes: # common palette
				$Sprite.material = ShaderMaterial.new()
				$Sprite.material.shader = Loader.loaded_palette_shader
				$Sprite.material.set_shader_param("swap", Loader.sfx_palettes[UniqEntity.PALETTE])
				
	elif palette_ref != null:
		if palette_ref in Loader.sfx_palettes: # common palette overwrite
			$Sprite.material = ShaderMaterial.new()
			$Sprite.material.shader = Loader.loaded_palette_shader
			$Sprite.material.set_shader_param("swap", Loader.sfx_palettes[palette_ref])
		elif creator_mob_ref != null and palette_ref in Loader.char_data[creator_mob_ref].palettes: # same palette as creator, just don't add PALETTE to UniqEntity
			$Sprite.material = ShaderMaterial.new()
			$Sprite.material.shader = Loader.loaded_palette_shader
			$Sprite.material.set_shader_param("swap", Loader.char_data[creator_mob_ref].palettes[palette_ref])
			
	if UniqEntity.has_method("load_entity"):
		UniqEntity.load_entity()
		

func simulate():
	hitstop = null
	
	if free: return
	if Globals.Game.is_stage_paused(): return
	if slowed != 0 and (slowed < 0 or posmod(Globals.Game.frametime, slowed) != 0):
		return
	
	$HitStopTimer.simulate() # advancing the hitstop timer at start of frame allow for one frame of knockback before hitstop
	# will be needed for multi-hit moves
	
	if !$HitStopTimer.is_running():
		simulate2()


func simulate2(): # only ran if not in hitstop
	
	UniqEntity.simulate()
	
	ignore_list_progress_timer()
	
	if free:
		$Sprite.hide()
		return
	
	
	if abs(velocity.x) < 5 * FMath.S:
		velocity.x = 0
	if abs(velocity.y) < 5 * FMath.S:
		velocity.y = 0
	
	# movement
	if has_node("EntityCollisionBox"):
		
		var orig_pos = position
		var orig_vel_x = velocity.x
		var orig_vel_y = velocity.y
	
		var results #  # [landing_check, collision_check, ledgedrop_check]
		if Em.entity_trait.GROUNDED in UniqEntity.TRAITS:
			results = move(Em.entity_trait.LEDGE_STOP in UniqEntity.TRAITS)
		else: # for non-grounded entities
			results = move()
		
		if UniqEntity.has_method("collision"): # entity can collide with solid platforms
			if is_in_wall(): # if spawned inside solid platform, kill it
				UniqEntity.kill()
			elif results[1]: # if colliding with a solid platform, runs collision() which can kill it or bounce it
				if $NoCollideTimer.is_running(): # if collide during 1st frame of hitstop, will return to position before moving
					position = orig_pos
					set_true_position()
					velocity.x = orig_vel_x
					velocity.y = orig_vel_y
				else:
					UniqEntity.collision()
		if Em.entity_trait.GROUNDED in UniqEntity.TRAITS:
			if !is_on_solid_ground(): # spawned in the air, kill it
				UniqEntity.kill()
		
	else: # no collision with platforms
		move_no_collision()
		
	interactions() # do this after movement!
	
	
func interactions():
	
	if UniqEntity.has_method("kill") and !Animator.to_play_anim.ends_with("Kill"):
		var my_hitbox = Animator.query_polygon("hitbox")
		if my_hitbox != null:
			
			var my_rect = get_sprite_rect()
			
			var to_destroy := false
			
			var easy_destructible := false # if true, all physical attacks can destroy this entity
			if Em.atk_attr.DESTRUCTIBLE_ENTITY in query_atk_attr() or get_proj_level() == 1:
				easy_destructible = true # use DESTRUCTIBLE_ENTITY for harmless entities, proj_level 1 for projectiles
				
			var indestructible := false
			if Em.atk_attr.INDESTRUCTIBLE_ENTITY in query_atk_attr() or get_proj_level() == 3:
				indestructible = true

			var can_clash := false
			if absorption_value != null and absorption_value > 0:
				can_clash = true

			 # get characters that can destroy this entity
			var character_array = get_tree().get_nodes_in_group("PlayerNodes")
			var destroyer_array = []
			
			for character in character_array:
				if character.player_ID != master_ID and (!"free" in character or !character.free) and character.is_atk_active() and \
						character.slowed >= 0:
					var char_atk_attr = character.query_atk_attr()
					if Em.atk_attr.REFLECT_ENTITIES in char_atk_attr and velocity.x != 0:
						master_ID = character.player_ID
						velocity.x = -velocity.x
						return
						
					if !indestructible and (easy_destructible or Em.atk_attr.DESTROY_ENTITIES in char_atk_attr):
						destroyer_array.append(character)
					
			 # get entities that can destroy or clash with this entity
			var entity_array = get_tree().get_nodes_in_group("EntityNodes")
			var clash_array := []
			for entity in entity_array:
				if !entity.free:
					if !indestructible and Em.atk_attr.DESTROY_ENTITIES in entity.query_atk_attr() and entity.slowed >= 0:
						destroyer_array.append(entity)
					elif can_clash and entity.absorption_value != null and entity.absorption_value > 0:
						clash_array.append(entity)
			
			# check for entity destroyers
			for destroyer in destroyer_array:
				var second_hitbox = destroyer.Animator.query_polygon("hitbox")
				if second_hitbox != null:
					var their_rect = destroyer.get_sprite_rect()
					
					if my_rect.intersects(their_rect):
						var intersect_polygons = Geometry.intersect_polygons_2d(second_hitbox, my_hitbox)
						if intersect_polygons.size() > 0: # detected intersection
							UniqEntity.kill()
							to_destroy = true
							break
					
			# check for clashes
			if !to_destroy and can_clash:
				var clash_array2 = []
				for entity in clash_array:
					var second_hitbox = entity.Animator.query_polygon("hitbox")
					if second_hitbox != null:
						var their_rect = entity.get_sprite_rect()
						
						if my_rect.intersects(their_rect):
							var intersect_polygons = Geometry.intersect_polygons_2d(second_hitbox, my_hitbox)
							if intersect_polygons.size() > 0: # detected intersection
								clash_array2.append(entity) 
		
				if clash_array2.size() > 0:
					var lowest_AV = absorption_value # find lowest absorption_value
					for x in clash_array2:
						if x.absorption_value < lowest_AV:
							lowest_AV = x.absorption_value
							
					absorption_value -= lowest_AV # reduce AV of all entities detected, kill all with 0 AV
					if absorption_value <= 0:
						UniqEntity.kill()
						to_destroy = true
					for x in clash_array2:
						x.absorption_value -= lowest_AV
						if x.absorption_value <= 0:
							x.UniqEntity.kill()	
							x.to_destroy = true
	
	
func simulate_after(): # do this after hit detection
	if Globals.Game.is_stage_paused(): return
	if free: return
	if slowed != 0 and (slowed < 0 or posmod(Globals.Game.frametime, slowed) != 0):
		slowed = 0
		$HitStopTimer.stop()
		return
	slowed = 0
	
	if !$HitStopTimer.is_running():
		$SpritePlayer.simulate()
		
		lifetime += 1
		if lifetime >= Globals.ENTITY_AUTO_DESPAWN: free = true
		elif lifespan != null and lifetime >= lifespan:
			UniqEntity.kill()
			
		if !hitstop:
			$NoCollideTimer.simulate()
				
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

func get_feet_pos(): # return global position of the point the entity is standing on, for SFX emission
	return position + Vector2(0, $EntityCollisionBox.rect_position.y + $EntityCollisionBox.rect_size.y)

func query_polygons(): # requested by main game node when doing hit detection

	var polygons_queried = {
		Em.hit.RECT : null,
		Em.hit.HITBOX : null,
		Em.hit.SWEETBOX: null,
		Em.hit.KBORIGIN: null,
		Em.hit.VACPOINT: null,
	}

	if !$HitStopTimer.is_running() and slowed >= 0: # no hitbox during hitstop
		if !Em.atk_attr.HARMLESS_ENTITY in query_atk_attr():
			polygons_queried[Em.hit.HITBOX] = Animator.query_polygon("hitbox")
			polygons_queried[Em.hit.SWEETBOX] = Animator.query_polygon("sweetbox")
			polygons_queried[Em.hit.KBORIGIN] = Animator.query_point("kborigin")
			polygons_queried[Em.hit.VACPOINT] = Animator.query_point("vacpoint")
			
			if polygons_queried[Em.hit.HITBOX] != null:
				polygons_queried[Em.hit.RECT] = get_sprite_rect()

	return polygons_queried

func get_sprite_rect():
	if UniqEntity.has_method("get_sprite_rect"): return UniqEntity.get_sprite_rect()
	var sprite_rect = $Sprite.get_rect()
	return Rect2(sprite_rect.position + position, sprite_rect.size)
	
func query_move_data_and_name(): # requested by main game node when doing hit detection
	if UniqEntity.has_method("query_move_data"):
		var move_name = Animator.to_play_anim
		if UniqEntity.has_method("refine_move_name"):
			move_name = UniqEntity.refine_move_name(move_name)
		return {Em.hit.MOVE_DATA : UniqEntity.query_move_data(Animator.to_play_anim), Em.hit.MOVE_NAME : move_name}
#	elif Animator.to_play_anim in UniqEntity.MOVE_DATABASE:
#		return {Em.hit.MOVE_DATA : UniqEntity.MOVE_DATABASE[Animator.to_play_anim], Em.hit.MOVE_NAME : Animator.to_play_anim}
	print("Error: " + Animator.to_play_anim + " not found in MOVE_DATABASE for query_move_data_and_name().")


func query_atk_attr(in_move_name = null): # may have certain conditions, if no move name passed in, check current attack
	
	if in_move_name == null:
		in_move_name = Animator.to_play_anim
	
	if UniqEntity.has_method("query_atk_attr"):
		return UniqEntity.query_atk_attr(in_move_name)
	return []
	
func query_move_data(in_move_name = null):
	
	if in_move_name == null:
		in_move_name = Animator.to_play_anim
		
	var move_data = UniqEntity.query_move_data(in_move_name)
	return move_data
	
#func get_proj_level():
#	if UniqEntity.MOVE_DATABASE.size() == 0: return null
#	else:
#		var move_data = query_move_data()
#		if Em.move.PROJ_LVL in move_data:
#			return move_data[Em.move.PROJ_LVL]
#	return null
	
func get_proj_level(in_move_name = null):
	
	if in_move_name == null:
		in_move_name = Animator.to_play_anim
	
	if UniqEntity.has_method("get_proj_level"):
		return UniqEntity.get_proj_level(in_move_name)
	return 1
	
func modify_stat(to_return, attr: int, values: Array):
	return FMath.percent(to_return, values[int(clamp(mob_attr[attr], 0, values.size() - 1))])
	
# LANDING A HIT ---------------------------------------------------------------------------------------------- 

func landed_a_hit(hit_data): # called by main game node when landing a hit
	
	var attacker = Globals.Game.get_player_node(hit_data[Em.hit.ATKER_ID]) # will be this entity's master
	if attacker != null:
		attacker.target_ID = hit_data[Em.hit.DEFENDER_ID] # target last attacked opponent

#	var defender = Globals.Game.get_player_node(hit_data[Em.hit.DEFENDER_ID])
	
	increment_hitcount(hit_data[Em.hit.DEFENDER_ID]) # for measuring hitcount of attacks


	# ENTITY HITSTOP ----------------------------------------------------------------------------------------------
		# hitstop is only set into HitStopTimer at end of frame

	if Em.move.FIXED_ATKER_HITSTOP in hit_data[Em.hit.MOVE_DATA]:
		hitstop = hit_data[Em.hit.MOVE_DATA][Em.move.FIXED_ATKER_HITSTOP]
		
	elif hit_data[Em.hit.LETHAL_HIT] or hit_data[Em.hit.STUN]:
		hitstop = null # no hitstop for entity for lethal hit, screenfreeze already enough
		
	else:
		if hitstop == null or hit_data[Em.hit.HITSTOP] > hitstop:
			hitstop = hit_data[Em.hit.HITSTOP]			
			
	if hitstop != null and hitstop > 0: # will freeze in place if colliding 1 frame after hitstop, more if has ignore_time, to make multi-hit projectiles more consistent
		if Em.hit.MULTIHIT in hit_data and Em.move.IGNORE_TIME in hit_data[Em.hit.MOVE_DATA]:
			$NoCollideTimer.time = hit_data[Em.hit.MOVE_DATA][Em.move.IGNORE_TIME]
		else:
			$NoCollideTimer.time = 1

	# AUDIO ----------------------------------------------------------------------------------------------

	if Em.move.HIT_SOUND in hit_data[Em.hit.MOVE_DATA]:

		if !hit_data[Em.hit.MOVE_DATA][Em.move.HIT_SOUND] is Array:
			play_audio(hit_data[Em.hit.MOVE_DATA][Em.move.HIT_SOUND].ref, hit_data[Em.hit.MOVE_DATA][Em.move.HIT_SOUND].aux_data)
		else: # multiple sounds at once
			for sound in hit_data[Em.hit.MOVE_DATA][Em.move.HIT_SOUND]:
				play_audio(sound.ref, sound.aux_data)
	
	
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
	
	if recorded_hitcount >= in_move_data[Em.move.HITCOUNT]:
		return true
	else: return false
	
	
func is_hitcount_last_hit(in_ID, in_move_data):
	var recorded_hitcount = get_hitcount(in_ID)
	
	if recorded_hitcount >= in_move_data[Em.move.HITCOUNT] - 1:
		return true
	else: return false
	
	
func is_hitcount_first_hit(in_ID): # for multi-hit moves, only 1st hit affect Guard Gauge
	var recorded_hitcount = get_hitcount(in_ID)
	if recorded_hitcount == 0: return true
	else: return false
	
	
# IGNORE LIST ------------------------------------------------------------------------------------------------
	
func append_ignore_list(in_ID, ignore_time): # added if the move has Em.move.IGNORE_TIME, called by the defender
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
	

func rotate_sprite(angle: int):
	angle = posmod(angle, 360)
	match facing:
		1:
			if angle > 90 and angle < 270:
				face(-facing)
				$Sprite.rotation = deg2rad(posmod(angle + 180, 360))
			else:
				$Sprite.rotation = deg2rad(angle)
		-1:
			if angle < 90 or angle > 270:
				face(-facing)
				$Sprite.rotation = deg2rad(angle)
			else:
				$Sprite.rotation = deg2rad(posmod(angle + 180, 360))
				
func rotate_sprite_x_axis(angle: int): # use to rotate sprite without changing facing
	$Sprite.rotation += deg2rad(angle * facing)

func play_audio(audio_ref: String, aux_data: Dictionary):
	
#	if !audio_ref in Loader.audio: # custom audio, have the audioplayer search this node's unique_audio dictionary
#		aux_data["mob_ref"] = creator_mob_ref # add a new key to aux_data
		
	Globals.Game.play_audio(audio_ref, aux_data)

# SAVE/LOAD STATE --------------------------------------------------------------------------------------------------

func save_state():
	var state_data = {
		"position" : position,
		"facing" : facing,
		"v_facing" : v_facing,
		"rotation" : $Sprite.rotation,
		"modulate" : $Sprite.modulate,
		
		"master_ID" : master_ID,
		"entity_ref" : entity_ref,
		"creator_mob_ref" : creator_mob_ref,
		"mob_level" : mob_level,
		"mob_attr": mob_attr,
		"palette_ref" : palette_ref,
		"SpritePlayer_data" : $SpritePlayer.save_state(),
		
		"free" : free,
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
		"entity_ID" : entity_ID,
		"birth_time" : birth_time,
		"slowed" : slowed,
		
		"HitStopTimer_time" : $HitStopTimer.time,
		"NoCollideTimer_time" : $NoCollideTimer.time,
	}
	return state_data

func load_state(state_data):
	position = state_data.position
	facing = state_data.facing
	$Sprite.scale.x = facing
	v_facing = state_data.v_facing
	$Sprite.scale.y = v_facing
	$Sprite.rotation = state_data.rotation
	$Sprite.modulate = state_data.modulate

	master_ID = state_data.master_ID
	entity_ref = state_data.entity_ref
	creator_mob_ref = state_data.creator_mob_ref
	mob_level = state_data.mob_level
	mob_attr = state_data.mob_attr
	palette_ref = state_data.palette_ref
	entity_ID = state_data.entity_ID
	birth_time = state_data.birth_time
	slowed = state_data.slowed
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
	$NoCollideTimer.time = state_data.NoCollideTimer_time

		
#--------------------------------------------------------------------------------------------------
