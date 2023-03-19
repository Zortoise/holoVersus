extends Node2D

const START_SPEED = 500 * FMath.S

const GRAVITY = 18 * FMath.S
const TERMINAL_DOWN_VELOCITY = 300 * FMath.S
const AIR_RESISTANCE = 2

const TRAITS = []

# cleaner code
onready var Entity = get_parent()
var Animator
var sprite


const MOVE_DATABASE = {
	"BurnActive" : {
		Em.move.ROOT : "FlaskE",
		Em.move.ATK_TYPE : Em.atk_type.ENTITY,
		Em.move.HITCOUNT : 1,
		Em.move.PROJ_LVL : 1,
		Em.move.ATK_ATTR : [Em.atk_attr.DESTRUCTIBLE_ENTITY],
	},
	"BurnKill" : {
		Em.move.ROOT : "FlaskBlastE",
		Em.move.ATK_TYPE : Em.atk_type.ENTITY,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 100,
		Em.move.KB : 500 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.RADIAL,
		Em.move.ATK_LVL : 5,
		Em.move.FIXED_ATKER_HITSTOP : 0,
		Em.move.KB_ANGLE : 0,
		Em.move.HITSPARK_TYPE : Em.hitspark_type.HIT,
		Em.move.HITSPARK_PALETTE : "yellow",
		Em.move.PROJ_LVL : 2,
		Em.move.ATK_ATTR : [Em.atk_attr.INDESTRUCTIBLE_ENTITY],
		Em.move.HIT_SOUND : { ref = "impact35", aux_data = {"vol" : -6} },
	},
	"FreezeKill" : {
		Em.move.ROOT : "FlaskBlastE",
		Em.move.ATK_TYPE : Em.atk_type.ENTITY,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 100,
		Em.move.KB : 500 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.RADIAL,
		Em.move.ATK_LVL : 5,
		Em.move.FIXED_ATKER_HITSTOP : 0,
		Em.move.KB_ANGLE : 0,
		Em.move.HITSPARK_TYPE : Em.hitspark_type.HIT,
		Em.move.HITSPARK_PALETTE : "blue",
		Em.move.PROJ_LVL : 2,
		Em.move.ATK_ATTR : [Em.atk_attr.INDESTRUCTIBLE_ENTITY],
		Em.move.HIT_SOUND : { ref = "freeze1", aux_data = {"vol" : -6} },
	},
	"PoisonKill" : {
		Em.move.ROOT : "FlaskBlastE",
		Em.move.ATK_TYPE : Em.atk_type.ENTITY,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 100,
		Em.move.KB : 500 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.RADIAL,
		Em.move.ATK_LVL : 5,
		Em.move.FIXED_ATKER_HITSTOP : 0,
		Em.move.KB_ANGLE : 0,
		Em.move.HITSPARK_TYPE : Em.hitspark_type.HIT,
		Em.move.HITSPARK_PALETTE : "dark_purple",
		Em.move.PROJ_LVL : 2,
		Em.move.ATK_ATTR : [Em.atk_attr.INDESTRUCTIBLE_ENTITY],
		Em.move.HIT_SOUND : { ref = "impact25", aux_data = {"vol" : -12} },
	},
}

func _ready():
	get_node("TestSprite").free() # test sprite is for sizing collision box

func init(_aux_data: Dictionary):
	Animator.play("Spawn")
	Entity.velocity.set_vector(START_SPEED, 0)
	Entity.velocity.rotate(-80)
		
	Entity.velocity.x *= Entity.facing
	
	Entity.absorption_value = 1
	Entity.life_point = 1
		
func refine_move_name(move_name):
		
	match move_name:
		"FreezeActive", "PoisonActive":
			return "BurnActive"
		"Burn2Kill":
			return "BurnKill"
		"Freeze2Kill":
			return "FreezeKill"
		"Poison2Kill":
			return "PoisonKill"
	return move_name
	
		
func query_move_data(move_name) -> Dictionary:
	
	var orig_move_name = move_name
	move_name = refine_move_name(move_name)
	
	if !move_name in MOVE_DATABASE:
		print("Error: Cannot retrieve move_data for " + move_name)
		return {}
	
	var move_data = MOVE_DATABASE[move_name].duplicate(true)
	
	if Globals.survival_level != null and Em.move.DMG in move_data:
		move_data[Em.move.DMG] = FMath.percent(move_data[Em.move.DMG], Inventory.modifier(Entity.master_ID, Cards.effect_ref.PROJ_DMG_MOD))
		
	match orig_move_name:
		"Burn2Kill", "Freeze2Kill", "Poison2Kill":
			move_data[Em.move.KB_TYPE] = Em.knockback_type.MIRRORED
			move_data[Em.move.KB_ANGLE] = -70
	
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
	if !Animator.to_play_animation.ends_with("Kill"):
		Entity.get_node("Sprite").rotation += 5*PI * Globals.FRAME * Entity.facing
		Entity.velocity.y = int(min(Entity.velocity.y + GRAVITY, TERMINAL_DOWN_VELOCITY))
		Entity.velocity.x = FMath.f_lerp(Entity.velocity.x, 0, AIR_RESISTANCE)
		
func landed_a_hit0(hit_data): # don't check with to_play_animation since can hit multiple enemies at the same time
	if hit_data[Em.hit.MOVE_NAME] == "BurnActive":
		kill()
		hit_data[Em.hit.CANCELLED] = true
	else:
		match hit_data[Em.hit.MOVE_NAME]:
			"BurnKill":
				hit_data[Em.hit.DEFENDER].status_effect_to_add.append([Em.status_effect.IGNITE, Cards.IGNITE_DURATION, Cards.IGNITE_DMG])
			"FreezeKill":
				hit_data[Em.hit.DEFENDER].status_effect_to_add.append([Em.status_effect.CHILL, Cards.CHILL_DURATION, Cards.CHILL_SLOW])
				
	
func kill():
	match Animator.to_play_animation:
		"BurnActive":
			Animator.play("BurnKill")
		"FreezeActive":
			Animator.play("FreezeKill")
		"PoisonActive":
			Animator.play("PoisonKill")
#	if sound: Entity.play_audio("impact25", {"vol" : -12})
	
func collision(): # collided with a platform
	match Animator.to_play_animation:
		"BurnActive":
			if Entity.is_on_solid_ground(Entity.get_node("EntityCollisionBox")):
				Animator.play("Burn2Kill")
			else:
				Animator.play("BurnKill")
		"FreezeActive":
			if Entity.is_on_solid_ground(Entity.get_node("EntityCollisionBox")):
				Animator.play("Freeze2Kill")
			else:
				Animator.play("FreezeKill")
		"PoisonActive":
			if Entity.is_on_solid_ground(Entity.get_node("EntityCollisionBox")):
				Animator.play("Poison2Kill")
			else:
				Animator.play("PoisonKill")
		

#func landed_a_hit(_hit_data):
#	kill(false)
		
func on_offstage():
	Entity.free = true
	
func _on_SpritePlayer_anim_finished(anim_name):
	match anim_name:
		"Spawn":
			match Globals.Game.rng_generate(2):
				0:
					Animator.play("BurnActive")
				1:
					Animator.play("FreezeActive")
#				2:
#					Animator.play("PoisonActive")
			
func _on_SpritePlayer_anim_started(anim_name):
	
	if Animator.to_play_animation.ends_with("Kill"):
		Entity.velocity.set_vector(0, 0)
		Entity.get_node("Sprite").rotation = 0
		Entity.absorption_value = null
	
	match anim_name:
		"BurnKill", "Burn2Kill":
			Entity.play_audio("explosion1", {"vol" : -15})
		"FreezeKill", "Freeze2Kill":
			Entity.play_audio("explosion3", {"vol" : -12})
