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

func stimulate():
	if Animator.to_play_animation == "Spawn" and get_node(Entity.master_path).unique_data.nibbler_cancel == true:
		Globals.Game.spawn_SFX("SmallSplash", [Entity.master_path, "SmallSplash"], Entity.position, {"facing":Entity.facing, "grounded":true})
		Entity.free = true # cancel spawning if master got hit
		
	elif Animator.current_animation == "Kill" and Animator.time == 5:
		var spawn_point = Entity.position + Animator.query_point("entityspawn")
		Globals.Game.spawn_entity(Entity.master_path, "Nibbler", spawn_point, {"facing" : Entity.facing})
		Globals.Game.spawn_SFX("MediumSplash", [Entity.master_path, "MediumSplash"], Entity.position, {"facing":Entity.facing, "grounded":true})
		Entity.play_audio("water6", {"unique_path" : Entity.master_path, "vol" : -20})
		Entity.free = true
	
func _on_SpritePlayer_anim_finished(anim_name):
	match anim_name:
		"Spawn":
			Animator.play("Kill")
			
func _on_SpritePlayer_anim_started(anim_name):
	match anim_name:
		"Kill":
			var new_facing_ref = get_node(get_node(Entity.master_path).targeted_opponent_path).position.x - Entity.position.x
			if new_facing_ref != 0: # turn to face targeted opponent on the start of "Kill" animation
				Entity.face(sign(new_facing_ref))

