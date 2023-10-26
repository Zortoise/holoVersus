extends Node2D


const TRAITS = []

# cleaner code
onready var Entity = get_parent()
var Animator
var sprite


const MOVE_DATABASE = {
	"Kill" : {
		Em.move.ROOT: "TakoExplode",
		Em.move.ATK_TYPE : Em.atk_type.ENTITY,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 90,
		Em.move.KB : 600 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 5,
		Em.move.FIXED_HITSTOP : 10,
		Em.move.FIXED_ATKER_HITSTOP : 0,
		Em.move.KB_ANGLE : -90,
		Em.move.HITSPARK_TYPE : Em.hitspark_type.HIT,
#		Em.move.HITSPARK_PALETTE : "dark_purple",
		Em.move.PROJ_LVL : 3,
		Em.move.ATK_ATTR : [Em.atk_attr.DESTROY_ENTITIES],
		Em.move.HIT_SOUND : { ref = "impact39", aux_data = {"vol" : -5} },
	},
}

func init(_aux_data: Dictionary):
	Animator.play("Kill") # starting animation
#	if "less_dmg" in aux_data: # for command grab
#		Entity.unique_data["less_dmg"] = true
		

func simulate():
	if posmod(Entity.lifetime, 3) == 0:
		Globals.Game.spawn_afterimage(Entity.entity_ID, Em.afterimage_type.ENTITY, Entity.entity_ref, sprite.get_path(), \
				Entity.palette_ref, Entity.master_ref, Color(0, 0, 0), 0.5, 10.0)
	
	
func query_move_data(move_name) -> Dictionary:
	
	if !move_name in MOVE_DATABASE:
		print("Error: Cannot retrieve move_data for " + move_name)
		return {}
	
	var move_data = MOVE_DATABASE[move_name].duplicate(true)
#	if "less_dmg" in Entity.unique_data: # for command grab
#		move_data[Em.move.DMG] = 50
#		move_data[Em.move.ROOT] = "TakoExplode2" 
#		move_data[Em.move.KB_ANGLE] = -75
			
	if Globals.survival_level != null and Em.move.DMG in move_data:
#		move_data[Em.move.DMG] = FMath.percent(move_data[Em.move.DMG], 60)	
		move_data[Em.move.DMG] = FMath.percent(move_data[Em.move.DMG], Inventory.modifier(Entity.master_ID, Cards.effect_ref.PROJ_DMG_MOD))

	return move_data
	
	
func query_atk_attr(move_name):
	
	if move_name in MOVE_DATABASE and Em.move.ATK_ATTR in MOVE_DATABASE[move_name]:
		return MOVE_DATABASE[move_name][Em.move.ATK_ATTR].duplicate(true)
		
#	print("Error: Cannot retrieve atk_attr for " + move_name)
	return []
	
	
func landed_a_hit(hit_data):
	if hit_data[Em.hit.BLOCK_STATE] == Em.block_state.UNBLOCKED and !hit_data[Em.hit.REPEAT]:
		hit_data[Em.hit.CRUSH] = true
		
	
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

