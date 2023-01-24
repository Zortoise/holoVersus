extends Node2D

const ID = "trident" # for master to find it

#const START_SPEED = 500
const START_ROTATION = -14 # integer degrees, negative for upward
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
		"root" : "TridentProj",
		"atk_type" : Globals.atk_type.ENTITY,
		"hitcount" : 1,
		"damage" : 70,
		"knockback" : 400 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED,
		"atk_level" : 4,
		"guard_drain": 1000,
		"guard_gain_on_combo" : 2500,
		"EX_gain": 2000,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : -45,
		"atk_attr" : [],
		"hit_sound" : { ref = "cut2", aux_data = {"vol" : -16} },
	},
	"[c2]Active" : {
		"root" : "TridentProj",
		"atk_type" : Globals.atk_type.ENTITY,
		"hitcount" : 2,
		"damage" : 55,
		"knockback" : 450 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED,
		"atk_level" : 4,
		"guard_drain": 1250,
		"guard_gain_on_combo" : 2500,
		"EX_gain": 1250,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : -45,
		"atk_attr" : [Globals.atk_attr.DRAG_KB],
		"hit_sound" : { ref = "cut2", aux_data = {"vol" : -16} },
	},
	"[c3]Active" : {
		"root" : "TridentProj",
		"atk_type" : Globals.atk_type.ENTITY,
		"hitcount" : 3,
		"damage" : 55,
		"knockback" : 500 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED,
		"atk_level" : 4,
		"guard_drain": 1500,
		"guard_gain_on_combo" : 2500,
		"EX_gain": 1000,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : -45,
		"atk_attr" : [Globals.atk_attr.ANTI_GUARD, Globals.atk_attr.DRAG_KB, Globals.atk_attr.INDESTRUCTIBLE_ENTITY],
		"hit_sound" : { ref = "cut2", aux_data = {"vol" : -16} },
	},
	"[ex]Active" : {
		"root" : "TridentProjEX",
		"atk_type" : Globals.atk_type.EX,
		"hitcount" : 2,
		"damage" : 70,
		"knockback" : 500 * FMath.S,
		"knockback_type": Globals.knockback_type.FIXED,
		"atk_level" : 4,
		"guard_drain": 1500,
		"guard_gain_on_combo" : 2500,
		"EX_gain": 0,
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "blue",
		"KB_angle" : -45,
		"atk_attr" : [Globals.atk_attr.DRAG_KB, Globals.atk_attr.INDESTRUCTIBLE_ENTITY],
		"hit_sound" : { ref = "cut2", aux_data = {"vol" : -16} },
	},
}

func _ready():
	get_node("TestSprite").hide() # test sprite is for sizing collision box

func init(aux_data: Dictionary):
	
	# set up starting data
	Entity.unique_data = {"new_facing" : null, "new_v_facing" : null, "reset_rot" : null}
	
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
				
	match Animator.to_play_animation:
		"[c1]Spawn":
			Entity.velocity.set_vector(500 * FMath.S, 0)
			Entity.velocity.rotate(START_ROTATION)
			Entity.velocity.x *= Entity.facing
			Entity.absorption_value = 1
			Entity.life_point = 1
		"[c2]Spawn":
			Entity.velocity.set_vector(600 * FMath.S, 0)
			Entity.velocity.rotate(START_ROTATION)
			Entity.velocity.x *= Entity.facing
			Entity.absorption_value = 2
			Entity.life_point = 2
			Globals.Game.spawn_SFX("TridentRing", [Entity.master_path, "TridentRing"], Entity.position, \
					{"facing":Entity.facing, "rot":deg2rad(START_ROTATION), "palette" : Entity.master_path})
		"[c3]Spawn", "[ex]Spawn":
			Entity.velocity.set_vector(700 * FMath.S, 0)
			Entity.velocity.rotate(START_ROTATION)
			Entity.velocity.x *= Entity.facing
			Entity.absorption_value = 3
			Entity.life_point = 3
			Globals.Game.spawn_SFX("WaterJet", [Entity.master_path, "WaterJet"], Entity.position, \
					{"facing":Entity.facing, "rot":deg2rad(START_ROTATION)})
		"a[c1]Spawn":
			Entity.velocity.set_vector(500 * FMath.S, 0)
			Entity.velocity.rotate(-START_ROTATION)
			Entity.velocity.x *= Entity.facing
			Entity.absorption_value = 1
			Entity.life_point = 1
		"a[c2]Spawn":
			Entity.velocity.set_vector(600 * FMath.S, 0)
			Entity.velocity.rotate(-START_ROTATION)
			Entity.velocity.x *= Entity.facing
			Entity.absorption_value = 2
			Entity.life_point = 2
			Globals.Game.spawn_SFX("TridentRing", [Entity.master_path, "TridentRing"], Entity.position, \
					{"facing":Entity.facing, "rot":-deg2rad(START_ROTATION), "palette" : Entity.master_path})
		"a[c3]Spawn", "a[ex]Spawn":
			Entity.velocity.set_vector(700 * FMath.S, 0)
			Entity.velocity.rotate(-START_ROTATION)
			Entity.velocity.x *= Entity.facing
			Entity.absorption_value = 3
			Entity.life_point = 3
			Globals.Game.spawn_SFX("WaterJet", [Entity.master_path, "WaterJet"], Entity.position, \
					{"facing":Entity.facing, "rot":-deg2rad(START_ROTATION)})

#	Entity.lifespan = LIFESPAN # set starting lifespan
#	Entity.absorption_value = ABSORPTION # set starting absorption_value

#func query_move_data_and_name():
#
#	var move_ref = Animator.to_play_animation
#
#	match move_name:
#		"[c1]Spawn":
#			move_name = "[c1]Active"
#		"[c2]Spawn":
#			move_name = "[c2]Active"
#		"[c3]Spawn":
#			move_name = "[c3]Active"
#		"[ex]Spawn":
#			move_name = "[ex]Active"
#		"a[c1]Spawn":
#			move_name = "a[c1]Active"
#		"a[c2]Spawn":
#			move_name = "a[c2]Active"
#		"a[c3]Spawn":
#			move_name = "a[c3]Active"
#		"a[ex]Spawn":
#			move_name = "a[ex]Active"
#
#	if move_ref in MOVE_DATABASE:
#		return {"move_data" : MOVE_DATABASE[move_ref], "move_name" : move_ref}

func spin():
	match Animator.to_play_animation:
		"[c2]Active", "a[c2]Active", "[ex]Active", "a[ex]Active", "[c2]TurnE", "[c2]TurnS", "[c2]TurnSE", "[c2]TurnSSE", "[c2]TurnESE":
			Animator.play("[c1]Spin")
		"[c3]Active", "a[c3]Active":
			Animator.play("[c2]Spin")

func turn_to_enemy():
	
	Entity.hitcount_record = []
	
	var master_node = get_node(Entity.master_path)
	var enemy_node = get_node(master_node.targeted_opponent_path)
	
	var angle_finder := FVector.new()
	angle_finder.set_from_vec(enemy_node.position - Entity.position)
	var angle = angle_finder.angle()
	var segment = Globals.split_angle(angle, Globals.angle_split.SIXTEEN)
	
	var new_facing := 1
	var new_v_facing := 1
	
	var charge_level: String = "1"
	if Animator.current_animation == "[c2]Spin":
		charge_level = "2"
		Entity.life_point = 2
		Entity.absorption_value = 2
		Entity.velocity.set_vector(600 * FMath.S, 0)
	else:
		Entity.life_point = 1
		Entity.absorption_value = 1
		Entity.velocity.set_vector(500 * FMath.S, 0)
	
	match segment:
		Globals.compass.E:
			Animator.play("[c"+ charge_level + "]TurnE")
		Globals.compass.ESE:
			Animator.play("[c"+ charge_level + "]TurnESE")
		Globals.compass.SE:
			Animator.play("[c"+ charge_level + "]TurnSE")
		Globals.compass.SSE:
			Animator.play("[c"+ charge_level + "]TurnSSE")
			
		Globals.compass.S:
			Animator.play("[c"+ charge_level + "]TurnS")
		Globals.compass.SSW:
			Animator.play("[c"+ charge_level + "]TurnSSE")
			new_facing = -1
		Globals.compass.SW:
			Animator.play("[c"+ charge_level + "]TurnSE")
			new_facing = -1
		Globals.compass.WSW:
			Animator.play("[c"+ charge_level + "]TurnESE")
			new_facing = -1
			
		Globals.compass.W:
			Animator.play("[c"+ charge_level + "]TurnE")
			new_facing = -1
		Globals.compass.WNW:
			Animator.play("[c"+ charge_level + "]TurnESE")
			new_facing = -1
			new_v_facing = -1
		Globals.compass.NW:
			Animator.play("[c"+ charge_level + "]TurnSE")
			new_facing = -1
			new_v_facing = -1
		Globals.compass.NNW:
			Animator.play("[c"+ charge_level + "]TurnSSE")
			new_facing = -1
			new_v_facing = -1
			
		Globals.compass.N:
			Animator.play("[c"+ charge_level + "]TurnS")
			new_v_facing = -1
		Globals.compass.NNE:
			Animator.play("[c"+ charge_level + "]TurnSSE")
			new_v_facing = -1
		Globals.compass.NE:
			Animator.play("[c"+ charge_level + "]TurnSE")
			new_v_facing = -1
		Globals.compass.ENE:
			Animator.play("[c"+ charge_level + "]TurnESE")
			new_v_facing = -1
			
	Entity.velocity.rotate(Globals.compass_to_angle(segment))
	Entity.unique_data.new_facing = new_facing
	Entity.unique_data.new_v_facing = new_v_facing
	Entity.unique_data.reset_rot = true
	

func refine_move_name(move_name):
	match move_name:
		"[c1]Spawn", "a[c1]Spawn", "a[c1]Active", "[c1]TurnE", "[c1]TurnS", "[c1]TurnSE", "[c1]TurnSSE", "[c1]TurnESE":
			return "[c1]Active"
		"[c2]Spawn", "a[c2]Spawn", "a[c2]Active", "[c2]TurnE", "[c2]TurnS", "[c2]TurnSE", "[c2]TurnSSE", "[c2]TurnESE":
			return "[c2]Active"
		"[c3]Spawn", "a[c3]Spawn", "a[c3]Active":
			return "[c3]Active"
		"[ex]Spawn", "a[ex]Spawn", "a[ex]Active":
			return "[ex]Active"
	return move_name

func query_move_data(move_name) -> Dictionary:
	
	var orig_move_name = move_name

	move_name = refine_move_name(move_name)
	
	if !move_name in MOVE_DATABASE:
		print("Error: Cannot retrieve move_data for " + move_name)
		return {}
	
	var move_data = MOVE_DATABASE[move_name].duplicate(true)
#	move_data["atk_attr"] = query_atk_attr(move_name, true)
	
	if orig_move_name.begins_with("a"):
		move_data.KB_angle = -25
	else:
		match orig_move_name:
			"[c1]TurnE", "[c2]TurnE":
				move_data.KB_angle = -31
			"[c1]TurnS", "[c2]TurnS":
				if Entity.v_facing == 1:
					move_data.KB_angle = 90
				else:
					move_data.KB_angle = -90
			"[c1]TurnSE", "[c2]TurnSE":
				if Entity.v_facing == 1:
					move_data.KB_angle = 0
				else:
					move_data.KB_angle = -76
			"[c1]TurnSSE", "[c2]TurnSSE":
				if Entity.v_facing == 1:
					move_data.KB_angle = 31
				else:
					move_data.KB_angle = -83
			"[c1]TurnESE", "[c2]TurnESE":
				if Entity.v_facing == 1:
					move_data.KB_angle = -25
				else:
					move_data.KB_angle = -55
	
	return move_data
	

func query_atk_attr(move_name, skip_refine := false):
	
	if !skip_refine:
		move_name = refine_move_name(move_name)

	if move_name in MOVE_DATABASE and "atk_attr" in MOVE_DATABASE[move_name]:
		return MOVE_DATABASE[move_name].atk_attr.duplicate(true)
		
#	print("Error: Cannot retrieve atk_attr for " + move_name)
	return []
	
			
func simulate():
	
	if Entity.unique_data.new_facing != null: # turn here
		Entity.face(Entity.unique_data.new_facing)
		Entity.unique_data.new_facing = null
	if Entity.unique_data.new_v_facing != null:
		Entity.v_face(Entity.unique_data.new_v_facing)
		Entity.unique_data.new_v_facing = null
	if Entity.unique_data.reset_rot != null:
		Entity.get_node("Sprite").rotation = 0
		Entity.unique_data.reset_rot = null
	
	match Animator.to_play_animation: # afterimage trail
		
		"[c1]Spin", "[c2]Spin":
			Entity.velocity.percent(85)
			Entity.get_node("Sprite").rotation += 9*PI * Globals.FRAME * Entity.facing
			if posmod(Entity.lifetime, 2) == 0:
				Globals.Game.spawn_afterimage(Entity.master_path, Entity.entity_ref, sprite.get_path(), Color(1.5, 1.5, 1.5), 0.5, 10.0)
		
		"[c2]Active", "a[c2]Active", "[c2]TurnE", "[c2]TurnS", "[c2]TurnSE", "[c2]TurnSSE", "[c2]TurnESE":
			if posmod(Entity.lifetime, 3) == 0:
				Globals.Game.spawn_afterimage(Entity.master_path, Entity.entity_ref, sprite.get_path(), Color(1.5, 1.5, 1.5), 0.5, 10.0)
#				spawn_afterimage(master_path, spritesheet_ref, sprite_node_path, in_position, color_modulate = null, starting_modulate_a = 0.5, lifetime = 10.0)
				
		"[c3]Active", "[ex]Active":
			if posmod(Entity.lifetime, 2) == 0:
				Globals.Game.spawn_afterimage(Entity.master_path, Entity.entity_ref, sprite.get_path(), Color(1.5, 1.5, 1.5), 0.5, 10.0)
			if posmod(Entity.lifetime, 6) == 0:
				Globals.Game.spawn_SFX("TridentRing", [Entity.master_path, "TridentRing"], Entity.position, \
						{"facing":Entity.facing, "rot": deg2rad(START_ROTATION), "palette" : Entity.master_path})
						
		"a[c3]Active", "a[ex]Active":
			if posmod(Entity.lifetime, 2) == 0:
				Globals.Game.spawn_afterimage(Entity.master_path, Entity.entity_ref, sprite.get_path(), Color(1.5, 1.5, 1.5), 0.5, 10.0)
			if posmod(Entity.lifetime, 6) == 0:
				Globals.Game.spawn_SFX("TridentRing", [Entity.master_path, "TridentRing"], Entity.position, \
						{"facing":Entity.facing, "rot":-deg2rad(START_ROTATION), "palette" : Entity.master_path})
	
	
func kill(sound = true):
	match Animator.to_play_animation:
		"[c1]Spawn", "[c2]Spawn", "[c3]Spawn", "[ex]Spawn", "[c1]Active", "[c2]Active", "[c3]Active", "[ex]Active":
			Animator.play("Kill")
			if sound: Entity.play_audio("break2", {"vol" : -15}) # don't put this outside, Spin animation has no kill()
		"a[c1]Spawn", "a[c2]Spawn", "a[c3]Spawn", "a[ex]Spawn", "a[c1]Active", "a[c2]Active", "a[c3]Active", "a[ex]Active":
			Animator.play("aKill")
			if sound: Entity.play_audio("break2", {"vol" : -15})
		"[c1]TurnE", "[c2]TurnE":
			Animator.play("EKill")
			if sound: Entity.play_audio("break2", {"vol" : -15})
		"[c1]TurnS", "[c2]TurnS":
			Animator.play("SKill")
			if sound: Entity.play_audio("break2", {"vol" : -15})
		"[c1]TurnSE", "[c2]TurnSE":
			Animator.play("SEKill")
			if sound: Entity.play_audio("break2", {"vol" : -15})
		"[c1]TurnSSE", "[c2]TurnSSE":
			Animator.play("SSEKill")
			if sound: Entity.play_audio("break2", {"vol" : -15})
		"[c1]TurnESE", "[c2]TurnESE":
			Animator.play("ESEKill")
			if sound: Entity.play_audio("break2", {"vol" : -15})

	
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
		"[c1]Spin", "[c2]Spin":
			turn_to_enemy()
			
func _on_SpritePlayer_anim_started(anim_name):
	if anim_name.ends_with("Kill"):
		Entity.velocity.set_vector(0, 0)

