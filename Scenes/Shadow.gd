extends Node2D

var free := false

var life # current
var lifetime
var starting_modulate_a
var sprite_node_path


func init(in_sprite_node_path, in_position, in_starting_modulate_a = 0.5, in_lifetime = 10.0):
	life = float(in_lifetime)
	lifetime = float(in_lifetime)
	starting_modulate_a = float(in_starting_modulate_a)
	position = in_position
	sprite_node_path = in_sprite_node_path
	# pass the absolute sprite_node_path all the way here to duplicate
	var sprite = get_node(sprite_node_path).duplicate()
	add_child(sprite)

func stimulate():
	life -= 1.0
	modulate.a = lerp(starting_modulate_a, 0.0, 1.0 - life/lifetime)
	
	if life <= 0.0:
		free = true # don't use queue_free!


# SAVE/LOAD STATE --------------------------------------------------------------------------------------------------

func save_state():
	var state_data = {
		"sprite_node_path" : sprite_node_path,
		"life" : life,
		"lifetime" : lifetime,
		"starting_modulate_a" : starting_modulate_a,
		"free" : free,
		"position" : position,
	}
	return state_data
	
func load_state(state_data):
	
	position = state_data.position
	
	sprite_node_path = state_data.sprite_node_path
	var sprite = get_node(sprite_node_path).duplicate()
	add_child(sprite)

	life = state_data.life
	lifetime = state_data.lifetime
	starting_modulate_a = state_data.starting_modulate_a
	free = state_data.free

	modulate.a = lerp(starting_modulate_a, 0.0, 1.0 - life/lifetime)
	pass
	
#--------------------------------------------------------------------------------------------------
