extends Node2D

#const START_SPEED = 500
const PALETTE = null # setting this to null make it use its master's palette, not having PALETTE make it use default colors

const TRAITS = [Globals.entity_trait.GROUNDED, Globals.entity_trait.LEDGE_STOP]
# example: Globals.entity_trait.GROUNDED

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
		Entity.lifespan = 300
	else:
		Entity.lifespan = 180	
			
func stimulate():
	
	match Animator.current_animation: # triggering shark breach
		"Active", "[h]Active", "Turn", "bTurn":
			if get_node(Entity.master_path).unique_data.groundfin_trigger:
#				var breach_facing = get_node(Entity.master_path).get_last_tapped_dir()
#				var turned := false
#				if breach_facing == 0:
#					breach_facing = get_node(Entity.master_path).dir
#				else:
#					turned = true # aleady turned via get_last_tapped_dir()
#				if breach_facing == 0:
#					breach_facing = Entity.facing
				var breach_facing = sign(Globals.Game.get_player_node(get_node(Entity.master_path).targeted_opponent).position.x - Entity.position.x)
				if breach_facing == 0:
					breach_facing = Entity.facing
				Globals.Game.spawn_entity(Entity.master_path, "SharkBreach", Entity.position, {"facing" : breach_facing})
				# reduce ground fin count
				get_node(Entity.master_path).unique_data.groundfin_count = max(0, get_node(Entity.master_path).unique_data.groundfin_count - 1)
				Entity.free = true

	
func kill(_sound = true):
	if !Animator.current_animation.ends_with("Kill"):
		Animator.play("Kill")
		# reduce ground fin count
		get_node(Entity.master_path).unique_data.groundfin_count = max(0, get_node(Entity.master_path).unique_data.groundfin_count - 1)
	
	
func collision(): # collided with a wall, turns
	ledge_stop()
	
func ledge_stop(): # about to go off the ledge, turns
	match Animator.current_animation:
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
			Entity.velocity = Vector2(250, 0)
			Entity.velocity.x *= Entity.facing
		"[h]Turn":
			Animator.play("[h]Active")
			Entity.velocity = Vector2(150, 0)
			Entity.velocity.x *= Entity.facing
			
func _on_SpritePlayer_anim_started(anim_name):
	match anim_name:
		"Spawn":
			Entity.velocity = Vector2(250, 0)
			Entity.velocity.x *= Entity.facing
		"[h]Spawn":
			Entity.velocity = Vector2(150, 0)
			Entity.velocity.x *= Entity.facing
		"Turn", "[h]Turn":
			Entity.velocity.x = 0
			Entity.face(-Entity.facing)
		"Kill":
			Entity.velocity = Vector2.ZERO

