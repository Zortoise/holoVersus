extends "res://Characters/Gura/GuraBase.gd"

#const STYLE = 0

# Steps to add an attack:
# 1. Add it in MOVE_DATABASE and STARTERS, also in EX_MOVES/SUPERS, and in UP_TILTS if needed (even for EX Moves)
# 2. Add it in state_detect()
# 3. Add it in _on_SpritePlayer_anim_finished() to set the transitions
# 4. Add it in _on_SpritePlayer_anim_started() to set up sfx_over, entity/sfx spawning  and other physics modifying characteristics
# 6. Add it in capture_combinations() if it is a special action
# 5. Add it in process_buffered_input() for inputs
# 7. Add any startup/recovery animations not in MOVE_DATABASE to query_atk_attr()

# --------------------------------------------------------------------------------------------------

# shortening code, set by main character node
onready var Character = get_parent()
var Animator
var sprite
var uniqueHUD

func _ready():
	get_node("TestSprite").free() # test sprite is for sizing collision box
	uniqueHUD = load("res://Characters/Gura/GuraHUD.tscn").instance()
	Globals.Game.set_uniqueHUD(Character.player_ID, uniqueHUD)
	uniqueHUD.get_node("Bitemark1").hide()
	uniqueHUD.get_node("Bitemark2").hide()
	uniqueHUD.get_node("Bitemark3").hide()
	
# STATE_DETECT --------------------------------------------------------------------------------------------------

func state_detect(anim): # for unique animations, continued from state_detect() of main character node
	match anim:
		
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
			
		"aSP2Startup", "aSP2[ex]Startup":
			return Globals.char_state.AIR_ATK_STARTUP
		"aSP2Active", "aSP2[h]Active", "aSP2[ex]Active":
			return Globals.char_state.AIR_ATK_ACTIVE
		"aSP2Recovery", "aSP2[h]Recovery":
			return Globals.char_state.AIR_ATK_RECOVERY
		"aSP2CRecovery":
			return Globals.char_state.AIR_C_RECOVERY
			
		"SP3Startup", "SP3[h]Startup", "SP3[ex]Startup":
			return Globals.char_state.GROUND_ATK_STARTUP
		"aSP3Startup", "aSP3[h]Startup", "aSP3[ex]Startup", "aSP3bStartup", "aSP3b[h]Startup", "aSP3b[ex]Startup":
			return Globals.char_state.AIR_ATK_STARTUP
		"aSP3Active", "aSP3[h]Active", "aSP3[ex]Active", "aSP3bActive", "aSP3b[h]Active", "aSP3b[ex]Active":
			return Globals.char_state.AIR_ATK_ACTIVE
		"aSP3Recovery", "aSP3bRecovery", "aSP3[ex]Recovery":
			return Globals.char_state.AIR_ATK_RECOVERY
			
		"SP4Startup", "SP4[ex]Startup":
			return Globals.char_state.GROUND_ATK_STARTUP
		"SP4Active", "SP4[h]Active", "SP4[ex]Active":
			return Globals.char_state.GROUND_ATK_ACTIVE
		"SP4Recovery", "SP4[ex]Recovery":
			return Globals.char_state.GROUND_ATK_RECOVERY
			
		"SP5Startup", "SP5[ex]Startup":
			return Globals.char_state.GROUND_ATK_STARTUP
		"aSP5Startup", "aSP5[ex]Startup":
			return Globals.char_state.AIR_ATK_STARTUP
		"aSP5Active", "aSP5[ex]Active":
			return Globals.char_state.AIR_ATK_ACTIVE
		"aSP5Recovery", "aSP5bRecovery", "aSP5[ex]Recovery", "aSP5b[ex]Recovery":
			return Globals.char_state.AIR_ATK_RECOVERY
		"SP5bRecovery", "SP5b[ex]Recovery":
			return Globals.char_state.GROUND_ATK_RECOVERY
			
		"SP6[ex]Startup":
			return Globals.char_state.GROUND_ATK_STARTUP
		"aSP6[ex]Startup":
			return Globals.char_state.AIR_ATK_STARTUP
		"aSP6[ex]Active":
			return Globals.char_state.AIR_ATK_ACTIVE
		"SP6[ex]Recovery", "SP6[ex]GrabRecovery":
			return Globals.char_state.GROUND_ATK_RECOVERY
		"aSP6[ex]Recovery", "aSP6[ex]GrabRecovery":
			return Globals.char_state.AIR_ATK_RECOVERY
		"SP6[ex]SeqA", "SP6[ex]SeqB", "SP6[ex]SeqC", "SP6[ex]SeqD", "SP6[ex]SeqE", "aSP6[ex]SeqE":
			return Globals.char_state.SEQUENCE_USER
		
	print("Error: " + anim + " not found.")
		
func check_collidable():  # some characters have move that can pass through other characters
	match Animator.to_play_animation:
#		"Dash":
#			return false
		"aSP2[h]Active":
			return false
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
			
#	if Character.state == Globals.char_state.GROUND_RECOVERY and Character.button_dash in Character.input_state.pressed and \
#		Animator.query_current(["Dash"]): 	# dash dancing, need to hold dash
#		if Character.button_left in Character.input_state.just_pressed and !Character.button_right in Character.input_state.just_pressed:
#			Character.face(-1)
#			Character.animate("Dash")
#		elif Character.button_right in Character.input_state.just_pressed and !Character.button_left in Character.input_state.just_pressed:
#			Character.face(1)
#			Character.animate("Dash")


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
	
	Character.combination_trio(Character.button_special, Character.button_light, Character.button_fierce, "Sp.H")
	Character.ex_combination_trio(Character.button_special, Character.button_light, Character.button_fierce, "ExSp.H")
	
	Character.ex_combination(Character.button_special, Character.button_aux, "ExSp.A")


func rebuffer_actions():
	Character.rebuffer(Character.button_up, Character.button_light, "uL")
	Character.rebuffer(Character.button_down, Character.button_light, "dL")
	Character.rebuffer(Character.button_up, Character.button_fierce, "uF")
	Character.rebuffer(Character.button_down, Character.button_fierce, "dF")
	Character.rebuffer(Character.button_light, Character.button_fierce, "H")
	
	Character.rebuffer(Character.button_special, Character.button_light, "Sp.L")
	Character.rebuffer(Character.button_special, Character.button_fierce, "Sp.F")
	Character.rebuffer_trio(Character.button_special, Character.button_up, Character.button_fierce, "Sp.uF")
	Character.rebuffer_trio(Character.button_special, Character.button_light, Character.button_fierce, "Sp.H")
	
func rebuffer_EX(): # only rebuffer EX moves on release of up/down
	Character.ex_rebuffer(Character.button_special, Character.button_light, "ExSp.L")
	Character.ex_rebuffer(Character.button_special, Character.button_fierce, "ExSp.F")
#	Character.ex_rebuffer_trio(Character.button_special, Character.button_up, Character.button_fierce, "ExSp.uF")
#	Character.ex_rebuffer_trio(Character.button_special, Character.button_light, Character.button_fierce, "ExSp.H")
	
func capture_instant_actions():
	Character.combination(Character.button_unique, Character.button_fierce, "GroundFinTrigger", false, true)
	Character.instant_action_tilt_combination(Character.button_light, "BitemarkTrigger", "BitemarkTriggerD", "BitemarkTriggerU")

func process_instant_actions():
	Character.unique_data.groundfin_trigger = false
	Character.unique_data.nibbler_cancel = max(Character.unique_data.nibbler_cancel - 1, 0)
	# nibbler_cancel is a timer, if 0 will not cancel, cannot use bool since it is set during detect_hit() and need to last 2 turns
	
	if !Character.get_node("RespawnTimer").is_running() and !Character.get_node("HitStunTimer").is_running() and \
			!Character.get_node("BlockStunTimer").is_running():
				
		if "GroundFinTrigger" in Character.instant_actions:
			Character.unique_data.groundfin_trigger = true # flag for triggering
			
		if "BitemarkTriggerU" in Character.instant_actions:
			if Character.unique_data.nibbler_count > 0:
				var spawn_point = get_node(Character.targeted_opponent_path).position
				spawn_point = Detection.ground_finder(spawn_point, Character.facing, Vector2(0, 150), Vector2(10, 300), 1)
				if spawn_point != null:
					Globals.Game.spawn_entity(Character.get_path(), "NibblerSpawn", spawn_point, {})
					Character.play_audio("water15", {"unique_path" : Character.get_path()})
					Character.unique_data.nibbler_count -= 1
					update_uniqueHUD()
						
		if "BitemarkTriggerD" in Character.instant_actions:
			if Character.unique_data.nibbler_count > 0:
				var spawn_point = Character.position
				spawn_point = Detection.ground_finder(spawn_point, Character.facing, Vector2(0, 150), Vector2(10, 300), 1)
				if spawn_point != null:
					Globals.Game.spawn_entity(Character.get_path(), "NibblerSpawn", spawn_point, {})
					Character.play_audio("water15", {"unique_path" : Character.get_path()})
					Character.unique_data.nibbler_count -= 1
					update_uniqueHUD()
						
		if "BitemarkTrigger" in Character.instant_actions:
			if Character.unique_data.nibbler_count > 0:
				var spawn_point = (get_node(Character.targeted_opponent_path).position + Character.position) * 0.5
				spawn_point.x = round(spawn_point.x)
				spawn_point.y = round(spawn_point.y)
				var spawn_point2 = Detection.ground_finder(spawn_point, Character.facing, Vector2(0, 150), Vector2(10, 300), 1)
				if spawn_point2 == null: # if no ground found below, check above a little
					spawn_point2 = Detection.ground_finder(spawn_point, Character.facing, Vector2(0, -50), Vector2(10, 100), -1)
				if spawn_point2 != null:
					Globals.Game.spawn_entity(Character.get_path(), "NibblerSpawn", spawn_point2, {})
					Character.play_audio("water15", {"unique_path" : Character.get_path()})
					Character.unique_data.nibbler_count -= 1
					update_uniqueHUD()


# INPUT BUFFER --------------------------------------------------------------------------------------------------

# called by main character node
func process_buffered_input(new_state, buffered_input, input_to_add, has_acted: Array):
	var keep = true
	match buffered_input[0]:
		
		Character.button_dash:
			match new_state:
				
			# GROUND DASH ---------------------------------------------------------------------------------
		
				Globals.char_state.GROUND_STANDBY, Globals.char_state.CROUCHING, Globals.char_state.GROUND_C_RECOVERY:
					if keep and !Character.button_light in Character.input_state.just_pressed and \
							!Character.button_fierce in Character.input_state.just_pressed and !Animator.query(["DashBrake"]):
						# cannot dash while pressing an attack, or during dash brake
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
								Character.animate("aDashTransit") # for dropping down and air dashing ASAP
						else:
							Character.animate("aDashTransit")
						keep = false
						
				Globals.char_state.AIR_STARTUP: # cancel start of air jump into air dash
					if Animator.query(["aJumpTransit", "WallJumpTransit", "aJumpTransit2", "WallJumpTransit2"]):
						if Character.air_dash > 0:
							Character.animate("aDashTransit")
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
							Character.animate("aDashTransit")
							keep = false
						else: # grounded
							Character.animate("DashTransit")
							keep = false
				
				Globals.char_state.AIR_ATK_ACTIVE:
					if Character.dash_cancel:
						if !Character.grounded:
							if Character.air_dash > 0:
								Character.animate("aDashTransit")
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
	
		"Sp.F":
			if !has_acted[0]:
				if !Character.grounded:
					keep = !process_move(new_state, "SP2", has_acted, buffered_input[1])
				else:
					if Character.unique_data.groundfin_count == 0:
						keep = !process_move(new_state, "SP4", has_acted, buffered_input[1])
						
		"Sp.uF":
			if !has_acted[0]:
				keep = !process_move(new_state, "SP3", has_acted, buffered_input[1])
				
		"Sp.H":
			if !has_acted[0]:
				keep = !process_move(new_state, "SP5", has_acted, buffered_input[1])
				
		"ExSp.L":
			if !has_acted[0]:
				keep = !process_move(new_state, "SP1[ex]", has_acted, buffered_input[1])
				if keep:
					keep = !process_move(new_state, "SP1", has_acted, buffered_input[1])

		"ExSp.F":
			if !has_acted[0]:
				if !Character.grounded:
					keep = !process_move(new_state, "SP2[ex]", has_acted, buffered_input[1])
					if keep:
						keep = !process_move(new_state, "SP2", has_acted, buffered_input[1])
				else:
					if Character.unique_data.groundfin_count <= 1:
						keep = !process_move(new_state, "SP4[ex]", has_acted, buffered_input[1])	
						if keep:
							keep = !process_move(new_state, "SP4", has_acted, buffered_input[1])
							
		"ExSp.uF":
			if !has_acted[0]:
				keep = !process_move(new_state, "SP3[ex]", has_acted, buffered_input[1])
				if keep:
					keep = !process_move(new_state, "SP3", has_acted, buffered_input[1])
					
		"ExSp.H":
			if !has_acted[0]:
				keep = !process_move(new_state, "SP5[ex]", has_acted, buffered_input[1])
				if keep:
					keep = !process_move(new_state, "SP5", has_acted, buffered_input[1])
					
		"ExSp.A":
			if !has_acted[0]:
				keep = !process_move(new_state, "SP6[ex]", has_acted, buffered_input[1])
						
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

	
func process_move(new_state, attack_ref: String, has_acted: Array, buffer_time): # return true if button consumed
	
	if Character.grounded and Character.button_jump in Character.input_state.pressed:
		return false # since this will trigger instant aerial
	
	match Character.state:
		Globals.char_state.GROUND_STARTUP: # can attack on 1st frame of ground dash
			if Animator.query_current(["DashTransit"]):
				if Character.is_ex_valid(attack_ref):
					Character.animate(attack_ref + "Startup")
					Character.chain_memory = []
					has_acted[0] = true
					return true
						
	match new_state:
			
		Globals.char_state.GROUND_STANDBY, Globals.char_state.CROUCHING, Globals.char_state.GROUND_C_RECOVERY:
			if Character.grounded and attack_ref in STARTERS:
				if new_state == Globals.char_state.GROUND_C_RECOVERY and Globals.atk_attr.NOT_FROM_C_REC in query_atk_attr(attack_ref):
					continue # certain moves cannot be performed during cancellable recovery
				elif Character.is_ex_valid(attack_ref):
					Character.animate(attack_ref + "Startup")
					Character.chain_memory = []
					has_acted[0] = true
					return true
					
		Globals.char_state.GROUND_STARTUP: # grounded up-tilt can be done during ground jump transit if jump is not pressed
			if Character.grounded and attack_ref in UP_TILTS and Animator.query_to_play(["JumpTransit"]):
				if Character.is_ex_valid(attack_ref):
					Character.animate(attack_ref + "Startup")
					Character.chain_memory = []
					has_acted[0] = true
					return true
					
		Globals.char_state.AIR_STANDBY, Globals.char_state.AIR_C_RECOVERY:
			if !Character.grounded: # must be currently not grounded even if next state is still considered an aerial state
				if ("a" + attack_ref) in STARTERS and Character.test_aerial_memory("a" + attack_ref):
					if new_state == Globals.char_state.AIR_C_RECOVERY and Globals.atk_attr.NOT_FROM_C_REC in query_atk_attr("a" + attack_ref):
						continue # certain moves cannot be performed during cancellable recovery
					if Character.is_ex_valid("a" + attack_ref):
						Character.animate("a" + attack_ref + "Startup")
						Character.chain_memory = []
						has_acted[0] = true
						return true
						
		Globals.char_state.AIR_STARTUP: # aerial up-tilt can be done during air jump transit if jump is not pressed
			if ("a" + attack_ref) in UP_TILTS and !Character.button_jump in Character.input_state.pressed and \
					Character.test_aerial_memory("a" + attack_ref) and \
					Animator.query_to_play(["aJumpTransit", "aJumpTransit2", "WallJumpTransit", "WallJumpTransit2"]):
				if Character.is_ex_valid("a" + attack_ref):
					Character.animate("a" + attack_ref + "Startup")
					Character.chain_memory = []
					has_acted[0] = true
					return true
				
			# chain cancel
		Globals.char_state.GROUND_ATK_RECOVERY, Globals.char_state.GROUND_ATK_ACTIVE:
			if attack_ref in STARTERS:
				if Character.test_chain_combo(attack_ref):
					if Character.is_ex_valid(attack_ref):
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
						if Character.is_ex_valid(attack_ref, true):
							Character.animate(attack_ref + "Startup")
							has_acted[0] = true
							return true
					
			# chain cancel
		Globals.char_state.AIR_ATK_RECOVERY, Globals.char_state.AIR_ATK_ACTIVE:
			if !Character.grounded:
				if ("a" + attack_ref) in STARTERS and Character.test_aerial_memory("a" + attack_ref):
					if Character.test_chain_combo("a" + attack_ref):
						if Character.is_ex_valid("a" + attack_ref):
							if buffer_time == Settings.input_buffer_time[Character.player_ID] and Animator.time == 0:
								Character.get_node("ModulatePlayer").play("unflinch_flash")
								Character.perfect_chain = true
							Character.animate("a" + attack_ref + "Startup")
							has_acted[0] = true
							return true
			else:
				if attack_ref in STARTERS:
					if Character.test_chain_combo(attack_ref): # grounded
						if Character.is_ex_valid(attack_ref):
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
						

func update_uniqueHUD():
	match Character.unique_data.nibbler_count:
		0:
			uniqueHUD.get_node("Bitemark1").hide()
			uniqueHUD.get_node("Bitemark2").hide()
			uniqueHUD.get_node("Bitemark3").hide()
		1:
			uniqueHUD.get_node("Bitemark1").show()
			uniqueHUD.get_node("Bitemark2").hide()
			uniqueHUD.get_node("Bitemark3").hide()
		2:
			uniqueHUD.get_node("Bitemark1").show()
			uniqueHUD.get_node("Bitemark2").show()
			uniqueHUD.get_node("Bitemark3").hide()
		3:
			uniqueHUD.get_node("Bitemark1").show()
			uniqueHUD.get_node("Bitemark2").show()
			uniqueHUD.get_node("Bitemark3").show()
			
						
func consume_one_air_dash(): # different characters can have different types of air_dash consumption
	Character.air_dash = max(Character.air_dash - 1, 0)
	
func gain_one_air_dash(): # different characters can have different types of air_dash consumption
	if Character.air_dash < MAX_AIR_DASH: # cannot go over
		Character.air_dash += 1

func afterimage_trail():# process afterimage trail
	match Animator.to_play_animation:
		"Dash", "aDash", "aDashD", "aDashU":
			Character.afterimage_trail()
		"SP6[ex]SeqB", "SP6[ex]SeqC", "SP6[ex]SeqD":
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
		"F2b":
			return MOVE_DATABASE["F2"].atk_attr
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
		"SP3":
			return MOVE_DATABASE["aSP3"].atk_attr
		"SP3[h]": 
			return MOVE_DATABASE["aSP3[h]"].atk_attr
		"SP3[ex]": 
			return MOVE_DATABASE["aSP3[ex]"].atk_attr
		"SP5", "SP5b", "aSP5b":
			return MOVE_DATABASE["aSP5"].atk_attr
		"SP5[ex]", "SP5b[ex]", "aSP5b[ex]":
			return MOVE_DATABASE["aSP5[ex]"].atk_attr
		"SP6[ex]", "SP6[ex]Grab", "aSP6[ex]Grab":
			return MOVE_DATABASE["aSP6[ex]"].atk_attr
			
	if move_name in MOVE_DATABASE and "atk_attr" in MOVE_DATABASE[move_name]:
		return MOVE_DATABASE[move_name].atk_attr
		
	print("Error: Cannot retrieve atk_attr for " + move_name)
	return []
	
func query_traits(): # may have special conditions
	return TRAITS


# HIT REACTIONS --------------------------------------------------------------------------------------------------

func landed_a_hit(hit_data): # reaction, can change hit_data from here
	
	match hit_data.move_name:
		"aL2":
			Character.animate("aL2Recovery")
		"L2":
			Character.animate("L2Recovery")
		"aSP5":
			if hit_data.sweetspotted:
				Character.unique_data.nibbler_count = min(Character.unique_data.nibbler_count + 2, 3)
			else:
				Character.unique_data.nibbler_count = min(Character.unique_data.nibbler_count + 1, 3)
			update_uniqueHUD()
		"aSP5[ex]":
			if hit_data.sweetspotted:
				Character.unique_data.nibbler_count = min(Character.unique_data.nibbler_count + 3, 3)
			else:
				Character.unique_data.nibbler_count = min(Character.unique_data.nibbler_count + 2, 3)
			update_uniqueHUD()


func being_hit(hit_data): # reaction, can change hit_data from here
	var defender = get_node(hit_data.defender_nodepath)
	
	if !hit_data.weak_hit and hit_data.move_data.damage > 0:
		match defender.state:
			Globals.char_state.AIR_STARTUP, Globals.char_state.AIR_RECOVERY:
				if Animator.query(["aDashU", "aDashD"]):
					hit_data.punish_hit = true
					
	if hit_data.block_state in [Globals.block_state.UNBLOCKED, Globals.block_state.AIR_WRONG, Globals.block_state.GROUND_WRONG]:
		Character.unique_data.nibbler_cancel = 2 # cancel spawning nibblers
		Character.unique_data.nibbler_count = max(Character.unique_data.nibbler_count - 1, 0)
		update_uniqueHUD()
				
	
	
# AUTO SEQUENCES --------------------------------------------------------------------------------------------------

func stimulate_sequence(): # this is ran on every frame during a sequence
	var Partner = get_node(Character.targeted_opponent_path)
	
	match Animator.to_play_animation:
		"SP6[ex]SeqA":
			if Animator.time == 10:
				Globals.Game.spawn_SFX("HitsparkB", "HitsparkB", Animator.query_point("grabpoint"), {"facing":-Character.facing, "palette":"blue"})
				Character.play_audio("cut1", {"vol":-12})
		"SP6[ex]SeqB":
			if Character.dir != 0: # can air strafe when going up
				Character.velocity.x += Character.dir * 10
			else:
				Character.velocity.x = lerp(Character.velocity.x, 0, 0.2) # air res
			Character.velocity.x = clamp(Character.velocity.x, -100, 100) # max air strafe speed
			Character.velocity.y += 1000 * Globals.FRAME # gravity
			if Animator.time in [0, 21]:
				Character.play_audio("whoosh3", {"vol":-10})
		"SP6[ex]SeqC":
			Character.velocity.x = lerp(Character.velocity.x, 0, 0.2) # air res
		"SP6[ex]SeqD":
			Partner.afterimage_trail()
			if Character.grounded: end_sequence_step("ground") # secondary trigger, in case the one in Character.stimulate_sequence() fails
		"SP6[ex]SeqE":
			pass
						
func stimulate_sequence_after(): # called after moving and animating every frame, grab_point and grab_rot_dir are only updated then
	
	var Partner = get_node(Character.targeted_opponent_path)
	var grab_point = Animator.query_point("grabpoint")
	var grab_rot_dir = Animator.query_point("grabrotdir")
	
	match Animator.to_play_animation:
		"SP6[ex]SeqA", "SP6[ex]SeqB", "SP6[ex]SeqC", "SP6[ex]SeqD":
			move_sequence_target(grab_point)
			if grab_rot_dir != null:
				if Partner.facing == -1:
					Partner.sprite.rotation = grab_point.angle_to_point(grab_rot_dir)
				else:
					Partner.sprite.rotation = grab_point.angle_to_point(grab_rot_dir) + PI
		"SP6[ex]SeqE":
			pass
						
func start_sequence_step(): # this is ran at the start of every sequence_step
	var Partner = get_node(Character.targeted_opponent_path)

	match Animator.to_play_animation:
		"SP6[ex]SeqA":
			Globals.Game.get_node("Players").move_child(Character, 0) # move Grabber to back, some grabs move Grabbed to back
			Character.velocity = Vector2.ZERO # freeze first
			Partner.velocity = Vector2.ZERO
			Partner.animate("aSeqFlinchAFreeze")
			Partner.face(-Character.facing)
			Partner.get_node("ModulatePlayer").play("tech_flash")
			Character.play_audio("bling6", {"vol":-20})
		"SP6[ex]SeqB":
			Character.velocity = Vector2(0, -500) # jump up
			if Character.grounded:
				Globals.Game.spawn_SFX("JumpDust", "DustClouds", Character.get_feet_pos(), {"facing":Character.facing, "grounded":true})
				Globals.Game.spawn_SFX("BounceDust", "DustClouds", Character.get_feet_pos(), {"facing":Character.facing, "grounded":true})
		"SP6[ex]SeqC":
			Character.velocity.y = 600 # dive down
			Globals.Game.spawn_SFX("WaterJet", [Character.get_path(), "WaterJet"], Character.position, \
					{"facing":Character.facing, "rot":PI/2})
			Character.play_audio("water14", {})
		"SP6[ex]SeqE":  # you hit ground
			Partner.sequence_hit(0)
			Character.velocity = Vector2.ZERO
			Partner.move_sequence_player_by(Vector2(0, Character.get_feet_pos().y - Partner.get_feet_pos().y)) # move opponent down to your level
			Globals.Game.spawn_SFX("MediumSplash", [Character.get_path(), "MediumSplash"], Character.get_feet_pos(), \
					{"facing":Character.facing, "back":true, "grounded":true})
			Globals.Game.spawn_SFX("BigSplash", [Character.get_path(), "BigSplash"], Partner.get_feet_pos(), \
					{"facing":Character.facing, "grounded":true})
			Globals.Game.spawn_SFX("BounceDust", "DustClouds", Character.get_feet_pos(), {"facing":Character.facing, "grounded":true})
			Globals.Game.spawn_SFX("BounceDust", "DustClouds", Partner.get_feet_pos(), {"facing":Character.facing, "grounded":true})
			Globals.Game.spawn_SFX("HitsparkD", "HitsparkD", Partner.get_feet_pos(), {"facing":Character.facing, "palette":"blue", "rot":PI/2})
			Globals.Game.set_screenshake()
			Character.play_audio("impact41", {"vol":-15, "bus":"LowPass"})
			Character.play_audio("rock3", {})
		"aSP6[ex]SeqE":  # parther hit the ground but not you
			Partner.sequence_hit(0)
			Character.velocity = Vector2.ZERO
			Globals.Game.spawn_SFX("BigSplash", [Character.get_path(), "BigSplash"], Partner.get_feet_pos(), \
					{"facing":Character.facing, "grounded":true})
			Globals.Game.spawn_SFX("BounceDust", "DustClouds", Partner.get_feet_pos(), {"facing":Character.facing, "grounded":true})
			Globals.Game.spawn_SFX("HitsparkD", "HitsparkD", Partner.get_feet_pos(), {"facing":Character.facing, "palette":"blue", "rot":PI/2})
			Globals.Game.set_screenshake()
			Character.play_audio("impact41", {"vol":-15, "bus":"LowPass"})
			Character.play_audio("rock3", {"vol":-5})
							
func end_sequence_step(trigger = null): # this is ran at the start of certain sequence_step, or to end a trigger sequence_step
	var Partner = get_node(Character.targeted_opponent_path)
	
	if trigger == "break": # grab break
		Character.animate("Idle")
		Partner.animate("Idle")
		return true
	
	match Animator.to_play_animation:
		"SP6[ex]SeqD": # ends when either you or parther hit the ground
			if trigger == "ground": # you hit the ground
				Character.animate("SP6[ex]SeqE")
				return true
			elif trigger == "target_ground": # parther hit the ground but not you
				Character.animate("aSP6[ex]SeqE")
				return true
		"SP6[ex]SeqE":
			Partner.sequence_launch()
			return true
		"aSP6[ex]SeqE":
			Partner.sequence_launch()
			return true
	return false
			
func move_sequence_target(new_position): # move sequence_target to new position
	if new_position == null: return # no grab point
	
	var Partner = get_node(Character.targeted_opponent_path)
	var results = Partner.move_sequence_player_to(new_position) # [in_velocity, landing_check, collision_check, ledgedrop_check]
	
	if results[1]: # Grabbed hit the ground, ends sequence step if it is triggered by Grabbed being grounded
		if end_sequence_step("target_ground"):
			return
			
	if results[2]: # Grabbed hit the wall/ceiling/ground outside ground trigger, reposition Grabber
		var reposition = Partner.position + (Character.position - Animator.query_point("grabpoint"))
		var reposition_results = Character.move_sequence_player_to(reposition)
		if reposition_results[2]: # fail to reposition properly
			end_sequence_step("break") # break grab
			
func sequence_fallthrough(): # which step in sequence ignore soft platforms
	match Animator.to_play_animation:
		"SP6[ex]SeqA", "SP6[ex]SeqB", "SP6[ex]SeqC":
			return true
	return false
	
func sequence_ledgestop(): # which step in sequence are stopped by ledges
	return false
	
func sequence_passthrough(): # which step in sequence ignore all platforms (for cinematic supers)
	return false
	
func sequence_passfloor(): # which step in sequence ignore hard floor
	match Animator.to_play_animation:
		"SP6[ex]SeqA", "SP6[ex]SeqB", "SP6[ex]SeqC":
			return true
	return false
	

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
			
		"aSP2Startup":
			if Character.button_fierce in Character.input_state.pressed:
				Character.animate("aSP2[h]Active")
			else:
				Character.animate("aSP2Active")
		"aSP2Active":
			Character.animate("aSP2Recovery")
		"aSP2[h]Active":
			Character.animate("aSP2[h]Recovery")
		"aSP2[h]Recovery":
			Character.animate("aSP2Recovery")
		"aSP2Recovery":
			Character.animate("aSP2CRecovery")
		"aSP2CRecovery":
			Character.animate("FallTransit")
				
		"aSP2[ex]Startup":
			Character.animate("aSP2[ex]Active")
		"aSP2[ex]Active":
			Character.animate("aSP2Recovery")
			
		"SP3Startup":
			if Character.button_fierce in Character.input_state.pressed:
				Character.animate("SP3[h]Startup")
			else:
				Character.animate("aSP3Active")
				Globals.Game.spawn_SFX("MediumSplash", [Character.get_path(), "MediumSplash"], Character.get_feet_pos(), \
						{"facing":Character.facing, "grounded":true, "back":true})
		"aSP3Startup":
			if Character.button_fierce in Character.input_state.pressed:
				Character.animate("aSP3[h]Startup")
			else:
				Character.animate("aSP3Active")
				Globals.Game.spawn_SFX("WaterJet", [Character.get_path(), "WaterJet"], Vector2(Character.position.x, Character.position.y - 40), \
						{"facing":Character.facing, "rot":-PI/2})
#		"aSP3bStartup":
#			Character.animate("aSP3Active")
		"SP3[h]Startup":
			Character.animate("aSP3[h]Active")
			Globals.Game.spawn_SFX("MediumSplash", [Character.get_path(), "MediumSplash"], Character.get_feet_pos(), \
					{"facing":Character.facing, "grounded":true, "back":true})
		"aSP3[h]Startup":
			Character.animate("aSP3[h]Active")
			Globals.Game.spawn_SFX("WaterJet", [Character.get_path(), "WaterJet"], Vector2(Character.position.x, Character.position.y - 40), \
					{"facing":Character.facing, "rot":-PI/2})
#		"aSP3b[h]Startup":
#			Character.animate("aSP3[h]Active")
		"aSP3Active":
			Character.animate("aSP3bActive")
		"aSP3[h]Active":
			Character.animate("aSP3b[h]Active")
		"aSP3bActive", "aSP3b[h]Active":
			Character.animate("aSP3Recovery")
		"aSP3Recovery":
			Character.animate("aSP3bRecovery")
		"aSP3bRecovery":
			Character.animate("FallTransit")
			
		"SP3[ex]Startup":
			Character.animate("aSP3[ex]Active")
			Globals.Game.spawn_SFX("MediumSplash", [Character.get_path(), "MediumSplash"], Character.get_feet_pos(), \
					{"facing":Character.facing, "grounded":true, "back":true})
		"aSP3[ex]Startup":
			Character.animate("aSP3[ex]Active")
			Globals.Game.spawn_SFX("WaterJet", [Character.get_path(), "WaterJet"], Vector2(Character.position.x, Character.position.y - 40), \
					{"facing":Character.facing, "rot":-PI/2})
#		"aSP3b[ex]Startup":
#			Character.animate("aSP3[ex]Active")
		"aSP3[ex]Active":
			Character.animate("aSP3b[ex]Active")
		"aSP3b[ex]Active":
			Character.animate("aSP3[ex]Recovery")
		"aSP3[ex]Recovery":
			Character.animate("aSP3bRecovery")
			
		"SP4Startup":
			if Character.button_fierce in Character.input_state.pressed:
				Character.animate("SP4[h]Active")
			else:
				Character.animate("SP4Active")
		"SP4[ex]Startup":
			Character.animate("SP4[ex]Active")
		"SP4Active", "SP4[h]Active":
			Character.animate("SP4Recovery")
		"SP4[ex]Active":
			Character.animate("SP4[ex]Recovery")
		"SP4Recovery", "SP4[ex]Recovery":
			Character.animate("Idle")
			
		"SP5Startup", "aSP5Startup":
			Character.animate("aSP5Active")
		"SP5[ex]Startup", "aSP5[ex]Startup":
			Character.animate("aSP5[ex]Active")
		"aSP5Active":
			Character.animate("aSP5Recovery")
		"aSP5[ex]Active":
			Character.animate("aSP5[ex]Recovery")
		"aSP5Recovery":
			if Character.grounded:
				Character.animate("SP5bRecovery")
			else:
				Character.animate("aSP5bRecovery")
		"aSP5[ex]Recovery":
			if Character.grounded:
				Character.animate("SP5b[ex]Recovery")
			else:
				Character.animate("aSP5b[ex]Recovery")
		"SP5bRecovery", "SP5b[ex]Recovery":
			Character.animate("Idle")
		"aSP5bRecovery", "aSP5b[ex]Recovery":
			Character.animate("FallTransit")
			
		"SP6[ex]Startup", "aSP6[ex]Startup":
			Character.animate("aSP6[ex]Active")
		"aSP6[ex]Active":
			if Character.grounded:
				Character.animate("SP6[ex]Recovery")
			else:
				Character.animate("aSP6[ex]Recovery")
		"SP6[ex]Recovery":
			Character.animate("Idle")
		"aSP6[ex]Recovery":
			Character.animate("FallTransit")
			
		"SP6[ex]SeqA":
			Character.animate("SP6[ex]SeqB")
		"SP6[ex]SeqB":
			Character.animate("SP6[ex]SeqC")
		"SP6[ex]SeqC":
			Character.animate("SP6[ex]SeqD")
		"SP6[ex]SeqE":
			end_sequence_step()
			Character.animate("SP6[ex]GrabRecovery")
		"SP6[ex]GrabRecovery":
			Character.animate("Idle")
		"aSP6[ex]SeqE":
			end_sequence_step()
			Character.animate("aSP6[ex]GrabRecovery")
		"aSP6[ex]GrabRecovery":
			Character.animate("FallTransit")
			

func _on_SpritePlayer_anim_started(anim_name):

	match anim_name:
		"Dash":
			Character.velocity.x = GROUND_DASH_SPEED * Character.facing
			Character.friction_mod = 0.0
			Character.afterimage_timer = 1 # sync afterimage trail
			Globals.Game.spawn_SFX( "GroundDashDust", "DustClouds", Character.get_feet_pos(), \
				{"facing":Character.facing, "grounded":true})
		"aDashTransit":
			Character.aerial_memory = []
			Character.velocity.x *= 0.2
			Character.velocity.y *= 0.2
			Character.gravity_mod = 0.0
		"aDash":
			consume_one_air_dash()
#			if Character.air_dash == 0:
#				Character.velocity.x = AIR_DASH_SPEED * 1.2 * Character.facing
#			else:
			Character.velocity.x = AIR_DASH_SPEED * Character.facing
			Character.velocity.y = 0
			Character.gravity_mod = 0.0
			Character.afterimage_timer = 1 # sync afterimage trail
			Globals.Game.spawn_SFX( "AirDashDust", "DustClouds", Character.position, {"facing":Character.facing})
#		"aDashD":
#			consume_one_air_dash()
#			Character.velocity = Vector2(AIR_DASH_SPEED * Character.facing, 0).rotated(PI/4 * Character.facing)
#			Character.gravity_mod = 0.0
#			Character.afterimage_timer = 1 # sync afterimage trail
#			Globals.Game.spawn_SFX( "AirDashDust", "DustClouds", Character.position, {"facing":Character.facing, "rot":PI/4})
#		"aDashU":
#			consume_one_air_dash()
#			Character.velocity = Vector2(AIR_DASH_SPEED * Character.facing, 0).rotated(-PI/4 * Character.facing)
#			Character.gravity_mod = 0.0
#			Character.afterimage_timer = 1 # sync afterimage trail
#			Globals.Game.spawn_SFX( "AirDashDust", "DustClouds", Character.position, {"facing":Character.facing, "rot":-PI/4})	
#		"AirDashDD":
#			consume_one_air_dash()
##			Character.velocity = Vector2(AIR_DASH_SPEED * Character.facing, 0).rotated(PI/2 * Character.facing)
#			Character.velocity.y = AIR_DASH_SPEED
#			Character.gravity_mod = 0.0
#			Character.afterimage_timer = 1 # sync afterimage trail
#			Globals.Game.spawn_SFX( "AirDashDust", "DustClouds", Character.position, {"facing":Character.facing, "rot":PI/2})
#		"AirDashUU":
#			consume_one_air_dash()
##			Character.velocity = Vector2(AIR_DASH_SPEED * Character.facing, 0).rotated(-PI/2 * Character.facing)
#			Character.velocity.y = -AIR_DASH_SPEED
#			Character.gravity_mod = 0.0
#			Character.afterimage_timer = 1 # sync afterimage trail
#			Globals.Game.spawn_SFX( "AirDashDust", "DustClouds", Character.position, {"facing":Character.facing, "rot":-PI/2})	
		"aDashD":
			consume_one_air_dash()
			Character.velocity = Vector2(AIR_DASH_SPEED * Character.facing, 0).rotated(PI/7 * Character.facing)
			Character.gravity_mod = 0.0
			Character.afterimage_timer = 1 # sync afterimage trail
			Globals.Game.spawn_SFX( "AirDashDust", "DustClouds", Character.position, {"facing":Character.facing, "rot":PI/7})
		"aDashU":
			consume_one_air_dash()
			Character.velocity = Vector2(AIR_DASH_SPEED * Character.facing, 0).rotated(-PI/7 * Character.facing)
			Character.gravity_mod = 0.0
			Character.afterimage_timer = 1 # sync afterimage trail
			Globals.Game.spawn_SFX( "AirDashDust", "DustClouds", Character.position, {"facing":Character.facing, "rot":-PI/7})
			
		"L2Startup":
			Character.velocity.x += Character.facing * SPEED * 0.8
		"L2Active":
			Character.velocity.x += Character.facing * SPEED * 1.2
			Character.friction_mod = 0.0
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
			Character.gravity_mod = 0.75
		"aL1Active":
			Character.velocity_limiter.x = 0.85
			Character.gravity_mod = 0.75
			Character.sfx_under.show()
		"aL1Recovery":
			Character.velocity_limiter.x = 0.85
			Character.sfx_under.show()
		"aL2Active":
			Character.velocity_limiter.x = 0.85
			Character.velocity_limiter.down = 1.2
		"aL2Recovery":
			Character.velocity.y = -600
			Character.sfx_over.show()
		"aF1Startup":
			Character.velocity_limiter.x = 0.85
			Character.gravity_mod = 0.75
		"aF1[h]Startup":
			Character.velocity_limiter.x = 0.85
		"aF1Active":
			Character.velocity_limiter.x = 0.85
			Character.velocity_limiter.down = 1.0
			Character.gravity_mod = 0.75
			Character.sfx_over.show()
		"aF1Recovery":
			Character.velocity_limiter.x = 0.85
			Character.velocity_limiter.down = 1.0
			Character.sfx_over.show()
		"aF3Startup":
			Character.velocity_limiter.x = 0.85
			Character.velocity_limiter.down = 0.0
			Character.velocity_limiter.up = 1.0
			Character.gravity_mod = 0.0
		"aF3Active":
			Character.velocity = Vector2(200 * Character.facing, 0).rotated(-PI/2.5 * Character.facing)
			Character.gravity_mod = 0.0
			Character.sfx_over.show()
		"aF3Recovery":
			Character.velocity_limiter.x = 0.75
			Character.velocity_limiter.down = 1.0
			Character.sfx_over.show()
		"aHStartup":
			Character.velocity_limiter.x_slow = 0.2
			Character.velocity_limiter.y_slow = 0.2
			Character.gravity_mod = 0.0
			Character.sfx_over.show()
		"aHActive":
			Character.velocity = Vector2.ZERO
			Character.velocity_limiter.x = 0
			Character.gravity_mod = 0.0
			Character.sfx_over.show()
		"aHRecovery":
			Character.velocity_limiter.x = 0.7
			Character.velocity_limiter.down = 0.7
			Character.sfx_over.show()
			
		"aSP1Startup", "aSP1[ex]Startup":
			Character.velocity_limiter.x_slow = 0.2
			Character.velocity_limiter.y_slow = 0.2
			Character.gravity_mod = 0.0
		"aSP1[c1]Startup", "aSP1[c2]Startup", "aSP1[c1]bStartup", "aSP1[c2]bStartup", "aSP1[c3]Startup":
			Character.velocity_limiter.x = 0.2
			Character.velocity_limiter.down = 0.2
		"SP1[c1]Active": # spawn projectile at EntitySpawn
			Character.velocity.x += Character.facing * SPEED * 0.5
			Globals.Game.spawn_entity(Character.get_path(), "TridentProj", Animator.query_point("entityspawn"), {"charge_lvl" : 1})
			Globals.Game.spawn_SFX("SpecialDust", "DustClouds", Character.get_feet_pos(), {"facing":Character.facing, "grounded":true})
		"SP1[c2]Active":
			Character.velocity.x += Character.facing * SPEED * 0.5
			Globals.Game.spawn_entity(Character.get_path(), "TridentProj", Animator.query_point("entityspawn"), {"charge_lvl" : 2})
			Globals.Game.spawn_SFX("SpecialDust", "DustClouds", Character.get_feet_pos(), {"facing":Character.facing, "grounded":true})
		"SP1[c3]Active":
			Character.velocity.x += Character.facing * SPEED * 0.5
			Globals.Game.spawn_entity(Character.get_path(), "TridentProj", Animator.query_point("entityspawn"), {"charge_lvl" : 3})
			Globals.Game.spawn_SFX("SpecialDust", "DustClouds", Character.get_feet_pos(), {"facing":Character.facing, "grounded":true})
		"SP1[ex]Active":
			Character.velocity.x += Character.facing * SPEED * 0.5
			Globals.Game.spawn_entity(Character.get_path(), "TridentProj", Animator.query_point("entityspawn"), {"charge_lvl" : 4})
			Globals.Game.spawn_SFX("SpecialDust", "DustClouds", Character.get_feet_pos(), {"facing":Character.facing, "grounded":true})
		"aSP1[c1]Active":
			Globals.Game.spawn_entity(Character.get_path(), "TridentProj", Animator.query_point("entityspawn"), {"aerial" : true, "charge_lvl" : 1})
		"aSP1[c2]Active":
			Globals.Game.spawn_entity(Character.get_path(), "TridentProj", Animator.query_point("entityspawn"), {"aerial" : true, "charge_lvl" : 2})
		"aSP1[c3]Active":
			Globals.Game.spawn_entity(Character.get_path(), "TridentProj", Animator.query_point("entityspawn"), {"aerial" : true, "charge_lvl" : 3})
		"aSP1[ex]Active":
			Globals.Game.spawn_entity(Character.get_path(), "TridentProj", Animator.query_point("entityspawn"), {"aerial" : true, "charge_lvl" : 4})
		"aSP1Recovery", "aSP1[ex]Recovery":
			Character.velocity_limiter.x = 0.7
			Character.velocity_limiter.down = 0.7
			
		"aSP2Startup", "aSP2[ex]Startup":
			Character.velocity_limiter.x_slow = 0.2
			Character.velocity_limiter.y_slow = 0.2
			Character.gravity_mod = 0.0
			Character.sfx_under.show()
		"aSP2Active":
			Character.velocity.x = Character.facing * 400
			Character.velocity.y = 0
			Character.gravity_mod = 0.0
			Character.friction_mod = 0.0
			Character.sfx_under.show()
			Globals.Game.spawn_SFX("WaterJet", [Character.get_path(), "WaterJet"], Character.position, {"facing":Character.facing})
		"aSP2[h]Active":
			Character.velocity.x = Character.facing * 500
			Character.velocity.y = 0
			Character.gravity_mod = 0.0
			Character.friction_mod = 0.0
			Character.sfx_under.show()
			Globals.Game.spawn_SFX("WaterJet", [Character.get_path(), "WaterJet"], Character.position, {"facing":Character.facing})
		"aSP2[ex]Active":
			Character.velocity.x = Character.facing * 500
			Character.velocity.y = 0
			Character.gravity_mod = 0.0
			Character.friction_mod = 0.0
			Character.sfx_under.show()
			Globals.Game.spawn_SFX("WaterJet", [Character.get_path(), "WaterJet"], Character.position, {"facing":Character.facing})
		"aSP2[h]Recovery":
			Character.velocity_limiter.down = 0.2
			Character.velocity.x *= 0.5
			Character.gravity_mod = 0.25
			Character.friction_mod = 0.0
			Character.sfx_under.show()
		"aSP2Recovery", "aSP2CRecovery":
			Character.velocity_limiter.down = 0.7
			Character.velocity.x *= 0.5
			Character.gravity_mod = 0.25
			Character.sfx_under.show()
		
			
		"SP3Startup", "SP3[h]Startup", "SP3[ex]Startup":
			Character.sfx_under.show()
		"aSP3Startup", "aSP3[h]Startup", "aSP3[ex]Startup":
			Character.velocity.x *= 0.5
			Character.velocity_limiter.y_slow = 0.2
			Character.gravity_mod = 0.0
			Character.sfx_under.show()
#		"aSP3bStartup":
#			Character.velocity.x *= 0.5
#			Character.velocity.y = -500
#			Character.gravity_mod = 0.0
#			Character.sfx_under.show()
		"aSP3Active":
			Character.velocity.x *= 0.5
			Character.velocity.y = -500
			Character.gravity_mod = 0.0
			Character.sfx_under.show()
#		"aSP3b[h]Startup", "aSP3b[ex]Startup":
#			Character.velocity.x *= 0.5
#			Character.velocity.y = -700
#			Character.gravity_mod = 0.0
#			Character.sfx_under.show()
		"aSP3[h]Active", "aSP3[ex]Active":
			Character.velocity.x *= 0.5
			Character.velocity.y = -700
			Character.gravity_mod = 0.0
			Character.sfx_under.show()
		"aSP3bActive", "aSP3b[h]Active", "aSP3b[ex]Active":
			Character.sfx_under.show()
		"aSP3Recovery", "aSP3[ex]Recovery", "aSP3bRecovery":
			Character.velocity_limiter.x = 0.7
			Character.sfx_under.show()
			
		"SP4Startup", "SP4[ex]Startup":
			Character.sfx_under.show()
		"SP4Active":
			Character.velocity.x += Character.facing * SPEED * 0.25
			Character.sfx_under.show()
			Globals.Game.spawn_entity(Character.get_path(), "GroundFin", Animator.query_point("entityspawn"), {})
			Character.unique_data.groundfin_count += 1
		"SP4[h]Active":
			Character.velocity.x += Character.facing * SPEED * 0.25
			Character.sfx_under.show()
			Globals.Game.spawn_entity(Character.get_path(), "GroundFin", Animator.query_point("entityspawn"), {"held" : true})
			Character.unique_data.groundfin_count += 1
		"SP4[ex]Active":
			Character.velocity.x += Character.facing * SPEED * 0.25
			Character.sfx_under.show()
			var spawn_point = Animator.query_point("entityspawn")
			Globals.Game.spawn_entity(Character.get_path(), "GroundFin", spawn_point, {"ex" : true})
			Globals.Game.spawn_entity(Character.get_path(), "GroundFin", spawn_point, {"held" : true, "ex" : true})
			Character.unique_data.groundfin_count += 2
		"SP4Recovery", "SP4[ex]Recovery":
			Character.sfx_under.show()
			
		"SP5Startup", "SP5[ex]Startup":
			Character.sfx_under.show()
		"aSP5Startup", "aSP5[ex]Startup":
			Character.velocity_limiter.x_slow = 0.2
			Character.velocity_limiter.y_slow = 0.2
			Character.gravity_mod = 0.0
			Character.sfx_under.show()
		"aSP5Active", "aSP5[ex]Active":
			Character.velocity.x = Character.facing * 200
			Character.velocity.y = 0
			Character.gravity_mod = 0.0
			Character.friction_mod = 0.0
			Character.sfx_under.show()
			if Character.grounded:
				Globals.Game.spawn_SFX("SpecialDust", "DustClouds", Character.get_feet_pos(), {"facing":Character.facing, "grounded":true})
		"aSP5Recovery", "aSP5[ex]Recovery":
			Character.velocity_limiter.down = 0.2
			Character.velocity.x *= 0.5
			Character.gravity_mod = 0.25
			Character.sfx_under.show()
			
		"SP6[ex]Startup":
			Character.velocity.x = 0.0
		"aSP6[ex]Startup":
			Character.velocity_limiter.x_slow = 0.2
			Character.velocity_limiter.y_slow = 0.2
			Character.gravity_mod = 0.0
		"aSP6[ex]Active":
			if Character.grounded:
				Character.velocity.x = Character.facing * 100
			Character.velocity.y = 0.0
			Character.gravity_mod = 0.0
		"aSP6[ex]Recovery": # whiff grab
			Character.velocity_limiter.x = 0.2
			Character.gravity_mod = 0.25
			Character.play_audio("fail1", {"vol":-20})
		"SP6[ex]Recovery": # whiff grab
			Character.play_audio("fail1", {"vol":-20})
		"SP6[ex]SeqA", "SP6[ex]SeqB", "SP6[ex]SeqC", "SP6[ex]SeqD", "SP6[ex]SeqE", "aSP6[ex]SeqE":
			start_sequence_step()
		"SP6[ex]GrabRecovery":
			Character.face(-Character.facing)
		"aSP6[ex]GrabRecovery":
			Character.face(-Character.facing)
			Character.velocity_limiter.down = 0.2
			Character.gravity_mod = 0.25
			
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
		"JumpTransit2", "WallJumpTransit2":
			Character.play_audio("jump1", {"bus":"PitchDown"})
		"aJumpTransit2":
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
		"aDash", "aDashD", "aDashU":
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
					
					
