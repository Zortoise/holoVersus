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
		"root" : "ScytheE",
		"atk_type" : Globals.atk_type.ENTITY,
		"hitcount" : 3,
		"damage" : 40,
		"knockback" : 300 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED,
		"atk_level" : 2,
		"KB_angle" : -45,
		"hitspark_type" : Globals.hitspark_type.SLASH,
		"hitspark_palette" : "dark_red",
		"proj_level" : 1,
		"atk_attr" : [Globals.atk_attr.DRAG_KB],
		"hit_sound" : { ref = "cut2", aux_data = {"vol" : -15} },
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
	
	if Globals.survival_level != null and "damage" in move_data:
		move_data.damage = FMath.percent(move_data.damage, Inventory.modifier(Entity.master_ID, Cards.effect_ref.PROJ_DMG_MOD))
	
	return move_data
		
		
func query_atk_attr(move_name):
	
	move_name = refine_move_name(move_name)

	if move_name in MOVE_DATABASE and "atk_attr" in MOVE_DATABASE[move_name]:
		return MOVE_DATABASE[move_name].atk_attr.duplicate(true)
		
#	print("Error: Cannot retrieve atk_attr for " + move_name)
	return []

			
func simulate():
	
	Entity.velocity.x += Entity.facing * ACCELERATION
	Entity.velocity.x = clamp(Entity.velocity.x, -START_SPEED, START_SPEED)
	
	Entity.get_node("Sprite").rotation += 5*PI * Globals.FRAME * Entity.facing
	Globals.Game.spawn_afterimage(Entity.entity_ID, true, Entity.master_ref, Entity.entity_ref, sprite.get_path(), Entity.palette_ref, \
		Color(0.8, 0.0, 0.3), 0.5, 10, Globals.afterimage_shader.WHITE)
	
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

