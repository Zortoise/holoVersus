extends "res://Characters/Gura/GuraBase.gd"
#
#const STYLE = 1
#
## UNIQUE INPUT CAPTURE --------------------------------------------------------------------------------------------------
## some holdable buttons can have effect unique to the character
#
#func simulate():
#
##	Character.input_state
##	Character.dir
##	Character.v_dir
#
#	if Character.state == Globals.char_state.AIR_ATK_ACTIVE and Animator.query(["aL2Active"]):
#		if Character.grounded:
#			Character.animate("HardLanding")
#		if !Character.button_light in Character.input_state.pressed:
#			Character.animate("aL2bRec")
#
#	if Character.state == Globals.char_state.AIR_ATK_STARTUP and Animator.query(["aF1[h]Startup"]):
#		if !Character.button_light in Character.input_state.pressed:
#			Character.animate("aF1Active")
#
#	# dash dancing
#	if Character.state == Globals.char_state.GROUND_RECOVERY and Animator.query(["Dash"]):
#		if Character.button_left in Character.input_state.just_pressed and !Character.button_right in Character.input_state.just_pressed:
#			Character.face(-1)
#			Character.animate("Dash")
#		elif Character.button_right in Character.input_state.just_pressed and !Character.button_left in Character.input_state.just_pressed:
#			Character.face(1)
#			Character.animate("Dash")
#
##	if Character.button_dash in Character.input_state.just_pressed and Character.state == Globals.char_state.GROUND_C_RECOVERY and \
##			Animator.time <= 1:
##		Character.animate("DashTransit")
#
## BLOCK BUTTON --------------------------------------------------------------------------------------------------	
#
#	if Character.button_dash in Character.input_state.pressed and Character.dir == 0 and Character.v_dir == 0:
#		match Character.state:
#			Globals.char_state.GROUND_STANDBY:
#				Character.animate("BlockStartup")
#			Globals.char_state.GROUND_C_RECOVERY:
#				if Animator.query_current(["DashBrake"]):
#					if Globals.trait.DASH_BLOCK in query_traits():
#						Character.animate("BlockStartup")
#				else:
#					Character.animate("BlockStartup")
#			Globals.char_state.AIR_STANDBY:
#				if Character.current_ex_gauge >= AIR_BLOCK_DRAIN_RATE * 0.5:
#					Character.animate("AirBlockStartup")
#					Character.get_node("VarJumpTimer").stop()
#			Globals.char_state.AIR_C_RECOVERY:
#				if !Animator.query_current(["AirDashBrake"]):
#					if Character.current_ex_gauge >= AIR_BLOCK_DRAIN_RATE * 0.5:
#						Character.animate("AirBlockStartup")
#						Character.get_node("VarJumpTimer").stop()
#
#
#	# QUICK CANCELS --------------------------------------------------------------------------------------------------
#
#	if Character.check_quick_cancel():
#
#		if Character.dir == 0 and Character.v_dir == 0:
#			if Animator.query(["DashTransit"]):
#				Character.animate("BlockStartup")
#			elif Animator.query(["AirDashTransit"]):
#				Character.animate("AirBlockStartup")
#
#		if Character.button_left in Character.input_state.just_pressed or \
#				Character.button_right in Character.input_state.just_pressed:
#			if Animator.query(["L1Startup"]) and Character.test_qc_chain_combo("F1"):
#				Character.animate("F1Startup")
#			elif Animator.query(["aL1Startup"]) and Character.test_qc_chain_combo("aF1"):
#				Character.animate("aF1Startup")
#		elif Character.button_left in Character.input_state.just_released or \
#				Character.button_right in Character.input_state.just_released:
#			if Animator.query(["F1Startup"]) and Character.test_qc_chain_combo("L1"):
#				Character.animate("L1Startup")
#			elif Animator.query(["aF1Startup"]) and Character.test_qc_chain_combo("aL1"):
#				Character.animate("aL1Startup")
#
#		if Character.button_up in Character.input_state.just_pressed:
#			if Animator.query(["L1Startup", "F1Startup"]) and Character.test_qc_chain_combo("F3"):
#				Character.animate("F3Startup")
#			elif Animator.query(["aL1Startup", "aF1Startup"]) and Character.test_qc_chain_combo("aF3"):
#				Character.animate("aF3Startup")
#
#		if Character.button_up in Character.input_state.just_released:
#			if Animator.query(["aF3Startup"]):
#				if Character.dir == 0 and Character.test_qc_chain_combo("aL1"):
#					Character.animate("aL1Startup")
#				elif Character.test_qc_chain_combo("aF1"):
#					Character.animate("aF1Startup")
#
#		if Character.button_down in Character.input_state.just_pressed:
#			if Animator.query(["L1Startup", "F1Startup"]) and Character.test_qc_chain_combo("L2"):
#				Character.animate("L2Startup")
#			elif Animator.query(["aL1Startup", "aF1Startup"]) and Character.test_qc_chain_combo("aL2"):
#				Character.animate("aL2Startup")
#			elif Animator.query(["HStartup"]) and Character.test_qc_chain_combo("F2"):
#				Character.animate("F2Startup")
#
#		if Character.button_down in Character.input_state.just_released:
#			if Animator.query(["aL2Startup"]):
#				if Character.dir == 0 and Character.test_qc_chain_combo("aL1"):
#					Character.animate("aL1Startup")
#				elif Character.test_qc_chain_combo("aF1"):
#					Character.animate("aF1Startup")
#			elif Animator.query(["L2Startup"]):
#				if Character.dir == 0 and Character.test_qc_chain_combo("L1"):
#					Character.animate("L1Startup")
#				elif Character.test_qc_chain_combo("F1"):
#					Character.animate("F1Startup")
#			elif Animator.query(["F2Startup"]) and Character.test_qc_chain_combo("H"):
#				Character.animate("HStartup")
#
##		if Character.button_fierce in Character.input_state.just_pressed:
##			if Animator.query(["L1Startup", "L2Startup"]):
##				Character.animate("HStartup")
##			if Animator.query(["aL1Startup", "aL2Startup"]) and !("aH" in Character.aerial_memory):
##				Character.animate("aHStartup")
##
##		if Character.button_light in Character.input_state.just_pressed:
##			if Animator.query(["F1Startup", "F2Startup", "F3Startup"]):
##				Character.animate("HStartup")
##			if Animator.query(["aF1Startup", "aF3Startup"]) and !("aH" in Character.aerial_memory):
##				Character.animate("aHStartup")
#
## SPECIAL ACTIONS --------------------------------------------------------------------------------------------------
#
#
#func capture_combinations():
#
#	Character.combination(Character.button_up, Character.button_fierce, "UpFierce") # can quick_cancel from light/fierce startup	
#
#	Character.combination(Character.button_up, Character.button_light, "UpLight") # can quick_cancel from light/fierce startup	
#
#	# Heavy Normal, place this after UpFierce
##	Character.combination(Character.button_light, Character.button_fierce, "H") # can quick_cancel from light/fierce startup
#
#	# Command Normals
#
#	if Character.get_node("SpecialTimer").is_running():
#		# insert Specials here
#		# also have InstaJumpAct Specials
#		pass
#	elif Character.get_node("EXTimer").is_running():
#		# insert EX Moves here
#		# also have InstaJumpAct EX Moves
#		pass
#	elif Character.get_node("SuperTimer").is_running():
#		# insert Supers here
#		# also have InstaJumpAct Supers
#		pass
#
#
## INPUT BUFFER --------------------------------------------------------------------------------------------------
#
## called by main character node
#func process_buffered_input(new_state, buffered_input, input_to_add, has_acted: Array):
#	var keep = true
#	match buffered_input[0]:
#
#		Character.button_dash:
#			if Character.dir == 0 and Character.v_dir == 0:
#				continue
#			match new_state:
#
#			# GROUND DASH ---------------------------------------------------------------------------------
#
#				Globals.char_state.GROUND_STANDBY, Globals.char_state.CROUCHING, Globals.char_state.GROUND_C_RECOVERY:
#					if keep and !Animator.query(["DashBrake"]): # cannot dash during dash brake
#						Character.animate("DashTransit")
#						keep = false
#
#			# AIR DASH ---------------------------------------------------------------------------------
#
#				Globals.char_state.AIR_STANDBY, Globals.char_state.AIR_C_RECOVERY:
#					if Character.air_dash > 0 or Character.get_node("HitStunGraceTimer").is_running():
#						if Character.button_down in Character.input_state.pressed and Character.check_snap_up():
#
#							if Character.button_jump in Character.input_state.pressed: # for easy wavedashing on soft platforms
#								Character.snap_up(Character.get_node("PlayerCollisionBox"), Character.get_node("DashLandDBox"))
#								Character.animate("JumpTransit") # if snapping up while falling downward, instantly wavedash
#								input_to_add.append([Character.button_dash, Settings.input_buffer_time[Character.player_ID]])
#
#							elif Character.velocity_previous_frame.y < 0: # moving upward
#								Character.snap_up(Character.get_node("PlayerCollisionBox"), Character.get_node("DashLandDBox"))
#								Character.animate("DashBrake")
#								Character.emit_signal("SFX","GroundDashDust", "DustClouds", Character.get_feet_pos(), \
#										{"facing":Character.facing, "grounded":true})
#								Character.velocity.x = Character.facing * AIR_DASH_SPEED
#								dash_sound()
#
#							else: # not moving upward
#								Character.animate("AirDashTransit") # for dropping down and air dashing ASAP
#						else:
#							Character.animate("AirDashTransit")
#						keep = false
#
#				Globals.char_state.AIR_STARTUP: # cancel start of air jump into air dash
#					if Animator.query(["AirJumpTransit", "WallJumpTransit", "AirJumpTransit2", "WallJumpTransit2"]):
#						if Character.air_dash > 0:
#							Character.animate("AirDashTransit")
#							keep = false
#
#			# DASH CANCELS ---------------------------------------------------------------------------------
#				# if land a sweetspot hit, can dash cancel afterward
#
#				Globals.char_state.GROUND_ATK_RECOVERY:
#					if Character.test_dash_cancel():
#						Character.animate("DashTransit")
#						keep = false
#
#				Globals.char_state.GROUND_ATK_ACTIVE:
#					if Character.dash_cancel:
#						Character.animate("DashTransit")
#						keep = false
#
#				Globals.char_state.AIR_ATK_RECOVERY:
#					if Character.test_dash_cancel():
#						if !Character.grounded:
#							Character.animate("AirDashTransit")
#							keep = false
#						else: # grounded
#							Character.animate("DashTransit")
#							keep = false
#
#				Globals.char_state.AIR_ATK_ACTIVE:
#					if Character.dash_cancel:
#						if !Character.grounded:
#							if Character.air_dash > 0:
#								Character.animate("AirDashTransit")
#								keep = false
#						else: # grounded
#							Character.animate("DashTransit")
#							keep = false
#
#		# ---------------------------------------------------------------------------------
#
#		Character.button_light:
#			if !has_acted[0]:
#				if Character.button_up in Character.input_state.pressed:
#					keep = !process_button(new_state, "F3", has_acted, buffered_input[1])
#				elif Character.button_down in Character.input_state.pressed:
#					keep = !process_button(new_state, "L2", has_acted, buffered_input[1])
#				elif Character.dir != 0:
#					keep = !process_button(new_state, "F1", has_acted, buffered_input[1])
#				if keep:
#					keep = !process_button(new_state, "L1", has_acted, buffered_input[1])
#
#		Character.button_fierce:
#			if !has_acted[0]:
##				if Character.button_up in Character.input_state.pressed:
##					keep = !process_button(new_state, "F3", has_acted, buffered_input[1]) # need to do this too for more consistency
#				if Character.button_down in Character.input_state.pressed:
#					keep = !process_button(new_state, "F2", has_acted, buffered_input[1])
#				if keep:
#					keep = !process_button(new_state, "H", has_acted, buffered_input[1])
#
#
#		# SPECIAL ACTIONS ---------------------------------------------------------------------------------
#		# buffered_input_action can be a string instead of int, for heavy attacks and special moves
#
##		"UpFierce":
##			if !has_acted[0]:
##				keep = !process_button(new_state, "F3", has_acted, buffered_input[1])
#
#		"UpLight":
#			if !has_acted[0]:
#				keep = !process_button(new_state, "F3", has_acted, buffered_input[1])
#
##		"H":
##			if !has_acted[0]:
##				keep = !process_button(new_state, "H", has_acted, buffered_input[1])
#
#		"InstaAirDash":
#			match new_state:
#				Globals.char_state.GROUND_STANDBY, Globals.char_state.CROUCHING, Globals.char_state.GROUND_C_RECOVERY:
#					Character.animate("JumpTransit")
#					input_to_add.append([Character.button_dash, Settings.input_buffer_time[Character.player_ID]])
#					has_acted[0] = true
#					keep = false
#				Globals.char_state.GROUND_STARTUP:
#					Character.animate("JumpTransit")
#					input_to_add.append([Character.button_dash, Settings.input_buffer_time[Character.player_ID]])
#					has_acted[0] = true
#					keep = false
#
#	# ---------------------------------------------------------------------------------
#
#	return keep # return true to keep buffered_input, false to remove buffered_input
#	# no need to return input_to_add since array is passed by reference
#
#func classic_air_translate(attack_ref):
#	match attack_ref:
#		"L1": # Nair
#			return "aL1"
#		"L2": # Dair
#			return "aL2"
#		"F1": # Nair
#			return "aF1"
#		"F2": # Hair
#			return "aH"
#		"F3": # Uair
#			return "aF3"
#		"H": # Hair
#			return "aH"
#
#
#func process_button(new_state, attack_ref: String, has_acted: Array, buffer_time): # return true if button consumed
#	match new_state:
#
#			Globals.char_state.GROUND_STANDBY, Globals.char_state.CROUCHING, Globals.char_state.GROUND_C_RECOVERY:
#				if attack_ref in MOVE_DATABASE:
#					Character.animate(attack_ref + "Startup")
#					Character.chain_memory = []
#					has_acted[0] = true
#					return true
#
#			Globals.char_state.GROUND_STARTUP:
#				if Character.button_up in Character.input_state.pressed and !Character.button_jump in Character.input_state.pressed and \
#						Animator.query(["JumpTransit"]):
#					 # can cancel JumpTransit into any up-tilts, unless holding jump
#					if attack_ref in MOVE_DATABASE:
#						Character.animate(attack_ref + "Startup")
#						Character.chain_memory = []
#						has_acted[0] = true
#						return true
#
#			Globals.char_state.AIR_STARTUP:
#				if Character.button_up in Character.input_state.pressed and !Character.button_jump in Character.input_state.pressed and \
#						Animator.query(["AirJumpTransit"]):
#					 # can cancel AirJumpTransit into any up-tilts, unless holding jump
#					if classic_air_translate(attack_ref) in MOVE_DATABASE and !(classic_air_translate(attack_ref) in Character.aerial_memory):
#						Character.animate(classic_air_translate(attack_ref) + "Startup")
#						Character.chain_memory = []
#						has_acted[0] = true
#						return true
#
#			Globals.char_state.AIR_STANDBY, Globals.char_state.AIR_C_RECOVERY:
#				if !Character.grounded: # must be currently not grounded even if next state is still considered an aerial state
#					if classic_air_translate(attack_ref) in MOVE_DATABASE and !(classic_air_translate(attack_ref) in Character.aerial_memory):
#						Character.animate(classic_air_translate(attack_ref) + "Startup")
#						Character.chain_memory = []
#						has_acted[0] = true
#						return true
#
#			Globals.char_state.GROUND_ATK_RECOVERY, Globals.char_state.GROUND_ATK_ACTIVE:
#				if attack_ref in MOVE_DATABASE:
#					if Character.test_chain_combo(attack_ref):
#						if buffer_time == Settings.input_buffer_time[Character.player_ID] and Animator.time == 0:
#							Character.get_node("ModulatePlayer").play("unflinch_flash")
#							Character.perfect_chain = true
#						Character.animate(attack_ref + "Startup")
#						has_acted[0] = true
#						return true
#
#			Globals.char_state.AIR_ATK_RECOVERY, Globals.char_state.AIR_ATK_ACTIVE:
#				if !Character.grounded:
#					if classic_air_translate(attack_ref) in MOVE_DATABASE and !(classic_air_translate(attack_ref) in Character.aerial_memory):
#						if Character.test_chain_combo(classic_air_translate(attack_ref)):
#							if buffer_time == Settings.input_buffer_time[Character.player_ID] and Animator.time == 0:
#								Character.get_node("ModulatePlayer").play("unflinch_flash")
#								Character.perfect_chain = true
#							Character.animate(classic_air_translate(attack_ref) + "Startup")
#							has_acted[0] = true
#							return true
#				else:
#					if attack_ref in MOVE_DATABASE:
#						if Character.test_chain_combo(attack_ref): # grounded
#							if buffer_time == Settings.input_buffer_time[Character.player_ID] and Animator.time == 0:
#								Character.get_node("ModulatePlayer").play("unflinch_flash")
#								Character.perfect_chain = true
#							Character.animate(attack_ref + "Startup")
#							has_acted[0] = true
#							return true
#
#	return false
#
