extends Node2D

var free := false

var life # current
var lifetime
var color_modulate
var starting_modulate_a

var master_path: NodePath
var spritesheet_ref: String


func init(in_master_path, in_spritesheet_ref, sprite_node_path, in_color_modulate = null, \
		in_starting_modulate_a = 0.5, in_lifetime = 10.0):
	
	master_path = in_master_path
	spritesheet_ref = in_spritesheet_ref
	if spritesheet_ref in get_node(master_path).spritesheets:
		$Sprite.texture = get_node(master_path).spritesheets[spritesheet_ref]
	elif spritesheet_ref in get_node(master_path).entity_data: # entity ref passed in instead
		$Sprite.texture = get_node(master_path).entity_data[spritesheet_ref].spritesheet
	else:
		print("Error: " + spritesheet_ref + " spritesheet not found in Shadow.gd.")


	var sprite_base = get_node(sprite_node_path)
	$Sprite.hframes = sprite_base.hframes
	$Sprite.vframes = sprite_base.vframes
	$Sprite.frame = sprite_base.frame
	$Sprite.scale = sprite_base.scale
	$Sprite.rotation = sprite_base.rotation
	
	color_modulate = in_color_modulate
	if color_modulate != null:
		$Sprite.modulate.r = color_modulate.r
		$Sprite.modulate.g = color_modulate.g
		$Sprite.modulate.b = color_modulate.b
	
	life = float(in_lifetime)
	lifetime = float(in_lifetime)
	starting_modulate_a = float(in_starting_modulate_a)
	position = sprite_base.global_position

func stimulate():
	life -= 1.0
	modulate.a = lerp(starting_modulate_a, 0.0, 1.0 - life/lifetime)
	
	if life <= 0.0:
		free = true # don't use queue_free!


# SAVE/LOAD STATE --------------------------------------------------------------------------------------------------

func save_state():
	var state_data = {
		"master_path" : master_path,
		"spritesheet_ref" : spritesheet_ref,
		"hframes" : $Sprite.hframes,
		"vframes" : $Sprite.vframes,
		"frame" : $Sprite.frame,
		"scale" : $Sprite.scale,
		"rotation" : $Sprite.rotation,
		"color_modulate" : color_modulate,
		
		"life" : life,
		"lifetime" : lifetime,
		"starting_modulate_a" : starting_modulate_a,
		"free" : free,
		"position" : position,
	}
	return state_data
	
func load_state(state_data):
	
	master_path = state_data.master_path
	spritesheet_ref = state_data.spritesheet_ref
	if spritesheet_ref in get_node(master_path).spritesheets:
		$Sprite.texture = get_node(master_path).spritesheets[spritesheet_ref]
	elif spritesheet_ref in get_node(master_path).entity_data: # entity ref passed in instead
		$Sprite.texture = get_node(master_path).entity_data[spritesheet_ref].spritesheet
	else:
		print("Error: " + spritesheet_ref + " spritesheet not found in Shadow.gd.")
	
	$Sprite.hframes = state_data.hframes
	$Sprite.vframes = state_data.vframes
	$Sprite.frame = state_data.frame
	$Sprite.scale = state_data.scale
	$Sprite.rotation = state_data.rotation
	
	color_modulate = state_data.color_modulate
	if color_modulate != null:
		$Sprite.modulate.r = color_modulate.r
		$Sprite.modulate.g = color_modulate.g
		$Sprite.modulate.b = color_modulate.b

	life = state_data.life
	lifetime = state_data.lifetime
	starting_modulate_a = state_data.starting_modulate_a
	free = state_data.free
	position = state_data.position

	modulate.a = lerp(starting_modulate_a, 0.0, 1.0 - life/lifetime)
	
#--------------------------------------------------------------------------------------------------
