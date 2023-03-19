extends Node2D


const TRAITS = []

const TARGETS = [Em.field_target.MOBS, Em.field_target.MOB_ENTITIES, Em.field_target.EFFECTS, Em.field_target.PLAYER_ENTITIES]
const RADIUS = 64
#const RECT_SIZE = Vector2[64, 64]

const SLOW_AMOUNT = -1


# cleaner code
onready var Entity = get_parent()
var Animator
var sprite


func _ready():
	get_node("TestSprite").free() # test sprite is for sizing collision box

func init(_aux_data: Dictionary):
	Entity.face(1)
	Animator.play("Spawn") # starting animation
	Entity.play_audio("clock1", {"vol" : -15})
	Entity.play_audio("faller1", {"vol" : -10})
	
func load_entity():
	sprite.material = ShaderMaterial.new()
	sprite.material.shader = Loader.screeninvert_shader

func simulate():
	Entity.get_node("Sprite").rotation -= 0.5*PI * Globals.FRAME
	if Globals.Game.get_player_node(Entity.master_ID).is_hitstunned_or_sequenced():
		kill()
	
	
func inflict(node):
	if "slowed" in node and Animator.to_play_animation != "Kill":
		node.slowed = SLOW_AMOUNT

func kill():
	if Animator.to_play_animation != "Kill":
		Animator.play("Kill")
	
func _on_SpritePlayer_anim_finished(anim_name):
	match anim_name:
		"Spawn":
			Animator.play("Active")
		"Active":
			Animator.play("Kill")
			
func _on_SpritePlayer_anim_started(anim_name):
	match anim_name:
		_:
			pass

