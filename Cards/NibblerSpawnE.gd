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
	if Animator.current_animation == "Kill" and Animator.time == 5:
		var spawn_point = Animator.query_point("entityspawn")
		Globals.Game.spawn_entity(get_node(Entity.creator_path).player_ID, "NibblerE", spawn_point, {"facing" : Entity.facing})
		Globals.Game.spawn_SFX("BigSplash", "BigSplash", Entity.position, {"facing":Entity.facing, "grounded":true})
		Entity.play_audio("water6", {"vol" : -20, "surv" : true})
		Entity.free = true
	
func _on_SpritePlayer_anim_finished(anim_name):
	match anim_name:
		"Spawn":
			Animator.play("Kill")
			
func _on_SpritePlayer_anim_started(anim_name):
	match anim_name:
		"Kill":
			var new_facing_ref = get_node(Entity.creator_path).get_target().position.x - \
					Entity.position.x
			if new_facing_ref != 0: # turn to face targeted opponent on the start of "Kill" animation
				Entity.face(sign(new_facing_ref))

