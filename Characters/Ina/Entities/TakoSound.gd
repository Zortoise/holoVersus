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

func init(_aux_data: Dictionary):
	Animator.play("Kill")

func simulate():
	match Animator.time:
		7:
			fire_tako(-40)
		14:
			fire_tako(0)
		21:
			fire_tako(40)
		28:
			fire_tako(20)
		35:
			fire_tako(-20)
	
func fire_tako(angle: int):
	if Entity.facing == -1:
		angle = Globals.mirror_angle(angle)
	Globals.Game.spawn_entity(Entity.master_ID, "Tako", Entity.position, \
			{"facing" : Entity.facing, "angle" : angle, "repeat" : true}, Entity.palette_ref, Entity.master_ref)
	Globals.Game.spawn_SFX("Blink", "Blink", Entity.position, {"facing":Globals.Game.rng_facing()}, Entity.palette_ref, Entity.master_ref)

	var master_node = Globals.Game.get_player_node(Entity.master_ID)
	if master_node.UniqChar.has_method("expire_extra_takos"):
		master_node.UniqChar.expire_extra_takos()
	
	
func query_atk_attr(_move_name):
	return []
	
	
func _on_SpritePlayer_anim_finished(anim_name):
	match anim_name:
		_:
			pass
			
func _on_SpritePlayer_anim_started(anim_name):
	match anim_name:
		_:
			pass

