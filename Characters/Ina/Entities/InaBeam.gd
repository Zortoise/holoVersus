extends Node2D


const TRAITS = [Em.entity_trait.BEAM]

# cleaner code
onready var Entity = get_parent()
var Animator
var sprite


const MOVE_DATABASE = {
	"Kill" : {
		Em.move.ROOT: "InaBeam",
		Em.move.ATK_TYPE : Em.atk_type.ENTITY,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 80,
		Em.move.KB : 450 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 3,
		Em.move.FIXED_ATKER_HITSTOP : 0,
		Em.move.KB_ANGLE : -30,
		Em.move.HITSPARK_TYPE : Em.hitspark_type.HIT,
#		Em.move.HITSPARK_PALETTE : "dark_purple",
		Em.move.PROJ_LVL : 1,
		Em.move.ATK_ATTR : [Em.atk_attr.DESTROY_ENTITIES],
		Em.move.HIT_SOUND : { ref = "impact43", aux_data = {"vol" : -12} },
	},
	"[h]Kill" : {
		Em.move.ROOT: "InaBeam",
		Em.move.ATK_TYPE : Em.atk_type.ENTITY,
		Em.move.HITCOUNT : 3,
		Em.move.DMG : 35,
		Em.move.KB : 500 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 3,
		Em.move.IGNORE_TIME : 5,
		Em.move.FIXED_HITSTOP : 6,
		Em.move.FIXED_ATKER_HITSTOP : 0,
		Em.move.KB_ANGLE : -30,
		Em.move.HITSPARK_TYPE : Em.hitspark_type.HIT,
#		Em.move.HITSPARK_PALETTE : "dark_purple",
		Em.move.PROJ_LVL : 1,
		Em.move.ATK_ATTR : [Em.atk_attr.DESTROY_ENTITIES],
		Em.move.HIT_SOUND : { ref = "impact43", aux_data = {"vol" : -15} },
	},
	"[ex]Kill" : {
		Em.move.ROOT: "InaBeamEX",
		Em.move.ATK_TYPE : Em.atk_type.EX_ENTITY,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 30,
		Em.move.KB : 700 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 3,
		Em.move.FIXED_HITSTOP : 7,
		Em.move.FIXED_ATKER_HITSTOP : 0,
		Em.move.KB_ANGLE : 0,
		Em.move.HITSPARK_TYPE : Em.hitspark_type.HIT,
#		Em.move.HITSPARK_PALETTE : "dark_purple",
		Em.move.PROJ_LVL : 3,
		Em.move.ATK_ATTR : [Em.atk_attr.REPEATABLE, Em.atk_attr.DESTROY_ENTITIES],
		Em.move.HIT_SOUND : { ref = "impact43", aux_data = {"vol" : -15} },
	},
}

func init(aux_data: Dictionary):
	if "sec" in aux_data:
		match aux_data.type:
			"base":
				Animator.play("SecKill")
			"held":
				Animator.play("[h]SecKill")
			"ex":
				Animator.play("[ex]SecKill")
	else:
		match aux_data.type:
			"base":
				Animator.play("Kill")
			"held":
				Animator.play("[h]Kill")
			"ex":
				Animator.play("[ex]Kill")
		
	Entity.unique_data["sticky_offset"] = Entity.position - Globals.Game.get_player_node(Entity.master_ID).position
	
	# spawn next section
	var spawn_dist = Entity.position.x + (Entity.facing * int(sprite.get_rect().size.x / 2))
	if spawn_dist <= Globals.Game.stage_box.rect_global_position.x + Globals.Game.stage_box.rect_size.x + (2 * Globals.CORNER_SIZE) and \
			spawn_dist >= Globals.Game.stage_box.rect_global_position.x - (2 * Globals.CORNER_SIZE):
		var sec_aux_data = {"sec":true, "facing": Entity.facing, "back":true, "type": aux_data.type}
		Globals.Game.spawn_entity(Entity.master_ID, "InaBeam", Vector2(spawn_dist, Entity.position.y), sec_aux_data, Entity.palette_ref, Entity.master_ref)


func simulate():
	var master_node = Globals.Game.get_player_node(Entity.master_ID)
	if !master_node.query_state([Em.char_state.AIR_ATK_ACTIVE, Em.char_state.AIR_ATK_REC]):
		Entity.free = true
		Globals.Game.spawn_afterimage(Entity.entity_ID, Em.afterimage_type.ENTITY, Entity.entity_ref, sprite.get_path(), \
				Entity.palette_ref, Entity.master_ref)
				
	match Animator.to_play_anim:
		"Kill", "SecKill":
			if !master_node.Animator.query_to_play(["aSP5Active", "aSP5Rec"]):
				Entity.free = true
				Globals.Game.spawn_afterimage(Entity.entity_ID, Em.afterimage_type.ENTITY, Entity.entity_ref, sprite.get_path(), \
						Entity.palette_ref, Entity.master_ref)
			elif Animator.time < 9:
				Entity.position = master_node.position + Entity.unique_data.sticky_offset
		"[ex]Kill", "[ex]SecKill":
			if !master_node.Animator.query_to_play(["aSP5[ex]Active", "aSP5[ex]Rec"]):
				Entity.free = true
				Globals.Game.spawn_afterimage(Entity.entity_ID, Em.afterimage_type.ENTITY, Entity.entity_ref, sprite.get_path(), \
						Entity.palette_ref, Entity.master_ref)
			elif Animator.time < 9:
				Entity.position = master_node.position + Entity.unique_data.sticky_offset
		"[h]Kill", "[h]SecKill":
			if !master_node.Animator.query_to_play(["aSP5[h]Active", "aSP5Rec"]):
				Entity.free = true
				Globals.Game.spawn_afterimage(Entity.entity_ID, Em.afterimage_type.ENTITY, Entity.entity_ref, sprite.get_path(), \
						Entity.palette_ref, Entity.master_ref)
			elif Animator.time < 27:
				Entity.position = master_node.position + Entity.unique_data.sticky_offset
						

	
	
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

