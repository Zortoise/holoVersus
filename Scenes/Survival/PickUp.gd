extends "res://Scenes/Physics/Physics.gd"

const GRAVITY = 50 * FMath.S # per frame
const TERMINAL_VELOCITY_MOD = 900 # affect terminal velocity downward
const AIR_RESISTANCE = 3
const FRICTION = 15
const BASE_LIFESPAN = 300
const FLASHING_TIME = 60

var UniqEntity
onready var Animator = $SpritePlayer

# to save:
var free := false

var item_ref: String
var palette_ref: String

var true_position := FVector.new() # scaled int vector, needed for slow and precise movement
var velocity := FVector.new()
var lifetime := 0
var lifespan = null
var stasis := false # if true, no movement and gravity
var ground_bounce_limit := 2 # can only bounce once on ground


func init(in_item_ref: String, in_position: Vector2, aux_data: Dictionary, in_lifespan = null, in_palette_ref = null):
	
	item_ref = in_item_ref
	if in_lifespan != null:
		lifespan = in_lifespan
	else:
		lifespan = BASE_LIFESPAN
	if in_palette_ref != null:
		palette_ref = in_palette_ref
		
	if "vel_array" in aux_data:
		velocity.set_vector(aux_data.vel_array[0], 0)
		velocity.rotate(aux_data.vel_array[1])
	
	position = in_position
	set_true_position()
	
	load_entity()
		
	UniqEntity.init(aux_data)
	
		
func load_entity():

	# item_data[item_ref] = { # uses common audio
#		"scene" : load(_),
#		"frame_data" : ResourceLoader.load(_),
#		"spritesheet" : ResourceLoader.load(_),
#	}
	var item_data = Globals.Game.LevelControl.item_data[item_ref]
	UniqEntity = item_data.scene.instance() # load UniqEntity scene
	$SpritePlayer.init_with_loaded_frame_data($Sprite, item_data.frame_data) # load frame data
	$Sprite.texture = item_data.spritesheet # load spritesheet
		
	add_child(UniqEntity)
	move_child(UniqEntity, 0)
	UniqEntity.sprite = $Sprite
	UniqEntity.Animator = $SpritePlayer
	
	# set up collision box dimensions
	if UniqEntity.has_node("DefaultCollisionBox"):
		var ref_rect = UniqEntity.get_node("DefaultCollisionBox")
		$EntityCollisionBox.rect_position = ref_rect.rect_position
		$EntityCollisionBox.rect_size = ref_rect.rect_size
		$EntityCollisionBox.add_to_group("Entities") # for moving platforms and offstage detection
		
		if Globals.entity_trait.GROUNDED in UniqEntity.TRAITS:
			$EntityCollisionBox.add_to_group("Grounded")
			
#		if Globals.entity_trait.GROUNDED in UniqEntity.TRAITS:
#			$EntityCollisionBox.add_to_group("Grounded")
#			$SoftPlatformDBox.rect_position.x = ref_rect.rect_position.x
#			$SoftPlatformDBox.rect_position.y = ref_rect.rect_position.y + ref_rect.rect_size.y - 1
#			$SoftPlatformDBox.rect_size.x = ref_rect.rect_size.x
#			$SoftPlatformDBox.rect_size.y = 1
#		else:
#			$SoftPlatformDBox.free()

	else: # no collision, delete EntityCollisionBox
		$EntityCollisionBox.free()
		
	if UniqEntity.has_node("DefaultSpriteBox"): # for an entity to go offstage, the entire sprite must be offstage
		var ref_rect = UniqEntity.get_node("DefaultSpriteBox")
		$EntitySpriteBox.rect_position = ref_rect.rect_position
		$EntitySpriteBox.rect_size = ref_rect.rect_size
	else:
		$EntitySpriteBox.free()
		
	if palette_ref != "":
		if palette_ref in LoadedSFX.loaded_sfx_palettes: # common palettes
			$Sprite.material = ShaderMaterial.new()
			$Sprite.material.shader = Globals.loaded_palette_shader
			$Sprite.material.set_shader_param("swap", LoadedSFX.loaded_sfx_palettes[palette_ref])
		elif palette_ref in item_data.palettes: # palette in loaded item data in LevelControl
			$Sprite.material = ShaderMaterial.new()
			$Sprite.material.shader = Globals.loaded_palette_shader
			$Sprite.material.set_shader_param("swap", item_data.palettes[palette_ref])	
		
#	if "PALETTE" in UniqEntity: # load palette
#		if is_common: # common palette stored in LoadedSFX.loaded_sfx_palettes
#			if UniqEntity.PALETTE in LoadedSFX.loaded_sfx_palettes:
#				$Sprite.material = ShaderMaterial.new()
#				$Sprite.material.shader = Globals.loaded_palette_shader
#				$Sprite.material.set_shader_param("swap", LoadedSFX.loaded_sfx_palettes[UniqEntity.PALETTE])
#
#		elif get_node(creator_path).loaded_palette != null: # same palette as creator, just set UniqEntity.PALETTE to null
#			$Sprite.material = ShaderMaterial.new()
#			$Sprite.material.shader = Globals.loaded_palette_shader
#			$Sprite.material.set_shader_param("swap", get_node(creator_path).loaded_palette)

func simulate():
	
	if Globals.Game.is_stage_paused(): return
	
	UniqEntity.simulate()
	
	if free:
		$Sprite.hide()
		return
		

	if !stasis:
	
		# flashing if running out of lifespan
		if lifetime + FLASHING_TIME >= lifespan:
			var value = posmod(Globals.Game.frametime, 8)
			if value < 4:
				$Sprite.show()
			else:
				$Sprite.hide()
		
		# gravity and friction
		if Globals.entity_trait.GROUNDED in UniqEntity.TRAITS:
			if !is_on_ground($EntityCollisionBox):
				velocity.y += GRAVITY
				var terminal = FMath.percent(GRAVITY, TERMINAL_VELOCITY_MOD)
				if velocity.y > terminal:
					velocity.y = FMath.f_lerp(velocity.y, terminal, 75)
				velocity.x = FMath.f_lerp(velocity.x, 0, AIR_RESISTANCE)
			else:
				velocity.x = FMath.f_lerp(velocity.x, 0, FRICTION)
		
		
		if abs(velocity.x) < 5 * FMath.S:
			velocity.x = 0
		if abs(velocity.y) < 5 * FMath.S:
			velocity.y = 0
		
		
		# movement
		if has_node("EntityCollisionBox"):
			
	#		var orig_pos = position
			var orig_vel_x = velocity.x
			var orig_vel_y = velocity.y
		
			var results #  # [landing_check, collision_check, ledgedrop_check]
			results = move($EntityCollisionBox, $EntityCollisionBox)
			
			if is_in_wall($EntityCollisionBox): # if spawned inside solid platform, kill it
				free = true
			else:
				if results[1]:
					bounce(orig_vel_x, orig_vel_y, results[0])
			
	#		if UniqEntity.has_method("collision"): # entity can collide with solid platforms
	#			if results[1]: # if colliding with a solid platform, runs collision() which can kill it or bounce it
	#				UniqEntity.collision()
					
			
		else: # no collision with platforms
			true_position.x += velocity.x
			true_position.y += velocity.y
			position = true_position.convert_to_vec()
		
		
		if UniqEntity.has_method("picked_up") and Animator.current_animation == "Active": # no pickup during spawn
			pickup()
	
	
func pickup():
	var character_array = get_tree().get_nodes_in_group("PlayerNodes")
	for character in character_array:
		if Detection.detect_duo(character.get_node("PlayerCollisionBox"), $EntityCollisionBox):
			if UniqEntity.picked_up(character):
				break
	
	
func simulate_after(): # do this after hit detection
	if Globals.Game.is_stage_paused(): return
	
	$SpritePlayer.simulate()
	
	lifetime += 1
	if !stasis and lifespan != null and lifetime >= lifespan:
		UniqEntity.kill()


		
		
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
			
func bounce(orig_vel_x, orig_vel_y, against_ground: bool):
	if is_against_wall($EntityCollisionBox, $EntityCollisionBox, sign(orig_vel_x)):
		velocity.x = -FMath.percent(orig_vel_x, 75)
				
	elif is_against_ceiling($EntityCollisionBox, $EntityCollisionBox):
		velocity.y = -FMath.percent(orig_vel_y, 50)
				
	elif against_ground:
		if ground_bounce_limit > 1:
			velocity.y = -FMath.percent(orig_vel_y, 100)
			ground_bounce_limit -= 1
			UniqEntity.bounce_sound()
		elif ground_bounce_limit == 1:
			velocity.y = -FMath.percent(orig_vel_y, 50)
			ground_bounce_limit -= 1
			UniqEntity.bounce_sound(true)
		else:
			velocity.y = 0
			
			
func on_offstage(): # what to do if entity leaves stage
	free = true

# ANIMATION AND AUDIO PROCESSING ---------------------------------------------------------------------------------------------------

func _on_SpritePlayer_anim_finished(anim_name):
	
#	if anim_name.ends_with("Kill"):
#		free = true # don't use queue_free!
		
	match anim_name:
		"Pickup":
			free = true
			
	UniqEntity._on_SpritePlayer_anim_finished(anim_name)
	
func _on_SpritePlayer_anim_started(anim_name):
	match anim_name:
		"Pickup":
			velocity.set_vector(0, 0)
			$Sprite.show()
			
	UniqEntity._on_SpritePlayer_anim_started(anim_name)
	

func play_audio(audio_ref: String, aux_data: Dictionary):
	
	if !audio_ref in LoadedSFX.loaded_audio: # use common audio only
		return
		
	Globals.Game.play_audio(audio_ref, aux_data)

# SAVE/LOAD STATE --------------------------------------------------------------------------------------------------

func save_state():
	var state_data = {
		"position" : position,
		"rotation" : $Sprite.rotation,
		"visible" : $Sprite.visible,
		
		"item_ref" : item_ref,
		"palette_ref" : palette_ref,
		"SpritePlayer_data" : $SpritePlayer.save_state(),
		
		"free" : free,
		"true_position_x" : true_position.x,
		"true_position_y" : true_position.y,
		"velocity_x" : velocity.x,
		"velocity_y" : velocity.y,
		"lifetime" : lifetime,
		"lifespan" : lifespan,
		
		"ground_bounce_limit" : ground_bounce_limit,
		"stasis" : stasis,
	}
	return state_data

func load_state(state_data):
	position = state_data.position
	$Sprite.rotation = state_data.rotation
	$Sprite.visible = state_data.visible

	item_ref = state_data.item_ref
	palette_ref = state_data.palette_ref
	load_entity()

	$SpritePlayer.load_state(state_data.SpritePlayer_data)
	
	free = state_data.free
	true_position.x = state_data.true_position_x
	true_position.y = state_data.true_position_y
	velocity.x = state_data.velocity_x
	velocity.y = state_data.velocity_y
	lifetime = state_data.lifetime
	lifespan = state_data.lifespan
	
	ground_bounce_limit = state_data.ground_bounce_limit
	stasis = state_data.stasis

		
#--------------------------------------------------------------------------------------------------
