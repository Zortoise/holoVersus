extends Node2D


var free := false
var sfx_ref

var palette_ref = null
var ignore_freeze := false

# for common sfx, loaded_sfx_ref is a string pointing to loaded sfx in LoadedSFX.gb
# for unique sfx, in_sfx_ref will be a an array with master's nodepath as 1st entry and string for 2nd entry
# for master's palette, place "palette" : get_path() in aux_data, palette_ref will be master's nodepath
# aux_data contain {"back" : bool, "facing" : 1/-1, "v_mirror" : bool, "rot" : radians, "grounded" : true, "back" : true}
func init(in_anim: String, in_sfx_ref, in_position: Vector2, aux_data: Dictionary):
	
	sfx_ref = in_sfx_ref
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
	
	if Globals.Game.is_stage_paused(): # if spawned during screenfreeze, will not be frozen during screenfreeze
		ignore_freeze = true
	
	
func load_sfx_ref(): # load frame data and spritesheet
	if sfx_ref is String and sfx_ref in LoadedSFX.loaded_sfx: # common sfx
		$Sprite.texture = LoadedSFX.loaded_sfx[sfx_ref]["spritesheet"]
		$SpritePlayer.init_with_loaded_frame_data($Sprite, LoadedSFX.loaded_sfx[sfx_ref]["frame_data"])
	elif sfx_ref is Array: # unique sfx, loaded_sfx_ref will be a an array with master's nodepath as 1st entry and string for 2nd entry
		$Sprite.texture = get_node(sfx_ref[0]).sfx_data[sfx_ref[1]]["spritesheet"]
		$SpritePlayer.init_with_loaded_frame_data($Sprite, get_node(sfx_ref[0]).sfx_data[sfx_ref[1]]["frame_data"])
	else:
		print("Error: sfx_ref not found.")


func palette():
	if !palette_ref is NodePath:
		if palette_ref in LoadedSFX.loaded_sfx_palette:
			$Sprite.material = ShaderMaterial.new()
			$Sprite.material.shader = Globals.loaded_palette_shader
			$Sprite.material.set_shader_param("swap", LoadedSFX.loaded_sfx_palette[palette_ref])
	elif get_node(palette_ref).loaded_palette != null: # same palette as master, just set UniqueEntity.PALETTE to null
		$Sprite.material = ShaderMaterial.new()
		$Sprite.material.shader = Globals.loaded_palette_shader
		$Sprite.material.set_shader_param("swap", get_node(palette_ref).loaded_palette)

func stimulate():
	if Globals.Game.is_stage_paused() and !ignore_freeze: return
	
	$SpritePlayer.stimulate()


func _on_SpritePlayer_anim_finished(_anim_name):
	free = true # don't use queue_free!


# SAVE/LOAD STATE --------------------------------------------------------------------------------------------------

func save_state():
	var state_data = {
		"sfx_ref" : sfx_ref,
		"SpritePlayer_data" : $SpritePlayer.save_state(),
		"free" : free,
		"position" : position,
		"scale" : scale,
		"rotation" : rotation,
		"palette_ref" : palette_ref,
		"ignore_freeze" : ignore_freeze
	}
	return state_data
	
func load_state(state_data):
	position = state_data.position
	scale = state_data.scale
	rotation = state_data.rotation
	palette_ref = state_data.palette_ref
	if state_data.palette_ref != null:
		palette()
	
	sfx_ref = state_data.sfx_ref
	load_sfx_ref()

	$SpritePlayer.load_state(state_data.SpritePlayer_data)
	free = state_data.free
	ignore_freeze = state_data.ignore_freeze
	
#--------------------------------------------------------------------------------------------------
