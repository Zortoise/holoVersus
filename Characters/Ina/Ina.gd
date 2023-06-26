extends "res://Characters/Ina/InaBase.gd"

# Steps to add an attack:
# 1. Add it in MOVE_DATABASE and STARTERS, also in EX_MOVES/SUPERS, and in UP_TILTS if needed (even for EX Moves)
# 2. Add it in state_detect()
# 3. Add it in _on_SpritePlayer_anim_finished() to set the transitions
# 4. Add it in _on_SpritePlayer_anim_started() to set up entity/sfx spawning and other physics modifying characteristics
# 6. Add it in capture_combinations() if it is a special action
# 5. Add it in process_buffered_input() for inputs
# 7. Add any startup/recovery animations not in MOVE_DATABASE to refine_move_name()
# 8. Add any active frame versions not in MOVE_DATABASE in get_root() for aerial and chain memory
	
# Steps to add auto-sequences:
# 1. Add final Sequence Steps and steps with damage into MOVE_DATABASE
# 2. Add Sequence Steps and GrabRec animations into state_detect()
# 3. Add Sequence Steps in _on_SpritePlayer_anim_finished() to set the transitions, place "end_sequence_step()" in last/branching steps
# 4. Add Sequence Steps in _on_SpritePlayer_anim_started(), place "start_sequence_step()" on each step
# 5. Add initial actions for each Step in start_sequence_step()
# 6. Add frame-by-frame events and physics (gravity, air res) in simulate_sequence()
# 7. Add frame-by-frame movement for the opponent in simulate_sequence_after() as "move_sequence_target(grab_point)" and "rotate_partner(Partner)"
# 8. Add final Steps and branching Steps in end_sequence_step(), for final Step place in "Partner.sequence_launch()" there
# 9. Add GrabRec animations into refine_move_name()
# 10. For hitgrabs, add the conditions in UniqChar.landed_a_hit()
	
# --------------------------------------------------------------------------------------------------

# shortening code, set by main character node
onready var Character = get_parent()
var Animator
var sprite
var uniqueHUD

func _ready():
	get_node("TestSprite").free() # test sprite is for sizing collision box

	
# STATE_DETECT --------------------------------------------------------------------------------------------------

func state_detect(anim): # for unique animations, continued from state_detect() of main character node
	match anim:
		_:
			pass
		
	print("Error: " + anim + " not found.")
		
func check_collidable():  # some characters have move that can pass through other characters
	match Character.new_state:
		_:
			pass
	return true
	
func check_semi_invuln():
	match Character.new_state:
		_:
			pass
	return false

# UNIQUE INPUT CAPTURE --------------------------------------------------------------------------------------------------
# some holdable buttons can have effect unique to the character
	
func simulate():
	
#	Character.input_state
#	Character.dir
#	Character.v_dir

	# LAND CANCEL --------------------------------------------------------------------------------------------------
	
	# RELEASING HELD INPUTS --------------------------------------------------------------------------------------------------

	match Character.state:
		
		_:
			pass
					

	# DASH DANCING --------------------------------------------------------------------------------------------------
			
#	if Character.state == Em.char_state.GROUND_C_REC and Animator.to_play_anim == "DashBrake": 	# dash dancing
#		match Character.facing:
#			1:
#				if Character.dir == -1:
#					Character.face(-1)
#					Character.animate("Dash")
#			-1:
#				if  Character.dir == 1:
#					Character.face(1)
#					Character.animate("Dash")


# SPECIAL ACTIONS --------------------------------------------------------------------------------------------------


func capture_combinations():
	
	Character.combination(Character.button_up, Character.button_light, "uL")
	Character.combination(Character.button_down, Character.button_light, "dL")
	Character.combination(Character.button_up, Character.button_fierce, "uF")
	Character.combination(Character.button_down, Character.button_fierce, "dF")
	Character.combination(Character.button_light, Character.button_fierce, "H")
	
	Character.combination(Character.button_special, Character.button_light, "Sp.L")
	Character.ex_combination(Character.button_special, Character.button_light, "ExSp.L")
	
	Character.combination(Character.button_special, Character.button_fierce, "Sp.F")
	Character.ex_combination(Character.button_special, Character.button_fierce, "ExSp.F")
	
	Character.combination_trio(Character.button_special, Character.button_up, Character.button_fierce, "Sp.uF")
	Character.ex_combination_trio(Character.button_special, Character.button_up, Character.button_fierce, "ExSp.uF")
	
	Character.ex_combination_trio(Character.button_special, Character.button_down, Character.button_fierce, "ExSp.dF")
	
	Character.combination_trio(Character.button_special, Character.button_light, Character.button_fierce, "Sp.H")
	Character.ex_combination_trio(Character.button_special, Character.button_light, Character.button_fierce, "ExSp.H")
	
#	Character.doubletap_combination(Character.button_special, Character.button_fierce, "SpSp.F")

func capture_unique_combinations():
	Character.combination_trio(Character.button_unique, Character.button_down, Character.button_fierce, "U.dF")

func rebuffer_actions(): # for when there are air and ground versions
	Character.rebuffer(Character.button_up, Character.button_light, "uL")
	Character.rebuffer(Character.button_down, Character.button_light, "dL")
	Character.rebuffer(Character.button_up, Character.button_fierce, "uF")
	Character.rebuffer(Character.button_down, Character.button_fierce, "dF")
	Character.rebuffer(Character.button_light, Character.button_fierce, "H")
	
#	Character.rebuffer(Character.button_special, Character.button_light, "Sp.L")
#	Character.rebuffer(Character.button_special, Character.button_fierce, "Sp.F")
#	Character.rebuffer_trio(Character.button_special, Character.button_up, Character.button_fierce, "Sp.uF")
#	Character.rebuffer_trio(Character.button_special, Character.button_light, Character.button_fierce, "Sp.H")
	
func rebuffer_EX(): # only rebuffer EX moves on release of up/down
	Character.ex_rebuffer(Character.button_special, Character.button_light, "ExSp.L")
	Character.ex_rebuffer(Character.button_special, Character.button_fierce, "ExSp.F")
	
func capture_instant_actions():
	pass

func process_instant_actions():
	pass


# INPUT BUFFER --------------------------------------------------------------------------------------------------

# called by main character node
func process_buffered_input(new_state, buffered_input, input_to_add, has_acted: Array):
	var keep = true
	match buffered_input[0]:
		
		Character.button_dash:
			if !has_acted[0]:
				match new_state:
					
				# GROUND DASH ---------------------------------------------------------------------------------
			
					Em.char_state.GROUND_STANDBY, Em.char_state.GROUND_C_REC:
						if !Character.button_light in Character.input_state.just_pressed and \
								!Character.button_fierce in Character.input_state.just_pressed:
							if !Animator.query(["DashBrake", "WaveDashBrake"]):
								# cannot dash during dash brake
								Character.animate("DashTransit")
								keep = false
							else: # during dash brake, can continue dash backwards, limited dash dancing
								if Character.dir == -Character.facing:
									Character.face(Character.dir)
									Character.animate("Dash")
									keep = false
								elif Character.instant_dir == -Character.facing:
									Character.face(Character.instant_dir)
									Character.animate("Dash")
									keep = false
							
#					Em.char_state.GROUND_D_REC:
						
							
				# AIR DASH ---------------------------------------------------------------------------------
					
					Em.char_state.AIR_STANDBY, Em.char_state.AIR_C_REC:
						
						if Animator.query(["aDashBrake"]) and !Character.has_trait(Em.trait.AIR_CHAIN_DASH):
							continue
						
						if Character.air_dash > 0:
							
							if Character.v_dir > 0 and Character.button_jump in Character.input_state.pressed and \
									Character.is_button_tapped_in_last_X_frames(Character.button_jump, 1) and \
									Character.check_snap_up() and \
									Character.snap_up(): # for easy wavedashing on soft platforms
								# cannot snap up if jump is pressed more than 1 frame ago, to allow easier down dash after fallthrough
								
								Character.animate("JumpTransit") # if snapping up while falling downward, instantly wavedash
								input_to_add.append([Character.button_dash, Settings.input_buffer_time[Character.player_ID]])
										
							else: # not in snap range
								Character.animate("aDashTransit")
								if Animator.query_current(["JumpTransit2"]): # if starting an air dash on the 1st frame after a ground jump
									Character.velocity.y = FMath.percent(Character.velocity.y, 50)
							keep = false
							
					Em.char_state.AIR_STARTUP: # cancel start of air jump into air dash, used for up-dashes
						if Animator.query(["aJumpTransit", "WallJumpTransit", "aJumpTransit2", "WallJumpTransit2"]):
							if Character.air_dash > 0:
								Character.animate("aDashTransit")
								keep = false

								
				# DASH CANCELS ---------------------------------------------------------------------------------
					# if land a sweetspot hit, can dash cancel on active
								
					Em.char_state.GROUND_ATK_REC:
						if Character.test_dash_cancel():
							Character.animate("DashTransit")
							keep = false
					
					Em.char_state.GROUND_ATK_ACTIVE:
						if Character.active_cancel:
							Character.afterimage_cancel() # need to do this manually for active cancel
							Character.animate("DashTransit")
							keep = false
							
					Em.char_state.AIR_ATK_REC:
						if Character.test_dash_cancel():
							if !Character.grounded:
								Character.animate("aDashTransit")
								keep = false
							else: # grounded
								Character.animate("DashTransit")
								keep = false
					
					Em.char_state.AIR_ATK_ACTIVE:
						if Character.active_cancel:
							if !Character.grounded:
								if Character.air_dash > 0:
									Character.afterimage_cancel() # need to do this manually for active cancel
									Character.animate("aDashTransit")
									keep = false
							else: # grounded
								Character.afterimage_cancel() # need to do this manually for active cancel
								Character.animate("DashTransit")
								keep = false
							
		# ---------------------------------------------------------------------------------
		
		Character.button_light:
			if !has_acted[0]:
				if Character.test_rekka("SP9Active"):
					keep = !process_move(new_state, "SP9d", has_acted)
				else:
					keep = !process_move(new_state, "L1", has_acted)
		
		Character.button_fierce:
			if !has_acted[0]:
				if Character.test_rekka("SP9Active"):
					keep = !process_move(new_state, "SP9a", has_acted)
				elif Character.test_rekka("aSP9cRec"):
					keep = !process_move(new_state, "SP9c[r]", has_acted)
				else:
					keep = !process_move(new_state, "F1", has_acted)
					

		# SPECIAL ACTIONS ---------------------------------------------------------------------------------
		# buffered_input_action can be a string instead of int, for heavy attacks and special moves

		"uL":
			if !has_acted[0]:
				keep = !process_move(new_state, "L3", has_acted)
				
		"dL":
			if !has_acted[0]:
				keep = !process_move(new_state, "L2", has_acted)

		"uF":
			if !has_acted[0]:
				keep = !process_move(new_state, "F3", has_acted)
				
		"dF":
			if !has_acted[0]:
				keep = !process_move(new_state, "F2", has_acted)
				
		"H":
			if !has_acted[0]:
				keep = !process_move(new_state, "H", has_acted)
				
#		"Sp.L":
#			if !has_acted[0]:
#				keep = !process_move(new_state, "SP1", has_acted)
#
#		"Sp.F":
#			if !has_acted[0]:
#				keep = !process_move(new_state, "SP2", has_acted)
						
#		"Sp.uF":
#			if !has_acted[0]:
#				keep = !process_move(new_state, "SP3", has_acted)
#
#		"Sp.H":
#			if !has_acted[0]:
#				keep = !process_move(new_state, "SP5", has_acted)
				
#		"ExSp.L":
#			if !has_acted[0]:
#				keep = !process_move(new_state, "SP1[ex]", has_acted)
#				if keep:
#					keep = !process_move(new_state, "SP1", has_acted)

#		"ExSp.F":
#			if !has_acted[0]:
#				keep = !process_move(new_state, "SP2[ex]", has_acted)
#				if keep:
#					keep = !process_move(new_state, "SP2", has_acted)
							
#		"ExSp.uF":
#			if !has_acted[0]:
#				keep = !process_move(new_state, "SP3[ex]", has_acted)
#				if keep:
#					keep = !process_move(new_state, "SP3", has_acted)
#
#		"ExSp.H":
#			if !has_acted[0]:
#				keep = !process_move(new_state, "SP5[ex]", has_acted)
#				if keep:
#					keep = !process_move(new_state, "SP5", has_acted)
						
		# ---------------------------------------------------------------------------------
		
		"InstaAirDash": # needed to chain wavedashes
			match new_state:
				Em.char_state.GROUND_STANDBY, Em.char_state.GROUND_C_REC:
					Character.animate("JumpTransit")
					input_to_add.append([Character.button_dash, Settings.input_buffer_time[Character.player_ID]])
					has_acted[0] = true
					keep = false

	
	# ---------------------------------------------------------------------------------
	
	return keep # return true to keep buffered_input, false to remove buffered_input
	# no need to return input_to_add since array is passed by reference

	
func process_move(new_state, attack_ref: String, has_acted: Array): # return true if button consumed
	
	 # no attacking during respawn grace
	if Character.query_status_effect(Em.status_effect.RESPAWN_GRACE):
		if Globals.survival_level != null and Inventory.has_quirk(Character.player_ID, Cards.effect_ref.RESPAWN_POWER):
			pass
		else:
			return true
	
	if Character.grounded and Character.button_jump in Character.input_state.pressed:
		return false # since this will trigger instant aerial
	
	
	match new_state:
			
		Em.char_state.GROUND_STANDBY, Em.char_state.GROUND_C_REC, Em.char_state.GROUND_D_REC:
			if Character.grounded and attack_ref in STARTERS:
				if new_state in [Em.char_state.GROUND_C_REC, Em.char_state.GROUND_D_REC] and \
						!Animator.query_to_play(["SoftLanding"]) and \
						Em.atk_attr.NOT_FROM_MOVE_REC in query_atk_attr(attack_ref):
					continue # certain moves cannot be performed during cancellable recovery
				if !Character.test_dash_attack(attack_ref):
					continue # if dash attacking, cannot use attacks already used in the chain
				if Character.is_ex_valid(attack_ref):
					Character.animate(attack_ref + "Startup")
					has_acted[0] = true
					return true
					
		Em.char_state.GROUND_STARTUP: # grounded up-tilt can be done during ground jump transit if jump is not pressed
			if Settings.input_assist[Character.player_ID]:
				if Character.grounded and attack_ref in UP_TILTS and Animator.query_to_play(["JumpTransit"]) and \
						Character.test_qc_chain_combo(attack_ref):
					if Character.is_ex_valid(attack_ref):
						Character.animate(attack_ref + "Startup")
						has_acted[0] = true
						return true
					
		Em.char_state.AIR_STANDBY, Em.char_state.AIR_C_REC, Em.char_state.AIR_D_REC:
			if !Character.grounded: # must be currently not grounded even if next state is still considered an aerial state
				if ("a" + attack_ref) in STARTERS and Character.test_aerial_memory("a" + attack_ref):
					if new_state in [Em.char_state.AIR_C_REC, Em.char_state.AIR_D_REC] and \
							Em.atk_attr.NOT_FROM_MOVE_REC in query_atk_attr("a" + attack_ref):
						continue # certain moves cannot be performed during cancellable recovery
					if !Character.test_dash_attack("a" + attack_ref):
						continue # if dash attacking, cannot use attacks already used in the chain
					if Character.is_ex_valid("a" + attack_ref):
						Character.animate("a" + attack_ref + "Startup")
						has_acted[0] = true
						return true
						
		Em.char_state.AIR_STARTUP: # aerial up-tilt can be done during air jump transit if jump is not pressed
			if Settings.input_assist[Character.player_ID]:
				if ("a" + attack_ref) in UP_TILTS and Character.test_aerial_memory("a" + attack_ref) and \
						!Character.button_jump in Character.input_state.pressed and \
						Animator.query_to_play(["aJumpTransit", "aJumpTransit2", "WallJumpTransit", "WallJumpTransit2"]) and \
						Character.test_qc_chain_combo("a" + attack_ref):
					if Character.is_ex_valid("a" + attack_ref):
						Character.animate("a" + attack_ref + "Startup")
						has_acted[0] = true
						return true
				
		# chain cancel
		Em.char_state.GROUND_ATK_REC, Em.char_state.GROUND_ATK_ACTIVE:
			if attack_ref in STARTERS:
				if Character.test_chain_combo(attack_ref):
					if Character.is_ex_valid(attack_ref):
#						if buffer_time == Settings.input_buffer_time[Character.player_ID] and Animator.time == 0:
#							Character.get_node("ModulatePlayer").play("unflinch_flash")
#							Character.perfect_chain = true
							
						Character.animate(attack_ref + "Startup")
						has_acted[0] = true
						return true
			
		# quick cancel
		Em.char_state.GROUND_ATK_STARTUP:
			if Settings.input_assist[Character.player_ID]:
				if Character.grounded and attack_ref in STARTERS:
					if Character.check_quick_cancel(attack_ref): # must be within 1st frame, animation name must be in MOVE_DATABASE
						if Character.test_qc_chain_combo(attack_ref):
							if Character.is_ex_valid(attack_ref, true):
								Character.animate(attack_ref + "Startup")
								has_acted[0] = true
								return true
					
		# chain cancel
		Em.char_state.AIR_ATK_REC, Em.char_state.AIR_ATK_ACTIVE:
			if !Character.grounded:
				if ("a" + attack_ref) in STARTERS and Character.test_aerial_memory("a" + attack_ref):
					if Character.test_chain_combo("a" + attack_ref):
						if Character.is_ex_valid("a" + attack_ref):
#							if buffer_time == Settings.input_buffer_time[Character.player_ID] and Animator.time == 0:
#								Character.get_node("ModulatePlayer").play("unflinch_flash")
#								Character.perfect_chain = true
							Character.animate("a" + attack_ref + "Startup")
							has_acted[0] = true
							return true
							
			else:
				if attack_ref in STARTERS:
					if Character.test_chain_combo(attack_ref): # grounded
						if Character.is_ex_valid(attack_ref):
#							if buffer_time == Settings.input_buffer_time[Character.player_ID] and Animator.time == 0:
#								Character.get_node("ModulatePlayer").play("unflinch_flash")
#								Character.perfect_chain = true
							Character.animate(attack_ref + "Startup")
							has_acted[0] = true
							return true
							
		# quick cancel
		Em.char_state.AIR_ATK_STARTUP:
			if Settings.input_assist[Character.player_ID]:
				if !Character.grounded:
					if ("a" + attack_ref) in STARTERS and Character.test_aerial_memory("a" + attack_ref):
						if Character.check_quick_cancel("a" + attack_ref):
							if Character.test_qc_chain_combo("a" + attack_ref):
								if Character.is_ex_valid("a" + attack_ref, true):
									Character.animate("a" + attack_ref + "Startup")
									has_acted[0] = true
									return true
				else:
					if attack_ref in STARTERS:
						if Character.check_quick_cancel(attack_ref):
							if Character.test_qc_chain_combo(attack_ref):
								if Character.is_ex_valid(attack_ref, true):
									Character.animate(attack_ref + "Startup")
									has_acted[0] = true
									return true
									
	return false
						
			
						
func consume_one_air_dash(): # different characters can have different types of air_dash consumption
	Character.air_dash = max(Character.air_dash - 1, 0)
	
#func gain_one_air_dash(): # different characters can have different types of air_dash consumption
#	if Character.air_dash < Character.get_stat("MAX_AIR_DASH"): # cannot go over
#		Character.air_dash += 1

func afterimage_trail():# process afterimage trail
	match Animator.to_play_anim:
		"SDashTransit", "SDash", "aSDash":
			Character.afterimage_trail()
		"Dodge":
			Character.afterimage_trail(null, 0.6, 10, Em.afterimage_shader.WHITE)
		"DodgeRec", "DodgeCRec":
			Character.afterimage_trail()
			
func unique_flash():
	match Animator.to_play_anim:
		_:
			pass
			
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
		_:
			pass
			
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
#		move_data[Em.move.DMG] = FMath.percent(move_data[Em.move.DMG], Character.SURV_BASE_DMG)
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
		
	return atk_attr
	

# HIT REACTIONS --------------------------------------------------------------------------------------------------

func landed_a_hit(hit_data): # reaction, can change hit_data from here
	
	match hit_data[Em.hit.MOVE_NAME]:
		_:
			pass
			

func being_hit(hit_data):
#	var defender = get_node(hit_data.defender_nodepath)
					
	if hit_data[Em.hit.BLOCK_STATE] in [Em.block_state.UNBLOCKED]:
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
#		seq_hit_data[Em.move.DMG] = FMath.percent(seq_hit_data[Em.move.DMG], Character.SURV_BASE_DMG)	
		seq_hit_data[Em.move.DMG] = FMath.percent(seq_hit_data[Em.move.DMG], Character.mod_damage(MOVE_DATABASE[Animator.to_play_anim][Em.move.STARTER]))

	return seq_hit_data
	
	
	
func get_seq_launch_data():
	var seq_data = MOVE_DATABASE[Animator.to_play_anim][Em.move.SEQ_LAUNCH].duplicate(true)

	if Globals.survival_level != null and Em.move.DMG in seq_data:
#		seq_data[Em.move.DMG] = FMath.percent(seq_data[Em.move.DMG], Character.SURV_BASE_DMG)	
		seq_data[Em.move.DMG] = FMath.percent(seq_data[Em.move.DMG], Character.mod_damage(MOVE_DATABASE[Animator.to_play_anim][Em.move.STARTER]))

	return seq_data
			
			
			
func sequence_fallthrough(): # which step in sequence ignore soft platforms
#	match Animator.to_play_anim:
#		_:
#			pass
	return false
	
func sequence_ledgestop(): # which step in sequence are stopped by ledges
	return false
	
func sequence_passthrough(): # which step in sequence ignore all platforms (for cinematic supers)
	return false
	
func sequence_partner_passthrough(): # which step in sequence has partner ignore all platforms
	return false
	
#func sequence_passfloor(): # which step in sequence ignore hard floor
#	match Animator.to_play_anim:
#		"SP6[ex]SeqA", "SP6[ex]SeqB", "SP6[ex]SeqC":
#			return true
#	return false
	
	
# CODE FOR CERTAIN MOVES ---------------------------------------------------------------------------------------------------

	
func unique_chaining_rules(_move_name, _attack_ref):
#	move_name = refine_move_name(move_name)
#	var attack_name = refine_move_name(attack_ref)
	
#	match Character.new_state:
#		_:
#			pass
				
	return false
	


# ANIMATION AND AUDIO PROCESSING ---------------------------------------------------------------------------------------------------
# these are ran by main character node when it gets the signals so that the order is easier to control

func _on_SpritePlayer_anim_finished(anim_name):
	
	match anim_name:
		"DashTransit":
			Character.animate("Dash")
		"Dash":
			if Character.held_version(Character.button_dash):
				Character.animate("Dash2")
			else:
				Character.animate("DashBrake")
		"Dash2":
			Character.animate("DashBrake")
		"DashBrake", "WaveDashBrake":
			Character.animate("Idle")
		"aDashTransit":
#			if Character.air_dash > 1:
#				if Character.button_down in Character.input_state.pressed and Character.dir != 0: # downward air dash
##					Character.face(Character.dir)
#					Character.animate("aDashD")
#				elif Character.button_up in Character.input_state.pressed and Character.dir != 0: # upward air dash
##					Character.face(Character.dir)
#					Character.animate("aDashU")
#				elif Character.button_down in Character.input_state.pressed: # downward air dash
#					Character.animate("AirDashDD")
#				elif Character.button_up in Character.input_state.pressed: # upward air dash
#					Character.animate("AirDashUU")
#				else: # horizontal air dash
#					Character.animate("aDash")
#			else:
			if Character.v_dir == 1: # downward air dash
				if !Character.snap_up_wave_land_check():
					Character.animate("aDashD")
			elif Character.v_dir == -1: # upward air dash
				Character.animate("aDashU")
			else: # horizontal air dash
				Character.animate("aDash")
#		"aDash", "aDashD", "aDashU", "AirDashUU", "AirDashDD", "AirDashD2", "AirDashU2":
		"aDash", "aDashD", "aDashU":
			Character.animate("aDashBrake")
		"aDashBrake":
			Character.animate("Fall")
			

func _on_SpritePlayer_anim_started(anim_name):

	match anim_name:
		"Run":
			var point = Character.get_feet_pos()
			point.x -= Character.facing * 5 # move back a bit
			Globals.Game.spawn_SFX("RunDust", "DustClouds", point, {"facing":Character.facing, "grounded":true})
		"aDashTransit":
			if Character.button_down in Character.input_state.pressed:
				Character.velocity.y = 0 # for faster wavedashes
#			Character.velocity_limiter.y_slow = 75
		"Dash":
			Character.velocity.x = Character.get_stat("GROUND_DASH_SPEED") * Character.facing
			Character.anim_friction_mod = 0
			Character.afterimage_timer = 1 # sync afterimage trail
			Globals.Game.spawn_SFX( "GroundDashDust", "DustClouds", Character.get_feet_pos(), \
				{"facing":Character.facing, "grounded":true})
		"Dash2":
			Character.anim_friction_mod = 0
			Character.afterimage_timer = 1 # sync afterimage trail
		"aDash":
			consume_one_air_dash()
			Character.aerial_memory = []
			Character.velocity.set_vector(Character.get_stat("AIR_DASH_SPEED") * Character.facing, 0)
			Character.anim_gravity_mod = 0
			Character.afterimage_timer = 1 # sync afterimage trail
			Globals.Game.spawn_SFX( "AirDashDust", "DustClouds", Character.position, {"facing":Character.facing})
		"aDashD":
			consume_one_air_dash()
			Character.aerial_memory = []
			Character.velocity.set_vector(Character.get_stat("AIR_DASH_SPEED") * Character.facing, 0)
			Character.velocity.rotate(26 * Character.facing)
			Character.anim_gravity_mod = 0
			Character.afterimage_timer = 1 # sync afterimage trail
			Globals.Game.spawn_SFX( "AirDashDust", "DustClouds", Character.position, {"facing":Character.facing, "rot":PI/7})
		"aDashU":
			consume_one_air_dash()
			Character.aerial_memory = []
			Character.velocity.set_vector(Character.get_stat("AIR_DASH_SPEED") * Character.facing, 0)
			Character.velocity.rotate(-26 * Character.facing)
			Character.anim_gravity_mod = 0
			Character.afterimage_timer = 1 # sync afterimage trail
			Globals.Game.spawn_SFX( "AirDashDust", "DustClouds", Character.position, {"facing":Character.facing, "rot":-PI/7})
			
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
			_:
				pass
	
	match anim_name:
		"JumpTransit2", "WallJumpTransit2":
			Character.play_audio("jump1", {"bus":"PitchDown"})
		"aJumpTransit2":
			Character.play_audio("jump1", {"vol":-2})
		"SoftLanding", "HardLanding", "BlockLanding":
			if Character.velocity_previous_frame.y > 0:
				landing_sound()
		"LaunchTransit":
			if Character.grounded and abs(Character.velocity.y) < 1 * FMath.S:
				Character.play_audio("launch2", {"vol" : -3, "bus":"LowPass"})
			else:
				Character.play_audio("launch1", {"vol":-15, "bus":"PitchDown"})
		"Dash":
			dash_sound()
		"aDash", "aDashD", "aDashU":
			Character.play_audio("dash1", {"vol" : -6})
		"SDash":
			Character.play_audio("dash1", {"vol" : -6})
			Character.play_audio("launch1", {"vol" : -11})

			
		


func landing_sound(): # can be called by main node
	Character.play_audio("land1", {"vol" : -3})
	
func dash_sound(): # can be called by snap-up wavelanding
	Character.play_audio("dash1", {"vol" : -5, "bus":"PitchDown"})


func stagger_anim():
	
	match Animator.current_anim:
		_:
			pass
					
					
