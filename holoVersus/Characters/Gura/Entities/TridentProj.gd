extends Node2D

const ID = "trident" # for master to find it

#const START_SPEED = 500
#const START_ROTATION = -14 # integer degrees, negative for upward
#const LIFESPAN = null

const TRAITS = []
# example: Em.entity_trait.GROUNDED

# cleaner code
onready var Entity = get_parent()
var Animator
var sprite


const MOVE_DATABASE = {
	"[c1]Active" : {
		Em.move.ROOT : "TridentProj",
		Em.move.ATK_TYPE : Em.atk_type.ENTITY,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 70,
		Em.move.KB : 400 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 3,
		Em.move.KB_ANGLE : -45,
		Em.move.PROJ_LVL : 1,
		Em.move.ATK_ATTR : [],
		Em.move.HIT_SOUND : { ref = "cut2", aux_data = {"vol" : -16} },
	},
	"[c2]Active" : {
		Em.move.ROOT : "TridentProj",
		Em.move.ATK_TYPE : Em.atk_type.ENTITY,
		Em.move.HITCOUNT : 2,
		Em.move.DMG : 55,
		Em.move.KB : 450 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 3,
		Em.move.KB_ANGLE : -45,
		Em.move.PROJ_LVL : 2,
		Em.move.ATK_ATTR : [Em.atk_attr.DRAG_KB],
		Em.move.HIT_SOUND : { ref = "cut2", aux_data = {"vol" : -16} },
	},
	"[c3]Active" : {
		Em.move.ROOT : "TridentProj",
		Em.move.ATK_TYPE : Em.atk_type.ENTITY,
		Em.move.HITCOUNT : 3,
		Em.move.DMG : 55,
		Em.move.KB : 500 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 4,
		Em.move.KB_ANGLE : -45,
		Em.move.PROJ_LVL : 3,
		Em.move.ATK_ATTR : [Em.atk_attr.DRAG_KB],
		Em.move.HIT_SOUND : { ref = "cut2", aux_data = {"vol" : -16} },
	},
	"[ex]Active" : {
		Em.move.ROOT : "TridentProjEX",
		Em.move.ATK_TYPE : Em.atk_type.EX_ENTITY,
		Em.move.HITCOUNT : 3,
		Em.move.DMG : 50,
		Em.move.KB : 500 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.FIXED,
		Em.move.ATK_LVL : 4,
		Em.move.KB_ANGLE : -45,
		Em.move.PROJ_LVL : 3,
		Em.move.ATK_ATTR : [Em.atk_attr.DRAG_KB],
		Em.move.HIT_SOUND : { ref = "cut2", aux_data = {"vol" : -16} },
	},
}

func _ready():
	get_node("TestSprite").free() # test sprite is for sizing collision box

func init(aux_data: Dictionary):
	
	# set up starting data
	Entity.unique_data = {"new_facing" : null, "new_v_facing" : null, "reset_rot" : null}
	var rot: int
	
	 # starting animation
	if !"alt_aim" in aux_data:
		rot = -14
		match aux_data.charge_lvl:
			1:
				Animator.play("[c1]Spawn")
			2:
				Animator.play("[c2]Spawn")
			3:
				Animator.play("[c3]Spawn")
			4:
				Animator.play("[ex]Spawn")
	else:
		rot = -68
		match aux_data.charge_lvl:
			1:
				Animator.play("[u][c1]Spawn")
			2:
				Animator.play("[u][c2]Spawn")
			3:
				Animator.play("[u][c3]Spawn")
			4:
				Animator.play("[u][ex]Spawn")	
				
	if "aerial" in aux_data:
		rot = -rot
		Entity.v_face(-1)
				
	match Animator.to_play_anim:
		"[c1]Spawn", "[u][c1]Spawn":
			Entity.velocity.set_vector(500 * FMath.S, 0)
			Entity.velocity.rotate(rot)
			Entity.velocity.x *= Entity.facing
			Entity.absorption_value = 1
			Entity.life_point = 1
		"[c2]Spawn", "[u][c2]Spawn":
			Entity.velocity.set_vector(600 * FMath.S, 0)
			Entity.velocity.rotate(rot)
			Entity.velocity.x *= Entity.facing
			Entity.absorption_value = 2
			Entity.life_point = 2
			Globals.Game.spawn_SFX("TridentRing", "TridentRing", Entity.position, \
					{"facing":Entity.facing, "rot":deg2rad(rot)}, Entity.palette_ref, Entity.master_ref)
		"[c3]Spawn", "[u][c3]Spawn":
			Entity.velocity.set_vector(700 * FMath.S, 0)
			Entity.velocity.rotate(rot)
			Entity.velocity.x *= Entity.facing
			Entity.absorption_value = 3
			Entity.life_point = 4
			Globals.Game.spawn_SFX("WaterJet", "WaterJet", Entity.position, \
					{"facing":Entity.facing, "rot":deg2rad(rot)}, Entity.palette_ref, Entity.master_ref)
		"[ex]Spawn", "[u][ex]Spawn":
			Entity.velocity.set_vector(700 * FMath.S, 0)
			Entity.velocity.rotate(rot)
			Entity.velocity.x *= Entity.facing
			Entity.absorption_value = 3
			Entity.life_point = 3
			Globals.Game.spawn_SFX("WaterJet", "WaterJet", Entity.position, \
					{"facing":Entity.facing, "rot":deg2rad(rot)}, Entity.palette_ref, Entity.master_ref)
#
#		"[u][c1]Spawn":
#			Entity.velocity.set_vector(500 * FMath.S, 0)
#			Entity.velocity.rotate(-rot)
#			Entity.velocity.x *= Entity.facing
#			Entity.absorption_value = 1
#			Entity.life_point = 1
#		"[u][c2]Spawn":
#			Entity.velocity.set_vector(600 * FMath.S, 0)
#			Entity.velocity.rotate(-START_ROTATION)
#			Entity.velocity.x *= Entity.facing
#			Entity.absorption_value = 2
#			Entity.life_point = 2
#			Globals.Game.spawn_SFX("TridentRing", [Entity.master_path, "TridentRing"], Entity.position, \
#					{"facing":Entity.facing, "rot":-deg2rad(START_ROTATION), "palette" : Entity.master_path})
#		"[u][c3]Spawn", "[u][ex]Spawn":
#			Entity.velocity.set_vector(700 * FMath.S, 0)
#			Entity.velocity.rotate(-START_ROTATION)
#			Entity.velocity.x *= Entity.facing
#			Entity.absorption_value = 3
#			Entity.life_point = 3
#			Globals.Game.spawn_SFX("WaterJet", [Entity.master_path, "WaterJet"], Entity.position, \
#					{"facing":Entity.facing, "rot":-deg2rad(START_ROTATION)})

#	Entity.lifespan = LIFESPAN # set starting lifespan
#	Entity.absorption_value = ABSORPTION # set starting absorption_value

#func query_move_data_and_name():
#
#	var move_ref = Animator.to_play_anim
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
#		return {Em.hit.MOVE_DATA : MOVE_DATABASE[move_ref], Em.hit.MOVE_NAME : move_ref}

func spin():
	match Animator.to_play_anim:
		"[c2]Active", "[u][c2]Active", "[c2]TurnE", "[c2]TurnS", "[c2]TurnSE", "[c2]TurnSSE", "[c2]TurnESE":
			Animator.play("[c1]Spin")
		"[c3]Active", "[u][c3]Active", "[ex]Active", "[u][ex]Active":
			Animator.play("[c2]Spin")

func turn_to_enemy():
	
	Entity.hitcount_record = []
	
	var master_node = Globals.Game.get_player_node(Entity.master_ID)
	var enemy_node = master_node.get_target()
	if enemy_node == null:
		enemy_node = master_node
	
	var angle_finder := FVector.new()
	angle_finder.set_from_vec(enemy_node.position - Entity.position)
	var angle = angle_finder.angle()
	var segment = Globals.split_angle(angle, Em.angle_split.SIXTEEN)
	
	var new_facing := 1
	var new_v_facing := 1
	
	var charge_level: String = "1"
	if Animator.current_anim == "[c2]Spin":
		charge_level = "2"
		Entity.life_point = 2
		Entity.absorption_value = 2
		Entity.velocity.set_vector(600 * FMath.S, 0)
	else:
		Entity.life_point = 1
		Entity.absorption_value = 1
		Entity.velocity.set_vector(500 * FMath.S, 0)
	
	match segment:
		Em.compass.E:
			Animator.play("[c"+ charge_level + "]TurnE")
		Em.compass.ESE:
			Animator.play("[c"+ charge_level + "]TurnESE")
		Em.compass.SE:
			Animator.play("[c"+ charge_level + "]TurnSE")
		Em.compass.SSE:
			Animator.play("[c"+ charge_level + "]TurnSSE")
			
		Em.compass.S:
			Animator.play("[c"+ charge_level + "]TurnS")
		Em.compass.SSW:
			Animator.play("[c"+ charge_level + "]TurnSSE")
			new_facing = -1
		Em.compass.SW:
			Animator.play("[c"+ charge_level + "]TurnSE")
			new_facing = -1
		Em.compass.WSW:
			Animator.play("[c"+ charge_level + "]TurnESE")
			new_facing = -1
			
		Em.compass.W:
			Animator.play("[c"+ charge_level + "]TurnE")
			new_facing = -1
		Em.compass.WNW:
			Animator.play("[c"+ charge_level + "]TurnESE")
			new_facing = -1
			new_v_facing = -1
		Em.compass.NW:
			Animator.play("[c"+ charge_level + "]TurnSE")
			new_facing = -1
			new_v_facing = -1
		Em.compass.NNW:
			Animator.play("[c"+ charge_level + "]TurnSSE")
			new_facing = -1
			new_v_facing = -1
			
		Em.compass.N:
			Animator.play("[c"+ charge_level + "]TurnS")
			new_v_facing = -1
		Em.compass.NNE:
			Animator.play("[c"+ charge_level + "]TurnSSE")
			new_v_facing = -1
		Em.compass.NE:
			Animator.play("[c"+ charge_level + "]TurnSE")
			new_v_facing = -1
		Em.compass.ENE:
			Animator.play("[c"+ charge_level + "]TurnESE")
			new_v_facing = -1
			
	Entity.velocity.rotate(Globals.compass_to_angle(segment))
	Entity.unique_data.new_facing = new_facing
	Entity.unique_data.new_v_facing = new_v_facing
	Entity.unique_data.reset_rot = true
	Entity.lifetime = 0
	Entity.play_audio("whoosh12", {"bus":"PitchDown"})
	

func refine_move_name(move_name):
		
	match move_name:
		"[c1]Spawn", "[u][c1]Spawn", "[u][c1]Active", "[c1]TurnE", "[c1]TurnS", "[c1]TurnSE", "[c1]TurnSSE", "[c1]TurnESE":
			return "[c1]Active"
		"[c2]Spawn", "[u][c2]Spawn", "[u][c2]Active", "[c2]TurnE", "[c2]TurnS", "[c2]TurnSE", "[c2]TurnSSE", "[c2]TurnESE":
			return "[c2]Active"
		"[c3]Spawn", "[u][c3]Spawn", "[u][c3]Active":
			return "[c3]Active"
		"[ex]Spawn", "[u][ex]Spawn", "[u][ex]Active":
			return "[ex]Active"
	return move_name

func query_move_data(move_name) -> Dictionary:
	
	var orig_move_name = move_name
	move_name = refine_move_name(move_name)
	
	if !move_name in MOVE_DATABASE:
		print("Error: Cannot retrieve move_data for " + move_name + " in " + filename)
		return {}
	
	var move_data = MOVE_DATABASE[move_name].duplicate(true)
#	move_data[Em.move.ATK_ATTR] = query_atk_attr(move_name)
	
#	if orig_move_name.begins_with("a"):
#		move_data[Em.move.KB_ANGLE] = -25
#	else:
	match orig_move_name:
		"[c1]TurnE", "[c2]TurnE":
			move_data[Em.move.KB_ANGLE] = -31
		"[c1]TurnS", "[c2]TurnS":
			if Entity.v_facing == 1:
				move_data[Em.move.KB_ANGLE] = 90
			else:
				move_data[Em.move.KB_ANGLE] = -90
		"[c1]TurnSE", "[c2]TurnSE":
			if Entity.v_facing == 1:
				move_data[Em.move.KB_ANGLE] = 0
			else:
				move_data[Em.move.KB_ANGLE] = -76
		"[c1]TurnSSE", "[c2]TurnSSE":
			if Entity.v_facing == 1:
				move_data[Em.move.KB_ANGLE] = 31
			else:
				move_data[Em.move.KB_ANGLE] = -83
		"[c1]TurnESE", "[c2]TurnESE":
			if Entity.v_facing == 1:
				move_data[Em.move.KB_ANGLE] = -25
			else:
				move_data[Em.move.KB_ANGLE] = -55
		_:
			if orig_move_name.begins_with("[u]"):
				if Entity.v_facing == 1:
					move_data[Em.move.KB_ANGLE] = -83
				else:
					move_data[Em.move.KB_ANGLE] = 31
			else:
				if Entity.v_facing == -1:
					move_data[Em.move.KB_ANGLE] = -25
	
	if Globals.survival_level != null:
		if Em.move.DMG in move_data:
	#		move_data[Em.move.DMG] = FMath.percent(move_data[Em.move.DMG], 60)	
			move_data[Em.move.DMG] = FMath.percent(move_data[Em.move.DMG], Inventory.modifier(Entity.master_ID, Cards.effect_ref.PROJ_DMG_MOD))
		if move_name == "[c3]Active":
			move_data[Em.move.PROJ_LVL] = 2
	
	return move_data
	

func query_atk_attr(move_name):
	
#	var orig_move_name = move_name
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
	
	if Entity.unique_data.new_facing != null: # turn here
		Entity.face(Entity.unique_data.new_facing)
		Entity.unique_data.new_facing = null
	if Entity.unique_data.new_v_facing != null:
		Entity.v_face(Entity.unique_data.new_v_facing)
		Entity.unique_data.new_v_facing = null
	if Entity.unique_data.reset_rot != null:
		Entity.get_node("Sprite").rotation = 0
		Entity.unique_data.reset_rot = null
	
	match Animator.to_play_anim: # afterimage trail
		
		"[c1]Spin", "[c2]Spin":
			Entity.velocity.percent(80)
			Entity.get_node("Sprite").rotation += 9*PI * Globals.FRAME * Entity.facing
#			if posmod(Entity.lifetime, 2) == 0:
#				Globals.Game.spawn_afterimage(Entity.entity_ID, true, Entity.entity_ref, sprite.get_path(), Entity.master_ref, Entity.palette_ref, \
#						Color(1.5, 1.5, 1.5), 0.5, 10.0)
		
		"[c2]Active", "[u][c2]Active", "[c2]TurnE", "[c2]TurnS", "[c2]TurnSE", "[c2]TurnSSE", "[c2]TurnESE":
			if posmod(Entity.lifetime, 3) == 0:
				Globals.Game.spawn_afterimage(Entity.entity_ID, Em.afterimage_type.ENTITY, Entity.entity_ref, sprite.get_path(), \
						Entity.palette_ref, Entity.master_ref, Color(1.5, 1.5, 1.5), 0.5, 10.0)
#				spawn_afterimage(master_path, spritesheet_ref, sprite_node_path, in_position, color_modulate = null, starting_modulate_a = 0.5, lifetime = 10.0)
			if !Animator.to_play_anim in ["[c2]Active", "[u][c2]Active"]:
				if Entity.lifetime > 25 and Entity.hitcount_record.size() == 0:
					Animator.play("[c1]Spin")
		
				
		"[c3]Active", "[ex]Active":
			if posmod(Entity.lifetime, 2) == 0:
				Globals.Game.spawn_afterimage(Entity.entity_ID, Em.afterimage_type.ENTITY, Entity.entity_ref, sprite.get_path(), \
						Entity.palette_ref,Entity.master_ref,  Color(1.5, 1.5, 1.5), 0.5, 10.0)
			if posmod(Entity.lifetime, 6) == 0:
				Globals.Game.spawn_SFX("TridentRing", "TridentRing", Entity.position, \
						{"facing":Entity.facing, "rot": Entity.v_facing * deg2rad(-14)}, Entity.palette_ref, Entity.master_ref)
						
		"[u][c3]Active", "[u][ex]Active":
			if posmod(Entity.lifetime, 2) == 0:
				Globals.Game.spawn_afterimage(Entity.entity_ID, Em.afterimage_type.ENTITY, Entity.entity_ref, sprite.get_path(), \
						Entity.palette_ref, Entity.master_ref, Color(1.5, 1.5, 1.5), 0.5, 10.0)
			if posmod(Entity.lifetime, 6) == 0:
				Globals.Game.spawn_SFX("TridentRing", "TridentRing", Entity.position, \
						{"facing":Entity.facing, "rot": Entity.v_facing * deg2rad(-68)}, Entity.palette_ref, Entity.master_ref)
	
	
func kill(sound = true):
	match Animator.to_play_anim:
		"[c1]Spawn", "[c2]Spawn", "[c3]Spawn", "[ex]Spawn", "[c1]Active", "[c2]Active", "[c3]Active", "[ex]Active":
			Animator.play("Kill")
			if sound: killsound() # don't put this outside, Spin animation has no kill()
		"[u][c1]Spawn", "[u][c2]Spawn", "[u][c3]Spawn", "[u][ex]Spawn", "[u][c1]Active", "[u][c2]Active", "[u][c3]Active", "[u][ex]Active":
			Animator.play("[u]Kill")
			if sound: killsound()
		"[c1]TurnE", "[c2]TurnE":
			Animator.play("EKill")
			if sound: killsound()
		"[c1]TurnS", "[c2]TurnS":
			Animator.play("SKill")
			if sound: killsound()
		"[c1]TurnSE", "[c2]TurnSE":
			Animator.play("SEKill")
			if sound: killsound()
		"[c1]TurnSSE", "[c2]TurnSSE":
			Animator.play("SSEKill")
			if sound: killsound()
		"[c1]TurnESE", "[c2]TurnESE":
			Animator.play("ESEKill")
			if sound: killsound()

func killsound():
	Entity.play_audio("break2", {"vol" : -15})
	
	
func collision(_landed := false, _orig_vel_x := 0, _orig_vel_y := 0): # collided with a platform
	
	match Animator.to_play_anim:
		"[c2]TurnE", "[c2]TurnS", "[c2]TurnSE", "[c2]TurnSSE", "[c2]TurnESE":
			if Entity.hitcount_record.size() == 0:
				Animator.play("[c1]Spin")
				return
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
		"[u][c1]Spawn":
			Animator.play("[u][c1]Active")
		"[u][c2]Spawn":
			Animator.play("[u][c2]Active")
		"[u][c3]Spawn":
			Animator.play("[u][c3]Active")
		"[u][ex]Spawn":
			Animator.play("[u][ex]Active")
		"[c1]Spin", "[c2]Spin":
			turn_to_enemy()
			
func _on_SpritePlayer_anim_started(anim_name):
	if anim_name.ends_with("Kill"):
		Entity.velocity.set_vector(0, 0)
		
	else:
		match anim_name:
			"[c1]Spin", "[c2]Spin":
				if Entity.v_facing == -1:
					Entity.v_face(1)

