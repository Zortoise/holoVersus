extends Node2D


const TRAITS = [Globals.entity_trait.GROUNDED]

# cleaner code
onready var Entity = get_parent()
var Animator
var sprite


const MOVE_DATABASE = {
	"Kill" : {
		"root" : "SharkBreach", # for entities, keep move_name in move_data, for checking repeat
		"atk_type" : Globals.atk_type.ENTITY,
		"hitcount" : 1,
		"damage" : 90,
		"knockback" : 475 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED,
		"atk_level" : 5,
		"fixed_hitstop" : 10,
		"KB_angle" : -60,
		"atk_attr" : [Globals.atk_attr.REPEATABLE],
		"hit_sound" : { ref = "water1", aux_data = {"vol" : -6} },
	}
}

func init(_aux_data: Dictionary):
	Animator.play("Kill") # starting animation

func simulate():
	pass
	
	
func query_move_data(move_name) -> Dictionary:
	
	if !move_name in MOVE_DATABASE:
		print("Error: Cannot retrieve move_data for " + move_name)
		return {}
	
	var move_data = MOVE_DATABASE[move_name].duplicate(true)

	if Globals.survival_level != null and "damage" in move_data:
#		move_data.damage = FMath.percent(move_data.damage, 60)	
		move_data.damage = FMath.percent(move_data.damage, Inventory.modifier(Entity.master_ID, Cards.effect_ref.PROJ_DMG_MOD))

	return move_data
	
	
func query_atk_attr(move_name):
	
	if move_name in MOVE_DATABASE and "atk_attr" in MOVE_DATABASE[move_name]:
		return MOVE_DATABASE[move_name].atk_attr.duplicate(true)
		
#	print("Error: Cannot retrieve atk_attr for " + move_name)
	return []
	
	
func _on_SpritePlayer_anim_finished(anim_name):
	match anim_name:
		_:
			pass
			
func _on_SpritePlayer_anim_started(anim_name):
	match anim_name:
		_:
			pass

