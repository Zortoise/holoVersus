extends Node2D


const TRAITS = []

const TARGETS = Globals.field_target.ALL_BUT_PLAYERS
const RADIUS = 64
#const RECT_SIZE = Vector2[64, 64]

const SLOW_AMOUNT = 4


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
	if "slowed" in node:
		node.slowed = SLOW_AMOUNT


	
func _on_SpritePlayer_anim_finished(anim_name):
	match anim_name:
		_:
			pass
			
func _on_SpritePlayer_anim_started(anim_name):
	match anim_name:
		_:
			pass

