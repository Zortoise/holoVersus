extends Node2D

#const START_SPEED = 0.0
#const START_ROTATION = 0.0
const PALETTE = "yellow"
#const LIFESPAN = null

const TRAITS = []

# cleaner code
onready var Entity = get_parent()
var Animator
var sprite


const MOVE_DATABASE = {
	"Kill" : {
		"burst" : "BurstCounter",
		"atk_type" : Globals.atk_type.ENTITY,
		"hitcount" : 1,
		"damage" : 0,
		"knockback" : 1000 * FMath.S,
		"knockback_type": Globals.knockback_type.RADIAL,
		"atk_level" : 8,
		"fixed_entity_hitstop" : 0,
		"fixed_hitstop" : 15,
		"fixed_hitstun" : 38,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "yellow",
		"KB_angle" : 0,
		"proj_level" : 3,
		"atk_attr" : [Globals.atk_attr.UNBLOCKABLE, Globals.atk_attr.SCREEN_SHAKE, Globals.atk_attr.DESTROY_ENTITIES],
		"hit_sound" : { ref = "blast2", aux_data = {"vol" : -9} },
	}
}

func _ready():
	get_node("TestSprite").free()

func init(_aux_data: Dictionary):
	
	# set up starting data
	
	Animator.play("Kill") # starting animation
	
#	Entity.velocity = Vector2(START_SPEED, 0).rotated(START_ROTATION)
	
#	Entity.lifespan = LIFESPAN # set starting lifespan
#	Entity.absorption_value = ABSORPTION # set starting absorption_value

	
func simulate():
	pass
	
	
func query_move_data(move_name) -> Dictionary:
	
	if !move_name in MOVE_DATABASE:
		print("Error: Cannot retrieve move_data for " + move_name)
		return {}
	
	var move_data = MOVE_DATABASE[move_name].duplicate(true)
	
	match move_name: # move data may change for certain moves under certain conditions, unique to character
		_ :
			pass
	
	return move_data
	
	
func query_atk_attr(move_name):
	
	if move_name in MOVE_DATABASE and "atk_attr" in MOVE_DATABASE[move_name]:
		return MOVE_DATABASE[move_name].atk_attr.duplicate(true)
	return []
	
	
func _on_SpritePlayer_anim_finished(anim_name):
	match anim_name:
		_:
			pass
			
func _on_SpritePlayer_anim_started(anim_name):
	match anim_name:
		_:
			pass

