extends Node2D

var master_node = null # not saved, set when loading state

var free := false
var sfx_ref

var master_ID = null
var mob_ref = null

var palette_ref = null
var ignore_freeze := false

var sticky_offset = null

# for common sfx, loaded_sfx_ref is a string pointing to loaded sfx in LoadedSFX.gb
# for master's palette, place "palette" : "master" in aux_data
# aux_data contain {"back" : bool, "facing" : 1/-1, "v_mirror" : bool, "rot" : radians, "grounded" : true, "back" : true}
func init(in_anim: String, in_sfx_ref: String, in_position: Vector2, aux_data: Dictionary, in_master_ID = null, in_mob_ref = null):
	
	sfx_ref = in_sfx_ref
	if in_master_ID != null:
		master_ID = in_master_ID
		master_node = Globals.Game.get_player_node(master_ID)
	mob_ref = in_mob_ref
	
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
	if "palette" in aux_data:
		palette_ref = aux_data.palette
		palette()
	if "sticky" in aux_data:
		if master_ID == null:
			print("Error: Did not pass in master_ID for sticky SFX!")
		else:
			sticky_offset = in_position - master_node.position
		
		
	$SpritePlayer.play(in_anim)
	
	if Globals.Game.is_stage_paused(): # if spawned during screenfreeze, will not be frozen during screenfreeze
		ignore_freeze = true
	
	
func load_sfx_ref(): # load frame data and spritesheet
	
	if sfx_ref in LoadedSFX.loaded_sfx: # common sfx
		$Sprite.texture = LoadedSFX.loaded_sfx[sfx_ref].spritesheet
		$SpritePlayer.init_with_loaded_frame_data($Sprite, LoadedSFX.loaded_sfx[sfx_ref].frame_data)
		
	elif master_ID != null and sfx_ref in master_node.sfx_data: # unique sfx
		$Sprite.texture = master_node.sfx_data[sfx_ref].spritesheet
		$SpritePlayer.init_with_loaded_frame_data($Sprite, master_node.sfx_data[sfx_ref].frame_data)
		
	elif mob_ref != null and sfx_ref in Globals.Game.LevelControl.mob_data[mob_ref].sfx_data:
		$Sprite.texture = Globals.Game.LevelControl.mob_data[mob_ref].sfx_data[sfx_ref].spritesheet
		$SpritePlayer.init_with_loaded_frame_data($Sprite, Globals.Game.LevelControl.mob_data[mob_ref].sfx_data[sfx_ref].frame_data)
		
	elif Globals.survival_level != null and sfx_ref in  Globals.Game.LevelControl.loaded_sfx: # survival sfx
		$Sprite.texture = Globals.Game.LevelControl.loaded_sfx[sfx_ref].spritesheet
		$SpritePlayer.init_with_loaded_frame_data($Sprite, Globals.Game.LevelControl.loaded_sfx[sfx_ref].frame_data)	
		
	else:
		print("Error: sfx_ref not found.")


func palette():
	if palette_ref in LoadedSFX.loaded_sfx_palettes:
		$Sprite.material = ShaderMaterial.new()
		$Sprite.material.shader = Globals.loaded_palette_shader
		$Sprite.material.set_shader_param("swap", LoadedSFX.loaded_sfx_palettes[palette_ref])
			
	elif mob_ref != null:
		if palette_ref in Globals.Game.LevelControl.mob_data[mob_ref].palettes:
			$Sprite.material = ShaderMaterial.new()
			$Sprite.material.shader = Globals.loaded_palette_shader
			$Sprite.material.set_shader_param("swap", Globals.Game.LevelControl.mob_data[mob_ref].palettes[palette_ref])
			
	elif master_ID != null and palette_ref == "master" and master_node.loaded_palette != null: # same palette as master
		$Sprite.material = ShaderMaterial.new()
		$Sprite.material.shader = Globals.loaded_palette_shader
		$Sprite.material.set_shader_param("swap", master_node.loaded_palette)


func simulate():
	if sticky_offset != null:
		position = master_node.position + sticky_offset
		
	if Globals.Game.is_stage_paused() and !ignore_freeze: return
	
	$SpritePlayer.simulate()


func _on_SpritePlayer_anim_finished(_anim_name):
	free = true # don't use queue_free!


# SAVE/LOAD STATE --------------------------------------------------------------------------------------------------

func save_state():
	var state_data = {
		"sfx_ref" : sfx_ref,
		"master_ID" : master_ID,
		"mob_ref" : mob_ref,
		"SpritePlayer_data" : $SpritePlayer.save_state(),
		"free" : free,
		"position" : position,
		"scale" : $Sprite.scale,
		"rotation" : $Sprite.rotation,
		"palette_ref" : palette_ref,
		"ignore_freeze" : ignore_freeze,
		"sticky_offset" : sticky_offset,
	}
	return state_data
	
func load_state(state_data):
	position = state_data.position
	$Sprite.scale = state_data.scale
	$Sprite.rotation = state_data.rotation
	
	sfx_ref = state_data.sfx_ref
	master_ID = state_data.master_ID
	if master_ID != null:
		master_node = Globals.Game.get_player_node(master_ID)
	mob_ref = state_data.mob_ref
	load_sfx_ref()
	
	palette_ref = state_data.palette_ref
	if state_data.palette_ref != null:
		palette()
	
	$SpritePlayer.load_state(state_data.SpritePlayer_data)
	free = state_data.free
	ignore_freeze = state_data.ignore_freeze
	
	sticky_offset = state_data.sticky_offset
	if sticky_offset != null:
		position = master_node.position + sticky_offset
	
#--------------------------------------------------------------------------------------------------
