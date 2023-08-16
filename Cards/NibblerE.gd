extends Node2D

const START_SPEED = 500 * FMath.S
const START_ROTATION = -70 # integer degree, negative for upward
const GRAVITY = 18 * FMath.S
const TERMINAL_DOWN_VELOCITY = 300 * FMath.S
const AIR_RESISTANCE = 1
#const LIFESPAN = null

const TRAITS = []
# example: Em.entity_trait.GROUNDED

# cleaner code
onready var Entity = get_parent()
var Animator
var sprite


const MOVE_DATABASE = {
	"Active" : {
		Em.move.ROOT : "NibblerE",
		Em.move.ATK_TYPE : Em.atk_type.ENTITY,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 40,
		Em.move.KB : 300 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 2,
		Em.move.KB_ANGLE : -45,
		Em.move.PROJ_LVL : 1,
		Em.move.ATK_ATTR : [],
		Em.move.HIT_SOUND : { ref = "cut1", aux_data = {"vol" : -12} },
	},
}

func _ready():
	get_node("TestSprite").free() # test sprite is for sizing collision box

func init(_aux_data: Dictionary):
	 # starting animation
	Animator.play("Active")
	
	match Animator.to_play_anim:
		"Active":
			Entity.velocity.set_vector(START_SPEED, 0)
			Entity.velocity.rotate(START_ROTATION)
			Entity.velocity.x *= Entity.facing
			Entity.absorption_value = 1

		
func refine_move_name(move_name):
		
	match move_name:
		"bActive":
			return "Active"
	return move_name
		
func query_move_data(move_name) -> Dictionary:
	
	move_name = refine_move_name(move_name)
	
	if !move_name in MOVE_DATABASE:
		print("Error: Cannot retrieve move_data for " + move_name)
		return {}
	
	var move_data = MOVE_DATABASE[move_name].duplicate(true)
#	move_data[Em.move.ATK_ATTR] = query_atk_attr(move_name)
	
	if Globals.survival_level != null and Em.move.DMG in move_data:
#		move_data[Em.move.DMG] = FMath.percent(move_data[Em.move.DMG], 60)	
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
	Entity.velocity.y = int(min(Entity.velocity.y + GRAVITY, TERMINAL_DOWN_VELOCITY))
	Entity.velocity.x = FMath.f_lerp(Entity.velocity.x, 0, AIR_RESISTANCE)

	match Animator.to_play_anim: # afterimage trail
		"Active", "bActive":
			if posmod(Entity.lifetime, 5) == 0:
				Globals.Game.spawn_afterimage(Entity.entity_ID, Em.afterimage_type.ENTITY, Entity.entity_ref, sprite.get_path(), null, null, \
						null, 1.0, 10.0, Em.afterimage_shader.WHITE)
	
func kill(sound = true):
	if Animator.to_play_anim != "Kill":
		Animator.play("Kill")
		# splash sound
		if sound:
			Entity.play_audio("water11", {"vol" : -12,})
			Entity.play_audio("water1", {"vol" : -12})
	
	
func collision(_landed := false, _orig_vel_x := 0, _orig_vel_y := 0): # collided with a platform
	var splash_pos = Entity.position + Vector2(0, Entity.get_node("EntityCollisionBox").rect_position.y + \
			Entity.get_node("EntityCollisionBox").rect_size.y) # get feet pos
	Globals.Game.spawn_SFX("SmallSplash", "SmallSplash", splash_pos, {"facing":Entity.facing, "grounded":true})
	kill()
	
#func ledge_drop():

func check_passthrough(): # during death bounce, will pass through walls
	if Animator.to_play_anim == "Kill":
		return true
	return false

	
func landed_a_hit(_hit_data):
	kill(false)
		
func on_offstage():
	Entity.free = true
	
func _on_SpritePlayer_anim_finished(anim_name):
	match anim_name:
		"Active":
			Animator.play("bActive")
			
func _on_SpritePlayer_anim_started(anim_name):
	match anim_name:
		"Kill":
			Entity.velocity.x = FMath.percent(Entity.velocity.x, 25)
			Entity.velocity.y = -250 * FMath.S

