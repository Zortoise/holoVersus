extends Node2D

const LIFESPAN = 180

const TRAITS = []

# cleaner code
onready var Entity = get_parent()
var Animator
var sprite


const MOVE_DATABASE = {
	"Active" : {
		Em.move.ROOT : "PeacockFeatherE",
		Em.move.ATK_TYPE : Em.atk_type.ENTITY,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 25,
		Em.move.KB : 300 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 2,
		Em.move.KB_ANGLE : -90,
		Em.move.HITSPARK_TYPE : Em.hitspark_type.HIT,
		Em.move.HITSPARK_PALETTE : "cyan",
		Em.move.PROJ_LVL : 1,
		Em.move.ATK_ATTR : [],
		Em.move.HIT_SOUND : { ref = "impact25", aux_data = {"vol" : -12} },
	},
}

func _ready():
	get_node("TestSprite").free() # test sprite is for sizing collision box

func init(aux_data: Dictionary):
	Animator.play("Spawn")
	Entity.absorption_value = 1
	Entity.life_point = 1
	Entity.lifespan = LIFESPAN
#	Entity.get_node("Sprite").rotation = deg2rad(90) * Entity.facing
	if "alt" in aux_data:
		Entity.unique_data["alt"] = true
		
func refine_move_name(move_name):
		
	match move_name:
		"Spawn":
			return "Active"
	return move_name
	
		
func query_move_data(move_name) -> Dictionary:
	
	move_name = refine_move_name(move_name)
	
	if !move_name in MOVE_DATABASE:
		print("Error: Cannot retrieve move_data for " + move_name + " in " + filename)
		return {}
	
	var move_data = MOVE_DATABASE[move_name].duplicate(true)
#	move_data[Em.move.ATK_ATTR] = query_atk_attr(move_name)
	
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
	if Animator.to_play_anim != "Kill":
		if "alt" in Entity.unique_data:
			Entity.velocity.y = -FMath.harmonic_motion_vel(5, 5, Entity.lifetime)
		else:
			Entity.velocity.y = FMath.harmonic_motion_vel(5, 5, Entity.lifetime)
	
	
func kill(sound = true):
	if Animator.to_play_anim != "Kill":
		Animator.play("Kill")
		if sound: Entity.play_audio("impact25", {"vol" : -12})
	
func expire():
	if Animator.to_play_anim != "Expire":
		Animator.play("Expire")
	
func collision(_landed := false, _orig_vel_x := 0, _orig_vel_y := 0): # collided with a platform
	kill()

func landed_a_hit(_hit_data):
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

