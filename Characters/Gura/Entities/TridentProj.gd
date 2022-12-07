extends Node2D

const START_SPEED = 100
const START_ROTATION = -0.245 # radians, negative for upward
const PALETTE = null # setting this to null make it use its master's palette, not having PALETTE make it use default colors
#const LIFESPAN = null

const TRAITS = []
# example: Globals.entity_trait.GROUNDED

# cleaner code
onready var Entity = get_parent()
var Animator
var sprite


const MOVE_DATABASE = {
	"Active" : {
		"move_name" : "TridentProj",
		"atk_type" : Globals.atk_type.ENTITY,
		"hitcount" : 1,
		"damage" : 70,
		"knockback" : 400,
		"knockback_type": Globals.knockback_type.FIXED,
		"attack_level" : 4,
		"guard_drain": 1500,
		"guard_gain_on_combo" : 2500,
		"EX_gain": 2000,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : -PI/4,
		"hit_sound" : { ref = "cut2", aux_data = {"vol" : -17} },
	},
	"[h]Active" : {
		"move_name" : "TridentProj",
		"atk_type" : Globals.atk_type.ENTITY,
		"hitcount" : 2,
		"damage" : 45,
		"knockback" : 450,
		"knockback_type": Globals.knockback_type.FIXED,
		"attack_level" : 5,
		"guard_drain": 1750,
		"guard_gain_on_combo" : 2500,
		"EX_gain": 2250,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : -PI/4,
		"hit_sound" : { ref = "cut2", aux_data = {"vol" : -15} },
	},
	"[h2]Active" : {
		"move_name" : "TridentProj",
		"atk_type" : Globals.atk_type.ENTITY,
		"hitcount" : 3,
		"damage" : 40,
		"knockback" : 500,
		"knockback_type": Globals.knockback_type.FIXED,
		"attack_level" : 6,
		"guard_drain": 2000,
		"guard_gain_on_combo" : 2500,
		"EX_gain": 2500,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : -PI/4,
		"hit_sound" : { ref = "cut2", aux_data = {"vol" : -13} },
	},
	"aActive" : {
		"move_name" : "TridentProj2", # upwards and downwards trident can be done once each before incurring repeat penalty
		"atk_type" : Globals.atk_type.ENTITY,
		"hitcount" : 1,
		"damage" : 70,
		"knockback" : 400,
		"knockback_type": Globals.knockback_type.FIXED,
		"attack_level" : 4,
		"guard_drain": 0,
		"guard_gain_on_combo" : 0,
		"EX_gain": 0,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : -0.295,
		"hit_sound" : { ref = "cut2", aux_data = {"vol" : -17} },
	},
	"a[h]Active" : {
		"move_name" : "TridentProj2",
		"atk_type" : Globals.atk_type.ENTITY,
		"hitcount" : 2,
		"damage" : 45,
		"knockback" : 450,
		"knockback_type": Globals.knockback_type.FIXED,
		"attack_level" : 5,
		"guard_drain": 0,
		"guard_gain_on_combo" : 0,
		"EX_gain": 0,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : -0.295,
		"hit_sound" : { ref = "cut2", aux_data = {"vol" : -15} },
	},
	"a[h2]Active" : {
		"move_name" : "TridentProj2",
		"atk_type" : Globals.atk_type.ENTITY,
		"hitcount" : 3,
		"damage" : 40,
		"knockback" : 500,
		"knockback_type": Globals.knockback_type.FIXED,
		"attack_level" : 6,
		"guard_drain": 0,
		"guard_gain_on_combo" : 0,
		"EX_gain": 0,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : -0.295,
		"hit_sound" : { ref = "cut2", aux_data = {"vol" : -13} },
	}
}

func init(aux_data: Dictionary):
	
	# set up starting data
	
	 # starting animation
	if "aerial" in aux_data:
		match aux_data.charge_lvl:
			1:
				sprite.play("aSpawn")
			2:
				sprite.play("a[h]Spawn")
			3:
				sprite.play("a[h2]Spawn")
	else:
		match aux_data.charge_lvl:
			1:
				sprite.play("Spawn")
			2:
				sprite.play("[h]Spawn")
			3:
				sprite.play("[h2]Spawn")

#	Entity.lifespan = LIFESPAN # set starting lifespan
#	Entity.absorption_value = ABSORPTION # set starting absorption_value

func query_move_data():
	
	var move_ref = Animator.current_animation
	
	match move_ref:
		"Spawn":
			move_ref = "Active"
		"[h]Spawn":
			move_ref = "[h]Active"
		"[h2]Spawn":
			move_ref = "[h2]Active"
		"aSpawn":
			move_ref = "aActive"
		"a[h]SSpawn":
			move_ref = "a[h]Active"
		"a[h2]Spawn":
			move_ref = "a[h2]Active"
	
	if move_ref in MOVE_DATABASE:
		return MOVE_DATABASE[move_ref]
			
			
func stimulate():
	pass
	
	
func kill():
	match Animator.current_animation:
		"Active", "[h]Active", "[h2]Active":
			Animator.play("Kill")
		"aActive", "a[h]Active", "a[h2]Active":
			Animator.play("aKill")
	
	
func collision(): # collided with a platform
	kill()
	
#func ledge_drop():

#func check_fallthrough():

	
func landed_a_hit(_hit_data):
	Entity.life_point -= 1
	if Entity.life_point <= 0:
		kill()
		
	
func _on_SpritePlayer_anim_finished(anim_name):
	match anim_name:
		"Spawn":
			Animator.play("Active")
		"[h]Spawn":
			Animator.play("[h]Active")
		"[h2]Spawn":
			Animator.play("[h2]Active")
		"aSpawn":
			Animator.play("aActive")
		"a[h]Spawn":
			Animator.play("a[h]Active")
		"a[h2]Spawn":
			Animator.play("a[h2]Active")
			
func _on_SpritePlayer_anim_started(anim_name):
	match anim_name:
		"Spawn":
			Entity.velocity = Vector2(START_SPEED, 0).rotated(START_ROTATION)
			Entity.absorption_value = 1
			Entity.life_point = 1
		"[h]Spawn":
			Entity.velocity = Vector2(START_SPEED * 1.25, 0).rotated(START_ROTATION)
			Entity.absorption_value = 2
			Entity.life_point = 2
		"[h2]Spawn":
			Entity.velocity = Vector2(START_SPEED * 1.5, 0).rotated(START_ROTATION)
			Entity.absorption_value = 3
			Entity.life_point = 3
		"aSpawn":
			Entity.velocity = Vector2(START_SPEED, 0).rotated(-START_ROTATION)
			Entity.absorption_value = 1
			Entity.life_point = 1
		"a[h]Spawn":
			Entity.velocity = Vector2(START_SPEED * 1.25, 0).rotated(-START_ROTATION)
			Entity.absorption_value = 2
			Entity.life_point = 2
		"a[h2]Spawn":
			Entity.velocity = Vector2(START_SPEED * 1.5, 0).rotated(-START_ROTATION)
			Entity.absorption_value = 3
			Entity.life_point = 3
		"Kill", "bKill":
			Entity.velocity = Vector2.ZERO

