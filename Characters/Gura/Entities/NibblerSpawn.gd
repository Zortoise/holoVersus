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
	Animator.play("Kill") # starting animation

func stimulate():
	pass
	
func _on_SpritePlayer_anim_finished(anim_name):
	match anim_name:
		_:
			pass
			
func _on_SpritePlayer_anim_started(anim_name):
	match anim_name:
		"Kill":
			Entity.play_audio("water4", {"unique_path" : Entity.master_path, "vol" : -23})
			Entity.play_audio("water8", {"unique_path" : Entity.master_path, "vol" : -13})

