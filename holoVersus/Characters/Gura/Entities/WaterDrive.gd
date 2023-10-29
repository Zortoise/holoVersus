extends Node2D

const START_SPEED = 400 * FMath.S
const LIFESPAN = 90

const TRAITS = []
# example: Em.entity_trait.GROUNDED

# cleaner code
onready var Entity = get_parent()
var Animator
var sprite


const MOVE_DATABASE = {
	"Active" : {
		Em.move.ROOT : "WaterDrive",
		Em.move.ATK_TYPE : Em.atk_type.ENTITY,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 60,
		Em.move.KB : 400 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 3,
		Em.move.KB_ANGLE : -30,
		Em.move.HITSPARK_TYPE : Em.hitspark_type.SLASH,
		Em.move.PROJ_LVL : 1,
		Em.move.ATK_ATTR : [],
		Em.move.HIT_SOUND : [{ ref = "cut5", aux_data = {"vol" : -10} }, { ref = "water11", aux_data = { "bus": "LowPass", "vol" : -8,}}],
	}
}

func _ready():
	get_node("TestSprite").free() # test sprite is for sizing collision box

func init(aux_data: Dictionary):
	
	Entity.velocity.set_vector(START_SPEED, 0)
	
	 # starting animation
	if !"alt_aim" in aux_data:
		Animator.play("Spawn")
	else:
		Animator.play("[u]Spawn")
		Entity.velocity.rotate(-45)

	Entity.velocity.x *= Entity.facing
	Entity.absorption_value = 1
	Entity.life_point = 1
	Entity.lifespan = LIFESPAN


func refine_move_name(move_name):
	match move_name:
		"Spawn", "[u]Spawn", "[u]Active":
			return "Active"
	return move_name


func query_move_data(move_name) -> Dictionary:
	
	var orig_move_name = move_name

	move_name = refine_move_name(move_name)
	
	if !move_name in MOVE_DATABASE:
		print("Error: Cannot retrieve move_data for " + move_name + " in " + filename)
		return {}
	
	var move_data = MOVE_DATABASE[move_name].duplicate(true)

	if orig_move_name.begins_with("[u]"):
		move_data[Em.move.KB_ANGLE] = -60
	
	if Globals.survival_level != null:
		if Em.move.DMG in move_data:
			move_data[Em.move.DMG] = FMath.percent(move_data[Em.move.DMG], Inventory.modifier(Entity.master_ID, Cards.effect_ref.PROJ_DMG_MOD))
	
	return move_data
	

func query_atk_attr(move_name):
	
	move_name = refine_move_name(move_name)

	if move_name in MOVE_DATABASE and Em.move.ATK_ATTR in MOVE_DATABASE[move_name]:
		return MOVE_DATABASE[move_name][Em.move.ATK_ATTR].duplicate(true)
		
#	print("Error: Cannot retrieve atk_attr for " + move_name)
	return []
	
	
func get_proj_level(move_name):
	move_name = refine_move_name(move_name)

	if move_name in MOVE_DATABASE and Em.move.PROJ_LVL in MOVE_DATABASE[move_name]:
		return MOVE_DATABASE[move_name][Em.move.PROJ_LVL]
	
	return 1
	
			
func simulate():
	pass
	
	
func kill(sound = true):
	match Animator.to_play_anim:
		"Spawn", "Active":
			Animator.play("Kill")
			if sound: killsound()
		"[u]Spawn", "[u]Active":
			Animator.play("[u]Kill")
			if sound: killsound()

func killsound():
	Entity.play_audio("water11", {"bus": "LowPass", "vol" : -5})

func collision(_landed := false, _orig_vel_x := 0, _orig_vel_y := 0): # collided with a platform
	kill()
	
func expire():
	kill(false)
	
func landed_a_hit(_hit_data):
	Entity.life_point -= 1
	if Entity.life_point <= 0:
		kill(false)
		Entity.hitstop = 0
		
func on_offstage():
	Entity.free = true
	
func _on_SpritePlayer_anim_finished(anim_name):
	match anim_name:
		"Spawn":
			Animator.play("Active")
		"[u]Spawn":
			Animator.play("[u]Active")

			
func _on_SpritePlayer_anim_started(anim_name):
	if anim_name.ends_with("Kill"):
		Entity.velocity.set_vector(0, 0)


