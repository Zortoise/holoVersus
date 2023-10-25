extends Resource

export var data_name := ""
export var version := Globals.VERSION
export var datetime := ""

export var stage_ref := "Grid"
export var P1_char_ref := "Gura"
export var P1_palette := 1
export var P1_assist := ""
#export var P1_input_style := 0
export var P2_char_ref := "Gura"
export var P2_palette := 2
export var P2_assist := ""
#export var P2_input_style := 0
export var starting_stock_pts := 9
export var time_limit := 999
export var assists := 0
export var static_stage := 0
export var music := "" # WIP

export var input_buffer_time := [5, 5]
export var tap_jump := [true, true]
export var dj_fastfall := [false, false]
export var input_assist := [true, true]

export var orig_rng_seed := 0

export var input_log := {}

export var netgame := false
export var P1_profile := ""
export var P2_profile := ""


func generate_replay(): # called at start of VictoryScreen
	
	stage_ref = Globals.stage_ref
	P1_char_ref = Globals.P1_char_ref
	P1_palette = Globals.P1_palette
	P1_assist = Globals.P1_assist
#	P1_input_style = Globals.P1_input_style
	P2_char_ref = Globals.P2_char_ref
	P2_palette = Globals.P2_palette
	P2_assist = Globals.P2_assist
#	P2_input_style = Globals.P2_input_style
	starting_stock_pts = Globals.starting_stock_pts
	time_limit = Globals.time_limit
	assists = Globals.assists
	static_stage = Globals.static_stage
	music = Globals.music
	
	input_buffer_time = Globals.temp_input_buffer_time
	tap_jump = Globals.temp_tap_jump
	dj_fastfall = Globals.temp_dj_fastfall
	input_assist = Globals.temp_input_assist

	orig_rng_seed = Globals.orig_rng_seed
	
	input_log = Globals.match_input_log.input_log.duplicate(true)
	
	if Netplay.is_netplay():
		netgame = true
		P1_profile = Netplay.player_list[0].profile_name
		P2_profile = Netplay.player_list[1].profile_name
	
	datetime = Time.get_datetime_string_from_system(false, true)
	data_name = "Replay " + datetime
	data_name = data_name.replace(":", "")
	
	
func save_replay(rename: String):
	
	data_name = rename

	var dir = Directory.new()
		
	if !dir.dir_exists("user://Replays"): # if Replays folder don't exist, make it
		if dir.make_dir("user://Replays") != OK:
			print("Error: Unable to create Replays folder")
		
	var filepath = "user://Replays/" + data_name + ".tres" # set filepath
	var value := 2
	while dir.file_exists(filepath): # if there is already a replay of the same name, increment the name
		data_name = rename + str(value)
		filepath = "user://Replays/" + data_name + ".tres"
		value += 1
		
# warning-ignore:return_value_discarded
	ResourceSaver.save(filepath, self)
				

