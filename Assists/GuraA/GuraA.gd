extends "res://Characters/Gura/GuraBase.gd"

const ASSIST_NAME = "Ina'nis"

# replace player_ID with master_ID or NPC_ID
# replace palette_number with palette_ref
# replace afterimage_type of CHAR with NPC
# remove all EX Moves
# remove all is_EX_valid()
# Character.cancel_action() has no parameters
# remove all move_child() in sequences
# add "facing" : Character.facing to aux_data of all entities
# for enitity and SFX spawns, replace "Character.palette_number, NAME" with "Character.palette_ref, Character.NPC_ref"

# --------------------------------------------------------------------------------------------------

# shortening code, set by main character node
onready var Character = get_parent()
var Animator
var sprite
var uniqueHUD

func _ready():
	get_node("TestSprite").free() # test sprite is for sizing collision box
	
	
# PROCESSING --------------------------------------------------------------------------------------------------
	
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
			offset(aux_data, master_node, Vector2(-30, 0))
			if aux_data.out_position.y < floor_level: # if called in the air
				min_height(aux_data, 75)
		Em.assist.DOWN:
			cooldown = 300
			offset(aux_data, master_node, Vector2(-40, 0))
			bring_to_ground(aux_data)
		
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
			if Character.grounded:
				Character.animate("SP1Startup")
			else:
				Character.animate("aSP1Startup")
		Em.assist.DOWN:
			Character.animate("SP9Startup")


func unsummon(assist_attacked := false): # can be different if custom assist
	if Character.master_node.assist_active:
		Character.master_node.assist_active = false
		if assist_attacked:
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
		
		
		"SP1Startup", "SP1[b]Startup", "SP1[c1]Startup", "SP1[c1]bStartup":
			return Em.char_state.GRD_ATK_STARTUP
		"SP1[u]Startup", "SP1[u][c1]Startup", "SP1[u][c1]bStartup":
			return Em.char_state.GRD_ATK_STARTUP
		"SP1[c1]Active", "SP1[u][c1]Active":
			return Em.char_state.GRD_ATK_ACTIVE
		"SP1Rec":
			return Em.char_state.GRD_ATK_REC
			
		"aSP1Startup", "aSP1[b]Startup", "aSP1[c1]Startup", "aSP1[c1]bStartup":
			return Em.char_state.AIR_ATK_STARTUP
		"aSP1[d]Startup", "aSP1[d][c1]Startup", "aSP1[d][c1]bStartup":
			return Em.char_state.AIR_ATK_STARTUP
		"aSP1[c1]Active", "aSP1[d][c1]Active":
			return Em.char_state.AIR_ATK_ACTIVE
		"aSP1Rec":
			return Em.char_state.AIR_ATK_REC
			
		"SP9Startup", "SP9aStartup":
			return Em.char_state.GRD_ATK_STARTUP
		"SP9Active":
			return Em.char_state.GRD_ATK_ACTIVE
		"aSP9aActive":
			return Em.char_state.AIR_ATK_ACTIVE
		"SP9aRec":
			return Em.char_state.GRD_ATK_REC
		"aSP9aRec":
			return Em.char_state.AIR_ATK_REC

	print("Error: " + anim + " not found.")
		
func check_collidable():  # some characters have move that can pass through other characters
	return false
	
func check_fallthrough():
	match Character.new_state:
		Em.char_state.AIR_ATK_ACTIVE:
			return true
	return false

func check_semi_invuln():
	return false

# UNIQUE INPUT CAPTURE --------------------------------------------------------------------------------------------------
# some holdable buttons can have effect unique to the character
	
func simulate():
	
	match Character.state:
		Em.char_state.GRD_ATK_ACTIVE:
			if Animator.query_to_play(["SP9Active"]):
				var dist = Character.get_target().position.x - Character.position.x
				if sign(dist) == Character.facing and abs(dist) <= 135:
					Character.animate("aSP9aActive")

# SPECIAL ACTIONS --------------------------------------------------------------------------------------------------


func afterimage_trail():# process afterimage trail
	match Character.new_state:
		_:
			pass
			
func unique_flash():
	match Character.new_state:
		Em.char_state.GRD_ATK_ACTIVE:
			if Animator.query_to_play(["SP9Active"]):
				if Animator.time != 0 and posmod(Animator.time, 2) == 0 and abs(Character.velocity.x) >= 800 * FMath.S:
					Globals.Game.spawn_SFX("WaterBurst", "WaterBurst", Character.get_feet_pos(), \
							{"facing":-Character.facing}, Character.palette_ref, Character.NPC_ref)

# GET DATA --------------------------------------------------------------------------------------------------

func get_stat(stat: String): # later can have effects that changes stats
	var to_return = get(stat)

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
		"SP1[b]", "aSP1", "aSP1[b]", "SP1[c1]", "SP1[c1]b", "aSP1[c1]", "aSP1[c1]b", \
				"SP1[u]", "SP1[u][c1]", "SP1[u][c1]b", "aSP1[d]", "aSP1[d][c1]", "aSP1[d][c1]b":
			return "SP1"
		"aSP9":
			return "SP9"
		"SP9a":
			return "aSP9a"

	return move_name
			
			
func query_move_data(move_name) -> Dictionary: # can change under conditions
	
	var orig_move_name = move_name
	move_name = refine_move_name(move_name)
	
	if !move_name in MOVE_DATABASE:
		print("Error: Cannot retrieve move_data for " + move_name)
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
	if Globals.survival_level == null:
		if hit_data[Em.hit.BLOCK_STATE] == Em.block_state.UNBLOCKED and "assist_fever" in hit_data[Em.hit.ATKER]:
			if !"assist_rescue_protect" in hit_data[Em.hit.DEFENDER]:
				return
			if !hit_data[Em.hit.DEFENDER].assist_rescue_protect:
				hit_data[Em.hit.ATKER].assist_fever = true
			
func being_hit(_hit_data):
	pass
		
	
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


# ANIMATION AND AUDIO PROCESSING ---------------------------------------------------------------------------------------------------
# these are ran by main character node when it gets the signals so that the order is easier to control

func _on_SpritePlayer_anim_finished(anim_name):
	
	match anim_name:


		"SP1Startup":
			match Character.get_opponent_angle_seg(Em.angle_split.FOUR):
				Em.compass.N:
					Character.animate("SP1[u]Startup")
				_:
					Character.animate("SP1[b]Startup")
		"SP1[b]Startup":
			Character.animate("SP1[c1]Startup")
		"SP1[c1]Startup":
			Character.animate("SP1[c1]bStartup")
		"SP1[c1]bStartup":
			Character.animate("SP1[c1]Active")
		"SP1[c1]Active":
			Character.animate("SP1Rec")
		"SP1Rec":
			Character.unsummon()
			
		"SP1[u]Startup":
			Character.animate("SP1[u][c1]Startup")
		"SP1[u][c1]Startup":
			Character.animate("SP1[u][c1]bStartup")
		"SP1[u][c1]bStartup":
			Character.animate("SP1[u][c1]Active")
		"SP1[u][c1]Active":
			Character.animate("SP1Rec")
			
		"aSP1Startup":
			match Character.get_opponent_angle_seg(Em.angle_split.FOUR):
				Em.compass.S:
					Character.animate("aSP1[d]Startup")
				_:
					Character.animate("aSP1[b]Startup")
		"aSP1[b]Startup":
			Character.animate("aSP1[c1]Startup")
		"aSP1[c1]Startup":
			Character.animate("aSP1[c1]bStartup")
		"aSP1[c1]bStartup":
			Character.animate("aSP1[c1]Active")
		"aSP1[c1]Active":
			Character.animate("aSP1Rec")
		"aSP1Rec":
			Character.unsummon()
			
		"aSP1[d]Startup":
			Character.animate("aSP1[d][c1]Startup")
		"aSP1[d][c1]Startup":
			Character.animate("aSP1[d][c1]bStartup")
		"aSP1[d][c1]bStartup":
			Character.animate("aSP1[d][c1]Active")
		"aSP1[d][c1]Active":
			Character.animate("aSP1Rec")

		"SP9Startup":
			Character.animate("SP9Active")
		"SP9Active":
			Character.animate("SP9aStartup")
			
		"SP9aStartup":
			Character.animate("aSP9aActive")
		"aSP9aActive":
			if Character.is_on_ground():
				Character.animate("SP9aRec")
			else:
				Character.animate("aSP9aRec")
		"SP9aRec", "aSP9aRec":
			Character.unsummon()
			

func _on_SpritePlayer_anim_started(anim_name):

	match anim_name:
			
		"aSP1Startup", "aSP1[b]Startup", "aSP1[d]Startup":
			Character.velocity_limiter.x_slow = 20
			Character.velocity_limiter.y_slow = 20
			Character.anim_gravity_mod = 0
		"aSP1[c1]Startup", "aSP1[c1]bStartup", "aSP1[d][c1]Startup", "aSP1[d][c1]bStartup":
			Character.velocity_limiter.x = 20
			Character.velocity_limiter.down = 20
		"SP1[c1]Active": # spawn projectile at EntitySpawn
			Character.velocity.x += Character.facing * FMath.percent(Character.get_stat("SPEED"), 50)
			Globals.Game.spawn_entity(Character.master_ID, "TridentProjA", Animator.query_point("entityspawn"), {"facing": Character.facing}, \
					Character.palette_ref, Character.NPC_ref)
			Globals.Game.spawn_SFX("SpecialDust", "DustClouds", Character.get_feet_pos(), {"facing":Character.facing, "grounded":true})
		"SP1[u][c1]Active": # spawn projectile at EntitySpawn
			Character.velocity.x += Character.facing * FMath.percent(Character.get_stat("SPEED"), 50)
			Globals.Game.spawn_entity(Character.master_ID, "TridentProjA", Animator.query_point("entityspawn"), {"facing": Character.facing, \
					"alt_aim" : true}, Character.palette_ref, Character.NPC_ref)
			Globals.Game.spawn_SFX("SpecialDust", "DustClouds", Character.get_feet_pos(), {"facing":Character.facing, "grounded":true})
		"aSP1[c1]Active":
			Globals.Game.spawn_entity(Character.master_ID, "TridentProjA", \
					Animator.query_point("entityspawn"), {"facing": Character.facing, "aerial" : true}, \
					Character.palette_ref, Character.NPC_ref)
		"aSP1[d][c1]Active":
			Globals.Game.spawn_entity(Character.master_ID, "TridentProjA", \
					Animator.query_point("entityspawn"), {"facing": Character.facing, "aerial" : true, "alt_aim" : true}, \
					Character.palette_ref, Character.NPC_ref)

		"aSP1Rec":
			Character.velocity_limiter.x = 70
			Character.velocity_limiter.down = 70
			
		"SP9Active":
			Character.velocity.x = 800 * FMath.S * Character.facing
			Character.anim_friction_mod = 0
			Globals.Game.spawn_SFX("WaterBurst", "WaterBurst", Character.get_feet_pos(), \
					{"facing":-Character.facing}, Character.palette_ref, Character.NPC_ref)
		"SP9aStartup":
			Character.velocity.x = FMath.percent(Character.velocity.x, 50)
			Character.anim_gravity_mod = 0
			Character.anim_friction_mod = 0
		"aSP9aActive":
			Character.velocity.set_vector(Character.facing * 500 * FMath.S, 0)
			Character.anim_gravity_mod = 0
			Character.anim_friction_mod = 0
			Globals.Game.spawn_SFX("WaterJet", "WaterJet", Animator.query_point("sfxspawn"), {"facing":Character.facing}, \
					Character.palette_ref, Character.NPC_ref)
					
	start_audio(anim_name)


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

