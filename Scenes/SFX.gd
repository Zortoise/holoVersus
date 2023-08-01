extends Node2D

#var master_node = null # not saved, set when loading state

var free := false
var slowed := 0
var field := false # if true, not affected by fields

var master_ref = null
var sfx_ref

var palette_ref = null
var palette_master_ID = null

var ignore_freeze := false

var sticky_ID = null
var sticky_offset = null
var sticky_type = Em.sticky_sfx_type.CHAR

# for common sfx, in_sfx_ref is a string pointing to loaded sfx in NSAnims.gb
# for master's palette, place "palette_master_ID" : player_ID in aux_data
# aux_data contain {"back" : bool, "facing" : 1/-1, "v_mirror" : bool, "rot" : radians, "grounded" : true, "back" : true}
func init(in_anim: String, in_sfx_ref: String, in_position: Vector2, aux_data: Dictionary, in_palette_ref = null, in_master_ref = null):
	
	sfx_ref = in_sfx_ref
	master_ref = in_master_ref
	palette_ref = in_palette_ref
#	if in_master_ID != null:
#		master_ID = in_master_ID
#		master_node = Globals.Game.get_player_node(master_ID)
#	mob_ref = in_mob_ref
	
	load_sfx_ref() # load frame data and spritesheet
	
	position = in_position
	if "facing" in aux_data:
		$Sprite.scale.x = aux_data.facing
	if "v_mirror" in aux_data and aux_data.v_mirror: # mirror vertically, for hitsparks
		$Sprite.scale.y = -1
	if "rot" in aux_data:
		$Sprite.rotation = aux_data.rot * $Sprite.scale.x
	if "grounded" in aux_data:
		$GroundedBox.add_to_group("Grounded")
	if "sticky_ID" in aux_data:
#		if master_ID == null:
#			print("Error: Did not pass in master_ID for sticky SFX!")
#		else:
		sticky_ID = aux_data.sticky_ID
		if "sticky_type" in aux_data:
			sticky_type = aux_data.sticky_type
			match sticky_type:
				Em.sticky_sfx_type.CHAR:
					sticky_offset = in_position - Globals.Game.get_player_node(sticky_ID).position
				Em.sticky_sfx_type.ENTITY:
					sticky_offset = in_position - Globals.Game.get_entity_node(sticky_ID).position
				Em.sticky_sfx_type.NPC:
					sticky_offset = in_position - Globals.Game.get_NPC_node(sticky_ID).position
		else:
			sticky_offset = in_position - Globals.Game.get_player_node(sticky_ID).position
	if "field" in aux_data:
		field = true
		
	if palette_ref != null:
		palette()
		
		
	$SpritePlayer.play(in_anim)
	
	if Globals.Game.is_stage_paused(): # if spawned during screenfreeze, will not be frozen during screenfreeze
		ignore_freeze = true
	
	
func load_sfx_ref(): # load frame data and spritesheet
	
	if sfx_ref in Loader.sfx:
		$Sprite.texture = Loader.sfx[sfx_ref].spritesheet
		$SpritePlayer.init_with_loaded_frame_data($Sprite, Loader.sfx[sfx_ref].frame_data)
		
#	elif master_ID != null and sfx_ref in master_node.sfx_data: # unique sfx
#		$Sprite.texture = master_node.sfx_data[sfx_ref].spritesheet
#		$SpritePlayer.init_with_loaded_frame_data($Sprite, master_node.sfx_data[sfx_ref].frame_data)
#
#	elif mob_ref != null and sfx_ref in Globals.Game.LevelControl.mob_data[mob_ref].sfx_data:
#		$Sprite.texture = Globals.Game.LevelControl.mob_data[mob_ref].sfx_data[sfx_ref].spritesheet
#		$SpritePlayer.init_with_loaded_frame_data($Sprite, Globals.Game.LevelControl.mob_data[mob_ref].sfx_data[sfx_ref].frame_data)
#
#	elif Globals.survival_level != null and sfx_ref in  Globals.Game.LevelControl.loaded_sfx: # survival sfx
#		$Sprite.texture = Globals.Game.LevelControl.loaded_sfx[sfx_ref].spritesheet
#		$SpritePlayer.init_with_loaded_frame_data($Sprite, Globals.Game.LevelControl.loaded_sfx[sfx_ref].frame_data)	
		
	else:
		print("Error: sfx_ref not found.")


func palette():
	if palette_ref != null and !(palette_ref is String and palette_ref == "red"):
		if palette_ref in Loader.sfx_palettes: # common palette
			$Sprite.material = ShaderMaterial.new()
			$Sprite.material.shader = Loader.loaded_palette_shader
			$Sprite.material.set_shader_param("swap", Loader.sfx_palettes[palette_ref])
				
		elif master_ref != null: # same palette as a character
			if master_ref in Loader.char_data and palette_ref in Loader.char_data[master_ref].palettes:
				$Sprite.material = ShaderMaterial.new()
				$Sprite.material.shader = Loader.loaded_palette_shader
				$Sprite.material.set_shader_param("swap", Loader.char_data[master_ref].palettes[palette_ref])
			elif master_ref in Loader.NPC_data and palette_ref in Loader.NPC_data[master_ref].palettes:
				$Sprite.material = ShaderMaterial.new()
				$Sprite.material.shader = Loader.loaded_palette_shader
				$Sprite.material.set_shader_param("swap", Loader.NPC_data[master_ref].palettes[palette_ref])
			
#	elif palette_master_ID != null: # same palette as master
#		var master_node = Globals.Game.get_player_node(palette_master_ID)
#		if master_node != null and master_node.palette_number != 1:
#			$Sprite.material = ShaderMaterial.new()
#			$Sprite.material.shader = Loader.loaded_palette_shader
#			$Sprite.material.set_shader_param("swap", master_node.get_palette())


func simulate():
	if sticky_ID != null:
		var master_node
		match sticky_type:
			Em.sticky_sfx_type.CHAR:
				master_node = Globals.Game.get_player_node(sticky_ID)
			Em.sticky_sfx_type.ENTITY:
				master_node = Globals.Game.get_entity_node(sticky_ID)
			Em.sticky_sfx_type.NPC:
				master_node = Globals.Game.get_NPC_node(sticky_ID)
			
		if master_node != null:
			position = master_node.position + sticky_offset
		else:
			free = true

		
	if Globals.Game.is_stage_paused() and !ignore_freeze: return
	if slowed != 0 and (slowed < 0 or posmod(Globals.Game.frametime, slowed) != 0):
		slowed = 0
		return
	slowed = 0
	
	$SpritePlayer.simulate()


func _on_SpritePlayer_anim_finished(_anim_name):
	free = true # don't use queue_free!


# SAVE/LOAD STATE --------------------------------------------------------------------------------------------------

func save_state():
	var state_data = {
		"sfx_ref" : sfx_ref,
		"master_ref" : master_ref,
		"SpritePlayer_data" : $SpritePlayer.save_state(),
		"free" : free,
		"position" : position,
		"scale" : $Sprite.scale,
		"rotation" : $Sprite.rotation,
		"palette_ref" : palette_ref,
		"palette_master_ID" : palette_master_ID,
		"ignore_freeze" : ignore_freeze,
		"sticky_ID" : sticky_ID,
		"sticky_offset" : sticky_offset,
		"sticky_type" : sticky_type,
		"slowed" : slowed,
		"field" : field,
	}
	return state_data
	
func load_state(state_data):
	position = state_data.position
	$Sprite.scale = state_data.scale
	$Sprite.rotation = state_data.rotation
	
	sfx_ref = state_data.sfx_ref
	master_ref = state_data.master_ref
	load_sfx_ref()
	
	palette_ref = state_data.palette_ref
	palette_master_ID = state_data.palette_master_ID
	if palette_ref != null or palette_master_ID != null:
		palette()
	
	$SpritePlayer.load_state(state_data.SpritePlayer_data)
	free = state_data.free
	ignore_freeze = state_data.ignore_freeze
	slowed = state_data.slowed
	field = state_data.field
	
	sticky_ID = state_data.sticky_ID
	sticky_offset = state_data.sticky_offset
	sticky_type = state_data.sticky_type
#	if sticky_ID != null:
#		var master_node
#		if sticky_entity:
#			master_node = Globals.Game.get_entity_node(sticky_ID)
#		else:
#			master_node = Globals.Game.get_player_node(sticky_ID)
#		if master_node != null:
#			position = master_node.position + sticky_offset
#		else:
#			free = true
	
#--------------------------------------------------------------------------------------------------
