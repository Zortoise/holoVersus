extends Node2D

const START_SPEED = 500
const START_ROTATION = -PI/2.6 # radians, negative for upward
const GRAVITY = 1000
const TERMINAL_DOWN_VELOCITY = 300
const AIR_RESISTANCE = 0.01
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
		"move_name" : "Nibbler",
		"atk_type" : Globals.atk_type.ENTITY,
		"hitcount" : 1,
		"damage" : 40,
		"knockback" : 300,
		"knockback_type": Globals.knockback_type.FIXED,
		"attack_level" : 2,
		"guard_drain": 1500,
		"guard_gain_on_combo" : 1500,
		"EX_gain": 1200,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : -PI/4,
		"hit_sound" : { ref = "cut1", aux_data = {"vol" : -12} },
	},
}

func _ready():
	get_node("TestSprite").hide() # test sprite is for sizing collision box

func init(_aux_data: Dictionary):
	 # starting animation
	Animator.play("Active")
	
	match Animator.to_play_animation:
		"Active":
			Entity.velocity = Vector2(START_SPEED, 0).rotated(START_ROTATION)
			Entity.velocity.x *= Entity.facing
			Entity.absorption_value = 1

func query_move_data():
	
	var move_ref = Animator.to_play_animation
	match move_ref:
		"bActive":
			move_ref = "Active"
	
	if move_ref in MOVE_DATABASE:
		return MOVE_DATABASE[move_ref]
		
func query_atk_attr(_move_name):
	return [Globals.atk_attr.REPEATABLE]

			
func simulate():
	Entity.velocity.y = min(Entity.velocity.y + (GRAVITY * Globals.FRAME), TERMINAL_DOWN_VELOCITY)
	Entity.velocity.x = lerp(Entity.velocity.x, 0, AIR_RESISTANCE)

	match Animator.to_play_animation: # afterimage trail
		"Active", "bActive":
			if posmod(Entity.lifetime, 5) == 0:
				Globals.Game.spawn_afterimage(Entity.master_path, Entity.entity_ref, sprite.get_path(), null, 1.0, 10.0, \
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
	Globals.Game.spawn_SFX("SmallSplash", [Entity.master_path, "SmallSplash"], splash_pos, {"facing":Entity.facing, "grounded":true})
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
			Entity.velocity.x *= 0.25
			Entity.velocity.y = -250

