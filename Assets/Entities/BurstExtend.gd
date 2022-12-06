extends Node2D

const START_SPEED = 0.0
const START_ROTATION = 0.0
const START_ANIM = "Kill"

const GROUNDED_ENTITY = false

const PALETTE = null # for red
const LIFESPAN = null

# cleaner code
onready var Entity = get_parent()
var Animator
var sprite


const MOVE_DATABASE = {
	"Kill" : {
		"move_name" : "BurstExtend", # for entities, keep move_name in move_data, for checking repeat_penalty
		"atk_type" : Globals.atk_type.ENTITY,
		"hitcount" : 1,
		"damage" : 0,
		"knockback" : 550,
		"knockback_type": Globals.knockback_type.FIXED,
		"attack_level" : 8,
		"priority": 9,
		"fixed_entity_hitstop" : 0,
		"fixed_hitstop" : 15,
		"fixed_hitstun" : 50,
		"fixed_blockstun" : 5,
		"guard_drain": 0,
		"guard_gain_on_combo" : 0,
		"EX_gain": 0,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "red",
		"KB_angle" : -PI/2,
		"hit_sound" : { ref = "blast2", aux_data = {"vol" : -9} },
	}
}

func init():
	pass
	
func stimulate():
	pass
	
	
func _on_SpritePlayer_anim_finished(anim_name):
	match anim_name:
		_:
			pass
			
func _on_SpritePlayer_anim_started(anim_name):
	match anim_name:
		_:
			pass

