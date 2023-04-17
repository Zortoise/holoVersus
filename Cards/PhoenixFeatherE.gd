extends Node2D

const START_SPEED = 250 * FMath.S
const LIFESPAN = 60

const TRAITS = []

# cleaner code
onready var Entity = get_parent()
var Animator
var sprite


const MOVE_DATABASE = {
	"Active" : {
		Em.move.ROOT : "PhoenixFeatherE",
		Em.move.ATK_TYPE : Em.atk_type.ENTITY,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 30,
		Em.move.KB : 300 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 2,
		Em.move.KB_ANGLE : -45,
		Em.move.HITSPARK_TYPE : Em.hitspark_type.HIT,
		Em.move.HITSPARK_PALETTE : "yellow",
		Em.move.PROJ_LVL : 1,
		Em.move.ATK_ATTR : [],
		Em.move.HIT_SOUND : { ref = "impact25", aux_data = {"vol" : -12} },
	},
}

func _ready():
	get_node("TestSprite").free() # test sprite is for sizing collision box

func init(aux_data: Dictionary):
	Animator.play("Spawn")
	Entity.velocity.set_vector(START_SPEED, 0)
	if "ground2" in aux_data:
		Entity.velocity.rotate(-30)
		Entity.rotate_sprite_x_axis(-30)
	if "ground3" in aux_data:
		Entity.velocity.rotate(-60)
		Entity.rotate_sprite_x_axis(-60)
	elif "air2" in aux_data:
		Entity.velocity.rotate(30)
		Entity.rotate_sprite_x_axis(30)
	elif "air3" in aux_data:
		Entity.velocity.rotate(-30)
		Entity.rotate_sprite_x_axis(-30)
		
	Entity.velocity.x *= Entity.facing
	
	Entity.absorption_value = 1
	Entity.life_point = 1
	Entity.lifespan = LIFESPAN
		
func refine_move_name(move_name):
		
	match move_name:
		"Spawn":
			return "Active"
	return move_name
	
		
func query_move_data(move_name) -> Dictionary:
	
	move_name = refine_move_name(move_name)
	
	if !move_name in MOVE_DATABASE:
		print("Error: Cannot retrieve move_data for " + move_name)
		return {}
	
	var move_data = MOVE_DATABASE[move_name].duplicate(true)
	
	if Globals.survival_level != null and Em.move.DMG in move_data:
		move_data[Em.move.DMG] = FMath.percent(move_data[Em.move.DMG], Inventory.modifier(Entity.master_ID, Cards.effect_ref.PROJ_DMG_MOD))
	
	return move_data
		
		
func query_atk_attr(move_name):
	
	move_name = refine_move_name(move_name)

	if move_name in MOVE_DATABASE and Em.move.ATK_ATTR in MOVE_DATABASE[move_name]:
		return MOVE_DATABASE[move_name][Em.move.ATK_ATTR].duplicate(true)
		
#	print("Error: Cannot retrieve atk_attr for " + move_name)
	return []
	
	
func get_proj_level(move_name):
	move_name = refine_move_name(move_name)

	if move_name in MOVE_DATABASE and Em.move.PROJ_LVL in MOVE_DATABASE[move_name]:
		return MOVE_DATABASE[move_name][Em.move.PROJ_LVL]
	
	return 1
			
			
func simulate():
	pass
	
func kill(sound = true):
	if Animator.to_play_anim != "Kill":
		Animator.play("Kill")
		if sound: Entity.play_audio("impact25", {"vol" : -12})
	
func expire():
	if Animator.to_play_anim != "Expire":
		Animator.play("Expire")
	
func collision(): # collided with a platform
	kill()

func landed_a_hit(hit_data):
	hit_data[Em.hit.DEFENDER].status_effect_to_add.append([Em.status_effect.IGNITE, Cards.IGNITE_DURATION, Cards.IGNITE_DMG])
	kill(false)
		
func on_offstage():
	Entity.free = true
	
func _on_SpritePlayer_anim_finished(anim_name):
	match anim_name:
		"Spawn":
			Animator.play("Active")
			
func _on_SpritePlayer_anim_started(anim_name):
	match anim_name:
		"Kill":
			Entity.velocity.set_vector(0, 0)

