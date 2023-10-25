extends Node2D


const PALETTE = null

const TRAITS = [Em.entity_trait.GROUNDED, Em.entity_trait.BLAST_BARRIER_COLLIDE]

# cleaner code
onready var Entity = get_parent()
var Animator
var sprite

func _ready():
	get_node("TestSprite").free() # test sprite is for sizing collision box

func init(_aux_data: Dictionary):
	Animator.play("Spawn")

func simulate():
	pass
	
func picked_up(character):
	Animator.play("Pickup")
	Entity.stasis = true
	character.get_node("ModulatePlayer").play("unlaunch_flash")
	Entity.play_audio("bling1", {"vol" : -20, "bus" : "PitchUp"})
	Entity.play_audio("bling2", {"vol" : -15})
	if character.has_method("gain_prism"):
		if Globals.player_count == 1:
			character.gain_prism(10)
		else:
			character.gain_prism(15)
	
func bounce_sound(soften: bool = false):
	if !soften:
		Entity.play_audio("bling6", {"vol" : -10})
	else:
		Entity.play_audio("bling6", {"vol" : -20})
	
func kill():
	Entity.free = true
		
func on_offstage():
	Entity.free = true
	
func _on_SpritePlayer_anim_finished(anim_name):
	match anim_name:
		"Spawn":
			Animator.play("Active")
		
func _on_SpritePlayer_anim_started(anim_name):
	match anim_name:
		_:
			pass
