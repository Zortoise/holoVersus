extends "res://Characters/Gura/GuraBase.gd"

const STYLE = 0

# UNIQUE INPUT CAPTURE --------------------------------------------------------------------------------------------------
# some holdable buttons can have effect unique to the character
	
func stimulate():
	
#	Character.input_state
#	Character.dir
#	Character.v_dir
	
	# quick impulse
	if Character.new_state == Globals.char_state.GROUND_ATK_STARTUP and Character.dir != 0 and !Character.impulse_used and\
			(Character.button_left in Character.input_state.just_pressed or \
			Character.button_right in Character.input_state.just_pressed) and \
			Animator.time <= Character.QUICK_CANCEL_TIME and Animator.time != 0:
		var move_name = Animator.to_play_animation.trim_suffix("Startup")
		if move_name in MOVE_DATABASE:
			if !Globals.atk_attr.NO_IMPULSE in MOVE_DATABASE[move_name].atk_attr: # ground impulse
				Character.velocity.x = Character.dir * SPEED
				Character.impulse_used = true
	
	if Character.state == Globals.char_state.AIR_ATK_ACTIVE and Animator.query(["aL2Active"]):
		if Character.grounded:
			Character.animate("HardLanding")
		elif !Character.button_light in Character.input_state.pressed:
			Character.animate("aL2bRecovery")
			
	# dash dancing
	if Character.state == Globals.char_state.GROUND_RECOVERY and Animator.query(["Dash"]):
		if Character.button_left in Character.input_state.just_pressed and !Character.button_right in Character.input_state.just_pressed:
			Character.face(-1)
			Character.animate("Dash")
		elif Character.button_right in Character.input_state.just_pressed and !Character.button_left in Character.input_state.just_pressed:
			Character.face(1)
			Character.animate("Dash")
			
			
#	if Character.button_dash in Character.input_state.just_pressed and Character.state == Globals.char_state.GROUND_C_RECOVERY and \
#			Animator.time <= 1:
#		Character.animate("DashTransit")
		
			
	# QUICK CANCELS --------------------------------------------------------------------------------------------------
	
	if Character.check_quick_cancel():
		
		if Character.button_up in Character.input_state.just_pressed:
			if Animator.query(["F1Startup"]) and Character.test_qc_chain_combo("F3"):
				Character.animate("F3Startup")
			elif Animator.query(["aF1Startup"]) and Character.test_qc_chain_combo("aF3"):
				Character.animate("aF3Startup")
				
		if Character.button_up in Character.input_state.just_released:
			if Animator.query(["F3Startup"]) and Character.test_qc_chain_combo("F1"):
				Character.animate("F1Startup")
			elif Animator.query(["aF3Startup"]) and Character.test_qc_chain_combo("aF1"):
				Character.animate("aF1Startup")
				
		if Character.button_down in Character.input_state.just_pressed:
			if Animator.query(["F1Startup"]) and Character.test_qc_chain_combo("F2"):
				Character.animate("F2Startup")
			elif Animator.query(["L1Startup"]) and Character.test_qc_chain_combo("L2"):
				Character.animate("L2Startup")
			elif Animator.query(["aL1Startup"]) and Character.test_qc_chain_combo("aL2"):
				Character.animate("aL2Startup")
				
		if Character.button_down in Character.input_state.just_released:
			if Animator.query(["F2Startup"]) and Character.test_qc_chain_combo("F1"):
				Character.animate("F1Startup")
			elif Animator.query(["L2Startup"]) and Character.test_qc_chain_combo("L1"):
				Character.animate("L1Startup")
			elif Animator.query(["aL2Startup"]) and Character.test_qc_chain_combo("aL1"):
				Character.animate("aL1Startup")				
				
		if Character.button_fierce in Character.input_state.just_pressed:
			if Animator.query(["L1Startup", "L2Startup"]) and Character.test_qc_chain_combo("H"):
				Character.animate("HStartup")
			elif Animator.query(["aL1Startup", "aL2Startup"]) and Character.test_qc_chain_combo("aH"):
				Character.animate("aHStartup")
		
		if Character.button_light in Character.input_state.just_pressed:
			if Animator.query(["F1Startup", "F2Startup", "F3Startup"]) and Character.test_qc_chain_combo("H"):
				Character.animate("HStartup")
			elif Animator.query(["aF1Startup", "aF3Startup"]) and Character.test_qc_chain_combo("aH"):
				Character.animate("aHStartup")

# SPECIAL ACTIONS --------------------------------------------------------------------------------------------------


func capture_combinations():
	
	Character.combination(Character.button_up, Character.button_fierce, "UpFierce") # can quick_cancel from light/fierce startup	
	
	# Heavy Normal, place this after UpFierce
	Character.combination(Character.button_light, Character.button_fierce, "H") # can quick_cancel from light/fierce startup

	# Command Normals

	if Character.get_node("SpecialTimer").is_running():
		# insert Specials here
		# also have InstaJumpAct Specials
		pass
	elif Character.get_node("EXTimer").is_running():
		# insert EX Moves here
		# also have InstaJumpAct EX Moves
		pass
	elif Character.get_node("SuperTimer").is_running():
		# insert Supers here
		# also have InstaJumpAct Supers
		pass


# INPUT BUFFER --------------------------------------------------------------------------------------------------

# called by main character node
func process_buffered_input(new_state, buffered_input, input_to_add, has_acted: Array):
	var keep = true
	match buffered_input[0]:
		
		Character.button_dash:
			match new_state:
				
			# GROUND DASH ---------------------------------------------------------------------------------
		
				Globals.char_state.GROUND_STANDBY, Globals.char_state.CROUCHING, Globals.char_state.GROUND_C_RECOVERY:
					if keep and !Animator.query(["DashBrake"]): # cannot dash during dash brake
						Character.animate("DashTransit")
						keep = false
						
			# AIR DASH ---------------------------------------------------------------------------------
				
				Globals.char_state.AIR_STANDBY, Globals.char_state.AIR_C_RECOVERY:
					if Character.air_dash > 0 or Character.get_node("HitStunGraceTimer").is_running():
						if Character.button_down in Character.input_state.pressed and Character.check_snap_up():
							
							if Character.velocity_previous_frame.y < 0: # moving upward
								Character.snap_up(Character.get_node("PlayerCollisionBox"), Character.get_node("DashLandDBox"))
#								if Character.dir != 0:
#									Character.face(Character.dir)
								Character.animate("AirDashD2") # snap up waveland if going upward, landing check will change it to brake later
#								else:
#									Character.animate("AirDashDD") 
							elif Animator.time == 0: # moving downward and within 1st frame of falling, for easy wavedashing on soft platforms
								Character.snap_up(Character.get_node("PlayerCollisionBox"), Character.get_node("DashLandDBox"))
								Character.animate("JumpTransit") # if snapping up while falling downward, instantly wavedash
								input_to_add.append([Character.button_dash, Settings.input_buffer_time[Character.player_ID]])
								
							else: # moving downward and in place of snap up but too late
								Character.animate("AirDashTransit") # for dropping down and air dashing ASAP
						else:
							Character.animate("AirDashTransit")
						keep = false
						
				Globals.char_state.AIR_STARTUP: # cancel start of air jump into air dash
					if Animator.query(["AirJumpTransit", "WallJumpTransit", "AirJumpTransit2", "WallJumpTransit2"]):
						if Character.air_dash > 0:
							Character.animate("AirDashTransit")
							keep = false
							
			# DASH CANCELS ---------------------------------------------------------------------------------
				# if land a sweetspot hit, can dash cancel afterward
							
				Globals.char_state.GROUND_ATK_RECOVERY:
					if Character.test_dash_cancel():
						Character.animate("DashTransit")
						keep = false
				
				Globals.char_state.GROUND_ATK_ACTIVE:
					if Character.dash_cancel:
						Character.animate("DashTransit")
						keep = false
						
				Globals.char_state.AIR_ATK_RECOVERY:
					if Character.test_dash_cancel():
						if !Character.grounded:
							Character.animate("AirDashTransit")
							keep = false
						else: # grounded
							Character.animate("DashTransit")
							keep = false
				
				Globals.char_state.AIR_ATK_ACTIVE:
					if Character.dash_cancel:
						if !Character.grounded:
							if Character.air_dash > 0:
								Character.animate("AirDashTransit")
								keep = false
						else: # grounded
							Character.animate("DashTransit")
							keep = false
		
		# ---------------------------------------------------------------------------------
		
		Character.button_light:
			if !has_acted[0]:
				if Character.button_down in Character.input_state.pressed:
					keep = !process_button(new_state, "L2", has_acted, buffered_input[1])
				if keep:
					keep = !process_button(new_state, "L1", has_acted, buffered_input[1])
		
		Character.button_fierce:
			if !has_acted[0]:
				if Character.button_up in Character.input_state.pressed:
					keep = !process_button(new_state, "F3", has_acted, buffered_input[1]) # need to do this too for more consistency
				elif Character.button_down in Character.input_state.pressed:
					keep = !process_button(new_state, "F2", has_acted, buffered_input[1])
				if keep:
					keep = !process_button(new_state, "F1", has_acted, buffered_input[1])


		# SPECIAL ACTIONS ---------------------------------------------------------------------------------
		# buffered_input_action can be a string instead of int, for heavy attacks and special moves

		"UpFierce":
			if !has_acted[0]:
				keep = !process_button(new_state, "F3", has_acted, buffered_input[1])
				
		"H":
			if !has_acted[0]:
				keep = !process_button(new_state, "H", has_acted, buffered_input[1])
		
		"InstaAirDash": # needed to chain wavedashes
			match new_state:
				Globals.char_state.GROUND_STANDBY, Globals.char_state.CROUCHING, Globals.char_state.GROUND_C_RECOVERY:
					Character.animate("JumpTransit")
					input_to_add.append([Character.button_dash, Settings.input_buffer_time[Character.player_ID]])
					has_acted[0] = true
					keep = false
				Globals.char_state.GROUND_STARTUP:
					Character.animate("JumpTransit")
					input_to_add.append([Character.button_dash, Settings.input_buffer_time[Character.player_ID]])
					has_acted[0] = true
					keep = false

	
	# ---------------------------------------------------------------------------------
	
	return keep # return true to keep buffered_input, false to remove buffered_input
	# no need to return input_to_add since array is passed by reference


func process_button(new_state, attack_ref: String, has_acted: Array, buffer_time): # return true if button consumed
	match new_state:
			
			Globals.char_state.GROUND_STANDBY, Globals.char_state.CROUCHING, Globals.char_state.GROUND_C_RECOVERY:
				if attack_ref in MOVE_DATABASE:
					Character.animate(attack_ref + "Startup")
					Character.chain_memory = []
					has_acted[0] = true
					return true
				
			Globals.char_state.GROUND_STARTUP:
				if Character.button_up in Character.input_state.pressed and !Character.button_jump in Character.input_state.pressed and \
						Animator.query(["JumpTransit"]):
					 # can cancel JumpTransit into any up-tilts, unless holding jump
					if attack_ref in MOVE_DATABASE:
						Character.animate(attack_ref + "Startup")
						Character.chain_memory = []
						has_acted[0] = true
						return true
						
			Globals.char_state.AIR_STARTUP:
				if Character.button_up in Character.input_state.pressed and !Character.button_jump in Character.input_state.pressed and \
						Animator.query(["AirJumpTransit"]):
					 # can cancel AirJumpTransit into any up-tilts, unless holding jump
					if "a" + attack_ref in MOVE_DATABASE and !("a" + attack_ref in Character.aerial_memory):
						Character.animate("a" + attack_ref + "Startup")
						Character.chain_memory = []
						has_acted[0] = true
						return true
				
			Globals.char_state.AIR_STANDBY, Globals.char_state.AIR_C_RECOVERY:
				if !Character.grounded: # must be currently not grounded even if next state is still considered an aerial state
					if "a" + attack_ref in MOVE_DATABASE and !("a" + attack_ref in Character.aerial_memory):
						Character.animate("a" + attack_ref + "Startup")
						Character.chain_memory = []
						has_acted[0] = true
						return true
				
			Globals.char_state.GROUND_ATK_RECOVERY, Globals.char_state.GROUND_ATK_ACTIVE:
				if attack_ref in MOVE_DATABASE:
					if Character.test_chain_combo(attack_ref):
						if buffer_time == Settings.input_buffer_time[Character.player_ID] and Animator.time == 0:
							Character.get_node("ModulatePlayer").play("unflinch_flash")
							Character.perfect_chain = true
						Character.animate(attack_ref + "Startup")
						has_acted[0] = true
						return true
					
			Globals.char_state.AIR_ATK_RECOVERY, Globals.char_state.AIR_ATK_ACTIVE:
				if !Character.grounded:
					if "a" + attack_ref in MOVE_DATABASE and !("a" + attack_ref in Character.aerial_memory):
						if Character.test_chain_combo("a" + attack_ref):
							if buffer_time == Settings.input_buffer_time[Character.player_ID] and Animator.time == 0:
								Character.get_node("ModulatePlayer").play("unflinch_flash")
								Character.perfect_chain = true
							Character.animate("a" + attack_ref + "Startup")
							has_acted[0] = true
							return true
				else:
					if attack_ref in MOVE_DATABASE:
						if Character.test_chain_combo(attack_ref): # grounded
							if buffer_time == Settings.input_buffer_time[Character.player_ID] and Animator.time == 0:
								Character.get_node("ModulatePlayer").play("unflinch_flash")
								Character.perfect_chain = true
							Character.animate(attack_ref + "Startup")
							has_acted[0] = true
							return true
					
	return false
						
