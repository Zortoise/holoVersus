extends Node2D


const TRAITS = []

const TARGETS = Globals.field_target.ALL_MOBS
const RADIUS = 64
#const RECT_SIZE = Vector2[64, 64]

const VACUUM_STR = 200


# cleaner code
onready var Entity = get_parent()
var Animator
var sprite


func _ready():
	get_node("TestSprite").free() # test sprite is for sizing collision box

func init(_aux_data: Dictionary):
	
	Animator.play("Kill") # starting animation
	Entity.play_audio("blast3", {"vol" : -10})

func simulate():
	pass
	
	
func inflict(node):

	node.velocity.x -= FMath.percent((node.position.x - Entity.position.x) * FMath.S, VACUUM_STR)
	if !node.grounded and node.position.y < Entity.position.y:
		node.velocity.y -= FMath.percent((node.position.y - Entity.position.y) * FMath.S, VACUUM_STR)

	if posmod(Entity.lifetime, 30) == 1:
		node.take_DOT(20)
		
	node.modulate_play("gravitize")

	
func _on_SpritePlayer_anim_finished(anim_name):
	match anim_name:
		_:
			pass
			
func _on_SpritePlayer_anim_started(anim_name):
	match anim_name:
		_:
			pass

