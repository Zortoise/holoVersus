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
		Em.move.DMG : 50,
		Em.move.KB : 450 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 4,
		Em.move.FIXED_HITSTOP : 10,
		Em.move.FIXED_ATKER_HITSTOP: 0,
		Em.move.HITSPARK_TYPE : Em.hitspark_type.SLASH,
		Em.move.HITSPARK_PALETTE : "pink",
		Em.move.KB_ANGLE : -45,
		Em.move.PROJ_LVL : 1,
		Em.move.ATK_ATTR : [],
		Em.move.HIT_SOUND : { ref = "cut2", aux_data = {"vol" : -13} },
	}
}

func _ready():
	get_node("TestSprite").free() # test sprite is for sizing collision box

func init(aux_data: Dictionary):
	
	Animator.play("Kill") # starting animation
#	Entity.play_audio("cut6", {"vol" : -5})

	if "count" in aux_data:
		Entity.unique_data["count"] = aux_data.count - 1


func simulate():
	
	if Animator.time == 8 and "count" in Entity.unique_data and Entity.unique_data.count > 0:
		Globals.Game.spawn_entity(Entity.master_ID, "FuwaSlashE", Entity.position, {"facing" : -Entity.facing, "count" : Entity.unique_data.count})
	
	
func query_move_data(move_name) -> Dictionary:
	
	if !move_name in MOVE_DATABASE:
		print("Error: Cannot retrieve move_data for " + move_name)
		return {}
	
	var move_data = MOVE_DATABASE[move_name].duplicate(true)
#	move_data[Em.move.ATK_ATTR] = query_atk_attr(move_name)
	
	if "count" in Entity.unique_data:
		move_data[Em.move.KB_ANGLE] = -90
	
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

