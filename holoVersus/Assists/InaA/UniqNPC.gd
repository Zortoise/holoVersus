extends "res://Characters/Ina/CharBase.gd"

const ASSIST_NAME = "Ina'nis"

# replace player_ID with master_ID or NPC_ID
# replace palette_number with palette_ref
# replace afterimage_type of CHAR with NPC
# remove all EX Moves
# remove all is_EX_valid()
# Character.cancel_action() has no parameters
# remove all move_child() in sequences
# add "facing" : Character.facing to aux_data of all entities
# for entity and SFX spawns, replace "Character.palette_number, NAME" with "Character.palette_ref, Character.NPC_ref"
# for entity, make sure there is "A" at end of entity name
# copy DefaultCollisionBox from original character

# --------------------------------------------------------------------------------------------------

# shortening code, set by main character node
onready var Character = get_parent()
var Animator
var sprite
var uniqueHUD

func _ready():
	get_node("TestSprite").free() # test sprite is for sizing collision box
	
	
# PROCESSING --------------------------------------------------------------------------------------------------
	
func get_smart_selection(_target, _origin_point: Vector2) -> Array:
	var selection_array := []
	
	# NEUTRAL
	selection_array.append({
		"name" : "InaA", 
		"atk_ID" : Em.assist.NEUTRAL,
		"weight" : 10,
	})
	
	# DOWN
	selection_array.append({
		"name" : "InaA", 
		"atk_ID" : Em.assist.DOWN,
		"weight" : 10,
	})
		
	return selection_array
	
	
func preprocess(master_ID: int, aux_data: Dictionary): # modify aux_data based on move used
#	var aux_data = {
#		"NPC_ref" : NPC_ref,
#		"out_position" : out_position,
#		"start_facing" : start_facing,
#		"palette_ref" : palette_ref,
#		"atk_ID" : atk_ID,
#	}

	var floor_level = Globals.Game.middle_point.y
	var master_node = Globals.Game.get_player_node(master_ID)
	var cooldown := 100
	
	match aux_data.atk_ID:
		Em.assist.NEUTRAL:
			cooldown = 300
			offset(aux_data, master_node, Vector2(-40, 0))
			if aux_data.out_position.y < floor_level: # if called in the air
				min_height(aux_data, 75)
		Em.assist.DOWN:
			cooldown = 300
			offset(aux_data, master_node, Vector2(-40, 0))
			if aux_data.out_position.y < floor_level: # if called in the air
				min_height(aux_data, 75)
		
	clamp_pos(aux_data)
	
	if master_node.is_hitstunned(): # increase cooldown if used during hitstun
		cooldown = FMath.percent(cooldown, Globals.Game.ASSIST_CD_PENALTY)
	elif master_node.assist_fever:
		cooldown = FMath.percent(cooldown, Globals.Game.ASSIST_FEVER_CD_REDUCE)
	master_node.get_node("AssistCDTimer").time += cooldown # set the cooldown
	
	
func offset(aux_data: Dictionary, master_node, offset_vec: = Vector2.ZERO): # positive is towards facing, ALWAYS DO OFFSET FIRST!
	if !master_node.is_hitstunned():
		offset_vec.x *= aux_data.start_facing
		aux_data.out_position += offset_vec
	else:
		# Assist Rescue offset
		aux_data.out_position.x += master_node.dir * Globals.Game.ASSIST_RESCUE_OFFSET
		
#		if master_node.dir == 0 and master_node.v_dir == 0: return
#		var v_dir = master_node.v_dir
#
#		var vec = FVector.new()
#		vec.set_vector(Globals.Game.ASSIST_RESCUE_OFFSET * FMath.S, 0)
#		vec.rotate(Globals.dir_to_angle(master_node.dir, master_node.v_dir, aux_data.start_facing))
#		aux_data.out_position += vec.convert_to_vec()
		

func min_height(aux_data: Dictionary, height: int):
	aux_data.out_position.y = min(aux_data.out_position.y, Globals.Game.middle_point.y - height)

func clamp_pos(aux_data: Dictionary):
	aux_data.out_position.x = clamp(aux_data.out_position.x, Globals.Game.left_corner, Globals.Game.right_corner)
	aux_data.out_position.y = clamp(aux_data.out_position.y, Globals.Game.stage_box.rect_global_position.y + Globals.CORNER_SIZE, \
			Globals.Game.middle_point.y)
	
func bring_to_ground(aux_data: Dictionary):
	var ground_found = Detection.ground_finder(aux_data.out_position, aux_data.start_facing, Vector2(0, 315), Vector2(10, 650), 1)
	if ground_found:
		aux_data.out_position = ground_found
	
	
# SUMMON ACTIONS --------------------------------------------------------------------------------------------------
	
func start_attack(atk_ID: int):
	shine()
	Character.play_audio("bling3", {"vol" : -20})
	Character.play_audio("bling7", {"vol" : -15, "bus" : "HighPass"})
	
	Character.modulate_play("sweet_flash")
	Character.face_opponent()
	match atk_ID:
		Em.assist.NEUTRAL:
			Character.animate("aSP1Startup")
		Em.assist.DOWN:
			if Character.master_node.is_hitstunned(): # since drill disable during hitstun
				Character.animate("aSP1Startup")
			else:
				Character.animate("aSP4Startup")


func unsummon(assist_attacked := false): # can be different if custom assist
	if Character.master_node.assist_active:
		Character.master_node.assist_active = false
		
	if assist_attacked:
		if Globals.assists == 1:
			Character.master_node.get_node("AssistCDTimer").time = FMath.percent(Character.master_node.get_node("AssistCDTimer").time, \
					Globals.Game.ASSIST_CD_PENALTY)
		Character.play_audio("bling8", {"vol" : -18})
	else:
		Character.play_audio("bling3", {"vol" : -18})
		Character.play_audio("bling7", {"vol" : -25, "bus" : "HighPass"})
	shine()

			
	if Character.sfx_under.visible:
		Globals.Game.spawn_afterimage(Character.NPC_ID, Em.afterimage_type.NPC, Character.sprite_texture_ref.sfx_under, \
				Character.sfx_under.get_path(), Character.palette_ref, Character.NPC_ref, null, 0.8, 15, Em.afterimage_shader.WHITE)
			
	Globals.Game.spawn_afterimage(Character.NPC_ID, Em.afterimage_type.NPC, Character.sprite_texture_ref.sprite, sprite.get_path(), \
			Character.palette_ref, Character.NPC_ref, null, 0.8, 15, Em.afterimage_shader.WHITE)
	
	if Character.sfx_over.visible:
		Globals.Game.spawn_afterimage(Character.NPC_ID, Em.afterimage_type.NPC, Character.sprite_texture_ref.sfx_over, \
				Character.sfx_over.get_path(), Character.palette_ref, Character.NPC_ref, null, 0.8, 15, Em.afterimage_shader.WHITE)
					
				
func shine():
	var player_palette := "red"
	match Character.master_ID:
		1:
			player_palette = "blue"
	Globals.Game.spawn_SFX("Summon", "Summon", Character.position, {"facing":Globals.Game.rng_facing(), \
			"v_mirror":Globals.Game.rng_bool()}, player_palette)
	
# STATE_DETECT --------------------------------------------------------------------------------------------------

func state_detect(anim): # for unique animations, continued from state_detect() of main character node
	match anim:
		
		"aSP1Startup":
			return Em.char_state.AIR_ATK_STARTUP
		"aSP1Active", "aSP1[d]Active", "aSP1[u]Active":
			return Em.char_state.AIR_ATK_ACTIVE
		"aSP1Rec":
			return Em.char_state.AIR_ATK_REC
			
		"aSP4Startup":
			return Em.char_state.AIR_ATK_STARTUP
		"aSP4Active":
			return Em.char_state.AIR_ATK_ACTIVE
		"aSP4Rec":
			return Em.char_state.AIR_ATK_REC

	print("Error: " + anim + " not found.")
	
		
func check_collidable():  # some characters have move that can pass through other characters
	return false
	
func check_fallthrough():
	match Character.new_state:
		Em.char_state.AIR_ATK_ACTIVE:
			return true
	return false

func check_semi_invuln(_crossed_up := false):
	return false

# UNIQUE INPUT CAPTURE --------------------------------------------------------------------------------------------------
# some holdable buttons can have effect unique to the character
	
func simulate():
	
	match Character.state:
		Em.char_state.AIR_ATK_ACTIVE:
			if Animator.time in [1, 7, 13] and Animator.query_current(["aSP1Active", "aSP1[d]Active", "aSP1[u]Active"]):
				var aux_data := {"facing": Character.facing, "angle" : 0}
				match Animator.current_anim:
					"aSP1Active":
						match Animator.time:
							1:
								aux_data.angle = -30
							7:
								aux_data.angle = 0
							13:
								aux_data.angle = 30
					"aSP1[d]Active":
						match Animator.time:
							1:
								aux_data.angle = 15
							7:
								aux_data.angle = 45
							13:
								aux_data.angle = 75
					"aSP1[u]Active":
						match Animator.time:
							1:
								aux_data.angle = -15
							7:
								aux_data.angle = -45
							13:
								aux_data.angle = -75
				if Character.facing == -1:
					aux_data.angle = Globals.mirror_angle(aux_data.angle)
					
				var spawn_point = Animator.query_point("entityspawn")
				Globals.Game.spawn_entity(Character.master_ID, "TakoA", spawn_point, aux_data, \
						Character.palette_ref, Character.NPC_ref)
				Globals.Game.spawn_SFX("Blink", "Blink", spawn_point, {"facing":Globals.Game.rng_facing()}, Character.palette_ref, Character.NPC_ref)
				expire_extra_takos()
				
				Character.play_audio("energy8", {"vol": -21, "bus":"LowPass"})
				Character.play_audio("bling8", {"vol": -16, "bus":"PitchUp"})

# SPECIAL ACTIONS --------------------------------------------------------------------------------------------------


func afterimage_trail():# process afterimage trail
	match Character.new_state:
		_:
			pass
			
func unique_flash():
	pass

# GET DATA --------------------------------------------------------------------------------------------------

func get_stat(stat: String): # later can have effects that changes stats
	var to_return
	if stat in self:
		to_return = get(stat)
	else:
		to_return = StandardStats.retrieve(stat, CLASS1, CLASS2)
	
	return to_return
	
	
func query_traits(): # may have special conditions
	return TRAITS
			
func get_root(move_name): # for aerial, chain and repeat memory, only needed for versions with active frames not in MOVE_DATABASE
	
	if move_name in MOVE_DATABASE and Em.move.ROOT in MOVE_DATABASE[move_name]:
		return MOVE_DATABASE[move_name][Em.move.ROOT]
		
	move_name = refine_move_name(move_name)
	
	if move_name in MOVE_DATABASE and Em.move.ROOT in MOVE_DATABASE[move_name]:
		return MOVE_DATABASE[move_name][Em.move.ROOT] # refined move_name can have root
		
	return move_name
		
			
func refine_move_name(move_name):
		
	match move_name:
		"aSP1[d]", "aSP1[u]":
			return "aSP1"

	return move_name
			
			
func query_move_data(move_name) -> Dictionary: # can change under conditions
	
	var orig_move_name = move_name
	move_name = refine_move_name(move_name)
	
	if !move_name in MOVE_DATABASE:
		print("Error: Cannot retrieve move_data for " + move_name + " in " + filename)
		return {}
	
	var move_data = MOVE_DATABASE[move_name].duplicate(true)
	move_data[Em.move.ATK_ATTR] = query_atk_attr(orig_move_name)
	
	match orig_move_name:
		_:
			pass
			
	if Globals.survival_level != null and Em.move.DMG in move_data:
		move_data[Em.move.DMG] = FMath.percent(move_data[Em.move.DMG], Character.mod_damage(move_name))


	return move_data


						
func query_atk_attr(move_name) -> Array: # can change under conditions

	var orig_move_name = move_name
	move_name = refine_move_name(move_name)

	var atk_attr := []
	if move_name in MOVE_DATABASE and Em.move.ATK_ATTR in MOVE_DATABASE[move_name]:
		atk_attr = MOVE_DATABASE[move_name][Em.move.ATK_ATTR].duplicate(true)
	else:
		print("Error: Cannot retrieve atk_attr for " + move_name)
		return []
	
	match orig_move_name: # can add various atk_attr to certain animations under under conditions
		_:
			pass
			
	atk_attr.append(Em.atk_attr.ASSIST) # add "Assist" to move name when added to Repeat Memory
			
	return atk_attr
	

# HIT REACTIONS --------------------------------------------------------------------------------------------------

func landed_a_hit(hit_data): # reaction, can change hit_data from here
	fever(hit_data)

func fever(hit_data):
	if Globals.survival_level == null and Globals.assists == 1:
		if hit_data[Em.hit.BLOCK_STATE] == Em.block_state.UNBLOCKED and "assist_fever" in hit_data[Em.hit.ATKER]:
			if !"assist_rescue_protect" in hit_data[Em.hit.DEFENDER]:
				return
			if !hit_data[Em.hit.DEFENDER].assist_rescue_protect:
				hit_data[Em.hit.ATKER].assist_fever = true
			
			
func being_hit(_hit_data):
	clear_drill()
					
				
		
	
# AUTO SEQUENCES --------------------------------------------------------------------------------------------------

func simulate_sequence(): # this is ran on every frame during a sequence
	
	var Partner = Character.get_seq_partner()
	if Partner == null:
		Character.animate("Idle")
		return

	match Animator.to_play_anim:
		_:
			pass
						
func simulate_sequence_after(): # called after moving and animating every frame, grab_point and grab_rot_dir are only updated then
	
	var Partner = Character.get_seq_partner()
	if Partner == null:
		Character.animate("Idle")
		return

#	var grab_point = Animator.query_point("grabpoint")

	match Animator.to_play_anim:
		_:
			pass
			
						
func start_sequence_step(): # this is ran at the start of every sequence_step
	var Partner = Character.get_seq_partner()
	if Partner == null: # DO NOT START ANIMATIONS HERE!
		return

	match Animator.to_play_anim:
		_:
			pass
			
							
func end_sequence_step(trigger = null): # this is ran at the end of certain sequence_step, or to end a trigger sequence_step
	# return true if sequence_step ended
	
	var Partner = Character.get_seq_partner()
	if Partner == null:
		Character.animate("Idle")
		return true
	
	if trigger == "break": # grab break
		Character.animate("Idle")
		Partner.animate("Idle")
		return true
				
	if trigger == null: # launching
		match Animator.to_play_anim:
			_:
				pass
	else:
		match Animator.to_play_anim:
			_:
				pass
				
	return false
			
			
func rotate_partner(Partner): # rotate partner according to grabrotdir
	var grab_point = Animator.query_point("grabpoint")
	var grab_rot_dir = Animator.query_point("grabrotdir")

	if grab_rot_dir != null:
		if Partner.facing == -1:
			Partner.sprite.rotation = grab_point.angle_to_point(grab_rot_dir)
		else:
			Partner.sprite.rotation = grab_point.angle_to_point(grab_rot_dir) + PI
			
func move_sequence_target(new_position): # move sequence_target to new position
	if new_position == null: return # no grab point
	
	var Partner = Character.get_seq_partner()
	if Partner == null:
		Character.animate("Idle")
		return
		
	var results = Partner.move_sequence_player_to(new_position) # [landing_check, collision_check, ledgedrop_check]
	
	if results[0]: # Grabbed hit the ground, ends sequence step if it is triggered by Grabbed being grounded
		if end_sequence_step("target_ground"):
			return
			
	if results[1]: # Grabbed hit the wall/ceiling/ground outside ground trigger, reposition Grabber
		var reposition = Partner.position + (Character.position - Animator.query_point("grabpoint"))
		var reposition_results = Character.move_sequence_player_to(reposition) # [landing_check, collision_check, ledgedrop_check]
		if reposition_results[1]: # fail to reposition properly
			end_sequence_step("break") # break grab
		
			
func get_seq_hit_data(hit_key: int):
	var seq_hit_data = MOVE_DATABASE[Animator.to_play_anim][Em.move.SEQ_HITS][hit_key].duplicate(true)

	if Globals.survival_level != null and Em.move.DMG in seq_hit_data:
		seq_hit_data[Em.move.DMG] = FMath.percent(seq_hit_data[Em.move.DMG], Character.mod_damage(MOVE_DATABASE[Animator.to_play_anim][Em.move.STARTER]))

	return seq_hit_data
	
	
	
func get_seq_launch_data():
	var seq_data = MOVE_DATABASE[Animator.to_play_anim][Em.move.SEQ_LAUNCH].duplicate(true)

	if Globals.survival_level != null and Em.move.DMG in seq_data:
		seq_data[Em.move.DMG] = FMath.percent(seq_data[Em.move.DMG], Character.mod_damage(MOVE_DATABASE[Animator.to_play_anim][Em.move.STARTER]))

	return seq_data
			
			
			
func sequence_fallthrough(): # which step in sequence ignore soft platforms
	return false
	
func sequence_ledgestop(): # which step in sequence are stopped by ledges
	return false
	
func sequence_passthrough(): # which step in sequence ignore all platforms (for cinematic supers)
	return false
	
func sequence_partner_passthrough(): # which step in sequence has partner ignore all platforms
	return false
	
	
# CODE FOR CERTAIN MOVES ---------------------------------------------------------------------------------------------------

func get_takos() -> Array:
	var tako_array := []
	var entity_array := []
	if Globals.player_count > 2:
		entity_array = get_tree().get_nodes_in_group("EntityNodes")
	else:
		entity_array = get_tree().get_nodes_in_group("P" + str(Character.master_ID + 1) + "EntityNodes")
	for entity in entity_array:
		if !entity.free and entity.master_ID == Character.master_ID and "ID" in entity.UniqEntity and entity.UniqEntity.ID == "tako" and \
				entity.Animator.current_anim != "Kill":
			tako_array.append(entity)
	return tako_array
	
	
func expire_extra_takos():
	var tako_array = get_takos()
	if tako_array.size() > 10:
		var number_to_remove = tako_array.size() - 10
		for x in number_to_remove:
			var oldest_tako = null
			var oldest_tako_age := 0
			for tako in tako_array:
				if oldest_tako == null: # 1st tako
					oldest_tako = tako
					oldest_tako_age = tako.birth_time
				elif tako.birth_time < oldest_tako_age:
					oldest_tako = tako
					oldest_tako_age = tako.birth_time
			if oldest_tako != null:
				oldest_tako.UniqEntity.expire()
				tako_array.erase(oldest_tako)


func spawn_drill():
	clear_drill()
	
	var spawn_point = Character.position
	spawn_point.x += Character.facing * 96
	
	spawn_point.y = min(spawn_point.y, Globals.Game.middle_point.y - 96) # minimum height
	
	spawn_point.x = clamp(spawn_point.x, Globals.Game.left_corner, Globals.Game.right_corner) # clamp position
	spawn_point.y = clamp(spawn_point.y, Globals.Game.stage_box.rect_global_position.y + Globals.CORNER_SIZE, \
			Globals.Game.middle_point.y)
	
	Globals.Game.spawn_entity(Character.master_ID, "InaDrillA", spawn_point, {"facing": Character.facing}, \
			Character.palette_ref, Character.NPC_ref)
					
					
func clear_drill():
	var entity_array := []
	if Globals.player_count > 2:
		entity_array = get_tree().get_nodes_in_group("EntityNodes")
	else:
		entity_array = get_tree().get_nodes_in_group("P" + str(Character.master_ID + 1) + "EntityNodes")
	for entity in entity_array:
		if !entity.free and entity.master_ID == Character.master_ID and "ID" in entity.UniqEntity and entity.UniqEntity.ID == "drill" and \
				!entity.Animator.current_anim.ends_with("Kill"):
			entity.UniqEntity.kill()
			
			

# ANIMATION AND AUDIO PROCESSING ---------------------------------------------------------------------------------------------------
# these are ran by main character node when it gets the signals so that the order is easier to control

func _on_SpritePlayer_anim_finished(anim_name):
	
	match anim_name:
	
		"aSP1Startup":
			match Character.get_opponent_angle_seg(Em.angle_split.EIGHT):
				Em.compass.E, Em.compass.W:
					Character.animate("aSP1Active")
				Em.compass.N, Em.compass.NE, Em.compass.NW:
					Character.animate("aSP1[u]Active")
				Em.compass.S, Em.compass.SE, Em.compass.SW:
					if Character.is_on_solid_ground():
						Character.animate("aSP1Active")
					else:
						Character.animate("aSP1[d]Active")
		"aSP1Active", "aSP1[d]Active", "aSP1[u]Active":
			Character.animate("aSP1Rec")
		"aSP1Rec":
			Character.unsummon()
			

		"aSP4Startup":
			Character.animate("aSP4Active")
		"aSP4Active":
			Character.animate("aSP4Rec")
		"aSP4Rec":
			Character.unsummon()

			

func _on_SpritePlayer_anim_started(anim_name):

	match anim_name:
		
		"aSP1Startup", "aSP1[ex]Startup", "aSP2Startup", "aSP2[ex]Startup":
			Character.velocity_limiter.x_slow = 20
			Character.velocity_limiter.y_slow = 20
			Character.anim_gravity_mod = 0
		"aSP1Active", "aSP1[u]Active", "aSP1[d]Active":
			stop_momentum()
			special_dust()
			
		"aSP4Startup":
			Character.velocity_limiter.x_slow = 20
			Character.velocity_limiter.y_slow = 20
			Character.anim_gravity_mod = 0
		"aSP4Active":
			stop_momentum()
			special_dust()
			spawn_drill()
			Character.play_audio("magic3", {"vol": -10})
		
		"aSP1Rec", "aSP4Rec":
			Character.velocity_limiter.x = 70
			Character.velocity_limiter.down = 70
					
	start_audio(anim_name)


func special_dust(): # cleaner code
	if Character.grounded:
		var pos = Character.get_feet_pos()
		pos.x -= 5 * Character.facing
		Globals.Game.spawn_SFX("SpecialDust", "DustClouds", pos, {"facing":Character.facing})

func stop_momentum(): # cleaner code
	Character.velocity.set_vector(0, 0)
	Character.velocity_limiter.x = 0
	Character.velocity_limiter.down = 0
	Character.velocity_limiter.up = 0
	Character.anim_gravity_mod = 0
	

func start_audio(anim_name):
	if Character.is_atk_active():
		var move_name = anim_name.trim_suffix("Active")
		var orig_move_name = move_name
		if !move_name in MOVE_DATABASE:
			move_name = refine_move_name(move_name)
		if move_name in MOVE_DATABASE:
			if Em.move.MOVE_SOUND in MOVE_DATABASE[move_name]:
				if !MOVE_DATABASE[move_name][Em.move.MOVE_SOUND] is Array:
					Character.play_audio(MOVE_DATABASE[move_name][Em.move.MOVE_SOUND].ref, MOVE_DATABASE[move_name][Em.move.MOVE_SOUND].aux_data)
				else:
					for sound in MOVE_DATABASE[move_name][Em.move.MOVE_SOUND]:
						Character.play_audio(sound.ref, sound.aux_data)
						
		match orig_move_name:
			"SP1[c1]", "SP1[u][c1]", "aSP1[c1]", "aSP1[d][c1]":
				Character.play_audio("whoosh12", {"bus":"PitchDown"})

	match Character.state:
		Em.char_state.LAUNCHED_HITSTUN:
			match anim_name:
				"LaunchTransit":
					if Character.grounded and abs(Character.velocity.y) < 1 * FMath.S:
						Character.play_audio("launch2", {"vol" : -3, "bus":"LowPass"})
					else:
						Character.play_audio("launch1", {"vol":-15, "bus":"PitchDown"})


func landing_sound(): # can be called by main node
	Character.play_audio("land1", {"vol" : -3})
	
func dash_sound(): # can be called by snap-up wavelanding
	Character.play_audio("dash1", {"vol" : -5, "bus":"PitchDown"})

func stagger_anim():
	match Character.state:
		_:
			pass

