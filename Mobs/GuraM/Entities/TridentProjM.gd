extends Node2D



const TRAITS = []

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
		"hitspark_type" : Globals.hitspark_type.HIT,
		"hitspark_palette" : "white",
		"KB_angle" : -45,
		"proj_level" : 1,
		"atk_attr" : [],
		"hit_sound" : { ref = "cut2", aux_data = {"vol" : -16} },
	},
}

func _ready():
	get_node("TestSprite").free() # test sprite is for sizing collision box

func init(aux_data: Dictionary):
	
	# set up starting data
	Entity.unique_data = {"target_ID" : null, "spun" : false, "new_facing" : null, "new_v_facing" : null, "reset_rot" : null}
	var rot: int
	
	if "target_ID" in aux_data: # for homing projectiles
		Entity.unique_data.target_ID = aux_data.target_ID
	
	 # starting animation
	if !"alt_aim" in aux_data:
		rot = -14
		Animator.play("[c1]Spawn")
	else:
		rot = -68
		Animator.play("[u][c1]Spawn")
				
	if "aerial" in aux_data:
		rot = -rot
		Entity.v_face(-1)
				
	match Animator.to_play_animation:
		"[c1]Spawn", "[u][c1]Spawn":

			var vel = 500
			if Globals.mob_attr.PROJ_SPEED in Entity.mob_attr:
				vel = Entity.modify_stat(vel, Globals.mob_attr.PROJ_SPEED, [50, 75, 125, 150])
			Entity.velocity.set_vector(vel * FMath.S, 0)
			
			Entity.velocity.rotate(rot)
			Entity.velocity.x *= Entity.facing
			Entity.absorption_value = 1
			Entity.life_point = 1
			if "2_hits_proj" in Entity.unique_data:
				Entity.absorption_value += 1
				Entity.life_point += 1
			Globals.Game.spawn_SFX("TridentRing", "TridentRing", Entity.position, \
					{"facing":Entity.facing, "rot":deg2rad(rot)}, Entity.palette_ref, Entity.creator_mob_ref)
			# if Entity.creater_mob_ref is passed in, ignores master_ID and will search for "palette" in LevelControl
			# set "palette" to Entity.palette_ref under Entity.creater_mob_ref in LevelControl instead of "master"

#func spin():
#	match Animator.to_play_animation:
#		"[c1]Active", "[u][c1]Active":
#			Animator.play("[c1]Spin")

func turn_to_enemy():
	
	Entity.hitcount_record = []
	
	var enemy_node = Globals.Game.get_player_node(Entity.unique_data.target_ID)
	
	var angle_finder := FVector.new()
	angle_finder.set_from_vec(enemy_node.position - Entity.position)
	var angle = angle_finder.angle()
	var segment = Globals.split_angle(angle, Globals.angle_split.SIXTEEN)
	
	var new_facing := 1
	var new_v_facing := 1
	
	Entity.life_point = 1
	Entity.absorption_value = 1

	var vel = 500
	if Globals.mob_attr.PROJ_SPEED in Entity.mob_attr:
		vel = Entity.modify_stat(vel, Globals.mob_attr.PROJ_SPEED, [50, 75, 125, 150])
	Entity.velocity.set_vector(vel * FMath.S, 0)
	
	match segment:
		Globals.compass.E:
			Animator.play("[c1]TurnE")
		Globals.compass.ESE:
			Animator.play("[c1]TurnESE")
		Globals.compass.SE:
			Animator.play("[c1]TurnSE")
		Globals.compass.SSE:
			Animator.play("[c1]TurnSSE")
			
		Globals.compass.S:
			Animator.play("[c1]TurnS")
		Globals.compass.SSW:
			Animator.play("[c1]TurnSSE")
			new_facing = -1
		Globals.compass.SW:
			Animator.play("[c1]TurnSE")
			new_facing = -1
		Globals.compass.WSW:
			Animator.play("[c1]TurnESE")
			new_facing = -1
			
		Globals.compass.W:
			Animator.play("[c1]TurnE")
			new_facing = -1
		Globals.compass.WNW:
			Animator.play("[c1]TurnESE")
			new_facing = -1
			new_v_facing = -1
		Globals.compass.NW:
			Animator.play("[c1]TurnSE")
			new_facing = -1
			new_v_facing = -1
		Globals.compass.NNW:
			Animator.play("[c1]TurnSSE")
			new_facing = -1
			new_v_facing = -1
			
		Globals.compass.N:
			Animator.play("[c1]TurnS")
			new_v_facing = -1
		Globals.compass.NNE:
			Animator.play("[c1]TurnSSE")
			new_v_facing = -1
		Globals.compass.NE:
			Animator.play("[c1]TurnSE")
			new_v_facing = -1
		Globals.compass.ENE:
			Animator.play("[c1]TurnESE")
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
	return move_name

func query_move_data(move_name) -> Dictionary:
	
	var orig_move_name = move_name

	move_name = refine_move_name(move_name)
	
	if !move_name in MOVE_DATABASE:
		print("Error: Cannot retrieve move_data for " + move_name)
		return {}
	
	var move_data = MOVE_DATABASE[move_name].duplicate(true)
#	move_data["atk_attr"] = query_atk_attr(move_name, true)
	
#	if orig_move_name.begins_with("a"):
#		move_data.KB_angle = -25
#	else:
	match orig_move_name:
		"[c1]TurnE":
			move_data.KB_angle = -31
		"[c1]TurnS":
			if Entity.v_facing == 1:
				move_data.KB_angle = 90
			else:
				move_data.KB_angle = -90
		"[c1]TurnSE":
			if Entity.v_facing == 1:
				move_data.KB_angle = 0
			else:
				move_data.KB_angle = -76
		"[c1]TurnSSE":
			if Entity.v_facing == 1:
				move_data.KB_angle = 31
			else:
				move_data.KB_angle = -83
		"[c1]TurnESE":
			if Entity.v_facing == 1:
				move_data.KB_angle = -25
			else:
				move_data.KB_angle = -55
		_:
			if orig_move_name.begins_with("[u]"):
				if Entity.v_facing == 1:
					move_data.KB_angle = -83
				else:
					move_data.KB_angle = 31
			else:
				if Entity.v_facing == -1:
					move_data.KB_angle = -25
					
					
	move_data.damage = FMath.percent(move_data.damage, Entity.MOB_LEVEL_TO_DMG[Entity.mob_level])
					
	if Globals.mob_attr.POWER in Entity.mob_attr:
		move_data.damage = Entity.modify_stat(move_data.damage, Globals.mob_attr.POWER, [50, 75, 125, 150, 175, 200])
	
	return move_data
	

func query_atk_attr(move_name):
	
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
		
		"[c1]Spin":
			Entity.velocity.percent(80)
			Entity.get_node("Sprite").rotation += 9*PI * Globals.FRAME * Entity.facing

#func spawn_afterimage(master_ID: int, is_entity: bool, master_ref: String, spritesheet_ref: String, sprite_node_path: NodePath, \
#		palette_ref, color_modulate = null, starting_modulate_a = 0.5, lifetime = 10, afterimage_shader = Globals.afterimage_shader.MASTER):

			if posmod(Entity.lifetime, 2) == 0:
				if Globals.mob_attr.WHITE_PROJ_TRAIL in Entity.mob_attr:
					Globals.Game.spawn_afterimage(Entity.entity_ID, true, Entity.creator_mob_ref, Entity.entity_ref, sprite.get_path(), Entity.palette_ref, \
							null, 0.5, 10.0, Globals.afterimage_shader.WHITE)
#					Globals.Game.spawn_mob_afterimage(Entity.creator_mob_ref, Entity.palette_ref, Entity.entity_ref, sprite.get_path(), null, \
#							0.5, 10.0, Globals.afterimage_shader.WHITE)
				if Globals.mob_attr.BLACK_PROJ_TRAIL in Entity.mob_attr:
					Globals.Game.spawn_afterimage(Entity.entity_ID, true, Entity.creator_mob_ref, Entity.entity_ref, sprite.get_path(), Entity.palette_ref, \
							Color(0.0, 0.0, 0.0), 0.5, 10.0, Globals.afterimage_shader.MASTER)
#					Globals.Game.spawn_mob_afterimage(Entity.creator_mob_ref, Entity.palette_ref, Entity.entity_ref, sprite.get_path(), \
#							Color(0.0, 0.0, 0.0), 0.5, 10.0, Globals.afterimage_shader.MASTER)
				else:
					Globals.Game.spawn_afterimage(Entity.entity_ID, true, Entity.creator_mob_ref, Entity.entity_ref, sprite.get_path(), Entity.palette_ref, \
							Color(1.5, 1.5, 1.5), 0.5, 10.0, Globals.afterimage_shader.MASTER)
#					Globals.Game.spawn_mob_afterimage(Entity.creator_mob_ref, Entity.palette_ref, Entity.entity_ref, sprite.get_path(), \
#							Color(1.5, 1.5, 1.5), 0.5, 10.0, Globals.afterimage_shader.MASTER)
		
		"[c1]Active", "[u][c1]Active":
			if Entity.lifetime > 25 and Entity.unique_data.spun == false:
				Entity.unique_data.spun = true
				var master_node = Globals.Game.get_player_node(Entity.master_ID)
				if master_node != null and !master_node.is_hitstunned_or_sequenced():
					Animator.play("[c1]Spin")
			continue
			
		_:
			if posmod(Entity.lifetime, 2) == 0:
				if Globals.mob_attr.PROJ_TRAIL in Entity.mob_attr:
					Globals.Game.spawn_afterimage(Entity.entity_ID, true, Entity.creator_mob_ref, Entity.entity_ref, sprite.get_path(), Entity.palette_ref, \
							Color(1.5, 1.5, 1.5), 0.5, 10.0, Globals.afterimage_shader.MASTER)
				elif Globals.mob_attr.WHITE_PROJ_TRAIL in Entity.mob_attr:
					Globals.Game.spawn_afterimage(Entity.entity_ID, true, Entity.creator_mob_ref, Entity.entity_ref, sprite.get_path(), Entity.palette_ref, \
							null, 0.5, 10.0, Globals.afterimage_shader.WHITE)
				elif Globals.mob_attr.BLACK_PROJ_TRAIL in Entity.mob_attr:
					Globals.Game.spawn_afterimage(Entity.entity_ID, true, Entity.creator_mob_ref, Entity.entity_ref, sprite.get_path(), Entity.palette_ref, \
							Color(0.0, 0.0, 0.0), 0.5, 10.0, Globals.afterimage_shader.MASTER)
						
	
func kill(sound = true):
	match Animator.to_play_animation:
		"[c1]Spawn", "[c1]Active":
			Animator.play("Kill")
			if sound: Entity.play_audio("break2", {"vol" : -15}) # don't put this outside, Spin animation has no kill()
		"[u][c1]Spawn", "[u][c1]Active":
			Animator.play("[u]Kill")
			if sound: Entity.play_audio("break2", {"vol" : -15})
		"[c1]TurnE":
			Animator.play("EKill")
			if sound: Entity.play_audio("break2", {"vol" : -15})
		"[c1]TurnS":
			Animator.play("SKill")
			if sound: Entity.play_audio("break2", {"vol" : -15})
		"[c1]TurnSE":
			Animator.play("SEKill")
			if sound: Entity.play_audio("break2", {"vol" : -15})
		"[c1]TurnSSE":
			Animator.play("SSEKill")
			if sound: Entity.play_audio("break2", {"vol" : -15})
		"[c1]TurnESE":
			Animator.play("ESEKill")
			if sound: Entity.play_audio("break2", {"vol" : -15})

	
func collision(): # collided with a platform
	kill()
	
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
		"[u][c1]Spawn":
			Animator.play("[u][c1]Active")
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
