extends Node2D

const PALETTE = null

const TRAITS = [Globals.entity_trait.GROUNDED]

# cleaner code
onready var Entity = get_parent()
var Animator
var sprite


const MOVE_DATABASE = {
}

func init(_aux_data: Dictionary):
	Animator.play("Spawn") # starting animation

func simulate():
	if Animator.to_play_animation == "Spawn" and get_node(Entity.creator_path).unique_data.nibbler_cancel > 0:
		Globals.Game.spawn_SFX("SmallSplash", "SmallSplash", Entity.position, {"facing":Entity.facing, "grounded":true, \
				"palette":"master"}, get_node(Entity.creator_path).player_ID)
		Entity.free = true # cancel spawning if master got hit
		
	elif Animator.current_animation == "Kill" and Animator.time == 5:
		var spawn_point = Animator.query_point("entityspawn")
		Globals.Game.spawn_entity(get_node(Entity.creator_path).player_ID, "Nibbler", spawn_point, {"facing" : Entity.facing})
		Globals.Game.spawn_SFX("BigSplash", "BigSplash", Entity.position, \
				{"facing":Entity.facing, "grounded":true, "palette":"master"}, get_node(Entity.creator_path).player_ID)
		Entity.play_audio("water6", {"vol" : -20})
		Entity.free = true
	
func _on_SpritePlayer_anim_finished(anim_name):
	match anim_name:
		"Spawn":
			Animator.play("Kill")
			
func _on_SpritePlayer_anim_started(anim_name):
	match anim_name:
		"Kill":
			var new_facing_ref = Globals.Game.get_player_node(get_node(Entity.creator_path).target_ID).position.x - \
					Entity.position.x
			if new_facing_ref != 0: # turn to face targeted opponent on the start of "Kill" animation
				Entity.face(sign(new_facing_ref))

