extends Node2D

const TRAITS = []

# cleaner code
onready var Entity = get_parent()
var Animator
var sprite


const MOVE_DATABASE = {
	"Active1" : {
		Em.move.ROOT : "TakoE",
		Em.move.ATK_TYPE : Em.atk_type.ENTITY,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 50,
		Em.move.KB : 400 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 3,
		Em.move.KB_ANGLE : -90,
		Em.move.HITSPARK_TYPE : Em.hitspark_type.HIT,
		Em.move.HITSPARK_PALETTE : "dark_purple",
		Em.move.PROJ_LVL : 1,
		Em.move.ATK_ATTR : [],
		Em.move.HIT_SOUND : { ref = "impact39", aux_data = {"vol" : -15} },
	},
}

func _ready():
	get_node("TestSprite").free() # test sprite is for sizing collision box

func init(aux_data: Dictionary):
	if "alt3" in aux_data:
		Animator.play("Active3")
		Entity.velocity.set_vector(300 * FMath.S * Entity.facing, 0)
		Entity.lifespan = 60
	elif "alt2" in aux_data:
		Animator.play("Active2")
		Entity.velocity.set_vector(200 * FMath.S * Entity.facing, 180 * FMath.S)
		Entity.unique_data["alt2"] = true
		Entity.lifespan = 90
	elif "alt4" in aux_data:
		Animator.play("Active1")
		Entity.velocity.set_vector(0, -100 * FMath.S)
		Entity.lifespan = 120
	elif "alt1" in aux_data:
		Animator.play("Active1")
		Entity.velocity.set_vector(0, 100 * FMath.S)
		Entity.unique_data["alt1"] = true
		Entity.lifespan = 120
	
	Entity.absorption_value = 1
	Entity.life_point = 1
	
		
func refine_move_name(move_name):
		
	match move_name:
		"Active2", "Active3":
			return "Active1"
			
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
	if Animator.to_play_animation != "Kill":
		if "alt2" in Entity.unique_data:
			Entity.velocity.y -= 6 * FMath.S
		elif "alt1" in Entity.unique_data:
			Entity.velocity.x = FMath.harmonic_motion_vel(64, 5, Entity.lifetime) * Entity.facing
		
	
func kill(sound = true):
	if Animator.to_play_animation != "Kill":
		Animator.play("Kill")
		if sound: Entity.play_audio("impact25", {"vol" : -12})
	
func expire():
	Entity.free = true
	Globals.Game.spawn_SFX("TakoGateEffect", "TakoGateEffect", Entity.position, {"facing":Entity.facing})
	
#func collision(): # collided with a platform
#	Entity.free = true
#	Globals.Game.spawn_SFX("TakoGateEffect", "TakoGateEffect", Entity.position, {"facing":Entity.facing})

func landed_a_hit(_hit_data):
	kill(false)
		
func on_offstage():
	if Entity.lifetime > 30:
		Entity.free = true
	
func _on_SpritePlayer_anim_finished(anim_name):
	match anim_name:
		_:
			pass
			
func _on_SpritePlayer_anim_started(anim_name):
	match anim_name:
		"Kill":
			Entity.velocity.set_vector(0, 0)

