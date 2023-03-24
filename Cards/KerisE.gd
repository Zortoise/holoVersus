extends Node2D

const START_SPEED = 500 * FMath.S

const TRAITS = []

# cleaner code
onready var Entity = get_parent()
var Animator
var sprite


const MOVE_DATABASE = {
	"Active" : {
		Em.move.ROOT : "KerisE",
		Em.move.ATK_TYPE : Em.atk_type.ENTITY,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 25,
		Em.move.KB : 300 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.VELOCITY,
		Em.move.ATK_LVL : 2,
		Em.move.KB_ANGLE : 0,
		Em.move.HITSPARK_TYPE : Em.hitspark_type.SLASH,
		Em.move.HITSPARK_PALETTE : "yellow",
		Em.move.PROJ_LVL : 1,
		Em.move.ATK_ATTR : [],
		Em.move.HIT_SOUND : { ref = "cut6", aux_data = {"vol" : -10} },
	},
}

func _ready():
	get_node("TestSprite").free() # test sprite is for sizing collision box

func init(_aux_data: Dictionary):
	Animator.play("Spawn")
	Entity.absorption_value = 1
	Entity.life_point = 1
		
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
	if Animator.to_play_animation in ["Spawn", "Spin"]:
		if Entity.lifetime < 60:
			Entity.get_node("Sprite").rotation += 5*PI * Globals.FRAME * Entity.facing
		else:
			Animator.play("Active")
			var master_node = Globals.Game.get_player_node(Entity.master_ID)
			var enemy_node = master_node.get_target()
			if enemy_node == null:
				enemy_node = master_node
			
			if enemy_node == master_node:
				Entity.velocity.set_vector(START_SPEED * Entity.facing, 0)
				Entity.get_node("Sprite").rotation = 0
			else:
				var angle_finder := FVector.new()
				angle_finder.set_from_vec(enemy_node.position - Entity.position)
				var angle = angle_finder.angle()
				
				Entity.velocity.set_vector(START_SPEED, 0)
				Entity.velocity.rotate(angle)
#				Entity.get_node("Sprite").rotation = 0
				Entity.rotate_sprite(angle)
			
	
func kill(sound = true):
	if Animator.to_play_animation != "Kill":
		Animator.play("Kill")
		if sound: Entity.play_audio("break2", {"vol" : -18})
	
#func expire():
#	if Animator.to_play_animation != "Expire":
#		Animator.play("Expire")
	
func collision(): # collided with a platform
	kill()

func landed_a_hit(_hit_data):
	kill(false)
		
func on_offstage():
	if Entity.lifetime > 120:
		Entity.free = true
	
func _on_SpritePlayer_anim_finished(anim_name):
	match anim_name:
		"Spawn":
			Animator.play("Spin")
			
func _on_SpritePlayer_anim_started(anim_name):
	match anim_name:
		"Kill":
			Entity.velocity.set_vector(0, 0)

