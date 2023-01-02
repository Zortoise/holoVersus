extends Node

var input_delay := 0 # max recommended is 3 frames
var max_rollback := 5

var game_ongoing := false

var opponent_payload = null
var opponent_latest_correct_time := 0
var rollback_starttime = null # tells the game which frame to load and start stimulating
var time_diff := 0 # number of frames to speed up for, set to non-zero if behind in time

var INPUTS_PACKET_CHECKER = [[],[]] # used for checking if a toggled key belongs to player 1/2
		
var desync_escape_timer = null
const DESYNC_ERROR_TIME = 240 # if frozen for 4 secs, exit game

var positions_for_desync_check = {}
const POS_DESYNC_MAX_SIZE = 10
const POS_DESYNC_CHECK_INTERVAL = 70 # compare positions of players every 70 frames to check for desyncs

var lag_freeze := false

		
func _ready():
	self.set_pause_mode(2)
	lag_freeze = false
	
	# fill in INPUTS_PACKET_CHECKER
	for key_array in Globals.INPUTS[0].values():
		var converted_key: int = key_array[1] # get int form of the key
		INPUTS_PACKET_CHECKER[0].append(converted_key)
	for key_array in Globals.INPUTS[1].values():
		var converted_key: int = key_array[1] # get int form of the key
		INPUTS_PACKET_CHECKER[1].append(converted_key)
			
			
func _physics_process(_delta):
	if Netplay.is_netplay() and game_ongoing:
		if posmod(Globals.Game.frametime, POS_DESYNC_CHECK_INTERVAL) == 0: # every 70 frames, do a position desync check
			if positions_for_desync_check.size() > 2: # have at least 3 saved positions
				var sorted_keys = positions_for_desync_check.keys()
				sorted_keys.sort()
				var check_time = sorted_keys[round(sorted_keys.size()/2.0)] # get the middle entry of check_positions_for_desync
				rpc("check_positions_for_desync", check_time, positions_for_desync_check[check_time])
			
		if desync_escape_timer != null: # if desync frozen too long, stop game
			desync_escape_timer += 1
			if desync_escape_timer > DESYNC_ERROR_TIME:
				desync_escape_timer = null
				Globals.Game.get_node("../../..").desync_escape()
		
		
func save_positions_for_desync_check(frametime_check, positions): # called by NetgameSetup every 70 frames
	positions_for_desync_check[frametime_check] = positions.duplicate(true)
	if positions_for_desync_check.size() > POS_DESYNC_MAX_SIZE:
		positions_for_desync_check.erase(positions_for_desync_check.keys().min()) # remove oldest entry


remote func check_positions_for_desync(frametime_check, positions):
	if Netplay.is_netplay() and game_ongoing:
		if frametime_check in positions_for_desync_check:
			if positions_for_desync_check[frametime_check].hash() != positions.hash(): # position desync detected, stop game
				rpc("check_positions_failed")
		else: rpc("check_positions_failed2") # if not inside saved_states_for_desync_check, fail it anyway
	
			
remote func check_positions_failed():
	if Netplay.is_netplay() and game_ongoing:
		Globals.Game.get_node("../../..").positions_desync()
	
#	var debugger = load("res://Scenes/Debugger.gd").new()
#	debugger.save_stateA = data1
#	debugger.save_stateB = data2
#	ResourceSaver.save("res://Scenes/SavedData/DebugLog.tres", debugger)
	
remotesync func check_positions_failed2():
	if Netplay.is_netplay() and game_ongoing:
		Globals.Game.get_node("../../..").positions_desync2()
	

func desync_check(): # called every frame after processing payload
	if Netplay.is_netplay() and game_ongoing:
		if Globals.Game.match_input_log.latest_correct_time < Globals.Game.frametime + Netcode.input_delay - ceil(Netcode.max_rollback / 2.0):
			lag_freezer()


func lag_freezer():
	if !lag_freeze:
		lag_freeze = true # desync risk immediate, freeze game immediately
		desync_escape_timer = 0
		# request for special retrieve_inputs() from opponent in reliable rpc call that starts from latest_correct_time
		rpc("desync_retrieve_inputs", Globals.Game.match_input_log.latest_correct_time)
		

func retrieve_inputs(): # every frame, send the last [Netcode.max_rollback] frames of your inputs, along with the time range
	var payload = [ # no strings, minimize size of payload
		Globals.Game.frametime + input_delay, # latest time
		{}, # timestamps
		Globals.Game.match_input_log.latest_correct_time
		]

	var starting_time = max(opponent_latest_correct_time - 1, payload[0] - Netcode.max_rollback)
	# start retrieving from start of opponent's latest_correct_time

	for frame in range(starting_time, payload[0] + 1): # for each frame in the last [Netcode.max_rollback] frames
		if frame in Globals.Game.match_input_log.input_log: # check if this frametime is recorded in input log as a timestamp
			for key in Globals.Game.match_input_log.input_log[frame]: # for each key within this timestamp
				if key in INPUTS_PACKET_CHECKER[Netplay.my_player_id()]: # if this key belongs to you
					if !frame in payload[1]: # add it to the payload
						payload[1][frame] = [key]
					else:
						payload[1][frame].append(key)
						
#	print(payload)

	rpc_unreliable("receive_payload", payload) # send payload to opponent
	
	
# special version of retrieve_inputs() called, send over reliable rpc call that starts from opponent's latest_correct_time
remote func desync_retrieve_inputs(starting_time):
	var payload = [ # no strings, minimize size of payload
		[starting_time, Globals.Game.frametime + input_delay], # time range
		{} # timestamps
		]
	
	for frame in range(payload[0][0], payload[0][1] + 1):
		if frame in Globals.Game.match_input_log.input_log: # check if this frametime is recorded in input log as a timestamp
			for key in Globals.Game.match_input_log.input_log[frame]: # for each key within this timestamp
				if key in INPUTS_PACKET_CHECKER[Netplay.my_player_id()]: # if this key belongs to you
					if !frame in payload[1]: # add it to the payload
						payload[1][frame] = [key]
					else:
						payload[1][frame].append(key)
	
	rpc("desync_receive_payload", payload)
	
	if !lag_freeze: # freezes as well to let opponent catch up
		lag_freeze = true # desync risk immediate, freeze game immediately
		desync_escape_timer = 0
	
	
remote func receive_payload(in_opponent_payload): # receive payload from opponent
	if game_ongoing:
		if opponent_latest_correct_time < in_opponent_payload[2]: # update opponent_latest_correct_time
			opponent_latest_correct_time = in_opponent_payload[2]
			
		if !in_opponent_payload[0] is Array:
			# set up time range
			in_opponent_payload[0] = [in_opponent_payload[0] - Netcode.max_rollback, in_opponent_payload[0]]
		
		if opponent_payload == null:
			opponent_payload = in_opponent_payload.duplicate(true)
		else: # special case where you receive 2 payloads in 1 frame
			opponent_payload = merge_payloads(opponent_payload, in_opponent_payload)
			
			
func merge_payloads(payload_A, payload_B):
	var merged_payload = [[null, null], null] # no more need for opponent_latest_correct_time
	if payload_A[0][0] < payload_B[0][0]: # set start of time range to be the earliest one
		merged_payload[0][0] = payload_A[0][0]
	else:
		merged_payload[0][0] = payload_B[0][0]
	if payload_A[0][1] < payload_B[0][1]: # set end of time range to be the latest one
		merged_payload[0][1] = payload_B[0][1]
	else:
		merged_payload[0][1] = payload_A[0][1]
		
	merged_payload[1] = payload_A[1].duplicate(true) # merge timestamps
	for timestamp in payload_B[1].keys():
		if !timestamp in merged_payload[1]:
			merged_payload[1][timestamp] = payload_B[1][timestamp].duplicate(true)
			
	return merged_payload
			
		
remote func desync_receive_payload(in_opponent_payload): # receive payload from opponent
	if game_ongoing:
		lag_freeze = false # received correct payload, stop lag freeze
		desync_escape_timer = null
		if in_opponent_payload[0][0] <= Globals.Game.match_input_log.latest_correct_time + 1:
			opponent_payload = in_opponent_payload.duplicate(true)	
			process_payload()
	
func process_payload():

	if !opponent_payload[0] is Array:
		# set up time range, just in case
		opponent_payload[0] = [opponent_payload[0] - Netcode.max_rollback, opponent_payload[0]]

	if !lag_freeze:
		if !Globals.Game.input_lock and opponent_payload[0][0] > Globals.Game.match_input_log.latest_correct_time + 1: # gap in input!
			# desync freeze protection is suppose to prevent this, stop game if this occurs
#			Globals.Game.get_node("../../..").gap_in_input()
			opponent_payload = null
			lag_freezer()
			return
	else: # currently desync lag frozen and waiting for opponent's desync_retrieve_inputs to unfrozen in desync_receive_payload()
		if opponent_payload[0][0] <= Globals.Game.match_input_log.latest_correct_time + 1:
			lag_freeze = false # received correct payload, stop lag freeze
			desync_escape_timer = null
			pass
		else:
			opponent_payload = null
			return # payload is not good enough to unfreeze, ignore it
	
	
	for frame in range(Globals.Game.match_input_log.latest_correct_time + 1, opponent_payload[0][1] + 1):
		# go through payload frame for frame starting from latest_correct_time
		if frame in opponent_payload[1]: # new toggle input for opponent discovered
			if rollback_starttime == null:
				rollback_starttime = frame # start rollback from here
			if frame in Globals.Game.match_input_log.input_log: # if you have inputs that frame, merge yours and opponent's inputs
				Globals.Game.match_input_log.input_log[frame].append_array(opponent_payload[1][frame])
			else: # if not, add their inputs to your input log in a new timestamp
				Globals.Game.match_input_log.input_log[frame] = opponent_payload[1][frame].duplicate(true)
			
	Globals.Game.match_input_log.latest_correct_time = opponent_payload[0][1] # update latest_correct_time
	desync_check()
	
	if Netplay.ping != null:
		var opponent_time = opponent_payload[0][1] + (Netplay.ping * 0.5 * 60.0) - input_delay
		time_diff = Globals.Game.frametime - opponent_time
	# warning-ignore:narrowing_conversion
		if time_diff > 0: time_diff = floor(time_diff)
	# warning-ignore:narrowing_conversion
		else: time_diff = ceil(time_diff)
	
	opponent_payload = null
			
			
func force_game_over_to_opponent(winner_ID): # ran at start of VictoryScreenNet
	rpc("force_game_over", winner_ID)
	
remote func force_game_over(winner_ID):
	if Netplay.is_netplay() and Netcode.game_ongoing:
		Globals.Game.get_node("../../..").force_game_over(winner_ID)
	

