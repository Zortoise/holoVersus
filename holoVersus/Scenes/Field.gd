extends "res://Scenes/Physics/Physics.gd"

var UniqEntity
onready var Animator = $SpritePlayer

# to save:
var free := false

var facing := 1
var v_facing := 1
var master_ID: int # can be different from creator

var entity_ref: String
var master_ref # always creator, use it to find palette
var palette_ref

var true_position := FVector.new() # scaled int vector, needed for slow and precise movement
var velocity := FVector.new()
var lifetime := 0
var lifespan = null
var unique_data = {} # data unique for the entity, stored as a dictionary
var entity_ID := 0
var birth_time := 0


func init(in_master_ID: int, in_entity_ref: String, in_position: Vector2, aux_data: Dictionary, in_palette_ref = null, in_master_ref = null):
	
	entity_ID = Globals.Game.entity_ID_ref
	Globals.Game.entity_ID_ref += 1
	birth_time = Globals.Game.frametime
	
	master_ID = in_master_ID
	entity_ref = in_entity_ref
	
	master_ref = in_master_ref # for palette
	palette_ref = in_palette_ref
	
	position = in_position
	set_true_position()
	
	if !"facing" in aux_data:
		face(Globals.Game.get_player_node(master_ID).facing) # face in same direction as master
	elif aux_data.facing != 0: # just in case
		face(aux_data.facing)
	
	load_entity()
		
	if "UNIQUE_DATA_REF" in UniqEntity:
		unique_data = UniqEntity.UNIQUE_DATA_REF.duplicate(true)
		
	UniqEntity.init(aux_data)
	
		
func load_entity():

	if entity_ref in Loader.entity_data:
		UniqEntity = Loader.entity_data[entity_ref].scene.instance() # load UniqEntity scene
		$SpritePlayer.init_with_loaded_frame_data($Sprite, Loader.entity_data[entity_ref].frame_data) # load frame data
		$Sprite.texture = Loader.entity_data[entity_ref].spritesheet # load spritesheet
	else:
		print("Error: " + entity_ref + " entity not found in Loader.entity_data")

		
	add_child(UniqEntity)
	move_child(UniqEntity, 0)
	UniqEntity.sprite = $Sprite
	UniqEntity.Animator = $SpritePlayer
		
	if UniqEntity.has_node("DefaultSpriteBox"): # for an entity to go offstage, the entire sprite must be offstage
		var ref_rect = UniqEntity.get_node("DefaultSpriteBox")
		$EntitySpriteBox.rect_position = ref_rect.rect_position
		$EntitySpriteBox.rect_size = ref_rect.rect_size
	else:
		$EntitySpriteBox.free()
		
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
		elif master_ref != null and palette_ref in Loader.char_data[master_ref].palettes: # same palette as creator, just don't add PALETTE to UniqEntity
			$Sprite.material = ShaderMaterial.new()
			$Sprite.material.shader = Loader.loaded_palette_shader
			$Sprite.material.set_shader_param("swap", Loader.char_data[master_ref].palettes[palette_ref])
			
	if UniqEntity.has_method("load_entity"):
		UniqEntity.load_entity()
				

func simulate():
	
	if Globals.Game.is_stage_paused(): return
	if free: return
	
	UniqEntity.simulate()
	
	if free:
		$Sprite.hide()
		return
		
	if "TARGETS" in UniqEntity:
		if Em.field_target.MOBS in UniqEntity.TARGETS:
			for node in get_tree().get_nodes_in_group("MobNodes"):
				inflict(node)
				
		if Em.field_target.MOB_ENTITIES in UniqEntity.TARGETS:
			for node in get_tree().get_nodes_in_group("MobEntityNodes"):
				inflict(node)
				
		if Em.field_target.PLAYERS in UniqEntity.TARGETS:
			for node in get_tree().get_nodes_in_group("PlayerNodes"):
				inflict(node)
				
		if Em.field_target.PLAYER_ENTITIES in UniqEntity.TARGETS:
			for node in get_tree().get_nodes_in_group("EntityNodes"):
				inflict(node)
				
		if Em.field_target.MASTER in UniqEntity.TARGETS:
			inflict(Globals.Game.get_player_node(master_ID))
				
		if Em.field_target.MASTER_ENTITIES in UniqEntity.TARGETS:
			if master_ID >= 0:
				for node in get_tree().get_nodes_in_group("EntityNodes"):
					if node.master_ID == master_ID:
						inflict(node)
			else:
				for node in get_tree().get_nodes_in_group("MobEntityNodes"):
					if node.master_ID == master_ID:
						inflict(node)
				
		if Em.field_target.OPPONENTS in UniqEntity.TARGETS:
			for node in get_tree().get_nodes_in_group("PlayerNodes"):
				if node.player_ID != master_ID:
					inflict(node)
				
		if Em.field_target.OPPONENT_ENTITIES in UniqEntity.TARGETS:
			for node in get_tree().get_nodes_in_group("EntityNodes"):
				if node.master_ID != master_ID:
					inflict(node)
					
		if Em.field_target.NPCS in UniqEntity.TARGETS:
			for node in get_tree().get_nodes_in_group("NPCNodes"):
				inflict(node)
					
		if Em.field_target.MASTER_NPCS in UniqEntity.TARGETS:
			for node in get_tree().get_nodes_in_group("NPCNodes"):
				if node.master_ID == master_ID:
					inflict(node)
					
		if Em.field_target.OPPONENT_NPCS in UniqEntity.TARGETS:
			for node in get_tree().get_nodes_in_group("NPCNodes"):
				if node.master_ID != master_ID:
					inflict(node)

				
		if Em.field_target.EFFECTS in UniqEntity.TARGETS:
			
			var sfx_nodes = Globals.Game.get_node("SFXFront").get_children()
			sfx_nodes.append_array(Globals.Game.get_node("SFXBack").get_children())
			
			for node in sfx_nodes:
				if node.field: pass
				elif node.sticky_ID != null:
					
					if Em.field_target.MOBS in UniqEntity.TARGETS:
						if node.sticky_type == Em.sticky_sfx_type.CHAR and node.sticky_ID < 0: inflict(node)
					if Em.field_target.PLAYERS in UniqEntity.TARGETS:
						if node.sticky_type == Em.sticky_sfx_type.CHAR and node.sticky_ID >= 0: inflict(node)
					if Em.field_target.MASTER in UniqEntity.TARGETS:
						if node.sticky_type == Em.sticky_sfx_type.CHAR and node.sticky_ID == master_ID: inflict(node)
					if Em.field_target.OPPONENTS in UniqEntity.TARGETS:
						if node.sticky_type == Em.sticky_sfx_type.CHAR and node.sticky_ID != master_ID: inflict(node)
						
					if Em.field_target.PLAYER_ENTITIES in UniqEntity.TARGETS:
						if node.sticky_type == Em.sticky_sfx_type.ENTITY and \
								Globals.Game.get_entity_node(node.sticky_ID).master_ID >= 0: inflict(node)
					if Em.field_target.MOB_ENTITIES in UniqEntity.TARGETS:
						if node.sticky_type == Em.sticky_sfx_type.ENTITY and \
								Globals.Game.get_entity_node(node.sticky_ID).master_ID < 0: inflict(node)
					if Em.field_target.MASTER_ENTITIES in UniqEntity.TARGETS:
						if node.sticky_type == Em.sticky_sfx_type.ENTITY and \
								Globals.Game.get_entity_node(node.sticky_ID).master_ID == master_ID: inflict(node)
					if Em.field_target.OPPONENT_ENTITIES in UniqEntity.TARGETS:
						if node.sticky_type == Em.sticky_sfx_type.ENTITY and \
								Globals.Game.get_entity_node(node.sticky_ID).master_ID != master_ID: inflict(node)
					
					if Em.field_target.NPCS in UniqEntity.TARGETS:
						if node.sticky_type == Em.sticky_sfx_type.NPC: inflict(node)		
					if Em.field_target.MASTER_NPCS in UniqEntity.TARGETS:
						if node.sticky_type == Em.sticky_sfx_type.NPC and \
								Globals.Game.get_NPC_node(node.sticky_ID).master_ID == master_ID: inflict(node)
					if Em.field_target.OPPONENT_NPCS in UniqEntity.TARGETS:
						if node.sticky_type == Em.sticky_sfx_type.NPC and \
								Globals.Game.get_NPC_node(node.sticky_ID).master_ID != master_ID: inflict(node)
						
				else: inflict(node)
				
			for node in Globals.Game.get_node("Afterimages").get_children(): # original_ID is negative
				if Em.field_target.MOBS in UniqEntity.TARGETS:
					if node.type == Em.afterimage_type.CHAR and node.original_ID < 0: inflict(node)
				if Em.field_target.PLAYERS in UniqEntity.TARGETS:
					if node.type == Em.afterimage_type.CHAR and node.original_ID >= 0: inflict(node)
				if Em.field_target.MASTER in UniqEntity.TARGETS:
					if node.type == Em.afterimage_type.CHAR and node.original_ID == master_ID: inflict(node)
				if Em.field_target.OPPONENTS in UniqEntity.TARGETS:
					if node.type == Em.afterimage_type.CHAR and node.original_ID != master_ID: inflict(node)
					
				if Em.field_target.PLAYER_ENTITIES in UniqEntity.TARGETS:
					if node.type == Em.afterimage_type.ENTITY and \
							Globals.Game.get_entity_node(node.original_ID).master_ID >= 0: inflict(node)
				if Em.field_target.MOB_ENTITIES in UniqEntity.TARGETS:
					if node.type == Em.afterimage_type.ENTITY and \
							Globals.Game.get_entity_node(node.original_ID).master_ID < 0: inflict(node)
				if Em.field_target.MASTER_ENTITIES in UniqEntity.TARGETS:
					if node.type == Em.afterimage_type.ENTITY and \
							Globals.Game.get_entity_node(node.original_ID).master_ID == master_ID: inflict(node)
				if Em.field_target.OPPONENT_ENTITIES in UniqEntity.TARGETS:
					if node.type == Em.afterimage_type.ENTITY and \
							Globals.Game.get_entity_node(node.original_ID).master_ID != master_ID: inflict(node)
				
				if Em.field_target.NPCS in UniqEntity.TARGETS:
					if node.type == Em.afterimage_type.NPC: inflict(node)		
				if Em.field_target.MASTER_NPCS in UniqEntity.TARGETS:
					if node.type == Em.afterimage_type.NPC and \
							Globals.Game.get_NPC_node(node.original_ID).master_ID == master_ID: inflict(node)
				if Em.field_target.OPPONENT_NPCS in UniqEntity.TARGETS:
					if node.type == Em.afterimage_type.NPC and \
							Globals.Game.get_NPC_node(node.original_ID).master_ID != master_ID: inflict(node)
				


	if abs(velocity.x) < 5 * FMath.S:
		velocity.x = 0
	if abs(velocity.y) < 5 * FMath.S:
		velocity.y = 0
	
	# movement
	# no collision with platforms
	move_no_collision()
	
	$SpritePlayer.simulate()
	lifetime += 1
	if lifetime >= Globals.ENTITY_AUTO_DESPAWN: free = true
	elif lifespan != null and lifetime >= lifespan and UniqEntity.has_method("expire"):
		UniqEntity.expire()


func inflict(node):
	if "RADIUS" in UniqEntity:
		var vec_to_test = node.position - position
		if !Globals.is_length_longer(vec_to_test, UniqEntity.RADIUS):
			UniqEntity.inflict(node)
			
	elif "RECT_SIZE" in UniqEntity:
		if node.position.x <= position.x + FMath.percent(UniqEntity.RECT_SIZE.x, 50) and \
				node.position.x >= position.x - FMath.percent(UniqEntity.RECT_SIZE.x, 50) and \
				node.position.y <= position.y + FMath.percent(UniqEntity.RECT_SIZE.y, 50) and \
				node.position.y >= position.y - FMath.percent(UniqEntity.RECT_SIZE.y, 50):
			UniqEntity.inflict(node)
	
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
		

# ANIMATION AND AUDIO PROCESSING ---------------------------------------------------------------------------------------------------

func _on_SpritePlayer_anim_finished(anim_name):
	
	if anim_name.ends_with("Kill") or anim_name.ends_with("Expire"):
		free = true # don't use queue_free!
			
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
	Globals.Game.play_audio(audio_ref, aux_data)

# SAVE/LOAD STATE --------------------------------------------------------------------------------------------------

func save_state():
	var state_data = {
		"position" : position,
		"facing" : facing,
		"v_facing" : v_facing,
		"rotation" : $Sprite.rotation,
		"visible" : $Sprite.visible,
		
		"entity_ref" : entity_ref,
		"master_ID" : master_ID,
		"master_ref" : master_ref,
		"palette_ref" : palette_ref,
		
		"SpritePlayer_data" : $SpritePlayer.save_state(),
		
		"free" : free,
		"true_position_x" : true_position.x,
		"true_position_y" : true_position.y,
		"velocity_x" : velocity.x,
		"velocity_y" : velocity.y,
		"lifetime" : lifetime,
		"lifespan" : lifespan,
		"unique_data" : unique_data,
		"entity_ID" : entity_ID,
		"birth_time" : birth_time,
	}
	return state_data

func load_state(state_data):
	position = state_data.position
	facing = state_data.facing
	$Sprite.scale.x = facing
	v_facing = state_data.v_facing
	$Sprite.scale.y = v_facing
	$Sprite.rotation = state_data.rotation
	$Sprite.visible = state_data.visible

	entity_ref = state_data.entity_ref
	master_ID = state_data.master_ID
	master_ref = state_data.master_ref
	palette_ref = state_data.palette_ref
	entity_ID = state_data.entity_ID
	
	birth_time = state_data.birth_time
	load_entity()

	$SpritePlayer.load_state(state_data.SpritePlayer_data)
	
	free = state_data.free
	true_position.x = state_data.true_position_x
	true_position.y = state_data.true_position_y
	velocity.x = state_data.velocity_x
	velocity.y = state_data.velocity_y
	lifetime = state_data.lifetime
	lifespan = state_data.lifespan
	unique_data = state_data.unique_data

		
#--------------------------------------------------------------------------------------------------
