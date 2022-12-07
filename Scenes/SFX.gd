extends Node2D


var free := false
var loaded_sfx_ref

var palette_ref = null

# for common sfx, loaded_sfx_ref is a string pointing to loaded sfx in LoadedSFX.gb
# for unique sfx, loaded_sfx_ref will be a NodePath leading to the sfx's loaded FrameData .tres file and loaded spritesheet
func init(in_anim: String, in_loaded_sfx_ref, in_position: Vector2, aux_data: Dictionary):
	
	loaded_sfx_ref = in_loaded_sfx_ref
	load_sfx_ref() # load frame data and spritesheet
	
	position = in_position
	if "facing" in aux_data:
		scale.x = aux_data.facing
	if "v_mirror" in aux_data and aux_data.v_mirror: # mirror vertically, for hitsparks
		scale.y = -1
	if "rot" in aux_data:
		rotation = aux_data.rot * scale.x
	if "grounded" in aux_data:
		$GroundedBox.add_to_group("Grounded")
	if "palette" in aux_data:
		palette_ref = aux_data.palette
		palette()
		
	$SpritePlayer.play(in_anim)
	
	
func load_sfx_ref(): # load frame data and spritesheet
	if !loaded_sfx_ref is NodePath: # loaded_sfx_ref is a string pointing to loaded sfx in LoadedSFX.gb
		$Sprite.texture = LoadedSFX.loaded_sfx[loaded_sfx_ref]["spritesheet"]
		$SpritePlayer.init_with_loaded_frame_data($Sprite, LoadedSFX.loaded_sfx[loaded_sfx_ref]["frame_data"])
	else: # loaded_sfx_ref is a NodePath leading to the sfx's loaded FrameData .tres file and loaded spritesheet
		# WIP
		pass


func palette():
	if palette_ref in LoadedSFX.loaded_sfx_palette:
		$Sprite.material = ShaderMaterial.new()
		$Sprite.material.shader = Globals.loaded_palette_shader
		$Sprite.material.set_shader_param("swap", LoadedSFX.loaded_sfx_palette[palette_ref])
		

func stimulate():
	$SpritePlayer.stimulate()


func _on_SpritePlayer_anim_finished(_anim_name):
	free = true # don't use queue_free!


# SAVE/LOAD STATE --------------------------------------------------------------------------------------------------

func save_state():
	var state_data = {
		"loaded_sfx_ref" : loaded_sfx_ref,
		"SpritePlayer_data" : $SpritePlayer.save_state(),
		"free" : free,
		"position" : position,
		"scale" : scale,
		"rotation" : rotation,
		"palette_ref" : palette_ref
	}
	return state_data
	
func load_state(state_data):
	position = state_data.position
	scale = state_data.scale
	rotation = state_data.rotation
	palette_ref = state_data.palette_ref
	if state_data.palette_ref != null:
		palette()
	
	loaded_sfx_ref = state_data.loaded_sfx_ref
	load_sfx_ref()

	$SpritePlayer.load_state(state_data.SpritePlayer_data)
	free = state_data.free
	
#--------------------------------------------------------------------------------------------------
