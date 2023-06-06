extends Node2D

signal saved_state
signal loaded_state
signal record_ended
signal playback_started
signal game_set
signal time_over


#const CAMERA_MARGIN = 55 # camera limit distance from blast zone
const MARGIN_TO_TILT_KILLBLAST = 100
const KILLBLAST_TILT_ANGLE = PI/7
const HUD_FADE = 0.3
	
const SCREEN_SHAKE_DECAY_RATE = 0.25
var screen_shake_amount: float

const SCREEN_DARKEN = Color(0.5, 0.5, 0.5)
const FLASHING_TIME_THRESHOLD = 10

onready var stage_ref = Globals.stage_ref
onready var P1_char_ref = Globals.P1_char_ref
onready var P1_palette = Globals.P1_palette
#onready var P1_input_style = Globals.P1_input_style
onready var P2_char_ref = Globals.P2_char_ref
onready var P2_palette = Globals.P2_palette
#onready var P2_input_style = Globals.P2_input_style
onready var starting_stock_pts = Globals.starting_stock_pts

# variables for stage box and starting positions/facings, these are set by the stage's node
var stage
var stage_box
#var blastbarrierL
#var blastbarrierR
#var blastbarrierU
var respawn_points = []
var middle_point
#var left_ledge_point
#var right_ledge_point
var left_corner
var right_corner
var P1_position: Vector2
var P1_facing: int
var P2_position: Vector2
var P2_facing: int

var HUD
var frame_viewer
var viewport
var card_menu

onready var match_input_log = Globals.match_input_log
var true_frametime := 0 # to set target to simulate to
var playback_mode := false
var record_end_time := 0 # set end of playback, when loading set true_frame_time to it while clearing all
							# inputs pass record_end_time within match_input_log

var test_state # save state for testing
var test_state2 # save state for testing
#onready var debugger = load("res://Scenes/Debugger.gd").new() # for checking input stuff, very useful
var test_saved_game_states: Dictionary
var frame_reverse := true

var training_save_state # save state used for training mode

# GameState, these are to be saved
var frametime := 0
var matchtime: int
var current_rng_seed: int # changed after each random number generation
var player_input_state = { # in int form
		"pressed" : [],
		"just_pressed" : [],
		"just_released" : [],
	}
var captured_input_state = { # use for capturing inputs, during input delay cannot rely on player_input_state
		"old_pressed" : [],
		"pressed" : [],
	}
var screenfreeze = null # when set to a player_ID, only that player will simulate, along with any sfx/shadow spawned during screenfreeze
var darken := false # stage will turn dark
var input_lock := true
var screenstop := 0 # when set to a number pause game for that number of frames, used mostly for non-lethal last hit of supers
					# (especially projectile and beam supers), often used with screenshake
var entity_ID_ref := 0 # used to assign entity ID to entities

# -----------------------------------------------------------------------------------------------------------------------

var game_set := false # caused issue when save/loaded, need more testing

var play_speed := 1 # testing

var orig_rng_seed: int	# saved in replay file, starting rng_seed, host must send this over to client

var you_label # node
var to_superfreeze = null # set superfreeze at end of frame after players/entities have animated
var to_lethalfreeze = null # set lethalfreeze at end of frame after players/entities have animated

# -----------------------------------------------------------------------------------------------------------------------

var audio_queue := [] # contain audio created while the game is being simulated without rendering
const AUDIO_QUEUE_LIFE = 5
var rollback_start_frametime = null

var LevelControl


func _ready():
	
# SETUP STAGE, CAMERA, RNG SEED --------------------------------------------------------------------------------------------------
	
	Globals.Game = self
	Globals.pausing = false
	Globals.zoom_level = 2.0
	Globals.winner = []
	Globals.debug_mode = false
	Globals.match_input_log.reset()
	
#	Globals.survival_level = "Test" # test
#	Globals.player_count = 1
	
	HUD = get_node("../../../HUD")
	frame_viewer = get_node("../../../HUD/FrameViewer")
	viewport = get_node("../../..")
	card_menu = get_node("../../../CardMenu")
	
	if Globals.player_count == 1:
		HUD.get_node("P1_HUDRect").rect_position.x = 0
	
	if Globals.survival_level != null:
		LevelControl = load("res://Scenes/Survival/LevelControl.tscn").instance()
		add_child(LevelControl)
		move_child(LevelControl, 0)
		LevelControl.init()
		setup()
		input_lock = false
		Inventory.shop_open = false
		Globals.survival_time = 0
		
	elif Netplay.is_netplay():
		var NetgameSetup = load("res://Scenes/Netplay/NetgameSetup.tscn").instance()
		add_child(NetgameSetup)
		move_child(NetgameSetup, 0)
		NetgameSetup.init()
		
	elif Globals.watching_replay:
		var ReplayControl = load("res://Scenes/ReplayControl.tscn").instance()
		add_child(ReplayControl)
		move_child(ReplayControl, 0)
		ReplayControl.init()
		setup()
		
	else:
		setup()
	
func setup():

	if !Netplay.is_netplay() and !Globals.watching_replay: # for netgame, rng seed is generated at init() of NetgameSetup
		orig_rng_seed = Globals.random.randi_range(1, 9999)
		current_rng_seed = orig_rng_seed
		Globals.orig_rng_seed = orig_rng_seed
		
	matchtime = Globals.time_limit * 60

	# remove test stage node and add the real stage node
#	var test_stage = $Stage.get_child(0) # test stage node should be directly under this node
#	test_stage.free()

	stage = load("res://Stages/" + stage_ref + "/" + stage_ref + ".tscn").instance()
	$Stage.add_child(stage)
	stage.init()

	set_camera_limit()
	
	if Globals.time_limit == 0: # no time limit
		HUD.get_node("MatchTime").hide()
		HUD.get_node("TimeFrame").hide()
	else:
		HUD.get_node("MatchTime").show()
		HUD.get_node("TimeFrame").show()
	
	if Globals.survival_level == null or Globals.difficulty >= 2:
		HUD.get_node("P1_HUDRect/Portrait/Coin").hide()
		HUD.get_node("P2_HUDRect/Portrait/Coin").hide()
	
# ADD PLAYERS --------------------------------------------------------------------------------------------------
	
	if Globals.survival_level == null or Globals.player_count > 1:
		# add players, players added later overlap players added eariler
		var P2_character
	#	if P2_input_style == 0:
		P2_character = load("res://Characters/" + P2_char_ref + "/" + P2_char_ref + ".tscn").instance()
	#	else:
	#		P2_character = load("res://Characters/" + P2_char_ref + "/" + P2_char_ref + "C.tscn").instance()
		var P2 = Loader.loaded_character_scene.instance() # main character node, not unique character node
		$Players.add_child(P2)
		P2.init(1, P2_character, P2_position, P2_facing, P2_palette)
		frame_viewer.P2_node = P2
	else:
		HUD.get_node("P2_HUDRect").hide()
	
	var P1_character
#	if P1_input_style == 0:
	P1_character = load("res://Characters/" + P1_char_ref + "/" + P1_char_ref + ".tscn").instance()
#	else:
#		P1_character = load("res://Characters/" + P1_char_ref + "/" + P1_char_ref + "C.tscn").instance()
	var P1 = Loader.loaded_character_scene.instance()
	$Players.add_child(P1)
	P1.init(0, P1_character, P1_position, P1_facing, P1_palette)
	frame_viewer.P1_node = P1
	
	if Netplay.is_netplay():
		you_label = load("res://Scenes/YouLabel.tscn").instance()
		get_player_node(Netplay.my_player_id()).add_child(you_label)
		
	P1.test = true # testing purposes
#	P2.test = true # testing purposes
	
	for player in $Players.get_children(): # each player target a random other player
		player.initial_targeting()
		
	var players_position := Vector2.ZERO
	for player in $Players.get_children():
		players_position += player.position # add together to find midpoint
			
	var point_btw_char = players_position / $Players.get_child_count() # get midpoint
	point_btw_char.y -= get_viewport_rect().size.y / 10.0 # lower it by a little
	$CameraRef.position = point_btw_char

# --------------------------------------------------------------------------------------------------

func set_camera_limit():
	$CameraRef/Camera2D.limit_left = stage_box.rect_global_position.x
	$CameraRef/Camera2D.limit_right = stage_box.rect_global_position.x + stage_box.rect_size.x
	$CameraRef/Camera2D.limit_top = stage_box.rect_global_position.y
	$CameraRef/Camera2D.limit_bottom = stage_box.rect_global_position.y + stage_box.rect_size.y

# MAIN LOOP (TESTING STUFF) --------------------------------------------------------------------------------------------------

func debug():
	if Input.is_action_just_pressed("speed_up"):
# warning-ignore:narrowing_conversion
		play_speed = min(play_speed + 1, 1)
	if Input.is_action_just_pressed("speed_down"):
# warning-ignore:narrowing_conversion
		play_speed = max(play_speed - 1, 0)
			
	if Input.is_action_just_released("zoom_in"):
		Globals.change_zoom_level(0.1)
	if Input.is_action_just_released("zoom_out"):
		Globals.change_zoom_level(-0.1)
		
	# save state
	if Input.is_action_just_pressed("save_state1"):
		save_state("test_state")
		emit_signal("saved_state") # to tell text to show message
		
	# load state
	if Input.is_action_just_pressed("load_state1"):
		if playback_mode == false:
	#		if ResourceLoader.exists("res://Scenes/SavedData/GameState.tres"):
	#			var loaded_data = ResourceLoader.load("res://Scenes/SavedData/GameState.tres")
	#			load_state(loaded_data)
			if test_state != null:
				load_state(test_state, false)
				true_frametime = frametime
				match_input_log.set_end_frametime(frametime)
				emit_signal("loaded_state") # to tell text to show message
			else:
				print("Error: Saved game state not found")
				
	# save state
	if Input.is_action_just_pressed("save_state2"):
		save_state("test_state2")
		emit_signal("saved_state") # to tell text to show message
		
	# load state
	if Input.is_action_just_pressed("load_state2"):
		if playback_mode == false:
	#		if ResourceLoader.exists("res://Scenes/SavedData/GameState.tres"):
	#			var loaded_data = ResourceLoader.load("res://Scenes/SavedData/GameState.tres")
	#			load_state(loaded_data)
			if test_state2 != null:
				load_state(test_state2, false)
				true_frametime = frametime
				match_input_log.set_end_frametime(frametime)
				emit_signal("loaded_state") # to tell text to show message
			else:
				print("Error: Saved game state not found")
			
	if Input.is_action_just_pressed("record_end"):
		record_end_time = frametime
		emit_signal("record_ended") # to tell text to show message
		
	if Input.is_action_just_pressed("play_recording"):
		if test_state != null:
			load_state(test_state)
			playback_mode = true # begin playback
			rollback_start_frametime = null
			true_frametime = record_end_time
			match_input_log.set_end_frametime(record_end_time)
			emit_signal("playback_started") # to tell text to show message
		else:
			print("Error: Saved game state not found")

	if Input.is_action_just_pressed("frame_advance"):
		if Globals.watching_replay:
			simulate(false)
		elif playback_mode == false:
			simulate()
		else:
			simulate(false)
			
	if frame_reverse and Input.is_action_just_pressed("frame_reverse"): # reverse 1 frame by loading save state of previous frame, can do up to certain times
		if playback_mode == false:
			if Globals.Game.frametime - 2 in test_saved_game_states:
# warning-ignore:return_value_discarded
				test_saved_game_states.erase(frametime)
				load_state(test_saved_game_states[frametime - 2])
				true_frametime = frametime
				simulate(false)
				match_input_log.set_end_frametime(frametime)
			
			
func export_logs():
#		if Netplay.is_netplay():
## warning-ignore:return_value_discarded
#			ResourceSaver.save("res://Scenes/SavedData/DebugLog" + str(Netplay.my_player_id()) + ".tres", Globals.debugger)
#		else:
## warning-ignore:return_value_discarded
#			ResourceSaver.save("res://Scenes/SavedData/DebugLog.tres", Globals.debugger)
			
		pass
			

func _physics_process(_delta):
	
	if Globals.editor:
		if !Netplay.is_netplay() and !Globals.watching_replay:
			debug() # only allow most debugging tools for local games while running in the editor
				
	#		if Input.is_action_just_pressed("export_input_log"): # for saving replays
	#			export_logs()
			
	if Globals.debug_mode:
		$PolygonDrawer.show()
		if Globals.survival_level == null:
			frame_viewer.show()
	else:
		$PolygonDrawer.hide()
		frame_viewer.hide()
			
	if Globals.watching_replay:
		if $ReplayControl.show_hitbox:
			$PolygonDrawer.show()
		else:
			$PolygonDrawer.hide()
			
	if Globals.training_mode:
		set_input_indicator()
		if Globals.training_settings.hitbox_viewer == 1:
			$PolygonDrawer.show()
		else:
			$PolygonDrawer.hide()
		if Globals.training_settings.frame_viewer == 1:
			frame_viewer.show()
		else:
			frame_viewer.hide()
			
#	ROLLBACK TESTER
#	if Netplay.is_netplay():

#	var random_frames = Globals.random.randi_range(1, 5)
#	if playback_mode == false:
#		if posmod(frametime, Globals.random.randi_range(1, 10)) == 0:
#			if frametime - random_frames in test_saved_game_states:
#				load_state(test_saved_game_states[frametime - random_frames])
#				playback_mode = true
#				rollback_start_frametime = frametime
#				while playback_mode:
#					simulate(false)


	if Netplay.is_netplay(): # rollback
		
		if Netcode.opponent_payload != null:
			Netcode.process_payload()
			
		Netcode.desync_check()
		
		if Netcode.rollback_starttime != null:
			if Netcode.rollback_starttime >= frametime:
				Netcode.rollback_starttime = null # ignore rollback if within input delay
				
			elif Netcode.rollback_starttime in $NetgameSetup.saved_game_states:
				load_state($NetgameSetup.saved_game_states[Netcode.rollback_starttime])
				playback_mode = true
				var rollback_frames := 0
				rollback_start_frametime = frametime
				while playback_mode:
					simulate(false)
					rollback_frames += 1
				Netcode.rollback_starttime = null # rollback completed
				Fps.set_rolled_back_frames(rollback_frames) # display latest frames rolled back
			elif !input_lock:
				# desync freeze protection is suppose to prevent this, stops the game if this occurs
#				get_node("../../..").rollback_over_limit()
				Netcode.rollback_starttime = null
				Netcode.lag_freezer()


# simulate FRAME --------------------------------------------------------------------------------------------------

	if Globals.watching_replay:
		$ReplayControl.replay_control()
		if !$ReplayControl.freeze_frame:
			for x in play_speed:
				simulate(false)
		set_input_indicator()

	elif !Netplay.is_netplay(): # normal
		for x in play_speed:
			if playback_mode == false:
				simulate()
			else:
				simulate(false)
				
	else: # netplay
		if !Netcode.lag_freeze:
			if Netcode.time_diff < 0:
				simulate()
				if posmod(frametime, 10) == 0:
					simulate() # rendering = true to capture inputs
					Netcode.time_diff += 1
			else:
				simulate()

# SCREEN SHAKE --------------------------------------------------------------------------------------------------

	if screen_shake_amount > 0.0:
		screen_shake_amount = max(screen_shake_amount - SCREEN_SHAKE_DECAY_RATE, 0)
		screenshake()
		if screen_shake_amount <= 0.01:
			screen_shake_amount = 0.0
			set_camera_limit()
	else: # just in case
		$CameraRef/Camera2D.offset_h = 0
		$CameraRef/Camera2D.offset_v = 0
		

# MATCH TIMER --------------------------------------------------------------------------------------------------


	if Globals.time_limit != 0:
		var matchtime_floor = max(ceil(matchtime / 60.0), 0)
		HUD.get_node("MatchTime").text = str(floor(matchtime_floor))

		if matchtime_floor < FLASHING_TIME_THRESHOLD:
			HUD.get_node("MatchTime/AnimationPlayer").play("flashing")
		else:
			HUD.get_node("MatchTime/AnimationPlayer").play("RESET")
			
		if matchtime == 0 and !game_set:
			game_set = true
			emit_signal("time_over")
			
			var max_stock_points_left = -1
			var winner_ID
			var damage_value_of_winner = 0
			for player in $Players.get_children():
				if player.stock_points_left > max_stock_points_left:
					max_stock_points_left = player.stock_points_left
					winner_ID = player.player_ID
					damage_value_of_winner = player.current_damage_value
				elif player.stock_points_left == max_stock_points_left: # there is a tie
					if player.current_damage_value <= damage_value_of_winner: # whoever has less damage wins
						winner_ID = player.player_ID
						damage_value_of_winner = player.current_damage_value		
			Globals.winner = [winner_ID, get_player_node(winner_ID).UniqChar.NAME]
			
	camera()
	

func camera():

# MOVE CAMERA --------------------------------------------------------------------------------------------------
	# camera management outside of simulation, no need to simulate camera
	
	var players_position := Vector2.ZERO
	
	var focused_player_count := 0

	if Globals.survival_level == null:
		
		for player in $Players.get_children():
			var valid := true
			if player.state == Em.char_state.DEAD:
				if player.stock_points_left > 0:
					var time_diff = Globals.RespawnTimer_WAIT_TIME - player.get_node("RespawnTimer").time
					if time_diff > 30 or time_diff < 0:
						valid = false
				else: valid = false
			if valid:
				focused_player_count += 1
				players_position += player.position # add together to find midpoint
			
	else: # survival mode
		var player_1 = get_player_node(0)
		
		var p1_valid := true
		if player_1.state == Em.char_state.DEAD:
			if player_1.stock_points_left > 0:
				var time_diff = Globals.RespawnTimer_WAIT_TIME - player_1.get_node("RespawnTimer").time
				if time_diff > 30 or time_diff < 0:
					p1_valid = false
			else: p1_valid = false
					
		if p1_valid:
			focused_player_count += 1
			players_position += player_1.position
			var target = player_1.get_target()
			if target != player_1:
				focused_player_count += 1
				players_position += target.position
				
				
		if Globals.player_count == 2:
			var player_2 = get_player_node(1)
			
			var p2_valid := true
			if player_2.state == Em.char_state.DEAD:
				if player_2.stock_points_left > 0:
					var time_diff = Globals.RespawnTimer_WAIT_TIME - player_2.get_node("RespawnTimer").time
					if time_diff > 30 or time_diff < 0:
						p2_valid = false
				else: p2_valid = false
			
			if p2_valid:
				focused_player_count += 1
				players_position += player_2.position
				var target = player_2.get_target()
				if target != player_2:
					focused_player_count += 1
					players_position += target.position
					
		if focused_player_count == 0:
			focused_player_count += 1 # mid point, if no one left alive
			players_position += middle_point
				
	var point_btw_char = players_position / focused_player_count # get midpoint
#	if Globals.survival_level == null:
	point_btw_char.y -= get_viewport_rect().size.y / 10.0 # lower it by a little
	$CameraRef.position = point_btw_char
	
	
	handle_zoom() # complex stuff to determine zoom level
	HUD_fade() # fade out UI elements if a player goes behind them
	

	
# INPUT CAPTURE --------------------------------------------------------------------------------------------------
	# produce input log as well
	
func input_capture(input_delay = 0):
	var toggled_keys := [] # in int form
	
	# player 1
	if !Netplay.is_netplay() or Netplay.my_player_id() == 0: # in netplay, ignore P2 buttons not being pressed
		for key_array in Globals.INPUTS[0].values():
			var converted_key: int = key_array[1] # get int form of the key
			if Input.is_action_pressed(key_array[0]): # use string form for this
				if !converted_key in captured_input_state["pressed"]: # new button pressed
					toggled_keys.append(converted_key) # record toggled key
			elif converted_key in captured_input_state["pressed"]: # released a held button
				toggled_keys.append(converted_key) # record toggled key
			
	# player 2
	if Globals.player_count > 1:
		if !Netplay.is_netplay() or Netplay.my_player_id() == 1: # in netplay, ignore P1 buttons not being pressed
			for key_array in Globals.INPUTS[1].values():
				var converted_key: int = key_array[1] # get int form of the key
				if Input.is_action_pressed(key_array[0]): # use string form for this
					if !converted_key in captured_input_state["pressed"]: # new button pressed
						toggled_keys.append(converted_key) # record toggled key
				elif converted_key in captured_input_state["pressed"]: # released a held button
					toggled_keys.append(converted_key) # record toggled key	
			
	# save toggled keys in match_input_log
	if toggled_keys.size() > 0:
		if !(frametime + input_delay in match_input_log.input_log):
			match_input_log.input_log[frametime + input_delay] = toggled_keys
		else:
			match_input_log.input_log[frametime + input_delay].append_array(toggled_keys) # just in case

		
		
# INPUT LOADING FROM LOG --------------------------------------------------------------------------------------------------
		
func update_captured_input_state(input_delay = 0):
	
	captured_input_state.old_pressed = captured_input_state.pressed.duplicate()
	
	if frametime + input_delay in match_input_log.input_log:
		
		var toggled_inputs: Array
		toggled_inputs = match_input_log.input_log[frametime + input_delay]
		for toggled_input in toggled_inputs:

			if !toggled_input in captured_input_state.pressed:
				captured_input_state.pressed.append(toggled_input)
			else:
				captured_input_state.pressed.erase(toggled_input)
		
				
		
func load_inputs():
	# clear just_pressed and just_released inputs
	
	player_input_state.just_pressed = []
	player_input_state.just_released = []
	
	# produce new player_input_state based on old player_input_state and match_input_log
	
	if frametime in match_input_log.input_log: # if there is a timestamp for the frametime of the loaded state
		
		
		var toggled_inputs: Array
		toggled_inputs = match_input_log.input_log[frametime]
		
		for toggled_input in toggled_inputs:
			
			# player 1
			# new button pressed
			if !(toggled_input in player_input_state.pressed):
				player_input_state.pressed.append(toggled_input)
				player_input_state.just_pressed.append(toggled_input)
			else: # held button released
				player_input_state.pressed.erase(toggled_input)
				player_input_state.just_released.append(toggled_input)

				
	else:
		# no change in held inputs
		pass
			
	
# SIMULATE LOOP --------------------------------------------------------------------------------------------------
	
# simulate a physics tick, do this function multiple times a frame to simulate without rendering
func simulate(rendering = true):
	# if rendering is false, will load inputs from match_input_log instead of capturing new ones

	if frametime == 126:
		get_node("../../..").start_battle()
	
	$PolygonDrawer.extra_boxes = [] # clear the extra boxes

	if Netplay.is_netplay(): # must save state even when not rendering or overwrite incorrect states!
		$NetgameSetup.auto_savestate() # save first before processing inputs, so that when loading will start processing input on same frame
	elif Globals.watching_replay:
		$ReplayControl.replay_auto_savestate()
	elif Globals.editor and frame_reverse:
		test_auto_savestate()
	
	if rendering: # not loading inputs for log, capture new ones
		if !input_lock: # no inputs when input lock is on
			if Netplay.is_netplay():
				input_capture(Netcode.input_delay)
			else:
				input_capture()
				
		# if netplay, retrieve and send input here
		if Netplay.is_netplay():
			Netcode.retrieve_inputs()
	
	if Netplay.is_netplay():
		update_captured_input_state(Netcode.input_delay)
	else:
		update_captured_input_state()
	
	load_inputs()
	
#	if frametime in match_input_log.input_log:
#		Globals.debugger.set_state(frametime, match_input_log.input_log[frametime], player_input_state)
#	else:
#		Globals.debugger.set_state(frametime, null, player_input_state)
#	if !rendering and test[0]:
#		debugger.rollback_check(frametime)
#	debugger.set_player_input_state(frametime, player_input_state)
#	debugger.set_latest_correct_time(frametime, match_input_log.latest_correct_time)

#	Globals.debugger.set_physics_logs(frametime, $Players.get_children())
	
# simulate CHILDREN NODES --------------------------------------------------------------------------------------------------

#	rng_randomize()
	to_superfreeze = null
	to_lethalfreeze = null

	if Globals.survival_level != null and !Inventory.shop_open:
		LevelControl.simulate()

	# activate player's physics

	for field in $Fields.get_children():
		if field.free:
			field.free()
		else:
			field.simulate()

	for player in $Players.get_children():
		if "free" in player and player.free:
			player.free() # remove killed mobs
		else:
			player.simulate(player_input_state)

	for entity in $EntitiesBack.get_children():
		if entity.free:
			entity.free()
		else:
			entity.simulate()
		
	for entity in $EntitiesFront.get_children():
		if entity.free:
			entity.free()
		else:
			entity.simulate()
			
	for entity in $MobEntities.get_children():
		if entity.free:
			entity.free()
		else:
			entity.simulate()
			
	for pickup in $PickUps.get_children():
		if pickup.free:
			pickup.free()
		else:
			pickup.simulate()

	if !is_stage_paused():
		detect_hit()
	

	# activate player's simulate_after()
	for player in $Players.get_children():
		player.simulate_after()
		
	for entity in $EntitiesBack.get_children():
		entity.simulate_after()
		
	for entity in $EntitiesFront.get_children():
		entity.simulate_after()
		
	for entity in $MobEntities.get_children():
		entity.simulate_after()
		
	for pickup in $PickUps.get_children():
		pickup.simulate_after()


	for afterimage in $Afterimages.get_children():
		if afterimage.free: # Physics Tick version of queue_free()
			afterimage.free()
		else:
			afterimage.simulate()
		
	for SFX in $SFXFront.get_children():
		if SFX.free:
			SFX.free()
		else:
			SFX.simulate()
			
	for SFX in $SFXBack.get_children():
		if SFX.free:
			SFX.free()
		else:
			SFX.simulate()
			
	for number in $DamageNumbers.get_children():
		if number.free:
			number.free()
		else:
			number.simulate()
			
#	for audio in $AudioPlayers.get_children():
#		if audio.free:
#			audio.free()
#		else:
#			audio.simulate()

			
	if Globals.static_stage == 0:
		stage.simulate()
		
	check_superfreeze() # only freeze after players/entites/sfx have simulated
	check_lethalfreeze()
	process_screenstop()
			
	frame_viewer.simulate()

# --------------------------------------------------------------------------------------------------

	frametime += 1 # advance frametime at end of each physics tick
	if playback_mode == false:
		true_frametime += 1 # true_frametime marks the "present" will not advance during playback mode
	elif frametime >= true_frametime: # reached back to present
		if playback_mode == true:
			if rollback_start_frametime != null:
				load_queued_audio()
				rollback_start_frametime = null
		playback_mode = false # stop playback
	else:
		progress_audio_queue()
		
	if !input_lock and !is_stage_paused():
		matchtime -= 1 # match time only start counting down when "BEGIN!" vanishes
	
	
# SAVING/LOADING GAME STATE --------------------------------------------------------------------------------------------------
	
func test_auto_savestate(): # make a savestate every frame of the past 60 frames for testing
	save_state(frametime)
	while test_saved_game_states.size() > 181: # erase savestates if too many
# warning-ignore:return_value_discarded
		test_saved_game_states.erase(test_saved_game_states.keys().min())
#
#		var oldest_key = test_saved_game_states.keys().min()
## warning-ignore:return_value_discarded
#		test_saved_game_states.erase(oldest_key) # erase oldest savestate
	
func save_state(timestamp):

	var game_state = {
		"match_data" : {
			"frametime" : null,
			"matchtime" : null,
			"player_input_state" : null,
			"captured_input_state" : null,
			"input_lock" : null,
	#		"game_set" : null
			},
		"current_rng_seed" : null,
		"player_data" : {},
		"afterimage_data" : [],
		"entities_back_data" : [],
		"entities_front_data" : [],
		"SFX_back_data" : [],
		"SFX_front_data" : [],
		"mob_entities_data" : [],
		"pickups_data" : [],
		"damage_numbers_data" : [],
		"fields_data" : [],
#		"audio_data" : [],
		"stage_data" : {},
		"screenfreeze" : null,
		"darken" : false,
		"screenstop" : 0,
		"entity_ID_ref" : 0
	}
	
	game_state.match_data.frametime = frametime
	game_state.match_data.matchtime = matchtime
	game_state.match_data.player_input_state = player_input_state
	game_state.match_data.captured_input_state = captured_input_state
	game_state.match_data.input_lock = input_lock
	game_state.current_rng_seed = current_rng_seed
#	game_state.match_data.game_set = game_set
	game_state.screenfreeze = screenfreeze
	game_state.darken = darken
	game_state.screenstop = screenstop
	game_state.entity_ID_ref = entity_ID_ref
	

	for player in $Players.get_children():
		game_state.player_data[player.player_ID] = player.save_state()

	for afterimage in $Afterimages.get_children():
		game_state.afterimage_data.append(afterimage.save_state())
		
	for entity in $EntitiesBack.get_children():
		game_state.entities_back_data.append(entity.save_state())
		
	for entity in $EntitiesFront.get_children():
		game_state.entities_front_data.append(entity.save_state())
		
	for entity in $MobEntities.get_children():
		game_state.mob_entities_data.append(entity.save_state())
		
	for SFX in $SFXFront.get_children():
		game_state.SFX_front_data.append(SFX.save_state())
		
	for SFX in $SFXBack.get_children():
		game_state.SFX_back_data.append(SFX.save_state())
		
	for pickup in $PickUps.get_children():
		game_state.pickups_data.append(pickup.save_state())
		
	for field in $Fields.get_children():
		game_state.fields_data.append(field.save_state())
		
	for number in $DamageNumbers.get_children():
		game_state.damage_numbers_data.append(number.save_state())

#	for AudioManager in $AudioPlayers.get_children():
#		game_state.audio_data.append(AudioManager.save_state())
		
	if Globals.static_stage == 0:
		game_state.stage_data = stage.save_state()
		
	if Globals.survival_level != null:
		game_state.level_data = LevelControl.save_state()

#	ResourceSaver.save("res://Scenes/SavedData/GameState.tres", game_state)
	if timestamp is int:
		if Netplay.is_netplay():
			$NetgameSetup.saved_game_states[timestamp] = game_state.duplicate(true)
		elif Globals.watching_replay:
			$ReplayControl.replay_saved_game_states[timestamp] = game_state.duplicate(true)
		elif frame_reverse and Globals.editor:
			test_saved_game_states[timestamp] = game_state.duplicate(true)
	else:
		if Globals.editor:
			if timestamp == "test_state":
				if !Globals.watching_replay:
					test_state = game_state.duplicate(true)
				else:
					$ReplayControl.test_state = game_state.duplicate(true)
			elif timestamp == "test_state2":
				if !Globals.watching_replay:
					test_state2 = game_state.duplicate(true)
			else:
				training_save_state = game_state.duplicate(true)
		else:
			training_save_state = game_state.duplicate(true)
				
#	game_state.clear()


func load_state(game_state, loading_autosave = true):
	
	var loaded_game_state = game_state.duplicate(true)

	frametime = loaded_game_state.match_data.frametime
	matchtime = loaded_game_state.match_data.matchtime
	player_input_state = loaded_game_state.match_data.player_input_state
	captured_input_state = loaded_game_state.match_data.captured_input_state
	input_lock = loaded_game_state.match_data.input_lock
	current_rng_seed = loaded_game_state.current_rng_seed
	entity_ID_ref = loaded_game_state.entity_ID_ref
#	game_set = loaded_game_state.game_state.match_data.game_set
		
	if Globals.survival_level != null:
		LevelControl.load_state(game_state.level_data)

	if Globals.static_stage == 0:
		stage.load_state(loaded_game_state.stage_data)

	for mob in get_tree().get_nodes_in_group("MobNodes"):
		mob.free()
	for load_player_id in loaded_game_state.player_data.keys():
		if load_player_id >= 0:
			get_player_node(load_player_id).load_state(loaded_game_state.player_data[load_player_id])
		else:
			var new_mob = LevelControl.loaded_mob_scene.instance()
			$Players.add_child(new_mob)
			new_mob.load_state(loaded_game_state.player_data[load_player_id])
		
	for player in $Players.get_children():
		player.load_state(loaded_game_state.player_data[player.player_ID])
	
	# remove children
	for afterimage in $Afterimages.get_children():
		afterimage.free()
	for entity in $EntitiesBack.get_children():
		entity.free()
	for entity in $EntitiesFront.get_children():
		entity.free()
	for entity in $MobEntities.get_children():
		entity.free()
	for SFX in $SFXFront.get_children():
		SFX.free()
	for SFX in $SFXBack.get_children():
		SFX.free()
	for pickup in $PickUps.get_children():
		pickup.free()
	for field in $Fields.get_children():
		field.free()
	for number in $DamageNumbers.get_children():
		number.free()
#	for AudioManager in $AudioPlayers.get_children():
#		AudioManager.kill()
		
		
	# re-add children
	for state_data in loaded_game_state.afterimage_data:
		var new_afterimage = Loader.loaded_afterimage_scene.instance()
		$Afterimages.add_child(new_afterimage)
		new_afterimage.load_state(state_data)

	for state_data in loaded_game_state.entities_back_data:
		var new_entity = Loader.loaded_entity_scene.instance()
		$EntitiesBack.add_child(new_entity)
		new_entity.load_state(state_data)
		
	for state_data in loaded_game_state.entities_front_data:
		var new_entity = Loader.loaded_entity_scene.instance()
		$EntitiesFront.add_child(new_entity)
		new_entity.load_state(state_data)
		
	for state_data in loaded_game_state.mob_entities_data:
		var new_entity = LevelControl.loaded_mob_entity_scene.instance()
		$MobEntities.add_child(new_entity)
		new_entity.load_state(state_data)
		
	for state_data in loaded_game_state.SFX_front_data:
		var new_SFX = Loader.loaded_SFX_scene.instance()
		$SFXFront.add_child(new_SFX)
		new_SFX.load_state(state_data)
		
	for state_data in loaded_game_state.SFX_back_data:
		var new_SFX = Loader.loaded_SFX_scene.instance()
		$SFXBack.add_child(new_SFX)
		new_SFX.load_state(state_data)
		
	for state_data in loaded_game_state.pickups_data:
		var new_pickup = LevelControl.loaded_pickup_scene.instance()
		$PickUps.add_child(new_pickup)
		new_pickup.load_state(state_data)
		
	for state_data in loaded_game_state.fields_data:
		var new_field = Loader.loaded_field_scene.instance()
		$Fields.add_child(new_field)
		new_field.load_state(state_data)
		
	for state_data in loaded_game_state.damage_numbers_data:
		var new_number = Loader.loaded_dmg_num_scene.instance()
		$DamageNumbers.add_child(new_number)
		new_number.load_state(state_data)
		
#	for state_data in loaded_game_state.audio_data:
#		var new_audio = Globals.loaded_audio_scene.instance()
#		$AudioPlayers.add_child(new_audio)
#		new_audio.load_state(state_data)
	
		
	# do these after re-adding the children
	screenfreeze = loaded_game_state.screenfreeze
	screenstop = loaded_game_state.screenstop
	process_screenfreeze()
	darken = loaded_game_state.darken
	process_darken()
		
	if frame_reverse and !loading_autosave: # when loading manual save, erase autoload states
		test_saved_game_states.clear()
		
#	loaded_game_state.clear()
	
	
# DETECT RINGOUT --------------------------------------------------------------------------------------------------	
# called by Physics.gd

func is_offstage(in_box):
	var target_box
	if in_box is Rect2:
		target_box = in_box
	else:
		target_box = Rect2(in_box.rect_global_position, in_box.rect_size)
	if !stage_box.get_rect().intersects(target_box):
		return true
	return false
	
func is_point_offstage(point: Vector2):
	var point_rect = Rect2(point.x - 1, point.y - 1, 2, 2)
	if !stage_box.get_rect().intersects(point_rect):
		return true
	return false
		
func detect_kill(character_box):
	if is_offstage(character_box): # if collision box is outside stage_box, kill them
		character_box.get_parent().on_kill()
		return true
	return false
	
func detect_offstage(entity_sprite_box):
	if is_offstage(entity_sprite_box): # if collision box is outside stage_box, kill them
		entity_sprite_box.get_parent().on_offstage()
		return true
	return false
	
func get_killblast_angle_and_screenshake(body_position):
	
	var out_angle := 0.0
	
	var left_wall_lvl = stage_box.rect_global_position.x
	var right_wall_lvl = stage_box.rect_global_position.x + stage_box.rect_size.x
	var ceil_lvl = stage_box.rect_global_position.y
	var floor_lvl = stage_box.rect_global_position.y + stage_box.rect_size.y
#	var center := Vector2(stage_box.rect_global_position.x + stage_box.rect_size.x / 2.0, \
#			stage_box.rect_global_position.y + stage_box.rect_size.y / 2.0)
	
	if body_position.y >= floor_lvl: # floor
		out_angle = 0.0
		if body_position.x <= left_wall_lvl + MARGIN_TO_TILT_KILLBLAST:
			out_angle -= KILLBLAST_TILT_ANGLE
		elif body_position.x >= right_wall_lvl - MARGIN_TO_TILT_KILLBLAST:
			out_angle += KILLBLAST_TILT_ANGLE
		set_screenshake(6)
			
	elif body_position.y <= ceil_lvl:
		out_angle = PI
		if body_position.x <= left_wall_lvl + MARGIN_TO_TILT_KILLBLAST:
			out_angle += KILLBLAST_TILT_ANGLE
		elif body_position.x >= right_wall_lvl - MARGIN_TO_TILT_KILLBLAST:
			out_angle -= KILLBLAST_TILT_ANGLE
		set_screenshake(6)
			
	elif body_position.x <= left_wall_lvl:
		out_angle = -PI/2
		if body_position.y <= ceil_lvl + MARGIN_TO_TILT_KILLBLAST:
			out_angle -= KILLBLAST_TILT_ANGLE
		elif body_position.y >= floor_lvl - MARGIN_TO_TILT_KILLBLAST:
			out_angle += KILLBLAST_TILT_ANGLE
		set_screenshake(6)
		
	else: # right side
		out_angle = PI/2
		if body_position.y <= ceil_lvl + MARGIN_TO_TILT_KILLBLAST:
			out_angle += KILLBLAST_TILT_ANGLE
		elif body_position.y >= floor_lvl - MARGIN_TO_TILT_KILLBLAST:
			out_angle -= KILLBLAST_TILT_ANGLE
		set_screenshake(6)
			
	return out_angle

	
	
	
# DETECT HIT --------------------------------------------------------------------------------------------------	
		
func detect_hit():
	
	# get the hitboxes and hurtboxes of every player and attach attack data to each hitbox, convert their coordinates to global coordinates
	# iterate through the hitboxes and test if they overlap with any hurtbox not belonging to their parent
	# if so, call landed_a_hit() and being_hit() for those characters
	
	# EXTRACT POLYGONS --------------------------------------------------------------------------------------------------
	
	var player_hitboxes = [] # array of dictionaries
	var player_hurtboxes = []
#	var SD_hurtboxes = []

	var mob_hitboxes = [] # array of dictionaries
	var mob_hurtboxes = []
	
	for player in $Players.get_children():
		var polygons_queried = player.query_polygons()
		# will not return hitbox if in hitstop
		
		if polygons_queried[Em.hit.HITBOX] != null: # if hitbox is not empty
			var move_data_and_name = player.query_move_data_and_name()
			var hitbox = {
				Em.hit.RECT: polygons_queried[Em.hit.RECT],
				Em.hit.POLYGON : polygons_queried[Em.hit.HITBOX],
				Em.hit.OWNER_ID : player.player_ID,
				Em.hit.FACING: player.facing,
				Em.hit.MOVE_NAME : move_data_and_name[Em.hit.MOVE_NAME],
				Em.hit.MOVE_DATA : move_data_and_name[Em.hit.MOVE_DATA], # damage, attack level, etc
			}
			if polygons_queried[Em.hit.SWEETBOX] != null: # if sweetbox is not empty
				hitbox[Em.hit.SWEETBOX] = polygons_queried[Em.hit.SWEETBOX]
			if polygons_queried[Em.hit.KBORIGIN] != null: # if kborigin is not null
				hitbox[Em.hit.KBORIGIN] = polygons_queried[Em.hit.KBORIGIN]
			if polygons_queried[Em.hit.VACPOINT] != null: # if kborigin is not null
				hitbox[Em.hit.VACPOINT] = polygons_queried[Em.hit.VACPOINT]
				
			if !"MOB" in player:
				player_hitboxes.append(hitbox)
			else:
				mob_hitboxes.append(hitbox)
			
		if polygons_queried[Em.hit.HURTBOX] != null:
			var hurtbox = {
				Em.hit.RECT: polygons_queried[Em.hit.RECT],
				Em.hit.POLYGON : polygons_queried[Em.hit.HURTBOX],
				Em.hit.OWNER_ID : player.player_ID,
				Em.hit.FACING: player.facing,
#				"defensive_state" : null, # blocking, punishable state, etc
			}
			if polygons_queried[Em.hit.SDHURTBOX] != null:
				hurtbox[Em.hit.SDHURTBOX] = polygons_queried[Em.hit.SDHURTBOX]
			
			if !"MOB" in player:
				player_hurtboxes.append(hurtbox)
			else:
				mob_hurtboxes.append(hurtbox)
			
	# for entities
	var entities = $EntitiesBack.get_children()
	entities.append_array($EntitiesFront.get_children())
	
	for entity in entities:
		var polygons_queried = entity.query_polygons()
		if polygons_queried[Em.hit.HITBOX] != null: # if hitbox is not empty
			var move_data_and_name = entity.query_move_data_and_name()
			var hitbox = {
				Em.hit.RECT: polygons_queried[Em.hit.RECT],
				Em.hit.POLYGON : polygons_queried[Em.hit.HITBOX],
				Em.hit.OWNER_ID : entity.master_ID,
				Em.hit.ENTITY_PATH : entity.get_path(),
				Em.hit.FACING: entity.facing,
				Em.hit.MOVE_NAME : move_data_and_name[Em.hit.MOVE_NAME],
				Em.hit.MOVE_DATA : move_data_and_name[Em.hit.MOVE_DATA], # damage, attack level, etc
			}
			if polygons_queried[Em.hit.SWEETBOX] != null: # if sweetbox is not empty
				hitbox[Em.hit.SWEETBOX] = polygons_queried[Em.hit.SWEETBOX]
			if polygons_queried[Em.hit.KBORIGIN] != null: # if kborigin is not null
				hitbox[Em.hit.KBORIGIN] = polygons_queried[Em.hit.KBORIGIN]
			if polygons_queried[Em.hit.VACPOINT] != null: # if kborigin is not null
				hitbox[Em.hit.VACPOINT] =  polygons_queried[Em.hit.VACPOINT]
				
			player_hitboxes.append(hitbox)
			
	for mob_entity in $MobEntities.get_children():
		var polygons_queried = mob_entity.query_polygons()
		if polygons_queried[Em.hit.HITBOX] != null: # if hitbox is not empty
			var move_data_and_name = mob_entity.query_move_data_and_name()
			var hitbox = {
				Em.hit.MOB : true,
				Em.hit.RECT: polygons_queried[Em.hit.RECT],
				Em.hit.POLYGON : polygons_queried[Em.hit.HITBOX],
				Em.hit.OWNER_ID : mob_entity.master_ID,
				Em.hit.ENTITY_PATH : mob_entity.get_path(),
				Em.hit.FACING: mob_entity.facing,
				Em.hit.MOVE_NAME : move_data_and_name[Em.hit.MOVE_NAME],
				Em.hit.MOVE_DATA : move_data_and_name[Em.hit.MOVE_DATA], # damage, attack level, etc
			}
			if polygons_queried[Em.hit.SWEETBOX] != null: # if sweetbox is not empty
				hitbox[Em.hit.SWEETBOX] = polygons_queried[Em.hit.SWEETBOX]
			if polygons_queried[Em.hit.KBORIGIN] != null: # if kborigin is not null
				hitbox[Em.hit.KBORIGIN] = polygons_queried[Em.hit.KBORIGIN]
			if polygons_queried[Em.hit.VACPOINT] != null: # if kborigin is not null
				hitbox[Em.hit.VACPOINT] =  polygons_queried[Em.hit.VACPOINT]
				
			mob_hitboxes.append(hitbox)
	
	if $PolygonDrawer.visible:
		$PolygonDrawer.activate(player_hitboxes, mob_hitboxes, player_hurtboxes, mob_hurtboxes)
		# draw the polygons, only visible during training/debugging
	
	# ACTUAL HIT DETECTION --------------------------------------------------------------------------------------------------
	
	var hit_data_array = []
	
	if Globals.survival_level == null:
		scan_for_hits(hit_data_array, player_hitboxes, player_hurtboxes)
	else:
		scan_for_hits(hit_data_array, player_hitboxes, mob_hurtboxes)
		scan_for_hits(hit_data_array, mob_hitboxes, player_hurtboxes)
		

	for hit_data in hit_data_array:
		
		var attacker = get_player_node(hit_data[Em.hit.ATKER_ID])
		var attacker_or_entity = attacker
		if Em.hit.ENTITY_PATH in hit_data:
			attacker_or_entity = get_node(hit_data[Em.hit.ENTITY_PATH])
			
		var defender = get_player_node(hit_data[Em.hit.DEFENDER_ID])
		
		if attacker_or_entity.is_hitcount_maxed(defender.player_ID, hit_data[Em.hit.MOVE_DATA]):
			continue # attacker/entity must still have hitcount left, some attacks changes hitcount record of other attacks, so put this here
		
		defender.being_hit(hit_data) # will add stuff to hit_data, passing by reference
		
		if !Em.move.SEQ in hit_data[Em.hit.MOVE_DATA] and !Em.hit.CANCELLED in hit_data:
#			if !Em.hit.ENTITY_PATH in hit_data:
#				attacker.landed_a_hit(hit_data)
#	#				$Players.move_child(get_node(hit_data.attacker_nodepath), 0) # move attacker to bottom layer to see defender easier
#			else:
			attacker_or_entity.landed_a_hit(hit_data)
				
		
func scan_for_hits(hit_data_array, hitboxes, hurtboxes):
	for hitbox in hitboxes:
		for hurtbox in hurtboxes:
			if hitbox[Em.hit.OWNER_ID] == hurtbox[Em.hit.OWNER_ID]:
				continue # defender must not be owner of hitbox
			
			var attacker = get_player_node(hitbox[Em.hit.OWNER_ID])
			var attacker_or_entity = attacker
			if Em.hit.ENTITY_PATH in hitbox:
				attacker_or_entity = get_node(hitbox[Em.hit.ENTITY_PATH])
			var defender = get_player_node(hurtbox[Em.hit.OWNER_ID])

			if attacker_or_entity == null or defender == null: continue # invalid attack
			
#			if defender_command_grab_dodge(hitbox, hurtbox):
#				continue # attacker must not be command grabbing a defender in ground/air movement startup or in blockstun
			if !Em.hit.ENTITY_PATH in hitbox:
				if !test_priority(hitbox, attacker, hurtbox, defender):
					continue # attacker must pass the priority test
				if defender_anti_airing(hitbox, attacker, hurtbox, defender):
					continue # attacker must not be using an aerial against an anti-airing defender
#				if defender_backdash(hitbox, hurtbox):
#					continue # defender must not be backdashing away from attacker's UNBLOCKABLE/ANTI_GUARD attack
#				if attacker.is_hitcount_maxed(defender.player_ID, hitbox.move_data):
#					continue # attacker must still have hitcount left
#				if attacker.is_player_in_ignore_list(defender.player_ID):
#					continue # defender must not be in attacker's ignore list
			else:
				if first_active_frame_miss(defender):
					continue
				if mob_projectile_miss(attacker_or_entity, defender):
					continue # mob projectiles cannot hit hitstunned players
#			else: # for entities
#				if attacker_or_entity.is_hitcount_maxed(defender.player_ID, hitbox.move_data):
#					continue # entity must still have hitcount left
			if attacker_or_entity.is_player_in_ignore_list(defender.player_ID):
				continue # defender must not be in entity's ignore list
#			if Globals.survival_level != null and defender_mob_grace(hitbox, attacker, hurtbox, defender):
#				continue # attacking mob cannot hit hitstunned player if not being targeted
					
			if !hitbox[Em.hit.RECT].intersects(hurtbox[Em.hit.RECT]):
				continue # intersect_polygons_2d is expensive?
						
			# get an array of PoolVector2Arrays of the intersecting polygons
			var intersect_polygons = Geometry.intersect_polygons_2d(hitbox[Em.hit.POLYGON], hurtbox[Em.hit.POLYGON])
			if intersect_polygons.size() > 0: # detected a hit
				
				if defender_semi_invul(hitbox, attacker_or_entity, hurtbox, defender):
					pass # attacker must not be attacking a semi-invul defender unless with certain moves
				else:
					create_hit_data(hit_data_array, intersect_polygons, hitbox, attacker_or_entity, hurtbox)
				
			elif Em.hit.SDHURTBOX in hurtbox: # detecting a semi-disjoint hit
				var intersect_polygons_sd = Geometry.intersect_polygons_2d(hitbox[Em.hit.POLYGON], hurtbox[Em.hit.SDHURTBOX])
				if intersect_polygons_sd.size() > 0:
					
					create_hit_data(hit_data_array, intersect_polygons_sd, hitbox, attacker_or_entity, hurtbox, true)
					
						
func create_hit_data(hit_data_array, intersect_polygons, hitbox, attacker_or_entity, hurtbox, semi_disjoint = false):
	
	# calculate hit_center (used for emitting hitspark and sweetspotting)
	var point_array := []
	for intersect_polygon in intersect_polygons:
		point_array.append_array(intersect_polygon)
	var hit_center: Vector2 = FMath.find_center(point_array, attacker_or_entity.facing)
	
#	var sum := Vector2.ZERO
#	var number_of_points := 0.0
#	for intersect_polygon in intersect_polygons:
#		for point in intersect_polygon:
#			sum += point
#			number_of_points += 1.0
#	var hit_center: Vector2
#	hit_center = sum / number_of_points
#	hit_center.x = round(hit_center.x) # remove decimals
#	hit_center.y = round(hit_center.y) # remove decimals

	var sweetspotted := false
	if semi_disjoint == false and Em.hit.SWEETBOX in hitbox:
		if Detection.point_in_polygon(hit_center, hitbox[Em.hit.SWEETBOX]): # Geometry.is_point_in_polygon() wouldn't work on pixels due to left/right
			sweetspotted = true # cannot sweetspot on SD hits
	
	var hit_data = { # send this to both attacker and defender
		Em.hit.ATKER_ID : hitbox[Em.hit.OWNER_ID],
		Em.hit.DEFENDER_ID : hurtbox[Em.hit.OWNER_ID],
		Em.hit.HIT_CENTER : hit_center,
		Em.hit.SEMI_DISJOINT: semi_disjoint,
		Em.hit.SWEETSPOTTED : sweetspotted,
		Em.hit.ATK_FACING : hitbox[Em.hit.FACING],
		Em.hit.DEFEND_FACING : hurtbox[Em.hit.FACING],
		Em.hit.MOVE_NAME : hitbox[Em.hit.MOVE_NAME],
		Em.hit.MOVE_DATA : hitbox[Em.hit.MOVE_DATA],
#		"defensive_state": hurtbox.defensive_state,
	}
	
	if Em.hit.KBORIGIN in hitbox:
		hit_data[Em.hit.KBORIGIN] = hitbox[Em.hit.KBORIGIN]
	if Em.hit.VACPOINT in hitbox:
		hit_data[Em.hit.VACPOINT] = hitbox[Em.hit.VACPOINT]
	
	if Em.hit.ENTITY_PATH in hitbox: # flag hit as a entity
		hit_data[Em.hit.ENTITY_PATH] = hitbox[Em.hit.ENTITY_PATH]
	
	hit_data_array.append(hit_data)
	
	
func test_priority(hitbox, attacker, _hurtbox, defender): # return false if attacker fail the priority check, will not process the hit if so
#	return true
	if defender.is_atk_active():
		# Rule 1: you cannot hit an opponent on the 1st frame of THEIR active frames
		# you are invincible on the 1st frame of your active frames!
		# this allow at least the 1st frame of the attack to be shown during clashes
		if defender.Animator.time == 0:
			return false
		# Rule 2: you cannot hit an opponent using a move of higher priority on the 1st 2 frames of YOUR active frames
		# this allow higher priority attack to beat lower priority ones after the frame 1 invincibility of Rule 1
		# sweetspots should at least be 3 frames long (50ms)
		elif attacker.Animator.time <= 1:
			if attacker.query_priority(hitbox[Em.hit.MOVE_NAME]) < defender.query_priority():
				return false
	return true
	
	
func first_active_frame_miss(defender): # projectiles cannot hit targets on 1st frame of active frame
	if defender.is_atk_active():
		if defender.Animator.time == 0:
			return true
	return false
	
	
func mob_projectile_miss(entity, defender):
	
	if Globals.survival_level == null: return false
	
	if Globals.difficulty == 3:
		return false
	if entity == null or defender == null:
		return false
	if !entity.is_in_group("MobEntityNodes"):
		return false
	if !defender.is_in_group("PlayerNodes"):
		return false
	if "can_combo" in entity.unique_data:
		return false
	if defender.is_hitstunned():
		return true
	return false
	
	
func defender_anti_airing(hitbox, attacker, _hurtbox, defender):

	if Globals.survival_level != null: return false # anti-air is not a thing in Survival

	if attacker.grounded:
		return false
	elif attacker.get_feet_pos().y > defender.get_feet_pos().y:
		return false # if attacker is airborne, they must be above defender
		
	if defender.is_atk_startup() or defender.is_atk_active():
		
		var defender_move_data = defender.query_move_data()
		
		if Em.atk_attr.ANTI_AIR in defender_move_data[Em.move.ATK_ATTR]:

			# for defender to successfully anti-air, they must be attacking, must be using an ANTI-AIR move, 
			# and the attacker must be airborne and above defender
			var defender_tier = Globals.atk_type_to_tier(defender_move_data[Em.move.ATK_TYPE])
			var attacker_tier = Globals.atk_type_to_tier(hitbox[Em.hit.MOVE_DATA][Em.move.ATK_TYPE])
			
			if attacker_tier == 0: return true # air normals can be anti-aired by anything
			elif attacker_tier > defender_tier: return false # cannot anti-air attacks of higher tier
#			elif attacker_tier == defender_tier:
#				if attacker.query_priority(hitbox.move_name) >= defender.query_priority():
#					return false # if same tier, cannot anti-air attacks of equal or higher priority
			else:
				return true # defender successfully anti-aired
					
	return false
	
#func defender_mob_grace(hitbox, attacker, hurtbox, defender):
#
#	if hitbox.mob == true and hurtbox.mob == false: pass # attacker must be a mob, defender a player
#	else: return
#
#	if !defender.get_node("HitStunTimer").is_running(): return false # defender must be in hitstun
#
#	var attacker_ID: int
#	if !Em.hit.ENTITY_PATH in hitbox: # not entity
#		attacker_ID = attacker.player_ID
#	else:
#		attacker_ID = get_node(hitbox[Em.hit.ENTITY_PATH]).master_ID
#
#	if defender.target_ID != attacker_ID: return true # attacking mob is not targeted by player, cannot hit hitstunned player
#	else:
#		return false
	
	
func defender_semi_invul(hitbox, attacker, _hurtbox, defender):
	var attacker_or_entity
	if !Em.hit.ENTITY_PATH in hitbox: # not entity
		attacker_or_entity = attacker
	else:
		attacker_or_entity = get_node(hitbox[Em.hit.ENTITY_PATH])
		
#	if Em.atk_attr.UNBLOCKABLE in hitbox.move_data[Em.move.ATK_ATTR] or \
#			hitbox.move_data[Em.move.ATK_TYPE] in [Em.atk_type.SUPER]:
#		return false # defender's semi-invul failed
		
	if hitbox[Em.hit.MOVE_DATA][Em.move.ATK_TYPE] in [Em.atk_type.SUPER]:
		return false # defender's semi-invul failed
				
	if defender.check_semi_invuln():
		if "chain_combo" in attacker_or_entity: # prevent chaining on iframed attack
			attacker_or_entity.chain_combo = Em.chain_combo.NO_CHAIN
		defender.perfect_dodge()
		return true # defender's semi-invul succeeded

	return false
	
	
#func defender_backdash(hitbox, hurtbox):
#	var attacker = get_node(hitbox.owner_nodepath)
#	var defender = get_node(hurtbox.owner_nodepath)
#	var attacker_attr = hitbox.move_data[Em.move.ATK_ATTR]
#	if Em.atk_attr.UNBLOCKABLE in attacker_attr or Em.atk_attr.ANTI_GUARD in attacker_attr:
#		if defender.new_state in [Em.char_state.GROUND_REC, Em.char_state.AIR_REC] or \
#				defender.Animator.query_to_play(["DashTransit", "aDashTransit"]):
#			if defender.Animator.query_to_play(["Tech", "GuardTech"]):
#				return false
#			elif defender.facing == sign(defender.position.x - attacker.position.x) and \
#					!defender.Animator.query_to_play(["aDashUU", "aDashDD"]):
#				return true # defender's backdash succeeded
#	return false # defender's backdash failed
#
#func defender_command_grab_dodge(hitbox, hurtbox):
##	var attacker_or_entity
##	if !Em.hit.ENTITY_PATH in hitbox: # not entity
##		attacker_or_entity = get_node(hitbox.owner_nodepath)
##	else:
##		attacker_or_entity = get_node(hitbox[Em.hit.ENTITY_PATH]) # rare entity command grab
#	var defender = get_node(hurtbox.owner_nodepath)
#	if Em.atk_attr.COMMAND_GRAB in hitbox.move_data[Em.move.ATK_ATTR]:
#		if defender.new_state in [Em.char_state.GROUND_STARTUP, Em.char_state.AIR_STARTUP, Em.char_state.GROUND_BLOCKSTUN, \
#				Em.char_state.AIR_BLOCKSTUN]:
#			return true # defender's evaded command grab
#	return false

# HANDLING ZOOM --------------------------------------------------------------------------------------------------

func handle_zoom():
	# first, find the distance between the furthest player and the average positions of the players
	# find for both vertical and horizontal
	var array_of_horizontal_diff = [0]
	var array_of_vertical_diff = [0]
	
	if Globals.survival_level == null:
		
		for player in $Players.get_children():
			var valid := true
			if player.state == Em.char_state.DEAD:
				if player.stock_points_left > 0:
					var time_diff = Globals.RespawnTimer_WAIT_TIME - player.get_node("RespawnTimer").time
					if time_diff > 30 or time_diff < 0:
						valid = false
				else: valid = false
					
			if valid:
				array_of_horizontal_diff.append(abs(player.position.x - $CameraRef.position.x))
				array_of_vertical_diff.append(abs(player.position.y - $CameraRef.position.y))
			
	else: # survival mode
		var player_1 = get_player_node(0)
		if player_1.state != Em.char_state.DEAD:
			array_of_horizontal_diff.append(abs(player_1.position.x - $CameraRef.position.x))
			array_of_vertical_diff.append(abs(player_1.position.y - $CameraRef.position.y))
			var target = player_1.get_target()
			if target != player_1:
				array_of_horizontal_diff.append(abs(target.position.x - $CameraRef.position.x))
				array_of_vertical_diff.append(abs(target.position.y - $CameraRef.position.y))
		if Globals.player_count == 2:
			var player_2 = get_player_node(1)
			if player_2.state != Em.char_state.DEAD:
				array_of_horizontal_diff.append(abs(player_2.position.x - $CameraRef.position.x))
				array_of_vertical_diff.append(abs(player_2.position.y - $CameraRef.position.y))
				var target = player_2.get_target()
				if target != player_2:
					array_of_horizontal_diff.append(abs(target.position.x - $CameraRef.position.x))
					array_of_vertical_diff.append(abs(target.position.y - $CameraRef.position.y))
	
	var furthest_horizontal = array_of_horizontal_diff.max()
	var furthest_vertical = array_of_vertical_diff.max()
	
	# for either of these distances, draw the smallest 16:9 rectangle centered on the average position
	# that reaches the furthest horizontal/vertical player
	var horizontal_rect_area = (furthest_horizontal * 2) * (furthest_horizontal * (9.0/16.0) * 2)
	var vertical_rect_area = (furthest_vertical * 2) * (furthest_vertical * (16.0/9.0) * 2)
	
	# get the area of the larger rectangle, this is the smallest 16:9 rectangle centered on the average position
	# that reaches the furthest player
	var largest_area = max(horizontal_rect_area, vertical_rect_area)
	
	# get the difference between this area and the target area with the distances you want the players to be at
	var viewport_rect_area = get_viewport_rect().size.x * get_viewport_rect().size.y
	var area_diff = largest_area - viewport_rect_area * 0.5
	
	var change_in_zoom: float = 0.0
	
	if area_diff > 2000: # players too far (smallest rectangle larger than target area), zoom out
		# only zoom out if camera size not over camera limit
		if get_viewport_rect().size.x < $CameraRef/Camera2D.limit_right - $CameraRef/Camera2D.limit_left and \
				get_viewport_rect().size.y < $CameraRef/Camera2D.limit_bottom - $CameraRef/Camera2D.limit_top:
			change_in_zoom -= Globals.CAMERA_ZOOM_SPEED * Globals.FRAME * abs(area_diff - 2000)
			# slow down zoom speed when reaching camera limits
			if get_viewport_rect().size.x + 200 > $CameraRef/Camera2D.limit_right - $CameraRef/Camera2D.limit_left or \
					get_viewport_rect().size.y + 200  > $CameraRef/Camera2D.limit_bottom - $CameraRef/Camera2D.limit_top:
				change_in_zoom *= 0.5
	elif area_diff < -2000: # players too near (smallest rectangle smaller than target area), zoom in
		change_in_zoom += Globals.CAMERA_ZOOM_SPEED * Globals.FRAME * abs(area_diff + 2000) * 0.5
		
	# when zoomed out, reduce zoom speed, when zoomed in, increase zoom speed
	if Globals.zoom_level < 1.0:
		change_in_zoom *= 0.5
	elif Globals.zoom_level > 1.0:
		change_in_zoom *= Globals.zoom_level * 1.5
	
	Globals.change_zoom_level(change_in_zoom)
	
# SCREEN EFFECTS  --------------------------------------------------------------------------------------------------
	
func screenshake():
	$CameraRef/Camera2D.offset_h = screen_shake_amount * rand_range(-0.1, 0.1)
	
# warning-ignore:narrowing_conversion
	if posmod(floor(frametime / 4.0), 2) == 0: # change offset direction every X frames
		$CameraRef/Camera2D.offset_v = screen_shake_amount
	else:
		$CameraRef/Camera2D.offset_v = -screen_shake_amount
	
	$CameraRef/Camera2D.limit_left = stage_box.rect_global_position.x - $CameraRef/Camera2D.offset_h
	$CameraRef/Camera2D.limit_right = stage_box.rect_global_position.x + stage_box.rect_size.x + $CameraRef/Camera2D.offset_h
	$CameraRef/Camera2D.limit_top = stage_box.rect_global_position.y - $CameraRef/Camera2D.offset_v
	$CameraRef/Camera2D.limit_bottom = stage_box.rect_global_position.y + stage_box.rect_size.y + $CameraRef/Camera2D.offset_v
	
	
func set_screenshake(amount = 5):
	if amount > screen_shake_amount:
		screen_shake_amount = amount
		
func set_screenstop(amount = 20):
	screenstop = amount
	process_screenfreeze()
	
func process_screenstop():
	if screenstop > 0:
# warning-ignore:narrowing_conversion
		screenstop = max(screenstop - 1, 0)
		if screenstop == 0:
			process_screenfreeze()
	
func process_screenfreeze():
	if screenfreeze != null or screenstop != 0:
		for x in get_tree().get_nodes_in_group("StagePause"):
			for x_child in x.get_children():
				if x_child is AnimatedSprite:
					x_child.playing = false
	else:
		for x in get_tree().get_nodes_in_group("StagePause"):
			for x_child in x.get_children():
				if x_child is AnimatedSprite:
					x_child.playing = true
					
func process_darken():
	if darken:
		for x in get_tree().get_nodes_in_group("StageDarken"):
			x.modulate = SCREEN_DARKEN
		for x in $EntitiesBack.get_children():
			if x.master_ID == screenfreeze: pass
			else: x.modulate = SCREEN_DARKEN
		for x in $SFXBack.get_children():
			if "ignore_freeze" in x and x.ignore_freeze: pass
			else: x.modulate = SCREEN_DARKEN
		for x in $Afterimages.get_children():
			if "ignore_freeze" in x and x.ignore_freeze: pass
			else: x.modulate = SCREEN_DARKEN
		for x in $Players.get_children():
			if x.player_ID == screenfreeze: pass
			else: x.modulate = SCREEN_DARKEN
		for x in $EntitiesFront.get_children():
			if x.master_ID == screenfreeze: pass
			else: x.modulate = SCREEN_DARKEN
		for x in $MobEntities.get_children():
			if x.master_ID == screenfreeze: pass
			else: x.modulate = SCREEN_DARKEN
		for x in $SFXFront.get_children():
			if "ignore_freeze" in x and x.ignore_freeze: pass
			else: x.modulate = SCREEN_DARKEN
	else:
		for x in get_tree().get_nodes_in_group("StageDarken"):
			x.modulate = Color(1.0, 1.0, 1.0)
		for x in $EntitiesBack.get_children(): x.modulate = Color(1.0, 1.0, 1.0)
		for x in $SFXBack.get_children(): x.modulate = Color(1.0, 1.0, 1.0)
		for x in $Afterimages.get_children(): x.modulate = Color(1.0, 1.0, 1.0)
		for x in $Players.get_children(): x.modulate = Color(1.0, 1.0, 1.0)
		for x in $EntitiesFront.get_children(): x.modulate = Color(1.0, 1.0, 1.0)
		for x in $MobEntities.get_children(): x.modulate = Color(1.0, 1.0, 1.0)
		for x in $SFXFront.get_children(): x.modulate = Color(1.0, 1.0, 1.0)
					
func superfreeze(player_path):		
	to_superfreeze = player_path
					
func check_superfreeze():
	if to_superfreeze != null:
		if screenfreeze == null:
			screenfreeze = get_node(to_superfreeze).player_ID
			darken = true
		else:
			screenfreeze = null
			darken = false
		process_screenfreeze()
		process_darken()
		$Players.move_child(get_node(to_superfreeze), $Players.get_child_count() - 1) # move to topmost layer
	
func lethalfreeze(player_path):
	to_lethalfreeze = player_path
	
func check_lethalfreeze():
	if to_lethalfreeze != null:
		if to_lethalfreeze != "unfreeze":
			if screenfreeze == null:
				screenfreeze = get_node(to_lethalfreeze).player_ID
			else:
				screenfreeze = null
			process_screenfreeze()
		else:
			screenfreeze = null
			process_screenfreeze()
			
func is_stage_paused():
	if screenfreeze != null or screenstop != 0:
		return true
	else: return false
	

# HUD ELEMENTS  --------------------------------------------------------------------------------------------------

func set_input_indicator():
	for player_ID in Globals.player_count:
		var player = get_player_node(player_ID)
		var indicator = HUD.get_node("P" + str(player_ID + 1) + "_HUDRect/Inputs")
		if (Globals.watching_replay and $ReplayControl.input_indicators) or \
				(Globals.training_mode and Globals.training_settings.input_viewer == 1):
			indicator.show()
			for input in indicator.get_children():
				if input.name != "InputFrame":
					input.hide()
			for input in player.input_state.pressed:
				match input:
					player.button_up:
						indicator.get_node("InputUp").show()
					player.button_down:
						indicator.get_node("InputDown").show()
					player.button_left:
						indicator.get_node("InputLeft").show()
					player.button_right:
						indicator.get_node("InputRight").show()
					player.button_unique:
						indicator.get_node("InputUnique").show()
					player.button_special:
						indicator.get_node("InputSpecial").show()
					player.button_jump:
						indicator.get_node("InputJump").show()
					player.button_light:
						indicator.get_node("InputLight").show()
					player.button_fierce:
						indicator.get_node("InputFierce").show()
					player.button_dash:
						indicator.get_node("InputDash").show()
					player.button_aux:
						indicator.get_node("InputAux").show()
					player.button_block:
						indicator.get_node("InputBlock").show()	
		else:
			indicator.hide()
			

#func damage_limit_update(character):
#	var dmg_limit_indicator = HUD.get_node("P" + str(character.player_ID + 1) + "_HUDRect/Portrait/DamageLimit")
#	dmg_limit_indicator.text = str(character.UniqChar.get_stat("DAMAGE_VALUE_LIMIT"))
	

func damage_update(character, damage: int = 0):
	var dmg_val_indicator = HUD.get_node("P" + str(character.player_ID + 1) + "_HUDRect/Portrait/DamageNode/DamageValue")
	dmg_val_indicator.text = str(character.get_stat("DAMAGE_VALUE_LIMIT") - character.current_damage_value)
	
	# change color
	var dmg_percent = character.get_damage_percent()
	if dmg_percent < 25:
		dmg_val_indicator.get_node("../AnimationPlayer2").stop()
		dmg_val_indicator.modulate = Color(1.0, 1.0, 1.0)
	elif dmg_percent < 50:
		dmg_val_indicator.get_node("../AnimationPlayer2").stop()
		dmg_val_indicator.modulate = Color(1.0, 1.0, 0.5)
	elif dmg_percent < 75:
		dmg_val_indicator.get_node("../AnimationPlayer2").stop()
		dmg_val_indicator.modulate = Color(1.0, 0.5, 0.2)
	elif dmg_percent < 100:
		dmg_val_indicator.get_node("../AnimationPlayer2").stop()
		dmg_val_indicator.modulate = Color(1.0, 0.0, 0.0)
	else:
		dmg_val_indicator.get_node("../AnimationPlayer2").play("flashing")
		
	if damage > 0:
		dmg_val_indicator.get_node("../AnimationPlayer").stop() # this will restart the animation if it is playing it
		dmg_val_indicator.get_node("../AnimationPlayer").play("damage") # shake label
		
				
func guard_gauge_update(character):
	
	var gg_indicator1 = HUD.get_node("P" + str(character.player_ID + 1) + "_HUDRect/GaugesUnder/GuardGauge1")
	var gg_indicator2 = HUD.get_node("P" + str(character.player_ID + 1) + "_HUDRect/GaugesUnder/GuardGauge2")
	
	var guard_gauge_percent: int
	if character.current_guard_gauge <= 0:
		guard_gauge_percent = character.get_guard_gauge_percent_below()
		gg_indicator1.value = guard_gauge_percent
		gg_indicator2.value = 0
	else:
		guard_gauge_percent = character.get_guard_gauge_percent_above()
		gg_indicator1.value = 100
		gg_indicator2.value = guard_gauge_percent
		
	
func ex_gauge_update(character):
	
	var ex_gauge_bars = HUD.get_node("P" + str(character.player_ID + 1) + "_HUDRect/GaugesUnder/EXGauges")
#	var ex_lvl_indicator = HUD.get_node("P" + str(character.player_ID + 1) + "_HUDRect/GaugesUnder/EXLevel")

#	if character.install_time != null and character.get_node("InstallTimer").is_running():
#		character.current_ex_gauge = 0
#		ex_gauge_bars.get_node("AnimationPlayer").play("install")
#		ex_gauge_bars.get_node("EXGauge").value = 0
#		ex_gauge_bars.get_node("EXGauge2").value = 0
#		ex_gauge_bars.get_node("EXGauge3").value = 0
#		ex_gauge_bars.get_node("../EXLock").value = character.get_node("InstallTimer").time / float(character.install_time) * 100
#		return
#	if character.super_ex_lock != null and character.get_node("EXSealTimer").is_running():
#		character.current_ex_gauge = 0
#		ex_gauge_bars.get_node("AnimationPlayer").play("lock")
#		ex_gauge_bars.get_node("EXGauge").value = 0
#		ex_gauge_bars.get_node("EXGauge2").value = 0
#		ex_gauge_bars.get_node("EXGauge3").value = 0
#		ex_gauge_bars.get_node("../EXLock").value = character.get_node("EXSealTimer").time / float(character.super_ex_lock) * 100
#		return

	var current_ex_level: int = int(character.current_ex_gauge / 10000)
	var leftover_ex_gauge: int
	if current_ex_level >= 3:
		leftover_ex_gauge = 100
	else:
		leftover_ex_gauge = FMath.get_fraction_percent(character.current_ex_gauge - (current_ex_level * 10000), 10000)
	
#	ex_gauge_bar.value = leftover_ex_gauge
#	ex_lvl_indicator.text = str(current_ex_level)
	
	match current_ex_level:
		0:
			ex_gauge_bars.get_node("AnimationPlayer").play("level0")
			ex_gauge_bars.get_node("EXGauge").value = leftover_ex_gauge
			ex_gauge_bars.get_node("EXGauge2").value = 0
			ex_gauge_bars.get_node("EXGauge3").value = 0
		1:
			ex_gauge_bars.get_node("AnimationPlayer").play("level1")
			ex_gauge_bars.get_node("EXGauge").value = 100
			ex_gauge_bars.get_node("EXGauge2").value = leftover_ex_gauge
			ex_gauge_bars.get_node("EXGauge3").value = 0
		2:
			ex_gauge_bars.get_node("AnimationPlayer").play("level2")
			ex_gauge_bars.get_node("EXGauge").value = 100
			ex_gauge_bars.get_node("EXGauge2").value = 100
			ex_gauge_bars.get_node("EXGauge3").value = leftover_ex_gauge
		3:
			ex_gauge_bars.get_node("AnimationPlayer").play("level3")
			ex_gauge_bars.get_node("EXGauge").value = 100
			ex_gauge_bars.get_node("EXGauge2").value = 100
			ex_gauge_bars.get_node("EXGauge3").value = 100
	
	if character.current_ex_lock > 0:
		var current_ex_lock_lvl: int = int(character.current_ex_lock / 10000)
		var leftover_ex_lock: int = FMath.get_fraction_percent(character.current_ex_lock - (current_ex_lock_lvl * 10000), 10000)
		
		match current_ex_lock_lvl:
			0:
				ex_gauge_bars.get_node("EXLock").hide()
				ex_gauge_bars.get_node("EXLock2").hide()
				if leftover_ex_lock > 0:
					ex_gauge_bars.get_node("EXLock3").show()
					ex_gauge_bars.get_node("EXLock3").value = leftover_ex_lock
				else:
					ex_gauge_bars.get_node("EXLock3").hide()
			1:
				ex_gauge_bars.get_node("EXLock").hide()
				if leftover_ex_lock > 0:
					ex_gauge_bars.get_node("EXLock2").show()
					ex_gauge_bars.get_node("EXLock2").value = leftover_ex_lock
				else:
					ex_gauge_bars.get_node("EXLock2").hide()
				ex_gauge_bars.get_node("EXLock3").show()
				ex_gauge_bars.get_node("EXLock3").value = 100
			2:
				if leftover_ex_lock > 0:
					ex_gauge_bars.get_node("EXLock").show()
					ex_gauge_bars.get_node("EXLock").value = leftover_ex_lock
				else:
					ex_gauge_bars.get_node("EXLock").hide()
				ex_gauge_bars.get_node("EXLock2").show()
				ex_gauge_bars.get_node("EXLock3").show()
				ex_gauge_bars.get_node("EXLock2").value = 100
				ex_gauge_bars.get_node("EXLock3").value = 100
			3:
				ex_gauge_bars.get_node("EXLock").show()
				ex_gauge_bars.get_node("EXLock2").show()
				ex_gauge_bars.get_node("EXLock3").show()
				ex_gauge_bars.get_node("EXLock").value = 100
				ex_gauge_bars.get_node("EXLock2").value = 100
				ex_gauge_bars.get_node("EXLock3").value = 100
			
	else:
		ex_gauge_bars.get_node("EXLock").hide()
		ex_gauge_bars.get_node("EXLock2").hide()
		ex_gauge_bars.get_node("EXLock3").hide()
		
	
func stock_points_update(character):
	
	var stock_indicator = HUD.get_node("P" + str(character.player_ID + 1) + "_HUDRect/Portrait/StockPoints")
	if !Globals.training_mode:
		stock_indicator.text = str(character.stock_points_left)
	else:
		stock_indicator.text = "INF"
		
#	stock_points_change = int(min(stock_points_change, 9999))
	
#	if stock_points_change < 0: # loss points
#		var stock_loss_indicator = HUD.get_node("P" + str(character.player_ID + 1) + "_HUDRect/Portrait/StockPoints/StockLoss")
#		stock_loss_indicator.text = str(stock_points_change)
#		stock_loss_indicator.get_node("AnimationPlayer").play("stock_loss")
	
	if Globals.survival_level != null and character.stock_points_left <= 0:
		var dmg_val_indicator = HUD.get_node("P" + str(character.player_ID + 1) + "_HUDRect/Portrait/DamageNode/DamageValue")
		dmg_val_indicator.text = "DEAD"
		dmg_val_indicator.get_node("../AnimationPlayer2").stop()
		dmg_val_indicator.modulate = Color(0.6, 0.6, 0.6)
	
	if character.stock_points_left <= 0 and !game_set:
		
		if Globals.survival_level == null:
			game_set = true
			emit_signal("game_set")
			
			match character.player_ID:
				0:
					Globals.winner = [1, get_player_node(1).UniqChar.NAME]
				1:
					Globals.winner = [0, get_player_node(0).UniqChar.NAME]
				
				
func burst_update(character):
	var burst_token = HUD.get_node("P" + str(character.player_ID + 1) + "_HUDRect/Portrait/BurstToken")
	if character.burst_token == Em.burst.AVAILABLE:
		burst_token.get_node("AnimationPlayer").play("flash")
	elif character.burst_token == Em.burst.CONSUMED:
		burst_token.get_node("AnimationPlayer").play("empty")
	elif character.burst_token == Em.burst.EXHAUSTED:
		burst_token.get_node("AnimationPlayer").play("gray")
		
func coin_update(character):	
	var coin_counter = HUD.get_node("P" + str(character.player_ID + 1) + "_HUDRect/Portrait/Coin/Amount")
	coin_counter.text = str(character.coin_count)
		
				
func set_uniqueHUD(player_ID, uniqueHUD):
	HUD.get_node("P" + str(player_ID + 1) + "_HUDRect/GaugesUnder/Unique").add_child(uniqueHUD)
				
				
func get_player_node(player_ID):
	if player_ID == null: return null
	
	if player_ID >= 0:
		for player in get_tree().get_nodes_in_group("PlayerNodes"):
			if player.player_ID == player_ID:
				return player
	else:
		for player in get_tree().get_nodes_in_group("MobNodes"):
			if player.player_ID == player_ID:
				return player
	return null
	
func get_entity_node(entity_ID):
	if entity_ID == null: return null
	
	for field in $Fields.get_children():
		if field.entity_ID == entity_ID:
			return field
			
	if entity_ID >= 0: # positive is player
		for entity in get_tree().get_nodes_in_group("EntityNodes"):
			if entity.entity_ID == entity_ID:
				return entity
		return null
	else: # negative is mob
		for entity in get_tree().get_nodes_in_group("MobEntityNodes"):
			if entity.entity_ID == entity_ID:
				return entity
		return null
	
#func get_player_entity_node(entity_ID):
#	if entity_ID == null: return null
#
#	for entity in get_tree().get_nodes_in_group("EntityNodes"):
#		if entity.entity_ID == entity_ID:
#			return entity
##	for entity in get_tree().get_nodes_in_group("MobEntityNodes"):
##		if entity.entity_ID == entity_ID:
##			return entity
#	return null
#
#func get_mob_entity_node(entity_ID):
#	if entity_ID == null: return null
#
##	for entity in get_tree().get_nodes_in_group("EntityNodes"):
##		if entity.entity_ID == entity_ID:
##			return entity
#	for entity in get_tree().get_nodes_in_group("MobEntityNodes"):
#		if entity.entity_ID == entity_ID:
#			return entity
#	return null


# fade out HUD elements if there is a player behind them
func HUD_fade():
	#  adjust zoom for top and bottom detect boxes,
	$TopHUDBoxP1.rect_size.x = get_viewport_rect().size.x / 6.0
	$TopHUDBoxP1.rect_size.y = get_viewport_rect().size.y / 8.75
	$TopHUDBoxP1.rect_position = $CameraRef/Camera2D.get_camera_screen_center()
	if Globals.player_count != 1:
		$TopHUDBoxP1.rect_position.x -= $TopHUDBoxP1.rect_size.x * 2.0
	else:
		$TopHUDBoxP1.rect_position.x -= $TopHUDBoxP1.rect_size.x * 2.75
	$TopHUDBoxP1.rect_position.y -= $TopHUDBoxP1.rect_size.y * 4
	
	if Detection.detect_bool([$TopHUDBoxP1], ["Players"]):
		HUD.get_node("P1_HUDRect/Portrait").modulate.a = HUD_FADE
	else:
		HUD.get_node("P1_HUDRect/Portrait").modulate.a = 1.0

	$BottomHUDBoxP1.rect_size = get_viewport_rect().size / 6.0
	$BottomHUDBoxP1.rect_size.y = get_viewport_rect().size.y / 8.75
	$BottomHUDBoxP1.rect_position = $CameraRef/Camera2D.get_camera_screen_center()
	if Globals.player_count != 1:
		$BottomHUDBoxP1.rect_position.x -= $BottomHUDBoxP1.rect_size.x * 2.0
	else:
		$BottomHUDBoxP1.rect_position.x -= $BottomHUDBoxP1.rect_size.x * 2.75
	$BottomHUDBoxP1.rect_position.y += $BottomHUDBoxP1.rect_size.y * 3
	
	if Detection.detect_bool([$BottomHUDBoxP1], ["Players"]):
		HUD.get_node("P1_HUDRect/GaugesUnder").modulate.a = HUD_FADE
	else:
		HUD.get_node("P1_HUDRect/GaugesUnder").modulate.a = 1.0
	
	if Globals.player_count > 1:
		$TopHUDBoxP2.rect_size.x = get_viewport_rect().size.x / 6.0
		$TopHUDBoxP2.rect_size.y = get_viewport_rect().size.y / 8.75
		$TopHUDBoxP2.rect_position = $CameraRef/Camera2D.get_camera_screen_center()
		$TopHUDBoxP2.rect_position.x += $TopHUDBoxP2.rect_size.x * 1.0
		$TopHUDBoxP2.rect_position.y -= $TopHUDBoxP2.rect_size.y * 4
		
		if Detection.detect_bool([$TopHUDBoxP2], ["Players"]):
			HUD.get_node("P2_HUDRect/Portrait").modulate.a = HUD_FADE
		else:
			HUD.get_node("P2_HUDRect/Portrait").modulate.a = 1.0

		$BottomHUDBoxP2.rect_size = get_viewport_rect().size / 6.0
		$BottomHUDBoxP2.rect_size.y = get_viewport_rect().size.y / 8.75
		$BottomHUDBoxP2.rect_position = $CameraRef/Camera2D.get_camera_screen_center()
		$BottomHUDBoxP2.rect_position.x += $BottomHUDBoxP2.rect_size.x * 1.0
		$BottomHUDBoxP2.rect_position.y += $BottomHUDBoxP2.rect_size.y * 3	
		
		if Detection.detect_bool([$BottomHUDBoxP2], ["Players"]):
			HUD.get_node("P2_HUDRect/GaugesUnder").modulate.a = HUD_FADE
		else:
			HUD.get_node("P2_HUDRect/GaugesUnder").modulate.a = 1.0
		
	if Globals.time_limit != 0:
		$TimeHUDBox.rect_size = get_viewport_rect().size / 15.0
		$TimeHUDBox.rect_size.y = get_viewport_rect().size.y / 14.0
		$TimeHUDBox.rect_position = $CameraRef/Camera2D.get_camera_screen_center()
		$TimeHUDBox.rect_position.x -= $TimeHUDBox.rect_size.x * 0.5
		$TimeHUDBox.rect_position.y += $TimeHUDBox.rect_size.y * 5.35	
		
		if Detection.detect_bool([$TimeHUDBox], ["Players"]):
			HUD.get_node("MatchTime").modulate.a = HUD_FADE
			HUD.get_node("TimeFrame").modulate.a = HUD_FADE
		else:
			HUD.get_node("MatchTime").modulate.a = 1.0
			HUD.get_node("TimeFrame").modulate.a = 1.0
			
# RNG GENERATOR --------------------------------------------------------------------------------------------------

func rng_generate(upper_limit: int) -> int: # will return a number from 0 to (upper_limit - 1)
	var result: int = current_rng_seed * Globals.PI_NUMBERS[posmod(current_rng_seed + frametime, 100)] + \
			Globals.PI_NUMBERS[posmod(current_rng_seed, 100)] + posmod(frametime, 10000)
	current_rng_seed = wrapi(result, 1, 10000) # each call to generate a number changes the current seed
	return posmod(result, upper_limit)
			
func rng_range(lower_limit: int, upper_limit: int) -> int:
	return lower_limit + rng_generate(upper_limit - lower_limit)
			
func rng_facing():
	if rng_generate(2) == 0:
		return 1
	else:
		return -1
		
func rng_bool():
	if rng_generate(2) == 0:
		return true
	else:
		return false
		
func rng_array(array: Array):
	var index = rng_generate(array.size())
	return array[index]
	
			
# SPAWN STUFF --------------------------------------------------------------------------------------------------


func spawn_entity(master_ID: int, entity_ref: String, out_position, aux_data: Dictionary, palette_ref = null, master_ref = null):
	var entity = Loader.loaded_entity_scene.instance()
	if !"back" in aux_data:
		$EntitiesFront.add_child(entity)
	else:
		$EntitiesBack.add_child(entity)
	entity.init(master_ID, entity_ref, out_position, aux_data, palette_ref, master_ref)
	return entity
	
func spawn_field(master_ID: int, entity_ref: String, out_position, aux_data: Dictionary, palette_ref = null, master_ref = null):
	var field = Loader.loaded_field_scene.instance()
	$Fields.add_child(field)
	field.init(master_ID, entity_ref, out_position, aux_data, palette_ref, master_ref)
	return field

# aux_data contain {"back" : bool, "facing" : 1/-1, "v_mirror" : bool, "rot" : radians, "grounded" : true, "back" : true}
func spawn_SFX(anim: String, loaded_sfx_ref, out_position, aux_data: Dictionary, palette_ref = null, master_ref = null):
	var sfx = Loader.loaded_SFX_scene.instance()
	if !"back" in aux_data:
		$SFXFront.add_child(sfx)
	else:
		$SFXBack.add_child(sfx)
	sfx.init(anim, loaded_sfx_ref, out_position, aux_data, palette_ref, master_ref)
	return sfx
	

# master_ID is passed in to freeze afterimages during hitstop
# master_ref is used to locate spritesheet_ref for character afterimages and locate palettes as well
func spawn_afterimage(master_ID: int, is_entity: bool, spritesheet_ref: String, sprite_node_path: NodePath, master_ref = null, \
		palette_ref = null, color_modulate = null, starting_modulate_a = 0.5, lifetime = 10, afterimage_shader = Em.afterimage_shader.MASTER):
	var afterimage = Loader.loaded_afterimage_scene.instance()
	$Afterimages.add_child(afterimage)
	afterimage.init(master_ID, is_entity, spritesheet_ref, sprite_node_path, master_ref, palette_ref, color_modulate, starting_modulate_a, \
			lifetime, afterimage_shader)
	return afterimage
	
	
func spawn_damage_number(in_number: int, in_position: Vector2, in_color = null):
	if Globals.damage_numbers:
		var number = Loader.loaded_dmg_num_scene.instance()
		$DamageNumbers.add_child(number)
		number.init(in_number, in_position, in_color)
		
	
# aux_data contain "vol", "bus"
func play_audio(audio_ref: String, aux_data: Dictionary):
	if rollback_start_frametime == null:
		var new_audio = Loader.loaded_audio_scene.instance()
		$AudioPlayers.add_child(new_audio)
		new_audio.init(audio_ref, aux_data)
	else: # during rollback, add the audio to the audio_queue instead of playing it, remove audio after AUDIO_QUEUE_LIFE frames
		audio_queue.append({"audio_ref" : audio_ref, "aux_data" : aux_data, "time" : 0})
		
		
func progress_audio_queue():
	var to_erase = []
	for audio in audio_queue:
		audio.time += 1
		if audio.time >= AUDIO_QUEUE_LIFE:
			to_erase.append(audio)
	for x in to_erase:
		audio_queue.erase(x)
		
		
func load_queued_audio():
	
	# first, look for AudioPlayers that do not have matching queued audio, these are to be removed since they no longer happened
	# second, look for queued audios that do not have matching AudioPlayer, these are to be played since they are what actually happened
	
	var to_retain := []
	for audio_manager in $AudioPlayers.get_children():
#			print(frametime - rollback_start_frametime)
		if audio_manager.time <= frametime - rollback_start_frametime - 1:
			for queued_audio in audio_queue: # found a queued audio same as existing audio when rollbacking
#				print("audio_time: " + str(audio_manager.time))
#				print("queue_time: " + str(queued_audio.time))
				if audio_manager.audio_ref == queued_audio.audio_ref and audio_manager.time == queued_audio.time:
					to_retain.append(audio_manager)
					audio_manager.confirmed = true
					break
		else:
			audio_manager.confirmed = true
				
	for audio_manager in $AudioPlayers.get_children():
		if audio_manager.time <= frametime - rollback_start_frametime - 1:
			if !audio_manager in to_retain and !audio_manager.confirmed:
				audio_manager.kill()
			
			
	var to_exclude := []
	for queued_audio in audio_queue:
		
		for audio_manager in $AudioPlayers.get_children():
			if audio_manager.audio_ref == queued_audio.audio_ref and audio_manager.time == queued_audio.time:
#				print("audio_time: " + str(audio_manager.time))
#				print("queue_time: " + str(queued_audio.time))
				to_exclude.append(queued_audio)
				break
				
	for queued_audio in audio_queue:
		if !queued_audio in to_exclude:
			var new_audio = Loader.loaded_audio_scene.instance()
			$AudioPlayers.add_child(new_audio)
			new_audio.init(queued_audio.audio_ref, queued_audio.aux_data)
			new_audio.confirmed = true
			
	audio_queue.clear()
			
		
		
		

