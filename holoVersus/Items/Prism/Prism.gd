extends Node2D


const PALETTE = null

const TRAITS = [Em.entity_trait.GROUNDED, Em.entity_trait.BLAST_BARRIER_COLLIDE]

# cleaner code
onready var Entity = get_parent()
var Animator
var sprite

func _ready():
	get_node("TestSprite").free() # test sprite is for sizing collision box

func init(aux_data: Dictionary):
	Animator.play("Spawn")
	
	Entity.unique_data = {"type" : 0}
	
	if "type" in aux_data:
		Entity.unique_data.type = aux_data.type
		

func has_trait(trait: int) -> bool:
	if trait in TRAITS:
		return true
	return false

func simulate():
	pass
	
func picked_up(character):
	Entity.stasis = true
	character.get_node("ModulatePlayer").play("unlaunch_flash")
	Entity.play_audio("bling1", {"vol" : -20, "bus" : "PitchUp"})
	Entity.play_audio("bling2", {"vol" : -15})
	
	match Entity.unique_data.type:
		0:
			Animator.play("Pickup")
			if character.has_method("gain_prism"):
				if Globals.player_count == 1:
					character.gain_prism(10)
				else:
					character.gain_prism(15)
		1:
			Animator.play("LifePickup")
			if character.has_method("get_stat") and character.has_method("take_damage"):
				var healed = FMath.percent(character.get_stat("DAMAGE_VALUE_LIMIT"), 20)
				character.take_damage(-healed)
				Globals.Game.spawn_damage_number(healed, character.position, Em.dmg_num_col.GREEN, true)
	
		2:
			Animator.play("TimePickup")
			Globals.Game.spawn_damage_number("+30 sec", Entity.position, null, true)
			Globals.Game.matchtime += 30 * 60
	
	
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
			match Entity.unique_data.type:
				0:
					Animator.play("Active")
				1:
					Animator.play("LifeActive")
				2:
					Animator.play("TimeActive")
		
func _on_SpritePlayer_anim_started(anim_name):
	match anim_name:
		_:
			pass
