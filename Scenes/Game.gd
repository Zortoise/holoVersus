extends Node2D

signal saved_state
signal loaded_state
signal record_ended
signal playback_started
signal game_set
signal time_over


const CAMERA_MARGIN = 55 # camera limit distance from blast zone
const MARGIN_TO_TILT_KILLBLAST = 100
const KILLBLAST_TILT_ANGLE = PI/7
const HUD_FADE = 0.3
	
const SCREEN_SHAKE_DECAY_RATE = 0.25
var screen_shake_amount: float

const FLASHING_TIME_THRESHOLD = 10

onready var stage_ref = Globals.stage_ref
onready var P1_char_ref = Globals.P1_char_ref
onready var P1_palette = Globals.P1_palette
onready var P1_input_style = Globals.P1_input_style
onready var P2_char_ref = Globals.P2_char_ref
onready var P2_palette = Globals.P2_palette
onready var P2_input_style = Globals.P2_input_style
onready var starting_stock_pts = Globals.starting_stock_pts

# variables for stage box and starting positions/facings, these are set by the stage's node
var stage
var stage_box
var respawn_points = []
var middle_point
var P1_position: Vector2
var P1_facing: int
var P2_position: Vector2
var P2_facing: int

var HUD
var frame_viewer

onready var match_input_log = Globals.match_input_log
var true_frametime := 0 # to set target to stimulate to
var playback_mode := false
var record_end_time := 0 # set end of playback, when loading set true_frame_time to it while clearing all
							# inputs pass record_end_time within match_input_log

var test_state # save state for testing
#onready var debugger = load("res://Scenes/Debugger.gd").new() # for checking input stuff, very useful


# GameState, these are to be saved
var frametime := 0
var matchtime
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

var input_lock := true # lock inputs at start of game,  caused issue when save/loaded,
var game_set := false # caused issue when save/loaded, need more testing

var play_speed := 1 # testing

var orig_rng_seed: int	# saved in replay file, starting rng_seed, host must send this over to client

var you_label # node


func _ready():
	
# SETUP STAGE, CAMERA, RNG SEED --------------------------------------------------------------------------------------------------
	
	Globals.Game = self
	Globals.pausing = false
	Globals.zoom_level = 1.0
	Globals.winner = []
	Globals.debug_mode = false
	Globals.match_input_log.reset()
	
	if Netplay.is_netplay():
		var NetgameSetup = load("res://Scenes/NetgameSetup.tscn").instance()
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
	var test_stage = $Stage.get_child(0) # test stage node should be directly under this node
	test_stage.free()

	stage = load("res://Stages/" + stage_ref + "/" + stage_ref + ".tscn").instance()
	$Stage.add_child(stage)
	stage.init()

	set_camera_limit()
	$CameraRef.position = Vector2.ZERO
	
	HUD = get_node("../../../HUD")
	frame_viewer = get_node("../../../HUD/FrameViewer")
	
	if Globals.time_limit == 0: # no time limit
		HUD.get_node("MatchTime").hide()
		HUD.get_node("TimeFrame").hide()
	
# ADD PLAYERS --------------------------------------------------------------------------------------------------
	
	# add players, players added later overlap players added eariler
	var P2_character
#	if P2_input_style == 0:
	P2_character = load("res://Characters/" + P2_char_ref + "/" + P2_char_ref + ".tscn").instance()
#	else:
#		P2_character = load("res://Characters/" + P2_char_ref + "/" + P2_char_ref + "C.tscn").instance()
	var P2 = Globals.loaded_character_scene.instance() # main character node, not unique character node
	$Players.add_child(P2)
	P2.init(1, P2_character, P2_position, P2_facing, P2_palette)
	frame_viewer.P2_node = P2
	
	var P1_character
#	if P1_input_style == 0:
	P1_character = load("res://Characters/" + P1_char_ref + "/" + P1_char_ref + ".tscn").instance()
#	else:
#		P1_character = load("res://Characters/" + P1_char_ref + "/" + P1_char_ref + "C.tscn").instance()
	var P1 = Globals.loaded_character_scene.instance()
	$Players.add_child(P1)
	P1.init(0, P1_character, P1_position, P1_facing, P1_palette)
	frame_viewer.P1_node = P1
	
	if Netplay.is_netplay():
		you_label = load("res://Scenes/YouLabel.tscn").instance()
		get_player_node(Netplay.my_player_id()).add_child(you_label)
		
	P1.test = true # testing purposes

# --------------------------------------------------------------------------------------------------

func set_camera_limit():
	$CameraRef/Camera2D.limit_left = stage_box.rect_global_position.x + CAMERA_MARGIN
	$CameraRef/Camera2D.limit_right = stage_box.rect_global_position.x + stage_box.rect_size.x - CAMERA_MARGIN
	$CameraRef/Camera2D.limit_top = stage_box.rect_global_position.y + CAMERA_MARGIN
	$CameraRef/Camera2D.limit_bottom = stage_box.rect_global_position.y + stage_box.rect_size.y - CAMERA_MARGIN

# MAIN LOOP (TESTING STUFF) --------------------------------------------------------------------------------------------------

func debug():
	if Input.is_action_just_pressed("speed_up"):
		play_speed += 1
	if Input.is_action_just_pressed("speed_down") and play_speed > 0:
		play_speed -= 1
			
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
				load_state(test_state)
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
			true_frametime = record_end_time
			match_input_log.set_end_frametime(record_end_time)
			emit_signal("playback_started") # to tell text to show message
		else:
			print("Error: Saved game state not found")

	if Input.is_action_just_pressed("frame_advance"):
		if Globals.watching_replay:
			stimulate(false)
		elif playback_mode == false:
			stimulate()
		else:
			stimulate(false)
			
#	if Input.is_action_just_pressed("frame_reverse"): # reverse 1 frame by loading save state of previous frame, can do up to certain times
#		if playback_mode == false:
#			if frametime - 1 in $NetgameSetup.saved_game_states:
#				load_state($NetgameSetup.saved_game_states[frametime - 1])
#				true_frametime = frametime
#				match_input_log.set_end_frametime(frametime)
			
			
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
		frame_viewer.show()
	else:
		$PolygonDrawer.hide()
		frame_viewer.hide()
			
	if Globals.watching_replay:
		if $ReplayControl.show_hitbox:
			$PolygonDrawer.show()
		else:
			$PolygonDrawer.hide()
			
#	ROLLBACK TESTER
#	if Netplay.is_netplay():
#		var random_frames = Globals.random.randi_range(1, 5)
#		if playback_mode == false:
#			if posmod(frametime, Globals.random.randi_range(1, 10)) == 0:
#				if frametime - random_frames in $NetgameSetup.saved_game_states:
#					load_state($NetgameSetup.saved_game_states[frametime - random_frames])
#					playback_mode = true
#					while playback_mode:
#						stimulate(false)


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
				while playback_mode:
					stimulate(false)
					rollback_frames += 1
				Netcode.rollback_starttime = null # rollback completed
				Fps.set_rolled_back_frames(rollback_frames) # display latest frames rolled back
			elif !input_lock:
				# desync freeze protection is suppose to prevent this, stops the game if this occurs
#				get_node("../../..").rollback_over_limit()
				Netcode.rollback_starttime = null
				Netcode.lag_freezer()


# STIMULATE FRAME --------------------------------------------------------------------------------------------------

	if Globals.watching_replay:
		$ReplayControl.replay_control()
		if !$ReplayControl.freeze_frame:
			for x in play_speed:
				stimulate(false)
		set_input_indicator()

	elif !Netplay.is_netplay():
		for x in play_speed:
			if playback_mode == false:
				stimulate()
			else:
				stimulate(false)
	else: # netplay
		if !Netcode.lag_freeze:
			if Netcode.time_diff < 0:
				stimulate()
				if posmod(frametime, 10) == 0:
					stimulate()
					Netcode.time_diff += 1
			else:
				stimulate()

# SCREEN SHAKE --------------------------------------------------------------------------------------------------

	if screen_shake_amount > 0.0:
		screen_shake_amount = max(screen_shake_amount - SCREEN_SHAKE_DECAY_RATE, 0)
		screenshake()
		if screen_shake_amount <= 0.0:
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
			
		if matchtime_floor == 0 and !game_set:
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
			Globals.winner = [winner_ID, get_player_node(winner_ID).UniqueCharacter.NAME]
					

func _process(delta):

# MOVE CAMERA --------------------------------------------------------------------------------------------------
	# camera management outside of stimulation, no need to stimulate camera
	
	var players_position := Vector2.ZERO
	

	for player in $Players.get_children():
		players_position += player.position # add together to find midpoint
			
	var point_btw_char = players_position / $Players.get_child_count() # get midpoint
	point_btw_char.y -= get_viewport_rect().size.y / 10.0 # lower it by a little
	$CameraRef.position = point_btw_char
	
	
	handle_zoom(delta) # complex stuff to determine zoom level
	HUD_fade() # fade out UI elements if a player goes behind them, WIP
	

	
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
			
	
# STIMULATE LOOP --------------------------------------------------------------------------------------------------
	
# stimulate a physics tick, do this function multiple times a frame to stimulate without rendering
func stimulate(rendering = true):
	# if rendering is false, will load inputs from match_input_log instead of capturing new ones
	
	$PolygonDrawer.extra_boxes = [] # clear the extra boxes

	if Netplay.is_netplay(): # must save state even when not rendering or overwrite incorrect states!
		$NetgameSetup.auto_savestate() # save first before processing inputs, so that when loading will start processing input on same frame
	elif Globals.watching_replay:
		$ReplayControl.replay_auto_savestate()
	
	if rendering: # not loading inputs for log, capture new ones
		if !Globals.Game.input_lock: # no inputs when input lock is on
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
	
# STIMULATE CHILDREN NODES --------------------------------------------------------------------------------------------------


	# activate player's physics
	for player in $Players.get_children():
		player.stimulate(player_input_state)

	for NPE in $NonPlayerEntitiesBack.get_children():
		if NPE.free:
			NPE.free()
		else:
			NPE.stimulate()
		
	for NPE in $NonPlayerEntitiesFront.get_children():
		if NPE.free:
			NPE.free()
		else:
			NPE.stimulate()

	detect_hit()
	
	# activate player's stimulate_after()
	for player in $Players.get_children():
		player.stimulate_after()
		
	for NPE in $NonPlayerEntitiesBack.get_children():
		NPE.stimulate_after()
		
	for NPE in $NonPlayerEntitiesFront.get_children():
		NPE.stimulate_after()


	for shadow in $ShadowTrail.get_children():
		if shadow.free: # Physics Tick version of queue_free()
			shadow.free()
		else:
			shadow.stimulate()
		
	for SFX in $SFXFront.get_children():
		if SFX.free:
			SFX.free()
		else:
			SFX.stimulate()
			
	for SFX in $SFXBack.get_children():
		if SFX.free:
			SFX.free()
		else:
			SFX.stimulate()
			
	for audio in $AudioPlayers.get_children():
		if audio.free:
			audio.free()
		else:
			audio.stimulate()
			
	if Globals.static_stage == 0:
		stage.stimulate()
			
	frame_viewer.stimulate()

# --------------------------------------------------------------------------------------------------

	frametime += 1 # advance frametime at end of each physics tick
	if playback_mode == false:
		true_frametime += 1 # true_frametime marks the "present" will not advance during playback mode
	elif frametime >= true_frametime: # reached back to present
		playback_mode = false # stop playback
		
	if !input_lock:
		matchtime -= 1 # match time only start counting down when "BEGIN!" vanishes
	
	
# SAVING/LOADING GAME STATE --------------------------------------------------------------------------------------------------
	
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
		"player_data" : {},
		"shadow_data" : [],
		"NPE_back_data" : [],
		"NPE_front_data" : [],
		"SFX_back_data" : [],
		"SFX_front_data" : [],
		"audio_data" : [],
		"stage_data" : {}
	}
	
	game_state.match_data.frametime = frametime
	game_state.match_data.matchtime = matchtime
	game_state.match_data.player_input_state = player_input_state
	game_state.match_data.captured_input_state = captured_input_state
	game_state.match_data.input_lock = input_lock
	game_state.current_rng_seed = current_rng_seed
#	game_state.match_data.game_set = game_set
	

	for player in $Players.get_children():
		game_state.player_data[player.player_ID] = player.save_state()

	for shadow in $ShadowTrail.get_children():
		game_state.shadow_data.append(shadow.save_state())
		
	for NPE in $NonPlayerEntitiesBack.get_children():
		game_state.NPE_back_data.append(NPE.save_state())
		
	for NPE in $NonPlayerEntitiesFront.get_children():
		game_state.NPE_front_data.append(NPE.save_state())
		
	for SFX in $SFXFront.get_children():
		game_state.SFX_front_data.append(SFX.save_state())
		
	for SFX in $SFXBack.get_children():
		game_state.SFX_back_data.append(SFX.save_state())

	for AudioManager in $AudioPlayers.get_children():
		game_state.audio_data.append(AudioManager.save_state())

	if Globals.static_stage == 0:
		game_state.stage_data = stage.save_state()

#	ResourceSaver.save("res://Scenes/SavedData/GameState.tres", game_state)
	if timestamp is int:
		if Netplay.is_netplay():
			$NetgameSetup.saved_game_states[timestamp] = game_state.duplicate(true)
		elif Globals.watching_replay:
			$ReplayControl.replay_saved_game_states[timestamp] = game_state.duplicate(true)
	else:
		if !Globals.watching_replay:
			test_state = game_state.duplicate(true)
		else:
			$ReplayControl.test_state = game_state.duplicate(true)


func load_state(game_state):
	
	var loaded_game_state = game_state.duplicate(true)

	frametime = loaded_game_state.match_data.frametime
	matchtime = loaded_game_state.match_data.matchtime
	player_input_state = loaded_game_state.match_data.player_input_state
	captured_input_state = loaded_game_state.match_data.captured_input_state
	input_lock = loaded_game_state.match_data.input_lock
	current_rng_seed = loaded_game_state.current_rng_seed
#	game_set = loaded_game_state.game_state.match_data.game_set

	for player in $Players.get_children():
		player.load_state(loaded_game_state.player_data[player.player_ID])
	
	# remove children
	for shadow in $ShadowTrail.get_children():
		shadow.free()
	for NPE in $NonPlayerEntitiesBack.get_children():
		NPE.free()
	for NPE in $NonPlayerEntitiesFront.get_children():
		NPE.free()
	for SFX in $SFXFront.get_children():
		SFX.free()
	for SFX in $SFXBack.get_children():
		SFX.free()
	for AudioManager in $AudioPlayers.get_children():
		AudioManager.kill()
		
	# re-add children
	for state_data in loaded_game_state.shadow_data:
		var new_shadow = Globals.loaded_shadow_scene.instance()
		$ShadowTrail.add_child(new_shadow)
		new_shadow.load_state(state_data)

	for state_data in loaded_game_state.NPE_back_data:
		var new_projectile = Globals.loaded_proj_scene.instance()
		$NonPlayerEntitiesBack.add_child(new_projectile)
		new_projectile.load_state(state_data)
		
	for state_data in loaded_game_state.NPE_front_data:
		var new_projectile = Globals.loaded_proj_scene.instance()
		$NonPlayerEntitiesFront.add_child(new_projectile)
		new_projectile.load_state(state_data)
		
	for state_data in loaded_game_state.SFX_front_data:
		var new_SFX = Globals.loaded_SFX_scene.instance()
		$SFXFront.add_child(new_SFX)
		new_SFX.load_state(state_data)
		
	for state_data in loaded_game_state.SFX_back_data:
		var new_SFX = Globals.loaded_SFX_scene.instance()
		$SFXBack.add_child(new_SFX)
		new_SFX.load_state(state_data)
	
	for state_data in loaded_game_state.audio_data:
		var new_audio = Globals.loaded_audio_scene.instance()
		$AudioPlayers.add_child(new_audio)
		new_audio.load_state(state_data)
		
	if Globals.static_stage == 0:
		stage.load_state(loaded_game_state.stage_data)
	
	
# DETECT RINGOUT --------------------------------------------------------------------------------------------------	
# called by Physics.gd

func detect_kill(character_box):
# warning-ignore:unassigned_variable
	var target_box: Rect2
	target_box.position = character_box.rect_global_position
	target_box.size = character_box.rect_size
	if !stage_box.get_rect().intersects(target_box):
		# if collision box is outside stage_box, kill them
		character_box.get_parent().on_kill()
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
		set_screenshake(12)
			
	elif body_position.y <= ceil_lvl:
		out_angle = PI
		if body_position.x <= left_wall_lvl + MARGIN_TO_TILT_KILLBLAST:
			out_angle += KILLBLAST_TILT_ANGLE
		elif body_position.x >= right_wall_lvl - MARGIN_TO_TILT_KILLBLAST:
			out_angle -= KILLBLAST_TILT_ANGLE
		set_screenshake(12)
			
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
	
	var hitboxes = [] # array of dictionaries
	var hurtboxes = []
#	var SD_hurtboxes = []
	
	for player in $Players.get_children():
		var polygons_queried = player.query_polygons()
		# will not return hitbox if in hitstop or when HarmlessTimer is running or if hits_left_in_current_active = 0
		
		if polygons_queried.hitbox: # if hitbox is not empty
			var converted_polygon = []
			for point in polygons_queried.hitbox: # convert to global position
				converted_polygon.append(player.position + point)
			var move_data_and_name = player.query_move_data_and_name()
			var hitbox = {
				"polygon" : converted_polygon,
				"owner_nodepath" : player.get_path(),
				"facing": player.facing,
				"kborigin" : null,
				"move_name" : move_data_and_name.move_name,
				"move_data" : move_data_and_name.move_data, # damage, attack level, etc
			}
			if polygons_queried.sweetbox: # if sweetbox is not empty
				var converted_polygon2 = []
				for point in polygons_queried.sweetbox: # convert to global position
					converted_polygon2.append(player.position + point)
				hitbox["sweetbox"] = converted_polygon2
			if polygons_queried.kborigin: # if kborigin is not null
				hitbox["kborigin"] = player.position + polygons_queried.kborigin
				
			hitboxes.append(hitbox)
			
		if polygons_queried.hurtbox:
			var converted_polygon = []
			for point in polygons_queried.hurtbox: # convert to global position
				converted_polygon.append(player.position + point)
			var hurtbox = {
				"polygon" : converted_polygon,
				"owner_nodepath" : player.get_path(),
				"facing": player.facing,
#				"defensive_state" : null, # blocking, punishable state, etc
			}
			if polygons_queried.sdhurtbox:
				var converted_polygon2 = []
				for point in polygons_queried.sdhurtbox: # convert to global position
					converted_polygon2.append(player.position + point)
				hurtbox["sdhurtbox"] = converted_polygon2
			
			hurtboxes.append(hurtbox)
			
	# for projectiles
	var entities = $NonPlayerEntitiesBack.get_children()
	entities.append_array($NonPlayerEntitiesFront.get_children())
	
	for entity in entities:
		var polygons_queried = entity.query_polygons()
		if polygons_queried.hitbox != null: # if hitbox is not empty
			var converted_polygon = []
			for point in polygons_queried.hitbox: # convert to global position
				converted_polygon.append(entity.position + point)
			var move_data = entity.query_move_data()
			var hitbox = {
				"polygon" : converted_polygon,
				"owner_nodepath" : get_player_node(entity.owner_ID).get_path(),
				"entity_nodepath" : entity.get_path(),
				"facing": entity.facing,
				"kborigin" : null,
				"move_name" : move_data.move_name,
				"move_data" : move_data, # damage, attack level, etc
			}
			if polygons_queried.sweetbox != null: # if sweetbox is not empty
				var converted_polygon2 = []
				for point in polygons_queried.sweetbox: # convert to global position
					converted_polygon2.append(entity.position + point)
				hitbox["sweetbox"] = converted_polygon2
			if polygons_queried.kborigin != null: # if kborigin is not null
				hitbox["kborigin"] = entity.position + polygons_queried.kborigin
				
			hitboxes.append(hitbox)
	
	$PolygonDrawer.activate(hitboxes, hurtboxes) # draw the polygons, only visible during training/debugging
	
	# ACTUAL HIT DETECTION --------------------------------------------------------------------------------------------------
	
	var hit_data_array = []
	
	for hitbox in hitboxes:
			
		for hurtbox in hurtboxes:
			if hitbox.owner_nodepath == hurtbox.owner_nodepath:
				continue # defender must not be owner of hitbox
			if defender_semi_invul(hitbox, hurtbox):
				continue # attacker must not be attacking a semi-invul defender unless with certain moves
			if !"entity_nodepath" in hitbox:
				if !test_priority(hitbox, hurtbox):
					continue # attacker must pass the priority test
				if defender_anti_airing(hitbox, hurtbox):
					continue # attacker must not be using an aerial against an anti-airing defender
				if defender_backdash(hitbox, hurtbox):
					continue # defender must not be backdashing away from attacker's UNBLOCKABLE/ANTI_GUARD attack
				if get_node(hitbox.owner_nodepath).is_hitcount_maxed(get_node(hurtbox.owner_nodepath).player_ID, hitbox.move_data):
					continue # attacker must still have hitcount left
				if get_node(hitbox.owner_nodepath).is_player_in_ignore_list(get_node(hurtbox.owner_nodepath).player_ID):
					continue # defender must not be in attacker's ignore list
			else: # for projectiles
				if get_node(hitbox.entity_nodepath).is_hitcount_maxed(get_node(hurtbox.owner_nodepath).player_ID, hitbox.move_data):
					continue # projectile must still have hitcount left
				if get_node(hitbox.entity_nodepath).is_player_in_ignore_list(get_node(hurtbox.owner_nodepath).player_ID):
					continue # defender must not be in projectile's ignore list
						
			# get an array of PoolVector2Arrays of the intersecting polygons
			var intersect_polygons = Geometry.intersect_polygons_2d(hitbox.polygon, hurtbox.polygon)
			if intersect_polygons.size() > 0: # detected a hit
				
				create_hit_data(hit_data_array, intersect_polygons, hitbox, hurtbox)
				
			elif "sdhurtbox" in hurtbox: # detecting a semi-disjoint hit
				var intersect_polygons_sd = Geometry.intersect_polygons_2d(hitbox.polygon, hurtbox.sdhurtbox)
				if intersect_polygons_sd.size() > 0:
					
					create_hit_data(hit_data_array, intersect_polygons_sd, hitbox, hurtbox, true)
						
	for hit_data in hit_data_array:
		# call being_hit() on the defender and landed_a_hit() on the attacker/projectile
		get_node(hit_data.defender_nodepath).being_hit(hit_data) # will add stuff to hit_data, passing by reference
		if !"entity_nodepath" in hit_data:
			get_node(hit_data.attacker_nodepath).landed_a_hit(hit_data)
			$Players.move_child(get_node(hit_data.attacker_nodepath), 0) # move attacker to bottom layer to see defender easier
		else:
			get_node(hit_data.entity_nodepath).landed_a_hit(hit_data)
		
						
func create_hit_data(hit_data_array, intersect_polygons, hitbox, hurtbox, semi_disjoint = false):
	
	# calculate hit_center (used for emitting hitspark and sweetspotting)
	var sum := Vector2.ZERO
	var number_of_points := 0.0
	for intersect_polygon in intersect_polygons:
		for point in intersect_polygon:
			sum += point
			number_of_points += 1.0
	var hit_center: Vector2
	hit_center = sum / number_of_points
	hit_center.x = round(hit_center.x) # remove decimals
	hit_center.y = round(hit_center.y) # remove decimals
	
	
	var sweetspotted := false
	if semi_disjoint == false and "sweetbox" in hitbox and Geometry.is_point_in_polygon(hit_center, hitbox.sweetbox):
		sweetspotted = true # cannot sweetspot on SD hits
	
	var hit_data = { # send this to both attacker and defender
		"attacker_nodepath" : hitbox.owner_nodepath,
		"defender_nodepath" : hurtbox.owner_nodepath,
		"hit_center" : hit_center,
		"semi_disjoint": semi_disjoint,
		"sweetspotted" : sweetspotted,
		"kborigin": hitbox.kborigin,
		"attack_facing" : hitbox.facing,
		"defend_facing" : hurtbox.facing,
		"move_name" : hitbox.move_name,
		"move_data" : hitbox.move_data,
#		"defensive_state": hurtbox.defensive_state,
	}
	
	if "entity_nodepath" in hitbox: # flag hit as a projectile
		hit_data["entity_nodepath"] = hitbox.entity_nodepath
	
	hit_data_array.append(hit_data)
	
	

## 1st frame of attack is immune to attacks of equal or lower priority
#func test_priority(hitbox, hurtbox): # return false if attacker fail the priority check, will not process the hit if so
#	var defender = get_node(hurtbox.owner_nodepath)
#	if defender.is_atk_active() and defender.Animator.time == 0:
#		if hitbox.move_data.priority <= defender.query_move_data_and_name().move_data.priority:
#			return false
#	return true
	
func test_priority(hitbox, hurtbox): # return false if attacker fail the priority check, will not process the hit if so
	var attacker = get_node(hitbox.owner_nodepath)
	var defender = get_node(hurtbox.owner_nodepath)
	if defender.is_atk_active():
		# Rule 1: you cannot hit an opponent on the 1st frame of THEIR active frame
		# you are invincible on the 1st frame of your active frame!
		# this allow at least the 1st frame of the attack to be shown during clashes
		if defender.Animator.time == 0:
			return false
		# Rule 2: you cannot hit an opponent using a move of higher priority on the 1st 2 frames of YOUR active frame
		# this allow higher priority attack to beat lower priority ones after the frame 1 invincibility of Rule 1
		# sweetspots should at least be 3 frames long (50ms)
		elif attacker.Animator.time <= 1:
			if hitbox.move_data.priority < defender.query_move_data_and_name().move_data.priority:
				return false
	return true
	
## SDHurtbox during active frame cannot be hit by attacks of lower priority
#func test_sd_priority(hitbox, hurtbox): # return false if attacker fail the priority check, will not process the hit if so
#	var defender = get_node(hurtbox.owner_nodepath)
#	if defender.is_atk_active() and hitbox.move_data.priority < defender.query_move_data_and_name().move_data.priority:
#		return false
#	return true
	
	
func defender_anti_airing(hitbox, hurtbox):
	var attacker = get_node(hitbox.owner_nodepath)
	var defender = get_node(hurtbox.owner_nodepath)
	
	if defender.state == Globals.char_state.GROUND_ATK_STARTUP or defender.state == Globals.char_state.GROUND_ATK_ACTIVE or \
			defender.state == Globals.char_state.AIR_ATK_ACTIVE: # for airborne defender using anti-air, only anti-air during active frames
		
		var has_anti_air_attr = Globals.atk_attr.ANTI_AIR in defender.query_atk_attr()
		if has_anti_air_attr and Globals.atk_attr.AIR_ATTACK in attacker.UniqueCharacter.query_atk_attr(hitbox.move_name):
			# don't use hitbox.move_data.atk_attr, some attacks have special conditions added in UniqueCharacter.query_atk_attr()
			# for defender to successfully anti-air, they must be attacking, must be using an ANTI-AIR move, 
			# and the attacker must be using an AIR_ATTACK in air or on ground
			# now to check tiers
			var defender_tier = Globals.atk_type.HEAVY # for normal AIR_ATTACK attribute, can defend against all aerials HEAVY or below
			var attacker_tier = Globals.atk_type_to_tier(hitbox.move_data.atk_type)
			if defender_tier >= attacker_tier:
				return true # defender successfully anti-aired
	return false
	
func defender_semi_invul(hitbox, hurtbox):
	var attacker = get_node(hitbox.owner_nodepath)
	var defender = get_node(hurtbox.owner_nodepath)
	if defender.state == Globals.char_state.GROUND_ATK_STARTUP or defender.state == Globals.char_state.AIR_ATK_STARTUP:
		if Globals.atk_attr.SEMI_INVUL_STARTUP in defender.query_atk_attr():
			if Globals.atk_attr.UNBLOCKABLE in attacker.UniqueCharacter.query_atk_attr(hitbox.move_name) or \
					hitbox.move_data.atk_type == Globals.atk_type.EX or hitbox.move_data.atk_type == Globals.atk_type.SUPER:
				return false # defender's semi-invul failed
			else:
				return true # defender's semi-invul succeeded
	return false
	
func defender_backdash(hitbox, hurtbox):
	var attacker = get_node(hitbox.owner_nodepath)
	var defender = get_node(hurtbox.owner_nodepath)
	var attacker_attr = attacker.UniqueCharacter.query_atk_attr(hitbox.move_name)
	if Globals.atk_attr.UNBLOCKABLE in attacker_attr or Globals.atk_attr.ANTI_GUARD in attacker_attr:
		if defender.new_state in [Globals.char_state.GROUND_RECOVERY, Globals.char_state.AIR_RECOVERY] or \
				defender.Animator.query_to_play(["DashTransit", "AirDashTransit"]):
			if defender.facing == sign(defender.position.x - attacker.position.x) and \
					!defender.Animator.query_to_play(["AirDashUU", "AirDashDD"]):
				return true # defender's backdash succeeded
	return false # defender's backdash failed

# HANDLING ZOOM --------------------------------------------------------------------------------------------------

func handle_zoom(delta):
	# first, find the distance between the furthest player and the average positions of the players
	# find for both vertical and horizontal
	var array_of_horizontal_diff = []
	var array_of_vertical_diff = []
	
	for player in $Players.get_children():
		array_of_horizontal_diff.append(abs(player.position.x - $CameraRef.position.x))
		array_of_vertical_diff.append(abs(player.position.y - $CameraRef.position.y))
	
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
			change_in_zoom -= Globals.CAMERA_ZOOM_SPEED * delta * abs(area_diff - 2000)
			# slow down zoom speed when reaching camera limits
			if get_viewport_rect().size.x + 200 > $CameraRef/Camera2D.limit_right - $CameraRef/Camera2D.limit_left or \
					get_viewport_rect().size.y + 200  > $CameraRef/Camera2D.limit_bottom - $CameraRef/Camera2D.limit_top:
				change_in_zoom *= 0.5
	elif area_diff < -2000: # players too near (smallest rectangle smaller than target area), zoom in
		change_in_zoom += Globals.CAMERA_ZOOM_SPEED * delta * abs(area_diff + 2000) * 0.5
		
	# when zoomed out, reduce zoom speed, when zoomed in, increase zoom speed
	if Globals.zoom_level < 1.0:
		change_in_zoom *= 0.5
	elif Globals.zoom_level > 1.0:
		change_in_zoom *= Globals.zoom_level * 1.5
	
	Globals.change_zoom_level(change_in_zoom)
	
# SCREEN SHAKE --------------------------------------------------------------------------------------------------
	
func screenshake():
	$CameraRef/Camera2D.offset_h = screen_shake_amount * rand_range(-0.1, 0.1)
	$CameraRef/Camera2D.offset_v = screen_shake_amount * rand_range(-0.75, 0.75)
	
	$CameraRef/Camera2D.limit_left = stage_box.rect_global_position.x + CAMERA_MARGIN - $CameraRef/Camera2D.offset_h
	$CameraRef/Camera2D.limit_right = stage_box.rect_global_position.x + stage_box.rect_size.x - CAMERA_MARGIN + \
			$CameraRef/Camera2D.offset_h
	$CameraRef/Camera2D.limit_top = stage_box.rect_global_position.y + CAMERA_MARGIN - $CameraRef/Camera2D.offset_v
	$CameraRef/Camera2D.limit_bottom = stage_box.rect_global_position.y + stage_box.rect_size.y - CAMERA_MARGIN + \
			$CameraRef/Camera2D.offset_v
	
func set_screenshake(amount = 5):
	screen_shake_amount = amount
	
# HUD ELEMENTS  --------------------------------------------------------------------------------------------------

func set_input_indicator():
	for player in $Players.get_children():
		var indicator = HUD.get_node("P" + str(player.player_ID + 1) + "_HUDRect/Inputs")
		if !$ReplayControl.input_indicators:
			indicator.hide()
		else:
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
				

func damage_update(character, damage = 0):
	var dmg_val_indicator = HUD.get_node("P" + str(character.player_ID + 1) + "_HUDRect/Portrait/DamageValue")
	dmg_val_indicator.text = str(character.current_damage_value)
	
	# change color
	var dmg_percent = character.get_damage_percent()
	if dmg_percent < 0.25:
		dmg_val_indicator.get_node("AnimationPlayer2").stop()
		dmg_val_indicator.modulate = Color(1.0, 1.0, 1.0)
	elif dmg_percent >= 0.25 and dmg_percent < 0.50:
		dmg_val_indicator.get_node("AnimationPlayer2").stop()
		dmg_val_indicator.modulate = Color(1.0, 1.0, 0.5)
	elif dmg_percent >= 0.50 and dmg_percent < 0.75:
		dmg_val_indicator.get_node("AnimationPlayer2").stop()
		dmg_val_indicator.modulate = Color(1.0, 0.5, 0.2)
	elif dmg_percent >= 0.75 and dmg_percent < 1.0:
		dmg_val_indicator.get_node("AnimationPlayer2").stop()
		dmg_val_indicator.modulate = Color(1.0, 0.0, 0.0)
	elif dmg_percent >= 1.0:
		dmg_val_indicator.get_node("AnimationPlayer2").play("flashing")
		
	if damage > 0:
		dmg_val_indicator.get_node("AnimationPlayer").stop() # this will restart the animation if it is playing it
		dmg_val_indicator.get_node("AnimationPlayer").play("damage") # shake label
		
				
func guard_gauge_update(character):
	
	var gg_indicator1 = HUD.get_node("P" + str(character.player_ID + 1) + "_HUDRect/GaugesUnder/GuardGauge1")
	var gg_indicator2 = HUD.get_node("P" + str(character.player_ID + 1) + "_HUDRect/GaugesUnder/GuardGauge2")
	
	var guard_gauge_percent
	if character.current_guard_gauge <= 0:
		guard_gauge_percent = character.get_guard_gauge_percent_below()
		gg_indicator1.value = guard_gauge_percent * 100
		gg_indicator2.value = 0
	else:
		guard_gauge_percent = character.get_guard_gauge_percent_above()
		gg_indicator1.value = 100
		gg_indicator2.value = guard_gauge_percent * 100
		
	
func ex_gauge_update(character):
	
	var ex_gauge_bar = HUD.get_node("P" + str(character.player_ID + 1) + "_HUDRect/GaugesUnder/EXGauge")
	var ex_lvl_indicator = HUD.get_node("P" + str(character.player_ID + 1) + "_HUDRect/GaugesUnder/EXLevel")

	var current_ex_level = int(floor(character.current_ex_gauge / 10000.0))
	var leftover_ex_gauge
	if current_ex_level >= 5:
		leftover_ex_gauge = 100
	else:
		leftover_ex_gauge = (character.current_ex_gauge - (current_ex_level * 10000.0)) / 100.0
	
	ex_gauge_bar.value = leftover_ex_gauge
	ex_lvl_indicator.text = str(current_ex_level)
	
	# change color
	match current_ex_level:
		0:
			ex_gauge_bar.get_node("AnimationPlayer").stop()
			ex_gauge_bar.modulate = Color(1.0, 1.0, 1.0)
			ex_lvl_indicator.get_node("AnimationPlayer").stop()
			ex_lvl_indicator.modulate = Color(0.5, 0.5, 0.5)
		1, 2:
			ex_gauge_bar.get_node("AnimationPlayer").stop()
			ex_gauge_bar.modulate = Color(1.0, 1.0, 1.0)
			ex_lvl_indicator.get_node("AnimationPlayer").play("flash1")
		3, 4:
			ex_gauge_bar.get_node("AnimationPlayer").stop()
			ex_gauge_bar.modulate = Color(1.0, 1.0, 1.0)
			ex_lvl_indicator.get_node("AnimationPlayer").play("flash2")
		5:
			ex_lvl_indicator.get_node("AnimationPlayer").play("rainbow")
			ex_gauge_bar.get_node("AnimationPlayer").play("rainbow")
	
	
func stock_points_update(character, stock_points_change = 0):
	var stock_indicator = HUD.get_node("P" + str(character.player_ID + 1) + "_HUDRect/Portrait/StockPoints")
	stock_indicator.text = str(character.stock_points_left)
	
	if stock_points_change < 0:
		var stock_loss_indicator = HUD.get_node("P" + str(character.player_ID + 1) + "_HUDRect/Portrait/StockPoints/StockLoss")
		stock_loss_indicator.text = str(stock_points_change)
		stock_loss_indicator.get_node("AnimationPlayer").play("stock_loss")
	
	if character.stock_points_left <= 0 and !game_set:
		game_set = true
		emit_signal("game_set")
		
		match character.player_ID:
			0:
				Globals.winner = [1, get_player_node(1).UniqueCharacter.NAME]
			1:
				Globals.winner = [0, get_player_node(0).UniqueCharacter.NAME]
				
func burst_update(character):
	var burst_token = HUD.get_node("P" + str(character.player_ID + 1) + "_HUDRect/Portrait/BurstToken")
	if character.has_burst:
		burst_token.show()
	else:
		burst_token.hide()
				
				
func get_player_node(player_ID):
	for player in $Players.get_children():
		if player.player_ID == player_ID:
			return player

# fade out HUD elements if there is a player behind them
func HUD_fade():
	#  adjust zoom for top and bottom detect boxes,
	$TopHUDBoxP1.rect_size.x = get_viewport_rect().size.x / 6.0
	$TopHUDBoxP1.rect_size.y = get_viewport_rect().size.y / 8.75
	$TopHUDBoxP1.rect_position = $CameraRef/Camera2D.get_camera_screen_center()
	$TopHUDBoxP1.rect_position.x -= $TopHUDBoxP1.rect_size.x * 2.0
	$TopHUDBoxP1.rect_position.y -= $TopHUDBoxP1.rect_size.y * 4
	if Detection.detect_bool([$TopHUDBoxP1], ["Players"]):
		HUD.get_node("P1_HUDRect/Portrait").modulate.a = HUD_FADE
	else:
		HUD.get_node("P1_HUDRect/Portrait").modulate.a = 1.0

	$BottomHUDBoxP1.rect_size = get_viewport_rect().size / 6.0
	$BottomHUDBoxP1.rect_size.y = get_viewport_rect().size.y / 8.75
	$BottomHUDBoxP1.rect_position = $CameraRef/Camera2D.get_camera_screen_center()
	$BottomHUDBoxP1.rect_position.x -= $BottomHUDBoxP1.rect_size.x * 2.0
	$BottomHUDBoxP1.rect_position.y += $BottomHUDBoxP1.rect_size.y * 3	
	if Detection.detect_bool([$BottomHUDBoxP1], ["Players"]):
		HUD.get_node("P1_HUDRect/GaugesUnder").modulate.a = HUD_FADE
	else:
		HUD.get_node("P1_HUDRect/GaugesUnder").modulate.a = 1.0
	
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

func rng_generate(upper_limit: int): # will return a number from 0 to (upper_limit - 1)
	var result = current_rng_seed + posmod(frametime, 10000)
	current_rng_seed = wrapi(result, 1, 10000) # each call to generate a number changes the current seed
	return posmod(result, upper_limit)
			
# SPAWN STUFF --------------------------------------------------------------------------------------------------

# init(in_owner_ID, in_loaded_proj_ref, in_move_data: Dictionary, in_position: Vector2, aux_data: Dictionary):
func _on_Character_projectile(in_owner_ID: int, in_loaded_proj_ref, in_move_data: Dictionary, out_position, aux_data: Dictionary):
	var projectile = Globals.loaded_proj_scene.instance()
	if !"back" in aux_data:
		$NonPlayerEntitiesFront.add_child(projectile)
	else:
		$NonPlayerEntitiesBack.add_child(projectile)
	projectile.init(in_owner_ID, in_loaded_proj_ref, in_move_data, out_position, aux_data)
	

# for common sfx, loaded_sfx_ref is a string pointing to loaded sfx in LoadedSFX.gb
# for unique sfx, loaded_sfx_ref will be a NodePath leading to the sfx's loaded FrameData .tres file and loaded spritesheet
func _on_Character_SFX(anim: String, loaded_sfx_ref, out_position, aux_data: Dictionary):
	var sfx = Globals.loaded_SFX_scene.instance()
	if !"back" in aux_data:
		$SFXFront.add_child(sfx)
	else:
		$SFXBack.add_child(sfx)
	sfx.init(anim, loaded_sfx_ref, out_position, aux_data)
	
	
func _on_Character_shadow_trail(sprite_node_path, out_position, starting_modulate_a = 0.5, lifetime = 10.0):
	var shadow = Globals.loaded_shadow_scene.instance()
	$ShadowTrail.add_child(shadow)
	shadow.init(sprite_node_path, out_position, starting_modulate_a, lifetime)
	
	
# aux_data contain "vol", "bus"
func play_audio(audio_ref: String, aux_data: Dictionary):
	if audio_ref in LoadedSFX.loaded_audio: # main game node can only load common audio
		var new_audio = Globals.loaded_audio_scene.instance()
		$AudioPlayers.add_child(new_audio)
		new_audio.init(audio_ref, aux_data)

