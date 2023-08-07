extends Node2D



const TRAITS = []

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
		Em.move.HITSPARK_TYPE: Em.hitspark_type.HIT,
		Em.move.HITSPARK_PALETTE: "blue",
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
		Em.move.HITSPARK_TYPE: Em.hitspark_type.HIT,
		Em.move.HITSPARK_PALETTE: "blue",
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
		Animator.play("[c2]Spawn")
	else:
		rot = -68
		Animator.play("[u][c2]Spawn")

				
	if "aerial" in aux_data:
		rot = -rot
		Entity.v_face(-1)
				

	Entity.velocity.set_vector(600 * FMath.S, 0)
	Entity.velocity.rotate(rot)
	Entity.velocity.x *= Entity.facing
	Entity.absorption_value = 2
	Entity.life_point = 2
	Globals.Game.spawn_SFX("TridentRing", "TridentRing", Entity.position, \
			{"facing":Entity.facing, "rot":deg2rad(rot)}, Entity.palette_ref, Entity.master_ref)
			

#func spin():
#	match Animator.to_play_anim:
#		"[c1]Active", "[u][c1]Active":
#			Animator.play("[c1]Spin")

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
	
	Entity.life_point = 1
	Entity.absorption_value = 1
	Entity.velocity.set_vector(500 * FMath.S, 0)
	
	match segment:
		Em.compass.E:
			Animator.play("[c1]TurnE")
		Em.compass.ESE:
			Animator.play("[c1]TurnESE")
		Em.compass.SE:
			Animator.play("[c1]TurnSE")
		Em.compass.SSE:
			Animator.play("[c1]TurnSSE")
			
		Em.compass.S:
			Animator.play("[c1]TurnS")
		Em.compass.SSW:
			Animator.play("[c1]TurnSSE")
			new_facing = -1
		Em.compass.SW:
			Animator.play("[c1]TurnSE")
			new_facing = -1
		Em.compass.WSW:
			Animator.play("[c1]TurnESE")
			new_facing = -1
			
		Em.compass.W:
			Animator.play("[c1]TurnE")
			new_facing = -1
		Em.compass.WNW:
			Animator.play("[c1]TurnESE")
			new_facing = -1
			new_v_facing = -1
		Em.compass.NW:
			Animator.play("[c1]TurnSE")
			new_facing = -1
			new_v_facing = -1
		Em.compass.NNW:
			Animator.play("[c1]TurnSSE")
			new_facing = -1
			new_v_facing = -1
			
		Em.compass.N:
			Animator.play("[c1]TurnS")
			new_v_facing = -1
		Em.compass.NNE:
			Animator.play("[c1]TurnSSE")
			new_v_facing = -1
		Em.compass.NE:
			Animator.play("[c1]TurnSE")
			new_v_facing = -1
		Em.compass.ENE:
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
		"[u][c1]Active", "[c1]TurnE", "[c1]TurnS", "[c1]TurnSE", "[c1]TurnSSE", "[c1]TurnESE":
			return "[c1]Active"
		"[c2]Spawn", "[u][c2]Spawn", "[u][c2]Active", "[c2]TurnE", "[c2]TurnS", "[c2]TurnSE", "[c2]TurnSSE", "[c2]TurnESE":
			return "[c2]Active"
	return move_name

func query_move_data(move_name) -> Dictionary:
	
	var orig_move_name = move_name

	move_name = refine_move_name(move_name)
	
	if !move_name in MOVE_DATABASE:
		print("Error: Cannot retrieve move_data for " + move_name)
		return {}
	
	var move_data = MOVE_DATABASE[move_name].duplicate(true)
#	move_data[Em.move.ATK_ATTR] = query_atk_attr(move_name, true)
	
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
			move_data[Em.move.DMG] = FMath.percent(move_data[Em.move.DMG], Inventory.modifier(Entity.master_ID, Cards.effect_ref.ASSIST_DMG_MOD))
	
	return move_data
	

func query_atk_attr(move_name):
	
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
		
		"[c1]Spin":
			Entity.velocity.percent(80)
			Entity.get_node("Sprite").rotation += 9*PI * Globals.FRAME * Entity.facing

		"[c2]Active", "[u][c2]Active":
			if posmod(Entity.lifetime, 3) == 0:
				Globals.Game.spawn_afterimage(Entity.entity_ID, Em.afterimage_type.ENTITY, Entity.entity_ref, sprite.get_path(), \
						Entity.palette_ref, Entity.master_ref, Color(1.5, 1.5, 1.5), 0.5, 10.0)
			if Entity.lifetime > 15:
				var master_node = Globals.Game.get_player_node(Entity.master_ID)
				if master_node != null and !master_node.is_hitstunned_or_sequenced():
					Animator.play("[c1]Spin")

						
	
func kill(sound = true):
	match Animator.to_play_anim:
		"[c2]Spawn", "[c2]Active":
			Animator.play("Kill")
			if sound: killsound() # don't put this outside, Spin animation has no kill()
		"[u][c2]Spawn", "[u][c2]Active":
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
	
func collision(): # collided with a platform
	kill()
	
func landed_a_hit(hit_data):
	Entity.life_point -= 1
	if Entity.life_point <= 0:
		kill(false)
		Entity.hitstop = 0
		
	fever(hit_data)

func fever(hit_data):
	if Globals.survival_level == null:
		if hit_data[Em.hit.BLOCK_STATE] == Em.block_state.UNBLOCKED and "assist_fever" in hit_data[Em.hit.ATKER]:
			if !"assist_rescue_protect" in hit_data[Em.hit.DEFENDER]:
				return
			if !hit_data[Em.hit.DEFENDER].assist_rescue_protect:
				hit_data[Em.hit.ATKER].assist_fever = true
			
		
func on_offstage():
	Entity.free = true
	
func _on_SpritePlayer_anim_finished(anim_name):
	match anim_name:
		"[c2]Spawn":
			Animator.play("[c2]Active")
		"[u][c2]Spawn":
			Animator.play("[u][c2]Active")
		"[c1]Spin":
			turn_to_enemy()
			
func _on_SpritePlayer_anim_started(anim_name):
	if anim_name.ends_with("Kill"):
		Entity.velocity.set_vector(0, 0)
		
	else:
		match anim_name:
			"[c1]Spin":
				if Entity.v_facing == -1:
					Entity.v_face(1)
