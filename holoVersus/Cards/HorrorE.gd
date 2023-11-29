extends Node2D


const TRAITS = []

# cleaner code
onready var Entity = get_parent()
var Animator
var sprite


const MOVE_DATABASE = {
	"Kill" : {
		Em.move.ATK_TYPE : Em.atk_type.ENTITY,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 99,
		Em.move.KB : 500 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 5,
		Em.move.FIXED_HITSTOP : 10,
		Em.move.HITSPARK_TYPE : Em.hitspark_type.HIT,
		Em.move.HITSPARK_PALETTE : "dark_purple",
		Em.move.KB_ANGLE : -90,
		Em.move.PROJ_LVL : 2,
		Em.move.ATK_ATTR : [Em.atk_attr.UNBLOCKABLE, Em.atk_attr.DESTROY_ENTITIES],
		Em.move.HIT_SOUND : { ref = "impact39", aux_data = {"vol" : -10} },
	}
}

func _ready():
	get_node("TestSprite").free() # test sprite is for sizing collision box

func init(_aux_data: Dictionary):
	
	Animator.play("Kill") # starting animation

func simulate():
	pass
	
	
func query_move_data(move_name) -> Dictionary:
	
	if !move_name in MOVE_DATABASE:
		print("Error: Cannot retrieve move_data for " + move_name + " in " + filename)
		return {}
	
	var move_data = MOVE_DATABASE[move_name].duplicate(true)
#	move_data[Em.move.ATK_ATTR] = query_atk_attr(move_name)
	
	if Globals.survival_level != null and Em.move.DMG in move_data:
		move_data[Em.move.DMG] = FMath.percent(move_data[Em.move.DMG], Inventory.modifier(Entity.master_ID, Cards.effect_ref.PROJ_DMG_MOD))
	
	return move_data
	
	
func query_atk_attr(move_name):
	
	if move_name in MOVE_DATABASE and Em.move.ATK_ATTR in MOVE_DATABASE[move_name]:
		return MOVE_DATABASE[move_name][Em.move.ATK_ATTR].duplicate(true)
	return []
	
	
func _on_SpritePlayer_anim_finished(anim_name):
	match anim_name:
		_:
			pass
			
func _on_SpritePlayer_anim_started(anim_name):
	match anim_name:
		_:
			pass

