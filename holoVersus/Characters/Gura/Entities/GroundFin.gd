extends Node2D

const ID = "ground_fin" # for master to find it
#const START_SPEED = 500

const TRAITS = [Em.entity_trait.GROUNDED, Em.entity_trait.LEDGE_STOP]
# example: Em.entity_trait.GROUNDED

# cleaner code
onready var Entity = get_parent()
var Animator
var sprite


const MOVE_DATABASE = {
}

func _ready():
	get_node("TestSprite").free() # test sprite is for sizing collision box

func init(aux_data: Dictionary):

	 # starting animation
	if "held" in aux_data:
		Animator.play("[h]Spawn")
	else:
		Animator.play("Spawn")

	if "ex" in aux_data: # set starting lifespan
		Entity.lifespan = 600
	else:
		Entity.lifespan = 300	
		
	match Animator.to_play_anim:
		"Spawn":
			Entity.velocity.set_vector(250 * FMath.S, 0)
			Entity.velocity.x *= Entity.facing
		"[h]Spawn":
			Entity.velocity.set_vector(150 * FMath.S, 0)
			Entity.velocity.x *= Entity.facing
			
func simulate():
	
	match Animator.to_play_anim: # triggering shark breach
		"Active", "[h]Active", "Turn", "[h]Turn":
			var master_node = Globals.Game.get_player_node(Entity.master_ID)
			if "groundfin_trigger" in master_node.unique_data and master_node.unique_data.groundfin_trigger:
#				var breach_facing = get_node(Entity.master_path).get_last_tapped_dir()
#				var turned := false
#				if breach_facing == 0:
#					breach_facing = get_node(Entity.master_path).dir
#				else:
#					turned = true # aleady turned via get_last_tapped_dir()
#				if breach_facing == 0:
#					breach_facing = Entity.facing
				var breach_facing = Entity.facing
				var new_facing_ref = master_node.get_target().position.x - Entity.position.x
				if new_facing_ref != 0: # turn to face targeted opponent
					breach_facing = sign(new_facing_ref)
				Globals.Game.spawn_entity(Entity.master_ID, "SharkBreach", Entity.position, {"facing" : breach_facing}, Entity.palette_ref, Entity.master_ref)
				Entity.play_audio("water4", {"vol" : -23})
				Entity.play_audio("water8", {"vol" : -13})
				# reduce ground fin count
#				master_node.unique_data.groundfin_count = max(0, master_node.unique_data.groundfin_count - 1)
				Entity.free = true
				
				
func query_atk_attr(_move_name):
	return [Em.atk_attr.HARMLESS_ENTITY, Em.atk_attr.DESTRUCTIBLE_ENTITY, Em.atk_attr.NO_REFLECT_ENTITY]

	
func kill(_sound = true):
	if !Animator.to_play_anim.ends_with("Kill"):
		Animator.play("Kill")
		# reduce ground fin count
#		var master_node = Globals.Game.get_player_node(Entity.master_ID)
#		master_node.unique_data.groundfin_count = max(0, master_node.unique_data.groundfin_count - 1)
	
func expire():
	kill()
	
func collision(_landed := false, _orig_vel_x := 0, _orig_vel_y := 0): # collided with a wall, turns
	ledge_stop()
	
func ledge_stop(): # about to go off the ledge, turns
	match Animator.to_play_anim:
		"Spawn", "Active":
			Animator.play("Turn")
		"[h]Spawn", "[h]Active":
			Animator.play("[h]Turn")
	
func _on_SpritePlayer_anim_finished(anim_name):
	match anim_name:
		"Spawn":
			Animator.play("Active")
		"[h]Spawn":
			Animator.play("[h]Active")
			
		"Turn":
			Animator.play("Active")
			Entity.velocity.set_vector(250 * FMath.S, 0)
			Entity.velocity.x *= Entity.facing
		"[h]Turn":
			Animator.play("[h]Active")
			Entity.velocity.set_vector(150 * FMath.S, 0)
			Entity.velocity.x *= Entity.facing
			
func _on_SpritePlayer_anim_started(anim_name):
	match anim_name:
		"Turn", "[h]Turn":
			Entity.velocity.x = 0
			Entity.face(-Entity.facing)
		"Kill":
			Entity.velocity.set_vector(0, 0)

