extends Node2D

const TRAITS = []

# cleaner code
onready var Entity = get_parent()
var Animator
var sprite


const MOVE_DATABASE = {
	"Active" : {
		Em.move.ROOT : "TBlockE",
		Em.move.ATK_TYPE : Em.atk_type.ENTITY,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 25,
		Em.move.KB : 300 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 2,
		Em.move.KB_ANGLE : 90,
		Em.move.HITSPARK_TYPE : Em.hitspark_type.HIT,
		Em.move.HITSPARK_PALETTE : "blue",
		Em.move.PROJ_LVL : 1,
		Em.move.ATK_ATTR : [],
		Em.move.HIT_SOUND : { ref = "impact25", aux_data = {"vol" : -12} },
	},
}

func _ready():
	get_node("TestSprite").free() # test sprite is for sizing collision box

func load_entity():
	if Animator.to_play_animation != "Kill":
		Entity.get_node("EntityCollisionBox").add_to_group("CSolidPlatforms")

func init(aux_data: Dictionary):
	Animator.play("Spawn")
	Entity.absorption_value = 1
	Entity.life_point = 1
	
	if !"branch" in aux_data:
		var height = abs((Entity.position.y + 8) - Globals.Game.middle_point.y)
		if posmod(height, 16) == 0:
			pass
		else:
			height = (int(height / 16) + 1) * 16
		Entity.position.y = Globals.Game.middle_point.y - height - 8
		Entity.set_true_position()
		
		var block_type: int = Globals.Game.rng_generate(7)
		var coord_array := []
		
		block_type = 0
		match block_type:
			0: # I block
				coord_array = [Vector2(-1, 0), Vector2(1, 0), Vector2(2, 0)]
			1: # J block
				coord_array = [Vector2(-1, 0), Vector2(1, 0), Vector2(-1, -1)]
			2: # L block
				coord_array = [Vector2(-1, 0), Vector2(1, 0), Vector2(1, -1)]
			3: # O block
				coord_array = [Vector2(-1, 0), Vector2(0, -1), Vector2(-1, -1)]
			4: # S block
				coord_array = [Vector2(-1, 0), Vector2(0, -1), Vector2(1, -1)]
			5: # Z block
				coord_array = [Vector2(1, 0), Vector2(0, -1), Vector2(-1, -1)]
			6: # T block
				coord_array = [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1)]
				
		var coord_array2 := []
		var block_rot: int = Globals.Game.rng_generate(4)
		block_rot = 0
		match block_rot:
			0:
				coord_array2 = coord_array
			1:
				for coord in coord_array:
					coord_array2.append(Vector2(-coord.y, coord.x))
			2:
				for coord in coord_array:
					coord_array2.append(Vector2(-coord.x, -coord.y))
			3:
				for coord in coord_array:
					coord_array2.append(Vector2(coord.y, -coord.x))
					
		for coord in coord_array2:
			coord *= 16
			Globals.Game.spawn_entity(Entity.master_ID, "TBlockE", Entity.position + coord, {"branch":true})
	
		
func refine_move_name(move_name):
		
	match move_name:
		"Spawn":
			return "Active"
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
	if posmod(Entity.lifetime, 10) == 0 and Animator.to_play_animation != "Kill":
		if !Detection.detect_bool([Entity.get_node("EntityCollisionBox")], ["SolidPlatforms"], Vector2(0, 16)):
			Entity.position.y += 16
			Entity.set_true_position()
		else:
			kill()
	
func kill():
	if Animator.to_play_animation != "Kill":
		Animator.play("Kill")
		
	
func collision(): # collided with a platform
	kill()

func landed_a_hit(_hit_data):
	kill()
		
func on_offstage():
	Entity.free = true
	
func _on_SpritePlayer_anim_finished(anim_name):
	match anim_name:
		"Spawn":
			Animator.play("Active")
			
func _on_SpritePlayer_anim_started(anim_name):
	match anim_name:
		"Kill":
			Entity.velocity.set_vector(0, 0)
			Entity.play_audio("break2", {"vol" : -20})
			Entity.get_node("EntityCollisionBox").remove_from_group("CSolidPlatforms")

