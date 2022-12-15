extends Node2D

const PALETTE = null

const TRAITS = [Globals.entity_trait.GROUNDED]

# cleaner code
onready var Entity = get_parent()
var Animator
var sprite


const MOVE_DATABASE = {
	"Kill" : {
		"move_name" : "SharkBreach", # for entities, keep move_name in move_data, for checking repeat
		"atk_type" : Globals.atk_type.ENTITY,
		"hitcount" : 1,
		"damage" : 90,
		"knockback" : 475,
		"knockback_type": Globals.knockback_type.FIXED,
		"attack_level" : 5,
		"fixed_hitstop" : 10,
		"guard_drain": 1750,
		"guard_gain_on_combo" : 2500,
		"EX_gain": 0,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : -PI/3,
		"hit_sound" : { ref = "water1", aux_data = {"vol" : -6} },
	}
}

func init(_aux_data: Dictionary):
	Animator.play("Kill") # starting animation

func stimulate():
	pass
	
func query_atk_attr(_in_move_name):
	return [Globals.atk_attr.REPEATABLE]
	
func _on_SpritePlayer_anim_finished(anim_name):
	match anim_name:
		_:
			pass
			
func _on_SpritePlayer_anim_started(anim_name):
	match anim_name:
		_:
			pass

