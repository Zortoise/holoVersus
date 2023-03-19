extends Node2D

const START_SPEED = 500 * FMath.S
const ACCELERATION = 10 * FMath.S

const TRAITS = []

# cleaner code
onready var Entity = get_parent()
var Animator
var sprite


const MOVE_DATABASE = {
	"Active" : {
		Em.move.ROOT : "ScytheE",
		Em.move.ATK_TYPE : Em.atk_type.ENTITY,
		Em.move.HITCOUNT : 3,
		Em.move.DMG : 40,
		Em.move.KB : 300 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 4,
		Em.move.KB_ANGLE : -45,
		Em.move.HITSPARK_TYPE : Em.hitspark_type.SLASH,
		Em.move.HITSPARK_PALETTE : "dark_red",
		Em.move.PROJ_LVL : 1,
		Em.move.ATK_ATTR : [Em.atk_attr.DRAG_KB],
		Em.move.HIT_SOUND : { ref = "cut2", aux_data = {"vol" : -15} },
	},
}

func _ready():
	get_node("TestSprite").free() # test sprite is for sizing collision box

func init(_aux_data: Dictionary):
	Animator.play("Spawn")
	Entity.velocity.set_vector(-START_SPEED * Entity.facing, 0)
	Entity.absorption_value = 999
	Entity.life_point = 999
		
func refine_move_name(move_name):
		
#	match move_name:
#		"Spawn":
#			return "Active"
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
	
	Entity.velocity.x += Entity.facing * ACCELERATION
	Entity.velocity.x = clamp(Entity.velocity.x, -START_SPEED, START_SPEED)
	
	Entity.get_node("Sprite").rotation += 5*PI * Globals.FRAME * Entity.facing
	Globals.Game.spawn_afterimage(Entity.entity_ID, true, Entity.entity_ref, sprite.get_path(), null, null, \
		Color(0.8, 0.0, 0.3), 0.5, 10, Em.afterimage_shader.WHITE)
	
func kill(_sound = true):
	Entity.free = true
#	if Animator.to_play_animation != "Kill":
#		Animator.play("Kill")
#		if sound: Entity.play_audio("break2", {"vol" : -15})
	
#func expire():
#	if Animator.to_play_animation != "Expire":
#		Animator.play("Expire")
	
#func collision(): # collided with a platform
#	kill()

func landed_a_hit(_hit_data):
#	kill(false)
	pass
		
func on_offstage():
	if Entity.lifetime > 180:
		Entity.free = true
	
func _on_SpritePlayer_anim_finished(anim_name):
	match anim_name:
		"Spawn":
			Animator.play("Active")
			
func _on_SpritePlayer_anim_started(_anim_name):
	pass
#	match anim_name:
#		"Kill":
#			Entity.velocity.set_vector(0, 0)

