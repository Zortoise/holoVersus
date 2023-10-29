extends Node2D

const ID = "tako" # for master to find it
const TRAITS = []

const BLACK_REPLACER = 0.8 # for black_replace shader

# cleaner code
onready var Entity = get_parent()
var Animator
var sprite


const MOVE_DATABASE = {
	"Active2" : {
		Em.move.ROOT : "Tako",
		Em.move.ATK_TYPE : Em.atk_type.ENTITY,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 40,
		Em.move.KB : 300 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.VELOCITY,
		Em.move.ATK_LVL : 2,
		Em.move.FIXED_HITSTOP : 8,
		Em.move.KB_ANGLE : 0,
		Em.move.HITSPARK_TYPE : Em.hitspark_type.HIT,
		Em.move.HITSPARK_PALETTE : "dark_purple",
		Em.move.PROJ_LVL : 1,
		Em.move.ATK_ATTR : [Em.atk_attr.CAN_REPEAT_ONCE],
		Em.move.HIT_SOUND : { ref = "impact39", aux_data = {"vol" : -15} },
	},
}

func _ready():
	get_node("TestSprite").free() # test sprite is for sizing collision box

func init(aux_data: Dictionary):
	
	load_entity() # black_replace
	
	Animator.play("Active2")
	Entity.velocity.set_vector(100 * FMath.S, 0)
	Entity.velocity.rotate(aux_data.angle)

	Entity.absorption_value = 1
	Entity.life_point = 1
	
	
func load_entity():
	var replace = null
	match Entity.master_ID:
		0:
			replace = Color(BLACK_REPLACER, 0.0, 0.0)
		1:
			replace = Color(0.0, 0.0, BLACK_REPLACER)

	if replace != null:
		sprite.material = ShaderMaterial.new()
		sprite.material.shader = Loader.black_replace_shader
		sprite.material.set_shader_param("replace_r", replace.r)
		sprite.material.set_shader_param("replace_g", replace.g)
		sprite.material.set_shader_param("replace_b", replace.b)
	
		
func refine_move_name(move_name):
		
	match move_name:
		_:
			pass
			
	return move_name
	
		
func query_move_data(move_name) -> Dictionary:
	
	move_name = refine_move_name(move_name)
	
	if !move_name in MOVE_DATABASE:
		print("Error: Cannot retrieve move_data for " + move_name + " in " + filename)
		return {}
	
	var move_data = MOVE_DATABASE[move_name].duplicate(true)
	move_data[Em.move.ATK_ATTR] = query_atk_attr(move_name)
	
	
	if Globals.survival_level != null:
		if Em.move.DMG in move_data:
			move_data[Em.move.DMG] = FMath.percent(move_data[Em.move.DMG], Inventory.modifier(Entity.master_ID, Cards.effect_ref.ASSIST_DMG_MOD))
	
	return move_data
		
		
func query_atk_attr(move_name):
	
#	var orig_move_name = move_name
	move_name = refine_move_name(move_name)

	var atk_attr := []
	if move_name in MOVE_DATABASE and Em.move.ATK_ATTR in MOVE_DATABASE[move_name]:
		atk_attr = MOVE_DATABASE[move_name][Em.move.ATK_ATTR].duplicate(true)
		
	atk_attr.append(Em.atk_attr.ASSIST) # add "Assist" to move name when added to Repeat Memory
	
	return atk_attr
	
	
func get_proj_level(move_name):
	move_name = refine_move_name(move_name)

	if move_name in MOVE_DATABASE and Em.move.PROJ_LVL in MOVE_DATABASE[move_name]:
		return MOVE_DATABASE[move_name][Em.move.PROJ_LVL]
	
	return 1
			
			
func simulate():
	pass

	
func kill(sound = true):
	if Animator.to_play_anim != "Kill":
		Animator.play("Kill")
		if sound: Entity.play_audio("impact25", {"vol" : -12})
	
func expire():
	Entity.free = true
	Globals.Game.spawn_SFX("TakoFlash", "TakoFlash", Entity.position, {"facing":Entity.facing}, Entity.palette_ref, Entity.master_ref)

func collision(landed := false, _orig_vel_x := 0, orig_vel_y := 0): # collided with a platform
	if Animator.to_play_anim != "Kill":
		if landed:
			Entity.velocity.y = -orig_vel_y
		else:
			kill()

func landed_a_hit(hit_data):
	kill(false)
	
	fever(hit_data)

func fever(hit_data):
	if Globals.survival_level == null and Globals.assists == 1:
		if hit_data[Em.hit.BLOCK_STATE] == Em.block_state.UNBLOCKED and "assist_fever" in hit_data[Em.hit.ATKER]:
			if !"assist_rescue_protect" in hit_data[Em.hit.DEFENDER]:
				return
			if !hit_data[Em.hit.DEFENDER].assist_rescue_protect:
				hit_data[Em.hit.ATKER].assist_fever = true
		
func on_offstage():
	Entity.free = true
	
func _on_SpritePlayer_anim_finished(anim_name):
	match anim_name:
		_:
			pass
			
func _on_SpritePlayer_anim_started(anim_name):
	match anim_name:
		"Kill":
			Entity.velocity.set_vector(0, 0)

