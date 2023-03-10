extends "res://Characters/Gura/GuraBase.gd"

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
	uniqueHUD = load("res://Characters/Gura/GuraHUD.tscn").instance()
	Globals.Game.set_uniqueHUD(Character.player_ID, uniqueHUD)
	uniqueHUD.get_node("Bitemark1").hide()
	uniqueHUD.get_node("Bitemark2").hide()
	uniqueHUD.get_node("Bitemark3").hide()
	
# STATE_DETECT --------------------------------------------------------------------------------------------------

func state_detect(anim): # for unique animations, continued from state_detect() of main character node
	match anim:
		
		"L1Startup", "L2Startup", "L3Startup", "F1Startup", "F2Startup", "F3Startup", "F3[b]Startup", "F3[h]Startup", \
			"HStartup":
			return Globals.char_state.GROUND_ATK_STARTUP
		"L1Active", "L1bActive", "L1b[h]Active", "L1cActive", "L2Active", "L3Active", "F1Active", "F2Active", "F2[h]Active", "F3Active", \
				"F3[h]Active", "HActive", "HbActive":
			return Globals.char_state.GROUND_ATK_ACTIVE
		"L1Rec", "L1bRec", "L1b[h]Rec", "L1cRec", "L2bRec", "L3Rec", "F1Rec", "F2Rec", "F2[h]Rec", "F2[h]PRec", "F3Rec", "HbRec", \
				"aL2LandRec":
			return Globals.char_state.GROUND_ATK_RECOVERY
			
		"aL1Startup", "aL2Startup", "aL3Startup", "aF1Startup", "aF1[h]Startup", "aF2Startup", "aF3Startup", "aHStartup":
			return Globals.char_state.AIR_ATK_STARTUP
		"aL1Active", "aL2Active", "aL3Active", "aF1Active", "aF2Active", "aF3Active", "aHActive":
			return Globals.char_state.AIR_ATK_ACTIVE
		"L2Rec", "aL1Rec", "aL2Rec", "aL3Rec", "aL2bRec", "aF1Rec", "aF2Rec", "aF3Rec", "aHRec":
			return Globals.char_state.AIR_ATK_RECOVERY
		"L2cCRec":
			return Globals.char_state.AIR_C_RECOVERY
			
		"aF2SeqA", "aF2SeqB":
			return Globals.char_state.SEQUENCE_USER
		"aF2GrabRec":
			return Globals.char_state.AIR_C_RECOVERY
			
		"SP1Startup", "SP1[b]Startup", "SP1[c1]Startup", "SP1[c2]Startup", "SP1[c1]bStartup", "SP1[c2]bStartup", "SP1[c3]Startup", \
				"SP1[u]Startup", "SP1[u][c1]Startup", "SP1[u][c2]Startup", "SP1[u][c1]bStartup", "SP1[u][c2]bStartup", "SP1[u][c3]Startup", \
				"SP1[ex]Startup", "SP1[b][ex]Startup", "SP1[u][ex]Startup":
			return Globals.char_state.GROUND_ATK_STARTUP
		"SP1[c1]Active", "SP1[c2]Active", "SP1[c3]Active", "SP1[ex]Active", \
				"SP1[u][c1]Active", "SP1[u][c2]Active", "SP1[u][c3]Active", "SP1[u][ex]Active":
			return Globals.char_state.GROUND_ATK_ACTIVE
		"SP1Rec", "SP1[ex]Rec":
			return Globals.char_state.GROUND_ATK_RECOVERY
		"aSP1Startup", "aSP1[b]Startup", "aSP1[c1]Startup", "aSP1[c2]Startup", "aSP1[c1]bStartup", "aSP1[c2]bStartup", "aSP1[c3]Startup", \
				"aSP1[d]Startup", "aSP1[d][c1]Startup", "aSP1[d][c2]Startup", "aSP1[d][c1]bStartup", "aSP1[d][c2]bStartup", "aSP1[d][c3]Startup", \
				"aSP1[ex]Startup", "aSP1[b][ex]Startup", "aSP1[d][ex]Startup":
			return Globals.char_state.AIR_ATK_STARTUP
		"aSP1[c1]Active", "aSP1[c2]Active", "aSP1[c3]Active", "aSP1[ex]Active", \
				"aSP1[d][c1]Active", "aSP1[d][c2]Active", "aSP1[d][c3]Active", "aSP1[d][ex]Active":
			return Globals.char_state.AIR_ATK_ACTIVE
		"aSP1Rec", "aSP1[ex]Rec":
			return Globals.char_state.AIR_ATK_RECOVERY
			
		"aSP2Startup", "aSP2[ex]Startup":
			return Globals.char_state.AIR_ATK_STARTUP
		"aSP2Active", "aSP2[h]Active", "aSP2[ex]Active":
			return Globals.char_state.AIR_ATK_ACTIVE
		"aSP2Rec", "aSP2[h]Rec":
			return Globals.char_state.AIR_ATK_RECOVERY
		"aSP2CRec":
			return Globals.char_state.AIR_C_RECOVERY
			
			
			
		"SP3Startup", "SP3[h]Startup", "SP3[ex]Startup":
			return Globals.char_state.GROUND_ATK_STARTUP
		"aSP3Startup", "aSP3[h]Startup", "aSP3[ex]Startup":
			return Globals.char_state.AIR_ATK_STARTUP
		"aSP3Active", "aSP3[h]Active", "aSP3[ex]Active", "aSP3bActive", "aSP3b[h]Active", "aSP3b[ex]Active", \
				"SP3Active", "SP3[h]Active", "SP3[ex]Active", "SP3bActive", "SP3b[h]Active", "SP3b[ex]Active":
			return Globals.char_state.AIR_ATK_ACTIVE
		"aSP3Rec", "aSP3[ex]Rec", "SP3Rec":
			return Globals.char_state.AIR_ATK_RECOVERY
			
		"SP4Startup", "SP4[ex]Startup":
			return Globals.char_state.GROUND_ATK_STARTUP
		"SP4Active", "SP4[h]Active", "SP4[ex]Active":
			return Globals.char_state.GROUND_ATK_ACTIVE
		"SP4Rec", "SP4[ex]Rec":
			return Globals.char_state.GROUND_ATK_RECOVERY
			
		"SP5Startup", "SP5[ex]Startup":
			return Globals.char_state.GROUND_ATK_STARTUP
		"aSP5Startup", "aSP5[ex]Startup":
			return Globals.char_state.AIR_ATK_STARTUP
		"aSP5Active", "aSP5[h]Active", "aSP5[h]bActive", "aSP5[ex]Active":
			return Globals.char_state.AIR_ATK_ACTIVE
		"aSP5Rec", "aSP5bRec", "aSP5[h]Rec", "aSP5[ex]Rec", "aSP5b[ex]Rec":
			return Globals.char_state.AIR_ATK_RECOVERY
		"SP5bRec", "SP5b[ex]Rec":
			return Globals.char_state.GROUND_ATK_RECOVERY
			
		"SP6[ex]Startup":
			return Globals.char_state.GROUND_ATK_STARTUP
		"aSP6[ex]Startup":
			return Globals.char_state.AIR_ATK_STARTUP
		"aSP6[ex]Active":
			return Globals.char_state.AIR_ATK_ACTIVE
		"SP6[ex]Rec", "SP6[ex]GrabRec":
			return Globals.char_state.GROUND_ATK_RECOVERY
		"aSP6[ex]Rec", "aSP6[ex]GrabRec":
			return Globals.char_state.AIR_ATK_RECOVERY
		"SP6[ex]SeqA", "SP6[ex]SeqB", "SP6[ex]SeqC", "SP6[ex]SeqD", "SP6[ex]SeqE", "aSP6[ex]SeqE":
			return Globals.char_state.SEQUENCE_USER

		"SP7Startup":
			return Globals.char_state.GROUND_ATK_STARTUP
		"aSP7Startup":
			return Globals.char_state.AIR_ATK_STARTUP
		"aSP7Active":
			return Globals.char_state.AIR_ATK_ACTIVE
		"aSP7Rec":
			return Globals.char_state.AIR_ATK_RECOVERY
		"SP7Rec":
			return Globals.char_state.GROUND_ATK_RECOVERY
		
	print("Error: " + anim + " not found.")
		
func check_collidable():  # some characters have move that can pass through other characters
	match Animator.to_play_animation:
#		"Dash":
#			return false
		"aSP2[h]Active":
			return false
	return true
	
func check_semi_invuln():
	return false

# UNIQUE INPUT CAPTURE --------------------------------------------------------------------------------------------------
# some holdable buttons can have effect unique to the character
	
func simulate():
	
#	Character.input_state
#	Character.dir
#	Character.v_dir
	
	# QUICK CANCEL AIR DASH FROM AIR BLOCK ------------------------------------------------------------------------------------
	
#	if Character.state == Globals.char_state.AIR_BLOCK:
#		if Character.button_dash in Character.input_state.pressed and (Character.dir != 0 or Character.v_dir != 0):
#			if Animator.query_to_play(["aBlockStartup"]):
#				if Character.air_dash > 0:
#					Character.animate("aDashTransit")

	# LAND CANCEL --------------------------------------------------------------------------------------------------

	match Character.state:
		
		Globals.char_state.AIR_ATK_ACTIVE:
			if Animator.query_current(["aL2Active"]):
				if Character.grounded:
					Character.animate("aL2LandRec")
					landing_sound()
				elif !Character.button_light in Character.input_state.pressed:
					Character.animate("aL2bRec")
			
			# vertical air strafe for surfboard
			elif Animator.query_current(["aSP2Active", "aSP2[ex]Active"]):
				if Character.v_dir != 0:
					Character.velocity.y += Character.v_dir * 100 * FMath.S
					
#			elif Animator.query_current(["aSP1[c1]Active"]):
#				if Character.button_aux in Character.input_state.pressed:
#					Character.animate("aSP1[c1]Active")
			
		Globals.char_state.AIR_ATK_RECOVERY:
			
			if Animator.query_current(["aL2bRec"]):
				if Character.grounded:
					Character.animate("aL2LandRec")
					landing_sound()
					
			elif Animator.query_current(["aSP3Rec", "aSP3[ex]Rec"]):
				if Character.grounded:
					Character.animate("SP3Rec")
					landing_sound()
					Globals.Game.spawn_SFX("LandDust", "DustClouds", Character.get_feet_pos(), \
								{"facing":Character.facing, "grounded":true})
			
	# RELEASING HELD INPUTS --------------------------------------------------------------------------------------------------
			
		Globals.char_state.GROUND_ATK_STARTUP:
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
							
				"SP1[u][c1]Startup":
					if !Character.button_light in Character.input_state.pressed:
						Character.animate("SP1[u][c1]bStartup")
				"SP1[u][c2]Startup":
					if !Character.button_light in Character.input_state.pressed:
						if Animator.time == 1:
							Character.animate("SP1[u][c3]Startup")
						else:
							Character.animate("SP1[u][c2]bStartup")
			
		Globals.char_state.AIR_ATK_STARTUP:
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
							
				"aSP1[d][c1]Startup":
					if !Character.button_light in Character.input_state.pressed or Character.grounded:
						Character.animate("aSP1[d][c1]bStartup")
				"aSP1[d][c2]Startup":
					if Character.grounded:
						Character.animate("aSP1[d][c2]bStartup")
					elif !Character.button_light in Character.input_state.pressed:
						if Animator.time == 1:
							Character.animate("aSP1[d][c3]Startup")
						else:
							Character.animate("aSP1[d][c2]bStartup")
					

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
	
#	Character.combination_trio(Character.button_special, Character.button_down, Character.button_light, "Sp.dL")
	
	Character.combination(Character.button_special, Character.button_fierce, "Sp.F")
	Character.ex_combination(Character.button_special, Character.button_fierce, "ExSp.F")
	
	Character.combination_trio(Character.button_special, Character.button_up, Character.button_fierce, "Sp.uF")
	Character.ex_combination_trio(Character.button_special, Character.button_up, Character.button_fierce, "ExSp.uF")
	
	Character.ex_combination_trio(Character.button_special, Character.button_down, Character.button_fierce, "ExSp.dF")
	
	Character.combination_trio(Character.button_special, Character.button_light, Character.button_fierce, "Sp.H")
	Character.ex_combination_trio(Character.button_special, Character.button_light, Character.button_fierce, "ExSp.H")
	
#	Character.doubletap_combination(Character.button_special, Character.button_fierce, "SpSp.F")


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
	
	if !Character.get_node("RespawnTimer").is_running() and !Character.get_node("HitStunTimer").is_running():
				
		if "GroundFinTrigger" in Character.instant_actions:
			Character.unique_data.groundfin_trigger = true # flag for triggering
			
		if "BitemarkTriggerU" in Character.instant_actions and Character.get_target() != Character:
			if Character.unique_data.nibbler_count > 0:
				var spawn_point = Character.get_target().position
				spawn_point = Detection.ground_finder(spawn_point, Character.facing, Vector2(0, 150), Vector2(10, 300), 1)
				if spawn_point != null:
					Globals.Game.spawn_entity(Character.player_ID, "NibblerSpawn", spawn_point, {}, Character.palette_number, NAME)
					Character.play_audio("water15", {})
					Character.unique_data.nibbler_count -= 1
					update_uniqueHUD()
						
		if "BitemarkTriggerD" in Character.instant_actions and Character.get_target() != Character:
			if Character.unique_data.nibbler_count > 0:
				var spawn_point = Character.position
				spawn_point = Detection.ground_finder(spawn_point, Character.facing, Vector2(0, 150), Vector2(10, 300), 1)
				if spawn_point != null:
					Globals.Game.spawn_entity(Character.player_ID, "NibblerSpawn", spawn_point, {}, Character.palette_number, NAME)
					Character.play_audio("water15", {})
					Character.unique_data.nibbler_count -= 1
					update_uniqueHUD()
						
		if "BitemarkTrigger" in Character.instant_actions and Character.get_target() != Character:
			if Character.unique_data.nibbler_count > 0:
#				var spawn_point = (get_node(Character.targeted_opponent_path).position + Character.position) * 0.5
#				spawn_point.x = round(spawn_point.x)
#				spawn_point.y = round(spawn_point.y)
				var spawn_point = FMath.find_center([Character.get_target().position, Character.position], Character.facing)
				var spawn_point2 = Detection.ground_finder(spawn_point, Character.facing, Vector2(0, 150), Vector2(10, 300), 1)
				if spawn_point2 == null: # if no ground found below, check above a little
					spawn_point2 = Detection.ground_finder(spawn_point, Character.facing, Vector2(0, -50), Vector2(10, 100), -1)
				if spawn_point2 != null:
					Globals.Game.spawn_entity(Character.player_ID, "NibblerSpawn", spawn_point2, {}, Character.palette_number, NAME)
					Character.play_audio("water15", {})
					Character.unique_data.nibbler_count -= 1
					update_uniqueHUD()


# INPUT BUFFER --------------------------------------------------------------------------------------------------

# called by main character node
func process_buffered_input(new_state, buffered_input, input_to_add, has_acted: Array):
	var keep = true
	match buffered_input[0]:
		
		Character.button_dash:
			if !has_acted[0]:
				match new_state:
					
				# GROUND DASH ---------------------------------------------------------------------------------
			
					Globals.char_state.GROUND_STANDBY, Globals.char_state.CROUCHING, Globals.char_state.GROUND_C_RECOVERY:
						if keep and !Character.button_light in Character.input_state.just_pressed and \
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
							
				# AIR DASH ---------------------------------------------------------------------------------
					
					Globals.char_state.AIR_STANDBY, Globals.char_state.AIR_C_RECOVERY:
						
						if Animator.query(["aDashBrake"]) and !Character.has_trait(Globals.trait.AIR_CHAIN_DASH):
							continue
						
						if Character.air_dash > 0:
							
							if Character.v_dir > 0 and Character.button_jump in Character.input_state.pressed and \
									Character.is_button_tapped_in_last_X_frames(Character.button_jump, 1) and \
									Character.check_snap_up() and \
									Character.snap_up(Character.get_node("PlayerCollisionBox"), Character.get_node("DashLandDBox")): # for easy wavedashing on soft platforms
								# cannot snap up if jump is pressed more than 1 frame ago, to allow easier down dash after fallthrough

								Character.animate("JumpTransit") # if snapping up while falling downward, instantly wavedash
								input_to_add.append([Character.button_dash, Settings.input_buffer_time[Character.player_ID]])
										
							else: # not in snap range
								Character.animate("aDashTransit")
								if Animator.query_current(["JumpTransit2"]): # if starting an air dash on the 1st frame after a ground jump
									Character.velocity.y = FMath.percent(Character.velocity.y, 50)
							keep = false
							
					Globals.char_state.AIR_STARTUP: # cancel start of air jump into air dash, used for up-dashes
						if Animator.query(["aJumpTransit", "WallJumpTransit", "aJumpTransit2", "WallJumpTransit2"]):
							if Character.air_dash > 0:
								Character.animate("aDashTransit")
								keep = false

								
				# DASH CANCELS ---------------------------------------------------------------------------------
					# if land a sweetspot hit, can dash cancel on active
								
					Globals.char_state.GROUND_ATK_RECOVERY:
						if Character.test_dash_cancel():
							Character.animate("DashTransit")
							keep = false
					
					Globals.char_state.GROUND_ATK_ACTIVE:
						if Character.active_cancel:
							Character.afterimage_cancel() # need to do this manually for active cancel
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
				keep = !process_move(new_state, "L1", has_acted)
		
		Character.button_fierce:
			if !has_acted[0]:
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
				
		"Sp.L":
			if !has_acted[0]:
				if test_instinct():
					keep = !process_move(new_state, "SP7", has_acted)
				else:
					keep = !process_move(new_state, "SP1", has_acted)
				
#		"Sp.dL":
#			if !has_acted[0]:
#				if test_instinct():
#					keep = !process_move(new_state, "SP7", has_acted)
	
		"Sp.F":
			if !has_acted[0]:
				if !Character.grounded:
					keep = !process_move(new_state, "SP2", has_acted)
				else:
					if Character.unique_data.groundfin_count == 0:
						keep = !process_move(new_state, "SP4", has_acted)
						
		"Sp.uF":
			if !has_acted[0]:
				keep = !process_move(new_state, "SP3", has_acted)
				
		"Sp.H":
			if !has_acted[0]:
				keep = !process_move(new_state, "SP5", has_acted)
				
		"ExSp.L":
			if !has_acted[0]:
				keep = !process_move(new_state, "SP1[ex]", has_acted)
				if keep:
					keep = !process_move(new_state, "SP1", has_acted)

		"ExSp.F":
			if !has_acted[0]:
				if !Character.grounded:
					keep = !process_move(new_state, "SP2[ex]", has_acted)
					if keep:
						keep = !process_move(new_state, "SP2", has_acted)
				else:
					if Character.unique_data.groundfin_count <= 1:
						keep = !process_move(new_state, "SP4[ex]", has_acted)	
						if keep:
							keep = !process_move(new_state, "SP4", has_acted)
							
		"ExSp.uF":
			if !has_acted[0]:
				keep = !process_move(new_state, "SP3[ex]", has_acted)
				if keep:
					keep = !process_move(new_state, "SP3", has_acted)
			
		"ExSp.dF":
			if !has_acted[0]:
#				if !Character.impulse_used:
				keep = !process_move(new_state, "SP6[ex]", has_acted)
				
		"ExSp.H":
			if !has_acted[0]:
				keep = !process_move(new_state, "SP5[ex]", has_acted)
				if keep:
					keep = !process_move(new_state, "SP5", has_acted)
						
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

	
func process_move(new_state, attack_ref: String, has_acted: Array): # return true if button consumed
	
	 # no attacking during respawn grace
	if Character.query_status_effect(Globals.status_effect.RESPAWN_GRACE):
		if Globals.survival_level != null and Inventory.has_quirk(Character.player_ID, Cards.effect_ref.RESPAWN_POWER):
			pass
		else:
			return true
	
	if Character.grounded and Character.button_jump in Character.input_state.pressed:
		return false # since this will trigger instant aerial
	
	match Character.state:
		Globals.char_state.GROUND_STARTUP: # can attack on 1st frame of ground dash
			if Animator.query_current(["DashTransit"]) and attack_ref in STARTERS:
				if Character.test_qc_chain_combo(attack_ref):
					if Character.is_ex_valid(attack_ref):
						Character.animate(attack_ref + "Startup")
						has_acted[0] = true
						return true
		Globals.char_state.AIR_STARTUP: # can attack on 1st frames of air dash
			if Animator.query_current(["aDashTransit"]) and ("a" + attack_ref) in STARTERS and Character.test_aerial_memory("a" + attack_ref):
				if Character.test_qc_chain_combo("a" + attack_ref):
					if Character.is_ex_valid("a" + attack_ref):
						Character.animate("a" + attack_ref + "Startup")
						has_acted[0] = true
						return true
						
	match new_state:
			
		Globals.char_state.GROUND_STANDBY, Globals.char_state.CROUCHING, Globals.char_state.GROUND_C_RECOVERY, Globals.char_state.GROUND_D_RECOVERY:
			if Character.grounded and attack_ref in STARTERS:
				if new_state in [Globals.char_state.GROUND_C_RECOVERY, Globals.char_state.GROUND_D_RECOVERY] and \
						Globals.atk_attr.NOT_FROM_MOVE_REC in query_atk_attr(attack_ref):
					continue # certain moves cannot be performed during cancellable recovery
				if Character.is_ex_valid(attack_ref):
					Character.animate(attack_ref + "Startup")
					has_acted[0] = true
					return true
					
		Globals.char_state.GROUND_STARTUP: # grounded up-tilt can be done during ground jump transit if jump is not pressed
			if Character.grounded and attack_ref in UP_TILTS and Animator.query_to_play(["JumpTransit"]) and \
					Character.test_qc_chain_combo(attack_ref):
				if Character.is_ex_valid(attack_ref):
					Character.animate(attack_ref + "Startup")
					has_acted[0] = true
					return true
					
		Globals.char_state.AIR_STANDBY, Globals.char_state.AIR_C_RECOVERY, Globals.char_state.AIR_D_RECOVERY:
			if !Character.grounded: # must be currently not grounded even if next state is still considered an aerial state
				if ("a" + attack_ref) in STARTERS and Character.test_aerial_memory("a" + attack_ref):
					if new_state in [Globals.char_state.AIR_C_RECOVERY, Globals.char_state.AIR_D_RECOVERY] and \
							Globals.atk_attr.NOT_FROM_MOVE_REC in query_atk_attr("a" + attack_ref):
						continue # certain moves cannot be performed during cancellable recovery
					if Character.is_ex_valid("a" + attack_ref):
						Character.animate("a" + attack_ref + "Startup")
						has_acted[0] = true
						return true
						
		Globals.char_state.AIR_STARTUP: # aerial up-tilt can be done during air jump transit if jump is not pressed
			if ("a" + attack_ref) in UP_TILTS and Character.test_aerial_memory("a" + attack_ref) and \
					!Character.button_jump in Character.input_state.pressed and \
					Animator.query_to_play(["aJumpTransit", "aJumpTransit2", "WallJumpTransit", "WallJumpTransit2"]) and \
					Character.test_qc_chain_combo("a" + attack_ref):
				if Character.is_ex_valid("a" + attack_ref):
					Character.animate("a" + attack_ref + "Startup")
					has_acted[0] = true
					return true
				
		# chain cancel
		Globals.char_state.GROUND_ATK_RECOVERY, Globals.char_state.GROUND_ATK_ACTIVE:
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
		Globals.char_state.AIR_ATK_STARTUP:
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
	
#func gain_one_air_dash(): # different characters can have different types of air_dash consumption
#	if Character.air_dash < Character.get_stat("MAX_AIR_DASH"): # cannot go over
#		Character.air_dash += 1

func afterimage_trail():# process afterimage trail
	match Animator.to_play_animation:
		"Dash", "aDash", "aDashD", "aDashU", "SDashTransit", "SDash", "aSDash":
			Character.afterimage_trail()
		"Dodge":
			Character.afterimage_trail(null, 0.6, 10, Globals.afterimage_shader.WHITE)
		"DodgeRec", "DodgeCRec":
			Character.afterimage_trail()
		"SP6[ex]SeqB", "SP6[ex]SeqC", "SP6[ex]SeqD":
			Character.afterimage_trail()
			
func unique_flash():
	match Animator.to_play_animation:
		"SP1[c2]Startup", "SP1[u][c2]Startup", "aSP1[c2]Startup", "aSP1[d][c2]Startup":
			Character.get_node("ModulatePlayer").play("darken")
			
# GET DATA --------------------------------------------------------------------------------------------------

func get_stat(stat: String): # later can have effects that changes stats
	var to_return = get(stat)
	
	
	
	return to_return
	
	
func query_traits(): # may have special conditions
	return TRAITS
			
func get_root(move_name): # for aerial and chain memory, only needed for versions with active frames not in MOVE_DATABASE
	
	if move_name in MOVE_DATABASE and "root" in MOVE_DATABASE[move_name]:
		return MOVE_DATABASE[move_name].root
		
	match move_name:
		"F3[h]":
			return "F3"
		
		"SP1[c1]", "SP1[c2]", "SP1[c3]", "SP1[u][c1]", "SP1[u][c2]", "SP1[u][c3]", \
				"aSP1[c1]", "aSP1[c2]", "aSP1[c3]", "aSP1[d][c1]", "aSP1[d][c2]", "aSP1[d][c3]":
			return "SP1"
		"SP1[ex]", "SP1[u][ex]", "aSP1[ex]", "aSP1[d][ex]":
			return "SP1[ex]"
			
		"aSP1": # for startup for aerial memory
			return "SP1"

		"aSP7":
			return "SP7"
	
	return move_name
		
			
func refine_move_name(move_name):
		
	match move_name:
		"L2b":
			return "L2"
		"F2[h]P":
			return "F2[h]"
		"F3[b]", "F3[h]":
			return "F3"

		"aL2b", "aL2Land":
			return "aL2"
		"aF1[h]":
			return "aF1"
		"aF2Grab", "aF2bGrab":
			return "aF2"
		"SP1[b]", "aSP1", "aSP1[b]", "SP1[c1]", "SP1[c2]", "SP1[c1]b", "SP1[c2]b", "SP1[c3]", "aSP1[c1]", "aSP1[c2]", "aSP1[c1]b", "aSP1[c2]b", "aSP1[c3]", \
			"SP1[u]", "SP1[u][c1]", "SP1[u][c2]", "SP1[u][c1]b", "SP1[u][c2]b", "SP1[u][c3]", \
			"aSP1[d]", "aSP1[d][c1]", "aSP1[d][c2]", "aSP1[d][c1]b", "aSP1[d][c2]b", "aSP1[d][c3]":
			return "SP1"
		"SP1[b][ex]", "aSP1[ex]", "aSP1[b][ex]", "SP1[u][ex]", "aSP1[d][ex]":
			return "SP1[ex]"
		"SP3":
			return "aSP3"
		"SP3b":
			return "aSP3b"
		"SP3[h]": 
			return "aSP3[h]"
		"SP3b[h]": 
			return "aSP3b[h]"
		"SP3[ex]": 
			return "aSP3[ex]"
		"SP3b[ex]": 
			return "aSP3b[ex]"
		"SP5", "SP5b", "aSP5b":
			return "aSP5"
		"SP5[ex]", "SP5b[ex]", "aSP5b[ex]":
			return "aSP5[ex]"
		"SP6[ex]", "SP6[ex]Grab", "aSP6[ex]Grab":
			return "aSP6[ex]"
		"aSP7":
			return "SP7"
	return move_name
			
			
func query_move_data(move_name) -> Dictionary: # can change under conditions
	
	var orig_move_name = move_name
	move_name = refine_move_name(move_name)
	
	if !move_name in MOVE_DATABASE:
		print("Error: Cannot retrieve move_data for " + move_name)
		return {}
	
	var move_data = MOVE_DATABASE[move_name].duplicate(true)
	move_data["atk_attr"] = query_atk_attr(orig_move_name)
	
	match orig_move_name:
		_:
			pass
			
	if Globals.survival_level != null and "damage" in move_data:
#		move_data.damage = FMath.percent(move_data.damage, Character.SURV_BASE_DMG)
		move_data.damage = FMath.percent(move_data.damage, Character.mod_damage(move_name))


	return move_data


						
func query_atk_attr(move_name) -> Array: # can change under conditions

	var orig_move_name = move_name
	move_name = refine_move_name(move_name)

	var atk_attr := []
	if move_name in MOVE_DATABASE and "atk_attr" in MOVE_DATABASE[move_name]:
		atk_attr = MOVE_DATABASE[move_name].atk_attr.duplicate(true)
	else:
		print("Error: Cannot retrieve atk_attr for " + move_name)
		return []
	
	match orig_move_name: # can add various atk_attr to certain animations under under conditions
		"F3[h]":
			atk_attr.append_array([Globals.atk_attr.NORMALARMOR_STARTUP])

		"SP3", "SP3b", "SP3[h]", "SP3b[h]": 
			atk_attr.append_array([Globals.atk_attr.ANTI_AIR])
		"SP3[ex]", "SP3b[ex]": 
			atk_attr.append_array([Globals.atk_attr.ANTI_AIR, Globals.atk_attr.SEMI_INVUL_STARTUP])
		
#	if Globals.survival_level != null: # no anti-air normals during Survival Mode
#		if move_name in MOVE_DATABASE and "atk_type" in MOVE_DATABASE[move_name] and \
#				MOVE_DATABASE[move_name].atk_type in [Globals.atk_type.LIGHT, Globals.atk_type.FIERCE] and \
#				Globals.atk_attr.ANTI_AIR in atk_attr:
#			while Globals.atk_attr.ANTI_AIR in atk_attr:	
#				atk_attr.erase(Globals.atk_attr.ANTI_AIR)
		
	return atk_attr
	

# HIT REACTIONS --------------------------------------------------------------------------------------------------

func landed_a_hit(hit_data): # reaction, can change hit_data from here
	
	match hit_data.move_name:
		"aL2":
			Character.animate("aL2Rec")
		"L2":
			Character.animate("L2Rec")
			
		"F2[h]":
			if !"tough_mob" in hit_data and hit_data.sweetspotted and !hit_data.stun and !hit_data.lethal_hit:
				hit_data.move_data.KB_angle = 180
				hit_data.move_data.knockback = 200 * FMath.S
				hit_data["pull"] = true
				hit_data.move_data.atk_attr.append(Globals.atk_attr.DI_MANUAL_SEAL)
				Character.animate("F2[h]PRec")
			
		"aF2":
			if !"tough_mob" in hit_data and hit_data.sweetspotted:
				hit_data.move_data["sequence"] = "aF2SeqA"
			
		"aSP5", "aSP5[h]b":
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
			

func being_hit(hit_data):
#	var defender = get_node(hit_data.defender_nodepath)
					
	if hit_data.block_state in [Globals.block_state.UNBLOCKED]:
		Character.unique_data.nibbler_cancel = 2 # cancel spawning nibblers
		Character.unique_data.nibbler_count = max(Character.unique_data.nibbler_count - 1, 0)
		update_uniqueHUD()
		
	
# AUTO SEQUENCES --------------------------------------------------------------------------------------------------

func simulate_sequence(): # this is ran on every frame during a sequence
	
	var Partner = Character.get_seq_partner()
	if Partner == null:
		Character.animate("Idle")
		return
	
	match Animator.to_play_animation:
		"SP6[ex]SeqA":
			if Animator.time == 10:
				Globals.Game.spawn_SFX("HitsparkB", "HitsparkB", Animator.query_point("grabpoint"), {"facing":-Character.facing}, \
						Character.get_default_hitspark_palette())
				Character.play_audio("cut1", {"vol":-12})
		"SP6[ex]SeqB":
			if Character.dir != 0: # can air strafe when going up
				Character.velocity.x += Character.dir * 10 * FMath.S
			else:
				Character.velocity.x = FMath.f_lerp(Character.velocity.x, 0, 20) # air res
			Character.velocity.x = clamp(Character.velocity.x, -100 * FMath.S, 100 * FMath.S) # max air strafe speed
			Character.velocity.y += 18 * FMath.S # gravity
			if Animator.time in [0, 21]:
				Character.play_audio("whoosh3", {"vol":-10})
		"SP6[ex]SeqC":
			Character.velocity.x = FMath.f_lerp(Character.velocity.x, 0, 20) # air res
		"SP6[ex]SeqD":
			Partner.afterimage_trail()
			if Character.grounded: end_sequence_step("ground")
		"SP6[ex]SeqE":
			pass
						
func simulate_sequence_after(): # called after moving and animating every frame, grab_point and grab_rot_dir are only updated then
	
	var Partner = Character.get_seq_partner()
	if Partner == null:
		Character.animate("Idle")
		return
		
	var grab_point = Animator.query_point("grabpoint")
	
	match Animator.to_play_animation:
		"aF2SeqA", "aF2SeqB":
			move_sequence_target(grab_point)
			rotate_partner(Partner)
		
		"SP6[ex]SeqA", "SP6[ex]SeqB", "SP6[ex]SeqC", "SP6[ex]SeqD":
			move_sequence_target(grab_point)
			rotate_partner(Partner)
		"SP6[ex]SeqE":
			pass
					
						

			
						
func start_sequence_step(): # this is ran at the start of every sequence_step
	var Partner = Character.get_seq_partner()
	if Partner == null:
		Character.animate("Idle")
		return

	match Animator.to_play_animation:
		"aF2SeqA":
			Globals.Game.get_node("Players").move_child(Character, 0)
			Character.velocity.set_vector(0, 0)
			Partner.velocity.set_vector(0, 0)
			Partner.animate("aSeqFlinchAFreeze")
			Partner.face(-Character.facing)
			rotate_partner(Partner)
			Partner.get_node("ModulatePlayer").play("unlaunch_flash")
			Character.play_audio("cut2", {"vol":-15})
			Globals.Game.spawn_SFX("HitsparkC", "HitsparkC", Animator.query_point("grabpoint"), {"facing":-Character.facing, \
					"rot":deg2rad(-70)}, Character.get_default_hitspark_palette())
		"aF2SeqB":
			Character.velocity.set_vector(150 * FMath.S * Character.facing, 0)
			Character.velocity.rotate(70 * Character.facing)
			Character.play_audio("whoosh15", {"vol":-8})
			Character.play_audio("whoosh3", {"vol":-13, "bus":"PitchDown"})
			
		"SP6[ex]SeqA":
			Globals.Game.get_node("Players").move_child(Character, 0) # move Grabber to back, some grabs move Grabbed to back
			Character.velocity.set_vector(0, 0) # freeze first
			Partner.velocity.set_vector(0, 0)
			Partner.animate("aSeqFlinchAFreeze")
			Partner.face(-Character.facing)
			rotate_partner(Partner)
			Partner.get_node("ModulatePlayer").play("unlaunch_flash")
			Character.play_audio("impact29", {"vol":-20})
		"SP6[ex]SeqB":
			Character.velocity.set_vector(0, -500 * FMath.S)  # jump up
			if Character.grounded:
				Globals.Game.spawn_SFX("BigSplash", "BigSplash", Character.get_feet_pos(), \
						{"facing":Globals.Game.rng_facing(), "grounded":true, "back":true}, Character.palette_number, NAME)
				Character.play_audio("water4", {"vol" : -20})
#				Globals.Game.spawn_SFX("JumpDust", "DustClouds", Character.get_feet_pos(), {"facing":Character.facing, "grounded":true})
#				Globals.Game.spawn_SFX("BounceDust", "DustClouds", Character.get_feet_pos(), {"facing":Character.facing, "grounded":true})
		"SP6[ex]SeqC":
			Character.velocity.set_vector(0, 600 * FMath.S)  # dive down
			Globals.Game.spawn_SFX("WaterJet", "WaterJet", Character.position, \
					{"facing":Character.facing, "rot":PI/2}, Character.palette_number, NAME)
			Character.play_audio("water14", {})
		"SP6[ex]SeqE":  # you hit ground
			Partner.sequence_hit(0)
			Character.velocity.set_vector(0, 0)
			Partner.move_sequence_player_by(Vector2(0, Character.get_feet_pos().y - Partner.get_feet_pos().y)) # move opponent down to your level
			Globals.Game.spawn_SFX("BounceDust", "DustClouds", Character.get_feet_pos(), {"facing":Character.facing, "grounded":true})
			Globals.Game.spawn_SFX("BigSplash", "BigSplash", Partner.get_feet_pos(), \
					{"facing":Globals.Game.rng_facing(), "grounded":true}, Character.palette_number, NAME)
			Globals.Game.spawn_SFX("HitsparkD", "HitsparkD", Partner.get_feet_pos(), {"facing":Character.facing, "rot":PI/2}, \
					Character.get_default_hitspark_palette())
			Globals.Game.set_screenshake()
			Character.play_audio("impact41", {"vol":-15, "bus":"LowPass"})
			Character.play_audio("rock3", {})
		"aSP6[ex]SeqE":  # parther hit the ground but not you
			Partner.sequence_hit(0)
			Character.velocity.set_vector(0, 0)
			Globals.Game.spawn_SFX("BigSplash", "BigSplash", Partner.get_feet_pos(), \
					{"facing":Globals.Game.rng_facing(), "grounded":true}, Character.palette_number, NAME)
			Globals.Game.spawn_SFX("BounceDust", "DustClouds", Partner.get_feet_pos(), {"facing":Character.facing, "grounded":true})
			Globals.Game.spawn_SFX("HitsparkD", "HitsparkD", Partner.get_feet_pos(), {"facing":Character.facing, "rot":PI/2}, \
					Character.get_default_hitspark_palette())
			Globals.Game.set_screenshake()
			Character.play_audio("impact41", {"vol":-15, "bus":"LowPass"})
			Character.play_audio("rock3", {"vol":-5})
							
func end_sequence_step(trigger = null): # this is ran at the end of certain sequence_step, or to end a trigger sequence_step
	# return true if sequence_step ended
	
	var Partner = Character.get_seq_partner()
	if Partner == null:
		Character.animate("Idle")
		return
	
	if trigger == "break": # grab break
		Character.animate("Idle")
		Partner.animate("Idle")
		return true
	
	match Animator.to_play_animation:
		"aF2SeqB":
			Partner.sequence_launch()
			return true
		
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
	var seq_hit_data = MOVE_DATABASE[Animator.to_play_animation].sequence_hits[hit_key].duplicate(true)

	if Globals.survival_level != null and "damage" in seq_hit_data:
#		seq_hit_data.damage = FMath.percent(seq_hit_data.damage, Character.SURV_BASE_DMG)	
		seq_hit_data.damage = FMath.percent(seq_hit_data.damage, Character.mod_damage(MOVE_DATABASE[Animator.to_play_animation].starter))

	return seq_hit_data
	
	
	
func get_seq_launch_data():
	var seq_data = MOVE_DATABASE[Animator.to_play_animation].sequence_launch.duplicate(true)

	if Globals.survival_level != null and "damage" in seq_data:
#		seq_data.damage = FMath.percent(seq_data.damage, Character.SURV_BASE_DMG)	
		seq_data.damage = FMath.percent(seq_data.damage, Character.mod_damage(MOVE_DATABASE[Animator.to_play_animation].starter))

	return seq_data
			
			
			
func sequence_fallthrough(): # which step in sequence ignore soft platforms
	match Animator.to_play_animation:
		"SP6[ex]SeqA", "SP6[ex]SeqB", "SP6[ex]SeqC":
			return true
	return false
	
func sequence_ledgestop(): # which step in sequence are stopped by ledges
	return false
	
func sequence_passthrough(): # which step in sequence ignore all platforms (for cinematic supers)
	return false
	
func sequence_partner_passthrough(): # which step in sequence has partner ignore all platforms
	return false
	
#func sequence_passfloor(): # which step in sequence ignore hard floor
#	match Animator.to_play_animation:
#		"SP6[ex]SeqA", "SP6[ex]SeqB", "SP6[ex]SeqC":
#			return true
#	return false
	
	
# CODE FOR CERTAIN MOVES ---------------------------------------------------------------------------------------------------

#func unique_chaining_rules(move_name, attack_ref):
#	if Character.is_atk_recovery() and attack_ref == "SP7" and move_name in ["SP1", "aSP1", "SP1[ex]", "aSP1[ex]"]:
#		return true # can chain Akontio: Instinct from recovery of Akontio
#	return false
	
func unique_chaining_rules(move_name, attack_ref):
	if Character.is_atk_recovery() and refine_move_name(move_name) in ["SP1", "SP1[ex]"] and refine_move_name(attack_ref) == "SP7":
		return true
	return false
	
#func get_trident_array(): # return array of all spinnable tridents
#	var trident_array := []
#	for entity in Globals.Game.get_node("EntitiesFront").get_children():
#		if entity.master_ID == Character.player_ID and "ID" in entity.UniqEntity and entity.UniqEntity.ID == "trident":
#			if entity.hitcount_record.size() == 0 and entity.Animator.to_play_animation in ["[c2]Active", "[u][c2]Active", "[ex]Active", \
#					"[u][ex]Active", "[c3]Active", "[u][c3]Active"]:
#				trident_array.append(entity)
#	return trident_array
			
func test_instinct(): # to determine if move is usable
	if Character.unique_data.last_trident == null: return false
	
	var last_trident = Globals.Game.get_entity_node(Character.unique_data.last_trident)
	if last_trident == null: return false
	
	if last_trident.hitcount_record.size() == 0 and last_trident.Animator.to_play_animation in ["[c2]Active", "[u][c2]Active", "[ex]Active", \
			"[u][ex]Active", "[c3]Active", "[u][c3]Active"]:
		return true	
	return false
	
#	if get_trident_array().size() > 0: return true
#	return false
	
func instinct():
	
	if Character.unique_data.last_trident == null: return
	
	var last_trident = Globals.Game.get_entity_node(Character.unique_data.last_trident)
	if last_trident == null: return
	
	last_trident.UniqEntity.spin()
	
#	var trident_array = get_trident_array()
#
#	var to_spin = null
#	var lowest_lifetime = null
#	for trident in trident_array: # get youngest trident
#		if lowest_lifetime == null or trident.lifetime < lowest_lifetime:
#			to_spin = trident
#			lowest_lifetime = trident.lifetime
#
#	if to_spin != null:
#		to_spin.UniqEntity.spin()
			



# ANIMATION AND AUDIO PROCESSING ---------------------------------------------------------------------------------------------------
# these are ran by main character node when it gets the signals so that the order is easier to control

func _on_SpritePlayer_anim_finished(anim_name):
	
	match anim_name:
		"DashTransit":
			Character.animate("Dash")
		"Dash":
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
#		"SDash":
#			if !Character.grounded:
#				Character.animate("aDashBrake")
#			else:
#				Character.animate("DashBrake")
			
		"L1Startup":
			Character.animate("L1Active")
		"L1Active":
			Character.animate("L1Rec")
		"L1Rec":
			if Character.held_version(Character.button_light):
				Character.animate("L1b[h]Active")
			else:
				Character.animate("L1bActive")
		"L1bActive":
			Character.animate("L1bRec")
		"L1bRec":
			Character.animate("Idle")
		"L1b[h]Active":
			Character.animate("L1b[h]Rec")
		"L1b[h]Rec":
			Character.animate("L1cActive")
		"L1cActive":
			Character.animate("L1cRec")
		"L1cRec":
			Character.animate("Idle")
			
		"L2Startup":
			Character.animate("L2Active")
		"L2Active":
			if Character.is_on_ground(Character.get_node("SoftPlatformDBox")):
				Character.animate("L2bRec")
			else:
				Character.animate("L2cCRec")
		"L2Rec":
			Character.animate("FallTransit")
		"L2bRec":
			Character.animate("Idle")
		"L2cCRec":
			Character.animate("FallTransit")
			
		"L3Startup":
			Character.animate("L3Active")
		"L3Active":
			Character.animate("L3Rec")
		"L3Rec":
			Character.animate("Idle")
			
		"F1Startup":
			Character.animate("F1Active")
		"F1Active":
			Character.animate("F1Rec")
		"F1Rec":
			Character.animate("Idle")
			
		"F2Startup":
			if Character.held_version(Character.button_fierce):
				Character.animate("F2[h]Active")
			else:
				Character.animate("F2Active")
		"F2Active":
			Character.animate("F2Rec")
		"F2[h]Active":
			Character.animate("F2[h]Rec")
		"F2Rec":
			Character.animate("Idle")
		"F2[h]Rec":
			Character.animate("Idle")
		"F2[h]PRec":
			Character.animate("Idle")
			
		"F3Startup":
			if Globals.survival_level == null and Character.held_version(Character.button_fierce):
				Character.animate("F3[h]Startup")
			else:
				Character.animate("F3[b]Startup")
		"F3[b]Startup":
			Character.animate("F3Active")
		"F3[h]Startup":
			Character.animate("F3[h]Active")
		"F3Active":
			Character.animate("F3Rec")
		"F3[h]Active":
			Character.animate("F3Rec")
		"F3Rec":
			Character.animate("Idle")

		"HStartup":
			Character.animate("HActive")
		"HActive":
			Character.animate("HbActive")
		"HbActive":
			Character.animate("HbRec")
		"HbRec":
			Character.animate("Idle")

		"aL1Startup":
			Character.animate("aL1Active")
		"aL1Active":
			Character.animate("aL1Rec")
		"aL1Rec":
			Character.animate("FallTransit")

		"aL2Startup":
			Character.animate("aL2Active")
		"aL2Rec":
			if Character.held_version(Character.button_light):
				Character.animate("aL2Startup")
			else:
				Character.animate("aL2bRec")
		"aL2bRec":
			Character.animate("FallTransit")
		"aL2LandRec":
			Character.animate("Crouch")
			
		"aL3Startup":
			Character.animate("aL3Active")
		"aL3Active":
			Character.animate("aL3Rec")
		"aL3Rec":
			Character.animate("FallTransit")

		"aF1Startup":
#			if get("STYLE") == 0:
			if Character.held_version(Character.button_fierce):
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
			Character.animate("aF1Rec")
		"aF1Rec":
			Character.animate("FallTransit")

		"aF2Startup":
			Character.animate("aF2Active")
		"aF2Active":
			Character.animate("aF2Rec")
		"aF2Rec":
			Character.animate("FallTransit")

		"aF2SeqA":
			Character.animate("aF2SeqB")
		"aF2SeqB":
			end_sequence_step()
			Character.animate("aF2GrabRec")
		"aF2GrabRec":
			Character.animate("FallTransit")

		"aF3Startup":
			Character.animate("aF3Active")
		"aF3Active":
			Character.animate("aF3Rec")
		"aF3Rec":
			Character.animate("FallTransit")
	
		"aHStartup":
			Character.animate("aHActive")
		"aHActive":
			Character.animate("aHRec")
		"aHRec":
			Character.animate("FallTransit")
			
		"SP1Startup":
			if Character.button_up in Character.input_state.pressed:
				Character.animate("SP1[u]Startup")
			else:
				Character.animate("SP1[b]Startup")
		"SP1[b]Startup":
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
			Character.animate("SP1Rec")
		"SP1Rec":
			Character.animate("Idle")
			
		"SP1[u]Startup":
			Character.animate("SP1[u][c1]Startup")
		"SP1[u][c1]Startup":
			Character.animate("SP1[u][c2]Startup")
		"SP1[u][c2]Startup":
			Character.animate("SP1[u][c3]Startup")
		"SP1[u][c1]bStartup":
			Character.animate("SP1[u][c1]Active")
		"SP1[u][c2]bStartup":
			Character.animate("SP1[u][c2]Active")
		"SP1[u][c3]Startup":
			Character.animate("SP1[u][c3]Active")
		"SP1[u][c1]Active", "SP1[u][c2]Active", "SP1[u][c3]Active":
			Character.animate("SP1Rec")
			
		"aSP1Startup":
			if Character.button_down in Character.input_state.pressed:
				Character.animate("aSP1[d]Startup")
			else:
				Character.animate("aSP1[b]Startup")
		"aSP1[b]Startup":
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
			Character.animate("aSP1Rec")
		"aSP1Rec":
			Character.animate("FallTransit")
			
		"aSP1[d]Startup":
			Character.animate("aSP1[d][c1]Startup")
		"aSP1[d][c1]Startup":
			Character.animate("aSP1[d][c2]Startup")
		"aSP1[d][c2]Startup":
			Character.animate("aSP1[d][c3]Startup")
		"aSP1[d][c1]bStartup":
			Character.animate("aSP1[d][c1]Active")
		"aSP1[d][c2]bStartup":
			Character.animate("aSP1[d][c2]Active")
		"aSP1[d][c3]Startup":
			Character.animate("aSP1[d][c3]Active")
		"aSP1[d][c1]Active", "aSP1[d][c2]Active", "aSP1[d][c3]Active":
			Character.animate("aSP1Rec")
			
		"SP1[ex]Startup":
			if Character.button_up in Character.input_state.pressed:
				Character.animate("SP1[u][ex]Startup")
			else:
				Character.animate("SP1[b][ex]Startup")
		"SP1[b][ex]Startup":
			Character.animate("SP1[ex]Active")
		"SP1[ex]Active":
			Character.animate("SP1[ex]Rec")
		"SP1[ex]Rec":
			Character.animate("Idle")
			
		"SP1[u][ex]Startup":
			Character.animate("SP1[u][ex]Active")
		"SP1[u][ex]Active":
			Character.animate("SP1[ex]Rec")
			
		"aSP1[ex]Startup":
			if Character.button_down in Character.input_state.pressed:
				Character.animate("aSP1[d][ex]Startup")
			else:
				Character.animate("aSP1[b][ex]Startup")
		"aSP1[b][ex]Startup":
			Character.animate("aSP1[ex]Active")
		"aSP1[ex]Active":
			Character.animate("aSP1[ex]Rec")
		"aSP1[ex]Rec":
			Character.animate("FallTransit")
			
		"aSP1[d][ex]Startup":
			Character.animate("aSP1[d][ex]Active")
		"aSP1[d][ex]Active":
			Character.animate("aSP1[ex]Rec")
			
		"aSP2Startup":
			if Character.held_version(Character.button_fierce):
				Character.animate("aSP2[h]Active")
			else:
				Character.animate("aSP2Active")
		"aSP2Active":
			Character.animate("aSP2Rec")
		"aSP2[h]Active":
			Character.animate("aSP2[h]Rec")
		"aSP2[h]Rec":
			Character.animate("aSP2Rec")
		"aSP2Rec":
			Character.animate("aSP2CRec")
		"aSP2CRec":
			Character.animate("FallTransit")
				
		"aSP2[ex]Startup":
			Character.animate("aSP2[ex]Active")
		"aSP2[ex]Active":
			Character.animate("aSP2Rec")
			
		"SP3Startup":
			if Character.held_version(Character.button_fierce):
				Character.animate("SP3[h]Startup")
			else:
				Character.animate("SP3Active")
				Globals.Game.spawn_SFX("BigSplash", "BigSplash", Character.get_feet_pos(), \
						{"facing":Globals.Game.rng_facing(), "grounded":true, "back":true}, Character.palette_number, NAME)
		"aSP3Startup":
			if Character.held_version(Character.button_fierce):
				Character.animate("aSP3[h]Startup")
			else:
				Character.animate("aSP3Active")
				Globals.Game.spawn_SFX("WaterJet", "WaterJet", Character.position, {"facing":Character.facing, "rot":-PI/2}, \
						Character.palette_number, NAME)
#		"aSP3bStartup":
#			Character.animate("aSP3Active")
		"SP3[h]Startup":
			Character.animate("SP3[h]Active")
			Globals.Game.spawn_SFX("BigSplash", "BigSplash", Character.get_feet_pos(), \
					{"facing":Globals.Game.rng_facing(), "grounded":true, "back":true}, Character.palette_number, NAME)
		"aSP3[h]Startup":
			Character.animate("aSP3[h]Active")
			Globals.Game.spawn_SFX("WaterJet", "WaterJet", Character.position, {"facing":Character.facing, "rot":-PI/2}, \
					Character.palette_number, NAME)
		"aSP3Active":
			Character.animate("aSP3bActive")
		"aSP3[h]Active":
			Character.animate("aSP3b[h]Active")
		"SP3Active":
			Character.animate("SP3bActive")
		"SP3[h]Active":
			Character.animate("SP3b[h]Active")
		"aSP3bActive", "aSP3b[h]Active", "SP3bActive", "SP3b[h]Active":
			Character.animate("aSP3Rec")
		"aSP3Rec":
			Character.animate("FallTransit")
		"SP3Rec":
			Character.animate("Idle")
			
		"SP3[ex]Startup":
			Character.animate("SP3[ex]Active")
			Globals.Game.spawn_SFX("BigSplash", "BigSplash", Character.get_feet_pos(), \
					{"facing":Globals.Game.rng_facing(), "grounded":true, "back":true}, Character.palette_number, NAME)
		"aSP3[ex]Startup":
			Character.animate("aSP3[ex]Active")
			Globals.Game.spawn_SFX("WaterJet", "WaterJet", Character.position, {"facing":Character.facing, "rot":-PI/2}, \
					Character.palette_number, NAME)
		"aSP3[ex]Active":
			Character.animate("aSP3b[ex]Active")
		"aSP3b[ex]Active":
			Character.animate("aSP3[ex]Rec")
		"SP3[ex]Active":
			Character.animate("SP3b[ex]Active")
		"SP3b[ex]Active":
			Character.animate("aSP3[ex]Rec")
		"aSP3[ex]Rec":
			Character.animate("FallTransit")
			
		"SP4Startup":
			if Character.held_version(Character.button_fierce):
				Character.animate("SP4[h]Active")
			else:
				Character.animate("SP4Active")
		"SP4[ex]Startup":
			Character.animate("SP4[ex]Active")
		"SP4Active", "SP4[h]Active":
			Character.animate("SP4Rec")
		"SP4[ex]Active":
			Character.animate("SP4[ex]Rec")
		"SP4Rec", "SP4[ex]Rec":
			Character.animate("Idle")
			
		"SP5Startup", "aSP5Startup":
			if Character.held_version(Character.button_light) and Character.held_version(Character.button_fierce):
				Character.animate("aSP5[h]Active")
			else:
				Character.animate("aSP5Active")
		"SP5[ex]Startup", "aSP5[ex]Startup":
			Character.animate("aSP5[ex]Active")
		"aSP5Active":
			Character.animate("aSP5Rec")
		"aSP5[h]Active":
			Character.animate("aSP5[h]Rec")
		"aSP5[h]Rec":
			Character.animate("aSP5[h]bActive")
		"aSP5[h]bActive":
			Character.animate("aSP5Rec")
		"aSP5[ex]Active":
			Character.animate("aSP5[ex]Rec")
		"aSP5Rec":
			if Character.is_on_ground(Character.get_node("SoftPlatformDBox")):
				Character.animate("SP5bRec")
			else:
				Character.animate("aSP5bRec")
		"aSP5[ex]Rec":
			if Character.is_on_ground(Character.get_node("SoftPlatformDBox")):
				Character.animate("SP5b[ex]Rec")
			else:
				Character.animate("aSP5b[ex]Rec")
		"SP5bRec", "SP5b[ex]Rec":
			Character.animate("Idle")
		"aSP5bRec", "aSP5b[ex]Rec":
			Character.animate("FallTransit")
			
		"SP6[ex]Startup", "aSP6[ex]Startup":
			Character.animate("aSP6[ex]Active")
		"aSP6[ex]Active":
			if Character.is_on_ground(Character.get_node("SoftPlatformDBox")):
				Character.animate("SP6[ex]Rec")
			else:
				Character.animate("aSP6[ex]Rec")
		"SP6[ex]Rec":
			Character.animate("Idle")
		"aSP6[ex]Rec":
			Character.animate("FallTransit")
			
		"SP6[ex]SeqA":
			Character.animate("SP6[ex]SeqB")
		"SP6[ex]SeqB":
			Character.animate("SP6[ex]SeqC")
		"SP6[ex]SeqC":
			Character.animate("SP6[ex]SeqD")
		"SP6[ex]SeqE":
			end_sequence_step()
			Character.animate("SP6[ex]GrabRec")
		"SP6[ex]GrabRec":
			Character.animate("Idle")
		"aSP6[ex]SeqE":
			end_sequence_step()
			Character.animate("aSP6[ex]GrabRec")
		"aSP6[ex]GrabRec":
			Character.animate("FallTransit")
			
		"SP7Startup", "aSP7Startup":
			Character.animate("aSP7Active")
		"aSP7Active":
			if Character.is_on_ground(Character.get_node("SoftPlatformDBox")):
				Character.animate("SP7Rec")
			else:
				Character.animate("aSP7Rec")
		"SP7Rec":
			Character.animate("Idle")
		"aSP7Rec":
			Character.animate("FallTransit")

func _on_SpritePlayer_anim_started(anim_name):

	match anim_name:
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
			
		"L1Startup":
			Character.anim_friction_mod = 150
		"L2Startup":
			Character.velocity.x += Character.facing * FMath.percent(Character.get_stat("SPEED"), 80)
		"L2Active":
			Character.velocity.x += Character.facing * FMath.percent(Character.get_stat("SPEED"), 120)
			Character.anim_friction_mod = 0
			Globals.Game.spawn_SFX( "GroundDashDust", "DustClouds", Character.get_feet_pos(), \
				{"facing":Character.facing, "grounded":true})
		"L2Rec":
			Character.velocity.set_vector(500 * FMath.S * Character.facing, 0)
			Character.velocity.rotate(-78 * Character.facing)
		"F1Startup":
			Character.velocity.x += Character.facing * FMath.percent(Character.get_stat("SPEED"), 25)
		"F1Active":
			Character.velocity.x += Character.facing * FMath.percent(Character.get_stat("SPEED"), 50)
		"F2Startup":
			Character.velocity.x += Character.facing * FMath.percent(Character.get_stat("SPEED"), 50)
#		"F3[h]Startup":
#			Character.get_node("ModulatePlayer").play("armor_flash")
		"HStartup":
			Character.velocity.x += Character.facing * FMath.percent(Character.get_stat("SPEED"), 50)
			Character.anim_friction_mod = 150
			
		"aL1Startup", "aL3Startup":
			Character.velocity_limiter.x = 85
			Character.anim_gravity_mod = 75
		"aL1Active", "aL3Active":
			Character.velocity_limiter.x = 85
			Character.anim_gravity_mod = 75
		"aL1Rec", "aL3Rec":
			Character.velocity_limiter.x = 85
		"aL2Startup":
			Character.velocity.x = FMath.percent(Character.velocity.x, 50)
		"aL2Active":
			Character.velocity_limiter.x = 85
			Character.velocity_limiter.down = 120
		"aL2Rec":
			Character.velocity.y = -600 * FMath.S
		"aL2LandRec":
			Globals.Game.spawn_SFX("LandDust", "DustClouds", Character.get_feet_pos(), {"facing":Character.facing, "grounded":true})
		"aF1Startup":
			Character.velocity_limiter.x = 85
			Character.anim_gravity_mod = 75
		"aF1[h]Startup":
			Character.velocity_limiter.x = 85
		"aF1Active":
			Character.velocity_limiter.x = 85
			Character.velocity_limiter.down = 100
			Character.anim_gravity_mod = 75
		"aF1Rec":
			Character.velocity_limiter.x = 85
			Character.velocity_limiter.down = 100
		"aF2Startup":
			Character.velocity_limiter.x_slow = 20
			Character.velocity_limiter.y_slow = 20
			Character.anim_gravity_mod = 0
		"aF2Active":
			Character.velocity_limiter.x = 50
			Character.velocity_limiter.down = 85
			Character.anim_gravity_mod = 50
		"aF2Rec":
			Character.velocity_limiter.x = 70
			Character.velocity_limiter.down = 70
		"aF2SeqA", "aF2SeqB":
			start_sequence_step()
		"aF2GrabRec":
			Character.face(-Character.facing)
			Character.velocity_limiter.x = 50
			Character.velocity_limiter.down = 85
			Character.anim_gravity_mod = 50
			
		"aF3Startup":
			Character.velocity_limiter.x = 85
			Character.velocity_limiter.down = 0
			Character.velocity_limiter.up = 100
			Character.anim_gravity_mod = 0
		"aF3Active":
			Character.velocity.set_vector(200 * FMath.S * Character.facing, 0)
			Character.velocity.rotate(-72 * Character.facing)
			Character.anim_gravity_mod = 0
		"aF3Rec":
			Character.velocity_limiter.x = 75
			Character.velocity_limiter.down = 100
		"aHStartup":
			Character.velocity_limiter.x_slow = 20
			Character.velocity_limiter.y_slow = 20
			Character.anim_gravity_mod = 0
		"aHActive":
			Character.velocity.set_vector(0, 0)
			Character.velocity_limiter.x = 0
			Character.anim_gravity_mod = 0
		"aHRec":
			Character.velocity_limiter.x = 70
			Character.velocity_limiter.down = 70
			
		"aSP1Startup", "aSP1[ex]Startup", "aSP1[b]Startup", "aSP1[b][ex]Startup", "aSP1[d]Startup", "aSP1[d][ex]Startup":
			Character.velocity_limiter.x_slow = 20
			Character.velocity_limiter.y_slow = 20
			Character.anim_gravity_mod = 0
		"aSP1[c1]Startup", "aSP1[c2]Startup", "aSP1[c1]bStartup", "aSP1[c2]bStartup", "aSP1[c3]Startup", \
				"aSP1[d][c1]Startup", "aSP1[d][c2]Startup", "aSP1[d][c1]bStartup", "aSP1[d][c2]bStartup", "aSP1[d][c3]Startup":
			Character.velocity_limiter.x = 20
			Character.velocity_limiter.down = 20
		"SP1[c1]Active": # spawn projectile at EntitySpawn
			Character.velocity.x += Character.facing * FMath.percent(Character.get_stat("SPEED"), 50)
			Globals.Game.spawn_entity(Character.player_ID, "TridentProj", Animator.query_point("entityspawn"), {"charge_lvl" : 1}, \
					Character.palette_number, NAME)
			Globals.Game.spawn_SFX("SpecialDust", "DustClouds", Character.get_feet_pos(), {"facing":Character.facing, "grounded":true})
		"SP1[c2]Active":
			Character.velocity.x += Character.facing * FMath.percent(Character.get_stat("SPEED"), 50)
			Character.unique_data.last_trident = Globals.Game.spawn_entity(Character.player_ID, "TridentProj", \
					Animator.query_point("entityspawn"), {"charge_lvl" : 2}, Character.palette_number, NAME).entity_ID
			Globals.Game.spawn_SFX("SpecialDust", "DustClouds", Character.get_feet_pos(), {"facing":Character.facing, "grounded":true})
		"SP1[c3]Active":
			Character.velocity.x += Character.facing * FMath.percent(Character.get_stat("SPEED"), 50)
			Character.unique_data.last_trident = Globals.Game.spawn_entity(Character.player_ID, "TridentProj", \
					Animator.query_point("entityspawn"), {"charge_lvl" : 3}, Character.palette_number, NAME).entity_ID
			Globals.Game.spawn_SFX("SpecialDust", "DustClouds", Character.get_feet_pos(), {"facing":Character.facing, "grounded":true})
		"SP1[ex]Active":
			Character.velocity.x += Character.facing * FMath.percent(Character.get_stat("SPEED"), 50)
			Character.unique_data.last_trident = Globals.Game.spawn_entity(Character.player_ID, "TridentProj", \
					Animator.query_point("entityspawn"), {"charge_lvl" : 4}, Character.palette_number, NAME).entity_ID
			Globals.Game.spawn_SFX("SpecialDust", "DustClouds", Character.get_feet_pos(), {"facing":Character.facing, "grounded":true})
			
		"SP1[u][c1]Active": # spawn projectile at EntitySpawn
			Globals.Game.spawn_entity(Character.player_ID, "TridentProj", \
					Animator.query_point("entityspawn"), {"charge_lvl" : 1, "alt_aim" : true}, Character.palette_number, NAME)
			Globals.Game.spawn_SFX("SpecialDust", "DustClouds", Character.get_feet_pos(), {"facing":Character.facing, "grounded":true})
		"SP1[u][c2]Active":
			Character.unique_data.last_trident = Globals.Game.spawn_entity(Character.player_ID, "TridentProj", \
					Animator.query_point("entityspawn"), {"charge_lvl" : 2, "alt_aim" : true}, Character.palette_number, NAME).entity_ID
			Globals.Game.spawn_SFX("SpecialDust", "DustClouds", Character.get_feet_pos(), {"facing":Character.facing, "grounded":true})
		"SP1[u][c3]Active":
			Character.unique_data.last_trident = Globals.Game.spawn_entity(Character.player_ID, "TridentProj", \
					Animator.query_point("entityspawn"), {"charge_lvl" : 3, "alt_aim" : true}, Character.palette_number, NAME).entity_ID
			Globals.Game.spawn_SFX("SpecialDust", "DustClouds", Character.get_feet_pos(), {"facing":Character.facing, "grounded":true})
		"SP1[u][ex]Active":
			Character.unique_data.last_trident = Globals.Game.spawn_entity(Character.player_ID, "TridentProj", \
					Animator.query_point("entityspawn"), {"charge_lvl" : 4, "alt_aim" : true}, Character.palette_number, NAME).entity_ID
			Globals.Game.spawn_SFX("SpecialDust", "DustClouds", Character.get_feet_pos(), {"facing":Character.facing, "grounded":true})
			
		"aSP1[c1]Active":
			Globals.Game.spawn_entity(Character.player_ID, "TridentProj", \
					Animator.query_point("entityspawn"), {"aerial" : true, "charge_lvl" : 1}, Character.palette_number, NAME)
#			var point = Animator.query_point("entityspawn")
#			for x in 30:
#				point.y -= 5
#				Globals.Game.spawn_entity(Character.player_ID, "TridentProj", point, \
#						{"aerial" : true, "charge_lvl" : 1})
		"aSP1[c2]Active":
			Character.unique_data.last_trident = Globals.Game.spawn_entity(Character.player_ID, "TridentProj", \
					Animator.query_point("entityspawn"), {"aerial" : true, "charge_lvl" : 2}, Character.palette_number, NAME).entity_ID
		"aSP1[c3]Active":
			Character.unique_data.last_trident = Globals.Game.spawn_entity(Character.player_ID, "TridentProj", \
					Animator.query_point("entityspawn"), {"aerial" : true, "charge_lvl" : 3}, Character.palette_number, NAME).entity_ID
		"aSP1[ex]Active":
			Character.unique_data.last_trident = Globals.Game.spawn_entity(Character.player_ID, "TridentProj", \
					Animator.query_point("entityspawn"), {"aerial" : true, "charge_lvl" : 4}, Character.palette_number, NAME).entity_ID

		"aSP1[d][c1]Active":
			Globals.Game.spawn_entity(Character.player_ID, "TridentProj", \
					Animator.query_point("entityspawn"), {"aerial" : true, "charge_lvl" : 1, "alt_aim" : true}, Character.palette_number, NAME)
		"aSP1[d][c2]Active":
			Character.unique_data.last_trident = Globals.Game.spawn_entity(Character.player_ID, "TridentProj", \
					Animator.query_point("entityspawn"), {"aerial" : true, "charge_lvl" : 2, "alt_aim" : true}, Character.palette_number, NAME).entity_ID
		"aSP1[d][c3]Active":
			Character.unique_data.last_trident = Globals.Game.spawn_entity(Character.player_ID, "TridentProj", \
					Animator.query_point("entityspawn"), {"aerial" : true, "charge_lvl" : 3, "alt_aim" : true}, Character.palette_number, NAME).entity_ID
		"aSP1[d][ex]Active":
			Character.unique_data.last_trident = Globals.Game.spawn_entity(Character.player_ID, "TridentProj", \
					Animator.query_point("entityspawn"), {"aerial" : true, "charge_lvl" : 4, "alt_aim" : true}, Character.palette_number, NAME).entity_ID

		"aSP1Rec", "aSP1[ex]Rec":
			Character.velocity_limiter.x = 70
			Character.velocity_limiter.down = 70
			
		"aSP2Startup", "aSP2[ex]Startup":
			Character.velocity_limiter.x_slow = 20
			Character.velocity_limiter.y_slow = 20
			Character.anim_gravity_mod = 0
		"aSP2Active":
			Character.velocity.set_vector(Character.facing * 400 * FMath.S, 0)
			Character.anim_gravity_mod = 0
			Character.anim_friction_mod = 0
			Character.velocity_limiter.y_slow = 50
			Globals.Game.spawn_SFX("WaterJet", "WaterJet", Animator.query_point("sfxspawn"), {"facing":Character.facing}, \
					Character.palette_number, NAME)
		"aSP2[h]Active":
			Character.velocity.set_vector(Character.facing * 600 * FMath.S, 0)
			Character.anim_gravity_mod = 0
			Character.anim_friction_mod = 0
			Globals.Game.spawn_SFX("WaterJet", "WaterJet", Animator.query_point("sfxspawn"), {"facing":Character.facing}, \
					Character.palette_number, NAME)
		"aSP2[ex]Active":
			Character.velocity.set_vector(Character.facing * 500 * FMath.S, 0)
			Character.anim_gravity_mod = 0
			Character.anim_friction_mod = 0
			Character.velocity_limiter.y_slow = 50
			Globals.Game.spawn_SFX("WaterJet", "WaterJet", Animator.query_point("sfxspawn"), {"facing":Character.facing}, \
					Character.palette_number, NAME)
		"aSP2[h]Rec":
			Character.velocity_limiter.down = 20
			Character.velocity.x = FMath.percent(Character.velocity.x, 50)
			Character.anim_gravity_mod = 25
			Character.anim_friction_mod = 0
		"aSP2Rec", "aSP2CRec":
			Character.velocity_limiter.down = 70
			Character.velocity.x = FMath.percent(Character.velocity.x, 50)
			Character.anim_gravity_mod = 25
		
			
		"aSP3Startup", "aSP3[h]Startup", "aSP3[ex]Startup":
			Character.velocity.x = FMath.percent(Character.velocity.x, 50)
			Character.velocity_limiter.y_slow = 20
			Character.anim_gravity_mod = 0
		"aSP3Active", "SP3Active":
			Character.velocity.x = FMath.percent(Character.velocity.x, 50)
			Character.velocity.y = -500 * FMath.S
			Character.anim_gravity_mod = 0
		"aSP3[h]Active", "aSP3[ex]Active", "SP3[h]Active", "SP3[ex]Active":
			Character.velocity.x = FMath.percent(Character.velocity.x, 50)
			Character.velocity.y = -700 * FMath.S
			Character.anim_gravity_mod = 0
		"aSP3Rec", "aSP3[ex]Rec":
			Character.velocity_limiter.x = 70
			
		"SP4Active":
			Character.velocity.x += Character.facing * FMath.percent(Character.get_stat("SPEED"), 25)
			Globals.Game.spawn_entity(Character.player_ID, "GroundFin", Animator.query_point("entityspawn"), {}, Character.palette_number, NAME)
			Character.unique_data.groundfin_count += 1
		"SP4[h]Active":
			Character.velocity.x += Character.facing * FMath.percent(Character.get_stat("SPEED"), 25)
			Globals.Game.spawn_entity(Character.player_ID, "GroundFin", Animator.query_point("entityspawn"), \
					{"held" : true}, Character.palette_number, NAME)
			Character.unique_data.groundfin_count += 1
		"SP4[ex]Active":
			Character.velocity.x += Character.facing * FMath.percent(Character.get_stat("SPEED"), 25)
			var spawn_point = Animator.query_point("entityspawn")
			Globals.Game.spawn_entity(Character.player_ID, "GroundFin", spawn_point, {"ex" : true}, Character.palette_number, NAME)
			Globals.Game.spawn_entity(Character.player_ID, "GroundFin", spawn_point, {"held" : true, "ex" : true}, Character.palette_number, NAME)
			Character.unique_data.groundfin_count += 2
			
		"SP5Startup", "aSP5Startup", "aSP5[ex]Startup":
			Character.velocity_limiter.x_slow = 20
			Character.velocity_limiter.y_slow = 20
			Character.anim_gravity_mod = 0
			Character.anim_friction_mod = 0
		"aSP5Active", "aSP5[h]Active", "aSP5[ex]Active":
			Character.velocity.set_vector(Character.facing * 200 * FMath.S, 0)
			Character.anim_gravity_mod = 0
			Character.anim_friction_mod = 0
			if Character.grounded:
				Globals.Game.spawn_SFX("SpecialDust", "DustClouds", Character.get_feet_pos(), {"facing":Character.facing, "grounded":true})
		"aSP5[h]Rec", "aSP5[h]bActive":
			Character.velocity.x = FMath.percent(Character.velocity.x, 50)
			Character.anim_gravity_mod = 0
			Character.anim_friction_mod = 0
		"aSP5Rec", "aSP5[ex]Rec":
			Character.velocity_limiter.down = 20
			Character.velocity.x = FMath.percent(Character.velocity.x, 50)
			Character.anim_gravity_mod = 25
			
		"SP6[ex]Startup":
			Character.anim_friction_mod = 200
		"aSP6[ex]Startup":
			Character.velocity_limiter.x_slow = 20
			Character.velocity_limiter.y_slow = 20
			Character.anim_gravity_mod = 0
		"aSP6[ex]Active":
			if Character.grounded:
				Character.velocity.x = Character.facing * 100 * FMath.S
			Character.velocity.y = 0
			Character.anim_gravity_mod = 0
		"aSP6[ex]Rec": # whiff grab
			Character.velocity_limiter.x = 20
			Character.anim_gravity_mod = 25
			Character.play_audio("fail1", {"vol":-20})
		"SP6[ex]Rec": # whiff grab
			Character.play_audio("fail1", {"vol":-20})
		"SP6[ex]SeqA", "SP6[ex]SeqB", "SP6[ex]SeqC", "SP6[ex]SeqD", "SP6[ex]SeqE", "aSP6[ex]SeqE":
			start_sequence_step()
		"SP6[ex]GrabRec":
			Character.face(-Character.facing)
		"aSP6[ex]GrabRec":
			Character.face(-Character.facing)
			Character.velocity_limiter.down = 20
			Character.anim_gravity_mod = 25
		
		"SP7Startup":
			Character.face_opponent()
			Character.get_node("ModulatePlayer").play("unflinch_flash")
		"aSP7Startup":
			Character.face_opponent()
			Character.velocity_limiter.x_slow = 20
			Character.velocity_limiter.y_slow = 20
			Character.anim_gravity_mod = 0
			Character.get_node("ModulatePlayer").play("unflinch_flash")
		"aSP7Active":
			instinct()
			Character.velocity_limiter.x_slow = 20
			Character.velocity_limiter.down = 10
		"SP7Rec":
			Character.play_audio("water13", {"vol" : -10})
		"aSP7Rec":
			Character.play_audio("water13", {"vol" : -10})
			Character.velocity_limiter.x_slow = 20
			Character.velocity_limiter.down = 10
			
	start_audio(anim_name)


func start_audio(anim_name):
	if Character.is_atk_active():
		var move_name = anim_name.trim_suffix("Active")
		var orig_move_name = move_name
		if !move_name in MOVE_DATABASE:
			move_name = refine_move_name(move_name)
		if move_name in MOVE_DATABASE:
			if "move_sound" in MOVE_DATABASE[move_name]:
				if !MOVE_DATABASE[move_name].move_sound is Array:
					Character.play_audio(MOVE_DATABASE[move_name].move_sound.ref, MOVE_DATABASE[move_name].move_sound.aux_data)
				else:
					for sound in MOVE_DATABASE[move_name].move_sound:
						Character.play_audio(sound.ref, sound.aux_data)
						
		match orig_move_name:
			"SP1[c1]", "SP1[u][c1]", "aSP1[c1]", "aSP1[d][c1]":
				Character.play_audio("whoosh12", {"bus":"PitchDown"})
			"SP1[c2]", "SP1[u][c2]", "aSP1[c2]", "aSP1[d][c2]":
				Character.play_audio("whoosh12", {"bus":"PitchDown"})
			"SP1[c3]", "SP1[u][c3]", "aSP1[c3]", "aSP1[d][c3]", "SP1[ex]", "SP1[u][ex]", "aSP1[ex]", "aSP1[d][ex]":
				Character.play_audio("whoosh12", {"bus":"PitchDown"})
				Character.play_audio("water4", {"vol" : -20, "bus":"PitchDown"})
	
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
	
	match Animator.current_animation:
		"Run":
			match sprite.frame:
				38, 41:
					Character.play_audio("footstep2", {"vol":-1})
		"SP1[c1]Startup", "SP1[c2]Startup", "SP1[u][c1]Startup", "SP1[u][c2]Startup":
			if Animator.time == 3:
				Globals.Game.spawn_SFX("LandDust", "DustClouds", Character.get_feet_pos(), \
						{"facing":Character.facing, "grounded":true})
					
					
