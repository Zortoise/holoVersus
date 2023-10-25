extends Node2D


const TRAITS = []

const TARGETS = [Em.field_target.MOBS]
const RADIUS = 64
#const RECT_SIZE = Vector2[64, 64]

const VACUUM_STR = 300
const LIFESPAN = 240


# cleaner code
onready var Entity = get_parent()
var Animator
var sprite


func _ready():
	get_node("TestSprite").free() # test sprite is for sizing collision box

func init(_aux_data: Dictionary):
	
	Animator.play("Active") # starting animation

func simulate():
	if posmod(Entity.lifetime, 28) == 0:
		Entity.play_audio("vortex1", {"vol" : -18})
	
	if Entity.lifetime < 3:
		sprite.modulate.a = 0.33
	elif Entity.lifetime < 6:
		sprite.modulate.a = 0.67
	elif Entity.lifetime < LIFESPAN:
		sprite.modulate.a = 1
	elif Entity.lifetime < LIFESPAN + 3:
		sprite.modulate.a = 0.67
	elif Entity.lifetime < LIFESPAN + 6:
		sprite.modulate.a = 0.33
	else:
		Entity.free = true
		
	
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

