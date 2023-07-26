extends Node2D


const TRAITS = []

# cleaner code
onready var Entity = get_parent()
var Animator
var sprite


const MOVE_DATABASE = {
}

func _ready():
	get_node("TestSprite").free() # test sprite is for sizing collision box

func init(aux_data: Dictionary):
	
	Animator.play("Spawn")
	Entity.unique_data["aux"] = aux_data

func simulate():
	pass
	
	
func query_atk_attr(_move_name):
	return [Em.atk_attr.HARMLESS_ENTITY, Em.atk_attr.DESTRUCTIBLE_ENTITY]
	
func kill():
	if !Animator.to_play_anim.ends_with("Kill"):
		Animator.play("Kill")
	
func _on_SpritePlayer_anim_finished(anim_name):
	match anim_name:
		"Spawn":
			Animator.play("Kill")
			var aux = Entity.unique_data["aux"]
			aux["facing"] = Entity.facing
			Globals.Game.spawn_entity(Entity.master_ID, "TakoE", Entity.position, aux)
			Globals.Game.spawn_SFX("TakoFlash", "TakoFlash", Entity.position, {"facing":Entity.facing})
			Entity.play_audio("blast4", {"vol" : -15})
			
func _on_SpritePlayer_anim_started(anim_name):
	match anim_name:
		_:
			pass

