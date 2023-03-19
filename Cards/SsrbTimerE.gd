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
	Animator.play("Time5")
	if "sticky_ID" in aux_data:
		Entity.unique_data["sticky_ID"] = aux_data.sticky_ID
	else:
		Entity.free = true
	

			
func simulate():
	var sticky = Globals.Game.get_entity_node(Entity.unique_data.sticky_ID)
	if sticky == null:
		Entity.free = true
	else:
		Entity.position = sticky.position
					
	
func time(anim_name: String):
	if Animator.to_play_animation != anim_name:
		Animator.play(anim_name)
	
	
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

