extends Node2D


const TRAITS = [Em.entity_trait.GROUNDED]

# cleaner code
onready var Entity = get_parent()
var Animator
var sprite


const MOVE_DATABASE = {
	"Kill" : {
		Em.move.ROOT : "SharkBreach", # for entities, keep move_name in move_data, for checking repeat
		Em.move.ATK_TYPE : Em.atk_type.ENTITY,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 90,
		Em.move.KB : 475 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 5,
		Em.move.FIXED_HITSTOP : 10,
		Em.move.KB_ANGLE : -60,
		Em.move.ATK_ATTR : [Em.atk_attr.REPEATABLE, Em.atk_attr.DESTROY_ENTITIES],
		Em.move.HIT_SOUND : { ref = "water1", aux_data = {"vol" : -6} },
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

	if Globals.survival_level != null and Em.move.DMG in move_data:
#		move_data[Em.move.DMG] = FMath.percent(move_data[Em.move.DMG], 60)	
		move_data[Em.move.DMG] = FMath.percent(move_data[Em.move.DMG], Inventory.modifier(Entity.master_ID, Cards.effect_ref.PROJ_DMG_MOD))

	return move_data
	
	
func query_atk_attr(move_name):
	
	if move_name in MOVE_DATABASE and Em.move.ATK_ATTR in MOVE_DATABASE[move_name]:
		return MOVE_DATABASE[move_name][Em.move.ATK_ATTR].duplicate(true)
		
#	print("Error: Cannot retrieve atk_attr for " + move_name)
	return []
	
	
func get_proj_level(move_name):

	if move_name in MOVE_DATABASE and Em.move.PROJ_LVL in MOVE_DATABASE[move_name]:
		return MOVE_DATABASE[move_name][Em.move.PROJ_LVL]
	
	return 1
	
	
func _on_SpritePlayer_anim_finished(anim_name):
	match anim_name:
		_:
			pass
			
func _on_SpritePlayer_anim_started(anim_name):
	match anim_name:
		_:
			pass

