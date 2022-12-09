extends "res://Characters/Gura/GuraBase.gd"

#const STYLE = 0

# Steps to add an attack:
# 1. Add it in MOVE_DATABASE and STARTERS, also in EX_MOVES/SUPERS
# 2. Add it in state_detect()
# 3. Add it in _on_SpritePlayer_anim_finished() to set the transitions
# 4. Add it in _on_SpritePlayer_anim_started() to set up sfx_over, entity/sfx spawning  and other physics modifying characteristics
# 5. Add it in process_buffered_input() for inputs
# 6. Add it in capture_combinations() if it is a special action
# 7. Add any startup/recovery animations not in MOVE_DATABASE to query_atk_attr()

# --------------------------------------------------------------------------------------------------

# shortening code, set by main character node
onready var Character = get_parent()
var Animator
var sprite

func _ready():
	get_node("TestSprite").hide() # test sprite is for sizing collision box
	
# STATE_DETECT --------------------------------------------------------------------------------------------------

func state_detect(anim): # for unique animations, continued from state_detect() of main character node
	match anim:
		
		"AirDashU2", "AirDashD2":
			return Globals.char_state.AIR_RECOVERY
		
		"L1Startup", "L2Startup", "F1Startup", "F2Startup", "F2bStartup", "F3Startup", "F3bStartup", "F3[h]Startup", \
			"HStartup", "H[h]Startup":
			return Globals.char_state.GROUND_ATK_STARTUP
		"L1Active", "L1bActive", "L2Active", "F1Active", "F2Active", "F3Active", "HActive", "HbActive", "H[h]Active", "Hb[h]Active":
			return Globals.char_state.GROUND_ATK_ACTIVE
		"L1Recovery", "L1bRecovery", "L2bRecovery", "F1Recovery", "F2Recovery", "F3Recovery", "HbRecovery", "Hb[h]Recovery":
			return Globals.char_state.GROUND_ATK_RECOVERY
		"L1bCRecovery", "F1CRecovery":
			return Globals.char_state.GROUND_C_RECOVERY
			
		"aL1Startup", "aL2Startup", "aF1Startup", "aF1[h]Startup", "aF3Startup", "aHStartup":
			return Globals.char_state.AIR_ATK_STARTUP
		"aL1Active", "aL2Active", "aF1Active", "aF3Active", "aHActive":
			return Globals.char_state.AIR_ATK_ACTIVE
		"L2Recovery", "aL1Recovery", "aL2Recovery", "aL2bRecovery", "aF1Recovery", "aF3Recovery", "aHRecovery":
			return Globals.char_state.AIR_ATK_RECOVERY
		"L2cCRecovery", "aF1CRecovery", "aF3CRecovery":
			return Globals.char_state.AIR_C_RECOVERY
			
		"SP1Startup", "SP1[c1]Startup", "SP1[c2]Startup", "SP1[c1]bStartup", "SP1[c2]bStartup", "SP1[c3]Startup", "SP1[ex]Startup":
			return Globals.char_state.GROUND_ATK_STARTUP
		"SP1[c1]Active", "SP1[c2]Active", "SP1[c3]Active", "SP1[ex]Active":
			return Globals.char_state.GROUND_ATK_ACTIVE
		"SP1Recovery", "SP1[ex]Recovery":
			return Globals.char_state.GROUND_ATK_RECOVERY
		"aSP1Startup", "aSP1[c1]Startup", "aSP1[c2]Startup", "aSP1[c1]bStartup", "aSP1[c2]bStartup", "aSP1[c3]Startup", "aSP1[ex]Startup":
			return Globals.char_state.AIR_ATK_STARTUP
		"aSP1[c1]Active", "aSP1[c2]Active", "aSP1[c3]Active", "aSP1[ex]Active":
			return Globals.char_state.AIR_ATK_ACTIVE
		"aSP1Recovery", "aSP1[ex]Recovery":
			return Globals.char_state.AIR_ATK_RECOVERY
			
		"SP3Startup", "SP3[h]Startup", "SP3[ex]Startup":
			return Globals.char_state.GROUND_ATK_STARTUP
		"aSP3Startup", "aSP3[h]Startup", "aSP3[ex]Startup", "SP3bStartup", "SP3b[h]Startup", "SP3b[ex]Startup":
			return Globals.char_state.AIR_ATK_STARTUP
		"SP3Active", "SP3[h]Active", "SP3[ex]Active", "SP3bActive", "SP3b[h]Active", "SP3b[ex]Active":
			return Globals.char_state.AIR_ATK_ACTIVE
		"SP3Recovery", "SP3bRecovery", "SP3[ex]Recovery":
			return Globals.char_state.AIR_ATK_RECOVERY
		
	print("Error: " + anim + " not found.")
			

func check_collidable(): # some characters have move that can pass through other characters
	match Animator.to_play_animation:
#		"Dash": 			# example
#			return false
		_:
			pass
	return true

# UNIQUE INPUT CAPTURE --------------------------------------------------------------------------------------------------
# some holdable buttons can have effect unique to the character
	
func stimulate():
	
#	Character.input_state
#	Character.dir
#	Character.v_dir

	# LAND CANCEL --------------------------------------------------------------------------------------------------

	if Character.state == Globals.char_state.AIR_ATK_ACTIVE and Animator.query_current(["aL2Active"]):
		if Character.grounded:
			Character.animate("HardLanding")
			landing_sound()
		elif !Character.button_light in Character.input_state.pressed:
			Character.animate("aL2bRecovery")
	if Character.state == Globals.char_state.AIR_ATK_RECOVERY and Animator.query_current(["SP3bRecovery"]):
		if Character.grounded:
			Character.animate("HardLanding")
			landing_sound()
			
	# RELEASING HELD INPUTS --------------------------------------------------------------------------------------------------
			
	if Character.state == Globals.char_state.GROUND_ATK_STARTUP:
		match Animator.current_animation:
			"SP1[c1]Startup":
				if !Character.button_light in Character.input_state.pressed:
					Character.animate("SP1[c1]bStartup")
			"SP1[c2]Startup":
				if !Character.button_light in Character.input_state.pressed:
					if Animator.time == 1:
						Character.animate("SP1[c3]Startup")
					else:
						Character.animate("SP1[c2]bStartup")
			
	if Character.state == Globals.char_state.AIR_ATK_STARTUP:
		match Animator.current_animation:
			"aF1[h]Startup": # if holding a.F
				if !Character.button_fierce in Character.input_state.pressed:
					Character.animate("aF1Active")
				elif Character.grounded: # landing while holding a.F
					if Character.button_up in Character.input_state.pressed: # if pressing up, cancel to neutral
						Character.startup_cancel_flag = true
						Character.animate("HardLanding")
						landing_sound()
					else: # if not pressing up, do a.F
						Character.animate("aF1Active")
			
			"aSP1[c1]Startup":
				if !Character.button_light in Character.input_state.pressed or Character.grounded:
					Character.animate("aSP1[c1]bStartup")
			"aSP1[c2]Startup":
				if Character.grounded:
					Character.animate("aSP1[c2]bStartup")
				elif !Character.button_light in Character.input_state.pressed:
					if Animator.time == 1:
						Character.animate("aSP1[c3]Startup")
					else:
						Character.animate("aSP1[c2]bStartup")
					
			
	# DASH DANCING --------------------------------------------------------------------------------------------------
			
	if Character.state == Globals.char_state.GROUND_RECOVERY and Character.button_dash in Character.input_state.pressed and \
		Animator.query_current(["Dash"]): 	# dash dancing, need to hold dash
		if Character.button_left in Character.input_state.just_pressed and !Character.button_right in Character.input_state.just_pressed:
			Character.face(-1)
			Character.animate("Dash")
		elif Character.button_right in Character.input_state.just_pressed and !Character.button_left in Character.input_state.just_pressed:
			Character.face(1)
			Character.animate("Dash")

			
	# QUICK CANCELS --------------------------------------------------------------------------------------------------
	
		
#	if Animator.time <= Character.QUICK_CANCEL_TIME and Animator.time != 0:
#		match Character.new_state:
#			Globals.char_state.GROUND_ATK_STARTUP:
#				# can jump cancel the 1st frame of ground attacks, helps with instant aerials
#				if Character.button_jump in Character.input_state.just_pressed:
#					Character.animate("JumpTransit")
#					Character.rebuffer_actions() # this buffers the attack buttons currently being pressed
					
			# no longer need to cancel from button release due to new tilt system
			
#				# releasing up button to cancel up-tilts to neutral
#				if Character.button_up in Character.input_state.just_released:
#					if Animator.query(["F3Startup"]) and Character.test_qc_chain_combo("F1"):
#						Character.animate("F1Startup")
#				# releasing down button to cancel down-tilts to neutral
#				if Character.button_down in Character.input_state.just_released:
#					if Animator.query(["F2Startup"]) and Character.test_qc_chain_combo("F1"):
#						Character.animate("F1Startup")
#					elif Animator.query(["L2Startup"]) and Character.test_qc_chain_combo("L1"):
#						Character.animate("L1Startup")
						
#			Globals.char_state.AIR_ATK_STARTUP:
#				# releasing up button to cancel up-tilts to neutral
#				if Character.button_up in Character.input_state.just_released:
#					if Animator.query(["aF3Startup"]) and Character.test_qc_chain_combo("aF1"):
#						Character.animate("aF1Startup")
#				# releasing down button to cancel down-tilts to neutral
#				if Character.button_down in Character.input_state.just_released:
#					if Animator.query(["aL2Startup"]) and Character.test_qc_chain_combo("aL1"):
#						Character.animate("aL1Startup")

# SPECIAL ACTIONS --------------------------------------------------------------------------------------------------


func capture_combinations():
	
	Character.combination(Character.button_up, Character.button_light, "uL")
	Character.combination(Character.button_down, Character.button_light, "dL")
	Character.combination(Character.button_up, Character.button_fierce, "uF")
	Character.combination(Character.button_down, Character.button_fierce, "dF")
	Character.combination(Character.button_light, Character.button_fierce, "H")
	
	Character.combination(Character.button_special, Character.button_light, "Sp.L")
	Character.ex_combination(Character.button_special, Character.button_light, "ExSp.L")
	Character.combination_trio(Character.button_special, Character.button_up, Character.button_light, "Sp.uL")
	Character.ex_combination_trio(Character.button_special, Character.button_up, Character.button_light, "ExSp.uL")

func rebuffer_actions():
	Character.rebuffer(Character.button_up, Character.button_light, "uL")
	Character.rebuffer(Character.button_down, Character.button_light, "dL")
	Character.rebuffer(Character.button_up, Character.button_fierce, "uF")
	Character.rebuffer(Character.button_down, Character.button_fierce, "dF")
	Character.rebuffer(Character.button_light, Character.button_fierce, "H")
	
	Character.rebuffer(Character.button_special, Character.button_light, "Sp.L")
	Character.rebuffer_trio(Character.button_special, Character.button_up, Character.button_light, "Sp.uL")
	
#	Character.ex_rebuffer(Character.button_special, Character.button_light, "ExSp.L")

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
							
							if Character.button_jump in Character.input_state.pressed: # for easy wavedashing on soft platforms
								Character.snap_up(Character.get_node("PlayerCollisionBox"), Character.get_node("DashLandDBox"))
								Character.animate("JumpTransit") # if snapping up while falling downward, instantly wavedash
								input_to_add.append([Character.button_dash, Settings.input_buffer_time[Character.player_ID]])
								
							elif Character.velocity_previous_frame.y < 0: # moving upward
								Character.snap_up(Character.get_node("PlayerCollisionBox"), Character.get_node("DashLandDBox"))
								Character.animate("DashBrake")
								Globals.Game.spawn_SFX("GroundDashDust", "DustClouds", Character.get_feet_pos(), \
									{"facing":Character.facing, "grounded":true})
								Character.velocity.x = Character.facing * AIR_DASH_SPEED
								dash_sound()
								
							else: # not moving upward
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
#				if Character.button_down in Character.input_state.pressed:
#					keep = !process_move(new_state, "L2", has_acted, buffered_input[1])
#				if keep:
				keep = !process_move(new_state, "L1", has_acted, buffered_input[1])
		
		Character.button_fierce:
			if !has_acted[0]:
#				if Character.button_up in Character.input_state.pressed:
#					keep = !process_move(new_state, "F3", has_acted, buffered_input[1]) # need to do this too for more consistency
#				elif Character.button_down in Character.input_state.pressed:
#					keep = !process_move(new_state, "F2", has_acted, buffered_input[1])
#				if keep:
				keep = !process_move(new_state, "F1", has_acted, buffered_input[1])

		# SPECIAL ACTIONS ---------------------------------------------------------------------------------
		# buffered_input_action can be a string instead of int, for heavy attacks and special moves

		"uL":
			if !has_acted[0]:
				keep = !process_move(new_state, "L3", has_acted, buffered_input[1])
				
		"dL":
			if !has_acted[0]:
				keep = !process_move(new_state, "L2", has_acted, buffered_input[1])

		"uF":
			if !has_acted[0]:
				keep = !process_move(new_state, "F3", has_acted, buffered_input[1])
				
		"dF":
			if !has_acted[0]:
				keep = !process_move(new_state, "F2", has_acted, buffered_input[1])
				
		"H":
			if !has_acted[0]:
				keep = !process_move(new_state, "H", has_acted, buffered_input[1])
				
		"Sp.L":
			if !has_acted[0]:
				keep = !process_move(new_state, "SP1", has_acted, buffered_input[1])
				
		"Sp.uL":
			if !has_acted[0]:
				keep = !process_move(new_state, "SP3", has_acted, buffered_input[1])
				
		"ExSp.L":
			if !has_acted[0]:
				keep = !process_move(new_state, "SP1[ex]", has_acted, buffered_input[1])
				if keep:
					keep = !process_move(new_state, "SP1", has_acted, buffered_input[1])
					
		"ExSp.uL":
			if !has_acted[0]:
				keep = !process_move(new_state, "SP3[ex]", has_acted, buffered_input[1])
				if keep:
					keep = !process_move(new_state, "SP3", has_acted, buffered_input[1])

					
		# ---------------------------------------------------------------------------------
		
		"InstaAirDash": # needed to chain wavedashes
			match new_state:
				Globals.char_state.GROUND_STANDBY, Globals.char_state.CROUCHING, Globals.char_state.GROUND_C_RECOVERY:
					Character.animate("JumpTransit")
					input_to_add.append([Character.button_dash, Settings.input_buffer_time[Character.player_ID]])
					has_acted[0] = true
					keep = false

	
	# ---------------------------------------------------------------------------------
	
	return keep # return true to keep buffered_input, false to remove buffered_input
	# no need to return input_to_add since array is passed by reference
		
func is_grounded_uptilt(attack_ref):
	if attack_ref in ["F3", "SP3"]:
		return true
	return false
	
func is_aerial_uptilt(attack_ref):
	if attack_ref in ["aF3", "aSP3"]:
		return true
	return false
	
func is_ex_valid(attack_ref, quick_cancel = false): # don't put this condition with any other conditions!
	if !attack_ref in EX_MOVES: return true # not ex move
	if !quick_cancel: # not quick cancelling, must afford it
		if Character.current_ex_gauge >= 10000:
			Character.change_ex_gauge(-10000)
			Character.play_audio("bling6", {"vol" : -9, "bus" : "HighPass"}) # EX chime
			return true
		else: return false
	else:
		if Character.get_move_name() in EX_MOVES: # can quick cancel from 1 EX move to another, no cost and no chime if so
			return true
		elif Character.current_ex_gauge >= 10000: # quick cancel from non-ex move to EX move, must afford the cost
			Character.change_ex_gauge(-10000)
			Character.play_audio("bling6", {"vol" : -9, "bus" : "HighPass"}) # EX chime
			return true
		else: return false

func process_move(new_state, attack_ref: String, has_acted: Array, buffer_time): # return true if button consumed
	match new_state:
			
		Globals.char_state.GROUND_STANDBY, Globals.char_state.CROUCHING, Globals.char_state.GROUND_C_RECOVERY:
			if Character.grounded and attack_ref in STARTERS:
				if is_ex_valid(attack_ref):
					Character.animate(attack_ref + "Startup")
					Character.chain_memory = []
					has_acted[0] = true
					return true
					
		Globals.char_state.GROUND_STARTUP: # grounded up-tilt can be done during ground jump transit if jump is not pressed
			if Character.grounded and is_grounded_uptilt(attack_ref) and !Character.button_jump in Character.input_state.pressed and \
					Animator.query_to_play(["JumpTransit"]):
				if is_ex_valid(attack_ref):
					Character.animate(attack_ref + "Startup")
					Character.chain_memory = []
					has_acted[0] = true
					return true
					
		Globals.char_state.AIR_STANDBY, Globals.char_state.AIR_C_RECOVERY:
			if !Character.grounded: # must be currently not grounded even if next state is still considered an aerial state
				if ("a" + attack_ref) in STARTERS and Character.test_aerial_memory("a" + attack_ref):
					if is_ex_valid(attack_ref):
						Character.animate("a" + attack_ref + "Startup")
						Character.chain_memory = []
						has_acted[0] = true
						return true
						
		Globals.char_state.AIR_STARTUP: # aerial up-tilt can be done during air jump transit if jump is not pressed
			if is_aerial_uptilt("a" + attack_ref) and !Character.button_jump in Character.input_state.pressed and \
					Character.test_aerial_memory("a" + attack_ref) and \
					Animator.query_to_play(["AirJumpTransit", "AirJumpTransit2", "WallJumpTransit", "WallJumpTransit2"]):
				if is_ex_valid(attack_ref):
					Character.animate("a" + attack_ref + "Startup")
					Character.chain_memory = []
					has_acted[0] = true
					return true
				
			# chain cancel
		Globals.char_state.GROUND_ATK_RECOVERY, Globals.char_state.GROUND_ATK_ACTIVE:
			if attack_ref in STARTERS:
				if Character.test_chain_combo(attack_ref):
					if is_ex_valid(attack_ref):
						if buffer_time == Settings.input_buffer_time[Character.player_ID] and Animator.time == 0:
							Character.get_node("ModulatePlayer").play("unflinch_flash")
							Character.perfect_chain = true
							
						Character.animate(attack_ref + "Startup")
						has_acted[0] = true
						return true
			
			# quick cancel
		Globals.char_state.GROUND_ATK_STARTUP:
			if Character.grounded and attack_ref in STARTERS:
				if Character.check_quick_cancel(attack_ref): # must be within 1st frame, animation name must be in MOVE_DATABASE
					if Character.test_qc_chain_combo(attack_ref):
						if is_ex_valid(attack_ref, true):
							Character.animate(attack_ref + "Startup")
							has_acted[0] = true
							return true
					
			# chain cancel
		Globals.char_state.AIR_ATK_RECOVERY, Globals.char_state.AIR_ATK_ACTIVE:
			if !Character.grounded:
				if ("a" + attack_ref) in STARTERS and Character.test_aerial_memory("a" + attack_ref):
					if Character.test_chain_combo("a" + attack_ref):
						if is_ex_valid(attack_ref):
							if buffer_time == Settings.input_buffer_time[Character.player_ID] and Animator.time == 0:
								Character.get_node("ModulatePlayer").play("unflinch_flash")
								Character.perfect_chain = true
							Character.animate("a" + attack_ref + "Startup")
							has_acted[0] = true
							return true
			else:
				if attack_ref in STARTERS:
					if Character.test_chain_combo(attack_ref): # grounded
						if is_ex_valid(attack_ref):
							if buffer_time == Settings.input_buffer_time[Character.player_ID] and Animator.time == 0:
								Character.get_node("ModulatePlayer").play("unflinch_flash")
								Character.perfect_chain = true
							Character.animate(attack_ref + "Startup")
							has_acted[0] = true
							return true
							
			# quick cancel
		Globals.char_state.AIR_ATK_STARTUP:
			if !Character.grounded:
				if ("a" + attack_ref) in STARTERS:
					if Character.check_quick_cancel("a" + attack_ref):
						if Character.test_qc_chain_combo("a" + attack_ref):
							if is_ex_valid(attack_ref, true):
								Character.animate("a" + attack_ref + "Startup")
								has_acted[0] = true
								return true
			else:
				if attack_ref in STARTERS:
					if Character.check_quick_cancel(attack_ref):
						if Character.test_qc_chain_combo(attack_ref):
							if is_ex_valid(attack_ref, true):
								Character.animate(attack_ref + "Startup")
								has_acted[0] = true
								return true
					
	return false
						
						
func consume_one_air_dash(): # different characters can have different types of air_dash consumption
	Character.air_dash = max(Character.air_dash - 1, 0)
	
func gain_one_air_dash(): # different characters can have different types of air_dash consumption
	if Character.air_dash < MAX_AIR_DASH: # cannot go over
		Character.air_dash += 1

func afterimage_trail():# process afterimage trail
	# Character.afterimage_trail() can accept 2 parameters, 1st is the starting modulate, 2nd is the lifetime
	
	# afterimage trail for certain modulate animations with the key "afterimage_trail"
	if LoadedSFX.modulate_animations.has(Character.get_node("ModulatePlayer").current_animation) and \
		LoadedSFX.modulate_animations[Character.get_node("ModulatePlayer").current_animation].has("afterimage_trail") and \
		Character.get_node("ModulatePlayer").is_playing():
		# basic afterimage trail for "afterimage_trail" = 0
		if LoadedSFX.modulate_animations[Character.get_node("ModulatePlayer").current_animation]["afterimage_trail"] == 0:
			Character.afterimage_trail()
			return
			
	match Animator.to_play_animation:
		"Dash", "AirDash", "AirDashD2", "AirDashU2":
			Character.afterimage_trail()
			
			
func query_move_data(move_name) -> Dictionary: # can only be called during active frames
	# move data may change for certain moves under certain conditions, unique to character
	var move_data = MOVE_DATABASE[move_name]
	
	match move_data:
		_ :
			pass
	
	return move_data
	
func query_priority(move_name) -> int: # can only be called during active frames
			
	if move_name in MOVE_DATABASE and "priority" in MOVE_DATABASE[move_name]:
		return MOVE_DATABASE[move_name].priority
		
	print("Error: Cannot retrieve priority for " + move_name)
	return 0
	
func query_atk_attr(move_name) -> Array: # may have certain conditions

	# return atk attr for startup and recovery animations not in MOVE_DATABASE
	match move_name: # can add various atk_attr to certain animations under under conditions
		"L2b":
			return MOVE_DATABASE["L2"].atk_attr
		"F3b":
			return MOVE_DATABASE["F3"].atk_attr
		"F3[h]":
			return [Globals.atk_attr.SUPERARMOR]
		"aL2b":
			return MOVE_DATABASE["aL2"].atk_attr
		"aF1[h]":
			return MOVE_DATABASE["aF1"].atk_attr
		"SP1[c1]", "SP1[c2]", "SP1[c1]b", "SP1[c2]b", "SP1[c3]", "aSP1[c1]", "aSP1[c2]", "aSP1[c1]b", "aSP1[c2]b", "aSP1[c3]":
			return MOVE_DATABASE["SP1"].atk_attr
		"aSP3":
			return MOVE_DATABASE["SP3"].atk_attr
		"aSP3[h]": 
			return MOVE_DATABASE["SP3[h]"].atk_attr
		"aSP3[ex]": 
			return MOVE_DATABASE["SP3[ex]"].atk_attr
			
	if move_name in MOVE_DATABASE and "atk_attr" in MOVE_DATABASE[move_name]:
		return MOVE_DATABASE[move_name].atk_attr
		
	print("Error: Cannot retrieve atk_attr for " + move_name)
	return []


func landed_a_hit(_hit_data): # reaction, can change hit_data from here
	if Animator.query(["aL2Active"]):
		Character.animate("aL2Recovery")
	elif Animator.query(["L2Active"]):
		Character.animate("L2Recovery")
	
	
func being_hit(hit_data): # reaction, can change hit_data from here
	var defender = get_node(hit_data.defender_nodepath)
	
	if !hit_data.weak_hit and hit_data.move_data.damage > 0:
		match defender.state:
			Globals.char_state.AIR_STARTUP, Globals.char_state.AIR_RECOVERY:
				if Animator.query(["AirDashU2", "AirDashD2"]):
					hit_data.punish_hit = true
					
	
func query_traits(): # may have special conditions
	return TRAITS

# ANIMATION AND AUDIO PROCESSING ---------------------------------------------------------------------------------------------------
# these are ran by main character node when it gets the signals so that the order is easier to control

func _on_SpritePlayer_anim_finished(anim_name):
	
	match anim_name:
		"DashTransit":
			Character.animate("Dash")
		"Dash":
			Character.animate("DashBrake")
		"DashBrake":
			Character.animate("Idle")
		"AirDashTransit":
#			if Character.air_dash > 1:
#				if Character.button_down in Character.input_state.pressed and Character.dir != 0: # downward air dash
##					Character.face(Character.dir)
#					Character.animate("AirDashD")
#				elif Character.button_up in Character.input_state.pressed and Character.dir != 0: # upward air dash
##					Character.face(Character.dir)
#					Character.animate("AirDashU")
#				elif Character.button_down in Character.input_state.pressed: # downward air dash
#					Character.animate("AirDashDD")
#				elif Character.button_up in Character.input_state.pressed: # upward air dash
#					Character.animate("AirDashUU")
#				else: # horizontal air dash
#					Character.animate("AirDash")
#			else:
			if Character.button_down in Character.input_state.pressed: # downward air dash
				Character.animate("AirDashD2")
			elif Character.button_up in Character.input_state.pressed: # upward air dash
				Character.animate("AirDashU2")
			else: # horizontal air dash
				Character.animate("AirDash")
#		"AirDash", "AirDashD", "AirDashU", "AirDashUU", "AirDashDD", "AirDashD2", "AirDashU2":
		"AirDash", "AirDashD2", "AirDashU2":
			Character.animate("AirDashBrake")
		"AirDashBrake":
			Character.animate("Fall")
			
		"L1Startup":
			Character.animate("L1Active")
		"L1Active":
			Character.animate("L1Recovery")
		"L1Recovery":
			Character.animate("L1bActive")
		"L1bActive":
			Character.animate("L1bRecovery")
		"L1bRecovery":
			Character.animate("L1bCRecovery")
		"L1bCRecovery":
			Character.animate("Idle")
			
		"L2Startup":
			Character.animate("L2Active")
		"L2Active":
			if Character.grounded:
				Character.animate("L2bRecovery")
			else:
				Character.animate("L2cCRecovery")
		"L2Recovery":
			Character.animate("FallTransit")
		"L2bRecovery":
			Character.animate("Idle")
		"L2cCRecovery":
			Character.animate("FallTransit")
			
		"F1Startup":
			Character.animate("F1Active")
		"F1Active":
			Character.animate("F1Recovery")
		"F1Recovery":
			Character.animate("F1CRecovery")
		"F1CRecovery":
			Character.animate("Idle")
			
		"F2Startup":
			Character.animate("F2bStartup")
		"F2bStartup":
			Character.animate("F2Active")
		"F2Active":
			Character.animate("F2Recovery")
		"F2Recovery":
			Character.animate("Idle")
			
		"F3Startup":
#			if get("STYLE") == 0:
			if Character.button_fierce in Character.input_state.pressed:
				Character.animate("F3[h]Startup")
			else:
				Character.animate("F3bStartup")
#			else:
#				if Character.button_light in Character.input_state.pressed:
#					Character.animate("F3[h]Startup")
#				else:
#					Character.animate("F3bStartup")
		"F3bStartup":
			Character.animate("F3Active")
		"F3[h]Startup":
			Character.animate("F3Active")
		"F3Active":
			Character.animate("F3Recovery")
		"F3Recovery":
			Character.animate("Idle")

		"HStartup":
			if Character.button_light in Character.input_state.pressed and Character.button_fierce in Character.input_state.pressed:
				Character.animate("H[h]Startup")
			else:
				Character.animate("HActive")
		"HActive":
			Character.animate("HbActive")
		"HbActive":
			Character.animate("HbRecovery")
		"H[h]Startup":
			Character.animate("H[h]Active")
		"H[h]Active":
			Character.animate("Hb[h]Active")
		"Hb[h]Active":
			Character.animate("Hb[h]Recovery")
		"HbRecovery", "Hb[h]Recovery":
			Character.animate("Idle")

		"aL1Startup":
			Character.animate("aL1Active")
		"aL1Active":
			Character.animate("aL1Recovery")
		"aL1Recovery":
			Character.animate("FallTransit")

		"aL2Startup":
			Character.animate("aL2Active")
		"aL2Recovery":
			if Character.button_light in Character.input_state.pressed:
				Character.animate("aL2Startup")
			else:
				Character.animate("aL2bRecovery")
		"aL2bRecovery":
			Character.animate("FallTransit")

		"aF1Startup":
#			if get("STYLE") == 0:
			if Character.button_fierce in Character.input_state.pressed:
				Character.animate("aF1[h]Startup")
			else:
				Character.animate("aF1Active")
#			else:
#				if Character.button_light in Character.input_state.pressed:
#					Character.animate("aF1[h]Startup")
#				else:
#					Character.animate("aF1Active")
		"aF1[h]Startup":
			Character.animate("aF1Active")
		"aF1Active":
			Character.animate("aF1Recovery")
		"aF1Recovery":
			Character.animate("aF1CRecovery")
		"aF1CRecovery":
			Character.animate("FallTransit")

		"aF3Startup":
			Character.animate("aF3Active")
		"aF3Active":
			Character.animate("aF3Recovery")
		"aF3Recovery":
			Character.animate("aF3CRecovery")
		"aF3CRecovery":
			Character.animate("FallTransit")
	
		"aHStartup":
			Character.animate("aHActive")
		"aHActive":
			Character.animate("aHRecovery")
		"aHRecovery":
			Character.animate("FallTransit")
			
		"SP1Startup":
			Character.animate("SP1[c1]Startup")
		"SP1[c1]Startup":
			Character.animate("SP1[c2]Startup")
		"SP1[c2]Startup":
			Character.animate("SP1[c3]Startup")
		"SP1[c1]bStartup":
			Character.animate("SP1[c1]Active")
		"SP1[c2]bStartup":
			Character.animate("SP1[c2]Active")
		"SP1[c3]Startup":
			Character.animate("SP1[c3]Active")
		"SP1[c1]Active", "SP1[c2]Active", "SP1[c3]Active":
			Character.animate("SP1Recovery")
		"SP1Recovery":
			Character.animate("Idle")
		"aSP1Startup":
			Character.animate("aSP1[c1]Startup")
		"aSP1[c1]Startup":
			Character.animate("aSP1[c2]Startup")
		"aSP1[c2]Startup":
			Character.animate("aSP1[c3]Startup")
		"aSP1[c1]bStartup":
			Character.animate("aSP1[c1]Active")
		"aSP1[c2]bStartup":
			Character.animate("aSP1[c2]Active")
		"aSP1[c3]Startup":
			Character.animate("aSP1[c3]Active")
		"aSP1[c1]Active", "aSP1[c2]Active", "aSP1[c3]Active":
			Character.animate("aSP1Recovery")
		"aSP1Recovery":
			Character.animate("FallTransit")
			
		"SP1[ex]Startup":
			Character.animate("SP1[ex]Active")
		"SP1[ex]Active":
			Character.animate("SP1[ex]Recovery")
		"SP1[ex]Recovery":
			Character.animate("Idle")
		"aSP1[ex]Startup":
			Character.animate("aSP1[ex]Active")
		"aSP1[ex]Active":
			Character.animate("aSP1[ex]Recovery")
		"aSP1[ex]Recovery":
			Character.animate("FallTransit")
			
		"SP3Startup":
			if Character.button_light in Character.input_state.pressed:
				Character.animate("SP3[h]Startup")
			else:
				Character.animate("SP3bStartup")
				Globals.Game.spawn_SFX("MediumSplash", [Character.get_path(), "MediumSplash"], Character.get_feet_pos(), \
						{"facing":Character.facing, "grounded":true, "back":true})
		"aSP3Startup":
			if Character.button_light in Character.input_state.pressed:
				Character.animate("aSP3[h]Startup")
			else:
				Character.animate("SP3bStartup")
				Globals.Game.spawn_SFX("WaterJet", [Character.get_path(), "WaterJet"], Vector2(Character.position.x, Character.position.y - 40), \
						{"facing":Character.facing, "rot":-PI/2})
		"SP3bStartup":
			Character.animate("SP3Active")
		"SP3[h]Startup":
			Character.animate("SP3b[h]Startup")
			Globals.Game.spawn_SFX("MediumSplash", [Character.get_path(), "MediumSplash"], Character.get_feet_pos(), \
					{"facing":Character.facing, "grounded":true, "back":true})
		"aSP3[h]Startup":
			Character.animate("SP3b[h]Startup")
			Globals.Game.spawn_SFX("WaterJet", [Character.get_path(), "WaterJet"], Vector2(Character.position.x, Character.position.y - 40), \
					{"facing":Character.facing, "rot":-PI/2})
		"SP3b[h]Startup":
			Character.animate("SP3[h]Active")
		"SP3Active":
			Character.animate("SP3bActive")
		"SP3[h]Active":
			Character.animate("SP3b[h]Active")
		"SP3bActive", "SP3b[h]Active":
			Character.animate("SP3Recovery")
		"SP3Recovery":
			Character.animate("SP3bRecovery")
		"SP3bRecovery":
			Character.animate("FallTransit")
			
		"SP3[ex]Startup":
			Character.animate("SP3b[ex]Startup")
			Globals.Game.spawn_SFX("MediumSplash", [Character.get_path(), "MediumSplash"], Character.get_feet_pos(), \
					{"facing":Character.facing, "grounded":true, "back":true})
		"aSP3[ex]Startup":
			Character.animate("SP3b[ex]Startup")
			Globals.Game.spawn_SFX("WaterJet", [Character.get_path(), "WaterJet"], Vector2(Character.position.x, Character.position.y - 40), \
					{"facing":Character.facing, "rot":-PI/2})
		"SP3b[ex]Startup":
			Character.animate("SP3[ex]Active")
		"SP3[ex]Active":
			Character.animate("SP3b[ex]Active")
		"SP3b[ex]Active":
			Character.animate("SP3[ex]Recovery")
		"SP3[ex]Recovery":
			Character.animate("SP3bRecovery")
			

func _on_SpritePlayer_anim_started(anim_name):

	match anim_name:
		"Dash":
			Character.velocity.x = GROUND_DASH_SPEED * Character.facing
			Character.null_friction = true
			Character.afterimage_timer = 1 # sync afterimage trail
			Globals.Game.spawn_SFX( "GroundDashDust", "DustClouds", Character.get_feet_pos(), \
				{"facing":Character.facing, "grounded":true})
		"AirDashTransit":
			Character.aerial_memory = []
			Character.velocity.x *= 0.2
			Character.velocity.y *= 0.2
			Character.null_gravity = true
		"AirDash":
			consume_one_air_dash()
#			if Character.air_dash == 0:
#				Character.velocity.x = AIR_DASH_SPEED * 1.2 * Character.facing
#			else:
			Character.velocity.x = AIR_DASH_SPEED * Character.facing
			Character.velocity.y = 0
			Character.null_gravity = true
			Character.afterimage_timer = 1 # sync afterimage trail
			Globals.Game.spawn_SFX( "AirDashDust", "DustClouds", Character.position, {"facing":Character.facing})
#		"AirDashD":
#			consume_one_air_dash()
#			Character.velocity = Vector2(AIR_DASH_SPEED * Character.facing, 0).rotated(PI/4 * Character.facing)
#			Character.null_gravity = true
#			Character.afterimage_timer = 1 # sync afterimage trail
#			Globals.Game.spawn_SFX( "AirDashDust", "DustClouds", Character.position, {"facing":Character.facing, "rot":PI/4})
#		"AirDashU":
#			consume_one_air_dash()
#			Character.velocity = Vector2(AIR_DASH_SPEED * Character.facing, 0).rotated(-PI/4 * Character.facing)
#			Character.null_gravity = true
#			Character.afterimage_timer = 1 # sync afterimage trail
#			Globals.Game.spawn_SFX( "AirDashDust", "DustClouds", Character.position, {"facing":Character.facing, "rot":-PI/4})	
#		"AirDashDD":
#			consume_one_air_dash()
##			Character.velocity = Vector2(AIR_DASH_SPEED * Character.facing, 0).rotated(PI/2 * Character.facing)
#			Character.velocity.y = AIR_DASH_SPEED
#			Character.null_gravity = true
#			Character.afterimage_timer = 1 # sync afterimage trail
#			Globals.Game.spawn_SFX( "AirDashDust", "DustClouds", Character.position, {"facing":Character.facing, "rot":PI/2})
#		"AirDashUU":
#			consume_one_air_dash()
##			Character.velocity = Vector2(AIR_DASH_SPEED * Character.facing, 0).rotated(-PI/2 * Character.facing)
#			Character.velocity.y = -AIR_DASH_SPEED
#			Character.null_gravity = true
#			Character.afterimage_timer = 1 # sync afterimage trail
#			Globals.Game.spawn_SFX( "AirDashDust", "DustClouds", Character.position, {"facing":Character.facing, "rot":-PI/2})	
		"AirDashD2":
			consume_one_air_dash()
			Character.velocity = Vector2(AIR_DASH_SPEED * Character.facing, 0).rotated(PI/7 * Character.facing)
			Character.null_gravity = true
			Character.afterimage_timer = 1 # sync afterimage trail
			Globals.Game.spawn_SFX( "AirDashDust", "DustClouds", Character.position, {"facing":Character.facing, "rot":PI/7})
		"AirDashU2":
			consume_one_air_dash()
			Character.velocity = Vector2(AIR_DASH_SPEED * Character.facing, 0).rotated(-PI/7 * Character.facing)
			Character.null_gravity = true
			Character.afterimage_timer = 1 # sync afterimage trail
			Globals.Game.spawn_SFX( "AirDashDust", "DustClouds", Character.position, {"facing":Character.facing, "rot":-PI/7})
			
		"L2Startup":
			Character.velocity.x += Character.facing * SPEED * 0.8
		"L2Active":
			Character.velocity.x += Character.facing * SPEED * 1.2
			Character.null_friction = true
			Globals.Game.spawn_SFX( "GroundDashDust", "DustClouds", Character.get_feet_pos(), \
				{"facing":Character.facing, "grounded":true})
		"L2Recovery":
			Character.velocity = Vector2(500 * Character.facing, 0).rotated(-PI/2.3 * Character.facing)
		"F1Startup":
			Character.velocity.x += Character.facing * SPEED * 0.25
		"F1Active":
			Character.velocity.x += Character.facing * SPEED * 0.5
			Character.sfx_over.show()
		"F2bStartup":
			Character.velocity.x += Character.facing * SPEED * 0.5
		"F3[h]Startup":
			Character.get_node("ModulatePlayer").play("armor_flash")
		"F1Recovery", "F2Active", "F2Recovery", "F3Active", "F3Recovery":
			Character.sfx_over.show()
		"HStartup":
			Character.velocity.x += Character.facing * SPEED * 0.5
		"HActive", "HbActive", "HbRecovery":
			Character.sfx_under.show()
			Character.sfx_over.show()
		"H[h]Active", "Hb[h]Active", "Hb[h]Recovery":
			Character.sfx_under.show()
			Character.sfx_over.show()
			
		"aL1Startup":
			Character.velocity_limiter.x = 0.85
		"aL1Active", "aL1Recovery":
			Character.velocity_limiter.x = 0.85
			Character.velocity_limiter.down = 1.2
			Character.sfx_under.show()
		"aL2Active":
			Character.velocity_limiter.x = 0.85
			Character.velocity_limiter.down = 1.2
		"aL2Recovery":
			Character.velocity.y = -600
			Character.sfx_over.show()
		"aF1Startup", "aF1[h]Startup":
			Character.velocity_limiter.x = 0.85
		"aF1Active", "aF1Recovery":
			Character.velocity_limiter.x = 0.85
			Character.velocity_limiter.down = 1.0
			Character.sfx_over.show()
		"aF3Startup":
			Character.velocity_limiter.x = 0.85
			Character.velocity_limiter.down = 0.0
			Character.velocity_limiter.up = 1.0
			Character.null_gravity = true
		"aF3Active":
			Character.velocity = Vector2(200 * Character.facing, 0).rotated(-PI/2.5 * Character.facing)
			Character.null_gravity = true
			Character.sfx_over.show()
		"aF3Recovery":
			Character.velocity_limiter.x = 0.75
			Character.velocity_limiter.down = 1.0
			Character.sfx_over.show()
		"aHStartup":
			Character.velocity_limiter.x_slow = 0.2
			Character.velocity_limiter.y_slow = 0.2
			Character.null_gravity = true
			Character.sfx_over.show()
		"aHActive":
			Character.velocity = Vector2.ZERO
			Character.velocity_limiter.x = 0
			Character.null_gravity = true
			Character.sfx_over.show()
		"aHRecovery":
			Character.velocity_limiter.x = 0.7
			Character.velocity_limiter.down = 0.7
			Character.sfx_over.show()
			
		"aSP1Startup", "aSP1[ex]Startup":
			Character.velocity_limiter.x_slow = 0.2
			Character.velocity_limiter.y_slow = 0.2
			Character.null_gravity = true
		"aSP1[c1]Startup", "aSP1[c2]Startup", "aSP1[c1]bStartup", "aSP1[c2]bStartup", "aSP1[c3]Startup":
			Character.velocity_limiter.x = 0.2
			Character.velocity_limiter.down = 0.2
		"SP1[c1]Active": # spawn projectile at EntitySpawn
			Character.velocity.x += Character.facing * SPEED * 0.5
			var spawn_point = Character.position + Animator.query_point("entityspawn")
			Globals.Game.spawn_entity(Character.get_path(), "TridentProj", spawn_point, {"charge_lvl" : 1})
			Globals.Game.spawn_SFX("SpecialDust", "DustClouds", Character.get_feet_pos(), {"facing":Character.facing, "grounded":true})
		"SP1[c2]Active":
			Character.velocity.x += Character.facing * SPEED * 0.5
			var spawn_point = Character.position + Animator.query_point("entityspawn")
			Globals.Game.spawn_entity(Character.get_path(), "TridentProj", spawn_point, {"charge_lvl" : 2})
			Globals.Game.spawn_SFX("SpecialDust", "DustClouds", Character.get_feet_pos(), {"facing":Character.facing, "grounded":true})
		"SP1[c3]Active":
			Character.velocity.x += Character.facing * SPEED * 0.5
			var spawn_point = Character.position + Animator.query_point("entityspawn")
			Globals.Game.spawn_entity(Character.get_path(), "TridentProj", spawn_point, {"charge_lvl" : 3})
			Globals.Game.spawn_SFX("SpecialDust", "DustClouds", Character.get_feet_pos(), {"facing":Character.facing, "grounded":true})
		"SP1[ex]Active":
			Character.velocity.x += Character.facing * SPEED * 0.5
			var spawn_point = Character.position + Animator.query_point("entityspawn")
			Globals.Game.spawn_entity(Character.get_path(), "TridentProj", spawn_point, {"charge_lvl" : 4})
			Globals.Game.spawn_SFX("SpecialDust", "DustClouds", Character.get_feet_pos(), {"facing":Character.facing, "grounded":true})
		"aSP1[c1]Active":
			var spawn_point = Character.position + Animator.query_point("entityspawn")
			Globals.Game.spawn_entity(Character.get_path(), "TridentProj", spawn_point, {"aerial" : true, "charge_lvl" : 1})
		"aSP1[c2]Active":
			var spawn_point = Character.position + Animator.query_point("entityspawn")
			Globals.Game.spawn_entity(Character.get_path(), "TridentProj", spawn_point, {"aerial" : true, "charge_lvl" : 2})
		"aSP1[c3]Active":
			var spawn_point = Character.position + Animator.query_point("entityspawn")
			Globals.Game.spawn_entity(Character.get_path(), "TridentProj", spawn_point, {"aerial" : true, "charge_lvl" : 3})
		"aSP1[ex]Active":
			var spawn_point = Character.position + Animator.query_point("entityspawn")
			Globals.Game.spawn_entity(Character.get_path(), "TridentProj", spawn_point, {"aerial" : true, "charge_lvl" : 4})
		"aSP1Recovery", "aSP1[ex]Recovery":
			Character.velocity_limiter.x = 0.7
			Character.velocity_limiter.down = 0.7
			
		"SP3Startup", "SP3[h]Startup", "SP3[ex]Startup":
			Character.sfx_under.show()
		"aSP3Startup", "aSP3[h]Startup", "aSP3[ex]Startup":
			Character.velocity.x *= 0.5
			Character.velocity_limiter.y_slow = 0.2
			Character.null_gravity = true
			Character.sfx_under.show()
		"SP3bStartup":
			Character.velocity.x *= 0.5
			Character.velocity.y = -500
			Character.null_gravity = true
			Character.sfx_under.show()
		"SP3Active":
			Character.null_gravity = true
			Character.sfx_under.show()
		"SP3b[h]Startup", "SP3b[ex]Startup":
			Character.velocity.x *= 0.5
			Character.velocity.y = -700
			Character.null_gravity = true
			Character.sfx_under.show()
		"SP3[h]Active", "SP3[ex]Active":
			Character.null_gravity = true
			Character.sfx_under.show()
		"SP3bActive", "SP3b[h]Active", "SP3b[ex]Active":
			Character.sfx_under.show()
		"SP3Recovery", "SP3[ex]Recovery", "SP3bRecovery":
			Character.velocity_limiter.x = 0.7
			Character.sfx_under.show()
			
	start_audio(anim_name)


func start_audio(anim_name):
	if Character.is_atk_active():
		var move_name = anim_name.trim_suffix("Active")
		if move_name in MOVE_DATABASE:
			if "move_sound" in MOVE_DATABASE[move_name]:
				if !MOVE_DATABASE[move_name].move_sound is Array:
					Character.play_audio(MOVE_DATABASE[move_name].move_sound.ref, MOVE_DATABASE[move_name].move_sound.aux_data)
				else:
					for sound in MOVE_DATABASE[move_name].move_sound:
						Character.play_audio(sound.ref, sound.aux_data)
	
	match anim_name:
		"JumpTransit2", "WallJumpTransit2", "BlockHopTransit2":
			Character.play_audio("jump1", {"bus":"PitchDown"})
		"AirJumpTransit2":
			Character.play_audio("jump1", {"vol":-2})
		"SoftLanding", "HardLanding", "BlockLanding":
			if Character.velocity_previous_frame.y > 0:
				landing_sound()
		"LaunchTransit":
			if Character.grounded and abs(Character.velocity.y) < 1:
				Character.play_audio("launch2", {"vol" : -3, "bus":"LowPass"})
			else:
				Character.play_audio("launch1", {"vol":-15, "bus":"PitchDown"})
		"Dash":
			dash_sound()
		"AirDash", "AirDashD2", "AirDashU2":
			Character.play_audio("dash1", {"vol" : -6})

			
		


func landing_sound(): # can be called by main node
	Character.play_audio("land1", {"vol" : -2})
	
func dash_sound(): # can be called by snap-up wavelanding
	Character.play_audio("dash1", {"vol" : -5, "bus":"PitchDown"})


func stagger_anim():
	
	match Animator.current_animation:
		"Run":
			match sprite.frame:
				38, 41:
					Character.play_audio("footstep2", {"vol":-1})
		"SP1[c1]Startup", "SP1[c2]Startup":
			match sprite.frame:
				13:
					Globals.Game.spawn_SFX("LandDust", "DustClouds", Character.get_feet_pos(), \
						{"facing":Character.facing, "grounded":true})
					
					
