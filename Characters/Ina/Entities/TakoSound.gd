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
	Animator.play("Kill")
	Entity.unique_data["aim"] = aux_data.aim

func simulate():
	match Animator.time:
		20:
			match Entity.unique_data.aim:
				0:
					fire_tako(-40)
				1:
					fire_tako(5)
				-1:
					fire_tako(-5)
		27:
			match Entity.unique_data.aim:
				0:
					fire_tako(0)
				1:
					fire_tako(45)
				-1:
					fire_tako(-45)
		34:
			match Entity.unique_data.aim:
				0:
					fire_tako(40)
				1:
					fire_tako(85)
				-1:
					fire_tako(-85)
		41:
			match Entity.unique_data.aim:
				0:
					fire_tako(20)
				1:
					fire_tako(65)
				-1:
					fire_tako(-65)
		48:
			match Entity.unique_data.aim:
				0:
					fire_tako(-20)
				1:
					fire_tako(25)
				-1:
					fire_tako(-25)
	
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

