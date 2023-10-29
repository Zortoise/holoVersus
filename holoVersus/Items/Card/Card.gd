extends Node2D


const PALETTE = null

const TRAITS = [Em.entity_trait.GROUNDED, Em.entity_trait.BLAST_BARRIER_COLLIDE, Em.entity_trait.NO_BOUNCE, Em.entity_trait.FLOATY_ITEM,
		Em.entity_trait.SPAWN_OFFSET]

# cleaner code
onready var Entity = get_parent()
var Animator
var sprite

func _ready():
	get_node("TestSprite").free() # test sprite is for sizing collision box

func init(_aux_data: Dictionary):
	Animator.play("Marker")

func has_trait(trait: int) -> bool:
	if trait in TRAITS:
		return true
	return false

func simulate():
	pass
	
func picked_up(character):
	Animator.play("Pickup")
	Entity.stasis = true
	character.get_node("ModulatePlayer").play("unlaunch_flash")
	Entity.play_audio("ui_accept1", {"vol" : -12})
	
	if character.has_method("get_random_item"):
		character.get_random_item()

	
func bounce_sound(_soften: bool = false):
	pass
	
func kill():
	Entity.free = true
		
func on_offstage():
	Entity.free = true
	
func _on_SpritePlayer_anim_finished(anim_name):
	match anim_name:
		"Marker":
			Animator.play("Spawn")
#			Entity.play_audio("bling5", {"vol" : -10, "bus" : "PitchUp"})
		"Spawn":
			Animator.play("Active")
		
func _on_SpritePlayer_anim_started(anim_name):
	match anim_name:
		_:
			pass
