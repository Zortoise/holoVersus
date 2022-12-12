extends Node2D

#const START_SPEED = 0.0
#const START_ROTATION = 0.0
const PALETTE = "blue"
#const LIFESPAN = null

const TRAITS = []

# cleaner code
onready var Entity = get_parent()
var Animator
var sprite


const MOVE_DATABASE = {
	"Kill" : {
		"move_name" : "BurstEscape", # for entities, keep move_name in move_data, for checking repeat_penalty
		"atk_type" : Globals.atk_type.ENTITY,
		"hitcount" : 1,
		"damage" : 0,
		"knockback" : 550,
		"knockback_type": Globals.knockback_type.RADIAL,
		"attack_level" : 8,
		"fixed_entity_hitstop" : 0,
		"fixed_hitstop" : 15,
		"fixed_hitstun" : 30,
		"fixed_blockstun" : 5,
		"guard_drain": 0,
		"guard_gain_on_combo" : 0,
		"EX_gain": 0,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : 0.0,
		"hit_sound" : { ref = "blast2", aux_data = {"vol" : -9} },
	}
}

func init(_aux_data: Dictionary):
	
	# set up starting data
	
	Animator.play("Kill") # starting animation
	
#	Entity.velocity = Vector2(START_SPEED, 0).rotated(START_ROTATION)
	
#	Entity.lifespan = LIFESPAN # set starting lifespan
#	Entity.absorption_value = ABSORPTION # set starting absorption_value

	
func stimulate():
	pass
	
func query_atk_attr(_in_move_name):
	return [Globals.atk_attr.SCREEN_SHAKE]
	
func _on_SpritePlayer_anim_finished(anim_name):
	match anim_name:
		_:
			pass
			
func _on_SpritePlayer_anim_started(anim_name):
	match anim_name:
		_:
			pass

