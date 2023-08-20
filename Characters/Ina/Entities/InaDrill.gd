extends Node2D

const ID = "drill" # for master to find it
const TRAITS = []

# cleaner code
onready var Entity = get_parent()
var Animator
var sprite


const MOVE_DATABASE = {
	"Active" : {
		Em.move.ROOT: "InaDrill",
		Em.move.ATK_TYPE : Em.atk_type.ENTITY,
		Em.move.HITCOUNT : 5,
		Em.move.DMG : 25,
		Em.move.KB : 450 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 3,
		Em.move.IGNORE_TIME : 5,
		Em.move.FIXED_HITSTOP : 6,
		Em.move.FIXED_ATKER_HITSTOP : 0,
		Em.move.KB_ANGLE : 0,
		Em.move.HITSPARK_TYPE : Em.hitspark_type.HIT,
		Em.move.HITSPARK_PALETTE : "dark_purple",
		Em.move.PROJ_LVL : 2,
		Em.move.ATK_ATTR : [Em.atk_attr.CHIPPER, Em.atk_attr.INDESTRUCTIBLE_ENTITY, Em.atk_attr.NO_REFLECT_ENTITY, Em.atk_attr.DESTROY_ENTITIES],
		Em.move.HIT_SOUND : [{ ref = "impact40", aux_data = {"vol" : -20} }, { ref = "impact34", aux_data = {"vol" : -20} }],
	},
}

func init(aux_data: Dictionary):
	
	Entity.unique_data = {"timer" : 60, "ex": false, "new_facing" : null, "new_v_facing" : null,}
	
	Animator.play("CircleSpawn") # starting animation
	if aux_data.ex:
		Entity.unique_data["ex"] = true
		Entity.unique_data.timer = 30
		Entity.life_point = 8
	else:
		Entity.life_point = 5
		

func simulate():
#	if posmod(Entity.lifetime, 3) == 0:
#		Globals.Game.spawn_afterimage(Entity.entity_ID, Em.afterimage_type.ENTITY, Entity.entity_ref, sprite.get_path(), \
#				Entity.palette_ref, Entity.master_ref, Color(0, 0, 0), 0.5, 10.0)


	if !Animator.current_anim.ends_with("Kill"):
		
		if Entity.unique_data.new_facing != null: # turn here
			Entity.face(Entity.unique_data.new_facing)
			Entity.unique_data.new_facing = null
		if Entity.unique_data.new_v_facing != null:
			Entity.v_face(Entity.unique_data.new_v_facing)
			Entity.unique_data.new_v_facing = null
		
		if Entity.unique_data.timer > 0:
			Entity.unique_data.timer -= 1
		
		match Animator.current_anim:
			"CircleSpawn", "CircleActive":
				if Globals.Game.get_player_node(Entity.master_ID).is_hitstunned_or_sequenced(): # vanish if master is hit
					Entity.free = true
					Globals.Game.spawn_afterimage(Entity.entity_ID, Em.afterimage_type.ENTITY, Entity.entity_ref, sprite.get_path(), \
							Entity.palette_ref, Entity.master_ref)
				elif Entity.unique_data.timer == 0:
					trigger()
			_: # drill trigger
				if Entity.unique_data.timer == 0:
					kill()


func landed_a_hit(_hit_data):
	Entity.life_point -= 1
	if Entity.life_point <= 0:
		kill()

	
func kill():
	match Animator.current_anim:
		"CircleSpawn", "CircleActive":
			Entity.free = true
			Globals.Game.spawn_afterimage(Entity.entity_ID, Em.afterimage_type.ENTITY, Entity.entity_ref, sprite.get_path(), \
					Entity.palette_ref, Entity.master_ref)
			
		"ESpawn", "EActive":
			Animator.play("EKill")
		"SSpawn", "SActive":
			Animator.play("SKill")
		"SESpawn", "SEActive":
			Animator.play("SEKill")
		"ESESpawn", "ESEActive":
			Animator.play("ESEKill")
		"SSESpawn", "SSEActive":
			Animator.play("SSEKill")
			
			
func trigger():
	
	var master_node = Globals.Game.get_player_node(Entity.master_ID)
	var enemy_node = master_node.get_target()
	if enemy_node == null:
		enemy_node = master_node
	
	var angle_finder := FVector.new()
	angle_finder.set_from_vec(enemy_node.position - Entity.position)
	var angle = angle_finder.angle()
	var segment = Globals.split_angle(angle, Em.angle_split.SIXTEEN)
	
	var new_facing := 1
	var new_v_facing := 1
	
	match segment:
		Em.compass.E:
			Animator.play("ESpawn")
		Em.compass.ESE:
			Animator.play("ESESpawn")
		Em.compass.SE:
			Animator.play("SESpawn")
		Em.compass.SSE:
			Animator.play("SSESpawn")
			
		Em.compass.S:
			Animator.play("SSpawn")
		Em.compass.SSW:
			Animator.play("SSESpawn")
			new_facing = -1
		Em.compass.SW:
			Animator.play("SESpawn")
			new_facing = -1
		Em.compass.WSW:
			Animator.play("ESESpawn")
			new_facing = -1
			
		Em.compass.W:
			Animator.play("ESpawn")
			new_facing = -1
		Em.compass.WNW:
			Animator.play("ESESpawn")
			new_facing = -1
			new_v_facing = -1
		Em.compass.NW:
			Animator.play("SESpawn")
			new_facing = -1
			new_v_facing = -1
		Em.compass.NNW:
			Animator.play("SSESpawn")
			new_facing = -1
			new_v_facing = -1
			
		Em.compass.N:
			Animator.play("SSpawn")
			new_v_facing = -1
		Em.compass.NNE:
			Animator.play("SSESpawn")
			new_v_facing = -1
		Em.compass.NE:
			Animator.play("SESpawn")
			new_v_facing = -1
		Em.compass.ENE:
			Animator.play("ESESpawn")
			new_v_facing = -1
			
	Entity.unique_data.new_facing = new_facing
	Entity.unique_data.new_v_facing = new_v_facing
	if Entity.unique_data.ex:
		Entity.unique_data.timer = 90
	else:
		Entity.unique_data.timer = 60
		
	
func refine_move_name(move_name):
		
	match move_name:
		"ESpawn", "EActive", "SSpawn", "SActive", "SESpawn", "SEActive", "ESESpawn", "ESEActive", "SSESpawn", "SSEActive":
			return "Active"
	return move_name
	
	
func query_move_data(move_name) -> Dictionary:
	
	var orig_move_name = move_name
	move_name = refine_move_name(move_name)
	
	if !move_name in MOVE_DATABASE:
		print("Error: Cannot retrieve move_data for " + move_name)
		return {}
	
	var move_data = MOVE_DATABASE[move_name].duplicate(true)
	
	if Entity.unique_data.ex:
		move_data[Em.move.HITCOUNT] = 8
		move_data[Em.move.PROJ_LVL] = 3

	match orig_move_name:
		"ESpawn", "EActive":
			move_data[Em.move.KB_ANGLE] = -31
		"SSpawn", "SActive":
			if Entity.v_facing == 1:
				move_data[Em.move.KB_ANGLE] = 90
			else:
				move_data[Em.move.KB_ANGLE] = -90
		"SESpawn", "SEActive":
			if Entity.v_facing == 1:
				move_data[Em.move.KB_ANGLE] = 0
			else:
				move_data[Em.move.KB_ANGLE] = -76
		"SSESpawn", "SSEActive":
			if Entity.v_facing == 1:
				move_data[Em.move.KB_ANGLE] = 31
			else:
				move_data[Em.move.KB_ANGLE] = -83
		"ESESpawn", "ESEActive":
			if Entity.v_facing == 1:
				move_data[Em.move.KB_ANGLE] = -25
			else:
				move_data[Em.move.KB_ANGLE] = -55
			
	if Globals.survival_level != null and Em.move.DMG in move_data:
#		move_data[Em.move.DMG] = FMath.percent(move_data[Em.move.DMG], 60)	
		move_data[Em.move.DMG] = FMath.percent(move_data[Em.move.DMG], Inventory.modifier(Entity.master_ID, Cards.effect_ref.PROJ_DMG_MOD))

	return move_data
	
	
func query_atk_attr(move_name):
	
#	var orig_move_name = move_name
	move_name = refine_move_name(move_name)
	
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
		"CircleSpawn":
			Animator.play("CircleActive")
			
		"ESpawn":
			Animator.play("EActive")
		"SSpawn":
			Animator.play("SActive")
		"SESpawn":
			Animator.play("SEActive")
		"ESESpawn":
			Animator.play("ESEActive")
		"SSESpawn":
			Animator.play("SSEActive")
			
			
func _on_SpritePlayer_anim_started(anim_name):
	match anim_name:
		_:
			pass

