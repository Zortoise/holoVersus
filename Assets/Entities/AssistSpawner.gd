extends Node2D


const TRAITS = []

const ASSIST_SPAWN_TIME = 30

# cleaner code
onready var Entity = get_parent()
var Animator
var sprite


const MOVE_DATABASE = {
}

func _ready():
	get_node("TestSprite").free() # test sprite is for sizing collision box

func init(aux_data: Dictionary):
	
#	aux_data = {
#		"NPC_ref" : NPC_ref,
#		"start_facing" : start_facing,
#		"atk_ID" : atk_ID,
#	}
	
	match Entity.master_ID:
		0:
			Animator.play("Assist0")
		1:
			Animator.play("Assist1")
			
	Entity.unique_data["aux"] = aux_data
	Entity.play_audio("bling5", {"vol" : -10})
	

func simulate():
	if Entity.lifetime >= ASSIST_SPAWN_TIME:
		Globals.Game.spawn_assist(Entity.master_ID, Entity.unique_data.aux.NPC_ref, Entity.position, \
				Entity.unique_data.aux.start_facing, Entity.unique_data.aux.palette_ref, Entity.unique_data.aux.atk_ID)
		Entity.free = true
	
func query_atk_attr(_move_name):
	return []
	
func kill():
	Entity.free = true
	
func _on_SpritePlayer_anim_finished(anim_name):
	match anim_name:
		_:
			pass
			
func _on_SpritePlayer_anim_started(anim_name):
	match anim_name:
		_:
			pass

