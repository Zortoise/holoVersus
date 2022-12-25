extends Node

var opponent_ready := false
var ready := false
var my_tapjump_and_buffer
var new_input_map = {}
var sync_time := 0.0 # for synchronizing only, internal game logic runs on Game.frametime instead

var saved_game_states: Dictionary # save it internally, a dict with timestamps of the last [Netcode.max_rollback] frames


onready var Game = get_parent()


func init():
	get_tree().paused = true
	get_node("../../../../Synchro").show()
	my_tapjump_and_buffer = change_inputs()
	Netcode.opponent_payload = null
	Netcode.opponent_latest_correct_time = 0
	Netcode.rollback_starttime = null
	Netcode.time_diff = 0
	Fps.rolled_back_frames = 0
	Netcode.game_ongoing = false # just in case
	Netcode.desync_escape_timer = null
	Netcode.positions_for_desync_check = {}
	Netcode.lag_freeze = false
	
	if get_tree().is_network_server():
		Game.orig_rng_seed = Globals.random.randi_range(1, 9999)
		Game.current_rng_seed = Game.orig_rng_seed
		Globals.orig_rng_seed = Game.orig_rng_seed
	

func _process(delta):
	if !Netcode.game_ongoing and !ready and get_tree().paused: # start running after you finish loading, stops after game starts
		sync_time += delta
		if !get_tree().is_network_server():
			rpc("opponent_setup", my_tapjump_and_buffer) # every frame tell opponent you are ready and send them my_tapjump_and_buffer
		else:
			rpc("opponent_setup", my_tapjump_and_buffer, Globals.Game.orig_rng_seed) # for host, send over rng_seed as well
		if Netplay.ping != null and sync_time >= Netplay.ping * 0.5: # if at/after cut-off time
			if opponent_ready: # start if opponent is already ready, or instantly after getting message that opponent is ready
				get_tree().paused = false # start game here
				ready = true # stop sending rpc("opponent_setup")
				Netcode.game_ongoing = true
				get_node("../../../../Synchro").hide()
				Game.setup()
		
		
remote func opponent_setup(opponent_tapjump_and_buffer, host_orig_rng_seed = null): # rpc-ed by opponent when they finish loading
	if !opponent_ready:
		opponent_ready = true
		combine_inputs(opponent_tapjump_and_buffer)
		if host_orig_rng_seed != null:
			Game.orig_rng_seed = host_orig_rng_seed
			Game.current_rng_seed = Game.orig_rng_seed
			Globals.orig_rng_seed = Game.orig_rng_seed
		
		
func change_inputs(): # erase all inputs, load your P1_inputs into the slot for the player_id you are controlling
	
	var old_input_map = Settings.load_input_map()
	
	var input_list = ["P1_tapjump", "P1_buffer", "P1_dj_fastfall"] # hold the names of every input and tapjump/buffer for each player
	
	for player_inputs in Globals.INPUTS: # iterate through each player dictionary
		for input_array in player_inputs.values(): # iterate through each input array and get the key names
			input_list.append(input_array[0])
	
	var to_erase := "P"
	match Netplay.my_player_id():
		0: # you are controlling P1, erase P2 controls
			to_erase += "2"
			new_input_map["P1_tapjump"] = old_input_map.P1_tapjump
			new_input_map["P1_dj_fastfall"] = old_input_map.P1_dj_fastfall
			new_input_map["P1_buffer"] = old_input_map.P1_buffer
			new_input_map["P1_deadzone"] = old_input_map.P1_deadzone
			new_input_map["P1_extra_buttons"] = old_input_map.P1_extra_buttons
		1: # you are controlling P2, replace P2 controls with P1 controls and erase P1 controls
			to_erase += "1"
			new_input_map["P2_tapjump"] = old_input_map.P1_tapjump
			new_input_map["P2_dj_fastfall"] = old_input_map.P1_dj_fastfall
			new_input_map["P2_buffer"] = old_input_map.P1_buffer
			new_input_map["P2_deadzone"] = old_input_map.P1_deadzone
			new_input_map["P2_extra_buttons"] = old_input_map.P1_extra_buttons
			
	for input in input_list:
		if input.begins_with(to_erase): # this input is to be erased
			new_input_map[input] = null
		else: # this input is to either preserved or set to the other P1's
			if to_erase == "P2": # you are controlling P1 and this is a P1 input, preserve
				new_input_map[input] = old_input_map[input]
			else: # you are controlling P2 and this is a P2 input, set to old P1's
				new_input_map[input] = old_input_map["P1" + input.trim_prefix("P2")]
				
	return [old_input_map.P1_tapjump, old_input_map.P1_buffer, old_input_map.P1_dj_fastfall] # return your (old P1's) tapjump_and_buffer
	# after the game, just load and set the saved input map since these changed inputs are not saved
	# use: Settings.change_input_map(Settings.load_input_map())
	
	
func combine_inputs(opponent_tapjump_and_buffer):
	# get opponent's tapjump and buffer and add them to the input map before setting them for real

	match Netplay.my_player_id():
		0: # you are controlling P1, add opponent's tapjump and buffer to P2's side
			new_input_map["P2_tapjump"] = opponent_tapjump_and_buffer[0]
			new_input_map["P2_buffer"] = opponent_tapjump_and_buffer[1]
			new_input_map["P2_dj_fastfall"] = opponent_tapjump_and_buffer[2]
		1: # you are controlling P2, add opponent's tapjump and buffer to P1's side
			new_input_map["P1_tapjump"] = opponent_tapjump_and_buffer[0]
			new_input_map["P1_buffer"] = opponent_tapjump_and_buffer[1]
			new_input_map["P1_dj_fastfall"] = opponent_tapjump_and_buffer[2]
		
	Settings.change_input_map(new_input_map)
	
	
func auto_savestate(): # make a savestate every frame of the past [Netcode.max_rollback] frames
	Game.save_state(Game.frametime)
		
	if saved_game_states.size() > Netcode.max_rollback: # erase savestates if too many
		
		var oldest_key = saved_game_states.keys().min()
		
		if posmod(Game.frametime, Netcode.POS_DESYNC_CHECK_INTERVAL) == 0: # every 70 frames
			var positions = [saved_game_states[oldest_key].player_data[0].position,
					saved_game_states[oldest_key].player_data[1].position]
			Netcode.save_positions_for_desync_check(Game.frametime, positions)
			 # save that state for desync checking
		
# warning-ignore:return_value_discarded
		saved_game_states.erase(oldest_key) # erase oldest savestate
			
