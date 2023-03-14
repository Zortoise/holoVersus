extends Node2D


const TRAITS = []

# cleaner code
onready var Entity = get_parent()
var Animator
var sprite


const MOVE_DATABASE = {
	"Kill" : {
		"atk_type" : Globals.atk_type.ENTITY,
		"hitcount" : 1,
		"damage" : 99,
		"knockback" : 500 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED,
		"atk_level" : 5,
		"fixed_hitstop" : 10,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "dark_purple",
		"KB_angle" : -90,
		"proj_level" : 3,
		"atk_attr" : [Globals.atk_attr.UNBLOCKABLE],
		"hit_sound" : { ref = "impact39", aux_data = {"vol" : -10} },
	}
}

func _ready():
	get_node("TestSprite").free() # test sprite is for sizing collision box

func init(_aux_data: Dictionary):
	
	Animator.play("Kill") # starting animation
	Entity.play_audio("blast3", {"vol" : -10})

func simulate():
	pass
	
	
func query_move_data(move_name) -> Dictionary:
	
	if !move_name in MOVE_DATABASE:
		print("Error: Cannot retrieve move_data for " + move_name)
		return {}
	
	var move_data = MOVE_DATABASE[move_name].duplicate(true)
	
	if Globals.survival_level != null and "damage" in move_data:
		move_data.damage = FMath.percent(move_data.damage, Inventory.modifier(Entity.master_ID, Cards.effect_ref.PROJ_DMG_MOD))
	
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

