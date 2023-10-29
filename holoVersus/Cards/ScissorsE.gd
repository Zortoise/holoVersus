extends Node2D


const TRAITS = []

# cleaner code
onready var Entity = get_parent()
var Animator
var sprite


const MOVE_DATABASE = {
	"Kill" : {
		Em.move.ATK_TYPE : Em.atk_type.ENTITY,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 90,
		Em.move.KB : 700 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 5,
		Em.move.HITSPARK_TYPE : Em.hitspark_type.SLASH,
		Em.move.HITSPARK_PALETTE : "dark_purple",
		Em.move.KB_ANGLE : -20,
		Em.move.PROJ_LVL : 1,
		Em.move.ATK_ATTR : [Em.atk_attr.DESTROY_ENTITIES],
		Em.move.HIT_SOUND : { ref = "cut2", aux_data = {"vol" : -15} },
	}
}

func _ready():
	get_node("TestSprite").free() # test sprite is for sizing collision box

func init(aux_data: Dictionary):
	Animator.play("Spawn") # starting animation
	Entity.unique_data["target_ID"] = aux_data.target_ID
		

func simulate():
	if Animator.current_anim == "Spawn":
		var target = Globals.Game.get_player_node(Entity.unique_data.target_ID)
		if target != null:
			Entity.position = target.position
	
	
func query_move_data(move_name) -> Dictionary:
	
	if !move_name in MOVE_DATABASE:
		print("Error: Cannot retrieve move_data for " + move_name + " in " + filename)
		return {}
	
	var move_data = MOVE_DATABASE[move_name].duplicate(true)
#	move_data[Em.move.ATK_ATTR] = query_atk_attr(move_name)
	
	if Globals.survival_level != null and Em.move.DMG in move_data:
		move_data[Em.move.DMG] = FMath.percent(move_data[Em.move.DMG], Inventory.modifier(Entity.master_ID, Cards.effect_ref.PROJ_DMG_MOD))
	
	return move_data
	
	
func query_atk_attr(move_name):
	
	if move_name in MOVE_DATABASE and Em.move.ATK_ATTR in MOVE_DATABASE[move_name]:
		return MOVE_DATABASE[move_name][Em.move.ATK_ATTR].duplicate(true)
	return []
	
	
func _on_SpritePlayer_anim_finished(anim_name):
	match anim_name:
		"Spawn":
			Animator.play("Kill")
			
func _on_SpritePlayer_anim_started(anim_name):
	match anim_name:
		"Kill":
			Entity.play_audio("cut6", {"vol" : -5})

