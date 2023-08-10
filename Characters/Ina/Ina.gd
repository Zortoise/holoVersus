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
		
		"BlinkTransit", "EBlinkTransit":
			return Em.char_state.AIR_STARTUP
		"Blink", "EBlink":
			return Em.char_state.AIR_REC
		"BlinkRec", "EBlinkRec":
			return Em.char_state.GRD_D_REC
		"aBlinkRec", "aEBlinkRec":
			return Em.char_state.AIR_D_REC
		"BlinkCRec":
			return Em.char_state.GRD_C_REC
		"aBlinkCRec":
			return Em.char_state.AIR_C_REC
			
		"FloatTransit":
			return Em.char_state.AIR_STARTUP
		"Float", "FFloatTransit", "FFloat", "FloatBrake", "FloatRec":
			return Em.char_state.AIR_D_REC
			
		"L1Startup":
			return Em.char_state.GRD_ATK_STARTUP
		"L1Active":
			return Em.char_state.GRD_ATK_ACTIVE
		"L1Rec":
			return Em.char_state.GRD_ATK_REC
			
		"L2Startup":
			return Em.char_state.GRD_ATK_STARTUP
		"L2bStartup":
			return Em.char_state.AIR_ATK_STARTUP
		"L2Active":
			return Em.char_state.AIR_ATK_ACTIVE
		"L2Rec":
			return Em.char_state.AIR_ATK_REC
			
		"L3Startup":
			return Em.char_state.GRD_ATK_STARTUP
		"L3Active":
			return Em.char_state.GRD_ATK_ACTIVE
		"L3Rec":
			return Em.char_state.GRD_ATK_REC
			
		"F1Startup":
			return Em.char_state.GRD_ATK_STARTUP
		"F1Active", "F1[u]Active", "F1[d]Active", "F1[h]Active", "F1[h][u]Active", "F1[h][d]Active":
			return Em.char_state.GRD_ATK_ACTIVE
		"F1Rec":
			return Em.char_state.GRD_ATK_REC
			
		"F2Startup":
			return Em.char_state.GRD_ATK_STARTUP
		"F2Active", "F2[u]Active", "F2[d]Active":
			return Em.char_state.GRD_ATK_ACTIVE
		"F2Rec":
			return Em.char_state.GRD_ATK_REC
			
		"F3Startup":
			return Em.char_state.GRD_ATK_STARTUP
		"F3Active", "F3[u]Active", "F3[d]Active":
			return Em.char_state.GRD_ATK_ACTIVE
		"F3Rec":
			return Em.char_state.GRD_ATK_REC
		"F3CRec":
			return Em.char_state.GRD_C_REC
			
		"HStartup":
			return Em.char_state.GRD_ATK_STARTUP
		"HActive":
			return Em.char_state.GRD_ATK_ACTIVE
		"HRec":
			return Em.char_state.GRD_ATK_REC
			
		"aL1Startup":
			return Em.char_state.AIR_ATK_STARTUP
		"aL1Active":
			return Em.char_state.AIR_ATK_ACTIVE
		"aL1Rec":
			return Em.char_state.AIR_ATK_REC
			
		"aL2Startup":
			return Em.char_state.AIR_ATK_STARTUP
		"aL2Active":
			return Em.char_state.AIR_ATK_ACTIVE
		"aL2Rec":
			return Em.char_state.AIR_ATK_REC
			
		"aL3Startup":
			return Em.char_state.AIR_ATK_STARTUP
		"aL3Active":
			return Em.char_state.AIR_ATK_ACTIVE
		"aL3Rec":
			return Em.char_state.AIR_ATK_REC
			
		"aF1Startup":
			return Em.char_state.AIR_ATK_STARTUP
		"aF1Active", "aF1[u]Active", "aF1[d]Active", "aF1[h]Active", "aF1[h][u]Active", "aF1[h][d]Active":
			return Em.char_state.AIR_ATK_ACTIVE
		"aF1Rec":
			return Em.char_state.AIR_ATK_REC
			
		"aF2Startup":
			return Em.char_state.AIR_ATK_STARTUP
		"aF2Active", "aF2[u]Active", "aF2[d]Active":
			return Em.char_state.AIR_ATK_ACTIVE
		"aF2Rec":
			return Em.char_state.AIR_ATK_REC
			
		"aF3Startup":
			return Em.char_state.AIR_ATK_STARTUP
		"aF3Active", "aF3[u]Active", "aF3[d]Active":
			return Em.char_state.AIR_ATK_ACTIVE
		"aF3Rec":
			return Em.char_state.AIR_ATK_REC
			
		"aHStartup":
			return Em.char_state.AIR_ATK_STARTUP
		"aHActive":
			return Em.char_state.AIR_ATK_ACTIVE
		"aHRec":
			return Em.char_state.AIR_ATK_REC
			
		
	print("Error: " + anim + " not found.")
	
func check_jc_d_rec(): # some D_REC can be jump cancelled
	match Character.new_state:
		Em.char_state.AIR_D_REC:
			if Animator.query_to_play(["aBlinkRec", "aEBlinkRec"]):
				return true
				
	return false
		
func check_collidable():  # some characters have move that can pass through other characters
	match Character.new_state:
		Em.char_state.AIR_REC:
			if Animator.query_to_play(["Blink", "EBlink"]):
				return false
	return true
	
func check_fallthrough():
	match Character.new_state:
		Em.char_state.AIR_REC:
			if Animator.query_to_play(["Blink", "EBlink"]):
				return true
		Em.char_state.AIR_D_REC:
			if Animator.query_to_play(["Float", "FFloatTransit", "FFloat", "FloatBrake"]):
				return true
#		Em.char_state.AIR_ATK_ACTIVE:
#			if Animator.query_to_play(["aHActive"]):
#				return true
	return false
	
func check_semi_invuln():
	match Character.new_state:
		_:
			pass
	return false

func check_quick_turn(): # some unique character states cannot be quick turned
	if Character.state == Em.char_state.AIR_STARTUP and Animator.current_anim == "EBlinkTransit":
		return false
	return true

func punishable(): # some unique character states are punishable
	match Character.new_state:
		Em.char_state.AIR_STARTUP:
			if Animator.query_to_play(["BlinkTransit", "EBlinkTransit"]):
				return true
		Em.char_state.AIR_REC:
			if Animator.query_to_play(["Blink", "EBlink"]):
				return true
	return false
				

# UNIQUE INPUT CAPTURE --------------------------------------------------------------------------------------------------
# some holdable buttons can have effect unique to the character
	
func simulate():
	
#	Character.input_state
#	Character.dir
#	Character.v_dir

	if Character.grounded:
		Character.unique_data.float_used = false

	# FLOAT --------------------------------------------------------------------------------------------------

	match Character.state:
		Em.char_state.AIR_D_REC:
			if Animator.query_current(["Float", "FFloat", "FFloatTransit", "FloatBrake"]):
				
				if Character.button_jump in Character.input_state.just_pressed or (Character.grounded and !Character.soft_grounded) or \
						Character.unique_data.float_time <= 0: # unfloat
					Character.animate("FloatRec")
				else:
					Character.unique_data.float_time -= 1
					
					var float_vec = get_float_vec()
					
					match Animator.current_anim: # turning and changing animations
						"Float", "FloatBrake":
							if Character.dir != 0:
								Character.face(Character.dir)
								Character.animate("FFloatTransit")
						"FFloat", "FFloatTransit":
							if Character.dir == 0:
								Character.animate("FloatBrake")
							elif Character.facing != Character.dir:
								Character.face(Character.dir)
								Character.animate("FFloatTransit")
								
					if float_vec.x != 0:
						Character.velocity.x = FMath.f_lerp(Character.velocity.x, float_vec.x, 3)
					if float_vec.y != 0:
						Character.velocity.y = FMath.f_lerp(Character.velocity.y, float_vec.y, 10)
						
						
		Em.char_state.AIR_ATK_ACTIVE: # aH 8-way strafe
			if Animator.query_current(["aHActive"]):
				var strafe_vec = FVector.new()
				strafe_vec.set_vector(0, 0)
					
				if Character.dir != 0:
					strafe_vec.x = Character.dir * FMath.percent(Character.get_stat("SPEED"), 5)
					if Character.v_dir != 0:
						strafe_vec.x = FMath.percent(strafe_vec.x, 71) # *0.707
				
				if Character.v_dir != 0:
					strafe_vec.y = Character.v_dir * FMath.percent(Character.get_stat("SPEED"), 5)
					if Character.dir != 0:
						strafe_vec.y = FMath.percent(strafe_vec.y, 71) # *0.707
						
				Character.velocity.x += strafe_vec.x
				Character.velocity.y += strafe_vec.y
				

	# EASIER BLINKS --------------------------------------------------------------------------------------------------

		Em.char_state.AIR_STARTUP:
			if Animator.time == 8 and Animator.query_current(["BlinkTransit"]):
				Character.unique_data.blink_vec.x = Character.dir
				Character.unique_data.blink_vec.y = Character.v_dir
		
	# VACUUM EFFECT --------------------------------------------------------------------------------------------------
			
		Em.char_state.GRD_ATK_ACTIVE:
			if Animator.query_current(["HActive"]):
				vortex()

	# LAND CANCEL --------------------------------------------------------------------------------------------------
	
	# RELEASING HELD INPUTS --------------------------------------------------------------------------------------------------

	match Character.state:
		
		_:
			pass
					

	# DASH DANCING --------------------------------------------------------------------------------------------------
			
#	if Character.state == Em.char_state.GRD_C_REC and Animator.to_play_anim == "DashBrake": 	# dash dancing
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
	
	Character.combination(Character.button_special, Character.button_dash, "Float")
	
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
	
	pass
#	Character.combination(Character.button_unique, Character.button_jump, "Float")


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
func process_buffered_input(new_state, buffered_input, _input_to_add, has_acted: Array):
	var keep = true
	match buffered_input[0]:
		
		Character.button_dash:
			if !has_acted[0]:
				if Character.button_light in Character.input_state.pressed or \
						Character.button_fierce in Character.input_state.pressed:
					continue
				
				match new_state:
					
				# GROUND BLINK ---------------------------------------------------------------------------------
			
					Em.char_state.GRD_STANDBY, Em.char_state.GRD_C_REC:
						Character.animate("BlinkTransit")
						keep = false
						
					Em.char_state.GRD_STARTUP: # cancel start of ground jump into blink, used for up-blinks
						if Animator.query(["JumpTransit"]):
							Character.animate("BlinkTransit")
							keep = false
						
				# AIR BLINK ---------------------------------------------------------------------------------
					
					Em.char_state.AIR_STANDBY, Em.char_state.AIR_C_REC:
							
						if Character.grounded: # for AIR_C_REC
							Character.animate("BlinkTransit")
							keep = false
							
						if Character.air_dash > 0:
							Character.animate("BlinkTransit")
							keep = false
							
					Em.char_state.AIR_STARTUP: # cancel start of air jump into blink, used for up-blinks
						if Animator.query_to_play(["aJumpTransit", "WallJumpTransit", "aJumpTransit2", "WallJumpTransit2"]):
							if Character.air_dash > 0:
								Character.animate("BlinkTransit")
								keep = false

				# ECHO BLINK ---------------------------------------------------------------------------------
				
					Em.char_state.GRD_D_REC, Em.char_state.AIR_D_REC:
						if Animator.query_to_play(["BlinkRec", "aBlinkRec"]):
							Character.animate("EBlinkTransit")
							keep = false
							
						elif new_state == Em.char_state.AIR_D_REC and \
								Animator.query_to_play(["Float", "FFloat", "FFloatTransit", "FloatBrake"]): # from float
							if Character.air_dash > 0:
								Character.animate("BlinkTransit")
								keep = false
						
								
				# DASH CANCELS ---------------------------------------------------------------------------------
					# if land a sweetspot hit, can dash cancel on active
								
					Em.char_state.GRD_ATK_REC:
						if Character.test_dash_cancel():
							Character.animate("BlinkTransit")
							keep = false
					
					Em.char_state.GRD_ATK_ACTIVE:
						if Character.active_cancel:
							Character.afterimage_cancel() # need to do this manually for active cancel
							Character.animate("BlinkTransit")
							keep = false
							
					Em.char_state.AIR_ATK_REC:
						if Character.test_dash_cancel():
							Character.animate("BlinkTransit")
							keep = false
					
					Em.char_state.AIR_ATK_ACTIVE:
						if Character.active_cancel:
							if !Character.grounded:
								if Character.air_dash > 0:
									Character.afterimage_cancel() # need to do this manually for active cancel
									Character.animate("BlinkTransit")
									keep = false
							else: # grounded
								Character.afterimage_cancel() # need to do this manually for active cancel
								Character.animate("BlinkTransit")
								keep = false
							
		"Float":
			if !has_acted[0]:
				if !Character.unique_data.float_used:
					match new_state:
						
						Em.char_state.AIR_STANDBY, Em.char_state.AIR_C_REC, Em.char_state.AIR_D_REC, \
								Em.char_state.GRD_STANDBY, Em.char_state.GRD_C_REC, Em.char_state.GRD_D_REC:
							Character.animate("FloatTransit")
							keep = false
								
						Em.char_state.AIR_STARTUP: # cancel start of blink into float
							if Animator.query_to_play(["BlinkTransit"]):
								Character.animate("FloatTransit")
								keep = false
#
#						Em.char_state.GRD_STARTUP: # cancel start of jump into float
#							if Animator.query_to_play(["JumpTransit"]):
#								Character.animate("FloatTransit")
#								keep = false
								
						Em.char_state.AIR_ATK_REC, Em.char_state.GRD_ATK_REC: # float cancel normals
							if Character.is_normal_or_heavy(Character.get_move_name()):
								Character.animate("FloatTransit")
								keep = false
								Character.afterimage_cancel()
								
						Em.char_state.AIR_ATK_ACTIVE, Em.char_state.GRD_ATK_ACTIVE: # float cancel landed normals during active
							if Character.chain_combo in [Em.chain_combo.NORMAL, Em.chain_combo.BLOCKED] and \
									Character.is_normal_attack(Character.get_move_name()):
								Character.animate("FloatTransit")
								keep = false
								Character.afterimage_cancel()
							
	#					Em.char_state.GRD_STANDBY, Em.char_state.GRD_C_REC: # ground instant float
	#						Character.animate("JumpTransit")
	#						input_to_add.append(["uJump", Settings.input_buffer_time[Character.player_ID]])
	#						keep = false
							
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
#
#		"InstaAirDash": # needed to chain wavedashes
#			match new_state:
#				Em.char_state.GRD_STANDBY, Em.char_state.GRD_C_REC:
#					Character.animate("JumpTransit")
#					input_to_add.append([Character.button_dash, Settings.input_buffer_time[Character.player_ID]])
#					has_acted[0] = true
#					keep = false

	
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
			
		Em.char_state.GRD_STANDBY, Em.char_state.GRD_C_REC, Em.char_state.GRD_D_REC, Em.char_state.AIR_C_REC:
			if new_state == Em.char_state.AIR_C_REC and !Character.grounded: continue
			
			if Character.grounded and attack_ref in STARTERS:
				if new_state in [Em.char_state.GRD_C_REC, Em.char_state.GRD_D_REC, Em.char_state.AIR_C_REC] and \
						!Animator.query_to_play(["SoftLanding"]) and \
						Em.atk_attr.NOT_FROM_MOVE_REC in query_atk_attr(attack_ref):
					continue # certain moves cannot be performed during cancellable recovery
				if !Character.test_dash_attack(attack_ref):
					continue # if dash attacking, cannot use attacks already used in the chain
				if Character.is_ex_valid(attack_ref):
					Character.animate(attack_ref + "Startup")
					has_acted[0] = true
					return true
					
		Em.char_state.GRD_STARTUP: # grounded up-tilt can be done during ground jump transit if jump is not pressed
			if Settings.input_assist[Character.player_ID]:
				if !Character.no_jumpsquat_cancel and Character.grounded and attack_ref in UP_TILTS and \
						Animator.query_to_play(["JumpTransit"]) and Character.test_qc_chain_combo(attack_ref):
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
				if !Character.no_jumpsquat_cancel and ("a" + attack_ref) in UP_TILTS and Character.test_aerial_memory("a" + attack_ref) and \
						!Character.button_jump in Character.input_state.pressed and \
						Animator.query_to_play(["aJumpTransit", "aJumpTransit2", "WallJumpTransit", "WallJumpTransit2"]) and \
						Character.test_qc_chain_combo("a" + attack_ref):
					if Character.is_ex_valid("a" + attack_ref):
						Character.animate("a" + attack_ref + "Startup")
						has_acted[0] = true
						return true
				
		# chain cancel
		Em.char_state.GRD_ATK_REC, Em.char_state.GRD_ATK_ACTIVE:
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
		Em.char_state.GRD_ATK_STARTUP:
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
	match Character.new_state:
		Em.char_state.AIR_STARTUP:
			if Animator.query_to_play(["SDashTransit"]):
				Character.afterimage_trail()
		Em.char_state.AIR_REC:
			if Animator.query_to_play(["SDash", "DodgeRec"]):
				Character.afterimage_trail()
			if Animator.query_to_play(["Dodge"]):
				Character.afterimage_trail(null, 0.6, 10, Em.afterimage_shader.WHITE)
		Em.char_state.AIR_D_REC:
			if Animator.query_to_play(["Float", "FFloat", "FFloatTransit", "FloatBrake"]):
				Character.afterimage_trail(Color(0,0,0), 0.6, 10)
		Em.char_state.AIR_ATK_ACTIVE:
			if Animator.query_to_play(["aHActive"]):
				if posmod(Animator.time, 2) == 0:
					Globals.Game.spawn_afterimage(Character.player_ID, Em.afterimage_type.CHAR, Character.sprite_texture_ref.sfx_over, \
							Character.sfx_over.get_path(), Character.palette_number, NAME, Color(0,0,0), 0.5, 12)


			
func unique_flash():
	match Character.new_state:
		Em.char_state.AIR_REC:
			if Animator.query_to_play(["SDash"]):
				Character.particle("Sparkle", "Particles", Character.get_default_hitspark_palette(), 4, 1, 25)
			
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
		"L2b":
			return "L2"
		"F1[u]", "F1[d]", "F1[h]", "F1[h][u]", "F1[h][d]":
			return "F1"
		"F2[u]", "F2[d]":
			return "F2"
		"F3[u]", "F3[d]":
			return "F3"
		"aF1[u]", "aF1[d]", "aF1[h]", "aF1[h][u]", "aF1[h][d]":
			return "aF1"
		"aF2[u]", "aF2[d]":
			return "aF2"
		"aF3[u]", "aF3[d]":
			return "aF3"
			
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
		"F1[u]", "F1[h][u]", "F2[u]", "F3[u]", "aF1[u]", "aF1[h][u]", "aF2[u]", "aF3[u]":
			move_data[Em.move.KB_ANGLE] -= 15
		"F1[d]", "F1[h][d]", "F2[d]", "F3[d]", "aF1[d]", "aF1[h][d]", "aF3[d]":
			move_data[Em.move.KB_ANGLE] += 15
		"aF2[d]":
			move_data[Em.move.KB_ANGLE] = 125
			
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

#func landed_a_hit0(hit_data): # reaction, can change hit_data from here
#
#	match hit_data[Em.hit.MOVE_NAME]:
#		_:
##			hit_data[Em.hit.SOUR_HIT] = true
##			hit_data[Em.hit.SWEETSPOTTED] = false
#
#			pass
			

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
	
func get_float_vec():
	var float_vec = FVector.new()
	float_vec.set_vector(0, 0)
	
	if Character.dir == 0 and Character.v_dir == 0: return float_vec
	
	if Character.dir != 0:
		float_vec.x = Character.dir * FMath.percent(Character.get_stat("SPEED"), 420)
		if Character.v_dir != 0:
			float_vec.x = FMath.percent(float_vec.x, 71) # *0.707
	
	if Character.v_dir != 0:
		float_vec.y = Character.v_dir * FMath.percent(Character.get_stat("SPEED"), 50)
		if Character.dir != 0:
			float_vec.y = FMath.percent(float_vec.y, 71) # *0.707
			
	return float_vec
	
	
func get_target_height():
	var target = Character.get_target()
	if target == Character: return 0
	
	return target.position.y - Character.position.y
	
func get_target_dist_f3():
	var target = Character.get_target()
	if target == Character: return 0
	
	return Character.facing * (target.position.x - (Character.position.x + Character.facing * 31))
	
func get_target_angle(atk_angle):
	
#	var atk_angle = -37
	
	var target = Character.get_target()
	if target == Character: return 0
	
	var fvec = FVector.new()
	fvec.set_from_vec(target.position - Character.position)
	var angle = fvec.angle()

	if Character.facing == -1: angle = 180 - angle # flip over
	if angle > 180: angle = -(360 - angle) # set to negative if over 180
	
	var angle_diff = angle - atk_angle
	if angle_diff < -50 or angle_diff > 50:
		return 0 # neutral, out of cone
	elif angle_diff < -12:
		return -1 # upward
	elif angle_diff > 12:
		return 1 # downward
	else:
		return 0 # neutral
	
	# F2 is -37 degrees, +/- 14 degrees, 53 degree limit
	# aF2 is 65 degrees, aF3 is -65 degrees
	
func vortex():
	
	var vortex_point = Character.position # vortex origin is above
	vortex_point.y -= 58
	
	var max_hitcount = MOVE_DATABASE["H"][Em.move.HITCOUNT] # opponents who took all hits will not be sucked in
	
	var nodes
	if Globals.survival_level == null:
		nodes = get_tree().get_nodes_in_group("PlayerNodes")
	else:
		nodes = get_tree().get_nodes_in_group("MobNodes")
	
	for node in nodes:
		if node != Character and Character.get_hitcount(node.player_ID) < max_hitcount:
			
			var repeated := false
			for array in node.repeat_memory:
				if array[0] == Character.player_ID and array[1] == "H":
					repeated = true # no suction if already used once
					break
			if repeated: break
			
			var fvec = FVector.new()
			fvec.set_from_vec(vortex_point - node.position)
			if !fvec.is_longer_than(120 * FMath.S): # radius of suction
				var force: int
				if node.state == Em.char_state.LAUNCHED_HITSTUN:
					force = 500 * FMath.S
				else:
					force = 250 * FMath.S
					
				node.gravity_frame_mod = 0
				
#				if !node.grounded or node.get_feet_pos().y < Character.get_feet_pos().y:
					# grounded enemies same level or below experience no horizontal suction
				if node.position.x > vortex_point.x: # target is right side
					if node.velocity.x > -force:
						node.velocity.x = int(max(-force, node.velocity.x - force))
				elif node.position.x < vortex_point.x: # target is left side
					if node.velocity.x < force:
						node.velocity.x = int(min(force, node.velocity.x + force))
						
#				if !node.grounded: # grounded opponent experience no vertical suction
				if node.position.y > vortex_point.y: # target is below
					if node.velocity.y > -force:
						node.velocity.y = int(max(-force, node.velocity.y - force))
				elif node.position.y < vortex_point.y: # target is above
					if node.velocity.y < force:
						node.velocity.y = int(min(force, node.velocity.y + force))
				
	

# ANIMATION AND AUDIO PROCESSING ---------------------------------------------------------------------------------------------------
# these are ran by main character node when it gets the signals so that the order is easier to control

func _on_SpritePlayer_anim_finished(anim_name):
	
	match anim_name:
		"BlinkTransit":
			Character.animate("Blink")
		"Blink":
			if Character.is_on_ground():
				Character.animate("BlinkRec")
			else:
				Character.animate("aBlinkRec")
			Character.status_effect_to_add.append([Em.status_effect.NO_CROSSUP, 20])
		"BlinkRec":
			Character.animate("BlinkCRec")
		"aBlinkRec":
			Character.animate("aBlinkCRec")
		"BlinkCRec":
			Character.animate("Idle")
		"aBlinkCRec":
			Character.animate("Fall")
			
		"EBlinkTransit":
			Character.animate("EBlink")
		"EBlink":
			if Character.is_on_ground():
				Character.animate("EBlinkRec")
			else:
				Character.animate("aEBlinkRec")
			Character.status_effect_to_add.append([Em.status_effect.NO_CROSSUP, 20])
		"EBlinkRec":
			Character.animate("BlinkCRec")
		"aEBlinkRec":
			Character.animate("aBlinkCRec")
		
		"FloatTransit", "FloatBrake":
			Character.animate("Float")
		"FFloatTransit":
			Character.animate("FFloat")
		"FloatRec":
			if Character.is_on_ground():
				Character.animate("Idle")
			else:
				Character.animate("Fall")
			
		"DashBrake", "WaveDashBrake":
			Character.animate("Idle")
		"aDashBrake":
			Character.animate("Fall")
			
		"L1Startup":
			Character.animate("L1Active")
		"L1Active":
			Character.animate("L1Rec")
		"L1Rec":
			Character.animate("Idle")
			
		"L2Startup":
			Character.animate("L2bStartup")
		"L2bStartup":
			Character.animate("L2Active")
		"L2Active":
			Character.animate("L2Rec")
		"L2Rec":
			Character.animate("Fall")
			
		"L3Startup":
			Character.animate("L3Active")
		"L3Active":
			Character.animate("L3Rec")
		"L3Rec":
			Character.animate("Idle")
			
		"F1Startup":
			if Character.held_version(Character.button_fierce):
				var height_diff = get_target_height()
				if height_diff > 28:
					Character.animate("F1[h][d]Active")
				elif height_diff < -28:
					Character.animate("F1[h][u]Active")
				else:
					Character.animate("F1[h]Active")
			else:
				var height_diff = get_target_height()
				if height_diff > 28:
					Character.animate("F1[d]Active")
				elif height_diff < -28:
					Character.animate("F1[u]Active")
				else:
					Character.animate("F1Active")
		"F1Active", "F1[u]Active", "F1[d]Active", "F1[h]Active", "F1[h][u]Active", "F1[h][d]Active":
			Character.animate("F1Rec")
		"F1Rec":
			Character.animate("Idle")
			
		"F2Startup":
			match get_target_angle(-37):
				0:
					Character.animate("F2Active")
				1:
					Character.animate("F2[d]Active")
				-1:
					Character.animate("F2[u]Active")
		"F2Active", "F2[u]Active", "F2[d]Active":
			Character.animate("F2Rec")
		"F2Rec":
			Character.animate("Idle")
			
		"F3Startup":
			var target_dist = get_target_dist_f3()
			if target_dist > 18:
				Character.animate("F3[d]Active")
			elif target_dist < -18:
				Character.animate("F3[u]Active")
			else:
				Character.animate("F3Active")
		"F3Active", "F3[u]Active", "F3[d]Active":
			Character.animate("F3Rec")
		"F3Rec":
			Character.animate("F3CRec")
		"F3CRec":
			Character.animate("Idle")
			
		"HStartup":
			Character.animate("HActive")
		"HActive":
			Character.animate("HRec")
		"HRec":
			Character.animate("Idle")
			
		"aL1Startup":
			Character.animate("aL1Active")
		"aL1Active":
			Character.animate("aL1Rec")
		"aL1Rec":
			Character.animate("FallTransit")
			
		"aL2Startup":
			Character.animate("aL2Active")
		"aL2Active":
			Character.animate("aL2Rec")
		"aL2Rec":
			Character.animate("FallTransit")
			
		"aL3Startup":
			Character.animate("aL3Active")
		"aL3Active":
			Character.animate("aL3Rec")
		"aL3Rec":
			Character.animate("FallTransit")
			
		"aF1Startup":
			if Character.held_version(Character.button_fierce):
				var height_diff = get_target_height()
				if height_diff > 28:
					Character.animate("aF1[h][d]Active")
				elif height_diff < -28:
					Character.animate("aF1[h][u]Active")
				else:
					Character.animate("aF1[h]Active")
			else:
				var height_diff = get_target_height()
				if height_diff > 28:
					Character.animate("aF1[d]Active")
				elif height_diff < -28:
					Character.animate("aF1[u]Active")
				else:
					Character.animate("aF1Active")
		"aF1Active", "aF1[u]Active", "aF1[d]Active", "aF1[h]Active", "aF1[h][u]Active", "aF1[h][d]Active":
			Character.animate("aF1Rec")
		"aF1Rec":
			Character.animate("FallTransit")
			
		"aF2Startup":
			match get_target_angle(65):
				0:
					Character.animate("aF2Active")
				1:
					Character.animate("aF2[d]Active")
				-1:
					Character.animate("aF2[u]Active")
		"aF2Active", "aF2[u]Active", "aF2[d]Active":
			Character.animate("aF2Rec")
		"aF2Rec":
			Character.animate("FallTransit")
			
		"aF3Startup":
			match get_target_angle(-65):
				0:
					Character.animate("aF3Active")
				1:
					Character.animate("aF3[d]Active")
				-1:
					Character.animate("aF3[u]Active")
		"aF3Active", "aF3[u]Active", "aF3[d]Active":
			Character.animate("aF3Rec")
		"aF3Rec":
			Character.animate("FallTransit")
			
		"aHStartup":
			Character.animate("aHActive")
		"aHActive":
			Character.animate("aHRec")
		"aHRec":
			Character.animate("FallTransit")
				

func _on_SpritePlayer_anim_started(anim_name):

	match anim_name:
		"Run":
			var point = Character.get_feet_pos()
			point.x -= Character.facing * 5 # move back a bit
			Globals.Game.spawn_SFX("RunDust", "DustClouds", point, {"facing":Character.facing, "grounded":true})

		"BlinkTransit", "EBlinkTransit":
			Character.anim_gravity_mod = 0
			Character.anim_friction_mod = 0
			Character.velocity_limiter.x_slow = 15
			Character.velocity_limiter.y_slow = 15
		"Blink", "EBlink":
			consume_one_air_dash()
			Character.afterimage_cancel()
			Character.aerial_memory = []
			Character.anim_gravity_mod = 0
			Character.velocity.set_vector(0, 0)
			var vector := FVector.new()
			var blink_dist := int(max(GRD_DASH_SPEED, AIR_DASH_SPEED))
			vector.set_vector(blink_dist, 0)
			var y_direction : int = 0
			var x_direction : int = 0
			match anim_name:
				"Blink":
					y_direction = Character.unique_data.blink_vec.y
					x_direction = Character.unique_data.blink_vec.x
				"EBlink":
					y_direction = Character.v_dir
					x_direction = Character.dir
			match y_direction:
				1: # down
					if x_direction == 0: # straight down
						vector.y = vector.x
						vector.x = 0
					else:
						vector.rotate(45)
				-1: # up
					if x_direction == 0: # straight up
						vector.y = -vector.x
						vector.x = 0
					else:
						vector.rotate(-45)
			if x_direction != 0: # left/right
				vector.x *= x_direction
			else:
				vector.x *= Character.facing # not pressing left/right
			Globals.Game.spawn_SFX("Blink", "Blink", Character.position, {"facing":Globals.Game.rng_facing()}, Character.palette_number, NAME)
			Character.move_amount(vector.convert_to_vec())
			Character.set_true_position()
			Globals.Game.spawn_SFX("Blink", "Blink", Character.position, {"facing":Globals.Game.rng_facing()}, Character.palette_number, NAME)
			Character.play_audio("energy8", {"vol": -25, "bus":"PitchDown"})
			Character.play_audio("bling8", {"vol": -15, "bus":"PitchUp"})
		"aBlinkRec", "aEBlinkRec":
			Character.anim_gravity_mod = 0
		"aBlinkCRec":
			Character.anim_gravity_mod = 50
			
		"FloatTransit":
			Character.anim_gravity_mod = 0
			Character.anim_friction_mod = 0
			Character.velocity_limiter.y_slow = 10
			Character.aerial_memory = []
			Character.chain_memory = []
			Character.spent_special = true
			if !Character.is_on_ground():
				Character.velocity.y = FMath.percent(Character.velocity.y, 20)
			else:
				Globals.Game.spawn_SFX("JumpDust", "DustClouds", Character.get_feet_pos(), {"facing":Character.facing, "grounded":true})
				Character.velocity.y = -100 * FMath.S # if grounded, float up a bit
			
			Character.unique_data.float_used = true
			var feet_point = Character.get_feet_pos().y
			if feet_point >= Globals.Game.middle_point.y:
				Character.unique_data.float_time = UNIQUE_DATA_REF.float_time
			else: # the higher you are the less time to float
				var max_dist: int = Globals.Game.middle_point.y - Globals.Game.stage_box.rect_global_position.y
				var char_dist: int = int(min(abs(Globals.Game.middle_point.y - feet_point), max_dist))
				var weight = FMath.get_fraction_percent(char_dist, max_dist)
				Character.unique_data.float_time = FMath.f_lerp(UNIQUE_DATA_REF.float_time, 0, weight)
			Character.play_audio("buff1", {"vol": -20, "bus":"PitchDown2"})
			Character.play_audio("bling1", {"vol": -15, "bus":"PitchDown2"})
		"Float":
			Character.anim_gravity_mod = 0
			Character.velocity_limiter.x_slow = 5
			Character.velocity_limiter.y_slow = 5
		"FFloat", "FFloatTransit", "FloatBrake":
			Character.anim_gravity_mod = 0
			Character.velocity_limiter.x_slow = 5
			Character.velocity_limiter.y_slow = 5
		"FloatRec":
			Character.anim_gravity_mod = 50
			
		"L1Startup", "L2Startup", "L3Startup", "F1Startup", "F2Startup", "F3Startup", "HStartup":
			Character.anim_friction_mod = 300
		"L2bStartup":
			Character.anim_gravity_mod = 0
			Character.velocity.y = -200 * FMath.S
			Globals.Game.spawn_SFX("JumpDust", "DustClouds", Character.get_feet_pos(), {"facing":Character.facing, "grounded":true})
			Character.play_audio("jump1", {"bus":"PitchDown"})
		"L2Active":
			Character.anim_gravity_mod = 0
			Character.velocity.set_vector(400 * FMath.S * -Character.facing, 0)
			Character.velocity.rotate(-45 * -Character.facing)
			
		"F1Active", "F1[u]Active", "F1[d]Active", "F1[h]Active", "F1[h][u]Active", "F1[h][d]Active", \
				"F2Active", "F2[u]Active", "F2[d]Active", "F3Active", "F3[u]Active", "F3[d]Active":
			Character.velocity.x = 0
			Character.velocity_limiter.x = 0
			
		"HActive":
			Character.velocity.x = 0
			Character.velocity_limiter.x = 0

		"aL1Startup", "aL1Active", "aL2Startup", "aL2Active", "aL3Startup", "aL3Active", "aF1Startup", "aF2Startup", "aF3Startup", "aHStartup":
			Character.velocity_limiter.x_slow = 20
			Character.velocity_limiter.y_slow = 20
			Character.anim_gravity_mod = 0
		"aL1Rec", "aL2Rec", "aL3Rec", "aF1Rec", "aF2Rec", "aF3Rec", "aHRec":
			Character.velocity_limiter.x = 70
			Character.velocity_limiter.down = 70
			
		"aF1Active", "aF1[u]Active", "aF1[d]Active", "aF1[h]Active", "aF1[h][u]Active", "aF1[h][d]Active", \
				"aF2Active", "aF2[u]Active", "aF2[d]Active", "aF3Active", "aF3[u]Active", "aF3[d]Active":
			Character.velocity.x = 0
			Character.velocity.y = 0
			Character.velocity_limiter.x = 0
			Character.velocity_limiter.down = 0
			Character.velocity_limiter.up = 0
			Character.anim_gravity_mod = 0
			
		"aHActive":
			Character.velocity_limiter.x = 50
			Character.velocity_limiter.down = 50
			Character.velocity_limiter.up = 50
			Character.velocity_limiter.x_slow = 5
			Character.velocity_limiter.y_slow = 5
			Character.anim_gravity_mod = 0

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
	
	match Character.state:
		Em.char_state.AIR_STARTUP:
			match anim_name:
				"JumpTransit2", "WallJumpTransit2":
					Character.play_audio("jump1", {"bus":"PitchDown"})
				"aJumpTransit2":
					Character.play_audio("jump1", {"vol":-2})
		Em.char_state.GRD_C_REC:
			match anim_name:
				"SoftLanding", "HardLanding":
					if Character.velocity_previous_frame.y > 0:
						landing_sound()	
		Em.char_state.GRD_BLOCK:
			match anim_name:
				"BlockLanding":
					if Character.velocity_previous_frame.y > 0:
						landing_sound()	
		Em.char_state.AIR_REC:
			match anim_name:
				"SDash":
					Character.play_audio("dash1", {"vol" : -6})
					Character.play_audio("launch1", {"vol" : -11})
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
					
					
