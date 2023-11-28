extends Node2D

const START_SPEED = 450 * FMath.S
const RUN_SPEED = 75 * FMath.S

const GRAVITY = 18 * FMath.S
const TERMINAL_DOWN_VELOCITY = 300 * FMath.S
const AIR_RESISTANCE = 2

const TRAITS = [Em.entity_trait.GROUNDED, Em.entity_trait.AIR_GROUND, Em.entity_trait.BLAST_BARRIER_COLLIDE]

# cleaner code
onready var Entity = get_parent()
var Animator
var sprite


const MOVE_DATABASE = {
	"Kill" : {
		Em.move.ROOT : "SsrbE",
		Em.move.ATK_TYPE : Em.atk_type.ENTITY,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 150,
		Em.move.KB : 600 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.RADIAL,
		Em.move.ATK_LVL : 6,
		Em.move.FIXED_ATKER_HITSTOP : 0,
		Em.move.KB_ANGLE : 0,
		Em.move.HITSPARK_TYPE : Em.hitspark_type.HIT,
		Em.move.HITSPARK_PALETTE : "yellow",
		Em.move.PROJ_LVL : 3,
		Em.move.ATK_ATTR : [Em.atk_attr.DESTROY_ENTITIES],
		Em.move.HIT_SOUND : { ref = "impact35", aux_data = {"vol" : -6} },
	},
}

func _ready():
	get_node("TestSprite").free() # test sprite is for sizing collision box

func init(_aux_data: Dictionary):
	Animator.play("Spawn")
	Entity.velocity.set_vector(START_SPEED, 0)
	Entity.velocity.rotate(-65)
		
	Entity.velocity.x *= Entity.facing
	
	Entity.absorption_value = 1
	Entity.life_point = 1
	
	Entity.unique_data["timer_ID"] = Globals.Game.spawn_entity(Entity.master_ID, "SsrbTimerE", Entity.position, \
			{"facing" : 1, "sticky_ID" : Entity.entity_ID}).entity_ID # note, this is NOT a sticky SFX
	
	Entity.play_audio("matches1", {"vol" : -15})
		
func refine_move_name(move_name):
		
	match move_name:
		"2Kill":
			return "Kill"
	return move_name
	
		
func query_move_data(move_name) -> Dictionary:
	
	var orig_move_name = move_name
	move_name = refine_move_name(move_name)
	
	if !move_name in MOVE_DATABASE:
		print("Error: Cannot retrieve move_data for " + move_name + " in " + filename)
		return {}
	
	var move_data = MOVE_DATABASE[move_name].duplicate(true)
#	move_data[Em.move.ATK_ATTR] = query_atk_attr(move_name)
	
	if Globals.survival_level != null and Em.move.DMG in move_data:
		move_data[Em.move.DMG] = FMath.percent(move_data[Em.move.DMG], Inventory.modifier(Entity.master_ID, Cards.effect_ref.PROJ_DMG_MOD))
	
	match orig_move_name:
		"2Kill":
			move_data[Em.move.KB_TYPE] = Em.knockback_type.MIRRORED
			move_data[Em.move.KB_ANGLE] = -70
	
	return move_data
		
		
func query_atk_attr(move_name):
	
	if Animator.to_play_anim in ["Spawn", "Jump", "Run"]:
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
	if Animator.to_play_anim in ["Spawn", "Jump"]: # throw arc
		Entity.velocity.y = int(min(Entity.velocity.y + GRAVITY, TERMINAL_DOWN_VELOCITY))
		Entity.velocity.x = FMath.f_lerp(Entity.velocity.x, 0, AIR_RESISTANCE)
		
	elif Animator.to_play_anim == "Run":
		if Entity.is_on_ground(Entity.get_node("EntityCollisionBox")):
			var target = Globals.Game.get_player_node(Entity.master_ID).get_target()
			if target != null:
				var target_dir = int(sign(target.position.x - Entity.position.x))
				if target_dir != Entity.facing:
					Entity.face(-Entity.facing)
				
				if abs(target.position.x - Entity.position.x) <= 15:
					Entity.velocity.x = 0
				else:
					Entity.velocity.x = RUN_SPEED * Entity.facing
			
		else: # ran off ledges
			Animator.play("Jump")
			
	if !Animator.to_play_anim.ends_with("Kill"):
		var timer = Globals.Game.get_entity_node(Entity.unique_data.timer_ID)
		if timer != null:
			if Entity.lifetime <= 60:
				pass
			elif Entity.lifetime <= 120:
				timer.UniqEntity.time("Time4")
			elif Entity.lifetime <= 180:
				timer.UniqEntity.time("Time3")
			elif Entity.lifetime <= 240:
				timer.UniqEntity.time("Time2")
			elif Entity.lifetime <= 300:
				timer.UniqEntity.time("Time1")
			
		if Entity.lifetime > 300:
			kill()
					
	
func kill(sound = true):
	match Animator.to_play_anim:
		"Spawn", "Jump":
			Animator.play("Kill")
		"Run":
			Animator.play("2Kill")
	if sound: Entity.play_audio("impact25", {"vol" : -12})
	
	
func collision(_landed := false, _orig_vel_x := 0, _orig_vel_y := 0): # collided with a platform
	if Animator.to_play_anim in ["Spawn", "Jump"]:
		if Entity.is_on_ground(Entity.get_node("EntityCollisionBox")):
			Animator.play("Run")
			Globals.Game.spawn_SFX("LandDust", "DustClouds", Entity.get_feet_pos(), {"grounded":true})
			Entity.play_audio("entity_land2", {"vol" : -6})
		

#func landed_a_hit(_hit_data):
#	kill(false)
		
func on_offstage():
	Entity.free = true
	
func _on_SpritePlayer_anim_finished(anim_name):
	match anim_name:
		"Spawn":
			Animator.play("Jump")

			
func _on_SpritePlayer_anim_started(anim_name):
	
	if Animator.to_play_anim.ends_with("Kill"):
		Entity.velocity.set_vector(0, 0)
		Entity.get_node("Sprite").rotation = 0
		Entity.absorption_value = null
		var timer = Globals.Game.get_entity_node(Entity.unique_data.timer_ID)
		if timer != null: timer.free = true
	
	match anim_name:
		"Run":
			Entity.velocity.y = 0
		"Kill", "2Kill":
			Entity.play_audio("explosion2", {"vol" : -12})

