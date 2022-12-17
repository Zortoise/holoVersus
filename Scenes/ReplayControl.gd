extends Node

var replay_saved_game_states: Dictionary
const MAX_REPLAY_SAVE_STATES = 61

var test_state # a single save state
var freeze_frame := false
var show_hitbox := false
var input_indicators := false

var controls_panel # point to it in GameViewport

const SHOW_CONTROLS = "P1_special"
const SPEED_UP = "P1_up"
const SPEED_DOWN = "P1_down"
const NORMAL_SPEED = "P1_jump"
const FREEZE_FRAME = "P1_light"
const SAVE_STATE = "P1_fierce"
const LOAD_STATE = "P1_dash"
const FRAME_ADVANCE = "P1_right"
const FRAME_REVERSE = "P1_left"
const TOGGLE_VIEWER = "P1_block"
const TOGGLE_INPUTS = "P1_aux"
const STOP_WATCHING = "P1_pause"


func init():
	get_parent().match_input_log.input_log = Globals.replay_input_log
	controls_panel = get_node("../../../../ReplayControls")
	controls_panel.hide()


func replay_auto_savestate(): # make a savestate every frame of the past 60 frames for replaying
	Globals.Game.save_state(Globals.Game.frametime)
	while replay_saved_game_states.size() > MAX_REPLAY_SAVE_STATES: # erase savestates if too many
# warning-ignore:return_value_discarded
		replay_saved_game_states.erase(replay_saved_game_states.keys().min())
		
#		var oldest_key = replay_saved_game_states.keys().min()
## warning-ignore:return_value_discarded
#		replay_saved_game_states.erase(oldest_key) # erase oldest savestate


func replay_control():
	
	if Input.is_action_pressed(SHOW_CONTROLS):
		controls_panel.show()
	else:
		controls_panel.hide()
	
	if Input.is_action_just_pressed(SPEED_UP):
		Globals.Game.play_speed += 1
	if Input.is_action_just_pressed(SPEED_DOWN) and Globals.Game.play_speed > 1:
		Globals.Game.play_speed -= 1
	if Input.is_action_just_pressed(NORMAL_SPEED):
		Globals.Game.play_speed = 1
		
	if Input.is_action_just_pressed(FREEZE_FRAME):
		freeze_frame = !freeze_frame
		
	# save state
	if Input.is_action_just_pressed(SAVE_STATE):
		Globals.Game.save_state("test_state")
		Globals.Game.emit_signal("saved_state") # to tell text to show message
		
	# load state
	if Input.is_action_just_pressed(LOAD_STATE):
		if test_state != null:
			Globals.Game.load_state(test_state)
			Globals.Game.true_frametime = Globals.Game.frametime
			Globals.Game.emit_signal("loaded_state") # to tell text to show message
		else:
			print("Error: Saved game state not found")

	if Input.is_action_just_pressed(FRAME_ADVANCE):
		Globals.Game.stimulate(false)
			
	if Input.is_action_just_pressed(FRAME_REVERSE): # reverse 1 frame by loading save state of previous frame, can do up to certain times
		if Globals.Game.frametime - 2 in replay_saved_game_states:
# warning-ignore:return_value_discarded
			replay_saved_game_states.erase(Globals.Game.frametime)
			Globals.Game.load_state(replay_saved_game_states[Globals.Game.frametime - 2])
			Globals.Game.true_frametime = Globals.Game.frametime
			Globals.Game.stimulate(false)
			
	if Input.is_action_just_pressed(TOGGLE_VIEWER):
		show_hitbox = !show_hitbox
		
	if Input.is_action_just_pressed(TOGGLE_INPUTS):
		input_indicators = !input_indicators

	if Input.is_action_just_pressed(STOP_WATCHING):
		get_node("../../../../Transition").play("transit_to_replays")
