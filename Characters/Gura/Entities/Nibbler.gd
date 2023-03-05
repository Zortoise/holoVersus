extends Node2D

const START_SPEED = 500 * FMath.S
const START_ROTATION = -70 # integer degree, negative for upward
const GRAVITY = 18 * FMath.S
const TERMINAL_DOWN_VELOCITY = 300 * FMath.S
const AIR_RESISTANCE = 1
const PALETTE = null # setting this to null make it use its master's palette, not having PALETTE make it use default colors
#const LIFESPAN = null

const TRAITS = []
# example: Globals.entity_trait.GROUNDED

# cleaner code
onready var Entity = get_parent()
var Animator
var sprite


const MOVE_DATABASE = {
	"Active" : {
		"root" : "Nibbler",
		"atk_type" : Globals.atk_type.ENTITY,
		"hitcount" : 1,
		"damage" : 40,
		"knockback" : 300 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED,
		"atk_level" : 2,
		"KB_angle" : -45,
		"proj_level" : 1,
		"atk_attr" : [Globals.atk_attr.REPEATABLE],
		"hit_sound" : { ref = "cut1", aux_data = {"vol" : -12} },
	},
}

func _ready():
	get_node("TestSprite").free() # test sprite is for sizing collision box

func init(_aux_data: Dictionary):
	 # starting animation
	Animator.play("Active")
	
	match Animator.to_play_animation:
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
	
	if Globals.survival_level != null and "damage" in move_data:
		move_data.damage = FMath.percent(move_data.damage, 60)	
		move_data.damage = FMath.percent(move_data.damage, Inventory.modifier(Entity.master_ID, Cards.effect_ref.PROJ_DMG_MOD))
	
	return move_data
		
		
func query_atk_attr(move_name):
	
	move_name = refine_move_name(move_name)

	if move_name in MOVE_DATABASE and "atk_attr" in MOVE_DATABASE[move_name]:
		return MOVE_DATABASE[move_name].atk_attr.duplicate(true)
		
#	print("Error: Cannot retrieve atk_attr for " + move_name)
	return []

			
func simulate():
	Entity.velocity.y = int(min(Entity.velocity.y + GRAVITY, TERMINAL_DOWN_VELOCITY))
	Entity.velocity.x = FMath.f_lerp(Entity.velocity.x, 0, AIR_RESISTANCE)

	match Animator.to_play_animation: # afterimage trail
		"Active", "bActive":
			if posmod(Entity.lifetime, 5) == 0:
				Globals.Game.spawn_afterimage(get_node(Entity.creator_path).player_ID, Entity.entity_ref, sprite.get_path(), null, 1.0, 10.0, \
						Globals.afterimage_shader.WHITE)
	
func kill(sound = true):
	if Animator.to_play_animation != "Kill":
		Animator.play("Kill")
		# splash sound
		if sound:
			Entity.play_audio("water11", {"vol" : -12})
			Entity.play_audio("water1", {"vol" : -12})
	
	
func collision(): # collided with a platform
	var splash_pos = Entity.position + Vector2(0, Entity.get_node("EntityCollisionBox").rect_position.y + \
			Entity.get_node("EntityCollisionBox").rect_size.y) # get feet pos
	Globals.Game.spawn_SFX("SmallSplash", "SmallSplash", splash_pos, {"facing":Entity.facing, "grounded":true, "palette" : "master"}, \
			get_node(Entity.creator_path).player_ID)
	kill()
	
#func ledge_drop():

func check_passthrough(): # during death bounce, will pass through walls
	if Animator.to_play_animation == "Kill":
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

