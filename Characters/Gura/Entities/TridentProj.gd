extends Node2D

#const START_SPEED = 500
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
	"[c1]Active" : {
		"move_name" : "TridentProj",
		"atk_type" : Globals.atk_type.ENTITY,
		"hitcount" : 1,
		"damage" : 70,
		"knockback" : 400,
		"knockback_type": Globals.knockback_type.FIXED,
		"attack_level" : 2,
		"guard_drain": 1500,
		"guard_gain_on_combo" : 2500,
		"EX_gain": 2000,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : -PI/4,
		"hit_sound" : { ref = "cut2", aux_data = {"vol" : -17} },
	},
	"[c2]Active" : {
		"move_name" : "TridentProj",
		"atk_type" : Globals.atk_type.ENTITY,
		"hitcount" : 2,
		"damage" : 50,
		"knockback" : 450,
		"knockback_type": Globals.knockback_type.FIXED,
		"attack_level" : 3,
		"guard_drain": 1750,
		"guard_gain_on_combo" : 2500,
		"EX_gain": 1250,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : -PI/4,
		"hit_sound" : { ref = "cut2", aux_data = {"vol" : -16} },
	},
	"[c3]Active" : {
		"move_name" : "TridentProj",
		"atk_type" : Globals.atk_type.ENTITY,
		"hitcount" : 3,
		"damage" : 60,
		"knockback" : 500,
		"knockback_type": Globals.knockback_type.FIXED,
		"attack_level" : 4,
		"guard_drain": 2000,
		"guard_gain_on_combo" : 2500,
		"EX_gain": 1000,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : -PI/4,
		"hit_sound" : { ref = "cut2", aux_data = {"vol" : -15} },
	},
	"[ex]Active" : {
		"move_name" : "TridentProj",
		"atk_type" : Globals.atk_type.EX,
		"hitcount" : 3,
		"damage" : 60,
		"knockback" : 500,
		"knockback_type": Globals.knockback_type.FIXED,
		"attack_level" : 4,
		"guard_drain": 2000,
		"guard_gain_on_combo" : 2500,
		"EX_gain": 0,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : -PI/4,
		"hit_sound" : { ref = "cut2", aux_data = {"vol" : -15} },
	},
	"a[c1]Active" : {
		"move_name" : "TridentProj2", # upwards and downwards trident can be done once each before incurring repeat penalty
		"atk_type" : Globals.atk_type.ENTITY,
		"hitcount" : 1,
		"damage" : 70,
		"knockback" : 400,
		"knockback_type": Globals.knockback_type.FIXED,
		"attack_level" : 2,
		"guard_drain": 1500,
		"guard_gain_on_combo" : 2500,
		"EX_gain": 2000,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : -0.295,
		"hit_sound" : { ref = "cut2", aux_data = {"vol" : -17} },
	},
	"a[c2]Active" : {
		"move_name" : "TridentProj2",
		"atk_type" : Globals.atk_type.ENTITY,
		"hitcount" : 2,
		"damage" : 50,
		"knockback" : 450,
		"knockback_type": Globals.knockback_type.FIXED,
		"attack_level" : 3,
		"guard_drain": 1750,
		"guard_gain_on_combo" : 2500,
		"EX_gain": 1250,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : -0.295,
		"hit_sound" : { ref = "cut2", aux_data = {"vol" : -16} },
	},
	"a[c3]Active" : {
		"move_name" : "TridentProj2",
		"atk_type" : Globals.atk_type.ENTITY,
		"hitcount" : 3,
		"damage" : 60,
		"knockback" : 500,
		"knockback_type": Globals.knockback_type.FIXED,
		"attack_level" : 4,
		"guard_drain": 2000,
		"guard_gain_on_combo" : 2500,
		"EX_gain": 1000,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : -0.295,
		"hit_sound" : { ref = "cut2", aux_data = {"vol" : -15} },
	},
	"a[ex]Active" : {
		"move_name" : "TridentProj2",
		"atk_type" : Globals.atk_type.EX,
		"hitcount" : 3,
		"damage" : 60,
		"knockback" : 500,
		"knockback_type": Globals.knockback_type.FIXED,
		"attack_level" : 4,
		"guard_drain": 2000,
		"guard_gain_on_combo" : 2500,
		"EX_gain": 0,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : -0.295,
		"hit_sound" : { ref = "cut2", aux_data = {"vol" : -15} },
	}
}

func _ready():
	get_node("TestSprite").hide() # test sprite is for sizing collision box

func init(aux_data: Dictionary):
	
	# set up starting data
	
	 # starting animation
	if "aerial" in aux_data:
		match aux_data.charge_lvl:
			1:
				Animator.play("a[c1]Spawn")
			2:
				Animator.play("a[c2]Spawn")
			3:
				Animator.play("a[c3]Spawn")
			4:
				Animator.play("a[ex]Spawn")
	else:
		match aux_data.charge_lvl:
			1:
				Animator.play("[c1]Spawn")
			2:
				Animator.play("[c2]Spawn")
			3:
				Animator.play("[c3]Spawn")
			4:
				Animator.play("[ex]Spawn")

#	Entity.lifespan = LIFESPAN # set starting lifespan
#	Entity.absorption_value = ABSORPTION # set starting absorption_value

func query_move_data():
	
	var move_ref = Animator.current_animation
	
	match move_ref:
		"[c1]Spawn":
			move_ref = "[c1]Active"
		"[c2]Spawn":
			move_ref = "[c2]Active"
		"[c3]Spawn":
			move_ref = "[c3]Active"
		"[ex]Spawn":
			move_ref = "[ex]Active"
		"a[c1]Spawn":
			move_ref = "a[c1]Active"
		"a[c2]Spawn":
			move_ref = "a[c2]Active"
		"a[c3]Spawn":
			move_ref = "a[c3]Active"
		"a[ex]Spawn":
			move_ref = "a[ex]Active"
	
	if move_ref in MOVE_DATABASE:
		return MOVE_DATABASE[move_ref]


func query_atk_attr(in_move_name):
	if Animator.query_current(["[c3]Active", "a[c3]Active", "[c3]Spawn", "a[c3]Spawn"]):
		return [Globals.atk_attr.ANTI_GUARD, Globals.atk_attr.DRAG_KB]
	match in_move_name:
		"TridentProj", "TridentProj2":
			return [Globals.atk_attr.DRAG_KB]
			
			
func stimulate():
	match Animator.current_animation: # afterimage trail
		"[c2]Active", "a[c2]Active":
			if posmod(Entity.lifetime, 3) == 0:
				Globals.Game.spawn_afterimage(Entity.master_path, Entity.entity_ref, sprite.get_path(), null, 0.5, 10.0)
#				spawn_afterimage(master_path, spritesheet_ref, sprite_node_path, in_position, color_modulate = null, starting_modulate_a = 0.5, lifetime = 10.0)
				
		"[c3]Active", "[ex]Active":
			if posmod(Entity.lifetime, 2) == 0:
				Globals.Game.spawn_afterimage(Entity.master_path, Entity.entity_ref, sprite.get_path(), null, 0.5, 10.0)
			if posmod(Entity.lifetime, 6) == 0:
				Globals.Game.spawn_SFX("TridentRing", [Entity.master_path, "TridentRing"], Entity.position, \
						{"facing":Entity.facing, "rot":START_ROTATION, "palette" : Entity.master_path})
						
		"a[c3]Active", "a[ex]Active":
			if posmod(Entity.lifetime, 2) == 0:
				Globals.Game.spawn_afterimage(Entity.master_path, Entity.entity_ref, sprite.get_path(), null, 0.5, 10.0)
			if posmod(Entity.lifetime, 6) == 0:
				Globals.Game.spawn_SFX("TridentRing", [Entity.master_path, "TridentRing"], Entity.position, \
						{"facing":Entity.facing, "rot":-START_ROTATION, "palette" : Entity.master_path})
	
	
func kill(sound = true):
	match Animator.current_animation:
		"[c1]Spawn", "[c2]Spawn", "[c3]Spawn", "[ex]Spawn", "[c1]Active", "[c2]Active", "[c3]Active", "[ex]Active":
			Animator.play("Kill")
		"a[c1]Spawn", "a[c2]Spawn", "a[c3]Spawn", "a[ex]Spawn", "a[c1]Active", "a[c2]Active", "a[c3]Active", "a[ex]Active":
			Animator.play("aKill")
	
	if sound:
		Entity.play_audio("break2", {"vol" : -15})
	
	
func collision(): # collided with a platform
	kill()
	
#func ledge_drop():

#func check_fallthrough():

	
func landed_a_hit(_hit_data):
	Entity.life_point -= 1
	if Entity.life_point <= 0:
		kill(false)
		Entity.hitstop = 0
		
func on_offstage():
	Entity.free = true
	
func _on_SpritePlayer_anim_finished(anim_name):
	match anim_name:
		"[c1]Spawn":
			Animator.play("[c1]Active")
		"[c2]Spawn":
			Animator.play("[c2]Active")
		"[c3]Spawn":
			Animator.play("[c3]Active")
		"[ex]Spawn":
			Animator.play("[ex]Active")
		"a[c1]Spawn":
			Animator.play("a[c1]Active")
		"a[c2]Spawn":
			Animator.play("a[c2]Active")
		"a[c3]Spawn":
			Animator.play("a[c3]Active")
		"a[ex]Spawn":
			Animator.play("a[ex]Active")
			
func _on_SpritePlayer_anim_started(anim_name):
	match anim_name:
		"[c1]Spawn":
			Entity.velocity = Vector2(500, 0).rotated(START_ROTATION)
			Entity.velocity.x *= Entity.facing
			Entity.absorption_value = 1
			Entity.life_point = 1
		"[c2]Spawn":
			Entity.velocity = Vector2(650, 0).rotated(START_ROTATION)
			Entity.velocity.x *= Entity.facing
			Entity.absorption_value = 2
			Entity.life_point = 2
			Globals.Game.spawn_SFX("TridentRing", [Entity.master_path, "TridentRing"], Entity.position, \
					{"facing":Entity.facing, "rot":START_ROTATION, "palette" : Entity.master_path})
		"[c3]Spawn", "[ex]Spawn":
			Entity.velocity = Vector2(800, 0).rotated(START_ROTATION)
			Entity.velocity.x *= Entity.facing
			Entity.absorption_value = 3
			Entity.life_point = 3
			Globals.Game.spawn_SFX("WaterJet", [Entity.master_path, "WaterJet"], Entity.position, \
					{"facing":Entity.facing, "rot":START_ROTATION})
		"a[c1]Spawn":
			Entity.velocity = Vector2(500, 0).rotated(-START_ROTATION)
			Entity.velocity.x *= Entity.facing
			Entity.absorption_value = 1
			Entity.life_point = 1
		"a[c2]Spawn":
			Entity.velocity = Vector2(650, 0).rotated(-START_ROTATION)
			Entity.velocity.x *= Entity.facing
			Entity.absorption_value = 2
			Entity.life_point = 2
			Globals.Game.spawn_SFX("TridentRing", [Entity.master_path, "TridentRing"], Entity.position, \
					{"facing":Entity.facing, "rot":-START_ROTATION, "palette" : Entity.master_path})
		"a[c3]Spawn", "a[ex]Spawn":
			Entity.velocity = Vector2(800, 0).rotated(-START_ROTATION)
			Entity.velocity.x *= Entity.facing
			Entity.absorption_value = 3
			Entity.life_point = 3
			Globals.Game.spawn_SFX("WaterJet", [Entity.master_path, "WaterJet"], Entity.position, \
					{"facing":Entity.facing, "rot":-START_ROTATION})
		"Kill", "aKill":
			Entity.velocity = Vector2.ZERO

