extends Node2D

const START_SPEED = 500 * FMath.S

const GRAVITY = 18 * FMath.S
const TERMINAL_DOWN_VELOCITY = 400 * FMath.S
const AIR_RESISTANCE = 2
const FALL_LIMIT = -200 * FMath.S

const TRAITS = [Em.entity_trait.GROUNDED, Em.entity_trait.AIR_GROUND]

# cleaner code
onready var Entity = get_parent()
var Animator
var sprite


const MOVE_DATABASE = {
	"Strike" : {
		Em.move.ROOT : "NousagiE",
		Em.move.ATK_TYPE : Em.atk_type.ENTITY,
		Em.move.HITCOUNT : 2,
		Em.move.DMG : 40,
		Em.move.KB : 450 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.VELOCITY,
		Em.move.ATK_LVL : 3,
		Em.move.KB_ANGLE : 0,
		Em.move.HITSPARK_TYPE : Em.hitspark_type.HIT,
		Em.move.HITSPARK_PALETTE : "blue",
		Em.move.PROJ_LVL : 1,
		Em.move.ATK_ATTR : [Em.atk_attr.DRAG_KB],
		Em.move.HIT_SOUND : { ref = "impact25", aux_data = {"vol" : -12} },
	},
}

func _ready():
	get_node("TestSprite").free() # test sprite is for sizing collision box

func init(_aux_data: Dictionary):
	Animator.play("Spawn")

	Entity.absorption_value = 1
	Entity.life_point = 1
	
	Entity.velocity.set_vector(START_SPEED, 0)
	Entity.velocity.rotate(-75)
	Entity.velocity.x *= Entity.facing
	

func refine_move_name(move_name):
	return move_name
	
		
func query_move_data(move_name) -> Dictionary:
	
	move_name = refine_move_name(move_name)
	
	if !move_name in MOVE_DATABASE:
		print("Error: Cannot retrieve move_data for " + move_name + " in " + filename)
		return {}
	
	var move_data = MOVE_DATABASE[move_name].duplicate(true)
#	move_data[Em.move.ATK_ATTR] = query_atk_attr(move_name)
	
	if Globals.survival_level != null and Em.move.DMG in move_data:
		move_data[Em.move.DMG] = FMath.percent(move_data[Em.move.DMG], Inventory.modifier(Entity.master_ID, Cards.effect_ref.PROJ_DMG_MOD))
	
	return move_data
		
		
func query_atk_attr(move_name):
	
	if !Animator.to_play_anim in ["Kill", "Strike"]:
		return [Em.atk_attr.HARMLESS_ENTITY]
	
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
	if Animator.to_play_anim in ["Jump", "FallTransit", "Fall"]: # jump arc
		Entity.velocity.y = int(min(Entity.velocity.y + GRAVITY, TERMINAL_DOWN_VELOCITY))
		Entity.velocity.x = FMath.f_lerp(Entity.velocity.x, 0, AIR_RESISTANCE)
		
		match Animator.to_play_anim:
			"Jump":
				if Entity.velocity.y > FALL_LIMIT:
					Animator.play("FallTransit")
					
	
func kill(sound = true):
	if Animator.to_play_anim != "Kill": Animator.play("Kill")
	if sound: Entity.play_audio("impact25", {"vol" : -12})
	
	
func collision(_landed := false, _orig_vel_x := 0, _orig_vel_y := 0): # collided with a platform
	if Animator.to_play_anim in ["Jump", "FallTransit", "Fall"]:
		if Entity.is_on_ground(Entity.get_node("EntityCollisionBox")):
			Animator.play("Land")
		

#func landed_a_hit(_hit_data):
#	kill(false)
		
func on_offstage():
	Entity.free = true
	
func _on_SpritePlayer_anim_finished(anim_name):
	match anim_name:
		"Spawn":
			Animator.play("Jump")
		"FallTransit":
			Animator.play("Fall")
		"Land":
			Animator.play("Strike")
		"Strike":
			Animator.play("Kill")

			
func _on_SpritePlayer_anim_started(anim_name):
	
	if Animator.to_play_anim.ends_with("Kill"):
		Entity.velocity.set_vector(0, 0)
		Entity.get_node("Sprite").rotation = 0

	match anim_name:
		"Kill":
			Entity.velocity.set_vector(0, 0)
		"Land":
			Entity.velocity.x = 0
			Globals.Game.spawn_SFX("LandDust", "DustClouds", Entity.get_feet_pos(), {"grounded":true})
			var target = Globals.Game.get_player_node(Entity.master_ID).get_target()
			if target != null:
				var target_dir = int(sign(target.position.x - Entity.position.x))
				if target_dir != Entity.facing:
					Entity.face(-Entity.facing)
			Entity.play_audio("entity_land1", {"vol" : -12})
			Entity.play_audio("bling7", {"vol" : -15, "bus" : "PitchUp"}) # EX chime
			
		"Strike":
			var target = Globals.Game.get_player_node(Entity.master_ID).get_target()
			if target != null:
				var target_dir = int(sign(target.position.x - Entity.position.x))
				if target_dir != Entity.facing:
					Entity.face(-Entity.facing)
			var angle_finder := FVector.new()
			angle_finder.set_from_vec(target.position - Entity.position)
			var angle = angle_finder.angle()
			
			Entity.velocity.set_vector(START_SPEED, 0)
			Entity.velocity.rotate(angle)
			Entity.get_node("Sprite").rotation = 0
			Entity.rotate_sprite(angle)

			Entity.play_audio("impact37", {"vol" : -20})
