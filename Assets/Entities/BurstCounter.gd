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
		Em.move.BURST : "BurstCounter",
		Em.move.ATK_TYPE : Em.atk_type.ENTITY,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 0,
		Em.move.KB : 1000 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.RADIAL,
		Em.move.ATK_LVL : 8,
		Em.move.FIXED_ATKER_HITSTOP : 0,
		Em.move.FIXED_HITSTOP : 15,
		Em.move.FIXED_HITSTUN : 38,
		Em.move.HITSPARK_TYPE : Em.hitspark_type.HIT,
		Em.move.HITSPARK_PALETTE : "yellow",
		Em.move.KB_ANGLE : 0,
		Em.move.PROJ_LVL : 3,
		Em.move.ATK_ATTR : [Em.atk_attr.UNBLOCKABLE, Em.atk_attr.SCREEN_SHAKE, Em.atk_attr.DESTROY_ENTITIES],
		Em.move.HIT_SOUND : { ref = "blast2", aux_data = {"vol" : -9} },
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
	
	if move_name in MOVE_DATABASE and Em.move.ATK_ATTR in MOVE_DATABASE[move_name]:
		return MOVE_DATABASE[move_name][Em.move.ATK_ATTR].duplicate(true)
	return []
	
	
func _on_SpritePlayer_anim_finished(anim_name):
	match anim_name:
		_:
			pass
			
func _on_SpritePlayer_anim_started(anim_name):
	match anim_name:
		_:
			pass

